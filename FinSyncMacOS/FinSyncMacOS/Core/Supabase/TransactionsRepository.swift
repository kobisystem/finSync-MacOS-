import Foundation

public actor TransactionsRepository {
    private let transactions: [Transaction]
    private let classifications: [TransactionClassification]

    public init(transactions: [Transaction] = [], classifications: [TransactionClassification] = []) {
        self.transactions = transactions
        self.classifications = classifications
    }

    public func fetch(accountOwnerId: String, filter: TransactionFilter = TransactionFilter()) async throws -> [Transaction] {
        transactions.filter { transaction in
            guard transaction.accountOwnerId == accountOwnerId else { return false }
            let classification = classifications.first { $0.transactionId == transaction.id && $0.isActive }
            return filter.matches(transaction, classification: classification)
        }
    }
}

