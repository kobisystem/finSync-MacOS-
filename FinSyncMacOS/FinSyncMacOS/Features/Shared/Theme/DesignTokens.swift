import SwiftUI
import AppKit

// MARK: - Adaptive color helper

public extension Color {
    /// Builds a SwiftUI Color that resolves between light/dark variants based on the active appearance.
    /// Mirrors the `[data-theme="dark"]` swap from the corporate-design-system tokens.
    static func dynamic(light: Color, dark: Color) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            let match = appearance.bestMatch(from: [.aqua, .darkAqua, .vibrantLight, .vibrantDark, .accessibilityHighContrastAqua, .accessibilityHighContrastDarkAqua])
            switch match {
            case .darkAqua, .vibrantDark, .accessibilityHighContrastDarkAqua:
                return NSColor(dark)
            default:
                return NSColor(light)
            }
        })
    }

    /// Convenience hex initializer (#RRGGBB).
    init(hex: UInt32, opacity: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >>  8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }
}

// MARK: - Corporate Design System tokens (graphite + emerald)
//
// Mirrors `corporate-design-system/src/tokens/tokens.css`.
public enum DSTokens {
    // Graphite scale (theme-independent constants)
    public static let graphite50  = Color(hex: 0xF8F9FA)
    public static let graphite100 = Color(hex: 0xF2F4F5)
    public static let graphite200 = Color(hex: 0xDDE1E4)
    public static let graphite300 = Color(hex: 0xC4C9CE)
    public static let graphite500 = Color(hex: 0x7A838B)
    public static let graphite600 = Color(hex: 0x5A636B)
    public static let graphite700 = Color(hex: 0x3A4147)
    public static let graphite800 = Color(hex: 0x252A2E)
    public static let graphite900 = Color(hex: 0x1A1D1F)
    public static let graphite950 = Color(hex: 0x111315)

    // Emerald scale
    public static let emerald50  = Color(hex: 0xF1F8F5)
    public static let emerald100 = Color(hex: 0xDDEEE8)
    public static let emerald500 = Color(hex: 0x339276)
    public static let emerald600 = Color(hex: 0x28745F)
    public static let emerald700 = Color(hex: 0x1E5F4E)
    public static let emerald800 = Color(hex: 0x16483C)
    public static let emerald900 = Color(hex: 0x12382F)
    public static let emerald400Neon = Color(hex: 0x79FFD0)  // soft neon edge
    public static let emerald550Dark = Color(hex: 0x1FA36D)  // dark theme primary

    // Semantic — Light theme
    public static let bgLight              = graphite50
    public static let surfaceLight         = Color.white
    public static let surfaceRaisedLight   = Color.white
    public static let surfaceMutedLight    = graphite100
    public static let textLight            = graphite900
    public static let textMutedLight       = graphite600
    public static let textSoftLight        = graphite500
    public static let borderLight          = graphite200
    public static let borderStrongLight    = graphite300
    public static let primaryLight         = emerald700
    public static let primaryHoverLight    = emerald800
    public static let primarySoftLight     = emerald50

    // Semantic — Dark theme
    public static let bgDark              = Color(hex: 0x050606)
    public static let surfaceDark         = Color(hex: 0x0A0D0E)
    public static let surfaceRaisedDark   = Color(hex: 0x15191A)
    public static let surfaceMutedDark    = Color.white.opacity(0.04)
    public static let textDark            = Color(hex: 0xF4F7F8)
    public static let textMutedDark       = Color(hex: 0xA3A8AE)
    public static let textSoftDark        = Color(hex: 0x737B80)
    public static let borderDark          = Color.white.opacity(0.10)
    public static let borderStrongDark    = Color(hex: 0xD8DDE1, opacity: 0.24)
    public static let primaryDark         = emerald550Dark
    public static let primaryHoverDark    = Color(hex: 0x37C986)
    public static let primarySoftDark     = Color(hex: 0x1FA36D, opacity: 0.10)

    // Status
    public static let successLight = Color(hex: 0x28745F)
    public static let infoLight    = Color(hex: 0x3A6478)
    public static let warningLight = Color(hex: 0xA66A00)
    public static let errorLight   = Color(hex: 0xB42318)
    public static let warningDark  = Color(hex: 0xE7B55F)
    public static let errorDark    = Color(hex: 0xFF8A80)
}

/// Adaptive (light/dark) tokens — the “semantic” layer used by views.
public enum DS {
    // Surfaces
    public static let bg              = Color.dynamic(light: DSTokens.bgLight,            dark: DSTokens.bgDark)
    public static let surface         = Color.dynamic(light: DSTokens.surfaceLight,       dark: DSTokens.surfaceDark)
    public static let surfaceRaised   = Color.dynamic(light: DSTokens.surfaceRaisedLight, dark: DSTokens.surfaceRaisedDark)
    public static let surfaceMuted    = Color.dynamic(light: DSTokens.surfaceMutedLight,  dark: DSTokens.surfaceMutedDark)

    // Text
    public static let text            = Color.dynamic(light: DSTokens.textLight,          dark: DSTokens.textDark)
    public static let textMuted       = Color.dynamic(light: DSTokens.textMutedLight,     dark: DSTokens.textMutedDark)
    public static let textSoft        = Color.dynamic(light: DSTokens.textSoftLight,      dark: DSTokens.textSoftDark)

    // Border
    public static let border          = Color.dynamic(light: DSTokens.borderLight,        dark: DSTokens.borderDark)
    public static let borderStrong    = Color.dynamic(light: DSTokens.borderStrongLight,  dark: DSTokens.borderStrongDark)

    // Primary (emerald)
    public static let primary         = Color.dynamic(light: DSTokens.primaryLight,       dark: DSTokens.primaryDark)
    public static let primaryHover    = Color.dynamic(light: DSTokens.primaryHoverLight,  dark: DSTokens.primaryHoverDark)
    public static let primarySoft     = Color.dynamic(light: DSTokens.primarySoftLight,   dark: DSTokens.primarySoftDark)
    public static let primaryEdge     = DSTokens.emerald400Neon // neon highlight

    // Status
    public static let success         = Color.dynamic(light: DSTokens.successLight, dark: DSTokens.primaryDark)
    public static let info            = Color.dynamic(light: DSTokens.infoLight,    dark: Color(hex: 0x6FA9C2))
    public static let warning         = Color.dynamic(light: DSTokens.warningLight, dark: DSTokens.warningDark)
    public static let error           = Color.dynamic(light: DSTokens.errorLight,   dark: DSTokens.errorDark)

    // Decorative neon accents (used in moderation: KPI cards, dashboard chips, etc.)
    // These keep their identity across themes but tone down slightly in light mode.
    public static let accentCyan      = Color.dynamic(light: Color(hex: 0x0E8FA8), dark: Color(hex: 0x06D6F1))
    public static let accentMint      = Color.dynamic(light: Color(hex: 0x1FA36D), dark: Color(hex: 0x34F5C5))
    public static let accentPink      = Color.dynamic(light: Color(hex: 0xC83A77), dark: Color(hex: 0xFF4D9D))
    public static let accentOrange    = Color.dynamic(light: Color(hex: 0xC97A1F), dark: Color(hex: 0xFFB454))
    public static let accentRed       = Color.dynamic(light: Color(hex: 0xB42318), dark: Color(hex: 0xFF6068))

    // Glow tint applied behind elevated surfaces (very subtle in light mode).
    public static let glowTint        = Color.dynamic(
        light: DSTokens.emerald500.opacity(0.10),
        dark: DSTokens.primaryDark.opacity(0.18)
    )
}
