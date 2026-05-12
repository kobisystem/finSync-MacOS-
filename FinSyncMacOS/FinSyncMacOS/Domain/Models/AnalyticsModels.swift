import Foundation

public struct TopCategoryTotal: Identifiable, Equatable, Sendable {
    public let id: String
    public let categoryName: String
    public let total: Money
}

public struct MonthlyKPI: Identifiable, Equatable, Sendable {
    public let id: String
    public let month: Date
    public let income: GroupedMoneyTotals
    public let expenses: GroupedMoneyTotals
    public let netResult: GroupedMoneyTotals
    public let topCategories: [TopCategoryTotal]
}

public enum HistoryEligibility: Equatable, Sendable {
    case insufficient
    case lowConfidence
    case normalOrHighAllowed

    public static func from(monthCount: Int) -> HistoryEligibility {
        if monthCount < 3 { return .insufficient }
        if monthCount < 12 { return .lowConfidence }
        return .normalOrHighAllowed
    }
}

public struct ForecastPresentation: Identifiable, Equatable, Sendable {
    public let id: String
    public let month: Date
    public let projectedNetResult: Money
    public let projectedBalance: Money
    public let confidence: ForecastConfidence
    public let basisSummary: String
    public let generatedAt: Date
}

