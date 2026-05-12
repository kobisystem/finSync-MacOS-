import Foundation

public enum MoneyFormatter {
    public static func string(amount: Decimal, currency: CurrencyCode = .brl, signed: Bool = false) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency.rawValue
        if currency.rawValue == "BRL" {
            formatter.locale = Locale(identifier: "pt_BR")
        }
        let absolute = amount < 0 ? -amount : amount
        let value = NSDecimalNumber(decimal: absolute)
        let base = formatter.string(from: value) ?? "\(currency.rawValue) \(value)"
        if signed {
            return amount < 0 ? "-\(base)" : "+\(base)"
        }
        return amount < 0 ? "-\(base)" : base
    }
}

public enum BankIconography {
    public static func brandColor(for institutionName: String) -> (gradientStart: (Double, Double, Double), gradientEnd: (Double, Double, Double)) {
        let key = institutionName.lowercased()
        if key.contains("itau") || key.contains("itaú") {
            return ((1.0, 0.553, 0.027), (0.847, 0.353, 0.027))
        }
        if key.contains("nubank") || key.contains("nu pagam") {
            return ((0.510, 0.176, 0.808), (0.310, 0.094, 0.620))
        }
        if key.contains("bradesco") {
            return ((0.812, 0.071, 0.165), (0.541, 0.027, 0.090))
        }
        if key.contains("santander") {
            return ((0.929, 0.114, 0.141), (0.612, 0.027, 0.027))
        }
        if key.contains("caixa") {
            return ((0.000, 0.435, 0.749), (0.890, 0.518, 0.000))
        }
        if key.contains("banco do brasil") || key.contains("bb") {
            return ((0.961, 0.847, 0.000), (0.000, 0.255, 0.561))
        }
        if key.contains("inter") {
            return ((1.0, 0.388, 0.0), (0.831, 0.247, 0.027))
        }
        if key.contains("c6") {
            return ((0.114, 0.114, 0.114), (0.314, 0.314, 0.314))
        }
        if key.contains("xp") {
            return ((0.0, 0.0, 0.0), (0.282, 0.282, 0.282))
        }
        if key.contains("btg") {
            return ((0.063, 0.137, 0.255), (0.122, 0.255, 0.475))
        }
        // fallback purple/cyan
        return ((0.451, 0.290, 0.945), (0.024, 0.671, 0.953))
    }

    public static func iconName(for institutionName: String, kind: AccountKind) -> String {
        switch kind {
        case .creditCard: return "creditcard.fill"
        case .bankAccount: return "building.columns.fill"
        }
    }
}
