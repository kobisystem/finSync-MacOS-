import XCTest
@testable import FinSyncCore

final class ReviewRepositoryTests: XCTestCase {
    func testCorrectCreatesUserClassificationAndOptionalRuleSuggestion() async throws {
        let tx = TestData.transaction(id: "tx-1", type: .expense, amount: 10, review: .needsReview)
        let loaded = ReviewLoadedState(transactionUpdatedAt: tx.updatedAt, reviewStatus: .needsReview, activeClassificationId: nil)
        let item = ReviewItem(transaction: tx, activeClassification: nil, suggestedCategory: nil, categories: [TestData.category()], loadedState: loaded)
        let result = try await ReviewMutationRepository(items: [item]).correct(ReviewCorrection(item: item, category: TestData.category(), createRule: true))
        XCTAssertEqual(result.reviewStatus, .reviewed)
        XCTAssertEqual(result.activeClassification.source, .user)
        XCTAssertNotNil(result.ruleSuggestion)
    }
}

