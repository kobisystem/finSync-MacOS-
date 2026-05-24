import Foundation

public actor SupabaseAuthRepository: AuthRepository {
    private let store: any SessionStore
    private var session: AuthSession?

    public init(store: any SessionStore) {
        self.store = store
    }

    public func signIn(email: String, password: String) async throws -> AuthSession {
        guard email.contains("@"), password.isEmpty == false else {
            throw AppError.validation("Credenciais invalidas.")
        }
        let session = AuthSession(
            accessToken: "local-test-access-token",
            refreshToken: "local-test-refresh-token",
            accountOwnerId: "owner-1",
            expiresAt: Date().addingTimeInterval(3600)
        )
        self.session = session
        try await store.save(session)
        return session
    }

    public func currentSession() async throws -> AuthSession? {
        if let session { return session }
        return try await store.load()
    }

    public func signOut() async throws {
        session = nil
        try await store.clear()
    }
}
