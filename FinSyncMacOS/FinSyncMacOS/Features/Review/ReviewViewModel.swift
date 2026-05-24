import Foundation

@MainActor
public final class ReviewViewModel: ObservableObject {
    public enum State: Equatable {
        case idle
        case loading
        case ready([ReviewItem])
        case empty
        case saving
        case conflict
        case failed(AppError)
    }

    @Published public private(set) var state: State = .idle
    private let repository: any ReviewRepositoryProtocol
    private let accountOwnerId: String

    public init(repository: any ReviewRepositoryProtocol, accountOwnerId: String) {
        self.repository = repository
        self.accountOwnerId = accountOwnerId
    }

    public func load() async {
        state = .loading
        do {
            let items = try await repository.fetchReviewItems(accountOwnerId: accountOwnerId)
            state = items.isEmpty ? .empty : .ready(items)
        } catch let error as AppError {
            state = .failed(error)
        } catch {
            state = .failed(.unknown(String(describing: error)))
        }
    }

    public func confirm(_ item: ReviewItem) async {
        state = .saving
        do {
            _ = try await repository.confirm(item)
            await load()
        } catch AppError.reviewConflict {
            state = .conflict
        } catch let error as AppError {
            state = .failed(error)
        } catch {
            state = .failed(.unknown(String(describing: error)))
        }
    }
}
