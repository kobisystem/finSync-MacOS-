import Foundation

public protocol SessionStore: Sendable {
    func save(_ session: AuthSession) async throws
    func load() async throws -> AuthSession?
    func clear() async throws
}

public struct AuthSession: Codable, Equatable, Sendable {
    public let accessToken: String
    public let refreshToken: String
    public let accountOwnerId: String?
    public let expiresAt: Date

    public init(accessToken: String, refreshToken: String, accountOwnerId: String?, expiresAt: Date) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.accountOwnerId = accountOwnerId
        self.expiresAt = expiresAt
    }

    public var isExpired: Bool {
        expiresAt <= Date()
    }
}

public actor KeychainSessionStore: SessionStore {
    private var session: AuthSession?

    public init() {}

    public func save(_ session: AuthSession) async throws {
        self.session = session
    }

    public func load() async throws -> AuthSession? {
        session
    }

    public func clear() async throws {
        session = nil
    }
}

