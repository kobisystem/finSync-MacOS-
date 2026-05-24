import Foundation

extension KeyedDecodingContainer {
    /// PostgREST may return `numeric` columns as JSON strings to preserve
    /// precision. This helper accepts both numbers and strings.
    func decodeFlexibleDecimal(forKey key: Key) throws -> Decimal {
        if let direct = try? decode(Decimal.self, forKey: key) {
            return direct
        }
        if let raw = try? decode(String.self, forKey: key),
           let parsed = Decimal(string: raw, locale: Locale(identifier: "en_US_POSIX")) {
            return parsed
        }
        throw DecodingError.dataCorruptedError(
            forKey: key,
            in: self,
            debugDescription: "Invalid decimal for key \(key.stringValue)"
        )
    }

    func decodeFlexibleDecimalIfPresent(forKey key: Key) throws -> Decimal? {
        guard contains(key) else { return nil }
        if let direct = try? decode(Decimal.self, forKey: key) {
            return direct
        }
        if let raw = try? decode(String.self, forKey: key) {
            return Decimal(string: raw, locale: Locale(identifier: "en_US_POSIX"))
        }
        return nil
    }
}

public struct BalanceSnapshot: Codable, Identifiable, Equatable, Sendable {
    public let id: String
    public let accountOwnerId: String
    public let accountId: String
    public let snapshotDate: Date
    public let balanceAmount: Decimal
    public let source: BalanceSnapshotSource
    public let importFileId: String?
    public let confidence: ForecastConfidence
    public let createdAt: Date

    private enum CodingKeys: String, CodingKey {
        case id
        case accountOwnerId
        case accountId
        case snapshotDate
        case balanceAmount
        case source
        case importFileId
        case confidence
        case createdAt
    }

    public init(id: String, accountOwnerId: String, accountId: String, snapshotDate: Date, balanceAmount: Decimal, source: BalanceSnapshotSource, importFileId: String?, confidence: ForecastConfidence = .normal, createdAt: Date) {
        self.id = id
        self.accountOwnerId = accountOwnerId
        self.accountId = accountId
        self.snapshotDate = snapshotDate
        self.balanceAmount = balanceAmount
        self.source = source
        self.importFileId = importFileId
        self.confidence = confidence
        self.createdAt = createdAt
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        accountOwnerId = try container.decode(String.self, forKey: .accountOwnerId)
        accountId = try container.decode(String.self, forKey: .accountId)
        snapshotDate = try container.decode(Date.self, forKey: .snapshotDate)
        balanceAmount = try container.decodeFlexibleDecimal(forKey: .balanceAmount)
        source = try container.decodeIfPresent(BalanceSnapshotSource.self, forKey: .source) ?? .calculated
        importFileId = try container.decodeIfPresent(String.self, forKey: .importFileId)
        confidence = try container.decodeIfPresent(ForecastConfidence.self, forKey: .confidence) ?? .normal
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date.distantPast
    }
}

public struct MonthlyPeriod: Codable, Identifiable, Equatable, Sendable {
    public let id: String
    public let accountOwnerId: String
    public let month: Date
    public let status: MonthlyPeriodStatus
    public let incomeTotal: Decimal
    public let expenseTotal: Decimal
    public let netResult: Decimal
    public let expectedEndBalance: Decimal?
    public let actualEndBalance: Decimal?
    public let unreconciledDifference: Decimal?
    public let changedAfterReview: Bool
    public let changedAfterClose: Bool
    public let reviewedAt: Date?
    public let closedAt: Date?
    public let createdAt: Date
    public let updatedAt: Date

    private enum CodingKeys: String, CodingKey {
        case id
        case accountOwnerId
        case month
        case status
        case incomeTotal
        case expenseTotal
        case netResult
        case expectedEndBalance
        case actualEndBalance
        case unreconciledDifference
        case changedAfterReview
        case changedAfterClose
        case reviewedAt
        case closedAt
        case createdAt
        case updatedAt
    }

