import SwiftUI

public struct MonthlyView: View {
    private let transactions: [Transaction]
    private let classifications: [TransactionClassification]
    private let categories: [Category]
    private let accounts: [Account]
    private let periods: [MonthlyPeriod]
    private let onUpdateStatus: (MonthlyPeriod, MonthlyPeriodStatus) async throws -> Void
    @State private var selectedMonth: Date?
    @State private var isUpdatingStatus = false
    @State private var statusError: String?

    public init(
        transactions: [Transaction],
        classifications: [TransactionClassification],
        categories: [Category],
        accounts: [Account],
        periods: [MonthlyPeriod],
        onUpdateStatus: @escaping (MonthlyPeriod, MonthlyPeriodStatus) async throws -> Void = { _, _ in }
    ) {
        self.transactions = transactions
        self.classifications = classifications
        self.categories = categories
        self.accounts = accounts
        self.periods = periods
        self.onUpdateStatus = onUpdateStatus
    }

    private var currentPeriod: MonthlyPeriod? {
        guard let month = resolvedMonth else { return nil }
        let key = MonthMath.key(month)
        return periods.first { MonthMath.key($0.month) == key }
    }

    private var months: [Date] {
        MonthlyOverviewCalculator.availableMonths(transactions: transactions)
    }

    private var resolvedMonth: Date? {
        selectedMonth ?? months.first
    }

    private var overview: MonthlyOverview? {
        guard let month = resolvedMonth else { return nil }
        return MonthlyOverviewCalculator.overview(
            month: month,
            transactions: transactions,
            classifications: classifications,
            categories: categories,
            accounts: accounts,
            periods: periods
        )
    }

