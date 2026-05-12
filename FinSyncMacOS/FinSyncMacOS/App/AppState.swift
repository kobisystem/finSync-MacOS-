import Foundation

public enum AppState: Equatable {
    case unauthenticated
    case authenticatedLoading(AccountOwner)
    case authenticatedReady(AccountOwner)
    case authenticatedStale(AccountOwner, message: String)
    case sessionExpired
    case failed(AppError)
}

