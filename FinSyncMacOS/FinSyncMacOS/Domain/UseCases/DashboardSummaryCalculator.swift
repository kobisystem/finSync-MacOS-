import Foundation

public enum DashboardSummaryCalculator {
    public static func makeSummary(from dataSet: DashboardDataSet, staleMessage: String? = nil) -> DashboardSummary {
        var income = GroupedMoneyTotals()
        var expenses = GroupedMoneyTotals()
        let accountsById = Dictionary(uniqueKeysWithValues: dataSet.accounts.map { ($0.id, $0) })

        for transaction in dataSet.transactions {
            switch transaction.transactionType {
            case .income, .refund:
                income.add(normalizedMoney(from: transaction))
            case .expense, .fee:
                guard accountsById[transaction.accountId]?.kind != .creditCard else { continue }
                expenses.add(normalizedMoney(from: transaction))
            case .cardPayment:
                expenses.add(normalizedMoney(from: transaction))
            case .transfer, .adjustment, .unknown:
                continue
            }
        }

        var net = GroupedMoneyTotals()
        for currency in Set(income.currencies + expenses.currencies) {
            net.set(amount: income.amount(for: currency) - expenses.amount(for: currency), for: currency)
        }

        let recentImports = dataSet.imports
            .sorted { $0.updatedAt > $1.updatedAt }
            .prefix(5)
            .map { RecentImportStatus(id: $0.id, fileName: $0.fileName, status: $0.status, statusMessage: $0.statusMessage, updatedAt: $0.updatedAt) }

        return DashboardSummary(
            income: income,
            expenses: expenses,
            netResult: net,
            pendingReviewCount: dataSet.transactions.filter { $0.reviewStatus == .needsReview }.count,
            recentImports: Array(recentImports),
            forecastConfidence: dataSet.forecastMatrix.monthlyTotals.first?.confidence,
            lastRefresh: LastRefreshState(refreshedAt: dataSet.refreshedAt, isStale: staleMessage != nil, message: staleMessage)
        )
    }

    private static func normalizedMoney(from transaction: Transaction) -> Money {
        let amount = transaction.amount < 0 ? -transaction.amount : transaction.amount
        return Money(amount: amount, currency: transaction.currency)
    }
}
