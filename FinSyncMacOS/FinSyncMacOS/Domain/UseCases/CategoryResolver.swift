import Foundation

/// Resolves the effective spending category of a transaction, preferring an
/// active user/automated classification, then the transaction's own
/// `category_id`, and finally a synthetic "uncategorized" bucket derived from
/// the transaction type. Card payments, transfers and adjustments are not
/// consumption and resolve to `nil`.
public enum CategoryResolver {
    public struct ResolvedCategory: Equatable, Sendable {
        public let id: String
        public let name: String
        public let kind: CategoryKind

        public init(id: String, name: String, kind: CategoryKind) {
            self.id = id
            self.name = name
            self.kind = kind
        }
    }

    public static let uncategorizedIncomeId = "uncategorized-income"
    public static let uncategorizedExpenseId = "uncategorized-expense"

    public static func resolve(
        transaction: Transaction,
        activeClassification: TransactionClassification?,
        categoriesById: [String: Category]
    ) -> ResolvedCategory? {
        if let classification = activeClassification, let category = categoriesById[classification.categoryId] {
            return ResolvedCategory(id: category.id, name: category.name, kind: category.kind)
        }
        if let categoryId = transaction.categoryId, let category = categoriesById[categoryId] {
            return ResolvedCategory(id: category.id, name: category.name, kind: category.kind)
        }
        switch transaction.transactionType {
        case .income, .refund:
            return ResolvedCategory(id: uncategorizedIncomeId, name: "Sem categoria (entradas)", kind: .income)
        case .expense, .fee:
            return ResolvedCategory(id: uncategorizedExpenseId, name: "Sem categoria (saídas)", kind: .expense)
        case .cardPayment, .transfer, .adjustment, .unknown:
            return nil
        }
    }

    public static func activeClassificationMap(_ classifications: [TransactionClassification]) -> [String: TransactionClassification] {
        Dictionary(classifications.filter(\.isActive).map { ($0.transactionId, $0) }, uniquingKeysWith: { first, _ in first })
    }
}

enum MonthMath {
    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        return calendar
    }

    static func floor(_ date: Date) -> Date {
        let calendar = calendar
        return calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
    }

    static func key(_ date: Date) -> String {
        let components = calendar.dateComponents([.year, .month], from: date)
        return String(format: "%04d-%02d", components.year ?? 0, components.month ?? 0)
    }

    static func addingMonths(_ value: Int, to date: Date) -> Date {
        calendar.date(byAdding: .month, value: value, to: date) ?? date
    }
}
