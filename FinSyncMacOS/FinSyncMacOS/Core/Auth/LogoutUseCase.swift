import Foundation

public struct LogoutUseCase: Sendable {
    private let authRepository: any AuthRepository
    private let cache: ProtectedFinancialCache

    public init(authRepository: any AuthRepository, cache: ProtectedFinancialCache) {
        self.authRepository = authRepository
        self.cache = cache
    }

    public func logout() async throws {
        try await authRepository.signOut()
        await cache.logout()
    }
}
