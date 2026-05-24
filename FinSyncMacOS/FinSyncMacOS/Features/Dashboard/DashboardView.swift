import SwiftUI

public struct DashboardView: View {
    public let summary: DashboardSummary?
    public let creditCards: [Account]
    public let onReview: () -> Void
    public let onRefresh: () -> Void

    public init(
        summary: DashboardSummary?,
        creditCards: [Account] = [],
        onReview: @escaping () -> Void = {},
        onRefresh: @escaping () -> Void = {}
    ) {
        self.summary = summary
        self.creditCards = creditCards
        self.onReview = onReview
        self.onRefresh = onRefresh
    }

    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                header
                if let summary {
                    kpiGrid(summary)
                    if creditCards.isEmpty == false {
                        cardsSection
                    }
                    HStack(alignment: .top, spacing: 20) {
                        pendenciasCard(summary)
                        forecastCard(summary)
                    }
                    if summary.recentImports.isEmpty == false {
                        recentImportsCard(summary)
                    }
                    footerInfo(summary)
                } else {
                    EmptyStateView(message: "Nenhum dado financeiro processado.")
                        .neonCard(tint: NeonPalette.neonPurple)
                }
            }
            .padding(28)
        }
        .accessibilityIdentifier(Accessibility.dashboardView)
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Dashboard")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(NeonPalette.textPrimary)
                HStack(spacing: 6) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(NeonPalette.textTertiary)
                    Text("Home")
                        .foregroundStyle(NeonPalette.textTertiary)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(NeonPalette.textTertiary)
                    Text("Dashboard")
                        .foregroundStyle(NeonPalette.neonPurple)
                }
                .font(.system(size: 12, weight: .medium))
            }
            Spacer()
            Button(action: onRefresh) {
                HStack(spacing: 7) {
                    Image(systemName: "arrow.clockwise")
                    Text("Atualizar")
                }
            }
            .buttonStyle(NeonPrimaryButtonStyle())
            .accessibilityIdentifier(Accessibility.refreshButton)
        }
    }

    private func kpiGrid(_ summary: DashboardSummary) -> some View {
        let columns = [GridItem(.adaptive(minimum: 220, maximum: 360), spacing: 20)]
        return LazyVGrid(columns: columns, spacing: 20) {
            kpiCard(
                title: "Receitas",
                value: format(summary.income),
                icon: "arrow.down.left.circle.fill",
                tint: NeonPalette.neonMint
            )
            kpiCard(
                title: "Despesas",
                value: format(summary.expenses),
                icon: "arrow.up.right.circle.fill",
                tint: NeonPalette.neonPink
            )
            kpiCard(
                title: "Resultado",
                value: format(summary.netResult),
                icon: "chart.line.uptrend.xyaxis",
                tint: NeonPalette.neonPurple
            )
            kpiCard(
                title: "Pendencias",
                value: "\(summary.pendingReviewCount)",
                icon: "checkmark.seal.fill",
                tint: NeonPalette.neonOrange
            )
        }
    }

    private func kpiCard(title: String, value: String, icon: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                ZStack {
                    Circle()
                        .fill(tint.opacity(0.14))
                        .frame(width: 38, height: 38)
                        .overlay(
                            Circle().strokeBorder(tint.opacity(0.45), lineWidth: 1)
                        )
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(tint)
                        .neonGlow(tint, radius: 4)
                }
                Spacer()
                Image(systemName: "ellipsis")
                    .foregroundStyle(NeonPalette.textTertiary)
            }
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(tint)
                .textCase(.uppercase)
                .tracking(1.2)
                .neonGlow(tint, radius: 3)
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(NeonPalette.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            HStack(spacing: 6) {
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 9, weight: .bold))
                Text("Atualizado agora")
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundStyle(NeonPalette.textSecondary)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(Capsule().fill(NeonPalette.surfaceHigh))
            .overlay(Capsule().strokeBorder(NeonPalette.stroke, lineWidth: 1))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(ChromeNeonCardStyle(tint: tint))
    }

    private var cardsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Seus cartões")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(NeonPalette.textPrimary)
                    Text("Cartões de crédito vinculados às suas contas")
                        .font(.system(size: 11))
                        .foregroundStyle(NeonPalette.textSecondary)
                }
                Spacer()
                Image(systemName: "ellipsis")
                    .foregroundStyle(NeonPalette.textTertiary)
            }
            let columns = [GridItem(.adaptive(minimum: 320, maximum: 460), spacing: 20)]
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(creditCards) { card in
                    CreditCardCardView(account: card)
                }
            }
        }
    }

    private func pendenciasCard(_ summary: DashboardSummary) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Pendências de revisão")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(NeonPalette.textPrimary)
                Spacer()
                NeonStatusBadge(
                    kind: summary.pendingReviewCount > 0 ? .pending : .active,
                    label: summary.pendingReviewCount > 0 ? "\(summary.pendingReviewCount) abertas" : "Em dia"
                )
            }
            Text(summary.pendingReviewCount > 0
                 ? "Existem transações aguardando classificação."
                 : "Nenhuma transação pendente no momento.")
                .font(.system(size: 12))
                .foregroundStyle(NeonPalette.textSecondary)
            Button(action: onReview) {
                HStack(spacing: 7) {
                    Image(systemName: "checklist")
                    Text("Revisar agora")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(NeonPrimaryButtonStyle())
            .disabled(summary.pendingReviewCount == 0)
            .opacity(summary.pendingReviewCount == 0 ? 0.55 : 1.0)
            .accessibilityIdentifier(Accessibility.reviewButton)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .neonCard(tint: NeonPalette.neonOrange)
    }

    private func forecastCard(_ summary: DashboardSummary) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Forecast")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(NeonPalette.textPrimary)
                Spacer()
                Image(systemName: "sparkles")
                    .foregroundStyle(NeonPalette.neonCyan)
                    .neonGlow(NeonPalette.neonCyan, radius: 6)
            }
            Text(summary.forecastConfidence?.rawValue.capitalized ?? "Sem previsão disponível")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(NeonPalette.textPrimary)
            Text("Confiança baseada nas últimas importações e classificações ativas.")
                .font(.system(size: 11))
                .foregroundStyle(NeonPalette.textSecondary)
                .lineLimit(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .neonCard(tint: NeonPalette.neonCyan)
    }

    private func recentImportsCard(_ summary: DashboardSummary) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Importações recentes")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(NeonPalette.textPrimary)
                Spacer()
                Image(systemName: "tray.and.arrow.down.fill")
                    .foregroundStyle(NeonPalette.neonPurple)
            }
            VStack(spacing: 0) {
                ForEach(Array(summary.recentImports.enumerated()), id: \.element.id) { index, item in
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(NeonPalette.surfaceHigh)
                                .frame(width: 32, height: 32)
                            Image(systemName: "doc.fill")
                                .font(.system(size: 13))
                                .foregroundStyle(NeonPalette.neonPurple)
                        }
                        Text(item.fileName)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(NeonPalette.textPrimary)
                            .lineLimit(1)
                        Spacer()
                        NeonStatusBadge(
                            kind: badgeKind(for: item.status),
                            label: item.status.rawValue
                        )
                    }
                    .padding(.vertical, 10)
                    if index < summary.recentImports.count - 1 {
                        Divider().background(NeonPalette.stroke.opacity(0.5))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .neonCard(tint: NeonPalette.neonPurple)
    }

    private func footerInfo(_ summary: DashboardSummary) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "clock.fill")
                .font(.system(size: 11))
                .foregroundStyle(NeonPalette.textTertiary)
            Text("Última atualização: \(summary.lastRefresh.refreshedAt?.formatted() ?? "-")")
                .font(.system(size: 11))
                .foregroundStyle(NeonPalette.textSecondary)
            if let message = summary.lastRefresh.message {
                Text("•").foregroundStyle(NeonPalette.textTertiary)
                Text(message)
                    .font(.system(size: 11))
                    .foregroundStyle(NeonPalette.neonOrange)
            }
            Spacer()
        }
    }

    private func badgeKind(for status: ImportStatus) -> NeonStatusBadge.Kind {
        switch status {
        case .processed: return .active
        case .error: return .danger
        case .processing, .pending: return .pending
        case .ignored: return .neutral
        }
    }

    private func format(_ totals: GroupedMoneyTotals) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return totals.currencies.map { currency in
            formatter.currencyCode = currency.rawValue
            let value = NSDecimalNumber(decimal: totals.amount(for: currency))
            return formatter.string(from: value) ?? "\(currency.rawValue) \(value)"
        }.joined(separator: " | ")
    }
}