    public init(id: String, accountOwnerId: String, month: Date, status: MonthlyPeriodStatus, incomeTotal: Decimal, expenseTotal: Decimal, netResult: Decimal, expectedEndBalance: Decimal?, actualEndBalance: Decimal?, unreconciledDifference: Decimal?, changedAfterReview: Bool, changedAfterClose: Bool, reviewedAt: Date?, closedAt: Date?, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.accountOwnerId = accountOwnerId
        self.month = month
        self.status = status
        self.incomeTotal = incomeTotal
        self.expenseTotal = expenseTotal
        self.netResult = netResult
        self.expectedEndBalance = expectedEndBalance
        self.actualEndBalance = actualEndBalance
        self.unreconciledDifference = unreconciledDifference
        self.changedAfterReview = changedAfterReview
        self.changedAfterClose = changedAfterClose
        self.reviewedAt = reviewedAt
        self.closedAt = closedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        accountOwnerId = try container.decode(String.self, forKey: .accountOwnerId)
        month = try container.decode(Date.self, forKey: .month)
        status = try container.decodeIfPresent(MonthlyPeriodStatus.self, forKey: .status) ?? .open
        incomeTotal = try container.decodeFlexibleDecimalIfPresent(forKey: .incomeTotal) ?? 0
        expenseTotal = try container.decodeFlexibleDecimalIfPresent(forKey: .expenseTotal) ?? 0
        netResult = try container.decodeFlexibleDecimalIfPresent(forKey: .netResult) ?? 0
        expectedEndBalance = try container.decodeFlexibleDecimalIfPresent(forKey: .expectedEndBalance)
        actualEndBalance = try container.decodeFlexibleDecimalIfPresent(forKey: .actualEndBalance)
        unreconciledDifference = try container.decodeFlexibleDecimalIfPresent(forKey: .unreconciledDifference)
        changedAfterReview = try container.decodeIfPresent(Bool.self, forKey: .changedAfterReview) ?? false
        changedAfterClose = try container.decodeIfPresent(Bool.self, forKey: .changedAfterClose) ?? false
        reviewedAt = try container.decodeIfPresent(Date.self, forKey: .reviewedAt)
        closedAt = try container.decodeIfPresent(Date.self, forKey: .closedAt)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date.distantPast
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? createdAt
    }
}

public struct Obligation: Codable, Identifiable, Equatable, Sendable {
    public let id: String
    public let accountOwnerId: String
    public let sourceType: ObligationSourceType
    public let sourceId: String
    public let dueDate: Date
    public let competenceMonth: Date
    public let amount: Decimal
    public let status: ObligationStatus
    public let confidence: ForecastConfidence
    public let createdAt: Date
    public let updatedAt: Date

    private enum CodingKeys: String, CodingKey {
        case id
        case accountOwnerId
        case sourceType
        case sourceId
        case dueDate
        case competenceMonth
        case amount
        case status
        case confidence
        case createdAt
        case updatedAt
    }

    public init(id: String, accountOwnerId: String, sourceType: ObligationSourceType, sourceId: String, dueDate: Date, competenceMonth: Date, amount: Decimal, status: ObligationStatus, confidence: ForecastConfidence = .normal, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.accountOwnerId = accountOwnerId
        self.sourceType = sourceType
        self.sourceId = sourceId
        self.dueDate = dueDate
        self.competenceMonth = competenceMonth
        self.amount = amount
        self.status = status
        self.confidence = confidence
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        accountOwnerId = try container.decode(String.self, forKey: .accountOwnerId)
        sourceType = try container.decodeIfPresent(ObligationSourceType.self, forKey: .sourceType) ?? .manual
        sourceId = try container.decodeIfPresent(String.self, forKey: .sourceId) ?? id
        dueDate = try container.decode(Date.self, forKey: .dueDate)
        competenceMonth = try container.decodeIfPresent(Date.self, forKey: .competenceMonth) ?? dueDate
        amount = try container.decodeFlexibleDecimal(forKey: .amount)
        status = try container.decodeIfPresent(ObligationStatus.self, forKey: .status) ?? .pending
        confidence = try container.decodeIfPresent(ForecastConfidence.self, forKey: .confidence) ?? .normal
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date.distantPast
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? createdAt
    }
}
