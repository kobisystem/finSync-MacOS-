import XCTest
@testable import FinSyncCore

final class AccountOwnerIsolationTests: XCTestCase {
    func testDashboardRepositoryFiltersByOwner() async throws {
        let dataSet = DashboardDataSet(
            transactions: [
                TestData.transaction(id: "a", owner: "owner-1", type: .income, amount: 100),
                TestData.transaction(id: "b", owner: "owner-2", type: .income, amount: 100)
            ]
        )
        let repository = DashboardRepository(dataSet: dataSet)
        let result = try await repository.fetchDashboardData(accountOwnerId: "owner-1", month: Date())
        XCTAssertEqual(result.transactions.map(\.id), ["a"])
    }
}

