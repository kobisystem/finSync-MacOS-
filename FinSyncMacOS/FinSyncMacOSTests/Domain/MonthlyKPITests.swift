import XCTest
@testable import FinSyncCore

final class MonthlyKPITests: XCTestCase {
    func testMonthlyKPIExcludesCardPaymentAndSeparatesCurrency() {
        let kpis = MonthlyKPICalculator.calculate(transactions: [
            TestData.transaction(id: "income", type: .income, amount: 100),
            TestData.transaction(id: "expense", type: .expense, amount: 40),
            TestData.transaction(id: "card", type: .cardPayment, amount: 40),
            TestData.transaction(id: "usd", type: .expense, amount: 5, currency: CurrencyCode(rawValue: "USD"))
        ], classifications: [], categories: [])

        XCTAssertEqual(kpis.first?.expenses.amount(for: .brl), 40)
        XCTAssertEqual(kpis.first?.expenses.amount(for: CurrencyCode(rawValue: "USD")), 5)
    }
}

