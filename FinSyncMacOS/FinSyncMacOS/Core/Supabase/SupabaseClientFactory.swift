import Foundation

public struct SupabaseClientDescriptor: Equatable, Sendable {
    public let url: URL
    public let publishableKey: String
    public let schema: String

    public init(url: URL, publishableKey: String, schema: String = "public") {
        self.url = url
        self.publishableKey = publishableKey
        self.schema = schema
    }
}

public enum SupabaseClientFactory {
    public static func makeDescriptor(config: AppConfig) -> SupabaseClientDescriptor {
        SupabaseClientDescriptor(url: config.supabaseURL, publishableKey: config.supabasePublishableKey)
    }
}

