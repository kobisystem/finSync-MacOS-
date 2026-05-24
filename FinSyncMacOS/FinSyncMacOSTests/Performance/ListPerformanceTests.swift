import XCTest
@testable import FinSyncCore

final class ListPerformanceTests: XCTestCase {
    func testDashboardSummaryWithThousandRecordsIsFast() {
        let transactions = (0..<1000).map { index in
            TestData.transaction(id: "tx-\(index)", type: index.isMultiple(of: 2) ? .income : .expense, amount: Decimal(index))
        }
        measure {
            _ = DashboardSummaryCalculator.makeSummary(from: DashboardDataSet(transactions: transactions))
        }
    }
}

