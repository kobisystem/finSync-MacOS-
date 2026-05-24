import SwiftUI

public struct BalancesView: View {
    private let summary: NetWorthSummary
    private let onAddSnapshot: (_ accountId: String, _ date: Date, _ amount: Decimal) async throws -> Void

    @State private var snapshotAccountId: String = ""
    @State private var snapshotDate = Date()
    @State private var snapshotAmount = ""
    @State private var isSavingSnapshot = false
    @State private var snapshotError: String?
    @State private var snapshotSaved = false

    public init(
        summary: NetWorthSummary,
        onAddSnapshot: @escaping (_ accountId: String, _ date: Date, _ amount: Decimal) async throws -> Void = { _, _, _ in }
    ) {
        self.summary = summary
        self.onAddSnapshot = onAddSnapshot
    }

    public var body: some View {
        if summary.accountLines.isEmpty {
            EmptyStateView(message: "Nenhuma conta ou saldo disponível.")
                .neonCard(tint: NeonPalette.neonMint)
                .padding(28)
        } else {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    kpiStrip
                    accountsCard
                    manualSnapshotCard
                    if summary.unreconciled.isEmpty == false {
                        unreconciledCard
                    }
                }
                .padding(28)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Saldos")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(NeonPalette.textPrimary)
            Text("Quanto você tem e quanto deve")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(NeonPalette.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var kpiStrip: some View {
        let columns = [GridItem(.adaptive(minimum: 220, maximum: 360), spacing: 16)]
        return LazyVGrid(columns: columns, spacing: 16) {
            kpiCard(title: "Ativos (contas)", value: currency(summary.totalAssets), icon: "banknote.fill", tint: NeonPalette.neonMint)
            kpiCard(title: "Dívida de cartão", value: currency(summary.totalCardDebt), icon: "creditcard.fill", tint: NeonPalette.neonPink)
            kpiCard(title: "Patrimônio líquido estimado", value: currency(summary.estimatedNetWorth), icon: "chart.pie.fill", tint: summary.estimatedNetWorth < 0 ? NeonPalette.neonRed : NeonPalette.neonPurple)
        }
    }

    private var accountsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Saldo por conta")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(NeonPalette.textPrimary)
            ForEach(summary.accountLines) { line in
                accountRow(line)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .neonCard(tint: NeonPalette.neonMint, glow: 10, padding: 20)
    }

    private func accountRow(_ line: AccountBalanceLine) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(NeonPalette.surfaceHigh)
                    .frame(width: 34, height: 34)
                Image(systemName: BankIconography.iconName(for: line.institutionName, kind: line.kind))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(NeonPalette.neonCyan)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(line.displayName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(NeonPalette.textPrimary)
                Text("\(line.institutionName) · \(line.maskedIdentifier)")
                    .font(.system(size: 11))
                    .foregroundStyle(NeonPalette.textTertiary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                if let balance = line.snapshotBalance {
                    Text(currency(balance, line.currency))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(NeonPalette.textPrimary)
                    Text(snapshotHint(line))
                        .font(.system(size: 10))
                        .foregroundStyle(sourceTint(line.snapshotSource))
                } else {
                    Text("Sem snapshot")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(NeonPalette.textTertiary)
                }
            }
        }
        .padding(.vertical, 6)
    }

    private func snapshotHint(_ line: AccountBalanceLine) -> String {
        let source: String
        switch line.snapshotSource {
        case .importedStatement: source = "Importado"
        case .manual: source = "Manual"
        case .calculated: source = "Calculado"
        case .none: source = "—"
        }
        if let date = line.snapshotDate {
            return "\(source) · \(MonthlyDateFormat.day(date))"
        }
        return source
    }

    private func sourceTint(_ source: BalanceSnapshotSource?) -> Color {
        switch source {
        case .importedStatement: return NeonPalette.neonMint
        case .manual: return NeonPalette.neonCyan
        case .calculated: return NeonPalette.neonOrange
        case .none: return NeonPalette.textTertiary
        }
    }

    private var manualSnapshotCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "plus.viewfinder")
                    .foregroundStyle(NeonPalette.neonCyan)
                Text("Adicionar saldo manual")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(NeonPalette.textPrimary)
                Spacer()
                if isSavingSnapshot { ProgressView().controlSize(.small) }
            }
            Text("Registra uma observação de saldo. Não cria transação financeira.")
                .font(.system(size: 11))
                .foregroundStyle(NeonPalette.textTertiary)

            HStack(spacing: 12) {
                Picker("Conta", selection: $snapshotAccountId) {
                    Text("Selecione").tag("")
                    ForEach(summary.accountLines) { line in
                        Text(line.displayName).tag(line.accountId)
                    }
                }
                .labelsHidden()
                .frame(maxWidth: 220)
                .accessibilityIdentifier("balances.snapshotAccount")

                DatePicker("Data", selection: $snapshotDate, displayedComponents: .date)
                    .labelsHidden()
                    .datePickerStyle(.field)

                TextField("Valor", text: $snapshotAmount)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 140)
                    .accessibilityIdentifier("balances.snapshotAmount")

                Button("Salvar") {
                    Task { await saveSnapshot() }
                }
                .buttonStyle(NeonPrimaryButtonStyle())
                .disabled(isSavingSnapshot || snapshotAccountId.isEmpty || parsedAmount == nil)
            }

            if let snapshotError {
                Text(snapshotError)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(NeonPalette.neonRed)
            }
            if snapshotSaved {
                Text("Snapshot salvo.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(NeonPalette.neonMint)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .neonCard(tint: NeonPalette.neonCyan, glow: 10, padding: 20)
    }

    private var parsedAmount: Decimal? {
        let normalized = snapshotAmount
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespaces)
        guard normalized.isEmpty == false else { return nil }
        return Decimal(string: normalized, locale: Locale(identifier: "en_US_POSIX"))
    }

    private func saveSnapshot() async {
        guard let amount = parsedAmount, snapshotAccountId.isEmpty == false else { return }
        isSavingSnapshot = true
        snapshotError = nil
        snapshotSaved = false
        do {
            try await onAddSnapshot(snapshotAccountId, snapshotDate, amount)
            snapshotSaved = true
            snapshotAmount = ""
        } catch {
            snapshotError = "Não foi possível salvar o snapshot: \(error.localizedDescription)"
        }
        isSavingSnapshot = false
    }

    private var unreconciledCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(NeonPalette.neonOrange)
                Text("Diferenças não conciliadas")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(NeonPalette.textPrimary)
            }
            ForEach(summary.unreconciled) { line in
                HStack {
                    Text(MonthlyDateFormat.monthYear(line.month))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(NeonPalette.textPrimary)
                    Spacer()
                    if let expected = line.expected {
                        Text("Esp. \(currency(expected))")
                            .font(.system(size: 11))
                            .foregroundStyle(NeonPalette.textTertiary)
                    }
                    if let actual = line.actual {
                        Text("Real \(currency(actual))")
                            .font(.system(size: 11))
                            .foregroundStyle(NeonPalette.textTertiary)
                    }
                    Text(currency(line.difference, signed: true))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(NeonPalette.neonRed)
                }
                .padding(.vertical, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .neonCard(tint: NeonPalette.neonOrange, glow: 10, padding: 20)
    }

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

    private func currency(_ value: Decimal, _ code: CurrencyCode = .brl, signed: Bool = false) -> String {
        MoneyFormatter.string(amount: value, currency: code, signed: signed)
    }
}
