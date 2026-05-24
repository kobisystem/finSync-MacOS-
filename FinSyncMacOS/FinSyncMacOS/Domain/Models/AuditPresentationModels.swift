import Foundation

public struct AuditPresentation: Identifiable, Equatable, Sendable {
    public let id: String
    public let actor: ActorType
    public let eventType: String
    public let entityType: String
    public let entityId: String
    public let metadata: [String: String]
    public let createdAt: Date
}

