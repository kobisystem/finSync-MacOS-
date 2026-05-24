import Foundation
@testable import FinSyncCore

enum TestData {
    static func date(_ value: String = "2026-05-01T00:00:00Z") -> Date {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: value)!
    }

    static func owner(_ id: String = "owner-1") -> AccountOwner {
        AccountOwner(id: id, email: "\(id)@example.com", displayName: id, createdAt: date())
    }

    static func account(owner: String = "owner-1", id: String = "acc-1", currency: CurrencyCode = .brl, kind: AccountKind = .bankAccount) -> Account {
        Account(id: id, accountOwnerId: owner, kind: kind, institutionName: "Bank", displayName: "Conta", maskedIdentifier: "****1234", currency: currency, createdAt: date(), updatedAt: date())
    }

    static func transaction(id: String, owner: String = "owner-1", type: TransactionType, amount: Decimal, currency: CurrencyCode = .brl, review: ReviewStatus = .notNeeded) -> Transaction {
        Transaction(
            id: id,
            accountOwnerId: owner,
            accountId: "acc-1",
            importFileId: "imp-1",
            creditCardStatementId: nil,
            sourceTransactionId: nil,
            transactionType: type,
            originalDate: date(),
            postedDate: date(),
            descriptionOriginal: "Original \(id)",
            descriptionNormalized: "Normalized \(id)",
            amount: amount,
            currency: currency,
            installmentCurrent: nil,
            installmentTotal: nil,
            deduplicationFingerprint: "fp-\(id)",
            reviewStatus: review,
            createdAt: date(),
            updatedAt: date()
        )
    }

    static func category(id: String = "cat-1", owner: String = "owner-1", active: Bool = true) -> FinSyncCore.Category {
        FinSyncCore.Category(id: id, accountOwnerId: owner, name: "Categoria", kind: .expense, parentCategoryId: nil, isActive: active, createdAt: date(), updatedAt: date())
    }

    static func classification(id: String = "class-1", transactionId: String = "tx-1", owner: String = "owner-1", active: Bool = true) -> TransactionClassification {
        TransactionClassification(id: id, accountOwnerId: owner, transactionId: transactionId, categoryId: "cat-1", source: .automatedSuggestion, confidence: 0.7, explanation: "fixture", isActive: active, createdAt: date())
    }

    static func importFile(owner: String = "owner-1") -> ImportFile {
        ImportFile(id: "imp-1", accountOwnerId: owner, provider: .dropbox, providerFileId: "drop-1", originalPath: "/FinSync/Inbox/file.ofx", fileName: "file.ofx", mimeType: "application/ofx", fileExtension: "ofx", contentFingerprint: "content", fileType: .bankStatement, status: .processed, statusReasonCode: nil, statusMessage: nil, detectedIssuer: "Bank", detectedLayout: "OFX", processingStartedAt: date(), processingFinishedAt: date(), createdAt: date(), updatedAt: date())
    }

    static func forecast(owner: String = "owner-1", confidence: ForecastConfidence = .normal) -> CashFlowForecast {
        CashFlowForecast(id: "forecast-1", accountOwnerId: owner, month: date(), incomeConfirmed: 100, incomePredicted: 0, incomeEstimated: 0, expenseConfirmed: 60, expensePredicted: 0, expenseEstimated: 0, cardObligationsConfirmed: 10, cardObligationsPredicted: 0, cardObligationsEstimated: 0, projectedNetResult: 30, projectedBalance: 300, confidence: confidence, basisSummary: "Base fixture", generatedAt: date())
    }

    static func forecastMatrix(confidence: ForecastConfidence = .normal) -> CashFlowForecastMatrix {
        let start = date("2026-01-01T00:00:00Z")
        return CashFlowForecastMatrix(
            metadata: CashFlowForecastMetadata(
                generatedAt: date(),
                startMonth: start,
                months: 12,
                initialBalance: 0,
                defaultWindow: true
            ),
            months: CashFlowForecastMatrix.resolveMonths(start: start, count: 12),
            categoryLines: [],
            monthlyTotals: [
                CashFlowForecastMonthlyTotal(
                    month: start,
                    totalIncome: 100,
                    totalExpense: 60,
                    netResult: 40,
                    accumulatedBalance: 40,
                    confidence: confidence,
                    basisSummary: "Base fixture"
                )
            ]
        )
    }
}
