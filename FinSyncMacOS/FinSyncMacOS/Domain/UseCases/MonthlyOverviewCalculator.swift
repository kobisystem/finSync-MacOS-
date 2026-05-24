import Foundation

/// Builds the FinSync 1.0 monthly view (US1): competence-based income/expense,
/// category breakdown, credit-card consumption split from card-payment
/// settlements, previous-month comparison and balance divergence.
public enum MonthlyOverviewCalculator {
    public static func availableMonths(transactions: [Transaction]) -> [Date] {
        let months = Set(transactions.map { MonthMath.floor($0.competenceDate) })
        return months.sorted(by: >)
    }

    public static func overview(
        month: Date,
        transactions: [Transaction],
        classifications: [TransactionClassification],
        categories: [Category],
        accounts: [Account],
        periods: [MonthlyPeriod],
        currency: CurrencyCode = .brl
    ) -> MonthlyOverview {
        let targetMonth = MonthMath.floor(month)
        let targetKey = MonthMath.key(targetMonth)
        let previousKey = MonthMath.key(MonthMath.addingMonths(-1, to: targetMonth))

        let activeClassification = CategoryResolver.activeClassificationMap(classifications)
        let categoriesById = Dictionary(categories.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let accountKindById = Dictionary(accounts.map { ($0.id, $0.kind) }, uniquingKeysWith: { first, _ in first })

        var incomeTotal: Decimal = 0
        var expenseTotal: Decimal = 0
        var cardConsumption: Decimal = 0
        var bankConsumption: Decimal = 0
        var cardPaymentsTotal: Decimal = 0
        var previousMonthExpense: Decimal = 0
        var expenseByCategory: [String: (name: String, amount: Decimal)] = [:]
        var transactionCount = 0

        for tx in transactions {
            let competenceKey = MonthMath.key(tx.competenceDate)
            let cashKey = MonthMath.key(tx.cashDate)

            // Card payments are cash-settlement events, shown by cash month.
            if tx.transactionType == .cardPayment {
                if cashKey == targetKey { cardPaymentsTotal += tx.amount }
                continue
            }

            guard let resolved = CategoryResolver.resolve(
                transaction: tx,
                activeClassification: activeClassification[tx.id],
                categoriesById: categoriesById
            ) else { continue }

            if competenceKey == previousKey, resolved.kind == .expense {
                previousMonthExpense += tx.amount
            }

            guard competenceKey == targetKey else { continue }
            transactionCount += 1

            switch resolved.kind {
            case .income:
                incomeTotal += tx.amount
            case .expense:
                expenseTotal += tx.amount
                let existing = expenseByCategory[resolved.id]
                expenseByCategory[resolved.id] = (resolved.name, (existing?.amount ?? 0) + tx.amount)
                if accountKindById[tx.accountId] == .creditCard {
                    cardConsumption += tx.amount
                } else {
                    bankConsumption += tx.amount
                }
            }
        }

        let categoryLines = expenseByCategory
            .map { id, value -> MonthlyCategoryLine in
                let share = expenseTotal > 0 ? doubleValue(value.amount / expenseTotal) : 0
                return MonthlyCategoryLine(
                    categoryId: id,
                    categoryName: value.name,
                    kind: .expense,
                    amount: value.amount,
                    share: share
                )
            }
            .sorted { $0.amount > $1.amount }

        let period = periods.first { MonthMath.key($0.month) == targetKey }

        return MonthlyOverview(
            month: targetMonth,
            currency: currency,
            status: period?.status ?? .open,
            incomeTotal: incomeTotal,
            expenseTotal: expenseTotal,
            netResult: incomeTotal - expenseTotal,
            cardConsumption: cardConsumption,
            bankConsumption: bankConsumption,
            cardPaymentsTotal: cardPaymentsTotal,
            categoryLines: categoryLines,
            previousMonthExpense: previousMonthExpense,
            expenseDeltaVsPrevious: expenseTotal - previousMonthExpense,
            expectedEndBalance: period?.expectedEndBalance,
            actualEndBalance: period?.actualEndBalance,
            unreconciledDifference: period?.unreconciledDifference,
            changedAfterReview: period?.changedAfterReview ?? false,
            changedAfterClose: period?.changedAfterClose ?? false,
            transactionCount: transactionCount
        )
    }

    private static func doubleValue(_ decimal: Decimal) -> Double {
        NSDecimalNumber(decimal: decimal).doubleValue
    }
}
