import Foundation

public struct AccountBalanceLine: Identifiable, Equatable, Sendable {
    public let accountId: String
    public let displayName: String
    public let institutionName: String
    public let maskedIdentifier: String
    public let kind: AccountKind
    public let currency: CurrencyCode
    public let accountStatus: AccountStatus
    public let snapshotBalance: Decimal?
    public let snapshotDate: Date?
    public let snapshotSource: BalanceSnapshotSource?
    public let snapshotConfidence: ForecastConfidence?

    public var id: String { accountId }

    public init(accountId: String, displayName: String, institutionName: String, maskedIdentifier: String, kind: AccountKind, currency: CurrencyCode, accountStatus: AccountStatus, snapshotBalance: Decimal?, snapshotDate: Date?, snapshotSource: BalanceSnapshotSource?, snapshotConfidence: ForecastConfidence?) {
        self.accountId = accountId
        self.displayName = displayName
        self.institutionName = institutionName
        self.maskedIdentifier = maskedIdentifier
        self.kind = kind
        self.currency = currency
        self.accountStatus = accountStatus
        self.snapshotBalance = snapshotBalance
        self.snapshotDate = snapshotDate
        self.snapshotSource = snapshotSource
        self.snapshotConfidence = snapshotConfidence
    }
}

public struct UnreconciledLine: Identifiable, Equatable, Sendable {
    public let month: Date
    public let expected: Decimal?
    public let actual: Decimal?
    public let difference: Decimal

    public var id: String { MonthMath.key(month) }

    public init(month: Date, expected: Decimal?, actual: Decimal?, difference: Decimal) {
        self.month = month
        self.expected = expected
        self.actual = actual
        self.difference = difference
    }
}

public struct NetWorthSummary: Equatable, Sendable {
    public let currency: CurrencyCode
    public let totalAssets: Decimal
    public let totalCardDebt: Decimal
    public let estimatedNetWorth: Decimal
    public let accountLines: [AccountBalanceLine]
    public let unreconciled: [UnreconciledLine]

    public init(currency: CurrencyCode, totalAssets: Decimal, totalCardDebt: Decimal, estimatedNetWorth: Decimal, accountLines: [AccountBalanceLine], unreconciled: [UnreconciledLine]) {
        self.currency = currency
        self.totalAssets = totalAssets
        self.totalCardDebt = totalCardDebt
        self.estimatedNetWorth = estimatedNetWorth
        self.accountLines = accountLines
        self.unreconciled = unreconciled
    }
}
