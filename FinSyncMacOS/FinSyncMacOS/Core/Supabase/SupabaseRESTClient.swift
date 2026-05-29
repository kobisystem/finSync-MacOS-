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
    public var creditCardStatements: [CreditCardStatement]
    public var balanceSnapshots: [BalanceSnapshot]
    public var monthlyPeriods: [MonthlyPeriod]
    public var obligations: [Obligation]
    public var forecastMatrix: CashFlowForecastMatrix
    public var auditEvents: [AuditEvent]
    public var refreshedAt: Date

    public init(
        owner: AccountOwner,
        accounts: [Account] = [],
        imports: [ImportFile] = [],
        transactions: [Transaction] = [],
        categories: [Category] = [],
        classifications: [TransactionClassification] = [],
        creditCardStatements: [CreditCardStatement] = [],
        balanceSnapshots: [BalanceSnapshot] = [],
        monthlyPeriods: [MonthlyPeriod] = [],
        obligations: [Obligation] = [],
        forecastMatrix: CashFlowForecastMatrix,
        auditEvents: [AuditEvent] = [],
        refreshedAt: Date = Date()
    ) {
        self.owner = owner
        self.accounts = accounts
        self.imports = imports
        self.transactions = transactions
        self.categories = categories
        self.classifications = classifications
        self.creditCardStatements = creditCardStatements
        self.balanceSnapshots = balanceSnapshots
        self.monthlyPeriods = monthlyPeriods
        self.obligations = obligations
        self.forecastMatrix = forecastMatrix
        self.auditEvents = auditEvents
        self.refreshedAt = refreshedAt
    }

    public static func empty(owner: AccountOwner) -> FinancialSnapshot {
        FinancialSnapshot(
            owner: owner,
            forecastMatrix: CashFlowForecastMatrix.empty(startMonth: Calendar(identifier: .gregorian).date(from: Calendar(identifier: .gregorian).dateComponents([.year], from: Date())) ?? Date(), months: 12, defaultWindow: true),
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
        async let creditCardStatements: [CreditCardStatement] = getOwnedOptional(table: "credit_card_statements", ownerId: context.owner.id, token: context.session.accessToken)
        async let balanceSnapshots: [BalanceSnapshot] = getOwnedOptional(table: "balance_snapshots", ownerId: context.owner.id, token: context.session.accessToken)
        async let monthlyPeriods: [MonthlyPeriod] = getOwnedOptional(table: "monthly_periods", ownerId: context.owner.id, token: context.session.accessToken)
        async let obligations: [Obligation] = getOwnedOptional(table: "obligations", ownerId: context.owner.id, token: context.session.accessToken)
        async let forecastMatrix = fetchCashFlowForecastMatrixOwned(ownerId: context.owner.id, token: context.session.accessToken, months: 36, startMonth: nil)
        async let auditEvents: [AuditEvent] = getOwned(table: "audit_events", ownerId: context.owner.id, token: context.session.accessToken)

        return try await FinancialSnapshot(
            owner: context.owner,
            accounts: accounts,
            imports: imports,
            transactions: transactions,
            categories: categories,
            classifications: classifications,
            creditCardStatements: creditCardStatements,
            balanceSnapshots: balanceSnapshots,
            monthlyPeriods: monthlyPeriods,
            obligations: obligations,
            forecastMatrix: forecastMatrix,
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

    /// US5: marks a monthly period as open/reviewed/closed. Requires an existing
    /// monthly_periods row (the worker creates it); the client only updates it.
    public func updateMonthlyPeriodStatus(
        context: SupabaseSessionContext,
        periodId: String,
        status: MonthlyPeriodStatus
    ) async throws {
        let now = Self.isoTimestamp(Date())
        var body: [String: String] = ["status": status.rawValue, "updated_at": now]
        switch status {
        case .reviewed: body["reviewed_at"] = now
        case .closed: body["closed_at"] = now
        case .open: break
        }

        try await patch(
            table: "monthly_periods",
            filters: [
                URLQueryItem(name: "account_owner_id", value: "eq.\(context.owner.id)"),
                URLQueryItem(name: "id", value: "eq.\(periodId)")
            ],
            body: body,
            accessToken: context.session.accessToken
        )
    }

    /// FR-018: records a manual balance observation. Does not create a financial
    /// transaction. RLS only allows inserting snapshots with source `manual`.
    public func insertManualBalanceSnapshot(
        context: SupabaseSessionContext,
        accountId: String,
        snapshotDate: Date,
        balanceAmount: Decimal
    ) async throws {
        let row = ManualBalanceSnapshotInsert(
            accountOwnerId: context.owner.id,
            accountId: accountId,
            snapshotDate: Self.monthDateString(snapshotDate),
            balanceAmount: balanceAmount,
            source: "manual",
            confidence: "normal"
        )

        try await postRows(
            table: "balance_snapshots",
            rows: [row],
            accessToken: context.session.accessToken
        )
    }

    /// Requests server-side forecast regeneration. The worker consumes this
    /// request with the service role and creates a new forecast_run.
    public func requestForecastRegeneration(
        context: SupabaseSessionContext,
        startMonth: Date,
        months: Int
    ) async throws -> String {
        guard (1...36).contains(months) else {
            throw AppError.validation("Horizonte de previsão inválido. Use valores entre 1 e 36 meses.")
        }

        let requestId = UUID().uuidString
        let row = ForecastRefreshRequestInsert(
            id: requestId,
            accountOwnerId: context.owner.id,
            requestedBy: context.owner.id,
            startMonth: Self.monthDateString(startMonth),
            monthsAhead: months,
            status: "pending"
        )

        try await postRows(
            table: "forecast_refresh_requests",
            rows: [row],
            accessToken: context.session.accessToken
        )
        return requestId
    }

    public func waitForForecastRegeneration(
        context: SupabaseSessionContext,
        requestId: String,
        timeoutSeconds: TimeInterval = 90
    ) async throws {
        let deadline = Date().addingTimeInterval(timeoutSeconds)

        while Date() < deadline {
            let rows: [ForecastRefreshRequestRow] = try await get(
                table: "forecast_refresh_requests",
                select: "id,status,forecast_run_id,error_message",
                filters: [
                    URLQueryItem(name: "account_owner_id", value: "eq.\(context.owner.id)"),
                    URLQueryItem(name: "id", value: "eq.\(requestId)"),
                    URLQueryItem(name: "limit", value: "1")
                ],
                accessToken: context.session.accessToken
            )

            guard let row = rows.first else {
                throw AppError.network("Solicitação de previsão não encontrada.")
            }

            switch row.status {
            case "completed":
                return
            case "error":
                throw AppError.network(row.errorMessage ?? "Falha ao reprocessar previsão.")
            default:
                try await Task.sleep(nanoseconds: 3_000_000_000)
            }
        }

        throw AppError.network("Tempo limite ao aguardar reprocessamento da previsão.")
    }

    private func getOwned<T: Decodable & Sendable>(table: String, ownerId: String, token: String) async throws -> [T] {
        try await get(
            table: table,
            select: "*",
            filters: [URLQueryItem(name: "account_owner_id", value: "eq.\(ownerId)")],
            accessToken: token
        )
    }

    /// Like `getOwned` but tolerates tables that are not present in the Supabase
    /// schema yet (returns an empty array instead of failing the whole snapshot).
    private func getOwnedOptional<T: Decodable & Sendable>(table: String, ownerId: String, token: String) async throws -> [T] {
        do {
            return try await getOwned(table: table, ownerId: ownerId, token: token)
        } catch let error as AppError {
            if case .network(let message) = error,
               message.contains("PGRST205") || message.contains("PGRST204") || message.contains(table) {
                return []
            }
            throw error
        }
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

private struct ManualBalanceSnapshotInsert: Encodable {
    let accountOwnerId: String
    let accountId: String
    let snapshotDate: String
    let balanceAmount: Decimal
    let source: String
    let confidence: String
}

private struct ForecastRefreshRequestInsert: Encodable {
    let id: String
    let accountOwnerId: String
    let requestedBy: String
    let startMonth: String
    let monthsAhead: Int
    let status: String
}

private struct ForecastRefreshRequestRow: Decodable, Sendable {
    let id: String
    let status: String
    let forecastRunId: String?
    let errorMessage: String?
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

private extension SupabaseRESTClient {
    func fetchCashFlowForecastMatrixOwned(ownerId: String, token: String, months: Int, startMonth: Date?) async throws -> CashFlowForecastMatrix {
        guard (1...36).contains(months) else {
            throw AppError.validation("Horizonte de previsão inválido. Use valores entre 1 e 36 meses.")
        }

        let resolvedStartMonth = startMonth ?? Self.defaultForecastStartMonth()
        let resolvedMonths = Self.resolveForecastMonths(start: resolvedStartMonth, count: months)
        let startMonthQuery = Self.monthDateString(resolvedStartMonth)
        let runs: [ForecastRunRow]
        do {
            runs = try await get(
                table: "forecast_runs",
                select: "id,start_month,months_ahead,default_window,initial_balance,generated_at",
                filters: [
                    URLQueryItem(name: "account_owner_id", value: "eq.\(ownerId)"),
                    URLQueryItem(name: "start_month", value: "eq.\(startMonthQuery)"),
                    URLQueryItem(name: "order", value: "generated_at.desc"),
                    URLQueryItem(name: "limit", value: "1")
                ],
                accessToken: token
            )
        } catch {
            if Self.isMissingForecastMatrixSchemaError(error) {
                throw AppError.configuration("Schema de forecast 004 não aplicado no Supabase. Execute as migrations mais recentes.")
            }
            throw error
        }

        guard let run = runs.first else {
            return CashFlowForecastMatrix.empty(startMonth: resolvedStartMonth, months: months, defaultWindow: startMonth == nil)
        }

        let totalsRows: [ForecastMonthTotalRow]
        let categoryRows: [ForecastCategoryLineRow]
        do {
            totalsRows = try await get(
                table: "forecast_month_totals",
                select: "month,total_income,total_expense,net_result,accumulated_balance,confidence,basis_summary",
                filters: [
                    URLQueryItem(name: "account_owner_id", value: "eq.\(ownerId)"),
                    URLQueryItem(name: "forecast_run_id", value: "eq.\(run.id)"),
                    URLQueryItem(name: "order", value: "month.asc")
                ],
                accessToken: token
            )

            categoryRows = try await get(
                table: "forecast_category_lines",
                select: "category_id,category_name_snapshot,category_kind,month,projected_amount,calculation_basis,confidence,notes",
                filters: [
                    URLQueryItem(name: "forecast_run_id", value: "eq.\(run.id)"),
                    URLQueryItem(name: "order", value: "month.asc")
                ],
                accessToken: token
            )
        } catch {
            if Self.isMissingForecastMatrixSchemaError(error) {
                throw AppError.configuration("Schema de forecast 004 não aplicado no Supabase. Execute as migrations mais recentes.")
            }
            throw error
        }

        let monthKeySet = Set(resolvedMonths.map(Self.monthKey))

        let categoryLines = categoryRows.compactMap { row -> CashFlowForecastCategoryLine? in
            guard monthKeySet.contains(Self.monthKey(row.month)) else { return nil }
            let categoryKind = CategoryKind(rawValue: row.categoryKind) ?? .expense
            let calculationBasis = ForecastCalculationBasis(rawValue: row.calculationBasis) ?? .noHistory
            let confidence = ForecastConfidence(rawValue: row.confidence) ?? .low
            return CashFlowForecastCategoryLine(
                categoryId: row.categoryId ?? "00000000-0000-0000-0000-000000000999",
                categoryName: row.categoryNameSnapshot,
                categoryKind: categoryKind,
                month: row.month,
                projectedAmount: row.projectedAmount.value,
                calculationBasis: calculationBasis,
                confidence: confidence,
                notes: row.notes
            )
        }

        let totalsByMonth = Dictionary(uniqueKeysWithValues: totalsRows.map { (Self.monthKey($0.month), $0) })
        let monthlyTotals = resolvedMonths.map { month -> CashFlowForecastMonthlyTotal in
            if let row = totalsByMonth[Self.monthKey(month)] {
                return CashFlowForecastMonthlyTotal(
                    month: month,
                    totalIncome: row.totalIncome.value,
                    totalExpense: row.totalExpense.value,
                    netResult: row.netResult.value,
                    accumulatedBalance: row.accumulatedBalance.value,
                    confidence: ForecastConfidence(rawValue: row.confidence) ?? .low,
                    basisSummary: row.basisSummary ?? ""
                )
            }

            return CashFlowForecastMonthlyTotal(
                month: month,
                totalIncome: 0,
                totalExpense: 0,
                netResult: 0,
                accumulatedBalance: 0,
                confidence: .low,
                basisSummary: "Sem dados"
            )
        }

        let metadata = CashFlowForecastMetadata(
            generatedAt: run.generatedAt,
            startMonth: resolvedStartMonth,
            months: months,
            initialBalance: run.initialBalance.value,
            defaultWindow: run.defaultWindow
        )

        return CashFlowForecastMatrix(
            metadata: metadata,
            months: resolvedMonths,
            categoryLines: categoryLines,
            monthlyTotals: monthlyTotals
        )
    }

    static func defaultForecastStartMonth() -> Date {
        let calendar = Calendar(identifier: .gregorian)
        return calendar.date(from: calendar.dateComponents([.year], from: Date())) ?? Date()
    }

    static func resolveForecastMonths(start: Date, count: Int) -> [Date] {
        CashFlowForecastMatrix.resolveMonths(start: start, count: count)
    }

    static func monthKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: date)
    }

    static func monthDateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    static func isoTimestamp(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: date)
    }

    static func isMissingForecastMatrixSchemaError(_ error: any Error) -> Bool {
        guard case .network(let message) = (error as? AppError) else {
            return false
        }

        return message.contains("PGRST205")
            || message.contains("forecast_runs")
            || message.contains("forecast_month_totals")
            || message.contains("forecast_category_lines")
    }
}

/// PostgREST returns `numeric`/`decimal` columns as JSON strings by default to
/// preserve precision. Foundation's default `Decimal` decoder only accepts JSON
/// numbers, so direct decoding drops rows silently. This wrapper accepts both.
struct SupabaseDecimal: Decodable, Sendable {
    let value: Decimal

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let direct = try? container.decode(Decimal.self) {
            self.value = direct
            return
        }
        let raw = try container.decode(String.self)
        guard let parsed = Decimal(string: raw, locale: Locale(identifier: "en_US_POSIX")) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid decimal string: \(raw)"
            )
        }
        self.value = parsed
    }
}

private struct ForecastRunRow: Decodable, Sendable {
    let id: String
    let startMonth: Date
    let monthsAhead: Int
    let defaultWindow: Bool
    let initialBalance: SupabaseDecimal
    let generatedAt: Date
}

private struct ForecastMonthTotalRow: Decodable, Sendable {
    let month: Date
    let totalIncome: SupabaseDecimal
    let totalExpense: SupabaseDecimal
    let netResult: SupabaseDecimal
    let accumulatedBalance: SupabaseDecimal
    let confidence: String
    let basisSummary: String?
}

private struct ForecastCategoryLineRow: Decodable, Sendable {
    let categoryId: String?
    let categoryNameSnapshot: String
    let categoryKind: String
    let month: Date
    let projectedAmount: SupabaseDecimal
    let calculationBasis: String
    let confidence: String
    let notes: String?
}
