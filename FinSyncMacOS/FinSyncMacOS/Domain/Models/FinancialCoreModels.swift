import Foundation

public struct AccountOwner: Codable, Identifiable, Equatable, Sendable {
    public let id: String
    public let email: String
    public let displayName: String
    public let createdAt: Date

    public init(id: String, email: String, displayName: String, createdAt: Date) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.createdAt = createdAt
    }
}

public struct Account: Codable, Identifiable, Equatable, Sendable {
    public let id: String
    public let accountOwnerId: String
    public let kind: AccountKind
    public let institutionName: String
    public let displayName: String
    public let maskedIdentifier: String
    public let currency: CurrencyCode
    public let createdAt: Date
    public let updatedAt: Date

    private enum CodingKeys: String, CodingKey {
        case id
        case accountOwnerId
        case kind
        case institutionName
        case displayName
        case maskedIdentifier
        case currency
        case createdAt
        case updatedAt
    }

    public init(id: String, accountOwnerId: String, kind: AccountKind, institutionName: String, displayName: String, maskedIdentifier: String, currency: CurrencyCode, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.accountOwnerId = accountOwnerId
        self.kind = kind
        self.institutionName = institutionName
        self.displayName = displayName
        self.maskedIdentifier = maskedIdentifier
        self.currency = currency
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        accountOwnerId = try container.decode(String.self, forKey: .accountOwnerId)
        kind = try container.decode(AccountKind.self, forKey: .kind)
        institutionName = try container.decodeIfPresent(String.self, forKey: .institutionName) ?? "Instituicao nao informada"
        displayName = try container.decodeIfPresent(String.self, forKey: .displayName) ?? institutionName
        let rawMaskedIdentifier = try container.decodeIfPresent(String.self, forKey: .maskedIdentifier)
        maskedIdentifier = rawMaskedIdentifier?.isEmpty == false ? rawMaskedIdentifier! : "****"
        currency = try container.decodeIfPresent(CurrencyCode.self, forKey: .currency) ?? .brl
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date.distantPast
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? createdAt
    }
}

public struct ImportFile: Codable, Identifiable, Equatable, Sendable {
    public let id: String
    public let accountOwnerId: String
    public let provider: ImportProvider
    public let providerFileId: String
    public let originalPath: String
    public let fileName: String
    public let mimeType: String
    public let fileExtension: String
    public let contentFingerprint: String
    public let fileType: FileType
    public let status: ImportStatus
    public let statusReasonCode: String?
    public let statusMessage: String?
    public let detectedIssuer: String?
    public let detectedLayout: String?
    public let processingStartedAt: Date?
    public let processingFinishedAt: Date?
    public let createdAt: Date
    public let updatedAt: Date

    private enum CodingKeys: String, CodingKey {
        case id
        case accountOwnerId
        case provider
        case providerFileId
        case originalPath
        case fileName
        case mimeType
        case fileExtension
        case contentFingerprint
        case fileType
        case status
        case statusReasonCode
        case statusMessage
        case detectedIssuer
        case detectedLayout
        case processingStartedAt
        case processingFinishedAt
        case createdAt
        case updatedAt
    }

