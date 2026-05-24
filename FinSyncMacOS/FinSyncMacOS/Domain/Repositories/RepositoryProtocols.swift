import Foundation

public protocol AuthRepository: Sendable {
    func signIn(email: String, password: String) async throws -> AuthSession
    func currentSession() async throws -> AuthSession?
    func signOut() async throws
}

public protocol AccountOwnerRepository: Sendable {
    func fetchAccountOwner(session: AuthSession) async throws -> AccountOwner
}

public protocol DashboardRepositoryProtocol: Sendable {
    func fetchDashboardData(accountOwnerId: String, month: Date) async throws -> DashboardDataSet
}

public protocol ReviewRepositoryProtocol: Sendable {
    func fetchReviewItems(accountOwnerId: String) async throws -> [ReviewItem]
    func confirm(_ item: ReviewItem) async throws -> ReviewResult
    func correct(_ correction: ReviewCorrection) async throws -> ReviewResult
}

public protocol AuditRepositoryProtocol: Sendable {
    func fetchAuditEvents(accountOwnerId: String) async throws -> [AuditEvent]
}

