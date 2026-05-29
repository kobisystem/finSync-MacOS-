import Foundation

public actor DashboardRepository: DashboardRepositoryProtocol {
    private let dataSet: DashboardDataSet

    public init(dataSet: DashboardDataSet = DashboardDataSet()) {
        self.dataSet = dataSet
    }

    public func fetchDashboardData(accountOwnerId: String, month: Date) async throws -> DashboardDataSet {
        DashboardDataSet(
            accounts: dataSet.accounts.filter { $0.accountOwnerId == accountOwnerId },
            transactions: dataSet.transactions.filter { $0.accountOwnerId == accountOwnerId },
            classifications: dataSet.classifications.filter { $0.accountOwnerId == accountOwnerId },
            imports: dataSet.imports.filter { $0.accountOwnerId == accountOwnerId },
            forecastMatrix: dataSet.forecastMatrix,
            refreshedAt: Date()
        )
    }
}
