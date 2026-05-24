import Foundation
import FinSyncCore

enum Fixtures {
    static let now = Date(timeIntervalSince1970: 1_778_198_400)

    static func transaction(id: String, owner: String = "owner-1", type: TransactionType, amount: Decimal, currency: CurrencyCode = .brl, review: ReviewStatus = .notNeeded) -> Transaction {
        Transaction(id: id, accountOwnerId: owner, accountId: "acc-1", importFileId: "imp-1", creditCardStatementId: nil, sourceTransactionId: nil, transactionType: type, originalDate: now, postedDate: now, descriptionOriginal: "Original", descriptionNormalized: "Normalized", amount: amount, currency: currency, installmentCurrent: nil, installmentTotal: nil, deduplicationFingerprint: "fp-\(id)", reviewStatus: review, createdAt: now, updatedAt: now)
    }

    static func category(active: Bool = true) -> FinSyncCore.Category {
        FinSyncCore.Category(id: "cat-1", accountOwnerId: "owner-1", name: "Categoria", kind: .expense, parentCategoryId: nil, isActive: active, createdAt: now, updatedAt: now)
    }

    static func classification(active: Bool = true) -> TransactionClassification {
        TransactionClassification(id: "class-1", accountOwnerId: "owner-1", transactionId: "tx-1", categoryId: "cat-1", source: .automatedSuggestion, confidence: 0.7, explanation: "fixture", isActive: active, createdAt: now)
    }

    static func forecast(confidence: ForecastConfidence = .normal) -> CashFlowForecast {
        CashFlowForecast(id: "forecast-1", accountOwnerId: "owner-1", month: now, incomeConfirmed: 100, incomePredicted: 0, incomeEstimated: 0, expenseConfirmed: 60, expensePredicted: 0, expenseEstimated: 0, cardObligationsConfirmed: 10, cardObligationsPredicted: 0, cardObligationsEstimated: 0, projectedNetResult: 30, projectedBalance: 300, confidence: confidence, basisSummary: "Base", generatedAt: now)
    }
}

func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fputs("FAIL: \(message)\n", stderr)
        Foundation.exit(1)
    }
}

func expectThrows(_ message: String, _ block: () async throws -> Void) async {
    do {
        try await block()
        fputs("FAIL: \(message)\n", stderr)
        Foundation.exit(1)
    } catch {
        return
    }
}

let totals = [
    Money(amount: 10, currency: .brl),
    Money(amount: 15, currency: .brl),
    Money(amount: 20, currency: CurrencyCode(rawValue: "USD"))
].groupedByCurrency()
expect(totals.amount(for: .brl) == 25, "BRL totals should be grouped")
expect(totals.amount(for: CurrencyCode(rawValue: "USD")) == 20, "USD totals should be grouped separately")

let summary = DashboardSummaryCalculator.makeSummary(from: DashboardDataSet(transactions: [
    Fixtures.transaction(id: "income", type: .income, amount: 100),
    Fixtures.transaction(id: "expense", type: .expense, amount: 40),
    Fixtures.transaction(id: "card", type: .cardPayment, amount: 40),
    Fixtures.transaction(id: "usd", type: .expense, amount: 10, currency: CurrencyCode(rawValue: "USD"), review: .needsReview)
], forecastMatrix: CashFlowForecastMatrix.empty(startMonth: Fixtures.now, months: 12, defaultWindow: true)))
expect(summary.expenses.amount(for: .brl) == 40, "card_payment must not duplicate expense")
expect(summary.expenses.amount(for: CurrencyCode(rawValue: "USD")) == 10, "dashboard must separate currencies")
expect(summary.pendingReviewCount == 1, "dashboard must count pending review")

let cache = ProtectedFinancialCache()
await cache.authenticate(accountOwnerId: "owner-1")
try await cache.store(CachedFinancialRecord(accountOwnerId: "owner-1", entityType: "transaction", entityId: "tx-1", payload: Data("{}".utf8), sourceUpdatedAt: nil))
let cachedCount = try await cache.load(accountOwnerId: "owner-1").count
expect(cachedCount == 1, "cache should load after authentication")
await cache.logout()
await expectThrows("cache should not load after logout") {
    _ = try await cache.load(accountOwnerId: "owner-1")
}

let transaction = Fixtures.transaction(id: "tx-1", type: .expense, amount: 10, review: .needsReview)
let loaded = ReviewLoadedState(transactionUpdatedAt: transaction.updatedAt, reviewStatus: .needsReview, activeClassificationId: "class-1")
let item = ReviewItem(transaction: transaction, activeClassification: Fixtures.classification(), suggestedCategory: Fixtures.category(), categories: [Fixtures.category()], loadedState: loaded)
do {
    try ReviewClassificationUseCase.validateCorrection(ReviewCorrection(item: item, category: Fixtures.category(active: false)))
    fputs("FAIL: inactive category should be rejected\n", stderr)
    Foundation.exit(1)
} catch {}
do {
    try ReviewClassificationUseCase.validateNoConflict(item: item, current: ReviewLoadedState(transactionUpdatedAt: Date(), reviewStatus: .reviewed, activeClassificationId: "other"))
    fputs("FAIL: review conflict should be rejected\n", stderr)
    Foundation.exit(1)
} catch {}

expect(ForecastPresentationUseCase.present(Fixtures.forecast(), currency: .brl, historyMonths: 2) == nil, "less than 3 months should not present forecast")
expect(ForecastPresentationUseCase.present(Fixtures.forecast(confidence: .high), currency: .brl, historyMonths: 6)?.confidence == .low, "3-11 months should be low confidence")
expect(ForecastPresentationUseCase.present(Fixtures.forecast(confidence: .high), currency: .brl, historyMonths: 12)?.confidence == .high, "12+ months should preserve stored confidence")

let safe = AuditRedactionUseCase.safeMetadata([
    "status": "ok",
    "raw_document_content": "secret",
    "identifier": "unmasked_identifier 123"
])
expect(safe == ["status": "ok"], "audit metadata should be redacted")

print("FinSyncValidation PASS")
