import Foundation

public struct MonthlyCategoryLine: Identifiable, Equatable, Sendable {
    public let categoryId: String
    public let categoryName: String
    public let kind: CategoryKind
    public let amount: Decimal
    public let share: Double

    public var id: String { "\(categoryId)-\(kind.rawValue)" }

    public init(categoryId: String, categoryName: String, kind: CategoryKind, amount: Decimal, share: Double) {
        self.categoryId = categoryId
        self.categoryName = categoryName
        self.kind = kind
        self.amount = amount
        self.share = share
    }
}

public struct MonthlyOverview: Equatable, Sendable {
    public let month: Date
    public let currency: CurrencyCode
    public let status: MonthlyPeriodStatus
    public let incomeTotal: Decimal
    public let expenseTotal: Decimal
    public let netResult: Decimal
    public let cardConsumption: Decimal
    public let bankConsumption: Decimal
    public let cardPaymentsTotal: Decimal
    public let categoryLines: [MonthlyCategoryLine]
    public let previousMonthExpense: Decimal?
    public let expenseDeltaVsPrevious: Decimal?
    public let expectedEndBalance: Decimal?
    public let actualEndBalance: Decimal?
    public let unreconciledDifference: Decimal?
    public let changedAfterReview: Bool
    public let changedAfterClose: Bool
    public let transactionCount: Int

    public init(
        month: Date,
        currency: CurrencyCode,
        status: MonthlyPeriodStatus,
        incomeTotal: Decimal,
        expenseTotal: Decimal,
        netResult: Decimal,
        cardConsumption: Decimal,
        bankConsumption: Decimal,
        cardPaymentsTotal: Decimal,
        categoryLines: [MonthlyCategoryLine],
        previousMonthExpense: Decimal?,
        expenseDeltaVsPrevious: Decimal?,
        expectedEndBalance: Decimal?,
        actualEndBalance: Decimal?,
        unreconciledDifference: Decimal?,
        changedAfterReview: Bool,
        changedAfterClose: Bool,
        transactionCount: Int
    ) {
        self.month = month
        self.currency = currency
        self.status = status
        self.incomeTotal = incomeTotal
        self.expenseTotal = expenseTotal
        self.netResult = netResult
        self.cardConsumption = cardConsumption
        self.bankConsumption = bankConsumption
        self.cardPaymentsTotal = cardPaymentsTotal
        self.categoryLines = categoryLines
        self.previousMonthExpense = previousMonthExpense
        self.expenseDeltaVsPrevious = expenseDeltaVsPrevious
        self.expectedEndBalance = expectedEndBalance
        self.actualEndBalance = actualEndBalance
        self.unreconciledDifference = unreconciledDifference
        self.changedAfterReview = changedAfterReview
        self.changedAfterClose = changedAfterClose
        self.transactionCount = transactionCount
    }

    public var hasUnreconciledDifference: Bool {
        guard let diff = unreconciledDifference else { return false }
        return abs(diff) >= Decimal(string: "0.01")!
    }
}
