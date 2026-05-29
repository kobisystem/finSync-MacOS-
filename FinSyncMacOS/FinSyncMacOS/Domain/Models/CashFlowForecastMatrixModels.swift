import Foundation

public enum ForecastCalculationBasis: String, Codable, CaseIterable, Sendable {
    case seasonalLastYear = "seasonal_last_year"
    case movingAvg3m = "moving_avg_3m"
    case installmentSchedule = "installment_schedule"
    case confirmedActual = "confirmed_actual"
    case confirmedObligation = "confirmed_obligation"
    case noHistory = "no_history"
}

public struct CashFlowForecastMetadata: Codable, Equatable, Sendable {
    public let generatedAt: Date
    public let startMonth: Date
    public let months: Int
    public let initialBalance: Decimal
    public let defaultWindow: Bool

    public init(generatedAt: Date, startMonth: Date, months: Int, initialBalance: Decimal, defaultWindow: Bool) {
        self.generatedAt = generatedAt
        self.startMonth = startMonth
        self.months = months
        self.initialBalance = initialBalance
        self.defaultWindow = defaultWindow
    }
}

public struct CashFlowForecastCategoryLine: Codable, Identifiable, Equatable, Sendable {
    public let categoryId: String
    public let categoryName: String
    public let categoryKind: CategoryKind
    public let month: Date
    public let projectedAmount: Decimal
    public let calculationBasis: ForecastCalculationBasis
    public let confidence: ForecastConfidence
    public let notes: String?

    public var id: String { "\(categoryId)-\(month.timeIntervalSince1970)-\(categoryKind.rawValue)" }

    public init(categoryId: String, categoryName: String, categoryKind: CategoryKind, month: Date, projectedAmount: Decimal, calculationBasis: ForecastCalculationBasis, confidence: ForecastConfidence, notes: String?) {
        self.categoryId = categoryId
        self.categoryName = categoryName
        self.categoryKind = categoryKind
        self.month = month
        self.projectedAmount = projectedAmount
        self.calculationBasis = calculationBasis
        self.confidence = confidence
        self.notes = notes
    }
}

public struct CashFlowForecastMonthlyTotal: Codable, Identifiable, Equatable, Sendable {
    public let month: Date
    public let totalIncome: Decimal
    public let totalExpense: Decimal
    public let netResult: Decimal
    public let accumulatedBalance: Decimal
    public let confidence: ForecastConfidence
    public let basisSummary: String

    public var id: String { "\(month.timeIntervalSince1970)" }

    public init(month: Date, totalIncome: Decimal, totalExpense: Decimal, netResult: Decimal, accumulatedBalance: Decimal, confidence: ForecastConfidence, basisSummary: String) {
        self.month = month
        self.totalIncome = totalIncome
        self.totalExpense = totalExpense
        self.netResult = netResult
        self.accumulatedBalance = accumulatedBalance
        self.confidence = confidence
        self.basisSummary = basisSummary
    }
}

public struct CashFlowForecastMatrix: Equatable, Sendable {
    public let metadata: CashFlowForecastMetadata
    public let months: [Date]
    public let categoryLines: [CashFlowForecastCategoryLine]
    public let monthlyTotals: [CashFlowForecastMonthlyTotal]

    public init(metadata: CashFlowForecastMetadata, months: [Date], categoryLines: [CashFlowForecastCategoryLine], monthlyTotals: [CashFlowForecastMonthlyTotal]) {
        self.metadata = metadata
        self.months = months
        self.categoryLines = categoryLines
        self.monthlyTotals = monthlyTotals
    }

    public static func empty(startMonth: Date, months: Int, defaultWindow: Bool) -> CashFlowForecastMatrix {
        let period = CashFlowForecastMatrix.resolveMonths(start: startMonth, count: months)
        let metadata = CashFlowForecastMetadata(
            generatedAt: Date(),
            startMonth: startMonth,
            months: months,
            initialBalance: 0,
            defaultWindow: defaultWindow
        )
        let totals = period.map {
            CashFlowForecastMonthlyTotal(
                month: $0,
                totalIncome: 0,
                totalExpense: 0,
                netResult: 0,
                accumulatedBalance: 0,
                confidence: .low,
                basisSummary: "Sem dados"
            )
        }
        return CashFlowForecastMatrix(metadata: metadata, months: period, categoryLines: [], monthlyTotals: totals)
    }

    public static func resolveMonths(start: Date, count: Int) -> [Date] {
        let calendar = Calendar(identifier: .gregorian)
        let normalizedStart = calendar.date(from: calendar.dateComponents([.year, .month], from: start)) ?? start
        return (0..<count).compactMap { offset in
            calendar.date(byAdding: .month, value: offset, to: normalizedStart)
        }
    }
}
