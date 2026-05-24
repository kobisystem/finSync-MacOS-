import Foundation

public actor ReviewQueueRepository {
    private let items: [ReviewItem]

    public init(items: [ReviewItem] = []) {
        self.items = items
    }

    public func fetch(accountOwnerId: String) async throws -> [ReviewItem] {
        items.filter { $0.transaction.accountOwnerId == accountOwnerId && $0.transaction.reviewStatus == .needsReview }
    }
}

