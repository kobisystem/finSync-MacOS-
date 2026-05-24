# Tasks: FinSync macOS Desktop App

**Input**: Design documents from `/Users/marciomorais/Sites/finSync-MacOS/specs/001-macos-desktop-app/`
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/`, `quickstart.md`

**Tests**: Included because the feature specification and quickstart define independent tests, automated test targets, and measurable success criteria for financial correctness, auth isolation, cache behavior, review conflicts, and UI flows.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel because it writes different files and does not depend on incomplete tasks.
- **[Story]**: Maps a task to a user story phase only.
- Every task includes an exact file or directory path.

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create the native macOS project skeleton, configuration placeholders, and test target structure.

- [X] T001 Create the native macOS Xcode project at `FinSyncMacOS/FinSyncMacOS.xcodeproj`
- [X] T002 Configure the app target, test targets, macOS 14+ deployment target, and `supabase-swift` package dependency in `FinSyncMacOS/FinSyncMacOS.xcodeproj/project.pbxproj`
- [X] T003 [P] Create source directory structure under `FinSyncMacOS/FinSyncMacOS/`
- [X] T004 [P] Create unit test directory structure under `FinSyncMacOS/FinSyncMacOSTests/`
- [X] T005 [P] Create UI test directory structure under `FinSyncMacOS/FinSyncMacOSUITests/`
- [X] T006 [P] Add app configuration template for Supabase URL and publishable key in `FinSyncMacOS/FinSyncMacOS/Core/Config/AppConfig.swift`
- [X] T007 [P] Add test fixture bundle with account owners, accounts, transactions, imports, categories, forecasts, audit events, card payments, and multi-currency records in `FinSyncMacOS/FinSyncMacOSTests/Fixtures/FinSyncFixtures.json`
- [X] T008 [P] Add repository README with local configuration and secret-handling guidance in `FinSyncMacOS/README.md`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core domain, Supabase, auth boundary, cache, error, and state infrastructure required by all user stories.

**CRITICAL**: No user story work can begin until this phase is complete.

### Tests for Foundation

- [X] T009 [P] Add fixture decoding tests for all shared domain entities in `FinSyncMacOS/FinSyncMacOSTests/Domain/DomainDecodingTests.swift`
- [X] T010 [P] Add money aggregation tests for currency separation and no mixed-currency totals in `FinSyncMacOS/FinSyncMacOSTests/Domain/MoneyAggregationTests.swift`
- [X] T011 [P] Add error mapping tests for no session, expired session, network failure, permission denied, empty result, review conflict, and cache unavailable in `FinSyncMacOS/FinSyncMacOSTests/Repositories/ErrorMappingTests.swift`
- [X] T012 [P] Add protected cache tests for auth-before-display, account-owner scoping, stale marking, and logout deletion in `FinSyncMacOS/FinSyncMacOSTests/Core/ProtectedCacheTests.swift`

### Implementation for Foundation

- [X] T013 [P] Implement shared domain models for `AccountOwner`, `Account`, `ImportFile`, `Transaction`, and `CreditCardStatement` in `FinSyncMacOS/FinSyncMacOS/Domain/Models/FinancialCoreModels.swift`
- [X] T014 [P] Implement shared domain models for `Category`, `TransactionClassification`, `ClassificationRule`, `CashFlowForecast`, and `AuditEvent` in `FinSyncMacOS/FinSyncMacOS/Domain/Models/ClassificationForecastAuditModels.swift`
- [X] T015 [P] Implement `Money`, `CurrencyCode`, and grouped monetary totals in `FinSyncMacOS/FinSyncMacOS/Domain/Models/Money.swift`
- [X] T016 [P] Implement domain state enums for import status, review status, transaction type, statement status, classification source, forecast confidence, and app load state in `FinSyncMacOS/FinSyncMacOS/Domain/Models/DomainState.swift`
- [X] T017 Implement Supabase client factory and dependency injection entry point in `FinSyncMacOS/FinSyncMacOS/Core/Supabase/SupabaseClientFactory.swift`
- [X] T018 [P] Implement repository protocols for auth, account owner, financial reads, review mutations, cache, and audit access in `FinSyncMacOS/FinSyncMacOS/Domain/Repositories/RepositoryProtocols.swift`
- [X] T019 [P] Implement app-level error types and user-facing error mapping in `FinSyncMacOS/FinSyncMacOS/Core/Errors/AppError.swift`
- [X] T020 [P] Implement Keychain-backed session storage wrapper in `FinSyncMacOS/FinSyncMacOS/Core/Auth/KeychainSessionStore.swift`
- [X] T021 Implement protected local cache service scoped by `account_owner_id` in `FinSyncMacOS/FinSyncMacOS/Core/Cache/ProtectedFinancialCache.swift`
- [X] T022 Implement root app state model for unauthenticated, authenticated loading, ready, stale, expired, and error states in `FinSyncMacOS/FinSyncMacOS/App/AppState.swift`
- [X] T023 Implement root SwiftUI app entry and native macOS window shell in `FinSyncMacOS/FinSyncMacOS/App/FinSyncMacOSApp.swift`
- [X] T024 Implement authenticated desktop navigation shell for Dashboard, Imports, Accounts, Transactions, Review, Categories, KPIs, Forecast, and Audit in `FinSyncMacOS/FinSyncMacOS/App/AppShellView.swift`
- [X] T025 Implement shared loading, empty, stale, permission, and recoverable error views in `FinSyncMacOS/FinSyncMacOS/Features/Shared/LoadableStateViews.swift`

**Checkpoint**: Foundation ready. User story implementation can now begin in parallel.

---

## Phase 3: User Story 1 - Acessar dados financeiros com sessao segura (Priority: P1) MVP

**Goal**: User can open the app, authenticate, see only their own protected data shell, handle expired/denied sessions, and sign out without leaving financial data visible.

**Independent Test**: Launch without a session, verify no financial data is visible, authenticate with a valid account owner, verify the protected shell loads only that account owner, then sign out and verify cache/UI are cleared.

### Tests for User Story 1

- [X] T026 [P] [US1] Add auth state unit tests for unauthenticated, signed in, signed out, expired session, and missing account owner in `FinSyncMacOS/FinSyncMacOSTests/ViewModels/AuthViewModelTests.swift`
- [X] T027 [P] [US1] Add account-owner isolation repository tests using two fixture users in `FinSyncMacOS/FinSyncMacOSTests/Repositories/AccountOwnerIsolationTests.swift`
- [X] T028 [P] [US1] Add UI tests for unauthenticated launch, successful sign-in, session expired lock, and logout clearing protected UI in `FinSyncMacOS/FinSyncMacOSUITests/AuthFlowTests.swift`

### Implementation for User Story 1

- [X] T029 [US1] Implement Supabase auth repository for sign-in, auth-state observation, session refresh, and sign-out in `FinSyncMacOS/FinSyncMacOS/Core/Auth/SupabaseAuthRepository.swift`
- [X] T030 [US1] Implement account owner repository scoped to authenticated session in `FinSyncMacOS/FinSyncMacOS/Core/Supabase/AccountOwnerRepository.swift`
- [X] T031 [US1] Implement `AuthViewModel` with auth, missing-owner, session-expired, permission-denied, and logout states in `FinSyncMacOS/FinSyncMacOS/Features/Auth/AuthViewModel.swift`
- [X] T032 [US1] Implement native authentication view with loading and error states in `FinSyncMacOS/FinSyncMacOS/Features/Auth/AuthView.swift`
- [X] T033 [US1] Connect auth state to `AppState` and prevent protected shell rendering before valid session in `FinSyncMacOS/FinSyncMacOS/App/AppCoordinator.swift`
- [X] T034 [US1] Implement logout flow that clears Supabase session, protected cache, and visible financial state in `FinSyncMacOS/FinSyncMacOS/Core/Auth/LogoutUseCase.swift`

**Checkpoint**: User Story 1 is fully functional and testable independently as the MVP.

---

## Phase 4: User Story 2 - Acompanhar a saude financeira do mes (Priority: P1)

**Goal**: Authenticated user sees the current-month dashboard with income, expenses, net result, review count, recent imports, forecast confidence, last update, refresh triggers, stale cache handling, and no duplicated card payments.

**Independent Test**: Authenticate with fixture data, open Dashboard, verify current-month metrics, review count, recent imports, forecast confidence, last update timestamp, manual/window refresh, empty state, stale state, and card-payment exclusion.

### Tests for User Story 2

- [X] T035 [P] [US2] Add dashboard summary calculator tests for income, expense, net result, review count, recent imports, forecast confidence, card-payment exclusion, and currency grouping in `FinSyncMacOS/FinSyncMacOSTests/Domain/DashboardSummaryTests.swift`
- [X] T036 [P] [US2] Add dashboard repository contract tests with mocked Supabase responses and account-owner filters in `FinSyncMacOS/FinSyncMacOSTests/Repositories/DashboardRepositoryTests.swift`
- [X] T037 [P] [US2] Add UI tests for dashboard ready, empty, stale, recoverable error, manual refresh, and window-return refresh states in `FinSyncMacOS/FinSyncMacOSUITests/DashboardFlowTests.swift`

### Implementation for User Story 2

- [X] T038 [P] [US2] Implement `DashboardSummary`, `RecentImportStatus`, and `LastRefreshState` models in `FinSyncMacOS/FinSyncMacOS/Domain/Models/DashboardModels.swift`
- [X] T039 [US2] Implement dashboard repository reads for current-month transactions, active classifications, recent imports, and forecast records in `FinSyncMacOS/FinSyncMacOS/Core/Supabase/DashboardRepository.swift`
- [X] T040 [US2] Implement dashboard summary calculator with card-payment exclusion and currency grouping in `FinSyncMacOS/FinSyncMacOS/Domain/UseCases/DashboardSummaryCalculator.swift`
- [X] T041 [US2] Implement dashboard refresh coordinator for app open, window active, manual refresh, cache fallback, and stale markers in `FinSyncMacOS/FinSyncMacOS/Features/Dashboard/DashboardRefreshCoordinator.swift`
- [X] T042 [US2] Implement `DashboardViewModel` with loading, ready, empty, stale, recoverable error, and permission-denied states in `FinSyncMacOS/FinSyncMacOS/Features/Dashboard/DashboardViewModel.swift`
- [X] T043 [US2] Implement native dashboard screen and navigation actions to Review and Import detail in `FinSyncMacOS/FinSyncMacOS/Features/Dashboard/DashboardView.swift`

**Checkpoint**: Dashboard works independently after authentication and can be validated without other detailed screens.

---

## Phase 5: User Story 3 - Revisar classificacoes pendentes sem perder contexto (Priority: P1)

**Goal**: User can review pending classifications, confirm or correct categories, preserve history, leave exactly one active classification, handle conflicts safely, optionally create rules only after explicit confirmation, and return to dashboard context.

**Independent Test**: Load a `needs_review` fixture, confirm a suggestion, correct another category, verify review status and classification invariants, simulate conflict, verify blocked save/reload, and return to Dashboard with prior context.

### Tests for User Story 3

- [X] T044 [P] [US3] Add review invariant tests for one active classification, preserved history, reviewed status, active category requirement, and optional rule confirmation in `FinSyncMacOS/FinSyncMacOSTests/Domain/ReviewClassificationTests.swift`
- [X] T045 [P] [US3] Add review repository contract tests for confirm, correct, conflict detection, and explicit rule creation in `FinSyncMacOS/FinSyncMacOSTests/Repositories/ReviewRepositoryTests.swift`
- [X] T046 [P] [US3] Add UI tests for review queue, confirm, correct, rule prompt, conflict reload, save error, and return-to-dashboard context in `FinSyncMacOS/FinSyncMacOSUITests/ReviewFlowTests.swift`

### Implementation for User Story 3

- [X] T047 [P] [US3] Implement `ReviewItem`, `ReviewLoadedState`, `ReviewCorrection`, and `RuleSuggestion` models in `FinSyncMacOS/FinSyncMacOS/Domain/Models/ReviewModels.swift`
- [X] T048 [US3] Implement review queue reads with loaded-state snapshots in `FinSyncMacOS/FinSyncMacOS/Core/Supabase/ReviewQueueRepository.swift`
- [X] T049 [US3] Implement guarded review mutation repository for confirm, correct, conflict check, audit reflection, and optional rule creation in `FinSyncMacOS/FinSyncMacOS/Core/Supabase/ReviewMutationRepository.swift`
- [X] T050 [US3] Implement review use case enforcing classification history, one active classification, active category selection, and conflict blocking in `FinSyncMacOS/FinSyncMacOS/Domain/UseCases/ReviewClassificationUseCase.swift`
- [X] T051 [US3] Implement `ReviewViewModel` with queue, saving, conflict, rule confirmation, save error, and return-context states in `FinSyncMacOS/FinSyncMacOS/Features/Review/ReviewViewModel.swift`
- [X] T052 [US3] Implement review queue and detail UI with category picker, confidence/explanation display, confirm/correct actions, and conflict prompt in `FinSyncMacOS/FinSyncMacOS/Features/Review/ReviewView.swift`
- [X] T053 [US3] Implement dashboard-to-review context preservation and return navigation in `FinSyncMacOS/FinSyncMacOS/App/NavigationContext.swift`

**Checkpoint**: Classification review is independently functional and protects financial classification history.

---

## Phase 6: User Story 4 - Consultar importacoes, contas e transacoes (Priority: P2)

**Goal**: User can inspect imports, accounts, transactions, filters, relationships, immutable facts, masked identifiers, status reasons, and recent redacted history.

**Independent Test**: Authenticate with fixture data, open Imports/Accounts/Transactions, apply filters, verify status displays, masked identifiers, immutable read-only fields, relationships, and no raw sensitive content.

### Tests for User Story 4

- [X] T054 [P] [US4] Add import/account/transaction repository contract tests for status filtering, account-owner scoping, masked identifiers, and transaction filters in `FinSyncMacOS/FinSyncMacOSTests/Repositories/FinancialBrowseRepositoryTests.swift`
- [X] T055 [P] [US4] Add transaction filter and immutable-fact tests in `FinSyncMacOS/FinSyncMacOSTests/Domain/TransactionFilterTests.swift`
- [X] T056 [P] [US4] Add UI tests for Imports, Accounts, Transactions, filters, details, masked identifiers, and read-only immutable facts in `FinSyncMacOS/FinSyncMacOSUITests/BrowseFlowTests.swift`

### Implementation for User Story 4

- [X] T057 [P] [US4] Implement import list/detail models and status presentation helpers in `FinSyncMacOS/FinSyncMacOS/Domain/Models/ImportPresentationModels.swift`
- [X] T058 [P] [US4] Implement transaction filter and transaction detail presentation models in `FinSyncMacOS/FinSyncMacOS/Domain/Models/TransactionPresentationModels.swift`
- [X] T059 [US4] Implement imports repository with status filters, metadata fields, processing timestamps, and recent audit history in `FinSyncMacOS/FinSyncMacOS/Core/Supabase/ImportsRepository.swift`
- [X] T060 [US4] Implement accounts repository with masked identifier enforcement in `FinSyncMacOS/FinSyncMacOS/Core/Supabase/AccountsRepository.swift`
- [X] T061 [US4] Implement transactions repository with period, account, category, type, origin, and review-status filters in `FinSyncMacOS/FinSyncMacOS/Core/Supabase/TransactionsRepository.swift`
- [X] T062 [US4] Implement imports view model and native imports list/detail UI in `FinSyncMacOS/FinSyncMacOS/Features/Imports/ImportsView.swift`
- [X] T063 [US4] Implement accounts view model and native accounts list UI in `FinSyncMacOS/FinSyncMacOS/Features/Accounts/AccountsView.swift`
- [X] T064 [US4] Implement transactions view model, filter controls, list, and read-only detail UI in `FinSyncMacOS/FinSyncMacOS/Features/Transactions/TransactionsView.swift`

**Checkpoint**: Browse and investigation workflows are independently functional after authentication.

---

## Phase 7: User Story 5 - Analisar KPIs mensais e forecast (Priority: P2)

**Goal**: User can analyze monthly KPIs, top categories, month evolution, and existing cash-flow forecasts while respecting currency separation, card-payment exclusion, history thresholds, confidence, and generated timestamps.

**Independent Test**: Load fixture accounts with fewer than 3 months, 3-11 months, and 12+ months, then verify KPI grouping, card-payment exclusion, forecast confidence presentation, insufficient-history messaging, and no local confidence overwrite.

### Tests for User Story 5

- [X] T065 [P] [US5] Add monthly KPI tests for month grouping, top categories, net result, card-payment exclusion, and separate currency totals in `FinSyncMacOS/FinSyncMacOSTests/Domain/MonthlyKPITests.swift`
- [X] T066 [P] [US5] Add forecast presentation tests for insufficient history, low confidence, normal/high confidence, basis summary, and generated timestamp in `FinSyncMacOS/FinSyncMacOSTests/Domain/ForecastPresentationTests.swift`
- [X] T067 [P] [US5] Add UI tests for KPIs and Forecast ready, empty, insufficient-history, and error states in `FinSyncMacOS/FinSyncMacOSUITests/AnalyticsFlowTests.swift`

### Implementation for User Story 5

- [X] T068 [P] [US5] Implement `MonthlyKPI`, `TopCategoryTotal`, `ForecastPresentation`, and `HistoryEligibility` models in `FinSyncMacOS/FinSyncMacOS/Domain/Models/AnalyticsModels.swift`
- [X] T069 [US5] Implement KPI repository reads for transactions, active classifications, categories, and accounts over selected month ranges in `FinSyncMacOS/FinSyncMacOS/Core/Supabase/KPIRepository.swift`
- [X] T070 [US5] Implement monthly KPI calculator with month grouping, category ranking, card-payment exclusion, and currency separation in `FinSyncMacOS/FinSyncMacOS/Domain/UseCases/MonthlyKPICalculator.swift`
- [X] T071 [US5] Implement forecast repository reads and history eligibility lookup in `FinSyncMacOS/FinSyncMacOS/Core/Supabase/ForecastRepository.swift`
- [X] T072 [US5] Implement forecast presentation use case that displays stored confidence without local recalculation in `FinSyncMacOS/FinSyncMacOS/Domain/UseCases/ForecastPresentationUseCase.swift`
- [X] T073 [US5] Implement KPIs view model and native monthly KPI UI in `FinSyncMacOS/FinSyncMacOS/Features/KPIs/KPIsView.swift`
- [X] T074 [US5] Implement forecast view model and native forecast UI in `FinSyncMacOS/FinSyncMacOS/Features/Forecast/ForecastView.swift`

**Checkpoint**: Analytics and forecast workflows are independently functional after authentication.

---

## Phase 8: User Story 6 - Consultar auditoria sem dados sensiveis brutos (Priority: P3)

**Goal**: User can inspect relevant import, error, classification, correction, and forecast audit events with redacted metadata only.

**Independent Test**: Open audit list/detail with fixture events and verify actor, event type, entity context, date, redacted metadata, empty state, and absence of raw sensitive content.

### Tests for User Story 6

- [X] T075 [P] [US6] Add audit repository contract tests for account-owner scoping, entity filters, redacted metadata, and empty state in `FinSyncMacOS/FinSyncMacOSTests/Repositories/AuditRepositoryTests.swift`
- [X] T076 [P] [US6] Add audit redaction display tests that reject raw document content and unmasked identifiers in `FinSyncMacOS/FinSyncMacOSTests/Domain/AuditRedactionTests.swift`
- [X] T077 [P] [US6] Add UI tests for audit list, detail, empty state, and no raw sensitive content in `FinSyncMacOS/FinSyncMacOSUITests/AuditFlowTests.swift`

### Implementation for User Story 6

- [X] T078 [P] [US6] Implement audit presentation models for event summary, entity context, actor, and redacted metadata in `FinSyncMacOS/FinSyncMacOS/Domain/Models/AuditPresentationModels.swift`
- [X] T079 [US6] Implement audit repository reads for import, error, classification, correction, deduplication, and forecast events in `FinSyncMacOS/FinSyncMacOS/Core/Supabase/AuditRepository.swift`
- [X] T080 [US6] Implement audit redaction guard for display payloads in `FinSyncMacOS/FinSyncMacOS/Domain/UseCases/AuditRedactionUseCase.swift`
- [X] T081 [US6] Implement audit view model and native audit list/detail UI in `FinSyncMacOS/FinSyncMacOS/Features/Audit/AuditView.swift`

**Checkpoint**: Redacted audit inspection is independently functional after authentication.

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Final quality, performance, packaging, accessibility, and quickstart validation across stories.

- [X] T082 [P] Add Brazilian Portuguese localization strings for all user-facing states in `FinSyncMacOS/FinSyncMacOS/Resources/pt-BR.lproj/Localizable.strings`
- [X] T083 [P] Add accessibility identifiers and labels for auth, dashboard, review, browsing, analytics, forecast, and audit UI tests in `FinSyncMacOS/FinSyncMacOS/Features/Shared/Accessibility.swift`
- [X] T084 [P] Add performance tests for dashboard and list loading with 1,000 visible fixture records in `FinSyncMacOS/FinSyncMacOSTests/Performance/ListPerformanceTests.swift`
- [X] T085 Add app packaging settings and local install validation notes in `FinSyncMacOS/FinSyncMacOS.xcodeproj/project.pbxproj`
- [X] T086 Add quickstart validation checklist results template in `specs/001-macos-desktop-app/quickstart-validation.md`
- [X] T087 Run the full quickstart smoke test and record results in `specs/001-macos-desktop-app/quickstart-validation.md`
- [X] T088 Run all unit and UI tests and record command output summary in `specs/001-macos-desktop-app/quickstart-validation.md`
- [X] T089 Review generated app bundle for absence of service-role secrets and document result in `specs/001-macos-desktop-app/quickstart-validation.md`
- [X] T090 Update implementation notes and known limitations in `FinSyncMacOS/README.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 Setup**: No dependencies.
- **Phase 2 Foundational**: Depends on Phase 1; blocks all user stories.
- **Phase 3 US1**: Depends on Phase 2; MVP scope.
- **Phase 4 US2**: Depends on Phase 2 and authentication shell from US1 for end-to-end demo, but its domain/repository/view-model tasks can be built after foundation.
- **Phase 5 US3**: Depends on Phase 2 and benefits from dashboard navigation in US2 for context preservation; review core remains independently testable.
- **Phase 6 US4**: Depends on Phase 2; can run after foundation.
- **Phase 7 US5**: Depends on Phase 2; can run after foundation.
- **Phase 8 US6**: Depends on Phase 2; can run after foundation.
- **Phase 9 Polish**: Depends on all selected user stories being complete.

