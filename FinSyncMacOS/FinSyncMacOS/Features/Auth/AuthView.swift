import SwiftUI

public struct AuthView: View {
    @State private var email = "marcio777@gmail.com"
    @State private var password = "123456"
    @State private var supabaseURL: String
    @State private var publishableKey: String
    @State private var isConfigPresented = false
    @State private var emailFocused = false
    @State private var passwordFocused = false
    @FocusState private var focusedField: Field?
    public let onSignIn: (AuthRequest) -> Void

    private enum Field { case email, password }

    public init(onSignIn: @escaping (AuthRequest) -> Void = { _ in }) {
        let saved = SupabaseConfigStore.load()
        _supabaseURL = State(initialValue: saved.url)
        _publishableKey = State(initialValue: saved.publishableKey)
        self.onSignIn = onSignIn
    }

    public var body: some View {
        ZStack {
            NeonBackground()
            decorativeShapes
            card
                .frame(maxWidth: 420)
                .padding(40)
        }
        .frame(minWidth: 880, minHeight: 620)
        .accessibilityIdentifier(Accessibility.authView)
        .sheet(isPresented: $isConfigPresented) {
            SupabaseConfigurationView(
                supabaseURL: $supabaseURL,
                publishableKey: $publishableKey,
                onSave: {
                    SupabaseConfigStore.save(SavedSupabaseConfig(url: supabaseURL, publishableKey: publishableKey))
                    isConfigPresented = false
                }
            )
        }
    }

    private var decorativeShapes: some View {
        ZStack {
            // Soft ambient glow — kept very faint so the card stays the focal point
            Circle()
                .fill(NeonPalette.neonCyan.opacity(0.18))
                .frame(width: 260, height: 260)
                .blur(radius: 140)
                .offset(x: -300, y: -160)
            Circle()
                .fill(NeonPalette.neonPurple.opacity(0.20))
                .frame(width: 300, height: 300)
                .blur(radius: 160)
                .offset(x: 280, y: 140)
        }
        .allowsHitTesting(false)
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 22) {
            brand
            heading
            configChip
            VStack(alignment: .leading, spacing: 14) {
                neonField(
                    title: "Usuário",
                    icon: "envelope.fill",
                    text: $email,
                    secure: false,
                    field: .email,
                    accentLeft: NeonPalette.neonCyan,
                    accentRight: NeonPalette.neonPurple
                )
                neonField(
                    title: "Senha",
                    icon: "lock.fill",
                    text: $password,
                    secure: true,
                    field: .password,
                    accentLeft: NeonPalette.neonPurple,
                    accentRight: NeonPalette.neonPink
                )
            }
            HStack {
                rememberToggle
                Spacer()
                Button(action: {}) {
                    Text("Esqueceu a senha?")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(NeonPalette.neonCyan)
                }
                .buttonStyle(.plain)
            }
            primaryButton
            footer
        }
        .padding(28)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.06),
                                Color.white.opacity(0.02)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            NeonPalette.neonCyan.opacity(0.22),
                            Color.white.opacity(0.05),
                            NeonPalette.neonPurple.opacity(0.22)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: NeonPalette.neonPurple.opacity(0.14), radius: 28, y: 18)
        .shadow(color: .black.opacity(0.45), radius: 36, y: 22)
    }

    private var brand: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [NeonPalette.neonCyan, NeonPalette.neonPurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 46, height: 46)
                    .shadow(color: NeonPalette.neonPurple.opacity(0.30), radius: 10, y: 4)
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("FinSync")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(NeonPalette.textPrimary)
                Text("Controle financeiro pessoal")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(NeonPalette.textSecondary)
            }
            Spacer()
        }
    }

    private var heading: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Bem-vindo de volta")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(NeonPalette.textPrimary)
            Text("Entre com sua conta para sincronizar suas finanças.")
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(NeonPalette.textSecondary)
        }
    }

    private var configChip: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(configIsComplete ? NeonPalette.neonMint : NeonPalette.neonOrange)
                .frame(width: 7, height: 7)
                .neonGlow(configIsComplete ? NeonPalette.neonMint : NeonPalette.neonOrange, radius: 4)
            Text(configStatus)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(configIsComplete ? NeonPalette.textSecondary : NeonPalette.neonOrange)
            Spacer()
            Button {
                isConfigPresented = true
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "gearshape.fill").font(.system(size: 10))
                    Text("Configurar")
                }
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(NeonPalette.neonCyan)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(NeonPalette.surface.opacity(0.55))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(NeonPalette.stroke, lineWidth: 1)
        )
    }

    private func neonField(
        title: String,
        icon: String,
        text: Binding<String>,
        secure: Bool,
        field: Field,
        accentLeft: Color,
        accentRight: Color
    ) -> some View {
        let isFocused = focusedField == field
        return VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(NeonPalette.textTertiary)
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(isFocused ? accentLeft : NeonPalette.textTertiary)
                    .frame(width: 18)
                Group {
                    if secure {
                        SecureField("", text: text)
                    } else {
                        TextField("", text: text)
                            .textContentType(.emailAddress)
                    }
                }
                .textFieldStyle(.plain)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(NeonPalette.textPrimary)
                .focused($focusedField, equals: field)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: isFocused
                                ? [accentLeft.opacity(0.55), accentRight.opacity(0.55)]
                                : [NeonPalette.stroke, NeonPalette.stroke],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: isFocused ? 1.2 : 1
                    )
            )
            .shadow(color: isFocused ? accentLeft.opacity(0.18) : .clear, radius: 10, y: 3)
            .animation(.easeOut(duration: 0.2), value: isFocused)
        }
    }

    private var rememberToggle: some View {
        HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(NeonPalette.neonCyan.opacity(0.18))
                    .frame(width: 16, height: 16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .strokeBorder(NeonPalette.neonCyan.opacity(0.6), lineWidth: 1)
                    )
                Image(systemName: "checkmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(NeonPalette.neonCyan)
            }
            Text("Manter conectado")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(NeonPalette.textSecondary)
        }
    }

    private var primaryButton: some View {
        Button {
            SupabaseConfigStore.save(SavedSupabaseConfig(url: supabaseURL, publishableKey: publishableKey))
            onSignIn(
                AuthRequest(
                    email: email,
                    password: password,
                    supabaseURL: supabaseURL,
                    publishableKey: publishableKey
                )
            )
        } label: {
            HStack(spacing: 10) {
                Text("Entrar")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [NeonPalette.neonCyan, NeonPalette.neonPurple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.20), .clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    .blendMode(.plusLighter)
                    .allowsHitTesting(false)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.30), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .keyboardShortcut(.defaultAction)
        .shadow(color: NeonPalette.neonPurple.opacity(0.22), radius: 16, y: 6)
        .accessibilityIdentifier(Accessibility.signInButton)
    }

    private var footer: some View {
        HStack(spacing: 6) {
            Spacer()
            Text("Não tem uma conta?")
                .font(.system(size: 11, design: .rounded))
                .foregroundStyle(NeonPalette.textSecondary)
            Button("Criar conta") {}
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(NeonPalette.neonPurple)
            Spacer()
        }
        .padding(.top, 4)
    }

    private var configIsComplete: Bool {
        SavedSupabaseConfig(url: supabaseURL, publishableKey: publishableKey).isComplete
    }

    private var configStatus: String {
        configIsComplete ? "Supabase configurado" : "Supabase não configurado"
    }
}

