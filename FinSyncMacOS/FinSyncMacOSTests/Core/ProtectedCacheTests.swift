import XCTest
@testable import FinSyncCore

final class ProtectedCacheTests: XCTestCase {
    func testCacheRequiresMatchingAuthenticatedOwnerAndClearsOnLogout() async throws {
        let cache = ProtectedFinancialCache()
        let record = CachedFinancialRecord(accountOwnerId: "owner-1", entityType: "transaction", entityId: "tx-1", payload: Data("{}".utf8), sourceUpdatedAt: nil)

        XCTAssertThrowsError(try await cache.load(accountOwnerId: "owner-1"))
        await cache.authenticate(accountOwnerId: "owner-1")
        try await cache.store(record)
        XCTAssertEqual(try await cache.load(accountOwnerId: "owner-1").count, 1)
        await cache.logout()
        XCTAssertThrowsError(try await cache.load(accountOwnerId: "owner-1"))
    }
}

