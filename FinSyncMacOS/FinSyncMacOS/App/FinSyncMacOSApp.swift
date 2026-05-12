import SwiftUI

public struct FinSyncMacOSRootView: View {
    @State private var authState: RootAuthState = .signedOut
    @StateObject private var theme = AppTheme()

    public init() {}

    public var body: some View {
        Group {
            switch authState {
            case .signedOut, .failed:
                ZStack {
                    AuthView { request in
                        Task { await signIn(request) }
                    }
                    if case .failed(let error) = authState {
                        VStack {
                            Spacer()
                            Text(error.localizedDescription)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule().fill(DS.error)
                                )
                                .padding(.bottom, 24)
                        }
                    }
                }
            case .signingIn:
                ProgressView("Entrando...")
                    .frame(minWidth: 360, minHeight: 220)
            case .signedIn(let context):
                AppShellView(
                    context: context,
                    onLogout: {
                        authState = .signedOut
                    }
                )
            }
        }
        .environmentObject(theme)
        .preferredColorScheme(theme.colorScheme)
    }

    private func signIn(_ request: AuthRequest) async {
        authState = .signingIn
        do {
            guard let url = URL(string: request.supabaseURL), request.publishableKey.isEmpty == false else {
                throw AppError.configuration("Informe Supabase URL e publishable key.")
            }
            let config = AppConfig(supabaseURL: url, supabasePublishableKey: request.publishableKey)
            let client = SupabaseRESTClient(config: config)
            authState = .signedIn(try await client.signIn(email: request.email, password: request.password))
        } catch let error as AppError {
            authState = .failed(error)
        } catch {
            authState = .failed(.unknown(String(describing: error)))
        }
    }
}

private enum RootAuthState: Equatable {
    case signedOut
    case signingIn
    case signedIn(SupabaseSessionContext)
    case failed(AppError)
}
