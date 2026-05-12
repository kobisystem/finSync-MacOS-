import Foundation

public actor SupabaseAccountOwnerRepository: AccountOwnerRepository {
    private let owners: [String: AccountOwner]

    public init(owners: [AccountOwner] = []) {
        self.owners = Dictionary(uniqueKeysWithValues: owners.map { ($0.id, $0) })
    }

    public func fetchAccountOwner(session: AuthSession) async throws -> AccountOwner {
        guard let accountOwnerId = session.accountOwnerId else {
            throw AppError.missingAccountOwner
        }
        if let owner = owners[accountOwnerId] {
            return owner
        }
        return AccountOwner(id: accountOwnerId, email: "user@example.com", displayName: "FinSync User", createdAt: Date())
    }
}

