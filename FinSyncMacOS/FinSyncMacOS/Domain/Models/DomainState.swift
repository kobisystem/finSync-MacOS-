import Foundation

public enum AccountKind: String, Codable, CaseIterable, Sendable {
    case bankAccount = "bank_account"
    case creditCard = "credit_card"
}

public enum ImportStatus: String, Codable, CaseIterable, Sendable {
    case pending
    case processing
    case processed
    case error
    case ignored
}

public enum ImportProvider: String, Codable, CaseIterable, Sendable {
    case dropbox
}

public enum FileType: String, Codable, CaseIterable, Sendable {
    case bankStatement = "bank_statement"
    case creditCardStatement = "credit_card_statement"
    case unknown
}

public enum TransactionType: String, Codable, CaseIterable, Sendable {
    case income
    case expense
    case cardPayment = "card_payment"
    case refund
    case fee
    case transfer
    case unknown
}

public enum ReviewStatus: String, Codable, CaseIterable, Sendable {
    case notNeeded = "not_needed"
    case needsReview = "needs_review"
    case reviewed
}

public enum StatementStatus: String, Codable, CaseIterable, Sendable {
    case open
    case closed
    case paid
    case partial
    case unknown
}

public enum CategoryKind: String, Codable, CaseIterable, Sendable {
    case income
    case expense
}

public enum ClassificationSource: String, Codable, CaseIterable, Sendable {
    case rule
    case automatedSuggestion = "automated_suggestion"
    case user
}

public enum PatternType: String, Codable, CaseIterable, Sendable {
    case descriptionContains = "description_contains"
    case merchantNormalized = "merchant_normalized"
    case amountRange = "amount_range"
    case accountMatch = "account_match"
    case composite
}

public enum RuleCreatedFrom: String, Codable, CaseIterable, Sendable {
    case system
    case userCorrection = "user_correction"
}

public enum ForecastConfidence: String, Codable, CaseIterable, Sendable {
    case low
    case normal
    case high
}

public enum ActorType: String, Codable, CaseIterable, Sendable {
    case system
    case worker
    case user
}

public enum LoadableState<Value: Equatable & Sendable>: Equatable, Sendable {
    case idle
    case loading
    case ready(Value)
    case empty
    case stale(Value, message: String)
    case failed(AppError)
    case permissionDenied
    case sessionExpired
}
