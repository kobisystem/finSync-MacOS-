# Data Model: FinSync macOS Desktop App

The app consumes the existing Supabase data model. Supabase remains the source of truth. Local app models mirror the fields required for display, filtering, aggregation, cache identity, and guarded review mutation.

## AccountOwner

**Purpose**: Authenticated person who owns all visible financial data.

**Fields used by app**:
- `id`
- `email`
- `display_name`
- `created_at`

**Relationships**:
- Owns accounts, import files, transactions, classification rules, forecasts, and audit events.

**Validation rules**:
- All protected reads and mutations must be scoped to the authenticated `account_owner_id`.
- If no account owner is associated with the authenticated session, protected screens remain blocked.

## Account

**Purpose**: Bank account or credit card displayed in account filters, transaction details, dashboard context, and statement relationships.

**Fields used by app**:
- `id`
- `account_owner_id`
- `kind`
- `institution_name`
- `display_name`
- `masked_identifier`
- `currency`
- `created_at`
- `updated_at`

**Relationships**:
- Belongs to AccountOwner.
- Has many Transactions.
- Has many CreditCardStatements when `kind = credit_card`.

**Validation rules**:
- `kind` must be shown as bank account or credit card.
- `masked_identifier` is the only identifier representation allowed in UI, errors, and audit details.
- Aggregations must respect `currency`.

## ImportFile

**Purpose**: File detected and processed by the existing pipeline, displayed in import status views and transaction origin details.

**Fields used by app**:
- `id`
- `account_owner_id`
- `provider`
- `provider_file_id`
- `original_path`
- `file_name`
- `mime_type`
- `file_extension`
- `content_fingerprint`
- `file_type`
- `status`
- `status_reason_code`
- `status_message`
- `detected_issuer`
- `detected_layout`
- `processing_started_at`
- `processing_finished_at`
- `created_at`
- `updated_at`

**Relationships**:
- Belongs to AccountOwner.
- Can have many Transactions.
- Can have CreditCardStatements.
- Has AuditEvents.

**Validation rules**:
- Status display must support `pending`, `processing`, `processed`, `error`, and `ignored`.
- Reprocessing history must reflect valid state transitions when visible in existing records.
- Raw document content is never stored or displayed by the macOS app.

**State transitions**:
- `pending -> processing -> processed`
- `pending -> processing -> ignored`
- `pending -> processing -> error`
- `error -> processing -> processed`
- `ignored -> processing -> processed`

## Transaction

**Purpose**: Normalized financial movement used across dashboard, transactions, review, KPIs, statements, and audit context.

**Fields used by app**:
- `id`
- `account_owner_id`
- `account_id`
- `import_file_id`
- `credit_card_statement_id`
- `source_transaction_id`
- `transaction_type`
- `original_date`
- `posted_date`
- `description_original`
- `description_normalized`
- `amount`
- `currency`
- `installment_current`
- `installment_total`
- `deduplication_fingerprint`
- `review_status`
- `created_at`
- `updated_at`

**Relationships**:
- Belongs to AccountOwner, Account, and ImportFile.
- May belong to CreditCardStatement.
- Has classification history and one active TransactionClassification.

**Validation rules**:
- `amount`, `original_date`, `description_original`, and `import_file_id` are read-only in the app.
- `transaction_type = card_payment` is not counted as a common duplicated expense when card purchases are already counted.
- Review queue includes transactions with `review_status = needs_review`.
- If `review_status` changes from loaded state during review, save must be blocked and data reloaded.

**State transitions**:
- `not_needed -> needs_review -> reviewed`
- `needs_review -> reviewed`
- `reviewed -> needs_review`

## CreditCardStatement

**Purpose**: Monthly card bill displayed in transaction details, KPI context, and forecast obligations.

**Fields used by app**:
- `id`
- `account_owner_id`
- `account_id`
- `import_file_id`
- `statement_period_start`
- `statement_period_end`
- `due_date`
- `total_amount`
- `currency`
- `status`
- `created_at`
- `updated_at`

**Relationships**:
- Belongs to AccountOwner, Account, and ImportFile.
- Has many purchase Transactions.
- May be associated with card payment Transactions.

**Validation rules**:
- Only credit card accounts can own statements.
- Purchases count as expenses; card payments do not create duplicate common expenses.

**State transitions**:
- `unknown -> open -> closed -> paid`
- `unknown -> closed -> paid`
- `closed -> partial -> paid`