### User Story Dependencies

- **US1 (P1)**: No story dependency; required MVP.
- **US2 (P1)**: Uses authenticated shell from US1 for user-facing access.
- **US3 (P1)**: Uses authenticated shell from US1; dashboard return-context integration depends on US2 navigation.
- **US4 (P2)**: Uses authenticated shell from US1; otherwise independently testable.
- **US5 (P2)**: Uses authenticated shell from US1; otherwise independently testable.
- **US6 (P3)**: Uses authenticated shell from US1; otherwise independently testable.

### Within Each User Story

- Tests first, expected to fail before implementation.
- Models before repositories/use cases.
- Repositories/use cases before view models.
- View models before SwiftUI views.
- Story checkpoint before moving to the next priority story.

---

## Parallel Opportunities

- Setup tasks T003-T008 can run in parallel after T001-T002 project creation decisions are stable.
- Foundation tests T009-T012 can run in parallel.
- Foundation model/error/cache protocol tasks T013-T020 can run in parallel before T021-T025 integration tasks.
- After Phase 2, US4, US5, and US6 can proceed in parallel with US2/US3 if separate developers own separate feature folders.
- Test files within each user story are parallelizable.
- Presentation models in US4, US5, and US6 are parallelizable because they write different files.

## Parallel Example: User Story 2

