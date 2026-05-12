import Foundation

public actor AccountsRepository {
    private let accounts: [Account]

    public init(accounts: [Account] = []) {
        self.accounts = accounts
    }

    public func fetch(accountOwnerId: String) async throws -> [Account] {
        accounts.filter { $0.accountOwnerId == accountOwnerId }
    }
}

