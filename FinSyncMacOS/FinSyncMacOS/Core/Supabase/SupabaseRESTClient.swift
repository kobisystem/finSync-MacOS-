import Foundation

public struct SupabaseSessionContext: Equatable, Sendable {
    public let config: AppConfig
    public let session: AuthSession
    public let owner: AccountOwner
}

public struct FinancialSnapshot: Equatable, Sendable {
    public var owner: AccountOwner
    public var accounts: [Account]
    public var imports: [ImportFile]
    public var transactions: [Transaction]
    public var categories: [Category]
    public var classifications: [TransactionClassification]
    public var forecasts: [CashFlowForecast]
    public var auditEvents: [AuditEvent]
    public var refreshedAt: Date

    public static func empty(owner: AccountOwner) -> FinancialSnapshot {
        FinancialSnapshot(
            owner: owner,
            accounts: [],
            imports: [],
            transactions: [],
            categories: [],
            classifications: [],
            forecasts: [],
            auditEvents: [],
            refreshedAt: Date()
        )
    }
}

public actor SupabaseRESTClient {
    private let config: AppConfig
    private let session: URLSession
    private let decoder: JSONDecoder

    public init(config: AppConfig, session: URLSession = .shared) {
        self.config = config
        self.session = session
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            if let date = SupabaseDateParser.parse(value) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(value)")
        }
        self.decoder = decoder
    }

    public func signIn(email: String, password: String) async throws -> SupabaseSessionContext {
        guard email.contains("@"), password.isEmpty == false else {
            throw AppError.validation("Informe email e senha.")
        }

        let authResponse: PasswordAuthResponse = try await post(
            path: "/auth/v1/token",
            queryItems: [URLQueryItem(name: "grant_type", value: "password")],
            body: PasswordAuthRequest(email: email, password: password),
            accessToken: nil
        )

        let authSession = AuthSession(
            accessToken: authResponse.accessToken,
            refreshToken: authResponse.refreshToken,
            accountOwnerId: authResponse.user.id,
            expiresAt: Date().addingTimeInterval(TimeInterval(authResponse.expiresIn))
        )

        let owners: [AccountOwner] = try await get(
            table: "account_owners",
            select: "*",
            filters: [URLQueryItem(name: "email", value: "eq.\(authResponse.user.email)")],
            accessToken: authSession.accessToken
        )

        let owner = owners.first ?? AccountOwner(
            id: authResponse.user.id,
            email: authResponse.user.email,
            displayName: authResponse.user.email,
            createdAt: Date()
        )

        return SupabaseSessionContext(
            config: config,
            session: AuthSession(
                accessToken: authSession.accessToken,
                refreshToken: authSession.refreshToken,
                accountOwnerId: owner.id,
                expiresAt: authSession.expiresAt
            ),
            owner: owner
        )
    }

    public func fetchSnapshot(context: SupabaseSessionContext) async throws -> FinancialSnapshot {
        async let accounts: [Account] = getOwned(table: "accounts", ownerId: context.owner.id, token: context.session.accessToken)
        async let imports: [ImportFile] = getOwned(table: "import_files", ownerId: context.owner.id, token: context.session.accessToken)
        async let transactions: [Transaction] = getOwned(table: "transactions", ownerId: context.owner.id, token: context.session.accessToken)
        async let categories: [Category] = getOwned(table: "categories", ownerId: context.owner.id, token: context.session.accessToken)
        async let classifications: [TransactionClassification] = getOwned(table: "transaction_classifications", ownerId: context.owner.id, token: context.session.accessToken)
        async let forecasts: [CashFlowForecast] = getOwned(table: "cash_flow_forecasts", ownerId: context.owner.id, token: context.session.accessToken)
        async let auditEvents: [AuditEvent] = getOwned(table: "audit_events", ownerId: context.owner.id, token: context.session.accessToken)

        return try await FinancialSnapshot(
            owner: context.owner,
            accounts: accounts,
            imports: imports,
            transactions: transactions,
            categories: categories,
            classifications: classifications,
            forecasts: forecasts,
            auditEvents: auditEvents,
            refreshedAt: Date()
        )
    }

    public func correctCategory(
        context: SupabaseSessionContext,
        transaction: Transaction,
        category: Category,
        applyToSimilar: Bool
    ) async throws {
        let targetTransactions: [TransactionIdRow]
        if applyToSimilar {
            targetTransactions = try await get(
                table: "transactions",
                select: "id",
                filters: [
                    URLQueryItem(name: "account_owner_id", value: "eq.\(context.owner.id)"),
                    URLQueryItem(name: "description_normalized", value: "eq.\(transaction.descriptionNormalized)")
                ],
                accessToken: context.session.accessToken
            )
        } else {
            targetTransactions = [TransactionIdRow(id: transaction.id)]
        }

        let targetIds = Array(Set(targetTransactions.map(\.id)))
        guard targetIds.isEmpty == false else { return }
        let idFilter = "in.(\(targetIds.joined(separator: ",")))"

        try await patch(
            table: "transaction_classifications",
            filters: [
                URLQueryItem(name: "account_owner_id", value: "eq.\(context.owner.id)"),
                URLQueryItem(name: "transaction_id", value: idFilter)
            ],
            body: ClassificationActivePatch(isActive: false),
            accessToken: context.session.accessToken
        )

        let classifications = targetIds.map { transactionId in
            TransactionClassificationCorrectionInsert(
                accountOwnerId: context.owner.id,
                transactionId: transactionId,
                categoryId: category.id,
                source: "user",
                confidence: 1,
                confidenceLevel: "high",
                reviewStatus: "reviewed",
                explanation: "Correção manual do usuário.",
                evidenceRedacted: [
                    "correctedBy": "account_owner",
                    "appliedToSimilar": applyToSimilar ? "true" : "false"
                ],
                isActive: true
            )
        }

        try await postRows(
            table: "transaction_classifications",
            rows: classifications,
            accessToken: context.session.accessToken
        )

        try await patch(
            table: "transactions",
            filters: [
                URLQueryItem(name: "account_owner_id", value: "eq.\(context.owner.id)"),
                URLQueryItem(name: "id", value: idFilter)
            ],
            body: TransactionReviewStatusPatch(reviewStatus: "reviewed"),
            accessToken: context.session.accessToken
        )

        if applyToSimilar {
            try await postRows(
                table: "classification_rules",
                rows: [
                    ClassificationRuleCorrectionInsert(
                        accountOwnerId: context.owner.id,
                        categoryId: category.id,
                        patternType: "description_contains",
                        patternValue: transaction.descriptionNormalized,
                        priority: 10,
                        createdFrom: "user_correction",
                        isActive: true
                    )
                ],
                accessToken: context.session.accessToken
            )
        }
    }

    private func getOwned<T: Decodable & Sendable>(table: String, ownerId: String, token: String) async throws -> [T] {
        try await get(
            table: table,
            select: "*",
            filters: [URLQueryItem(name: "account_owner_id", value: "eq.\(ownerId)")],
            accessToken: token
        )
    }

    private func get<T: Decodable & Sendable>(table: String, select: String, filters: [URLQueryItem], accessToken: String) async throws -> T {
        var items = [
            URLQueryItem(name: "select", value: select)
        ]
        items.append(contentsOf: filters)
        return try await request(path: "/rest/v1/\(table)", queryItems: items, body: Optional<Data>.none, accessToken: accessToken, method: "GET")
    }

    private func post<Body: Encodable, Response: Decodable & Sendable>(path: String, queryItems: [URLQueryItem], body: Body, accessToken: String?) async throws -> Response {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return try await request(path: path, queryItems: queryItems, body: encoder.encode(body), accessToken: accessToken, method: "POST")
    }

    private func postRows<Body: Encodable>(table: String, rows: Body, accessToken: String) async throws {
        try await send(
            path: "/rest/v1/\(table)",
            queryItems: [],
            body: rows,
            accessToken: accessToken,
            method: "POST"
        )
    }

    private func patch<Body: Encodable>(table: String, filters: [URLQueryItem], body: Body, accessToken: String) async throws {
        try await send(
            path: "/rest/v1/\(table)",
            queryItems: filters,
            body: body,
            accessToken: accessToken,
            method: "PATCH"
        )
    }

    private func send<Body: Encodable>(path: String, queryItems: [URLQueryItem], body: Body, accessToken: String, method: String) async throws {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let payload = try encoder.encode(body)

        guard var components = URLComponents(url: config.supabaseURL.appendingPathComponent(path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))), resolvingAgainstBaseURL: false) else {
            throw AppError.configuration("Supabase URL invalida.")
        }
        components.queryItems = queryItems.isEmpty ? nil : queryItems
        guard let url = components.url else {
            throw AppError.configuration("Supabase URL invalida.")
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = payload
        request.setValue(config.supabasePublishableKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AppError.network("Resposta invalida do Supabase.")
        }
        guard (200..<300).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "HTTP \(http.statusCode)"
            throw AppError.network(message)
        }
    }

    private func request<Response: Decodable & Sendable>(path: String, queryItems: [URLQueryItem], body: Data?, accessToken: String?, method: String) async throws -> Response {
        guard var components = URLComponents(url: config.supabaseURL.appendingPathComponent(path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))), resolvingAgainstBaseURL: false) else {
            throw AppError.configuration("Supabase URL invalida.")
        }
        components.queryItems = queryItems.isEmpty ? nil : queryItems
        guard let url = components.url else {
            throw AppError.configuration("Supabase URL invalida.")
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(config.supabasePublishableKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let accessToken {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AppError.network("Resposta invalida do Supabase.")
        }

        switch http.statusCode {
        case 200..<300:
            do {
                return try decoder.decode(Response.self, from: Self.sanitizedResponseData(data, path: path))
            } catch {
                throw AppError.unknown("Falha ao decodificar \(path): \(error)")
            }
        case 401:
            throw AppError.expiredSession
        case 403:
            throw AppError.permissionDenied
        default:
            let message = String(data: data, encoding: .utf8) ?? "HTTP \(http.statusCode)"
            throw AppError.network(message)
        }
    }

    private static func sanitizedResponseData(_ data: Data, path: String) -> Data {
        guard path.contains("/rest/v1/accounts"),
              let json = try? JSONSerialization.jsonObject(with: data),
              let sanitized = sanitize(json),
              JSONSerialization.isValidJSONObject(sanitized),
              let output = try? JSONSerialization.data(withJSONObject: sanitized)
        else {
            return data
        }
        return output
    }

    private static func sanitize(_ value: Any) -> Any? {
        if let array = value as? [Any] {
            return array.map { sanitize($0) ?? NSNull() }
        }

        if let dictionary = value as? [String: Any] {
            var sanitized: [String: Any] = [:]
            for (key, rawValue) in dictionary {
                if (key == "masked_identifier" || key == "maskedIdentifier"), rawValue is NSNull {
                    sanitized[key] = "****"
                } else {
                    sanitized[key] = sanitize(rawValue) ?? rawValue
                }
            }
            return sanitized
        }

        return value
    }
}

