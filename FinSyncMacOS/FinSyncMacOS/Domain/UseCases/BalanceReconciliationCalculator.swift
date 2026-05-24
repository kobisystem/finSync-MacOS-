import Foundation

/// Builds the FinSync 1.0 balances/net-worth view (US3): current real snapshots
/// per account, estimated net worth (assets minus open card debt) and
/// unreconciled differences between expected and real balances.
public enum BalanceReconciliationCalculator {
    public static func summary(
        accounts: [Account],
        snapshots: [BalanceSnapshot],
        statements: [CreditCardStatement],
        periods: [MonthlyPeriod],
        currency: CurrencyCode = .brl
    ) -> NetWorthSummary {
        let snapshotsByAccount = Dictionary(grouping: snapshots, by: \.accountId)

        var accountLines: [AccountBalanceLine] = []
        var totalAssets: Decimal = 0

        for account in accounts {
            let best = snapshotsByAccount[account.id].flatMap(bestSnapshot)
            let line = AccountBalanceLine(
                accountId: account.id,
                displayName: account.displayName,
                institutionName: account.institutionName,
                maskedIdentifier: account.maskedIdentifier,
                kind: account.kind,
                currency: account.currency,
                accountStatus: account.status,
                snapshotBalance: best?.balanceAmount,
                snapshotDate: best?.snapshotDate,
                snapshotSource: best?.source,
                snapshotConfidence: best?.confidence
            )
            accountLines.append(line)

            if account.kind != .creditCard, let balance = best?.balanceAmount {
                totalAssets += balance
            }
        }

        let totalCardDebt = statements
            .filter { [.open, .partial, .unknown].contains($0.status) }
            .reduce(Decimal.zero) { $0 + $1.remainingAmount }

        let unreconciled = periods
            .compactMap { period -> UnreconciledLine? in
                guard let difference = period.unreconciledDifference, abs(difference) >= Decimal(string: "0.01")! else {
                    return nil
                }
                return UnreconciledLine(
                    month: period.month,
                    expected: period.expectedEndBalance,
                    actual: period.actualEndBalance,
                    difference: difference
                )
            }
            .sorted { $0.month > $1.month }

        let sortedLines = accountLines.sorted { lhs, rhs in
            if lhs.kind == rhs.kind {
                return lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName) == .orderedAscending
            }
            return kindOrder(lhs.kind) < kindOrder(rhs.kind)
        }

        return NetWorthSummary(
            currency: currency,
            totalAssets: totalAssets,
            totalCardDebt: totalCardDebt,
            estimatedNetWorth: totalAssets - totalCardDebt,
            accountLines: sortedLines,
            unreconciled: unreconciled
        )
    }

    private static func bestSnapshot(_ snapshots: [BalanceSnapshot]) -> BalanceSnapshot? {
        snapshots.max { lhs, rhs in
            let lhsPriority = sourcePriority(lhs.source)
            let rhsPriority = sourcePriority(rhs.source)
            if lhsPriority != rhsPriority { return lhsPriority < rhsPriority }
            return lhs.snapshotDate < rhs.snapshotDate
        }
    }

    private static func sourcePriority(_ source: BalanceSnapshotSource) -> Int {
        switch source {
        case .importedStatement: return 2
        case .manual: return 1
        case .calculated: return 0
        }
    }

    private static func kindOrder(_ kind: AccountKind) -> Int {
        switch kind {
        case .bankAccount: return 0
        case .wallet: return 1
        case .investment: return 2
        case .creditCard: return 3
        }
    }
}
