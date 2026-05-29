import XCTest
@testable import FinSyncCore

final class MonthlyKPITests: XCTestCase {
    func testMonthlyKPISeparatesCreditCardConsumptionFromCashExpense() {
        let kpis = MonthlyKPICalculator.calculate(transactions: [
            TestData.transaction(id: "income", accountId: "bank-1", type: .income, amount: 100),
            TestData.transaction(id: "expense", accountId: "bank-1", type: .expense, amount: -40),
            TestData.transaction(id: "card-purchase", accountId: "card-1", type: .expense, amount: -300),
            TestData.transaction(id: "card-payment", accountId: "bank-1", type: .cardPayment, amount: -50),
            TestData.transaction(id: "usd", accountId: "bank-1", type: .expense, amount: -5, currency: CurrencyCode(rawValue: "USD"))
        ], classifications: [], categories: [], accounts: [
            TestData.account(id: "bank-1", kind: .bankAccount),
            TestData.account(id: "card-1", kind: .creditCard)
        ])

        XCTAssertEqual(kpis.first?.expenses.amount(for: .brl), 90)
        XCTAssertEqual(kpis.first?.netResult.amount(for: .brl), 10)
        XCTAssertEqual(kpis.first?.expenses.amount(for: CurrencyCode(rawValue: "USD")), 5)
    }
}
