import XCTest
@testable import FinSyncCore

final class FinancialBrowseRepositoryTests: XCTestCase {
    func testAccountsAndTransactionsAreScopedAndFiltered() async throws {
        let accounts = AccountsRepository(accounts: [TestData.account(owner: "owner-1"), TestData.account(owner: "owner-2", id: "acc-2")])
        let accountsCount = try await accounts.fetch(accountOwnerId: "owner-1").count
        XCTAssertEqual(accountsCount, 1)

        let tx = TestData.transaction(id: "tx-1", type: .expense, amount: 10, review: .needsReview)
        let transactions = TransactionsRepository(transactions: [tx])
        let result = try await transactions.fetch(accountOwnerId: "owner-1", filter: TransactionFilter(reviewStatus: .needsReview))
        XCTAssertEqual(result.map(\.id), ["tx-1"])
    }
}

