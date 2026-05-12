import Foundation

public struct AppConfig: Equatable, Sendable {
    public let supabaseURL: URL
    public let supabasePublishableKey: String

    public init(supabaseURL: URL, supabasePublishableKey: String) {
        self.supabaseURL = supabaseURL
        self.supabasePublishableKey = supabasePublishableKey
    }

    public static func fromEnvironment(_ environment: [String: String] = ProcessInfo.processInfo.environment) throws -> AppConfig {
        guard let urlString = environment["SUPABASE_URL"], let url = URL(string: urlString) else {
            throw AppError.configuration("SUPABASE_URL is missing or invalid")
        }
        guard let key = environment["SUPABASE_PUBLISHABLE_KEY"], key.isEmpty == false else {
            throw AppError.configuration("SUPABASE_PUBLISHABLE_KEY is missing")
        }
        return AppConfig(supabaseURL: url, supabasePublishableKey: key)
    }
}