```text
Task: "T035 [P] [US2] Add dashboard summary calculator tests in FinSyncMacOS/FinSyncMacOSTests/Domain/DashboardSummaryTests.swift"
Task: "T036 [P] [US2] Add dashboard repository contract tests in FinSyncMacOS/FinSyncMacOSTests/Repositories/DashboardRepositoryTests.swift"
Task: "T037 [P] [US2] Add UI tests in FinSyncMacOS/FinSyncMacOSUITests/DashboardFlowTests.swift"
```

## Parallel Example: User Story 4

```text
Task: "T057 [P] [US4] Implement import list/detail models in FinSyncMacOS/FinSyncMacOS/Domain/Models/ImportPresentationModels.swift"
Task: "T058 [P] [US4] Implement transaction filter and detail models in FinSyncMacOS/FinSyncMacOS/Domain/Models/TransactionPresentationModels.swift"
Task: "T063 [US4] Implement accounts view model and native accounts list UI in FinSyncMacOS/FinSyncMacOS/Features/Accounts/AccountsView.swift"
```

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1 Setup.
2. Complete Phase 2 Foundation.
3. Complete Phase 3 US1.
4. Validate unauthenticated lock, sign-in, account-owner isolation, session-expired handling, and logout cache clearing.
5. Stop for MVP demo before adding dashboard and review.

### Incremental Delivery

1. Add US1 for secure authenticated shell.
2. Add US2 for recurring dashboard value.
3. Add US3 for classification review and data-quality improvement.
4. Add US4 for investigation and detailed browsing.
5. Add US5 for analytics and forecast planning.
6. Add US6 for redacted audit visibility.
7. Run Phase 9 quickstart and quality checks.

### Parallel Team Strategy

1. Complete Setup and Foundation together.
2. Assign feature folder ownership:
   - Developer A: `Features/Dashboard/` and dashboard domain files for US2.
   - Developer B: `Features/Review/` and review mutation files for US3.
   - Developer C: `Features/Imports/`, `Features/Accounts/`, `Features/Transactions/` for US4.
   - Developer D: `Features/KPIs/`, `Features/Forecast/`, `Features/Audit/` for US5/US6.
3. Keep shared repository protocols stable before parallel story work begins.

## Validation Checklist

- All tasks use `- [X] T###` checklist format.
- User story phase tasks include `[US#]` labels.
- Parallel tasks use `[P]` only when they target separate files or can run independently.
- Each user story has independent test criteria.
- Each user story has test tasks and implementation tasks.
- File paths are explicit for every task.
