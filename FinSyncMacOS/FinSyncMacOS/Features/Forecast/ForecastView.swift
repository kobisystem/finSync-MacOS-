import SwiftUI

public struct ForecastView: View {
    public let matrix: CashFlowForecastMatrix
    @State private var horizonMonths: Int = 12

    public init(matrix: CashFlowForecastMatrix) {
        self.matrix = matrix
    }

    private var maxHorizon: Int { max(1, min(36, matrix.months.count)) }

    private var presentation: ForecastMatrixPresentation {
        ForecastPresentationUseCase.presentMatrix(matrix, horizonMonths: horizonMonths)
    }

    private var incomeRows: [ForecastGridRowPresentation] {
        presentation.rows.filter { $0.categoryKind == .income }
    }

    private var expenseRows: [ForecastGridRowPresentation] {
        presentation.rows.filter { $0.categoryKind == .expense }
    }

    private var horizonSummary: HorizonSummary {
        let totals = presentation.monthlyTotals
        let income = totals.reduce(Decimal.zero) { $0 + $1.totalIncome }
        let expense = totals.reduce(Decimal.zero) { $0 + $1.totalExpense }
        let net = totals.reduce(Decimal.zero) { $0 + $1.netResult }
        let finalBalance = totals.last?.accumulatedBalance ?? matrix.metadata.initialBalance
        let lowConfidenceMonths = totals.filter { $0.confidence == .low }.count
        return HorizonSummary(
            totalIncome: income,
            totalExpense: expense,
            netResult: net,
            finalBalance: finalBalance,
            lowConfidenceMonths: lowConfidenceMonths
        )
    }

