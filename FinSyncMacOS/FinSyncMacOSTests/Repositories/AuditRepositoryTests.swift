import XCTest
@testable import FinSyncCore

final class AuditRepositoryTests: XCTestCase {
    func testAuditEventsAreScopedByOwner() async throws {
        let event1 = AuditEvent(id: "audit-1", accountOwnerId: "owner-1", actorType: .user, eventType: "classification.corrected", entityType: "transaction", entityId: "tx-1", metadataRedacted: ["category": "Food"], createdAt: TestData.date())
        let event2 = AuditEvent(id: "audit-2", accountOwnerId: "owner-2", actorType: .user, eventType: "classification.corrected", entityType: "transaction", entityId: "tx-2", metadataRedacted: [:], createdAt: TestData.date())
        let events = try await AuditRepository(events: [event1, event2]).fetchAuditEvents(accountOwnerId: "owner-1")
        XCTAssertEqual(events.map(\.id), ["audit-1"])
    }
}

