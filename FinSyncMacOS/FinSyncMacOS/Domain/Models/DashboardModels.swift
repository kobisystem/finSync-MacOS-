import Foundation

public struct DashboardDataSet: Equatable, Sendable {
    public var transactions: [Transaction]
    public var classifications: [TransactionClassification]
    public var imports: [ImportFile]
    public var forecasts: [CashFlowForecast]
    public var refreshedAt: Date

    public init(transactions: [Transaction] = [], classifications: [TransactionClassification] = [], imports: [ImportFile] = [], forecasts: [CashFlowForecast] = [], refreshedAt: Date = Date()) {
        self.transactions = transactions
        self.classifications = classifications
        self.imports = imports
        self.forecasts = forecasts
        self.refreshedAt = refreshedAt
    }
}

public struct RecentImportStatus: Identifiable, Equatable, Sendable {
    public let id: String
    public let fileName: String
    public let status: ImportStatus
    public let statusMessage: String?
    public let updatedAt: Date
}

public struct LastRefreshState: Equatable, Sendable {
    public let refreshedAt: Date?
    public let isStale: Bool
    public let message: String?
}

public struct DashboardSummary: Equatable, Sendable {
    public let income: GroupedMoneyTotals
    public let expenses: GroupedMoneyTotals
    public let netResult: GroupedMoneyTotals
    public let pendingReviewCount: Int
    public let recentImports: [RecentImportStatus]
    public let forecastConfidence: ForecastConfidence?
    public let lastRefresh: LastRefreshState
}