    public var body: some View {
        if matrix.months.isEmpty {
            EmptyStateView(message: "Sem previsão de fluxo de caixa disponível.")
                .neonCard(tint: NeonPalette.neonPurple)
                .padding(28)
        } else {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    kpiStrip
                    matrixCard
                    metadataFooter
                }
                .padding(28)
            }
            .onAppear { horizonMonths = min(12, maxHorizon) }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Previsão")
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
                    Text("Fluxo de caixa futuro")
                        .foregroundStyle(NeonPalette.neonPurple)
                }
                .font(.system(size: 12, weight: .medium))
            }
            Spacer()
            horizonControl
        }
    }

    private var horizonControl: some View {
        HStack(spacing: 10) {
            Image(systemName: "calendar.badge.clock")
                .foregroundStyle(NeonPalette.neonPurple)
            Text("Horizonte")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(NeonPalette.textSecondary)
            Stepper(value: $horizonMonths, in: 1...maxHorizon) {
                Text("\(horizonMonths) \(horizonMonths == 1 ? "mês" : "meses")")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(NeonPalette.textPrimary)
                    .frame(minWidth: 72, alignment: .leading)
                    .accessibilityIdentifier("forecast.horizon")
            }
            .labelsHidden()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(NeonPalette.surface.opacity(0.7))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(NeonPalette.stroke, lineWidth: 1)
        )
    }

    // MARK: - KPI Strip

    private var kpiStrip: some View {
        let summary = horizonSummary
        let columns = [GridItem(.adaptive(minimum: 200, maximum: 360), spacing: 16)]
        return LazyVGrid(columns: columns, spacing: 16) {
            kpiCard(
                title: "Entradas previstas",
                value: currency(summary.totalIncome),
                icon: "arrow.down.left.circle.fill",
                tint: NeonPalette.neonMint
            )
            kpiCard(
                title: "Saídas previstas",
                value: currency(summary.totalExpense),
                icon: "arrow.up.right.circle.fill",
                tint: NeonPalette.neonPink
            )
            kpiCard(
                title: "Resultado líquido",
                value: currency(summary.netResult),
                icon: "chart.line.uptrend.xyaxis",
                tint: summary.netResult < 0 ? NeonPalette.neonRed : NeonPalette.neonPurple
            )
            kpiCard(
                title: "Saldo final acumulado",
                value: currency(summary.finalBalance),
                icon: "banknote.fill",
                tint: summary.finalBalance < 0 ? NeonPalette.neonRed : NeonPalette.neonCyan
            )
        }
    }

    private func kpiCard(title: String, value: String, icon: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(tint.opacity(0.14))
                        .frame(width: 38, height: 38)
                        .overlay(Circle().strokeBorder(tint.opacity(0.45), lineWidth: 1))
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(tint)
                }
                Spacer()
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

    // MARK: - Matrix Card

    private var matrixCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text("Categorias × meses")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(NeonPalette.textPrimary)
                Spacer()
                if horizonSummary.lowConfidenceMonths > 0 {
                    confidencePill(
                        text: "\(horizonSummary.lowConfidenceMonths) mês(es) com baixa confiança",
                        tint: NeonPalette.neonOrange
                    )
                }
            }

            ScrollView([.horizontal], showsIndicators: true) {
                VStack(alignment: .leading, spacing: 0) {
                    gridHeader
                    Divider().background(NeonPalette.stroke)
                    if incomeRows.isEmpty == false {
                        groupHeader(title: "ENTRADAS", tint: NeonPalette.neonMint)
                        ForEach(Array(incomeRows.enumerated()), id: \.element.id) { index, row in
                            gridRow(row, zebra: index.isMultiple(of: 2))
                        }
                    }
                    if expenseRows.isEmpty == false {
                        groupHeader(title: "SAÍDAS", tint: NeonPalette.neonPink)
                        ForEach(Array(expenseRows.enumerated()), id: \.element.id) { index, row in
                            gridRow(row, zebra: index.isMultiple(of: 2))
                        }
                    }
                    if incomeRows.isEmpty && expenseRows.isEmpty {
                        Text("Nenhuma categoria projetada para o horizonte selecionado.")
                            .font(.system(size: 12))
                            .foregroundStyle(NeonPalette.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 16)
                    }
                    Divider().background(NeonPalette.stroke)
                    totalsRow(label: "Entradas",      values: presentation.monthlyTotals.map(\.totalIncome),  tint: NeonPalette.neonMint)
                    totalsRow(label: "Saídas",        values: presentation.monthlyTotals.map(\.totalExpense), tint: NeonPalette.neonPink)
                    totalsRow(label: "Resultado",     values: presentation.monthlyTotals.map(\.netResult),    tint: NeonPalette.neonPurple, bold: true)
                    totalsRow(label: "Saldo acumul.", values: presentation.monthlyTotals.map(\.accumulatedBalance), tint: NeonPalette.neonCyan, bold: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .neonCard(tint: NeonPalette.neonPurple, glow: 12, padding: 20)
    }

    private var gridHeader: some View {
        HStack(spacing: 0) {
            headerCell("Categoria", width: 200, alignment: .leading)
            ForEach(presentation.months, id: \.self) { month in
                headerCell(monthLabel(month).uppercased(), width: 110, alignment: .trailing)
            }
            headerCell("Subtotal", width: 120, alignment: .trailing)
            headerCell("Confiança", width: 96, alignment: .center)
        }
        .padding(.vertical, 10)
    }

    private func headerCell(_ text: String, width: CGFloat, alignment: Alignment) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .tracking(0.8)
            .foregroundStyle(NeonPalette.textTertiary)
            .frame(width: width, alignment: alignment)
            .padding(.horizontal, 6)
    }

    private func groupHeader(title: String, tint: Color) -> some View {
        HStack(spacing: 8) {
            Circle().fill(tint).frame(width: 6, height: 6).neonGlow(tint, radius: 4)
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(tint)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 8)
        .background(tint.opacity(0.06))
    }

    private func gridRow(_ row: ForecastGridRowPresentation, zebra: Bool) -> some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text(row.categoryName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(NeonPalette.textPrimary)
                    .lineLimit(1)
                if row.notes.isEmpty == false {
                    Text(row.notes.joined(separator: " • "))
                        .font(.system(size: 10))
                        .foregroundStyle(NeonPalette.textTertiary)
                        .lineLimit(1)
                }
            }
            .frame(width: 200, alignment: .leading)
            .padding(.horizontal, 6)

            ForEach(presentation.months, id: \.self) { month in
                let value = row.monthlyValues[monthKey(month)] ?? 0
                valueCell(value, width: 110, kind: row.categoryKind)
            }
            valueCell(row.subtotal, width: 120, kind: row.categoryKind, bold: true)
            HStack {
                Spacer()
                confidenceDot(row.confidence)
                Spacer()
            }
            .frame(width: 96)
        }
        .padding(.vertical, 8)
        .background(zebra ? NeonPalette.surfaceHigh.opacity(0.35) : Color.clear)
    }

    private func totalsRow(label: String, values: [Decimal], tint: Color, bold: Bool = false) -> some View {
        HStack(spacing: 0) {
            HStack(spacing: 8) {
                Circle().fill(tint).frame(width: 5, height: 5)
                Text(label)
                    .font(.system(size: 11, weight: bold ? .bold : .semibold))
                    .foregroundStyle(NeonPalette.textPrimary)
                Spacer(minLength: 0)
            }
            .frame(width: 200, alignment: .leading)
            .padding(.horizontal, 6)

            ForEach(Array(values.enumerated()), id: \.offset) { _, value in
                Text(currency(value))
                    .font(.system(size: 11, weight: bold ? .bold : .semibold, design: .rounded))
                    .foregroundStyle(value < 0 ? NeonPalette.neonRed : NeonPalette.textPrimary)
                    .frame(width: 110, alignment: .trailing)
                    .padding(.horizontal, 6)
            }
            Text(currency(values.reduce(Decimal.zero, +)))
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(NeonPalette.textPrimary)
                .frame(width: 120, alignment: .trailing)
                .padding(.horizontal, 6)
            Spacer().frame(width: 96)
        }
        .padding(.vertical, 8)
        .background(tint.opacity(0.05))
    }

    private func valueCell(_ value: Decimal, width: CGFloat, kind: CategoryKind, bold: Bool = false) -> some View {
        let isZero = value == 0
        let color: Color = {
            if isZero { return NeonPalette.textTertiary }
            if value < 0 { return NeonPalette.neonRed }
            return kind == .income ? NeonPalette.neonMint : NeonPalette.textPrimary
        }()
        return Text(isZero ? "—" : currency(value))
            .font(.system(size: 11, weight: bold ? .bold : .medium, design: .rounded))
            .foregroundStyle(color)
            .frame(width: width, alignment: .trailing)
            .padding(.horizontal, 6)
    }

    private func confidenceDot(_ value: ForecastConfidence) -> some View {
        let tint: Color = {
            switch value {
            case .high:   return NeonPalette.neonMint
            case .normal: return NeonPalette.neonCyan
            case .low:    return NeonPalette.neonOrange
            }
        }()
        return HStack(spacing: 6) {
            Circle().fill(tint).frame(width: 6, height: 6).neonGlow(tint, radius: 3)
            Text(confidenceLabel(value))
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(tint)
        }
    }

    private func confidencePill(text: String, tint: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 10, weight: .bold))
            Text(text)
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule().fill(tint.opacity(0.12))
        )
        .overlay(Capsule().strokeBorder(tint.opacity(0.4), lineWidth: 1))
    }

    // MARK: - Footer

    private var metadataFooter: some View {
        HStack(spacing: 18) {
            footerItem(icon: "clock.fill", label: "Gerado em", value: dateTime(matrix.metadata.generatedAt))
            footerItem(icon: "calendar", label: "Início", value: monthLabel(matrix.metadata.startMonth))
            footerItem(icon: "banknote", label: "Saldo inicial", value: currency(matrix.metadata.initialBalance))
            if matrix.metadata.defaultWindow {
                footerItem(icon: "checkmark.seal.fill", label: "Janela", value: "Padrão (jan–dez)")
            }
            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(NeonPalette.surface.opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(NeonPalette.stroke, lineWidth: 1)
        )
    }

    private func footerItem(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundStyle(NeonPalette.textTertiary)
            VStack(alignment: .leading, spacing: 1) {
                Text(label.uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .tracking(0.8)
                    .foregroundStyle(NeonPalette.textTertiary)
                Text(value)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(NeonPalette.textPrimary)
            }
        }
    }

    // MARK: - Formatting helpers

    private func currency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "BRL"
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: value as NSDecimalNumber) ?? "R$ 0,00"
    }

    private func monthLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "MMM/yy"
        return formatter.string(from: date)
    }

    private func dateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone.current
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func confidenceLabel(_ value: ForecastConfidence) -> String {
        switch value {
        case .low:    return "Baixa"
        case .normal: return "Média"
        case .high:   return "Alta"
        }
    }

    private func monthKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: date)
    }
}

private struct HorizonSummary {
    let totalIncome: Decimal
    let totalExpense: Decimal
    let netResult: Decimal
    let finalBalance: Decimal
    let lowConfidenceMonths: Int
}
