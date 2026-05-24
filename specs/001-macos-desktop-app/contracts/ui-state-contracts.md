# Contract: UI State and Navigation

This contract defines user-visible states and transitions expected from the native macOS app.

## App Shell

### Unauthenticated

**Visible**:
- Authentication screen.
- No financial, import, audit, account, transaction, KPI, or forecast data.

**Transitions**:
- Successful authentication -> Authenticated loading.
- Failed authentication -> Auth error state.

### Authenticated Loading

**Visible**:
- Native app shell.
- Loading state for protected data.
- No stale cached financial data until session validity is established.

**Transitions**:
- Data loaded -> Authenticated ready.
- Empty source -> Authenticated empty states.
- Network failure with cache -> Authenticated stale data.
- Network failure without cache -> Recoverable error.
- Session expired -> Session expired.

### Authenticated Ready

**Visible**:
- Sidebar or native desktop navigation for Dashboard, Imports, Accounts, Transactions, Review, Categories, KPIs, Forecast, Audit.
- Last successful update timestamp where data is aggregated or generated.

**Refresh triggers**:
- App opened with valid session.
- Window becomes active again.
- User chooses manual refresh.

### Session Expired

**Visible**:
- Reauthentication prompt.
- Protected data hidden or locked.

**Transitions**:
- Reauthentication success -> Authenticated loading.
- Logout -> Unauthenticated.

## Dashboard

**Required states**:
- Loading.
- Ready with month summary.
- Empty with no processed financial data.
- Stale with cached data and failed refresh indication.
- Recoverable error.
- Permission denied.

**Required actions**:
- Navigate to Review without losing dashboard period/context.
- Navigate to recent import detail.
- Manual refresh.

## Imports

**Required states**:
- Loading.
- Ready list.
- Empty.
- Error.

**Status display**:
- `pending`
- `processing`
- `processed`
- `error`
- `ignored`

**Detail display**:
- File metadata.
- Status reason/message when available.
- Detected issuer/layout when available.
- Processing timestamps.
- Recent redacted audit history.

## Accounts

**Required states**:
- Loading.
- Ready list.
- Empty.
- Error.

**Display rules**:
- Institution, display name, kind, currency, masked identifier.
- Never show unmasked identifiers.

## Transactions

**Required states**:
- Loading.
- Ready list.
- Empty from filters.
- Error.

**Filters**:
- Period.
- Account.
- Category.
- Transaction type.
- Origin/import file.
- Review status.

**Detail rules**:
- Immutable facts displayed read-only.
- Related account/import/statement/classification context.
- Currency preserved.

## Review

**Required states**:
- Loading queue.
- Ready item/list.
- Empty queue.
- Saving.
- Conflict detected.
- Save error.

**Actions**:
- Confirm suggested classification.
- Correct category using active category list.
- Confirm optional rule creation when suggested.
- Cancel and return to previous dashboard context.

**Conflict state**:
- Save is blocked.
- Current data is reloaded.
- User must confirm again against refreshed data.

## Categories

**Required states**:
- Loading.
- Ready active categories.
- Empty.
- Error.

**Display rules**:
- Show hierarchy when available.
- Historical inactive categories only in historical context.

## KPIs

**Required states**:
- Loading.
- Ready.
- Empty/no data.
- Error.

**Display rules**:
- Monthly revenue, expenses, net result, top categories, evolution.
- Group totals by currency.
- Never sum different currencies.
- Do not duplicate `card_payment` as common expense.

## Forecast

**Required states**:
- Loading.
- Ready forecast.
- Insufficient history.
- Empty/no forecast.
- Error.

**Display rules**:
- Show stored confidence and basis summary.
- Fewer than 3 months -> no monthly forecast message.
- 3 to 11 months -> low confidence when forecast exists.
- 12 or more months -> show existing normal/high confidence if present.

## Audit

**Required states**:
- Loading.
- Ready list/detail.
- Empty.
- Error.

**Display rules**:
- Actor, event type, entity type/id, date, redacted metadata.
- No raw sensitive content.

## Logout

**Required behavior**:
- Clear local protected cache.
- Clear authenticated state.
- Return to unauthenticated screen.
- Remove protected data from visible UI.
