import SwiftUI

public enum AppSection: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case monthly = "Mensal"
    case imports = "Importacoes"
    case accounts = "Contas"
    case transactions = "Transacoes"
    case cards = "Cartoes"
    case balances = "Saldos"
    case review = "Revisao"
    case categories = "Categorias"
    case kpis = "KPIs"
    case forecast = "Previsao"
    case audit = "Auditoria"

    public var id: String { rawValue }

    var icon: String {
        switch self {
        case .dashboard:    return "square.grid.2x2.fill"
        case .monthly:      return "calendar"
        case .imports:      return "tray.and.arrow.down.fill"
        case .accounts:     return "creditcard.fill"
        case .transactions: return "arrow.left.arrow.right.circle.fill"
        case .cards:        return "creditcard.and.123"
        case .balances:     return "scalemass.fill"
        case .review:       return "checkmark.seal.fill"
        case .categories:   return "tag.fill"
        case .kpis:         return "chart.bar.fill"
        case .forecast:     return "chart.line.uptrend.xyaxis"
        case .audit:        return "shield.lefthalf.filled"
        }
    }

    var tint: Color {
        switch self {
        case .dashboard:    return NeonPalette.neonPurple
        case .monthly:      return NeonPalette.neonCyan
        case .imports:      return NeonPalette.neonCyan
        case .accounts:     return NeonPalette.neonMint
        case .transactions: return NeonPalette.neonPink
        case .cards:        return NeonPalette.neonPink
        case .balances:     return NeonPalette.neonMint
        case .review:       return NeonPalette.neonOrange
        case .categories:   return NeonPalette.neonCyan
        case .kpis:         return NeonPalette.neonMint
        case .forecast:     return NeonPalette.neonPurple
        case .audit:        return NeonPalette.neonOrange
        }
    }
}

public struct AppShellView: View {
    @State private var selection: AppSection = .dashboard
    @State private var snapshotState: LoadableState<FinancialSnapshot>
    @EnvironmentObject private var theme: AppTheme
    private let context: SupabaseSessionContext
    private let onLogout: () -> Void

    public init(context: SupabaseSessionContext, onLogout: @escaping () -> Void = {}) {
        self.context = context
        _snapshotState = State(initialValue: .ready(.empty(owner: context.owner)))
        self.onLogout = onLogout
    }

