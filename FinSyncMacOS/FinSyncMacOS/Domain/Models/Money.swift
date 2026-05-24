import Foundation

public struct CurrencyCode: RawRepresentable, Codable, Hashable, Comparable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue.uppercased()
    }

    public static let brl = CurrencyCode(rawValue: "BRL")

    public static func < (lhs: CurrencyCode, rhs: CurrencyCode) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public struct Money: Codable, Hashable, Sendable {
    public let amount: Decimal
    public let currency: CurrencyCode

    public init(amount: Decimal, currency: CurrencyCode = .brl) {
        self.amount = amount
        self.currency = currency
    }

    public static func zero(_ currency: CurrencyCode = .brl) -> Money {
        Money(amount: 0, currency: currency)
    }
}

public struct GroupedMoneyTotals: Equatable, Sendable {
    public private(set) var totals: [CurrencyCode: Decimal]

    public init(totals: [CurrencyCode: Decimal] = [:]) {
        self.totals = totals
    }

    public mutating func add(_ money: Money) {
        totals[money.currency, default: 0] += money.amount
    }

    public mutating func set(amount: Decimal, for currency: CurrencyCode) {
        totals[currency] = amount
    }

    public func amount(for currency: CurrencyCode) -> Decimal {
        totals[currency, default: 0]
    }

    public var currencies: [CurrencyCode] {
        totals.keys.sorted()
    }
}

public extension Sequence where Element == Money {
    func groupedByCurrency() -> GroupedMoneyTotals {
        reduce(into: GroupedMoneyTotals()) { result, money in
            result.add(money)
        }
    }
}
