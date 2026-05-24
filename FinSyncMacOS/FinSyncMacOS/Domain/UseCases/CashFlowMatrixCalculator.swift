import Foundation

/// Builds a `CashFlowForecastMatrix` directly from the local transaction
/// snapshot when the backend forecast tables come back empty. Past months use
/// realized amounts; future months use the average of the last 3 completed
/// months of each category, with fallback to seasonal-last-year when 12+ months
/// of history are available.
public enum CashFlowMatrixCalculator {
    public static func build(
        transactions: [Transaction],
        classifications: [TransactionClassification],
        categories: [Category],
        startMonth: Date,
        months: Int,
        defaultWindow: Bool,
        now: Date = Date()
    ) -> CashFlowForecastMatrix {
        let calendar = gregorian
        let resolvedStart = monthFloor(startMonth, calendar: calendar)
        let horizon = CashFlowForecastMatrix.resolveMonths(start: resolvedStart, count: max(1, min(36, months)))
        let currentMonth = monthFloor(now, calendar: calendar)

        let activeClassification = Dictionary(
            uniqueKeysWithValues: classifications
                .filter(\.isActive)
                .map { ($0.transactionId, $0) }
        )
        let categoryById = Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0) })

        // Bucket: (categoryId, kind, name) -> [monthKey: realizedAmount]
        struct Bucket { let categoryId: String; let name: String; let kind: CategoryKind; var byMonth: [String: Decimal] = [:] }
        var buckets: [String: Bucket] = [:]
        var initialBalance: Decimal = 0

        for tx in transactions {
            let direction = effectiveDirection(transaction: tx, classification: activeClassification[tx.id], categoryById: categoryById)
            guard let direction else { continue }

            // Aggregate everything before the window into the initial balance.
            let txMonth = monthFloor(tx.originalDate, calendar: calendar)
            if txMonth < resolvedStart {
                initialBalance += (direction.kind == .income ? tx.amount : -tx.amount)
                continue
            }

            let categoryId = direction.categoryId
            let name = direction.name
            let bucketKey = "\(categoryId)|\(direction.kind.rawValue)"
            var bucket = buckets[bucketKey] ?? Bucket(categoryId: categoryId, name: name, kind: direction.kind)
            let key = monthKey(txMonth, calendar: calendar)
            bucket.byMonth[key, default: 0] += tx.amount
            buckets[bucketKey] = bucket
        }

        // Also fold historical buckets (months before window) into a 12-month
        // history map so we can do forecasting (last-year / 3m avg). We keep
        // pre-window aggregates separately to avoid mixing into the displayed
        // grid but still drive projections.
        var historyByBucket: [String: [String: Decimal]] = [:]
        for tx in transactions {
            let direction = effectiveDirection(transaction: tx, classification: activeClassification[tx.id], categoryById: categoryById)
            guard let direction else { continue }
            let txMonth = monthFloor(tx.originalDate, calendar: calendar)
            let bucketKey = "\(direction.categoryId)|\(direction.kind.rawValue)"
            historyByBucket[bucketKey, default: [:]][monthKey(txMonth, calendar: calendar), default: 0] += tx.amount
        }

        var categoryLines: [CashFlowForecastCategoryLine] = []
        for bucket in buckets.values {
            let bucketKey = "\(bucket.categoryId)|\(bucket.kind.rawValue)"
            let history = historyByBucket[bucketKey] ?? [:]

            for month in horizon {
                let key = monthKey(month, calendar: calendar)
                let isFuture = month > currentMonth
                let realized = bucket.byMonth[key] ?? 0

                let amount: Decimal
                let basis: ForecastCalculationBasis
                let confidence: ForecastConfidence
                let note: String?

                if !isFuture {
                    amount = realized
                    basis = .confirmedObligation
                    confidence = .high
                    note = nil
                } else {
                    let projection = project(history: history, targetMonth: month, calendar: calendar)
                    amount = projection.amount
                    basis = projection.basis
                    confidence = projection.confidence
                    note = projection.note
                }

                if amount == 0 && isFuture && history.isEmpty { continue }

                categoryLines.append(
                    CashFlowForecastCategoryLine(
                        categoryId: bucket.categoryId,
                        categoryName: bucket.name,
                        categoryKind: bucket.kind,
                        month: month,
                        projectedAmount: amount,
                        calculationBasis: basis,
                        confidence: confidence,
                        notes: note
                    )
                )
            }
        }

        // Monthly totals + accumulated balance.
        var monthlyTotals: [CashFlowForecastMonthlyTotal] = []
        var runningBalance = initialBalance
        for month in horizon {
            let key = monthKey(month, calendar: calendar)
            let monthLines = categoryLines.filter { monthKey($0.month, calendar: calendar) == key }
            let income = monthLines.filter { $0.categoryKind == .income }.reduce(Decimal.zero) { $0 + $1.projectedAmount }
            let expense = monthLines.filter { $0.categoryKind == .expense }.reduce(Decimal.zero) { $0 + $1.projectedAmount }
            let net = income - expense
            runningBalance += net

            let monthConfidence: ForecastConfidence = {
                if month <= currentMonth { return .high }
                if monthLines.contains(where: { $0.confidence == .low }) { return .low }
                if monthLines.contains(where: { $0.confidence == .normal }) { return .normal }
                return monthLines.isEmpty ? .low : .high
            }()

            monthlyTotals.append(
                CashFlowForecastMonthlyTotal(
                    month: month,
                    totalIncome: income,
                    totalExpense: expense,
                    netResult: net,
                    accumulatedBalance: runningBalance,
                    confidence: monthConfidence,
                    basisSummary: month <= currentMonth ? "Realizado" : "Projeção (média 3m / sazonal)"
                )
            )
        }

        let metadata = CashFlowForecastMetadata(
            generatedAt: now,
            startMonth: resolvedStart,
            months: horizon.count,
            initialBalance: initialBalance,
            defaultWindow: defaultWindow
        )

        return CashFlowForecastMatrix(
            metadata: metadata,
            months: horizon,
            categoryLines: categoryLines,
            monthlyTotals: monthlyTotals
        )
    }

    // MARK: - Helpers

    private struct Direction { let categoryId: String; let name: String; let kind: CategoryKind }

    private static func effectiveDirection(
        transaction: Transaction,
        classification: TransactionClassification?,
        categoryById: [String: Category]
    ) -> Direction? {
        if let classification, let category = categoryById[classification.categoryId] {
            return Direction(categoryId: category.id, name: category.name, kind: category.kind)
        }
        switch transaction.transactionType {
        case .income, .refund:
            return Direction(categoryId: "uncategorized-income", name: "Sem categoria (entradas)", kind: .income)
        case .expense, .fee:
            return Direction(categoryId: "uncategorized-expense", name: "Sem categoria (saídas)", kind: .expense)
        case .cardPayment, .transfer, .adjustment, .unknown:
            return nil
        }
    }

    private struct Projection {
        let amount: Decimal
        let basis: ForecastCalculationBasis
        let confidence: ForecastConfidence
        let note: String?
    }

    private static func project(history: [String: Decimal], targetMonth: Date, calendar: Calendar) -> Projection {
        // Seasonal last-year: same month-1y, only if 12+ months of any history.
        if history.count >= 12,
           let lastYear = calendar.date(byAdding: .year, value: -1, to: targetMonth),
           let value = history[monthKey(lastYear, calendar: calendar)],
           value > 0 {
            return Projection(amount: value, basis: .seasonalLastYear, confidence: .normal, note: "Sazonal (mesmo mês ano anterior)")
        }

        // Moving average of the last 3 completed months relative to the target.
        let lastThree: [Decimal] = (1...3).compactMap { offset -> Decimal? in
            guard let date = calendar.date(byAdding: .month, value: -offset, to: targetMonth) else { return nil }
            return history[monthKey(date, calendar: calendar)]
        }

        let nonZero = lastThree.filter { $0 > 0 }
        if nonZero.isEmpty {
            return Projection(amount: 0, basis: .noHistory, confidence: .low, note: "Sem histórico suficiente")
        }
        let sum = nonZero.reduce(Decimal.zero, +)
        var average = sum / Decimal(nonZero.count)
        var rounded = Decimal()
        NSDecimalRound(&rounded, &average, 2, .plain)
        let confidence: ForecastConfidence = history.count >= 6 ? .normal : .low
        return Projection(amount: rounded, basis: .movingAvg3m, confidence: confidence, note: history.count < 6 ? "Histórico < 6 meses" : nil)
    }

    private static var gregorian: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        return calendar
    }

    private static func monthFloor(_ date: Date, calendar: Calendar) -> Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
    }

    private static func monthKey(_ date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month], from: date)
        return String(format: "%04d-%02d", components.year ?? 0, components.month ?? 0)
    }
}
