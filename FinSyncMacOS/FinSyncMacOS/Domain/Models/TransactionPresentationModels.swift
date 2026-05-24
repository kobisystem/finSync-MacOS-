import Foundation

public struct TransactionFilter: Equatable, Sendable {
    public var startDate: Date?
    public var endDate: Date?
    public var accountId: String?
    public var categoryId: String?
    public var transactionType: TransactionType?
    public var importFileId: String?
    public var reviewStatus: ReviewStatus?

    public init(startDate: Date? = nil, endDate: Date? = nil, accountId: String? = nil, categoryId: String? = nil, transactionType: TransactionType? = nil, importFileId: String? = nil, reviewStatus: ReviewStatus? = nil) {
        self.startDate = startDate
        self.endDate = endDate
        self.accountId = accountId
        self.categoryId = categoryId
        self.transactionType = transactionType
        self.importFileId = importFileId
        self.reviewStatus = reviewStatus
    }

    public func matches(_ transaction: Transaction, classification: TransactionClassification? = nil) -> Bool {
        if let startDate, transaction.originalDate < startDate { return false }
        if let endDate, transaction.originalDate > endDate { return false }
        if let accountId, transaction.accountId != accountId { return false }
        if let categoryId, classification?.categoryId != categoryId { return false }
        if let transactionType, transaction.transactionType != transactionType { return false }
        if let importFileId, transaction.importFileId != importFileId { return false }
        if let reviewStatus, transaction.reviewStatus != reviewStatus { return false }
        return true
    }
}

public struct TransactionDetailPresentation: Identifiable, Equatable, Sendable {
    public let id: String
    public let descriptionOriginal: String
    public let amount: Money
    public let originalDate: Date
    public let isImmutable: Bool = true
}

