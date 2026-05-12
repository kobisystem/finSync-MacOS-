import XCTest
@testable import FinSyncCore

final class DomainDecodingTests: XCTestCase {
    func testFixtureBundleLoads() throws {
        let url = Bundle.module.url(forResource: "FinSyncFixtures", withExtension: "json")
        XCTAssertNotNil(url)
        let data = try XCTUnwrap(url).withUnsafeFileSystemRepresentation { path in
            try Data(contentsOf: URL(fileURLWithPath: String(cString: path!)))
        }
        XCTAssertGreaterThan(data.count, 0)
    }

    func testCoreModelsAreCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let owner = TestData.owner()
        let decoded = try decoder.decode(AccountOwner.self, from: encoder.encode(owner))
        XCTAssertEqual(decoded, owner)
    }
}

