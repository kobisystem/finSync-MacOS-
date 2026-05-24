import SwiftUI

public struct CardsView: View {
    private let overview: CardsOverview

    public init(overview: CardsOverview) {
        self.overview = overview
    }

    private var hasContent: Bool {
        overview.statements.isEmpty == false ||
            overview.unmatchedPayments.isEmpty == false ||
            overview.unmatchedInvoices.isEmpty == false ||
            overview.upcomingObligations.isEmpty == false
    }

    public var body: some View {
        if hasContent {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    if overview.statements.isEmpty == false {
                        statementsCard
                    }
                    if overview.unmatchedPayments.isEmpty == false || overview.unmatchedInvoices.isEmpty == false {
                        reviewCard
                    }
                    if overview.upcomingObligations.isEmpty == false {
                        obligationsCard
                    }
                }
                .padding(28)
            }
        } else {
            EmptyStateView(message: "Nenhuma fatura de cartão disponível.")
                .neonCard(tint: NeonPalette.neonPink)
                .padding(28)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Cartões")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(NeonPalette.textPrimary)
            Text("Faturas, pagamentos e parcelas")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(NeonPalette.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var statementsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Faturas")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(NeonPalette.textPrimary)
            ForEach(overview.statements) { statement in
                statementRow(statement)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .neonCard(tint: NeonPalette.neonPink, glow: 10, padding: 20)
    }

    private func statementRow(_ statement: CardStatementLine) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(statement.cardName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(NeonPalette.textPrimary)
                    Text("Vence \(MonthlyDateFormat.day(statement.dueDate))")
                        .font(.system(size: 11))
                        .foregroundStyle(NeonPalette.textTertiary)
                }
                Spacer()
                statusBadge(statement.status, linked: statement.isLinkedToPayment)
            }
            HStack(spacing: 16) {
                amountColumn(title: "Total", value: statement.totalAmount, currency: statement.currency, tint: NeonPalette.textPrimary)
                amountColumn(title: "Pago", value: statement.paidAmount, currency: statement.currency, tint: NeonPalette.neonMint)
                amountColumn(title: "Restante", value: statement.remainingAmount, currency: statement.currency, tint: statement.remainingAmount > 0 ? NeonPalette.neonOrange : NeonPalette.neonMint)
            }
        }
        .padding(.vertical, 8)
        .overlay(alignment: .bottom) {
            Divider().background(NeonPalette.stroke.opacity(0.5))
        }
    }

    private func amountColumn(title: String, value: Decimal, currency code: CurrencyCode, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(NeonPalette.textTertiary)
            Text(currency(value, code))
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func statusBadge(_ status: StatementStatus, linked: Bool) -> some View {
        let (label, tint): (String, Color) = {
            switch status {
            case .open: return ("Aberta", NeonPalette.neonOrange)
            case .partial: return ("Parcial", NeonPalette.neonCyan)
            case .paid: return ("Paga", NeonPalette.neonMint)
            case .closed: return ("Fechada", NeonPalette.neonPurple)
            case .unknown: return ("Revisar", NeonPalette.neonRed)
            }
        }()
        return Text(label)
            .font(.system(size: 10, weight: .bold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(tint.opacity(0.16)))
            .overlay(Capsule().strokeBorder(tint.opacity(0.45), lineWidth: 1))
            .foregroundStyle(tint)
    }

    private var reviewCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "questionmark.circle.fill")
                    .foregroundStyle(NeonPalette.neonOrange)
                Text("Itens sem vínculo para revisar")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(NeonPalette.textPrimary)
            }
            ForEach(overview.unmatchedInvoices) { item in
                reviewRow(item, label: "Fatura sem pagamento")
            }
            ForEach(overview.unmatchedPayments) { item in
                reviewRow(item, label: "Pagamento sem fatura")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .neonCard(tint: NeonPalette.neonOrange, glow: 10, padding: 20)
    }

    private func reviewRow(_ item: UnmatchedCardItem, label: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(NeonPalette.textPrimary)
                    .lineLimit(1)
                Text("\(label) · \(MonthlyDateFormat.day(item.date))")
                    .font(.system(size: 11))
                    .foregroundStyle(NeonPalette.textTertiary)
            }
            Spacer()
            Text(currency(item.amount, item.currency))
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(NeonPalette.textPrimary)
        }
        .padding(.vertical, 4)
    }

    private var obligationsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Próximas obrigações")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(NeonPalette.textPrimary)
            ForEach(overview.upcomingObligations) { obligation in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(obligationLabel(obligation.sourceType))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(NeonPalette.textPrimary)
                        Text("Vence \(MonthlyDateFormat.day(obligation.dueDate))")
                            .font(.system(size: 11))
                            .foregroundStyle(NeonPalette.textTertiary)
                    }
                    Spacer()
                    Text(currency(obligation.amount))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(NeonPalette.neonOrange)
                }
                .padding(.vertical, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .neonCard(tint: NeonPalette.neonPurple, glow: 10, padding: 20)
    }

    private func obligationLabel(_ source: ObligationSourceType) -> String {
        switch source {
        case .creditCardStatement: return "Fatura de cartão"
        case .installment: return "Parcela"
        case .recurringExpense: return "Despesa recorrente"
        case .manual: return "Obrigação manual"
        }
    }

    private func currency(_ value: Decimal, _ code: CurrencyCode = .brl, signed: Bool = false) -> String {
        MoneyFormatter.string(amount: value, currency: code, signed: signed)
    }
}
