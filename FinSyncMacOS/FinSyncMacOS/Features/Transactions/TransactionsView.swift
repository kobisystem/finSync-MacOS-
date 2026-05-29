import SwiftUI
import Foundation

public struct TransactionsView: View {
    public let transactions: [Transaction]
    public let accounts: [Account]
    public let categories: [Category]
    public let classifications: [TransactionClassification]
    public let onCategoryCorrection: (@Sendable (Transaction, Category, Bool) async throws -> Void)?

    @State private var searchText: String = ""
    @State private var filter: TransactionFilter = .all
    @State private var selectedStartDate: Date?
    @State private var selectedEndDate: Date?
    @State private var selectedMonth: Int = 0
    @State private var selectedYear: Int = 0
    @State private var selectedSource: String = "all"
    @State private var pendingCategoryCorrection: PendingCategoryCorrection?
    @State private var categoryMutationError: String?
    @State private var savingCategoryTransactionId: String?
    @State private var sortColumn: SortColumn = .date
    @State private var sortAscending: Bool = false

    public init(
        transactions: [Transaction],
        accounts: [Account] = [],
        categories: [Category] = [],
        classifications: [TransactionClassification] = [],
        onCategoryCorrection: (@Sendable (Transaction, Category, Bool) async throws -> Void)? = nil
    ) {
        self.transactions = transactions
        self.accounts = accounts
        self.categories = categories
        self.classifications = classifications
        self.onCategoryCorrection = onCategoryCorrection
    }

    private enum TransactionFilter: String, CaseIterable, Identifiable {
        case all = "Todas"
        case income = "Entradas"
        case expense = "Saídas"
        case card = "Cartões"
        var id: String { rawValue }
    }

    private enum SortColumn: String, CaseIterable {
        case date
        case account
        case description
        case category
        case amount
        case type
        case status
    }

    private var accountsById: [String: Account] {
        Dictionary(uniqueKeysWithValues: accounts.map { ($0.id, $0) })
    }

