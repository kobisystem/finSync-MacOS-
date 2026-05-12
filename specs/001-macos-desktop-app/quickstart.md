# Quickstart: FinSync macOS Desktop App

This quickstart describes how to validate the implementation once tasks have created the native macOS project.

## Prerequisites

- macOS development machine with current stable Xcode.
- Access to the existing Supabase project URL and publishable key.
- Existing Supabase Auth user with an associated AccountOwner.
- Existing processed financial data for at least one test user.
- A second test user or fixture account owner for isolation tests.

## Configuration

1. Open the native macOS project in Xcode.
2. Provide the Supabase project URL and publishable key through the app configuration mechanism defined by implementation tasks.
3. Confirm no service-role or privileged backend secret is included in the app bundle.
4. Confirm test fixtures include:
   - One account owner with transactions, accounts, imports, categories, classifications, forecasts, and audit events.
   - One account owner with no processed data.
   - At least one transaction with `review_status = needs_review`.
   - At least one `card_payment` transaction paired with card purchases.
   - At least one multi-currency case.

## Build

1. Select the FinSync macOS app scheme.
2. Build for macOS.
3. Confirm the output is a native macOS app bundle.

## Smoke Test

1. Launch the app without an authenticated session.
2. Verify no financial data is visible.
3. Sign in with a valid test user.
4. Verify the dashboard loads and shows:
   - Current month income.
   - Current month expenses.
   - Net result.
   - Review pending count.
   - Recent imports.
   - Forecast confidence.
   - Last successful update timestamp.
5. Trigger manual refresh and verify the last update behavior.
6. Put the app in background, return to the window, and verify refresh is attempted.

## Feature Validation

### User Isolation

1. Sign in as user A.
2. Record visible accounts/imports/transactions.
3. Sign out.
4. Sign in as user B.
5. Verify no user A data appears.

### Cache and Logout

1. Sign in with a user that has data.
2. Allow dashboard data to load.
3. Simulate network failure and refresh.
4. Verify stale cached data may appear with an explicit stale/error indication.
5. Sign out.
6. Verify protected cache is cleared and no financial data remains visible.

### Review Correction

1. Open the review queue.
2. Confirm a suggested classification.
3. Verify review status becomes reviewed.
4. Correct another transaction to a different active category.
5. Verify history is preserved and exactly one active classification remains.
6. If a rule is suggested, verify it is not created until explicitly confirmed.

### Review Conflict

1. Open a review item.
2. Change the same transaction/classification externally or through a fixture.
3. Try saving the stale review item.
4. Verify save is blocked, data reloads, and user confirmation is requested again.

### Financial Aggregation

1. Open Dashboard and KPIs.
2. Verify `card_payment` is not duplicated as a common expense.
3. Verify values with different currencies are grouped separately and never summed into one total.

### Forecast

1. Test account with fewer than 3 months of history.
2. Verify the app shows no monthly forecast due to insufficient history.
3. Test account with 3 to 11 months of history.
4. Verify forecast confidence is shown as low when a forecast exists.
5. Test account with 12+ months of history.
6. Verify existing stored confidence is displayed without local recalculation.

### Audit

1. Open audit list/detail.
2. Verify import, classification, correction, and forecast events appear when present.
3. Verify only redacted metadata is shown.

## Automated Test Targets

- Domain tests for currency aggregation, `card_payment` exclusion, forecast confidence presentation, and classification invariants.
- Repository tests for account-owner scoping and error mapping.
- Cache tests for logout deletion and auth-before-display guard.
- UI tests for unauthenticated lock, dashboard load, review correction, conflict handling, and logout.