public struct AuthRequest: Equatable, Sendable {
    public let email: String
    public let password: String
    public let supabaseURL: String
    public let publishableKey: String
}

private struct SupabaseConfigurationView: View {
    @Binding var supabaseURL: String
    @Binding var publishableKey: String
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            NeonBackground()
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 10) {
                    Image(systemName: "bolt.horizontal.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(NeonPalette.neonCyan)
                        .neonGlow(NeonPalette.neonCyan, radius: 6)
                    Text("Configurar Supabase")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(NeonPalette.textPrimary)
                    Spacer()
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("URL")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(1.2)
                        .foregroundStyle(NeonPalette.textTertiary)
                    TextField("https://xxxxxx.supabase.co", text: $supabaseURL)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(NeonPalette.textPrimary)
                        .padding(.horizontal, 12).padding(.vertical, 11)
                        .background(RoundedRectangle(cornerRadius: 10).fill(.ultraThinMaterial))
                        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(NeonPalette.neonCyan.opacity(0.45), lineWidth: 1))
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("PUBLISHABLE KEY")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(1.2)
                        .foregroundStyle(NeonPalette.textTertiary)
                    SecureField("eyJhbGciOi...", text: $publishableKey)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(NeonPalette.textPrimary)
                        .padding(.horizontal, 12).padding(.vertical, 11)
                        .background(RoundedRectangle(cornerRadius: 10).fill(.ultraThinMaterial))
                        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(NeonPalette.neonPurple.opacity(0.45), lineWidth: 1))
                }
                HStack {
                    Spacer()
                    Button("Cancelar") { dismiss() }
                        .buttonStyle(NeonSecondaryButtonStyle())
                    Button("Salvar", action: onSave)
                        .buttonStyle(NeonPrimaryButtonStyle())
                        .keyboardShortcut(.defaultAction)
                }
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [NeonPalette.neonCyan.opacity(0.5), NeonPalette.neonPurple.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .padding(28)
            .frame(minWidth: 540)
        }
        .frame(minWidth: 600, minHeight: 380)
    }
}
