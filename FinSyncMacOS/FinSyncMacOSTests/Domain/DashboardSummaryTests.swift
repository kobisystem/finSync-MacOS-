import XCTest
@testable import FinSyncCore

final class DashboardSummaryTests: XCTestCase {
    func testSummarySeparatesCreditCardConsumptionFromCashExpense() {
        let data = DashboardDataSet(
            accounts: [
                TestData.account(id: "bank-1", kind: .bankAccount),
                TestData.account(id: "card-1", kind: .creditCard)
            ],
            transactions: [
                TestData.transaction(id: "income", accountId: "bank-1", type: .income, amount: 100),
                TestData.transaction(id: "expense", accountId: "bank-1", type: .expense, amount: -40),
                TestData.transaction(id: "card-purchase", accountId: "card-1", type: .expense, amount: -300),
                TestData.transaction(id: "card-payment", accountId: "bank-1", type: .cardPayment, amount: -50),
                TestData.transaction(id: "usd", accountId: "bank-1", type: .expense, amount: -10, currency: CurrencyCode(rawValue: "USD"), review: .needsReview)
            ],
            imports: [TestData.importFile()],
            forecastMatrix: TestData.forecastMatrix(confidence: .normal)
        )
        let summary = DashboardSummaryCalculator.makeSummary(from: data)
        XCTAssertEqual(summary.income.amount(for: .brl), 100)
        XCTAssertEqual(summary.expenses.amount(for: .brl), 90)
        XCTAssertEqual(summary.netResult.amount(for: .brl), 10)
        XCTAssertEqual(summary.expenses.amount(for: CurrencyCode(rawValue: "USD")), 10)
        XCTAssertEqual(summary.pendingReviewCount, 1)
        XCTAssertEqual(summary.forecastConfidence, .normal)
    }
}
