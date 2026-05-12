import SwiftUI

public struct CreditCardCardView: View {
    public let account: Account
    public let accruedAmount: Decimal?
    public let balanceAmount: Decimal?
    public let blockedAmount: Decimal?
    public let validThru: String?

    public init(
        account: Account,
        accruedAmount: Decimal? = nil,
        balanceAmount: Decimal? = nil,
        blockedAmount: Decimal? = nil,
        validThru: String? = nil
    ) {
        self.account = account
        self.accruedAmount = accruedAmount
        self.balanceAmount = balanceAmount
        self.blockedAmount = blockedAmount
        self.validThru = validThru
    }

    private var gradient: LinearGradient {
        let palette = BankIconography.brandColor(for: account.institutionName)
        return LinearGradient(
            colors: [
                Color(red: palette.gradientStart.0, green: palette.gradientStart.1, blue: palette.gradientStart.2),
                Color(red: palette.gradientEnd.0, green: palette.gradientEnd.1, blue: palette.gradientEnd.2)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var tint: Color {
        let palette = BankIconography.brandColor(for: account.institutionName)
        return Color(red: palette.gradientStart.0, green: palette.gradientStart.1, blue: palette.gradientStart.2)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.white)
                        .frame(width: 46, height: 32)
                        .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
                    Image(systemName: BankIconography.iconName(for: account.institutionName, kind: account.kind))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(tint)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Card number")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.85))
                    Text(maskedNumber)
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                }
                Spacer(minLength: 0)
                Image(systemName: "ellipsis")
                    .foregroundStyle(.white.opacity(0.85))
            }

            Text(account.displayName.isEmpty ? account.institutionName : account.displayName)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.85))
                .textCase(.uppercase)
                .tracking(0.6)

            HStack(alignment: .top, spacing: 16) {
                metric(title: "Acumulado", value: accruedAmount.map { MoneyFormatter.string(amount: $0, currency: account.currency) } ?? "—")
                metric(title: "Saldo", value: balanceAmount.map { MoneyFormatter.string(amount: $0, currency: account.currency) } ?? "—")
                metric(title: "Bloqueado", value: blockedAmount.map { MoneyFormatter.string(amount: $0, currency: account.currency) } ?? "—")
                metric(title: "Validade", value: validThru ?? "—")
            }

            HStack {
                Text("Status do cartão")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.85))
                Spacer()
                NeonStatusBadge(kind: .active, label: "Ativo")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .neonGradientCard(gradient: gradient, tint: tint)
    }

    private var maskedNumber: String {
        let id = account.maskedIdentifier.replacingOccurrences(of: "*", with: "")
        let last = id.suffix(4)
        if last.isEmpty {
            return "**** **** **** ****"
        }
        return "8752**** **** \(last)"
    }

    private func metric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.80))
            Text(value)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
