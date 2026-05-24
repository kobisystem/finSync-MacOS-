import SwiftUI

public struct EmptyStateView: View {
    public let message: String

    public init(message: String) {
        self.message = message
    }

    public var body: some View {
        Text(message)
            .foregroundStyle(.secondary)
            .padding()
    }
}

public struct RecoverableErrorView: View {
    public let message: String
    public let retry: () -> Void

    public init(message: String, retry: @escaping () -> Void) {
        self.message = message
        self.retry = retry
    }

    public var body: some View {
        VStack {
            Text(message)
            Button("Tentar novamente", action: retry)
        }
        .padding()
    }
}

