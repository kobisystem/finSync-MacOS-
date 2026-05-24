import Foundation

@MainActor
public final class AuthViewModel: ObservableObject {
    public enum State: Equatable {
        case unauthenticated
        case loading
        case authenticated(AccountOwner)
        case expired
        case failed(AppError)
    }

    @Published public private(set) var state: State = .unauthenticated
    private let authRepository: any AuthRepository
    private let accountOwnerRepository: any AccountOwnerRepository

    public init(authRepository: any AuthRepository, accountOwnerRepository: any AccountOwnerRepository) {
        self.authRepository = authRepository
        self.accountOwnerRepository = accountOwnerRepository
    }

    public func signIn(email: String, password: String) async {
        state = .loading
        do {
            let session = try await authRepository.signIn(email: email, password: password)
            if session.isExpired {
                state = .expired
                return
            }
            state = .authenticated(try await accountOwnerRepository.fetchAccountOwner(session: session))
        } catch let error as AppError {
            state = .failed(error)
        } catch {
            state = .failed(.unknown(String(describing: error)))
        }
    }
}
