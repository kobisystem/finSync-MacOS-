import Foundation

public struct SavedSupabaseConfig: Equatable, Sendable {
    public let url: String
    public let publishableKey: String

    public var isComplete: Bool {
        URL(string: url) != nil && publishableKey.isEmpty == false
    }
}

public enum SupabaseConfigStore {
    private static let urlKey = "finsync.supabase.url"
    private static let publishableKeyKey = "finsync.supabase.publishableKey"

    public static func load(defaults: UserDefaults = .standard) -> SavedSupabaseConfig {
        SavedSupabaseConfig(
            url: defaults.string(forKey: urlKey) ?? ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? "",
            publishableKey: defaults.string(forKey: publishableKeyKey) ?? ProcessInfo.processInfo.environment["SUPABASE_PUBLISHABLE_KEY"] ?? ""
        )
    }

    public static func save(_ config: SavedSupabaseConfig, defaults: UserDefaults = .standard) {
        defaults.set(config.url, forKey: urlKey)
        defaults.set(config.publishableKey, forKey: publishableKeyKey)
    }

    public static func clear(defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: urlKey)
        defaults.removeObject(forKey: publishableKeyKey)
    }
}
