import XCTest
@testable import FinSyncCore

final class DashboardRepositoryTests: XCTestCase {
    func testDashboardRepositoryScopesAllCollections() async throws {
        let data = DashboardDataSet(
            accounts: [TestData.account(owner: "owner-1"), TestData.account(owner: "owner-2")],
            transactions: [TestData.transaction(id: "tx-1", owner: "owner-1", type: .income, amount: 1), TestData.transaction(id: "tx-2", owner: "owner-2", type: .income, amount: 1)],
            classifications: [TestData.classification(owner: "owner-1")],
            imports: [TestData.importFile(owner: "owner-1"), TestData.importFile(owner: "owner-2")],
            forecastMatrix: TestData.forecastMatrix(confidence: .high)
        )
        let result = try await DashboardRepository(dataSet: data).fetchDashboardData(accountOwnerId: "owner-1", month: Date())
        XCTAssertEqual(result.accounts.count, 1)
        XCTAssertEqual(result.transactions.count, 1)
        XCTAssertEqual(result.imports.count, 1)
        XCTAssertEqual(result.forecastMatrix.monthlyTotals.first?.confidence, .high)
    }
}
