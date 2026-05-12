import Foundation

public enum ForecastPresentationUseCase {
    public static func present(_ forecast: CashFlowForecast, currency: CurrencyCode, historyMonths: Int) -> ForecastPresentation? {
        guard HistoryEligibility.from(monthCount: historyMonths) != .insufficient else {
            return nil
        }
        let confidence: ForecastConfidence = historyMonths < 12 ? .low : forecast.confidence
        return ForecastPresentation(
            id: forecast.id,
            month: forecast.month,
            projectedNetResult: Money(amount: forecast.projectedNetResult, currency: currency),
            projectedBalance: Money(amount: forecast.projectedBalance, currency: currency),
            confidence: confidence,
            basisSummary: forecast.basisSummary,
            generatedAt: forecast.generatedAt
        )
    }
}

