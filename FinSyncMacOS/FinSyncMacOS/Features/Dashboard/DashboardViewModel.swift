import Foundation

@MainActor
public final class DashboardViewModel: ObservableObject {
    @Published public private(set) var state: LoadableState<DashboardSummary> = .idle
    private let coordinator: DashboardRefreshCoordinator
    private let accountOwnerId: String

    public init(coordinator: DashboardRefreshCoordinator, accountOwnerId: String) {
        self.coordinator = coordinator
        self.accountOwnerId = accountOwnerId
    }

    public func refresh(month: Date = Date(), trigger: RefreshTrigger = .manual) async {
        state = .loading
        state = await coordinator.refresh(accountOwnerId: accountOwnerId, month: month, trigger: trigger)
    }
}

