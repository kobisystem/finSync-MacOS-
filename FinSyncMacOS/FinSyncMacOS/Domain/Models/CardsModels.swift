import Foundation

public struct CardStatementLine: Identifiable, Equatable, Sendable {
    public let statementId: String
    public let cardAccountId: String
    public let cardName: String
    public let institutionName: String
    public let currency: CurrencyCode
    public let periodStart: Date
    public let periodEnd: Date
    public let dueDate: Date
    public let closingDate: Date?
    public let totalAmount: Decimal
    public let paidAmount: Decimal
    public let remainingAmount: Decimal
    public let status: StatementStatus
    public let isLinkedToPayment: Bool

    public var id: String { statementId }

    public init(statementId: String, cardAccountId: String, cardName: String, institutionName: String, currency: CurrencyCode, periodStart: Date, periodEnd: Date, dueDate: Date, closingDate: Date?, totalAmount: Decimal, paidAmount: Decimal, remainingAmount: Decimal, status: StatementStatus, isLinkedToPayment: Bool) {
        self.statementId = statementId
        self.cardAccountId = cardAccountId
        self.cardName = cardName
        self.institutionName = institutionName
        self.currency = currency
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.dueDate = dueDate
        self.closingDate = closingDate
        self.totalAmount = totalAmount
        self.paidAmount = paidAmount
        self.remainingAmount = remainingAmount
        self.status = status
        self.isLinkedToPayment = isLinkedToPayment
    }
}

public struct UnmatchedCardItem: Identifiable, Equatable, Sendable {
    public enum Kind: String, Equatable, Sendable {
        case payment
        case invoice
    }

    public let id: String
    public let kind: Kind
    public let title: String
    public let amount: Decimal
    public let currency: CurrencyCode
    public let date: Date

    public init(id: String, kind: Kind, title: String, amount: Decimal, currency: CurrencyCode, date: Date) {
        self.id = id
        self.kind = kind
        self.title = title
        self.amount = amount
        self.currency = currency
        self.date = date
    }
}

public struct CardsOverview: Equatable, Sendable {
    public let statements: [CardStatementLine]
    public let unmatchedPayments: [UnmatchedCardItem]
    public let unmatchedInvoices: [UnmatchedCardItem]
    public let upcomingObligations: [Obligation]

    public init(statements: [CardStatementLine], unmatchedPayments: [UnmatchedCardItem], unmatchedInvoices: [UnmatchedCardItem], upcomingObligations: [Obligation]) {
        self.statements = statements
        self.unmatchedPayments = unmatchedPayments
        self.unmatchedInvoices = unmatchedInvoices
        self.upcomingObligations = upcomingObligations
    }
}
