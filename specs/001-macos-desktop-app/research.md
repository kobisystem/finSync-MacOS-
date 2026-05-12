# Research: FinSync macOS Desktop App

## Decision: Build as a native SwiftUI macOS app

**Rationale**: The product requirement explicitly excludes a packaged web application and asks for a macOS-integrated, installable desktop experience. SwiftUI provides native macOS navigation, state handling, accessibility integration, and AppKit interoperability when needed.

**Alternatives considered**:
- Packaged web app: rejected because it violates the feature scope.
- Cross-platform desktop shell: rejected for initial scope because it weakens native macOS integration and adds packaging/runtime complexity.
- AppKit-only app: rejected as the default because SwiftUI is better aligned with modern macOS view composition; AppKit remains available for focused native behaviors.

## Decision: Use `supabase-swift` for direct Supabase access

**Rationale**: Supabase documents an official Swift client package installable with Swift Package Manager. It supports Auth and database access needed by this app, allowing the macOS client to use the existing Supabase backend without creating a new backend layer.

**Alternatives considered**:
- Raw REST calls: rejected because it increases auth/session/error-handling burden and duplicates client behavior.
- New backend facade: rejected because no backend creation is allowed in this phase.
- Generated SQL client: rejected for initial scope because the existing direct Supabase client covers the required read and limited mutation flows.

## Decision: Use Supabase Auth session as the app authentication boundary

**Rationale**: The existing product already uses Supabase as the system of record and the spec requires no financial data before authentication. The app should treat a valid Supabase authenticated session as the boundary for all protected screens and queries, and should react to sign-in, sign-out, and expired-session states.

**Alternatives considered**:
- Local-only account unlock: rejected because it does not prove account-owner identity against the data source.
- Custom auth service: rejected because it creates new backend scope.
- Anonymous financial access: rejected by privacy and isolation requirements.

## Decision: Store secrets/session material in Keychain and recent financial cache in protected local app storage

**Rationale**: Clarification allows protected local cache of recent financial data and requires deletion on logout. Session credentials and keys belong in Keychain. Cached financial records should be scoped to the authenticated account owner, protected at rest, invalidated on logout, and never rendered before a valid session.

**Alternatives considered**:
- No local cache: rejected by clarification because the app should support continuity when a refresh fails.
- Plain files only: rejected because financial data requires protected storage.
- Full offline-first replica: rejected because offline complete usage is out of scope.

## Decision: Treat Supabase as source of truth and perform only client-side presentation aggregation

**Rationale**: The backend and processed data already exist. The macOS app should not recalculate forecasts or mutate immutable financial facts. Dashboard/KPI computations can organize existing records for presentation, while forecasts are displayed from existing forecast records with their stored confidence.

**Alternatives considered**:
- Local forecast engine: rejected because forecasts already exist and local recalculation is out of scope.
- Local OFX/PDF processing: rejected explicitly by scope.
- Manual transaction creation: rejected explicitly by scope.

## Decision: Guard review mutations with conflict detection

**Rationale**: Classification corrections must preserve history and leave exactly one active classification. Clarification requires blocking save when the transaction, review status, or active classification changed since load. The client should compare the loaded version/state to the current server state before applying a correction.

**Alternatives considered**:
- Last-write-wins: rejected because it risks overwriting financial review work.
- Save and warn later: rejected because it can create incorrect active-classification history.
- Locking the whole review queue: rejected as unnecessary for a single-user desktop MVP.

## Decision: Aggregate monetary values by currency

**Rationale**: Clarification requires not summing different currencies. Dashboard and KPI components should group totals by currency and display separate totals when multiple currencies exist.

**Alternatives considered**:
- Convert currencies locally: rejected because exchange-rate sourcing and auditability are outside initial scope.
- Hide non-BRL values: rejected because it conceals user data.
- Sum all values with a warning: rejected because it produces misleading totals.

## Decision: Use deterministic refresh triggers instead of continuous polling

**Rationale**: Clarification requires refresh on app open, window return, and manual action. This gives recurring desktop users current data without constant polling or unnecessary Supabase load.

**Alternatives considered**:
- Manual-only refresh: rejected because it makes desktop recurrence less reliable.
- Fixed-interval polling: rejected because it is outside current scope and adds rate/energy concerns.
- Realtime subscriptions everywhere: deferred until a later phase if live collaboration or processing progress requires it.

## Decision: Test domain rules independently from UI flows

**Rationale**: Core correctness risks are financial aggregation, account-owner filtering, masking, cache deletion, review conflicts, and active-classification invariants. These should be covered by fast unit/contract tests, while XCUITest covers the critical user journeys.

**Alternatives considered**:
- UI-only testing: rejected because it is brittle and slow for financial rules.
- Manual QA only: rejected because data isolation and financial calculations need repeatable verification.
- Full live Supabase integration for every test: rejected for speed and determinism; reserve live checks for quickstart/smoke validation.
