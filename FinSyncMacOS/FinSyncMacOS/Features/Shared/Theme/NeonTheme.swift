import SwiftUI

// `NeonPalette` is now a thin alias over the corporate Design System (graphite + emerald)
// adaptive tokens. Saturated accents are kept as decorative tokens used in moderation
// (KPI cards, dashboard chips, status dots) per the DS readme guidance.
public enum NeonPalette {
    // Surfaces (theme-adaptive)
    public static var background: Color         { DS.bg }
    public static var backgroundElevated: Color { DS.surface }
    public static var surface: Color            { DS.surface }
    public static var surfaceHigh: Color        { DS.surfaceMuted }
    public static var stroke: Color             { DS.border }
    public static var strokeStrong: Color       { DS.borderStrong }

    // Text
    public static var textPrimary: Color        { DS.text }
    public static var textSecondary: Color      { DS.textMuted }
    public static var textTertiary: Color       { DS.textSoft }

    // Brand / primary actions — emerald per DS
    public static var neonPurple: Color         { DS.primary }
    public static var neonViolet: Color         { DS.primaryHover }

    // Decorative accents (used moderately for status / KPI variety)
    public static var neonCyan: Color           { DS.accentCyan }
    public static var neonMint: Color           { DS.accentMint }
    public static var neonPink: Color           { DS.accentPink }
    public static var neonOrange: Color         { DS.accentOrange }
    public static var neonRed: Color            { DS.accentRed }
}

