import Foundation

public struct Category: Codable, Identifiable, Equatable, Sendable {
    public let id: String
    public let accountOwnerId: String
    public let name: String
    public let kind: CategoryKind
    public let parentCategoryId: String?
    public let isActive: Bool
    public let createdAt: Date
    public let updatedAt: Date

    public init(id: String, accountOwnerId: String, name: String, kind: CategoryKind, parentCategoryId: String?, isActive: Bool, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.accountOwnerId = accountOwnerId
        self.name = name
        self.kind = kind
        self.parentCategoryId = parentCategoryId
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct TransactionClassification: Codable, Identifiable, Equatable, Sendable {
    public let id: String
    public let accountOwnerId: String
    public let transactionId: String
    public let categoryId: String
    public let source: ClassificationSource
    public let confidence: Double
    public let explanation: String?
    public let isActive: Bool
    public let createdAt: Date

    public init(id: String, accountOwnerId: String, transactionId: String, categoryId: String, source: ClassificationSource, confidence: Double, explanation: String?, isActive: Bool, createdAt: Date) {
        self.id = id
        self.accountOwnerId = accountOwnerId
        self.transactionId = transactionId
        self.categoryId = categoryId
        self.source = source
        self.confidence = confidence
        self.explanation = explanation
        self.isActive = isActive
        self.createdAt = createdAt
    }
}

public struct ClassificationRule: Codable, Identifiable, Equatable, Sendable {
    public let id: String
    public let accountOwnerId: String
    public let categoryId: String
    public let patternType: PatternType
    public let patternValue: String
    public let priority: Int
    public let createdFrom: RuleCreatedFrom
    public let isActive: Bool
    public let createdAt: Date
    public let updatedAt: Date

    public init(id: String, accountOwnerId: String, categoryId: String, patternType: PatternType, patternValue: String, priority: Int, createdFrom: RuleCreatedFrom, isActive: Bool, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.accountOwnerId = accountOwnerId
        self.categoryId = categoryId
        self.patternType = patternType
        self.patternValue = patternValue
        self.priority = priority
        self.createdFrom = createdFrom
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct CashFlowForecast: Codable, Identifiable, Equatable, Sendable {
    public let id: String
    public let accountOwnerId: String
    public let month: Date
    public let incomeConfirmed: Decimal
    public let incomePredicted: Decimal
    public let incomeEstimated: Decimal
    public let expenseConfirmed: Decimal
    public let expensePredicted: Decimal
    public let expenseEstimated: Decimal
    public let cardObligationsConfirmed: Decimal
    public let cardObligationsPredicted: Decimal
    public let cardObligationsEstimated: Decimal
    public let projectedNetResult: Decimal
    public let projectedBalance: Decimal
    public let confidence: ForecastConfidence
    public let basisSummary: String
    public let generatedAt: Date

    public init(id: String, accountOwnerId: String, month: Date, incomeConfirmed: Decimal, incomePredicted: Decimal, incomeEstimated: Decimal, expenseConfirmed: Decimal, expensePredicted: Decimal, expenseEstimated: Decimal, cardObligationsConfirmed: Decimal, cardObligationsPredicted: Decimal, cardObligationsEstimated: Decimal, projectedNetResult: Decimal, projectedBalance: Decimal, confidence: ForecastConfidence, basisSummary: String, generatedAt: Date) {
        self.id = id
        self.accountOwnerId = accountOwnerId
        self.month = month
        self.incomeConfirmed = incomeConfirmed
        self.incomePredicted = incomePredicted
        self.incomeEstimated = incomeEstimated
        self.expenseConfirmed = expenseConfirmed
        self.expensePredicted = expensePredicted
        self.expenseEstimated = expenseEstimated
        self.cardObligationsConfirmed = cardObligationsConfirmed
        self.cardObligationsPredicted = cardObligationsPredicted
        self.cardObligationsEstimated = cardObligationsEstimated
        self.projectedNetResult = projectedNetResult
        self.projectedBalance = projectedBalance
        self.confidence = confidence
        self.basisSummary = basisSummary
        self.generatedAt = generatedAt
    }
}

public struct AuditEvent: Codable, Identifiable, Equatable, Sendable {
    public let id: String
    public let accountOwnerId: String
    public let actorType: ActorType
    public let eventType: String
    public let entityType: String
    public let entityId: String
    public let metadataRedacted: [String: String]
    public let createdAt: Date

    public init(id: String, accountOwnerId: String, actorType: ActorType, eventType: String, entityType: String, entityId: String, metadataRedacted: [String: String], createdAt: Date) {
        self.id = id
        self.accountOwnerId = accountOwnerId
        self.actorType = actorType
        self.eventType = eventType
        self.entityType = entityType
        self.entityId = entityId
        self.metadataRedacted = metadataRedacted
        self.createdAt = createdAt
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case accountOwnerId
        case actorType
        case eventType
        case entityType
        case entityId
        case metadataRedacted
        case createdAt
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        accountOwnerId = try container.decode(String.self, forKey: .accountOwnerId)
        actorType = try container.decode(ActorType.self, forKey: .actorType)
        eventType = try container.decode(String.self, forKey: .eventType)
        entityType = try container.decode(String.self, forKey: .entityType)
        entityId = try container.decode(String.self, forKey: .entityId)
        createdAt = try container.decode(Date.self, forKey: .createdAt)

        if let metadata = try? container.decode([String: String].self, forKey: .metadataRedacted) {
            metadataRedacted = metadata
        } else {
            let metadata = try container.decodeIfPresent([String: AuditMetadataValue].self, forKey: .metadataRedacted) ?? [:]
            metadataRedacted = metadata.mapValues(\.description)
        }
    }
}

private enum AuditMetadataValue: Decodable, CustomStringConvertible {
    case string(String)
    case number(Double)
    case bool(Bool)
    case null
    case array([AuditMetadataValue])
    case object([String: AuditMetadataValue])

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode([AuditMetadataValue].self) {
            self = .array(value)
        } else {
            self = .object((try? container.decode([String: AuditMetadataValue].self)) ?? [:])
        }
    }

    var description: String {
        switch self {
        case .string(let value):
            return value
        case .number(let value):
            return value.rounded() == value ? String(Int(value)) : String(value)
        case .bool(let value):
            return value ? "true" : "false"
        case .null:
            return "null"
        case .array(let values):
            return values.map(\.description).joined(separator: ", ")
        case .object(let values):
            return values
                .sorted { $0.key < $1.key }
                .map { "\($0.key): \($0.value.description)" }
                .joined(separator: ", ")
        }
    }
}
