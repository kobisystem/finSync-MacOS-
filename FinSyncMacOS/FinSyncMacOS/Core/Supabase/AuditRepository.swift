import Foundation

public actor AuditRepository: AuditRepositoryProtocol {
    private let events: [AuditEvent]

    public init(events: [AuditEvent] = []) {
        self.events = events
    }

    public func fetchAuditEvents(accountOwnerId: String) async throws -> [AuditEvent] {
        events.filter { $0.accountOwnerId == accountOwnerId }
    }
}

