import XCTest
@testable import FinSyncCore

final class AuditRedactionTests: XCTestCase {
    func testDropsRawSensitiveMetadata() {
        let safe = AuditRedactionUseCase.safeMetadata([
            "status": "ok",
            "raw_document_content": "secret",
            "identifier": "unmasked_identifier 123"
        ])
        XCTAssertEqual(safe, ["status": "ok"])
    }
}

