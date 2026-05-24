import Foundation

public enum DashboardSummaryCalculator {
    public static func makeSummary(from dataSet: DashboardDataSet, staleMessage: String? = nil) -> DashboardSummary {
        var income = GroupedMoneyTotals()
        var expenses = GroupedMoneyTotals()

        for transaction in dataSet.transactions {
            switch transaction.transactionType {
            case .income, .refund:
                income.add(transaction.money)
            case .expense, .fee:
                expenses.add(transaction.money)
            case .cardPayment, .transfer, .adjustment, .unknown:
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
}
