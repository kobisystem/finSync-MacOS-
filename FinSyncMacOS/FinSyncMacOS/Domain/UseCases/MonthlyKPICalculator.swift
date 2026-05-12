import Foundation

public enum MonthlyKPICalculator {
    public static func calculate(transactions: [Transaction], classifications: [TransactionClassification], categories: [Category], calendar: Calendar = .current) -> [MonthlyKPI] {
        let grouped = Dictionary(grouping: transactions) { transaction in
            calendar.date(from: calendar.dateComponents([.year, .month], from: transaction.originalDate)) ?? transaction.originalDate
        }

        return grouped.keys.sorted().map { month in
            let monthTransactions = grouped[month, default: []]
            var income = GroupedMoneyTotals()
            var expenses = GroupedMoneyTotals()
            for transaction in monthTransactions {
                switch transaction.transactionType {
                case .income, .refund:
                    income.add(transaction.money)
                case .expense, .fee:
                    expenses.add(transaction.money)
                case .cardPayment, .transfer, .unknown:
                    continue
                }
            }
            var net = GroupedMoneyTotals()
            for currency in Set(income.currencies + expenses.currencies) {
                net.set(amount: income.amount(for: currency) - expenses.amount(for: currency), for: currency)
            }
            return MonthlyKPI(id: ISO8601DateFormatter().string(from: month), month: month, income: income, expenses: expenses, netResult: net, topCategories: [])
        }
    }
}
