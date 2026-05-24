import Foundation

public enum AppError: Error, Equatable, LocalizedError, Sendable {
    case noSession
    case expiredSession
    case network(String)
    case permissionDenied
    case emptyResult
    case reviewConflict
    case cacheUnavailable
    case missingAccountOwner
    case configuration(String)
    case validation(String)
    case unknown(String)

    public var errorDescription: String? {
        switch self {
        case .noSession: "Sessao nao iniciada."
        case .expiredSession: "Sessao expirada. Entre novamente."
        case .network(let message): "Falha de rede: \(message)"
        case .permissionDenied: "Permissao insuficiente para acessar estes dados."
        case .emptyResult: "Nenhum dado encontrado."
        case .reviewConflict: "Os dados foram alterados. Recarregue e confirme novamente."
        case .cacheUnavailable: "Cache local indisponivel."
        case .missingAccountOwner: "Conta financeira nao encontrada para este usuario."
        case .configuration(let message): "Configuracao invalida: \(message)"
        case .validation(let message): "Validacao falhou: \(message)"
        case .unknown(let message): "Erro inesperado: \(message)"
        }
    }
}

public enum RepositoryErrorMapper {
    public static func map(_ condition: String) -> AppError {
        switch condition {
        case "no_session": .noSession
        case "expired_session": .expiredSession
        case "permission_denied": .permissionDenied
        case "empty": .emptyResult
        case "review_conflict": .reviewConflict
        case "cache_unavailable": .cacheUnavailable
        default: .unknown(condition)
        }
    }
}