    public var body: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 240, ideal: 260, max: 300)
        } detail: {
            ZStack {
                NeonBackground()
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .task { await refresh() }
    }

    private var sidebar: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.dynamic(light: Color.white,                       dark: Color(red: 0.055, green: 0.067, blue: 0.122)),
                    Color.dynamic(light: DSTokens.surfaceMutedLight,        dark: Color(red: 0.039, green: 0.047, blue: 0.090))
                ],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
            .overlay(
                Rectangle()
                    .fill(DS.border)
                    .frame(width: 1)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            )

            VStack(alignment: .leading, spacing: 0) {
                brandHeader
                    .padding(.horizontal, 18)
                    .padding(.top, 22)
                    .padding(.bottom, 18)

                Divider()
                    .background(NeonPalette.stroke.opacity(0.6))
                    .padding(.horizontal, 14)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 4) {
                        sectionHeader("GERAL")
                        ForEach(AppSection.allCases) { section in
                            sidebarItem(section)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 14)
                }

                Spacer(minLength: 8)

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("APARÊNCIA")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(1.6)
                            .foregroundStyle(NeonPalette.textTertiary)
                        Spacer()
                    }
                    .padding(.horizontal, 4)
                    ThemeToggleControl(theme: theme)
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 12)

                userFooter
                    .padding(.horizontal, 14)
                    .padding(.bottom, 16)
            }
        }
    }

    private var brandHeader: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(NeonGradients.purple)
                    .frame(width: 38, height: 38)
                    .shadow(color: NeonPalette.neonPurple.opacity(0.7), radius: 12, y: 4)
                Image(systemName: "bolt.fill")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("FinSync")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(NeonPalette.textPrimary)
                Text("Controle Financeiro")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(NeonPalette.textSecondary)
            }
            Spacer()
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .bold))
            .tracking(1.6)
            .foregroundStyle(NeonPalette.textTertiary)
            .padding(.horizontal, 10)
            .padding(.bottom, 6)
    }

    private func sidebarItem(_ section: AppSection) -> some View {
        let isActive = selection == section
        return Button {
            selection = section
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(isActive ? section.tint.opacity(0.20) : NeonPalette.surface.opacity(0.6))
                        .frame(width: 30, height: 30)
                    Image(systemName: section.icon)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(isActive ? section.tint : NeonPalette.textSecondary)
                }
                Text(section.rawValue)
                    .font(.system(size: 13, weight: isActive ? .semibold : .medium))
                    .foregroundStyle(isActive ? NeonPalette.textPrimary : NeonPalette.textSecondary)
                Spacer()
                if isActive {
                    Circle()
                        .fill(section.tint)
                        .frame(width: 6, height: 6)
                        .neonGlow(section.tint, radius: 4)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(isActive ? section.tint.opacity(0.10) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .strokeBorder(isActive ? section.tint.opacity(0.35) : Color.clear, lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var userFooter: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Circle()
                    .fill(NeonGradients.cyan)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text(initials(from: context.owner.email))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    )
                    .shadow(color: NeonPalette.neonCyan.opacity(0.5), radius: 8)
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.owner.email)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(NeonPalette.textPrimary)
                        .lineLimit(1)
                    Text("Conectado")
                        .font(.system(size: 10))
                        .foregroundStyle(NeonPalette.neonMint)
                }
                Spacer(minLength: 0)
            }
            Button(action: onLogout) {
                HStack(spacing: 6) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Sair")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(NeonSecondaryButtonStyle())
            .accessibilityIdentifier("auth.logout")
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(NeonPalette.surface.opacity(0.7))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(NeonPalette.stroke, lineWidth: 1)
        )
    }

    private func initials(from email: String) -> String {
        let name = email.split(separator: "@").first.map(String.init) ?? email
        let parts = name.split(whereSeparator: { ".-_".contains($0) })
        let letters = parts.prefix(2).compactMap { $0.first }.map { String($0).uppercased() }
        return letters.joined().isEmpty ? "U" : letters.joined()
    }

    @ViewBuilder
    private var content: some View {
        switch snapshotState {
        case .idle, .loading:
            VStack(spacing: 14) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .controlSize(.large)
                    .tint(NeonPalette.neonPurple)
                Text("Carregando dados financeiros...")
                    .font(.system(size: 13))
                    .foregroundStyle(NeonPalette.textSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failed(let error):
            VStack(spacing: 14) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(NeonPalette.neonRed)
                    .neonGlow(NeonPalette.neonRed, radius: 8)
                Text("Build local: Supabase config + nullable account fix")
                    .font(.caption)
                    .foregroundStyle(NeonPalette.textSecondary)
                Text(error.localizedDescription)
                    .foregroundStyle(NeonPalette.neonRed)
                    .multilineTextAlignment(.center)
                Button("Tentar novamente") {
                    Task { await refresh() }
                }
                .buttonStyle(NeonPrimaryButtonStyle())
            }
            .padding(32)
            .neonCard(tint: NeonPalette.neonRed)
            .frame(maxWidth: 480)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .permissionDenied:
            EmptyStateView(message: "Permissao insuficiente para acessar estes dados.")
        case .sessionExpired:
            EmptyStateView(message: "Sessao expirada. Saia e entre novamente.")
        case .empty:
            EmptyStateView(message: "Nenhum dado financeiro processado.")
        case .stale(let snapshot, let message):
            sectionView(snapshot: snapshot, staleMessage: message)
        case .ready(let snapshot):
            sectionView(snapshot: snapshot, staleMessage: nil)
        }
    }

    @ViewBuilder
    private func sectionView(snapshot: FinancialSnapshot, staleMessage: String?) -> some View {
        switch selection {
        case .dashboard:
            DashboardView(
                summary: DashboardSummaryCalculator.makeSummary(
                    from: DashboardDataSet(
                        transactions: snapshot.transactions,
                        classifications: snapshot.classifications,
                        imports: snapshot.imports,
                        forecastMatrix: snapshot.forecastMatrix,
                        refreshedAt: snapshot.refreshedAt
                    ),
                    staleMessage: staleMessage
                ),
                creditCards: snapshot.accounts.filter { $0.kind == .creditCard },
                onReview: { selection = .review },
                onRefresh: { Task { await refresh() } }
            )
        case .monthly:
            MonthlyView(
                transactions: snapshot.transactions,
                classifications: snapshot.classifications,
                categories: snapshot.categories,
                accounts: snapshot.accounts,
                periods: snapshot.monthlyPeriods
            )
        case .imports:
            ImportsView(imports: snapshot.imports.map(ImportPresentation.init(file:)))
        case .accounts:
            AccountsView(accounts: snapshot.accounts)
        case .cards:
            CardsView(
                overview: CardStatementsCalculator.overview(
                    statements: snapshot.creditCardStatements,
                    transactions: snapshot.transactions,
                    accounts: snapshot.accounts,
                    obligations: snapshot.obligations
                )
            )
        case .balances:
            BalancesView(
                summary: BalanceReconciliationCalculator.summary(
                    accounts: snapshot.accounts,
                    snapshots: snapshot.balanceSnapshots,
                    statements: snapshot.creditCardStatements,
                    periods: snapshot.monthlyPeriods
                )
            )
        case .transactions:
            TransactionsView(
                transactions: snapshot.transactions,
                accounts: snapshot.accounts,
                categories: snapshot.categories,
                classifications: snapshot.classifications,
                onCategoryCorrection: { transaction, category, applyToSimilar in
                    try await SupabaseRESTClient(config: context.config).correctCategory(
                        context: context,
                        transaction: transaction,
                        category: category,
                        applyToSimilar: applyToSimilar
                    )
                    await refresh()
                }
            )
        case .review:
            ReviewView(items: reviewItems(from: snapshot), onClose: { selection = .dashboard })
        case .categories:
            CategoriesView(categories: snapshot.categories)
        case .kpis:
            KPIsView(kpis: MonthlyKPICalculator.calculate(transactions: snapshot.transactions, classifications: snapshot.classifications, categories: snapshot.categories))
        case .forecast:
            ForecastView(matrix: resolvedForecastMatrix(snapshot: snapshot))
        case .audit:
            AuditView(events: snapshot.auditEvents.map {
                AuditPresentation(
                    id: $0.id,
                    actor: $0.actorType,
                    eventType: $0.eventType,
                    entityType: $0.entityType,
                    entityId: $0.entityId,
                    metadata: $0.metadataRedacted,
                    createdAt: $0.createdAt
                )
            })
        }
    }

    private func refresh() async {
        if case .ready(let current) = snapshotState {
            snapshotState = .stale(current, message: "Atualizando...")
        } else {
            snapshotState = .loading
        }

        do {
            let client = SupabaseRESTClient(config: context.config)
            let snapshot = try await client.fetchSnapshot(context: context)
            let hasAnyData = snapshot.accounts.isEmpty == false ||
                snapshot.imports.isEmpty == false ||
                snapshot.transactions.isEmpty == false ||
                snapshot.categories.isEmpty == false ||
                snapshot.creditCardStatements.isEmpty == false ||
                snapshot.balanceSnapshots.isEmpty == false ||
                snapshot.monthlyPeriods.isEmpty == false ||
                snapshot.obligations.isEmpty == false ||
                snapshot.forecastMatrix.monthlyTotals.isEmpty == false ||
                snapshot.auditEvents.isEmpty == false
            snapshotState = hasAnyData ? .ready(snapshot) : .empty
        } catch AppError.permissionDenied {
            snapshotState = .permissionDenied
        } catch AppError.expiredSession {
            snapshotState = .sessionExpired
        } catch let error as AppError {
            snapshotState = .failed(error)
        } catch {
            snapshotState = .failed(.unknown(String(describing: error)))
        }
    }

    private func resolvedForecastMatrix(snapshot: FinancialSnapshot) -> CashFlowForecastMatrix {
        let backend = snapshot.forecastMatrix
        guard backend.categoryLines.isEmpty else { return backend }

        let startMonth = backend.months.first ?? backend.metadata.startMonth
        let monthsCount = max(backend.metadata.months, backend.months.count)
        return CashFlowMatrixCalculator.build(
            transactions: snapshot.transactions,
            classifications: snapshot.classifications,
            categories: snapshot.categories,
            startMonth: startMonth,
            months: monthsCount > 0 ? monthsCount : 12,
            defaultWindow: backend.metadata.defaultWindow
        )
    }

    private func reviewItems(from snapshot: FinancialSnapshot) -> [ReviewItem] {
        let categoriesById = Dictionary(uniqueKeysWithValues: snapshot.categories.map { ($0.id, $0) })
        let activeClassifications = Dictionary(
            uniqueKeysWithValues: snapshot.classifications.filter(\.isActive).map { ($0.transactionId, $0) }
        )

        return snapshot.transactions
            .filter { $0.reviewStatus == .needsReview }
            .map { transaction in
                let classification = activeClassifications[transaction.id]
                return ReviewItem(
                    transaction: transaction,
                    activeClassification: classification,
                    suggestedCategory: classification.flatMap { categoriesById[$0.categoryId] },
                    categories: snapshot.categories.filter(\.isActive),
                    loadedState: ReviewLoadedState(
                        transactionUpdatedAt: transaction.updatedAt,
                        reviewStatus: transaction.reviewStatus,
                        activeClassificationId: classification?.id
                    )
                )
            }
    }
}
