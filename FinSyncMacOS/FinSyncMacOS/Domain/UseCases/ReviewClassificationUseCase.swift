import Foundation

public enum ReviewClassificationUseCase {
    public static func validateNoConflict(item: ReviewItem, current: ReviewLoadedState) throws {
        guard item.loadedState == current else {
            throw AppError.reviewConflict
        }
    }

    public static func validateCorrection(_ correction: ReviewCorrection) throws {
        guard correction.category.isActive else {
            throw AppError.validation("Categoria inativa nao pode ser usada para nova correcao.")
        }
        guard correction.item.transaction.reviewStatus == .needsReview else {
            throw AppError.validation("Transacao nao esta pendente de revisao.")
        }
    }

    public static func activeClassificationCount(_ classifications: [TransactionClassification]) -> Int {
        classifications.filter(\.isActive).count
    }
}

