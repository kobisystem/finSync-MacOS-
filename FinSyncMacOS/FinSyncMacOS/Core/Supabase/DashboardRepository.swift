import Foundation

public actor DashboardRepository: DashboardRepositoryProtocol {
    private let dataSet: DashboardDataSet

    public init(dataSet: DashboardDataSet = DashboardDataSet()) {
        self.dataSet = dataSet
    }

    public func fetchDashboardData(accountOwnerId: String, month: Date) async throws -> DashboardDataSet {
        DashboardDataSet(
            transactions: dataSet.transactions.filter { $0.accountOwnerId == accountOwnerId },
            classifications: dataSet.classifications.filter { $0.accountOwnerId == accountOwnerId },
            imports: dataSet.imports.filter { $0.accountOwnerId == accountOwnerId },
            forecasts: dataSet.forecasts.filter { $0.accountOwnerId == accountOwnerId },
            refreshedAt: Date()
        )
    }
}

