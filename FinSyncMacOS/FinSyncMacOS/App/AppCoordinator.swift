import Foundation

@MainActor
public final class AppCoordinator: ObservableObject {
    @Published public private(set) var state: AppState = .unauthenticated
    private let logoutUseCase: LogoutUseCase?

    public init(logoutUseCase: LogoutUseCase? = nil) {
        self.logoutUseCase = logoutUseCase
    }

    public func showAuthenticated(_ owner: AccountOwner) {
        state = .authenticatedReady(owner)
    }

    public func expireSession() {
        state = .sessionExpired
    }

    public func logout() async {
        do {
            try await logoutUseCase?.logout()
            state = .unauthenticated
        } catch let error as AppError {
            state = .failed(error)
        } catch {
            state = .failed(.unknown(String(describing: error)))
        }
    }
}

