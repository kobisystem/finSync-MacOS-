import XCTest
@testable import FinSyncCore

final class MoneyAggregationTests: XCTestCase {
    func testGroupsByCurrencyWithoutMixingTotals() {
        let totals = [
            Money(amount: 10, currency: .brl),
            Money(amount: 15, currency: .brl),
            Money(amount: 20, currency: CurrencyCode(rawValue: "USD"))
        ].groupedByCurrency()

        XCTAssertEqual(totals.amount(for: .brl), 25)
        XCTAssertEqual(totals.amount(for: CurrencyCode(rawValue: "USD")), 20)
        XCTAssertEqual(totals.currencies.count, 2)
    }
}