private struct PasswordAuthRequest: Encodable {
    let email: String
    let password: String
}

private struct TransactionIdRow: Decodable, Sendable {
    let id: String
}

private struct ClassificationActivePatch: Encodable {
    let isActive: Bool
}

private struct TransactionReviewStatusPatch: Encodable {
    let reviewStatus: String
}

private struct TransactionClassificationCorrectionInsert: Encodable {
    let accountOwnerId: String
    let transactionId: String
    let categoryId: String
    let source: String
    let confidence: Double
    let confidenceLevel: String
    let reviewStatus: String
    let explanation: String
    let evidenceRedacted: [String: String]
    let isActive: Bool
}

private struct ClassificationRuleCorrectionInsert: Encodable {
    let accountOwnerId: String
    let categoryId: String
    let patternType: String
    let patternValue: String
    let priority: Int
    let createdFrom: String
    let isActive: Bool
}

private struct PasswordAuthResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    let user: SupabaseUser
}

private struct SupabaseUser: Decodable {
    let id: String
    let email: String
}

private enum SupabaseDateParser {
    static func parse(_ value: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: value) {
            return date
        }
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: value) {
            return date
        }

        let dateOnlyFormatter = DateFormatter()
        dateOnlyFormatter.calendar = Calendar(identifier: .gregorian)
        dateOnlyFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateOnlyFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateOnlyFormatter.dateFormat = "yyyy-MM-dd"
        return dateOnlyFormatter.date(from: value)
    }
}
