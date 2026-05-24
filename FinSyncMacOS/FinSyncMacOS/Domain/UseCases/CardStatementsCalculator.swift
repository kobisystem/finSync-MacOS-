import Foundation

/// Builds the FinSync 1.0 cards view (US3): credit-card statements with paid /
/// remaining amounts, plus review items for card payments and invoices without a
/// confident link, and upcoming card-related obligations.
public enum CardStatementsCalculator {
    public static func overview(
        statements: [CreditCardStatement],
        transactions: [Transaction],
        accounts: [Account],
        obligations: [Obligation]
    ) -> CardsOverview {
        let accountsById = Dictionary(accounts.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

        let statementLines = statements
            .map { statement -> CardStatementLine in
                let account = accountsById[statement.creditCardAccountId] ?? accountsById[statement.accountId]
                return CardStatementLine(
                    statementId: statement.id,
                    cardAccountId: statement.creditCardAccountId,
                    cardName: account?.displayName ?? "Cartão",
                    institutionName: account?.institutionName ?? "—",
                    currency: statement.currency,
                    periodStart: statement.statementPeriodStart,
                    periodEnd: statement.statementPeriodEnd,
                    dueDate: statement.dueDate,
                    closingDate: statement.closingDate,
                    totalAmount: statement.totalAmount,
                    paidAmount: statement.paidAmount,
                    remainingAmount: statement.remainingAmount,
                    status: statement.status,
                    isLinkedToPayment: statement.paidAmount > 0
                )
            }
            .sorted { $0.dueDate > $1.dueDate }

        let unmatchedPayments = transactions
            .filter { $0.transactionType == .cardPayment && ($0.creditCardStatementId == nil || $0.creditCardStatementId?.isEmpty == true) }
            .map { tx in
                UnmatchedCardItem(
                    id: tx.id,
                    kind: .payment,
                    title: tx.descriptionNormalized.isEmpty ? "Pagamento de cartão" : tx.descriptionNormalized,
                    amount: tx.amount,
                    currency: tx.currency,
                    date: tx.cashDate
                )
            }
            .sorted { $0.date > $1.date }

        let unmatchedInvoices = statements
            .filter { [.open, .partial, .unknown].contains($0.status) && $0.paidAmount <= 0 }
            .map { statement in
                let account = accountsById[statement.creditCardAccountId] ?? accountsById[statement.accountId]
                return UnmatchedCardItem(
                    id: statement.id,
                    kind: .invoice,
                    title: account?.displayName ?? "Fatura de cartão",
                    amount: statement.totalAmount,
                    currency: statement.currency,
                    date: statement.dueDate
                )
            }
            .sorted { $0.date > $1.date }

        let upcomingObligations = obligations
            .filter { $0.status == .pending && [.creditCardStatement, .installment].contains($0.sourceType) }
            .sorted { $0.dueDate < $1.dueDate }

        return CardsOverview(
            statements: statementLines,
            unmatchedPayments: unmatchedPayments,
            unmatchedInvoices: unmatchedInvoices,
            upcomingObligations: upcomingObligations
        )
    }
}
