import Foundation

public actor ImportsRepository {
    private let files: [ImportFile]
    private let auditEvents: [AuditEvent]

    public init(files: [ImportFile] = [], auditEvents: [AuditEvent] = []) {
        self.files = files
        self.auditEvents = auditEvents
    }

    public func fetch(accountOwnerId: String, status: ImportStatus? = nil) async throws -> [ImportPresentation] {
        files
            .filter { $0.accountOwnerId == accountOwnerId && (status == nil || $0.status == status) }
            .sorted { $0.updatedAt > $1.updatedAt }
            .map(ImportPresentation.init(file:))
    }
}

