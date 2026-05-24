import Foundation

public actor ForecastRepository {
    private let forecasts: [CashFlowForecast]
    private let historyMonths: Int

    public init(forecasts: [CashFlowForecast] = [], historyMonths: Int = 0) {
        self.forecasts = forecasts
        self.historyMonths = historyMonths
    }

    public func fetch(accountOwnerId: String) async throws -> ([CashFlowForecast], Int) {
        (forecasts.filter { $0.accountOwnerId == accountOwnerId }, historyMonths)
    }
}

