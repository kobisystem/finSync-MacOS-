import Foundation

public enum MonthlyKPICalculator {
    public static func calculate(transactions: [Transaction], classifications: [TransactionClassification], categories: [Category], accounts: [Account] = [], calendar: Calendar = .current) -> [MonthlyKPI] {
        let accountsById = Dictionary(uniqueKeysWithValues: accounts.map { ($0.id, $0) })
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
            return MonthlyKPI(id: ISO8601DateFormatter().string(from: month), month: month, income: income, expenses: expenses, netResult: net, topCategories: [])
        }
    }

    private static func normalizedMoney(from transaction: Transaction) -> Money {
        let amount = transaction.amount < 0 ? -transaction.amount : transaction.amount
        return Money(amount: amount, currency: transaction.currency)
    }
}
