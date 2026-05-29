import XCTest
@testable import FinSyncCore

final class DomainDecodingTests: XCTestCase {
    func testFixtureBundleLoads() throws {
        #if SWIFT_PACKAGE
        let bundle = Bundle.module
        #else
        let bundle = Bundle(for: DomainDecodingTests.self)
        #endif
        let url = bundle.url(forResource: "FinSyncFixtures", withExtension: "json")
        XCTAssertNotNil(url)
        let data = try XCTUnwrap(url).withUnsafeFileSystemRepresentation { path in
            try Data(contentsOf: URL(fileURLWithPath: String(cString: path!)))
        }
        XCTAssertGreaterThan(data.count, 0)
    }

    func testCoreModelsAreCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let owner = TestData.owner()
        let decoded = try decoder.decode(AccountOwner.self, from: encoder.encode(owner))
        XCTAssertEqual(decoded, owner)
    }

    func testCreditCardStatementDecodesNullableSupabasePeriodDates() throws {
        let json = """
        [
          {
            "id": "statement-1",
            "account_owner_id": "owner-1",
            "account_id": "account-card",
            "credit_card_account_id": null,
            "import_file_id": null,
            "statement_period_start": null,
            "statement_period_end": null,
            "due_date": "2026-02-10",
            "closing_date": null,
            "total_amount": 300.50,
            "paid_amount": null,
            "currency": "BRL",
            "status": null,
            "created_at": "2026-01-31T12:00:00Z",
            "updated_at": null
          }
        ]
        """

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)

            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = isoFormatter.date(from: value) {
                return date
            }

            isoFormatter.formatOptions = [.withInternetDateTime]
            if let date = isoFormatter.date(from: value) {
                return date
            }

            let dayFormatter = DateFormatter()
            dayFormatter.calendar = Calendar(identifier: .gregorian)
            dayFormatter.locale = Locale(identifier: "en_US_POSIX")
            dayFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            dayFormatter.dateFormat = "yyyy-MM-dd"
            if let date = dayFormatter.date(from: value) {
                return date
            }

            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(value)")
        }

        let statements = try decoder.decode([CreditCardStatement].self, from: Data(json.utf8))

        let statement = try XCTUnwrap(statements.first)
        XCTAssertEqual(statement.creditCardAccountId, "account-card")
        XCTAssertEqual(statement.importFileId, "")
        XCTAssertEqual(statement.statementPeriodStart, Date.distantPast)
        XCTAssertEqual(statement.statementPeriodEnd, Date.distantPast)
        XCTAssertEqual(statement.paidAmount, 0)
        XCTAssertEqual(statement.status, .unknown)
        XCTAssertEqual(statement.updatedAt, statement.createdAt)
    }
}
