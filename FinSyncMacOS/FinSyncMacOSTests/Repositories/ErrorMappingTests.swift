import XCTest
@testable import FinSyncCore

final class ErrorMappingTests: XCTestCase {
    func testMapsKnownRepositoryConditions() {
        XCTAssertEqual(RepositoryErrorMapper.map("no_session"), .noSession)
        XCTAssertEqual(RepositoryErrorMapper.map("expired_session"), .expiredSession)
        XCTAssertEqual(RepositoryErrorMapper.map("permission_denied"), .permissionDenied)
        XCTAssertEqual(RepositoryErrorMapper.map("empty"), .emptyResult)
        XCTAssertEqual(RepositoryErrorMapper.map("review_conflict"), .reviewConflict)
        XCTAssertEqual(RepositoryErrorMapper.map("cache_unavailable"), .cacheUnavailable)
    }
}

