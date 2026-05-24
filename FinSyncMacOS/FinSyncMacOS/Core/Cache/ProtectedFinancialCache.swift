import Foundation

public struct CachedFinancialRecord: Codable, Equatable, Sendable {
    public let accountOwnerId: String
    public let cachedAt: Date
    public let entityType: String
    public let entityId: String
    public let payload: Data
    public let sourceUpdatedAt: Date?

    public init(accountOwnerId: String, cachedAt: Date = Date(), entityType: String, entityId: String, payload: Data, sourceUpdatedAt: Date?) {
        self.accountOwnerId = accountOwnerId
        self.cachedAt = cachedAt
        self.entityType = entityType
        self.entityId = entityId
        self.payload = payload
        self.sourceUpdatedAt = sourceUpdatedAt
    }
}

public actor ProtectedFinancialCache {
    private var records: [String: [CachedFinancialRecord]] = [:]
    private var authenticatedAccountOwnerId: String?

    public init() {}

    public func authenticate(accountOwnerId: String) {
        authenticatedAccountOwnerId = accountOwnerId
    }

    public func store(_ record: CachedFinancialRecord) throws {
        guard authenticatedAccountOwnerId == record.accountOwnerId else {
            throw AppError.permissionDenied
        }
        records[record.accountOwnerId, default: []].removeAll {
            $0.entityType == record.entityType && $0.entityId == record.entityId
        }
        records[record.accountOwnerId, default: []].append(record)
    }

    public func load(accountOwnerId: String) throws -> [CachedFinancialRecord] {
        guard authenticatedAccountOwnerId == accountOwnerId else {
            throw AppError.noSession
        }
        return records[accountOwnerId, default: []]
    }

    public func logout() {
        if let accountOwnerId = authenticatedAccountOwnerId {
            records[accountOwnerId] = []
        }
        authenticatedAccountOwnerId = nil
    }
}

