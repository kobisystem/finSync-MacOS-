import XCTest
@testable import FinSyncCore

final class TransactionFilterTests: XCTestCase {
    func testFilterMatchesImmutableTransactionFacts() {
        let tx = TestData.transaction(id: "tx-1", type: .expense, amount: 10, review: .needsReview)
        XCTAssertTrue(TransactionFilter(reviewStatus: .needsReview).matches(tx))
        XCTAssertFalse(TransactionFilter(transactionType: .income).matches(tx))
        let detail = TransactionDetailPresentation(id: tx.id, descriptionOriginal: tx.descriptionOriginal, amount: tx.money, originalDate: tx.originalDate)
        XCTAssertTrue(detail.isImmutable)
    }
}

