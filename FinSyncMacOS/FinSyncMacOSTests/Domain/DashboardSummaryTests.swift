import XCTest
@testable import FinSyncCore

final class DashboardSummaryTests: XCTestCase {
    func testSummaryExcludesCardPaymentsAndGroupsCurrency() {
        let data = DashboardDataSet(
            transactions: [
                TestData.transaction(id: "income", type: .income, amount: 100),
                TestData.transaction(id: "expense", type: .expense, amount: 40),
                TestData.transaction(id: "card", type: .cardPayment, amount: 40),
                TestData.transaction(id: "usd", type: .expense, amount: 10, currency: CurrencyCode(rawValue: "USD"), review: .needsReview)
            ],
            imports: [TestData.importFile()],
            forecasts: [TestData.forecast()]
        )
        let summary = DashboardSummaryCalculator.makeSummary(from: data)
        XCTAssertEqual(summary.income.amount(for: .brl), 100)
        XCTAssertEqual(summary.expenses.amount(for: .brl), 40)
        XCTAssertEqual(summary.expenses.amount(for: CurrencyCode(rawValue: "USD")), 10)
        XCTAssertEqual(summary.pendingReviewCount, 1)
        XCTAssertEqual(summary.forecastConfidence, .normal)
    }
}

