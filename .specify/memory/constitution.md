# finSync-MacOS Constitution

## Core Principles

### I. Native Experience First

finSync-MacOS MUST provide a true native macOS experience (SwiftUI/AppKit), not a wrapped web experience.

User flows MUST prioritize clarity, fast readability of financial information, keyboard navigation where appropriate, and accessibility support for core screens.

### II. Engine Contract Fidelity

finSync-MacOS MUST treat `finSync` (engine) contracts and invariants as the source of truth for financial behavior.

The macOS client MUST NOT redefine business rules for import, classification, KPIs, forecast calculation basis, confidence semantics, or audit meaning.

When frontend needs a new behavior, the engine contract/spec MUST be updated first, then consumed by the client.

### III. Financial Fact Integrity In UI

The client MAY allow edits only for mutable metadata already supported by engine contracts (for example classification/category review outcomes).

The client MUST NOT expose or implement any path to mutate immutable source financial facts (original amount, original date, original description, source file identity, source transaction identity).

### IV. Privacy, Security, And Least Exposure

Financial information is sensitive. The app MUST minimize local data exposure by default.

Session material MUST be stored with platform-appropriate protection (for example Keychain). Local cache MUST be protected, scoped by account owner, and cleared on logout.

Logs and diagnostics MUST avoid unnecessary sensitive financial content.

### V. Deterministic UI State And Performance

Critical user flows MUST have deterministic loading, success, empty, and error states.

The app MUST provide explicit failure feedback for data fetch, session expiry, and mutation conflicts.

Performance targets for core flows:

- authenticated user reaches actionable dashboard in <= 30 seconds;
- common list screens (up to 1,000 visible rows) resolve in <= 3 seconds on normal connectivity;
- classification review action completes in <= 3 user interactions after opening the queue.

### VI. Testable Frontend Behavior

Every feature affecting dashboard, imports, transactions, review, KPIs, forecast, or audit visualization MUST include test coverage for:

- loading/error/empty/success states;
- account-owner isolation in presented data;
- protected-session behavior;
- expected mutation constraints;
- forecast readability of totals, net result, accumulated balance, confidence, and basis.

XCTest MUST cover domain/view-model logic. XCUITest MUST cover critical end-to-end desktop flows.

## Data And State Boundaries

Supabase data provided by the existing engine-backed schema is the canonical backend state.

finSync-MacOS local storage is a derived cache and MUST never be treated as a canonical financial source.

Client-side computed presentation values MUST remain reconcilable with backend records.

## Development Workflow

All meaningful product work MUST start from a specification.

Expected workflow:

1. Create or update feature spec.
2. Clarify ambiguous requirements.
3. Produce implementation plan.
4. Derive tasks.
5. Implement with focused commits.
6. Validate acceptance scenarios with automated tests.
7. Update specs when intended behavior changes.

For behavior changes crossing frontend/backend boundaries:

1. Update or confirm engine contract/spec in `finSync`.
2. Align macOS plan/tasks with the approved contract.
3. Implement client-side adaptation.

## Quality Gates

Before a frontend feature is complete, it MUST satisfy:

- acceptance scenarios implemented and verified;
- no path that mutates immutable financial source facts;
- account-owner isolation validated for all touched screens;
- session expiration and recovery behavior explicitly handled;
- errors are actionable and non-silent;
- forecast/KPI displays reconcile with contract semantics;
- tests updated at appropriate levels (XCTest/XCUITest).

## Language And Communication

Project working language for specifications, clarification, planning, and user-facing documentation is Brazilian Portuguese.

Code identifiers, API fields, schema names, and framework-specific terms MAY remain in English.

## Governance

This constitution governs finSync-MacOS specs, plans, tasks, and implementation decisions.

In case of conflict with client-side convenience, engine invariants and data integrity rules prevail.

Amendments MUST be intentional, versioned, and reflected in dependent templates/workflows.

**Version**: 1.0.0
**Ratified**: 2026-05-12
**Last Amended**: 2026-05-12
