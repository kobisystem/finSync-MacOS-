import Foundation

public struct ReviewLoadedState: Equatable, Sendable {
    public let transactionUpdatedAt: Date
    public let reviewStatus: ReviewStatus
    public let activeClassificationId: String?

    public init(transactionUpdatedAt: Date, reviewStatus: ReviewStatus, activeClassificationId: String?) {
        self.transactionUpdatedAt = transactionUpdatedAt
        self.reviewStatus = reviewStatus
        self.activeClassificationId = activeClassificationId
    }
}

public struct ReviewItem: Identifiable, Equatable, Sendable {
    public let id: String
    public let transaction: Transaction
    public let activeClassification: TransactionClassification?
    public let suggestedCategory: Category?
    public let categories: [Category]
    public let loadedState: ReviewLoadedState

    public init(transaction: Transaction, activeClassification: TransactionClassification?, suggestedCategory: Category?, categories: [Category], loadedState: ReviewLoadedState) {
        self.id = transaction.id
        self.transaction = transaction
        self.activeClassification = activeClassification
        self.suggestedCategory = suggestedCategory
        self.categories = categories
        self.loadedState = loadedState
    }
}

public struct ReviewCorrection: Equatable, Sendable {
    public let item: ReviewItem
    public let category: Category
    public let createRule: Bool

    public init(item: ReviewItem, category: Category, createRule: Bool = false) {
        self.item = item
        self.category = category
        self.createRule = createRule
    }
}

public struct RuleSuggestion: Equatable, Sendable {
    public let patternType: PatternType
    public let patternValue: String
    public let categoryId: String
}

public struct ReviewResult: Equatable, Sendable {
    public let transactionId: String
    public let reviewStatus: ReviewStatus
    public let activeClassification: TransactionClassification
    public let history: [TransactionClassification]
    public let auditEvent: AuditEvent?
    public let ruleSuggestion: RuleSuggestion?
}

