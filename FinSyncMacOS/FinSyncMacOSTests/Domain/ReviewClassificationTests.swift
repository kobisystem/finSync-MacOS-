import XCTest
@testable import FinSyncCore

final class ReviewClassificationTests: XCTestCase {
    func testRejectsInactiveCategoryAndDetectsConflict() {
        let tx = TestData.transaction(id: "tx-1", type: .expense, amount: 10, review: .needsReview)
        let loaded = ReviewLoadedState(transactionUpdatedAt: tx.updatedAt, reviewStatus: .needsReview, activeClassificationId: "class-1")
        let item = ReviewItem(transaction: tx, activeClassification: TestData.classification(), suggestedCategory: TestData.category(), categories: [TestData.category()], loadedState: loaded)

        XCTAssertThrowsError(try ReviewClassificationUseCase.validateCorrection(ReviewCorrection(item: item, category: TestData.category(active: false))))
        XCTAssertThrowsError(try ReviewClassificationUseCase.validateNoConflict(item: item, current: ReviewLoadedState(transactionUpdatedAt: Date(), reviewStatus: .reviewed, activeClassificationId: "other")))
    }
}

