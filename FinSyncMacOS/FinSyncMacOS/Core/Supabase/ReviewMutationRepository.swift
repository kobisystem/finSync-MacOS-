import Foundation

public actor ReviewMutationRepository: ReviewRepositoryProtocol {
    private var items: [ReviewItem]

    public init(items: [ReviewItem] = []) {
        self.items = items
    }

    public func fetchReviewItems(accountOwnerId: String) async throws -> [ReviewItem] {
        items.filter { $0.transaction.accountOwnerId == accountOwnerId && $0.transaction.reviewStatus == .needsReview }
    }

    public func confirm(_ item: ReviewItem) async throws -> ReviewResult {
        try ReviewClassificationUseCase.validateNoConflict(item: item, current: item.loadedState)
        guard let classification = item.activeClassification else {
            throw AppError.validation("Classificacao ativa ausente.")
        }
        return ReviewResult(transactionId: item.transaction.id, reviewStatus: .reviewed, activeClassification: classification, history: [classification], auditEvent: nil, ruleSuggestion: nil)
    }

    public func correct(_ correction: ReviewCorrection) async throws -> ReviewResult {
        try ReviewClassificationUseCase.validateCorrection(correction)
        let classification = TransactionClassification(
            id: "user-\(correction.item.transaction.id)",
            accountOwnerId: correction.item.transaction.accountOwnerId,
            transactionId: correction.item.transaction.id,
            categoryId: correction.category.id,
            source: .user,
            confidence: 1,
            explanation: "Correcao do usuario",
            isActive: true,
            createdAt: Date()
        )
        let suggestion = correction.createRule ? RuleSuggestion(patternType: .descriptionContains, patternValue: correction.item.transaction.descriptionNormalized, categoryId: correction.category.id) : nil
        return ReviewResult(transactionId: correction.item.transaction.id, reviewStatus: .reviewed, activeClassification: classification, history: [classification], auditEvent: nil, ruleSuggestion: suggestion)
    }
}