    private var categoriesById: [String: Category] {
        Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0) })
    }

    private var activeClassificationsByTransactionId: [String: TransactionClassification] {
        Dictionary(uniqueKeysWithValues: classifications.filter(\.isActive).map { ($0.transactionId, $0) })
    }

    private var filteredTransactions: [Transaction] {
        let typed: [Transaction]
        switch filter {
        case .all:
            typed = transactions
        case .income:
            typed = transactions.filter { $0.amount >= 0 || $0.transactionType == .income || $0.transactionType == .refund }
        case .expense:
            typed = transactions.filter { $0.amount < 0 || $0.transactionType == .expense || $0.transactionType == .fee }
        case .card:
            typed = transactions.filter { transaction in
                accountsById[transaction.accountId]?.kind == .creditCard || transaction.transactionType == .cardPayment
            }
        }

        let calendar = Calendar(identifier: .gregorian)
        let startDay = selectedStartDate.map { calendar.startOfDay(for: $0) }
        let endDay = selectedEndDate.map { calendar.startOfDay(for: $0) }
        let base = typed.filter { txn in
            let date = calendar.startOfDay(for: txn.postedDate ?? txn.originalDate)
            if let startDay, date < startDay { return false }
            if let endDay, date > endDay { return false }
            if selectedMonth != 0, calendar.component(.month, from: date) != selectedMonth { return false }
            if selectedYear != 0, calendar.component(.year, from: date) != selectedYear { return false }
            if matchesSelectedSource(txn) == false { return false }
            return true
        }

        let q = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        guard q.isEmpty == false else { return base }
        return base.filter { txn in
            txn.descriptionNormalized.lowercased().contains(q) ||
            txn.descriptionOriginal.lowercased().contains(q) ||
            (accountsById[txn.accountId]?.institutionName.lowercased().contains(q) ?? false) ||
            (accountsById[txn.accountId]?.displayName.lowercased().contains(q) ?? false) ||
            categoryName(for: txn).lowercased().contains(q)
        }
    }

    private var availableYears: [Int] {
        let calendar = Calendar(identifier: .gregorian)
        return Array(Set(transactions.map { calendar.component(.year, from: $0.postedDate ?? $0.originalDate) })).sorted(by: >)
    }

    private var activeAccounts: [Account] {
        accounts.sorted { lhs, rhs in
            if lhs.kind != rhs.kind { return lhs.kind.rawValue < rhs.kind.rawValue }
            return lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName) == .orderedAscending
        }
    }

    private struct PendingCategoryCorrection: Identifiable {
        let transaction: Transaction
        let category: Category
        var id: String { "\(transaction.id)-\(category.id)" }
    }

    private var sortedTransactions: [Transaction] {
        filteredTransactions.sorted { lhs, rhs in
            let comparison: ComparisonResult
            switch sortColumn {
            case .date:
                comparison = compare(lhs.postedDate ?? lhs.originalDate, rhs.postedDate ?? rhs.originalDate)
            case .account:
                comparison = compare(accountSortLabel(lhs), accountSortLabel(rhs))
            case .description:
                comparison = compare(lhs.descriptionNormalized, rhs.descriptionNormalized)
            case .category:
                comparison = compare(categoryName(for: lhs), categoryName(for: rhs))
            case .amount:
                comparison = compare(lhs.amount, rhs.amount)
            case .type:
                comparison = compare(label(for: lhs.transactionType), label(for: rhs.transactionType))
            case .status:
                comparison = compare(statusSortLabel(lhs), statusSortLabel(rhs))
            }

            if comparison == .orderedSame {
                return (lhs.postedDate ?? lhs.originalDate) > (rhs.postedDate ?? rhs.originalDate)
            }
            return sortAscending ? comparison == .orderedAscending : comparison == .orderedDescending
        }
    }

    private var totals: (income: Decimal, incomeCount: Int, expenses: Decimal, expenseCount: Int, net: Decimal, totalCount: Int) {
        var income: Decimal = 0
        var expenses: Decimal = 0
        var incomeCount = 0
        var expenseCount = 0
        for txn in filteredTransactions {
            if txn.amount >= 0 || txn.transactionType == .income || txn.transactionType == .refund {
                income += abs(txn.amount)
                incomeCount += 1
            } else {
                expenses += abs(txn.amount)
                expenseCount += 1
            }
        }
        return (income, incomeCount, expenses, expenseCount, income - expenses, filteredTransactions.count)
    }

    public var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 22) {
                header
                summaryCards
                filterBar
                if filteredTransactions.isEmpty {
                    EmptyStateView(message: transactions.isEmpty
                                   ? "Nenhuma transação encontrada."
                                   : "Nenhum resultado para os filtros aplicados.")
                        .frame(maxWidth: .infinity)
                        .neonCard(tint: NeonPalette.neonPurple)
                } else {
                    transactionsTable
                }
            }
            .padding(28)
        }
        .confirmationDialog(
            "Aplicar categoria \"\(pendingCategoryCorrection?.category.name ?? "")\"",
            isPresented: Binding(
                get: { pendingCategoryCorrection != nil },
                set: { if $0 == false { pendingCategoryCorrection = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Apenas este lançamento") {
                runPendingCategoryCorrection(applyToSimilar: false)
            }
            Button("Todos passados e futuros desta transação") {
                runPendingCategoryCorrection(applyToSimilar: true)
            }
            Button("Cancelar", role: .cancel) {
                pendingCategoryCorrection = nil
            }
        } message: {
            Text("Ao aplicar para todos, o sistema corrige lançamentos iguais já importados e cria uma regra para próximas importações.")
        }
        .alert("Não foi possível salvar a categoria", isPresented: Binding(
            get: { categoryMutationError != nil },
            set: { if $0 == false { categoryMutationError = nil } }
        )) {
            Button("OK", role: .cancel) { categoryMutationError = nil }
        } message: {
            Text(categoryMutationError ?? "")
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Transações")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(NeonPalette.textPrimary)
                HStack(spacing: 6) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 11))
                    Text("Home")
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .bold))
                    Text("Transações").foregroundStyle(NeonPalette.neonPurple)
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(NeonPalette.textTertiary)
            }
            Spacer()
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .foregroundStyle(NeonPalette.neonPurple)
                Text(periodLabel)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(NeonPalette.textSecondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(NeonPalette.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(NeonPalette.stroke, lineWidth: 1)
            )
        }
    }

    private var periodLabel: String {
        let dates = filteredTransactions.map { $0.postedDate ?? $0.originalDate }.sorted()
        guard let first = dates.first,
              let last = dates.last else {
            return "—"
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "dd MMM yyyy"
        return "\(formatter.string(from: first)) — \(formatter.string(from: last))"
    }

    private var summaryCards: some View {
        let columns = [GridItem(.adaptive(minimum: 220, maximum: 380), spacing: 18)]
        return LazyVGrid(columns: columns, spacing: 18) {
            summaryCard(title: "Entradas", amount: totals.income, signed: false, count: totals.incomeCount,
                        icon: "arrow.down.left.circle.fill", tint: NeonPalette.neonMint)
            summaryCard(title: "Saídas", amount: totals.expenses, signed: false, count: totals.expenseCount,
                        icon: "arrow.up.right.circle.fill", tint: NeonPalette.neonPink)
            summaryCard(title: "Saldo no período", amount: totals.net, signed: true, count: totals.totalCount,
                        icon: "equal.circle.fill", tint: NeonPalette.neonPurple)
        }
    }

    private func summaryCard(title: String, amount: Decimal, signed: Bool, count: Int, icon: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(tint.opacity(0.14))
                        .frame(width: 36, height: 36)
                        .overlay(Circle().strokeBorder(tint.opacity(0.45), lineWidth: 1))
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(tint)
                        .neonGlow(tint, radius: 4)
                }
                Spacer()
                Text("\(count) transações")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(NeonPalette.textSecondary)
                    .padding(.horizontal, 9).padding(.vertical, 4)
                    .background(Capsule().fill(NeonPalette.surfaceHigh))
                    .overlay(Capsule().strokeBorder(NeonPalette.stroke, lineWidth: 1))
            }
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(tint)
                .neonGlow(tint, radius: 3)
            Text(MoneyFormatter.string(amount: amount, currency: .brl, signed: signed))
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(NeonPalette.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .chromeNeonCard(tint: tint)
    }

    private var filterBar: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(NeonPalette.textTertiary)
                    TextField("Buscar por descrição, banco ou cartão", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .foregroundStyle(NeonPalette.textPrimary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(NeonPalette.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(NeonPalette.stroke, lineWidth: 1)
                )

                HStack(spacing: 6) {
                    ForEach(TransactionFilter.allCases) { item in
                        filterChip(item)
                    }
                }
            }

            HStack(spacing: 10) {
                optionalDatePicker(title: "Início", selection: $selectedStartDate)
                optionalDatePicker(title: "Fim", selection: $selectedEndDate)
                pickerPill(title: "Mês", systemImage: "calendar") {
                    Picker("Mês", selection: $selectedMonth) {
                        Text("Todos").tag(0)
                        ForEach(1...12, id: \.self) { month in
                            Text(monthName(month)).tag(month)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 128)
                }
                pickerPill(title: "Ano", systemImage: "calendar.badge.clock") {
                    Picker("Ano", selection: $selectedYear) {
                        Text("Todos").tag(0)
                        ForEach(availableYears, id: \.self) { year in
                            Text(String(year)).tag(year)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 96)
                }
                pickerPill(title: "Conta / Cartão", systemImage: "creditcard") {
                    Picker("Conta / Cartão", selection: $selectedSource) {
                        Text("Todas").tag("all")
                        Text("Só contas").tag("bank_accounts")
                        Text("Só cartões").tag("credit_cards")
                        Divider()
                        ForEach(activeAccounts) { account in
                            Text(account.displayName).tag("account:\(account.id)")
                        }
                    }
                    .labelsHidden()
                    .frame(width: 190)
                }

                Button {
                    clearAdvancedFilters()
                } label: {
                    Image(systemName: "xmark.circle")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(NeonPalette.textSecondary)
                        .frame(width: 32, height: 32)
                        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(NeonPalette.surface))
                        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(NeonPalette.stroke, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .help("Limpar filtros de período, mês, ano, conta e cartão")

                Spacer(minLength: 0)
            }
        }
    }

    private func optionalDatePicker(title: String, selection: Binding<Date?>) -> some View {
        pickerPill(title: title, systemImage: "calendar") {
            DatePicker(
                title,
                selection: Binding(
                    get: { selection.wrappedValue ?? Date() },
                    set: { selection.wrappedValue = $0 }
                ),
                displayedComponents: .date
            )
            .labelsHidden()
            .frame(width: 126)
        }
    }

    private func pickerPill<Content: View>(title: String, systemImage: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 7) {
            Image(systemName: systemImage)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(NeonPalette.textTertiary)
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(NeonPalette.textTertiary)
            content()
                .font(.system(size: 12, weight: .medium))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(NeonPalette.surface))
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(NeonPalette.stroke, lineWidth: 1))
    }

    private func clearAdvancedFilters() {
        selectedStartDate = nil
        selectedEndDate = nil
        selectedMonth = 0
        selectedYear = 0
        selectedSource = "all"
    }

    private func filterChip(_ item: TransactionFilter) -> some View {
        let isActive = filter == item
        return Button { filter = item } label: {
            Text(item.rawValue)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(isActive ? Color.white : NeonPalette.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(isActive ? AnyShapeStyle(NeonGradients.purple) : AnyShapeStyle(NeonPalette.surface))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(isActive ? NeonPalette.neonPurple.opacity(0.7) : NeonPalette.stroke, lineWidth: 1)
                )
                .shadow(color: isActive ? NeonPalette.neonPurple.opacity(0.45) : .clear, radius: 10, y: 4)
        }
        .buttonStyle(.plain)
    }

    private func matchesSelectedSource(_ txn: Transaction) -> Bool {
        guard selectedSource != "all" else { return true }
        let account = accountsById[txn.accountId]
        switch selectedSource {
        case "bank_accounts":
            return account?.kind == .bankAccount
        case "credit_cards":
            return account?.kind == .creditCard
        default:
            if selectedSource.hasPrefix("account:") {
                return txn.accountId == String(selectedSource.dropFirst("account:".count))
            }
            return true
        }
    }

    private func monthName(_ month: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.monthSymbols[max(0, min(month - 1, 11))].capitalized
    }

    private enum Col {
        static let date: CGFloat = 104
        static let account: CGFloat = 220
        static let category: CGFloat = 220
        static let value: CGFloat = 120
        static let type: CGFloat = 86
        static let status: CGFloat = 96
        static let ellipsis: CGFloat = 24
    }

    private var transactionsTable: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Movimentações")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(NeonPalette.textPrimary)
                Spacer()
                Image(systemName: "ellipsis")
                    .foregroundStyle(NeonPalette.textTertiary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            tableHeader
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(NeonPalette.surfaceHigh.opacity(0.35))

            ForEach(Array(sortedTransactions.enumerated()), id: \.element.id) { index, txn in
                transactionRow(txn)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 7)
                if index < sortedTransactions.count - 1 {
                    Divider().background(NeonPalette.stroke.opacity(0.35))
                        .padding(.horizontal, 16)
                }
            }
        }
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(NeonGradients.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(NeonPalette.stroke, lineWidth: 1)
        )
        .shadow(color: NeonPalette.neonPurple.opacity(0.18), radius: 16, y: 8)
    }

    private var tableHeader: some View {
        HStack(spacing: 16) {
            sortableColumnLabel("Data", column: .date, alignment: .leading)
                .frame(width: Col.date, alignment: .leading)
            sortableColumnLabel("Conta / Cartão", column: .account, alignment: .leading)
                .frame(width: Col.account, alignment: .leading)
            sortableColumnLabel("Descrição", column: .description, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            sortableColumnLabel("Categoria", column: .category, alignment: .leading)
                .frame(width: Col.category, alignment: .leading)
            sortableColumnLabel("Valor", column: .amount, alignment: .trailing)
                .frame(width: Col.value, alignment: .trailing)
            sortableColumnLabel("Tipo", column: .type, alignment: .center)
                .frame(width: Col.type, alignment: .center)
            sortableColumnLabel("Status", column: .status, alignment: .center)
                .frame(width: Col.status, alignment: .center)
            Color.clear.frame(width: Col.ellipsis)
        }
    }

    private func sortableColumnLabel(_ text: String, column: SortColumn, alignment: Alignment = .leading) -> some View {
        Button {
            updateSort(column)
        } label: {
            HStack(spacing: 4) {
                if alignment == .trailing { Spacer(minLength: 0) }
                Text(text)
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.6)
                    .textCase(.uppercase)
                if sortColumn == column {
                    Image(systemName: sortAscending ? "chevron.up" : "chevron.down")
                        .font(.system(size: 8, weight: .bold))
                }
                if alignment == .center || alignment == .leading { Spacer(minLength: 0) }
            }
            .foregroundStyle(sortColumn == column ? NeonPalette.neonCyan : NeonPalette.textTertiary)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func transactionRow(_ txn: Transaction) -> some View {
        let account = accountsById[txn.accountId]
        return HStack(alignment: .center, spacing: 16) {
            dateCell(txn)
                .frame(width: Col.date, alignment: .leading)

            accountCell(account: account, txn: txn)
                .frame(width: Col.account, alignment: .leading)

            descriptionCell(txn: txn)
                .frame(maxWidth: .infinity, alignment: .leading)

            categoryCell(txn: txn)
                .frame(width: Col.category, alignment: .leading)

            valueCell(txn: txn)
                .frame(width: Col.value, alignment: .trailing)

            typeCell(txn: txn)
                .frame(width: Col.type, alignment: .center)

            statusCell(txn: txn)
                .frame(width: Col.status, alignment: .center)

            Image(systemName: "ellipsis")
                .foregroundStyle(NeonPalette.textTertiary)
                .frame(width: Col.ellipsis, alignment: .center)
        }
    }

    private func updateSort(_ column: SortColumn) {
        if sortColumn == column {
            sortAscending.toggle()
        } else {
            sortColumn = column
            sortAscending = column == .amount
        }
    }

    private func compare(_ lhs: String, _ rhs: String) -> ComparisonResult {
        lhs.localizedCaseInsensitiveCompare(rhs)
    }

    private func compare(_ lhs: Date, _ rhs: Date) -> ComparisonResult {
        if lhs < rhs { return .orderedAscending }
        if lhs > rhs { return .orderedDescending }
        return .orderedSame
    }

    private func compare(_ lhs: Decimal, _ rhs: Decimal) -> ComparisonResult {
        if lhs < rhs { return .orderedAscending }
        if lhs > rhs { return .orderedDescending }
        return .orderedSame
    }

    private func accountSortLabel(_ txn: Transaction) -> String {
        guard let account = accountsById[txn.accountId] else { return "" }
        return "\(account.institutionName) \(account.displayName) \(account.maskedIdentifier)"
    }

    private func statusSortLabel(_ txn: Transaction) -> String {
        switch txn.reviewStatus {
        case .reviewed: return "Revisado"
        case .needsReview: return "Revisar"
        case .notNeeded: return "Auto"
        }
    }

    private func dateCell(_ txn: Transaction) -> some View {
        Text(dateLabel(txn.postedDate ?? txn.originalDate))
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundStyle(NeonPalette.textSecondary)
            .lineLimit(1)
    }

    private func dateLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: date)
    }

    private func categoryName(for txn: Transaction) -> String {
        guard let classification = activeClassificationsByTransactionId[txn.id],
              let category = categoriesById[classification.categoryId] else {
            return "Sem categoria"
        }
        return category.name
    }

    private func categoryCell(txn: Transaction) -> some View {
        let classification = activeClassificationsByTransactionId[txn.id]
        let label = categoryName(for: txn)
        let isMissing = classification == nil
        let isSaving = savingCategoryTransactionId == txn.id

        return Menu {
            ForEach(categories.filter(\.isActive)) { category in
                Button(category.name) {
                    pendingCategoryCorrection = PendingCategoryCorrection(transaction: txn, category: category)
                }
            }
        } label: {
            HStack(spacing: 5) {
                if isSaving {
                    ProgressView()
                        .controlSize(.mini)
                        .tint(NeonPalette.neonCyan)
                } else {
                    Image(systemName: "tag.fill")
                        .font(.system(size: 9, weight: .bold))
                }
                Text(label)
                    .lineLimit(1)
                    .fixedSize(horizontal: false, vertical: true)
                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(NeonPalette.textTertiary)
            }
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(isMissing ? NeonPalette.textTertiary : NeonPalette.neonCyan)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(Capsule().fill(isMissing ? NeonPalette.surfaceHigh : NeonPalette.neonCyan.opacity(0.12)))
            .overlay(Capsule().strokeBorder(isMissing ? NeonPalette.stroke : NeonPalette.neonCyan.opacity(0.42), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
        .disabled(categories.filter(\.isActive).isEmpty || isSaving)
    }

    private func runPendingCategoryCorrection(applyToSimilar: Bool) {
        guard let pending = pendingCategoryCorrection else { return }
        pendingCategoryCorrection = nil
        savingCategoryTransactionId = pending.transaction.id
        Task {
            do {
                try await onCategoryCorrection?(pending.transaction, pending.category, applyToSimilar)
                await MainActor.run {
                    savingCategoryTransactionId = nil
                }
            } catch {
                await MainActor.run {
                    savingCategoryTransactionId = nil
                    categoryMutationError = error.localizedDescription
                }
            }
        }
    }

    private func accountCell(account: Account?, txn: Transaction) -> some View {
        let palette = BankIconography.brandColor(for: account?.institutionName ?? "")
        let tint = Color(red: palette.gradientStart.0, green: palette.gradientStart.1, blue: palette.gradientStart.2)
        let isCard = account?.kind == .creditCard || txn.transactionType == .cardPayment || isDebitOrCardTransaction(txn)
        let icon = isCard ? "creditcard.fill" : "building.columns.fill"
        let bankLabel = account?.institutionName ?? "Conta não vinculada"
        let displayLabel = account?.displayName ?? "—"
        let masked = account?.maskedIdentifier ?? "****"

        return HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(
                        LinearGradient(colors: [tint.opacity(0.85), tint.opacity(0.55)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 30, height: 30)
                    .shadow(color: tint.opacity(0.40), radius: 6, y: 2)
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 6) {
                    Text(bankLabel)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(NeonPalette.textPrimary)
                        .lineLimit(1)
                    if isCard {
                        Text("CARTÃO")
                            .font(.system(size: 8, weight: .bold))
                            .tracking(0.6)
                            .foregroundStyle(NeonPalette.neonPink)
                            .padding(.horizontal, 5).padding(.vertical, 1)
                            .background(Capsule().fill(NeonPalette.neonPink.opacity(0.15)))
                            .overlay(Capsule().strokeBorder(NeonPalette.neonPink.opacity(0.45), lineWidth: 1))
                    }
                }
                HStack(spacing: 5) {
                    Text(displayLabel)
                        .font(.system(size: 10))
                        .foregroundStyle(NeonPalette.textSecondary)
                        .lineLimit(1)
                    Text("•").foregroundStyle(NeonPalette.textTertiary).font(.system(size: 10))
                    Text(masked)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(NeonPalette.textTertiary)
                        .lineLimit(1)
                }
            }
        }
    }

    private func isDebitOrCardTransaction(_ txn: Transaction) -> Bool {
        let description = "\(txn.descriptionNormalized) \(txn.descriptionOriginal)"
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "pt_BR"))
            .uppercased()
        return description.contains("CARTAO") ||
            description.contains("CARTAO DEBITO") ||
            description.contains("CARTAO CREDITO") ||
            description.contains("CARD")
    }

    private func descriptionCell(txn: Transaction) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(txn.descriptionNormalized.isEmpty ? txn.descriptionOriginal : txn.descriptionNormalized)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(NeonPalette.textPrimary)
                .lineLimit(1)
            if let installmentCurrent = txn.installmentCurrent, let installmentTotal = txn.installmentTotal, installmentTotal > 1 {
                Label("\(installmentCurrent)/\(installmentTotal)", systemImage: "square.stack.3d.up.fill")
                    .labelStyle(.titleAndIcon)
                    .font(.system(size: 11))
                    .foregroundStyle(NeonPalette.neonOrange)
            }
        }
    }

    private func valueCell(txn: Transaction) -> some View {
        let isNegative = txn.amount < 0
        let color = isNegative ? NeonPalette.neonPink : NeonPalette.neonMint
        return Text(MoneyFormatter.string(amount: txn.amount, currency: txn.currency, signed: true))
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
    }

    private func typeCell(txn: Transaction) -> some View {
        Text(label(for: txn.transactionType))
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(NeonPalette.textSecondary)
            .padding(.horizontal, 9).padding(.vertical, 4)
            .background(
                Capsule().fill(NeonPalette.surfaceHigh)
            )
            .overlay(
                Capsule().strokeBorder(NeonPalette.stroke, lineWidth: 1)
            )
    }

    private func statusCell(txn: Transaction) -> some View {
        switch txn.reviewStatus {
        case .reviewed:
            return AnyView(NeonStatusBadge(kind: .active, label: "Revisado"))
        case .needsReview:
            return AnyView(NeonStatusBadge(kind: .pending, label: "Revisar"))
        case .notNeeded:
            return AnyView(NeonStatusBadge(kind: .neutral, label: "Auto"))
        }
    }

    private func label(for type: TransactionType) -> String {
        switch type {
        case .income: return "Entrada"
        case .expense: return "Saída"
        case .cardPayment: return "Cartão"
        case .refund: return "Estorno"
        case .fee: return "Tarifa"
        case .transfer: return "Transferência"
        case .adjustment: return "Ajuste"
        case .unknown: return "—"
        }
    }
}
