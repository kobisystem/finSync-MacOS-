import SwiftUI

public enum ThemePreference: String, CaseIterable, Identifiable, Sendable {
    case system
    case light
    case dark

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .system: return "Sistema"
        case .light:  return "Claro"
        case .dark:   return "Escuro"
        }
    }

    public var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light:  return "sun.max.fill"
        case .dark:   return "moon.fill"
        }
    }

    public var resolvedColorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}

@MainActor
public final class AppTheme: ObservableObject {
    @AppStorage("finsync.themePreference") private var stored: String = ThemePreference.system.rawValue

    public init() {}

    public var preference: ThemePreference {
        get { ThemePreference(rawValue: stored) ?? .system }
        set {
            objectWillChange.send()
            stored = newValue.rawValue
        }
    }

    public var colorScheme: ColorScheme? { preference.resolvedColorScheme }
}

public struct ThemeToggleControl: View {
    @ObservedObject var theme: AppTheme

    public init(theme: AppTheme) {
        self.theme = theme
    }

    public var body: some View {
        HStack(spacing: 4) {
            ForEach(ThemePreference.allCases) { option in
                let isActive = theme.preference == option
                Button {
                    theme.preference = option
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: option.icon)
                            .font(.system(size: 10, weight: .semibold))
                        Text(option.label)
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(isActive ? Color.white : DS.textMuted)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(isActive ? AnyShapeStyle(DS.primary) : AnyShapeStyle(Color.clear))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .strokeBorder(isActive ? DS.primary.opacity(0.55) : Color.clear, lineWidth: 1)
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(DS.surfaceMuted)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .strokeBorder(DS.border, lineWidth: 1)
        )
    }
}
