# Contract: Supabase Data Access

This contract defines how the macOS app interacts with the existing Supabase data model. It is not a new backend API.

## Global Rules

- Every protected read and mutation must include the authenticated `account_owner_id` scope.
- No protected data may render before a valid authenticated session exists.
- RLS/policy denial must be surfaced as permission failure without partial financial data.
- Raw file contents, unmasked identifiers, and sensitive document data must never be requested for display.
- Queries should request only fields needed by the target screen.
- Refresh is triggered on app open, returning to active window, and manual user action.

## Auth Contract

### Sign In

**Input**:
- Existing Supabase Auth credential flow supported by the project.

**Success**:
- Valid session is available.
- Matching AccountOwner is loaded.
- Protected app shell becomes visible.

**Failure states**:
- Invalid credentials.
- Network unavailable.
- Session rejected/expired.
- Account owner missing.

### Sign Out

**Success**:
- Supabase session is cleared.
- Protected local cache is deleted.
- App returns to unauthenticated state.
- No financial data remains visible.

## Read Contracts

### Dashboard

**Reads**:
- Current-month Transactions scoped to account owner.
- Active TransactionClassifications for those Transactions.
- Accounts referenced by those Transactions.
- Recent ImportFiles.
- Current/relevant CashFlowForecast records.

**Postconditions**:
- Totals grouped by currency.
- `card_payment` not counted as duplicated common expense.
- Last successful refresh timestamp exposed.

### Imports

**Reads**:
- ImportFiles scoped to account owner.
- Recent AuditEvents related to visible import files when showing history/detail.

**Filters/sorting**:
- Status.
- File type.
- Date/updated time.
- Most recent first by default.

### Accounts

**Reads**:
- Accounts scoped to account owner.

**Postconditions**:
- Only masked identifiers are exposed to UI.

### Transactions

**Reads**:
- Transactions scoped to account owner.
- Related Account, ImportFile, optional CreditCardStatement.
- Active TransactionClassification and Category.

**Filters**:
- Period.
- Account.
- Category.
- Transaction type.
- Origin/import file.
- Review status.

**Postconditions**:
- Immutable facts are read-only.
- Currency is preserved.

### Review Queue

**Reads**:
- Transactions scoped to account owner with `review_status = needs_review`.
- Active classification and explanation.
- Active Categories compatible with transaction kind.
- Account and optional statement context.

**Postconditions**:
- Each review item includes loaded state needed for conflict detection.

### Categories

**Reads**:
- Categories scoped to account owner.

**Postconditions**:
- Active categories shown for current use.
- Inactive categories may appear only in historical context.

### KPIs

**Reads**:
- Transactions for selected monthly range.
- Active classifications and categories.
- Accounts when needed for currency/context.

**Postconditions**:
- Results grouped by month and currency.
- Different currencies are never summed.
- `card_payment` duplication rule applied.

### Forecast

**Reads**:
- CashFlowForecast records scoped to account owner.
- Minimal history indicators needed to present insufficient-history messaging.

**Postconditions**:
- Existing confidence is displayed.
- Forecast is never recalculated locally.

### Audit

**Reads**:
- AuditEvents scoped to account owner.
- Optional referenced entity metadata for context.

**Postconditions**:
- Only `metadata_redacted` is displayed.
- Raw sensitive content is never displayed.

## Mutation Contracts

### Confirm Classification

**Allowed mutation**:
- Mark transaction review as reviewed when confirming existing active classification.
- Register or reflect audit event according to existing backend behavior.

**Preconditions**:
- Authenticated session exists.
- Transaction belongs to authenticated account owner.
- Transaction is still in expected loaded review/classification state.

**Conflict behavior**:
- If transaction, review status, or active classification changed since load, block save, reload current data, and ask for confirmation again.

**Postconditions**:
- Transaction review status is reviewed.
- Exactly one active classification remains.
- History is preserved.

### Correct Classification

**Allowed mutation**:
- Deactivate prior active classification.
- Create or activate user-selected classification.
- Mark transaction review as reviewed.
- Register or reflect audit event according to existing backend behavior.

**Preconditions**:
- Authenticated session exists.
- Transaction belongs to authenticated account owner.
- Selected category is active.
- Loaded state still matches current state.

**Postconditions**:
- Exactly one active classification remains.
- Previous classifications remain in history.
- Immutable transaction facts are unchanged.

### Create Rule From Correction

**Allowed mutation**:
- Create classification rule from user correction only after explicit confirmation.

**Preconditions**:
- The app has presented the suggested rule pattern to the user.
- User explicitly confirms rule creation.
- Rule belongs to authenticated account owner.

**Postconditions**:
- Rule is associated with selected category.
- Rule source indicates user correction where supported by existing model.

## Error Mapping

| Condition | App State |
|-----------|-----------|
| No session | Unauthenticated |
| Expired session | Session expired, reauth required |
| Network failure | Recoverable error, retry available, cached data may be shown as stale |
| Permission denied | Permission error, no partial data |
| Empty result | Context-specific empty state |
| Review conflict | Block save, reload, ask for confirmation |
| Cache unavailable | Continue with live data or show recoverable load error |
