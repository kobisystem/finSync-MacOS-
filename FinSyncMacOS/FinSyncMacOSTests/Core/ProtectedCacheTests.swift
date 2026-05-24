import XCTest
@testable import FinSyncCore

final class ProtectedCacheTests: XCTestCase {
    func testCacheRequiresMatchingAuthenticatedOwnerAndClearsOnLogout() async throws {
        let cache = ProtectedFinancialCache()
        let record = CachedFinancialRecord(accountOwnerId: "owner-1", entityType: "transaction", entityId: "tx-1", payload: Data("{}".utf8), sourceUpdatedAt: nil)

        await assertThrowsAsync { try await cache.load(accountOwnerId: "owner-1") }
        await cache.authenticate(accountOwnerId: "owner-1")
        try await cache.store(record)
        let loadedCount = try await cache.load(accountOwnerId: "owner-1").count
        XCTAssertEqual(loadedCount, 1)
        await cache.logout()
        await assertThrowsAsync { try await cache.load(accountOwnerId: "owner-1") }
    }

    private func assertThrowsAsync(
        _ expression: () async throws -> some Any,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        do {
            _ = try await expression()
            XCTFail("Expected error but call succeeded", file: file, line: line)
        } catch {
            // expected
        }
    }
}