public enum NeonGradients {
    /// App background. Light mode: graphite-50 → soft emerald wash.
    /// Dark mode: deep graphite with subtle emerald glow.
    public static var appBackground: LinearGradient {
        LinearGradient(
            colors: [
                Color.dynamic(light: DSTokens.bgLight,           dark: Color(hex: 0x050606)),
                Color.dynamic(light: DSTokens.surfaceMutedLight, dark: Color(hex: 0x0A0F12)),
                Color.dynamic(light: DSTokens.emerald50,         dark: Color(hex: 0x07120E))
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Surface gradient used inside cards (very subtle).
    public static var surface: LinearGradient {
        LinearGradient(
            colors: [
                Color.dynamic(light: Color.white,                 dark: Color(hex: 0x15191A)),
                Color.dynamic(light: DSTokens.surfaceMutedLight,  dark: Color(hex: 0x0A0D0E))
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // Primary CTA — emerald gradient (uses neon highlight only in dark)
    public static var purple: LinearGradient {
        LinearGradient(
            colors: [
                Color.dynamic(light: DSTokens.emerald600, dark: DSTokens.emerald400Neon),
                Color.dynamic(light: DSTokens.emerald800, dark: DSTokens.primaryDark)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    public static var cyan: LinearGradient {
        LinearGradient(
            colors: [
                Color.dynamic(light: Color(hex: 0x1F7EA8), dark: Color(hex: 0x18ABDF)),
                Color.dynamic(light: Color(hex: 0x0E8FA8), dark: Color(hex: 0x06D6F1))
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    public static var mint: LinearGradient {
        LinearGradient(
            colors: [
                Color.dynamic(light: DSTokens.emerald500, dark: Color(hex: 0x2ED4A4)),
                Color.dynamic(light: DSTokens.emerald700, dark: Color(hex: 0x34F5C5))
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    public static var pink: LinearGradient {
        LinearGradient(
            colors: [
                Color.dynamic(light: Color(hex: 0xC83A77), dark: Color(hex: 0xF74D85)),
                Color.dynamic(light: Color(hex: 0x8C2A78), dark: Color(hex: 0x9C3AE3))
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    public static var orange: LinearGradient {
        LinearGradient(
            colors: [
                Color.dynamic(light: Color(hex: 0xC97A1F), dark: Color(hex: 0xFF8E4C)),
                Color.dynamic(light: Color(hex: 0xA66A00), dark: Color(hex: 0xFFB454))
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

public struct NeonBackground: View {
    @Environment(\.colorScheme) private var scheme
    public init() {}
    public var body: some View {
        ZStack {
            NeonGradients.appBackground.ignoresSafeArea()

            // Soft brand glow — strong in dark, near-invisible in light to keep the corporate feel
            Circle()
                .fill(DSTokens.emerald400Neon.opacity(scheme == .dark ? 0.16 : 0.04))
                .frame(width: 520, height: 520)
                .blur(radius: 140)
                .offset(x: -260, y: -240)
            Circle()
                .fill(DS.accentCyan.opacity(scheme == .dark ? 0.14 : 0.05))
                .frame(width: 480, height: 480)
                .blur(radius: 160)
                .offset(x: 320, y: 280)
            Circle()
                .fill(DS.primary.opacity(scheme == .dark ? 0.12 : 0.06))
                .frame(width: 360, height: 360)
                .blur(radius: 140)
                .offset(x: 240, y: -200)
        }
        .allowsHitTesting(false)
    }
}

public struct NeonCardStyle: ViewModifier {
    public var tint: Color
    public var glow: CGFloat
    public var padding: CGFloat
    @Environment(\.colorScheme) private var scheme

    public init(tint: Color = NeonPalette.neonPurple, glow: CGFloat = 14, padding: CGFloat = 20) {
        self.tint = tint
        self.glow = glow
        self.padding = padding
    }

    public func body(content: Content) -> some View {
        let strokeStrong = scheme == .dark ? tint.opacity(0.55) : DS.border
        let strokeSoft = scheme == .dark ? tint.opacity(0.18) : DS.border
        let glowOpacity = scheme == .dark ? 0.22 : 0.06
        let shadowOpacity = scheme == .dark ? 0.45 : 0.10

        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(NeonGradients.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [strokeStrong, DS.border.opacity(0.6), strokeSoft],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: tint.opacity(glowOpacity), radius: glow, x: 0, y: 6)
            .shadow(color: .black.opacity(shadowOpacity), radius: 18, x: 0, y: 12)
    }
}

public struct NeonGradientCardStyle: ViewModifier {
    public var gradient: LinearGradient
    public var tint: Color
    public var padding: CGFloat
    @Environment(\.colorScheme) private var scheme

    public init(gradient: LinearGradient, tint: Color, padding: CGFloat = 20) {
        self.gradient = gradient
        self.tint = tint
        self.padding = padding
    }

    public func body(content: Content) -> some View {
        let glowOpacity = scheme == .dark ? 0.55 : 0.18
        let shadowOpacity = scheme == .dark ? 0.45 : 0.12

        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(gradient)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.18), .clear],
                            startPoint: .top, endPoint: .center
                        )
                    )
                    .blendMode(.plusLighter)
                    .allowsHitTesting(false)
            )
            .shadow(color: tint.opacity(glowOpacity), radius: 22, x: 0, y: 10)
            .shadow(color: .black.opacity(shadowOpacity), radius: 24, x: 0, y: 16)
    }
}

/// Dark chrome / brushed-metal background with a glowing neon border tinted by the
/// supplied accent color. Used by KPI tiles where the body should remain neutral and
/// the colour identity lives only on the icon, label and the rim glow.
public struct ChromeNeonCardStyle: ViewModifier {
    public var tint: Color
    public var padding: CGFloat
    @Environment(\.colorScheme) private var scheme

    public init(tint: Color, padding: CGFloat = 20) {
        self.tint = tint
        self.padding = padding
    }

    private var chromeFill: LinearGradient {
        // Subtle metal/chrome gradient — much darker in dark mode, near-white in light mode.
        LinearGradient(
            colors: [
                Color.dynamic(light: Color.white,                          dark: Color(hex: 0x1B2126)),
                Color.dynamic(light: DSTokens.surfaceMutedLight,           dark: Color(hex: 0x10151A)),
                Color.dynamic(light: Color(hex: 0xEDF1F3),                 dark: Color(hex: 0x080B0E))
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var highlightGradient: LinearGradient {
        // Faint specular highlight along the top edge to evoke brushed metal.
        LinearGradient(
            colors: [
                Color.white.opacity(scheme == .dark ? 0.05 : 0.55),
                Color.white.opacity(0.0)
            ],
            startPoint: .top,
            endPoint: .center
        )
    }

    public func body(content: Content) -> some View {
        let glow = scheme == .dark ? 0.45 : 0.18
        let dropShadow = scheme == .dark ? 0.50 : 0.10

        return content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(chromeFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(highlightGradient)
                    .blendMode(.plusLighter)
                    .allowsHitTesting(false)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [tint.opacity(0.85), tint.opacity(0.25), tint.opacity(0.65)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.2
                    )
            )
            .shadow(color: tint.opacity(glow), radius: 18, x: 0, y: 6)
            .shadow(color: .black.opacity(dropShadow), radius: 22, x: 0, y: 14)
    }
}

public extension View {
    func chromeNeonCard(tint: Color, padding: CGFloat = 20) -> some View {
        modifier(ChromeNeonCardStyle(tint: tint, padding: padding))
    }

    func neonCard(tint: Color = NeonPalette.neonPurple, glow: CGFloat = 14, padding: CGFloat = 20) -> some View {
        modifier(NeonCardStyle(tint: tint, glow: glow, padding: padding))
    }
    func neonGradientCard(gradient: LinearGradient, tint: Color, padding: CGFloat = 20) -> some View {
        modifier(NeonGradientCardStyle(gradient: gradient, tint: tint, padding: padding))
    }
    func neonGlow(_ color: Color, radius: CGFloat = 8) -> some View {
        shadow(color: color.opacity(0.85), radius: radius)
            .shadow(color: color.opacity(0.4), radius: radius * 2)
    }
}

public struct NeonPrimaryButtonStyle: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Color.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(NeonGradients.purple)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
            )
            .shadow(color: DS.primary.opacity(configuration.isPressed ? 0.20 : 0.45), radius: 14, y: 6)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

public struct NeonSecondaryButtonStyle: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(DS.text)
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(DS.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(DS.borderStrong.opacity(0.7), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.75 : 1.0)
    }
}

public struct NeonStatusBadge: View {
    public enum Kind { case active, pending, neutral, danger }
    public let kind: Kind
    public let label: String

    public init(kind: Kind, label: String) {
        self.kind = kind
        self.label = label
    }

    private var tint: Color {
        switch kind {
        case .active:  return DS.success
        case .pending: return DS.warning
        case .neutral: return DS.info
        case .danger:  return DS.error
        }
    }

    public var body: some View {
        HStack(spacing: 6) {
            Circle().fill(tint).frame(width: 6, height: 6).neonGlow(tint, radius: 4)
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(tint)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule().fill(tint.opacity(0.10))
        )
        .overlay(
            Capsule().strokeBorder(tint.opacity(0.45), lineWidth: 1)
        )
    }
}
