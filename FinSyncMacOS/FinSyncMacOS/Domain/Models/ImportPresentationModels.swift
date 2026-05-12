import Foundation

public struct ImportPresentation: Identifiable, Equatable, Sendable {
    public let id: String
    public let fileName: String
    public let status: ImportStatus
    public let actionableReason: String?
    public let issuerLayout: String?
    public let updatedAt: Date

    public init(file: ImportFile) {
        id = file.id
        fileName = file.fileName
        status = file.status
        actionableReason = file.statusMessage ?? file.statusReasonCode
        issuerLayout = [file.detectedIssuer, file.detectedLayout].compactMap { $0 }.joined(separator: " / ")
        updatedAt = file.updatedAt
    }
}