    public init(id: String, accountOwnerId: String, provider: ImportProvider, providerFileId: String, originalPath: String, fileName: String, mimeType: String, fileExtension: String, contentFingerprint: String, fileType: FileType, status: ImportStatus, statusReasonCode: String?, statusMessage: String?, detectedIssuer: String?, detectedLayout: String?, processingStartedAt: Date?, processingFinishedAt: Date?, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.accountOwnerId = accountOwnerId
        self.provider = provider
        self.providerFileId = providerFileId
        self.originalPath = originalPath
        self.fileName = fileName
        self.mimeType = mimeType
        self.fileExtension = fileExtension
        self.contentFingerprint = contentFingerprint
        self.fileType = fileType
        self.status = status
        self.statusReasonCode = statusReasonCode
        self.statusMessage = statusMessage
        self.detectedIssuer = detectedIssuer
        self.detectedLayout = detectedLayout
        self.processingStartedAt = processingStartedAt
        self.processingFinishedAt = processingFinishedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        accountOwnerId = try container.decode(String.self, forKey: .accountOwnerId)
        provider = try container.decodeIfPresent(ImportProvider.self, forKey: .provider) ?? .dropbox
        providerFileId = try container.decodeIfPresent(String.self, forKey: .providerFileId) ?? id
        originalPath = try container.decodeIfPresent(String.self, forKey: .originalPath) ?? ""
        fileName = try container.decodeIfPresent(String.self, forKey: .fileName) ?? originalPath.components(separatedBy: "/").last ?? "Arquivo"
        mimeType = try container.decodeIfPresent(String.self, forKey: .mimeType) ?? "application/octet-stream"
        fileExtension = try container.decodeIfPresent(String.self, forKey: .fileExtension) ?? ""
        contentFingerprint = try container.decodeIfPresent(String.self, forKey: .contentFingerprint) ?? id
        fileType = try container.decodeIfPresent(FileType.self, forKey: .fileType) ?? .unknown
        status = try container.decodeIfPresent(ImportStatus.self, forKey: .status) ?? .pending
        statusReasonCode = try container.decodeIfPresent(String.self, forKey: .statusReasonCode)
        statusMessage = try container.decodeIfPresent(String.self, forKey: .statusMessage)
        detectedIssuer = try container.decodeIfPresent(String.self, forKey: .detectedIssuer)
        detectedLayout = try container.decodeIfPresent(String.self, forKey: .detectedLayout)
        processingStartedAt = try container.decodeIfPresent(Date.self, forKey: .processingStartedAt)
        processingFinishedAt = try container.decodeIfPresent(Date.self, forKey: .processingFinishedAt)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date.distantPast
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? createdAt
    }
}

public struct Transaction: Codable, Identifiable, Equatable, Sendable {
    public let id: String
    public let accountOwnerId: String
    public let accountId: String
    public let importFileId: String
    public let creditCardStatementId: String?
    public let sourceTransactionId: String?
    public let transactionType: TransactionType
    public let originalDate: Date
    public let postedDate: Date?
    public let descriptionOriginal: String
    public let descriptionNormalized: String
    public let amount: Decimal
    public let currency: CurrencyCode
    public let installmentCurrent: Int?
    public let installmentTotal: Int?
    public let deduplicationFingerprint: String
    public let reviewStatus: ReviewStatus
    public let createdAt: Date
    public let updatedAt: Date

    public var money: Money { Money(amount: amount, currency: currency) }

    public init(id: String, accountOwnerId: String, accountId: String, importFileId: String, creditCardStatementId: String?, sourceTransactionId: String?, transactionType: TransactionType, originalDate: Date, postedDate: Date?, descriptionOriginal: String, descriptionNormalized: String, amount: Decimal, currency: CurrencyCode, installmentCurrent: Int?, installmentTotal: Int?, deduplicationFingerprint: String, reviewStatus: ReviewStatus, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.accountOwnerId = accountOwnerId
        self.accountId = accountId
        self.importFileId = importFileId
        self.creditCardStatementId = creditCardStatementId
        self.sourceTransactionId = sourceTransactionId
        self.transactionType = transactionType
        self.originalDate = originalDate
        self.postedDate = postedDate
        self.descriptionOriginal = descriptionOriginal
        self.descriptionNormalized = descriptionNormalized
        self.amount = amount
        self.currency = currency
        self.installmentCurrent = installmentCurrent
        self.installmentTotal = installmentTotal
        self.deduplicationFingerprint = deduplicationFingerprint
        self.reviewStatus = reviewStatus
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct CreditCardStatement: Codable, Identifiable, Equatable, Sendable {
    public let id: String
    public let accountOwnerId: String
    public let accountId: String
    public let importFileId: String
    public let statementPeriodStart: Date
    public let statementPeriodEnd: Date
    public let dueDate: Date
    public let totalAmount: Decimal
    public let currency: CurrencyCode
    public let status: StatementStatus
    public let createdAt: Date
    public let updatedAt: Date

    public init(id: String, accountOwnerId: String, accountId: String, importFileId: String, statementPeriodStart: Date, statementPeriodEnd: Date, dueDate: Date, totalAmount: Decimal, currency: CurrencyCode, status: StatementStatus, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.accountOwnerId = accountOwnerId
        self.accountId = accountId
        self.importFileId = importFileId
        self.statementPeriodStart = statementPeriodStart
        self.statementPeriodEnd = statementPeriodEnd
        self.dueDate = dueDate
        self.totalAmount = totalAmount
        self.currency = currency
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
