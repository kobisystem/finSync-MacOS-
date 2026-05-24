import Foundation

public actor KPIRepository {
    private let transactions: [Transaction]
    private let classifications: [TransactionClassification]
    private let categories: [Category]

    public init(transactions: [Transaction] = [], classifications: [TransactionClassification] = [], categories: [Category] = []) {
        self.transactions = transactions
        self.classifications = classifications
        self.categories = categories
    }

    public func fetch(accountOwnerId: String) async throws -> ([Transaction], [TransactionClassification], [Category]) {
        (
            transactions.filter { $0.accountOwnerId == accountOwnerId },
            classifications.filter { $0.accountOwnerId == accountOwnerId },
            categories.filter { $0.accountOwnerId == accountOwnerId }
        )
    }
}

