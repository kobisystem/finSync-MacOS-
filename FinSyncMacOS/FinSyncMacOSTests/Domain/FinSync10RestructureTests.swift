import XCTest
@testable import FinSyncCore

final class FinSync10RestructureTests: XCTestCase {
    // MARK: - Helpers

    private func day(_ value: String) -> Date {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: value)!
    }

    private func tx(
        id: String,
        accountId: String,
        type: TransactionType,
        amount: Decimal,
        competence: String,
        cash: String,
        categoryId: String? = nil,
        statementId: String? = nil
    ) -> Transaction {
        Transaction(
            id: id,
            accountOwnerId: "owner-1",
            accountId: accountId,
            importFileId: "imp-1",
            creditCardStatementId: statementId,
            sourceTransactionId: nil,
            transactionType: type,
            originalDate: day(competence),
            postedDate: day(cash),
            cashDate: day(cash),
            competenceDate: day(competence),
            descriptionOriginal: "orig \(id)",
            descriptionNormalized: "norm \(id)",
            amount: amount,
            currency: .brl,
            categoryId: categoryId,
            paymentSourceAccountId: nil,
            installmentGroupId: nil,
            installmentCurrent: nil,
            installmentTotal: nil,
            deduplicationFingerprint: "fp-\(id)",
            reviewStatus: .notNeeded,
            createdAt: day(competence),
            updatedAt: day(competence)
        )
    }

    private func account(_ id: String, kind: AccountKind) -> Account {
        Account(id: id, accountOwnerId: "owner-1", kind: kind, institutionName: "Bank", displayName: id, maskedIdentifier: "****", currency: .brl, status: .active, createdAt: day("2026-01-01"), updatedAt: day("2026-01-01"))
    }

    private func category(_ id: String, kind: CategoryKind) -> FinSyncCore.Category {
        FinSyncCore.Category(id: id, accountOwnerId: "owner-1", name: id, kind: kind, parentCategoryId: nil, isActive: true, createdAt: day("2026-01-01"), updatedAt: day("2026-01-01"))
    }

    private func bankAndCard() -> [Account] {
        [account("acc-bank", kind: .bankAccount), account("acc-card", kind: .creditCard)]
    }

    private func sampleTransactions() -> [Transaction] {
        [
            tx(id: "salary", accountId: "acc-bank", type: .income, amount: 5000, competence: "2026-01-05", cash: "2026-01-05", categoryId: "salary"),
            tx(id: "groceries", accountId: "acc-bank", type: .expense, amount: 200, competence: "2026-01-10", cash: "2026-01-10", categoryId: "food"),
            tx(id: "card-buy", accountId: "acc-card", type: .expense, amount: 300, competence: "2026-01-15", cash: "2026-01-15", categoryId: "food"),
            // Invoice paid in February: settlement, not consumption.
            tx(id: "card-pay", accountId: "acc-bank", type: .cardPayment, amount: 300, competence: "2026-02-10", cash: "2026-02-10")
        ]
    }

    private var categories: [FinSyncCore.Category] {
        [category("food", kind: .expense), category("salary", kind: .income)]
    }

    // MARK: - Monthly overview (US1)

    func testCardPurchaseCountsOnceByCompetenceAndPaymentIsExcluded() {
        let overview = MonthlyOverviewCalculator.overview(
            month: day("2026-01-01"),
            transactions: sampleTransactions(),
            classifications: [],
            categories: categories,
            accounts: bankAndCard(),
            periods: []
        )

        XCTAssertEqual(overview.incomeTotal, 5000)
        XCTAssertEqual(overview.expenseTotal, 500) // groceries 200 + card purchase 300
        XCTAssertEqual(overview.netResult, 4500)
        XCTAssertEqual(overview.cardConsumption, 300)
        XCTAssertEqual(overview.bankConsumption, 200)
        // No card payment falls in January's cash month.
        XCTAssertEqual(overview.cardPaymentsTotal, 0)
        XCTAssertEqual(overview.categoryLines.first?.categoryName, "food")
        XCTAssertEqual(overview.categoryLines.first?.amount, 500)
    }

    func testCardPaymentAppearsAsSettlementInCashMonthNotConsumption() {
        let overview = MonthlyOverviewCalculator.overview(
            month: day("2026-02-01"),
            transactions: sampleTransactions(),
            classifications: [],
            categories: categories,
            accounts: bankAndCard(),
            periods: []
        )

        XCTAssertEqual(overview.expenseTotal, 0)
        XCTAssertEqual(overview.cardConsumption, 0)
        XCTAssertEqual(overview.cardPaymentsTotal, 300)
    }

    func testMonthlyOverviewSurfacesBalanceDivergenceFromPeriod() {
        let period = MonthlyPeriod(
            id: "p-1",
            accountOwnerId: "owner-1",
            month: day("2026-01-01"),
            status: .reviewed,
            incomeTotal: 5000,
            expenseTotal: 500,
            netResult: 4500,
            expectedEndBalance: 4500,
            actualEndBalance: 4400,
            unreconciledDifference: -100,
            changedAfterReview: true,
            changedAfterClose: false,
            reviewedAt: day("2026-02-01"),
            closedAt: nil,
            createdAt: day("2026-01-01"),
            updatedAt: day("2026-02-01")
        )

        let overview = MonthlyOverviewCalculator.overview(
            month: day("2026-01-01"),
            transactions: sampleTransactions(),
            classifications: [],
            categories: categories,
            accounts: bankAndCard(),
            periods: [period]
        )

        XCTAssertEqual(overview.status, .reviewed)
        XCTAssertTrue(overview.hasUnreconciledDifference)
        XCTAssertEqual(overview.unreconciledDifference, -100)
        XCTAssertTrue(overview.changedAfterReview)
    }

    func testActiveClassificationOverridesTransactionCategory() {
        let transactions = [
            tx(id: "x", accountId: "acc-bank", type: .expense, amount: 100, competence: "2026-01-10", cash: "2026-01-10", categoryId: "food")
        ]
        let classifications = [
            TransactionClassification(id: "c1", accountOwnerId: "owner-1", transactionId: "x", categoryId: "salary", source: .user, confidence: 1, explanation: nil, isActive: true, createdAt: day("2026-01-10"))
        ]
        // "salary" is an income category, so the expense reclassifies as income.
        let overview = MonthlyOverviewCalculator.overview(
            month: day("2026-01-01"),
            transactions: transactions,
            classifications: classifications,
            categories: categories,
            accounts: bankAndCard(),
            periods: []
        )
        XCTAssertEqual(overview.incomeTotal, 100)
        XCTAssertEqual(overview.expenseTotal, 0)
    }

    // MARK: - Balance reconciliation (US3)

    func testBestSnapshotPrefersImportedOverManualAndCalculated() {
        let snapshots = [
            BalanceSnapshot(id: "s1", accountOwnerId: "owner-1", accountId: "acc-bank", snapshotDate: day("2026-01-31"), balanceAmount: 1000, source: .calculated, importFileId: nil, confidence: .normal, createdAt: day("2026-01-31")),
            BalanceSnapshot(id: "s2", accountOwnerId: "owner-1", accountId: "acc-bank", snapshotDate: day("2026-01-31"), balanceAmount: 1200, source: .importedStatement, importFileId: "imp-1", confidence: .high, createdAt: day("2026-01-31")),
            // Manual is later but lower priority than imported.
            BalanceSnapshot(id: "s3", accountOwnerId: "owner-1", accountId: "acc-bank", snapshotDate: day("2026-02-05"), balanceAmount: 1100, source: .manual, importFileId: nil, confidence: .normal, createdAt: day("2026-02-05"))
        ]
        let statements = [
            CreditCardStatement(id: "st-1", accountOwnerId: "owner-1", accountId: "acc-card", creditCardAccountId: "acc-card", importFileId: "imp-1", statementPeriodStart: day("2026-01-01"), statementPeriodEnd: day("2026-01-31"), dueDate: day("2026-02-10"), closingDate: day("2026-01-28"), totalAmount: 300, paidAmount: 0, currency: .brl, status: .open, createdAt: day("2026-01-31"), updatedAt: day("2026-01-31"))
        ]

        let summary = BalanceReconciliationCalculator.summary(
            accounts: bankAndCard(),
            snapshots: snapshots,
            statements: statements,
            periods: []
        )

        let bankLine = summary.accountLines.first { $0.accountId == "acc-bank" }
        XCTAssertEqual(bankLine?.snapshotBalance, 1200)
        XCTAssertEqual(bankLine?.snapshotSource, .importedStatement)
        XCTAssertEqual(summary.totalAssets, 1200)
        XCTAssertEqual(summary.totalCardDebt, 300)
        XCTAssertEqual(summary.estimatedNetWorth, 900)
    }

    // MARK: - Cards (US3)

    func testCardsOverviewSeparatesUnmatchedPaymentsAndInvoices() {
        let statements = [
            CreditCardStatement(id: "st-open", accountOwnerId: "owner-1", accountId: "acc-card", creditCardAccountId: "acc-card", importFileId: "imp-1", statementPeriodStart: day("2026-01-01"), statementPeriodEnd: day("2026-01-31"), dueDate: day("2026-02-10"), closingDate: day("2026-01-28"), totalAmount: 300, paidAmount: 0, currency: .brl, status: .open, createdAt: day("2026-01-31"), updatedAt: day("2026-01-31")),
            CreditCardStatement(id: "st-paid", accountOwnerId: "owner-1", accountId: "acc-card", creditCardAccountId: "acc-card", importFileId: "imp-1", statementPeriodStart: day("2025-12-01"), statementPeriodEnd: day("2025-12-31"), dueDate: day("2026-01-10"), closingDate: day("2025-12-28"), totalAmount: 250, paidAmount: 250, currency: .brl, status: .paid, createdAt: day("2025-12-31"), updatedAt: day("2026-01-10"))
        ]
        let transactions = [
            tx(id: "pay-unlinked", accountId: "acc-bank", type: .cardPayment, amount: 250, competence: "2026-01-10", cash: "2026-01-10")
        ]
        let obligations = [
            Obligation(id: "o1", accountOwnerId: "owner-1", sourceType: .creditCardStatement, sourceId: "st-open", dueDate: day("2026-02-10"), competenceMonth: day("2026-02-01"), amount: 300, status: .pending, confidence: .normal, createdAt: day("2026-01-31"), updatedAt: day("2026-01-31"))
        ]

        let overview = CardStatementsCalculator.overview(
            statements: statements,
            transactions: transactions,
            accounts: bankAndCard(),
            obligations: obligations
        )

        XCTAssertEqual(overview.statements.count, 2)
        XCTAssertEqual(overview.statements.first?.statementId, "st-open") // sorted by due date desc
        XCTAssertEqual(overview.unmatchedInvoices.map(\.id), ["st-open"])
        XCTAssertEqual(overview.unmatchedPayments.map(\.id), ["pay-unlinked"])
        XCTAssertEqual(overview.upcomingObligations.map(\.id), ["o1"])

        let openLine = overview.statements.first { $0.statementId == "st-open" }
        XCTAssertEqual(openLine?.remainingAmount, 300)
        XCTAssertFalse(openLine?.isLinkedToPayment ?? true)
    }
}
