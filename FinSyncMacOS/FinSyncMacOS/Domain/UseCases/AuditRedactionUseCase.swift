import Foundation

public enum AuditRedactionUseCase {
    private static let forbiddenKeys = ["raw", "document_content", "unmasked_identifier", "full_card_number", "password"]

    public static func safeMetadata(_ metadata: [String: String]) -> [String: String] {
        metadata.filter { key, value in
            let loweredKey = key.lowercased()
            let loweredValue = value.lowercased()
            return forbiddenKeys.contains { loweredKey.contains($0) || loweredValue.contains($0) } == false
        }
    }
}

