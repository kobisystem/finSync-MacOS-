import Foundation

public struct ForecastGridRowPresentation: Identifiable, Equatable, Sendable {
    public let categoryId: String
    public let categoryName: String
    public let categoryKind: CategoryKind
    public let monthlyValues: [String: Decimal]
    public let subtotal: Decimal
    public let confidence: ForecastConfidence
    public let notes: [String]

    public var id: String { "\(categoryId)-\(categoryKind.rawValue)" }
}

public struct ForecastMatrixPresentation: Equatable, Sendable {
    public let metadata: CashFlowForecastMetadata
    public let months: [Date]
    public let rows: [ForecastGridRowPresentation]
    public let monthlyTotals: [CashFlowForecastMonthlyTotal]
}

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

    public static func presentMatrix(_ matrix: CashFlowForecastMatrix, horizonMonths: Int) -> ForecastMatrixPresentation {
        let resolvedHorizon = max(1, min(horizonMonths, matrix.months.count))
        let visibleMonths = Array(matrix.months.prefix(resolvedHorizon))
        let visibleMonthKeys = Set(visibleMonths.map(monthKey))

        var grouped: [String: [CashFlowForecastCategoryLine]] = [:]
        for line in matrix.categoryLines where visibleMonthKeys.contains(monthKey(line.month)) {
            let key = "\(line.categoryId):\(line.categoryKind.rawValue):\(line.categoryName)"
            grouped[key, default: []].append(line)
        }

        let rows: [ForecastGridRowPresentation] = grouped.compactMap { key, lines in
            let components = key.split(separator: ":", omittingEmptySubsequences: false).map(String.init)
            guard components.count >= 3 else { return nil }
            let categoryId = components[0]
            let categoryKind = CategoryKind(rawValue: components[1]) ?? .expense
            let categoryName = components.dropFirst(2).joined(separator: ":")

            var monthlyValues: [String: Decimal] = [:]
            var notes: [String] = []

            for month in visibleMonths {
                let key = monthKey(month)
                if let match = lines.first(where: { monthKey($0.month) == key }) {
                    monthlyValues[key] = match.projectedAmount
                    if let note = match.notes, note.isEmpty == false {
                        notes.append("\(key): \(note)")
                    }
                } else {
                    monthlyValues[key] = 0
                }
            }

            let subtotal = monthlyValues.values.reduce(Decimal.zero) { sum, value in
                sum + (value < 0 ? -value : value)
            }
            let confidence = mergeConfidence(lines.map(\.confidence))

            return ForecastGridRowPresentation(
                categoryId: categoryId,
                categoryName: categoryName,
                categoryKind: categoryKind,
                monthlyValues: monthlyValues,
                subtotal: subtotal,
                confidence: confidence,
                notes: notes
            )
        }
        .sorted { $0.categoryName.localizedCaseInsensitiveCompare($1.categoryName) == .orderedAscending }

        let monthTotalsByKey = Dictionary(uniqueKeysWithValues: matrix.monthlyTotals.map { (monthKey($0.month), $0) })
        let totals = visibleMonths.map { month in
            monthTotalsByKey[monthKey(month)] ?? CashFlowForecastMonthlyTotal(
                month: month,
                totalIncome: 0,
                totalExpense: 0,
                netResult: 0,
                accumulatedBalance: 0,
                confidence: .low,
                basisSummary: "Sem dados"
            )
        }

        return ForecastMatrixPresentation(metadata: matrix.metadata, months: visibleMonths, rows: rows, monthlyTotals: totals)
    }

    private static func mergeConfidence(_ values: [ForecastConfidence]) -> ForecastConfidence {
        if values.contains(.low) { return .low }
        if values.contains(.normal) { return .normal }
        return .high
    }

    private static func monthKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: date)
    }
}