    public var body: some View {
        if let overview {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    header(overview)
                    if overview.changedAfterClose || overview.changedAfterReview {
                        changedAlert(overview)
                    }
                    statusControl
                    kpiStrip(overview)
                    cardVsPaymentPanel(overview)
                    if overview.hasUnreconciledDifference {
                        divergencePanel(overview)
                    }
                    categoryBreakdown(overview)
                }
                .padding(28)
            }
        } else {
            EmptyStateView(message: "Nenhuma transação para montar a visão mensal.")
                .neonCard(tint: NeonPalette.neonPurple)
                .padding(28)
        }
    }

    // MARK: - Header

    private func header(_ overview: MonthlyOverview) -> some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Mensal")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(NeonPalette.textPrimary)
                Text("Como foi o seu mês, por competência")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(NeonPalette.textTertiary)
            }
            Spacer()
            statusBadge(overview.status)
            monthPicker
        }
    }

    private var monthPicker: some View {
        Picker("Mês", selection: Binding(
            get: { resolvedMonth ?? Date() },
            set: { selectedMonth = $0 }
        )) {
            ForEach(months, id: \.self) { month in
                Text(MonthlyDateFormat.monthYear(month)).tag(month)
            }
        }
        .labelsHidden()
        .frame(maxWidth: 200)
        .accessibilityIdentifier("monthly.monthPicker")
    }

    private func statusBadge(_ status: MonthlyPeriodStatus) -> some View {
        let (label, tint): (String, Color) = {
            switch status {
            case .open: return ("Aberto", NeonPalette.neonCyan)
            case .reviewed: return ("Revisado", NeonPalette.neonMint)
            case .closed: return ("Fechado", NeonPalette.neonPurple)
            }
        }()
        return Text(label)
            .font(.system(size: 11, weight: .bold))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(tint.opacity(0.16)))
            .overlay(Capsule().strokeBorder(tint.opacity(0.45), lineWidth: 1))
            .foregroundStyle(tint)
    }

    private func changedAlert(_ overview: MonthlyOverview) -> some View {
        let message = overview.changedAfterClose
            ? "Mês fechado teve dados alterados após o fechamento. Revise os totais afetados."
            : "Mês revisado teve dados alterados após a revisão."
        return HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(NeonPalette.neonOrange)
            Text(message)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(NeonPalette.textSecondary)
            Spacer()
        }
        .neonCard(tint: NeonPalette.neonOrange, glow: 8, padding: 16)
    }

    // MARK: - Status control (US5)

    @ViewBuilder
    private var statusControl: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(NeonPalette.neonMint)
                Text("Fechamento do mês")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(NeonPalette.textPrimary)
                Spacer()
                if isUpdatingStatus {
                    ProgressView().controlSize(.small)
                }
            }
            if let period = currentPeriod {
                HStack(spacing: 10) {
                    switch period.status {
                    case .open:
                        statusButton("Marcar revisado", icon: "checkmark.circle", tint: NeonPalette.neonMint, target: .reviewed, period: period)
                        statusButton("Fechar mês", icon: "lock.fill", tint: NeonPalette.neonPurple, target: .closed, period: period)
                    case .reviewed:
                        statusButton("Fechar mês", icon: "lock.fill", tint: NeonPalette.neonPurple, target: .closed, period: period)
                        statusButton("Reabrir", icon: "lock.open", tint: NeonPalette.neonOrange, target: .open, period: period)
                    case .closed:
                        statusButton("Reabrir", icon: "lock.open", tint: NeonPalette.neonOrange, target: .open, period: period)
                    }
                    Spacer()
                }
            } else {
                Text("Mês ainda não consolidado pelo processamento. O fechamento fica disponível após o worker gerar o período mensal.")
                    .font(.system(size: 12))
                    .foregroundStyle(NeonPalette.textTertiary)
            }
            if let statusError {
                Text(statusError)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(NeonPalette.neonRed)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .neonCard(tint: NeonPalette.neonMint, glow: 8, padding: 18)
    }

    private func statusButton(_ title: String, icon: String, tint: Color, target: MonthlyPeriodStatus, period: MonthlyPeriod) -> some View {
        Button {
            Task { await updateStatus(period, to: target) }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.system(size: 12, weight: .semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(tint.opacity(0.16)))
            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(tint.opacity(0.45), lineWidth: 1))
            .foregroundStyle(tint)
        }
        .buttonStyle(.plain)
        .disabled(isUpdatingStatus)
    }

    private func updateStatus(_ period: MonthlyPeriod, to target: MonthlyPeriodStatus) async {
        isUpdatingStatus = true
        statusError = nil
        do {
            try await onUpdateStatus(period, target)
        } catch {
            statusError = "Não foi possível atualizar o status: \(error.localizedDescription)"
        }
        isUpdatingStatus = false
    }

    // MARK: - KPI Strip

    private func kpiStrip(_ overview: MonthlyOverview) -> some View {
        let columns = [GridItem(.adaptive(minimum: 200, maximum: 360), spacing: 16)]
        return LazyVGrid(columns: columns, spacing: 16) {
            kpiCard(title: "Receitas", value: currency(overview.incomeTotal, overview.currency), icon: "arrow.down.left.circle.fill", tint: NeonPalette.neonMint)
            kpiCard(title: "Despesas", value: currency(overview.expenseTotal, overview.currency), icon: "arrow.up.right.circle.fill", tint: NeonPalette.neonPink)
            kpiCard(title: "Resultado do mês", value: currency(overview.netResult, overview.currency), icon: "chart.line.uptrend.xyaxis", tint: overview.netResult < 0 ? NeonPalette.neonRed : NeonPalette.neonPurple)
            kpiCard(title: deltaTitle(overview), value: deltaValue(overview), icon: "arrow.up.arrow.down.circle.fill", tint: deltaTint(overview))
        }
    }

    private func deltaTitle(_ overview: MonthlyOverview) -> String {
        guard overview.previousMonthExpense != nil else { return "vs mês anterior" }
        return "Despesas vs mês anterior"
    }

    private func deltaValue(_ overview: MonthlyOverview) -> String {
        guard let delta = overview.expenseDeltaVsPrevious, overview.previousMonthExpense != nil else { return "—" }
        return currency(delta, overview.currency, signed: true)
    }

    private func deltaTint(_ overview: MonthlyOverview) -> Color {
        guard let delta = overview.expenseDeltaVsPrevious else { return NeonPalette.neonCyan }
        return delta > 0 ? NeonPalette.neonRed : NeonPalette.neonMint
    }

    // MARK: - Card vs payment

    private func cardVsPaymentPanel(_ overview: MonthlyOverview) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Cartão x conta x pagamento de fatura")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(NeonPalette.textPrimary)
            HStack(spacing: 16) {
                splitItem(title: "Consumo no cartão", value: overview.cardConsumption, currency: overview.currency, tint: NeonPalette.neonPink, hint: "por competência")
                splitItem(title: "Consumo em conta", value: overview.bankConsumption, currency: overview.currency, tint: NeonPalette.neonCyan, hint: "por competência")
                splitItem(title: "Pagamento de fatura", value: overview.cardPaymentsTotal, currency: overview.currency, tint: NeonPalette.neonOrange, hint: "liquidação de caixa")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .neonCard(tint: NeonPalette.neonPink, glow: 10, padding: 20)
    }

    private func splitItem(title: String, value: Decimal, currency code: CurrencyCode, tint: Color, hint: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(NeonPalette.textTertiary)
            Text(currency(value, code))
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(NeonPalette.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(hint)
                .font(.system(size: 10))
                .foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Divergence

    private func divergencePanel(_ overview: MonthlyOverview) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "scalemass.fill")
                    .foregroundStyle(NeonPalette.neonOrange)
                Text("Divergência de saldo")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(NeonPalette.textPrimary)
            }
            HStack(spacing: 16) {
                if let expected = overview.expectedEndBalance {
                    splitItem(title: "Saldo esperado", value: expected, currency: overview.currency, tint: NeonPalette.neonCyan, hint: "calculado")
                }
                if let actual = overview.actualEndBalance {
                    splitItem(title: "Saldo real", value: actual, currency: overview.currency, tint: NeonPalette.neonMint, hint: "snapshot")
                }
                if let diff = overview.unreconciledDifference {
                    splitItem(title: "Não conciliado", value: diff, currency: overview.currency, tint: NeonPalette.neonRed, hint: "diferença")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .neonCard(tint: NeonPalette.neonOrange, glow: 10, padding: 20)
    }

    // MARK: - Category breakdown

    private func categoryBreakdown(_ overview: MonthlyOverview) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Despesas por categoria")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(NeonPalette.textPrimary)
            if overview.categoryLines.isEmpty {
                Text("Nenhuma despesa categorizada neste mês.")
                    .font(.system(size: 13))
                    .foregroundStyle(NeonPalette.textTertiary)
            } else {
                ForEach(overview.categoryLines) { line in
                    categoryRow(line, currency: overview.currency)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .neonCard(tint: NeonPalette.neonPurple, glow: 10, padding: 20)
    }

    private func categoryRow(_ line: MonthlyCategoryLine, currency code: CurrencyCode) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(line.categoryName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(NeonPalette.textPrimary)
                Spacer()
                Text(currency(line.amount, code))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(NeonPalette.textPrimary)
                Text(String(format: "%.0f%%", line.share * 100))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(NeonPalette.textTertiary)
                    .frame(width: 44, alignment: .trailing)
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(NeonPalette.surfaceHigh)
                    Capsule().fill(NeonPalette.neonPurple)
                        .frame(width: max(4, proxy.size.width * line.share))
                }
            }
            .frame(height: 6)
        }
    }

    // MARK: - Shared

    private func kpiCard(title: String, value: String, icon: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                Circle().fill(tint.opacity(0.14)).frame(width: 38, height: 38)
                    .overlay(Circle().strokeBorder(tint.opacity(0.45), lineWidth: 1))
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(tint)
            }
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.6)
                .foregroundStyle(NeonPalette.textTertiary)
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(NeonPalette.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .neonCard(tint: tint, glow: 10, padding: 18)
    }

    private func currency(_ value: Decimal, _ code: CurrencyCode, signed: Bool = false) -> String {
        MoneyFormatter.string(amount: value, currency: code, signed: signed)
    }
}

enum MonthlyDateFormat {
    private static let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "LLLL yyyy"
        return formatter
    }()

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter
    }()

    static func monthYear(_ date: Date) -> String {
        monthYearFormatter.string(from: date).capitalized
    }

    static func day(_ date: Date) -> String {
        dayFormatter.string(from: date)
    }
}
