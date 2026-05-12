import SwiftUI

public struct AccountsView: View {
    public let accounts: [Account]

    public init(accounts: [Account]) {
        self.accounts = accounts
    }

    public var body: some View {
        List(accounts) { account in
            VStack(alignment: .leading) {
                Text(account.displayName)
                Text("\(account.institutionName) - \(account.maskedIdentifier) - \(account.currency.rawValue)")
                    .foregroundStyle(.secondary)
            }
        }
        .overlay {
            if accounts.isEmpty { EmptyStateView(message: "Nenhuma conta encontrada.") }
        }
    }
}

