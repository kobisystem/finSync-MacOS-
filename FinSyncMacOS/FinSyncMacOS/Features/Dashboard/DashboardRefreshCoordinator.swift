import Foundation

public enum RefreshTrigger: Equatable, Sendable {
    case appOpened
    case windowActivated
    case manual
}

public actor DashboardRefreshCoordinator {
    private let repository: any DashboardRepositoryProtocol
    private let cache: ProtectedFinancialCache

    public init(repository: any DashboardRepositoryProtocol, cache: ProtectedFinancialCache) {
        self.repository = repository
        self.cache = cache
    }

    public func refresh(accountOwnerId: String, month: Date, trigger: RefreshTrigger) async -> LoadableState<DashboardSummary> {
        do {
            let dataSet = try await repository.fetchDashboardData(accountOwnerId: accountOwnerId, month: month)
            return .ready(DashboardSummaryCalculator.makeSummary(from: dataSet))
        } catch AppError.network(let message) {
            do {
                _ = try await cache.load(accountOwnerId: accountOwnerId)
                let emptyStale = DashboardSummaryCalculator.makeSummary(from: DashboardDataSet(refreshedAt: Date()), staleMessage: message)
                return .stale(emptyStale, message: message)
            } catch {
                return .failed(.network(message))
            }
        } catch let error as AppError {
            return .failed(error)
        } catch {
            return .failed(.unknown(String(describing: error)))
        }
    }
}