## Category

**Purpose**: Visible income/expense classification category used for filters, review choices, details, and KPIs.

**Fields used by app**:
- `id`
- `account_owner_id`
- `name`
- `kind`
- `parent_category_id`
- `is_active`
- `created_at`
- `updated_at`

**Relationships**:
- Belongs to AccountOwner.
- May have parent/child categories.
- Used by TransactionClassifications.

**Validation rules**:
- New review corrections should offer active categories.
- Inactive categories may appear in historical classification context but should not be preferred for new corrections.
- Category changes do not alter immutable transaction facts.

## TransactionClassification

**Purpose**: Classification assignment for a transaction, including source, confidence, explanation, active flag, and history.

**Fields used by app**:
- `id`
- `account_owner_id`
- `transaction_id`
- `category_id`
- `source`
- `confidence`
- `explanation`
- `is_active`
- `created_at`

**Relationships**:
- Belongs to AccountOwner, Transaction, and Category.

**Validation rules**:
- Exactly one classification may be active per transaction after confirmation or correction.
- Previous classifications remain in history.
- Low-confidence or missing-category cases appear in review only when transaction `review_status` indicates `needs_review`.
- If the active classification changes from loaded state during review, save must be blocked and data reloaded.

## ClassificationRule

**Purpose**: Existing deterministic rule that may explain prior classifications or be suggested from a user correction.

**Fields used by app**:
- `id`
- `account_owner_id`
- `category_id`
- `pattern_type`
- `pattern_value`
- `priority`
- `created_from`
- `is_active`
- `created_at`
- `updated_at`

**Relationships**:
- Belongs to AccountOwner and Category.

**Validation rules**:
- The initial app does not include advanced rule management.
- A correction may suggest a rule, but the rule can only be created after explicit user confirmation.

## CashFlowForecast

**Purpose**: Existing monthly forecast displayed without local recalculation.

**Fields used by app**:
- `id`
- `account_owner_id`
- `month`
- `income_confirmed`
- `income_predicted`
- `income_estimated`
- `expense_confirmed`
- `expense_predicted`
- `expense_estimated`
- `card_obligations_confirmed`
- `card_obligations_predicted`
- `card_obligations_estimated`
- `projected_net_result`
- `projected_balance`
- `confidence`
- `basis_summary`
- `generated_at`

**Relationships**:
- Belongs to AccountOwner.

**Validation rules**:
- Fewer than 3 months of eligible history means no monthly forecast is shown.
- 3 to 11 months means low confidence when a forecast exists.
- 12 or more months may show existing normal/high confidence.
- The app must not overwrite stored forecast confidence.

## AuditEvent

**Purpose**: Redacted trace of imports, failures, deduplications, classifications, corrections, and forecasts.

**Fields used by app**:
- `id`
- `account_owner_id`
- `actor_type`
- `event_type`
- `entity_type`
- `entity_id`
- `metadata_redacted`
- `created_at`

**Relationships**:
- Belongs to AccountOwner.
- May reference ImportFile, Transaction, TransactionClassification, CashFlowForecast, or CreditCardStatement.

**Validation rules**:
- Raw sensitive content must not be displayed.
- Metadata must be treated as redacted display data.

## Local Protected Cache

**Purpose**: Recent financial data cache that supports continuity when refresh fails.

**Fields**:
- `account_owner_id`
- `cached_at`
- `entity_type`
- `entity_id`
- `payload`
- `source_updated_at`

**Validation rules**:
- Cache is scoped to the authenticated account owner.
- Cache is never rendered before a valid authenticated session.
- Cache is cleared on logout.
- Cache does not become source of truth and must be marked stale when refresh fails.

## Derived View Models

### DashboardSummary

**Inputs**: Transactions, active classifications, import files, forecasts, account owner, selected month.

**Rules**:
- Group totals by currency.
- Exclude duplicated `card_payment` common expenses.
- Include review count and recent import statuses.
- Show last successful update time.

### MonthlyKPI

**Inputs**: Transactions, categories, active classifications, selected month range.

**Rules**:
- Group by month and currency.
- Show income, expense, net result, top categories, and month evolution.
- Never sum different currencies.

### ReviewItem

**Inputs**: Transaction, active classification, categories, account, optional statement.

**Rules**:
- Include loaded transaction/review/classification state for conflict detection.
- Saving requires current state to match loaded state.
