# Quickstart Validation: FinSync macOS Desktop App

**Created**: 2026-05-05

## Environment

- Swift Package Manager validation is available.
- Full Xcode validation is available with `/Applications/Xcode.app/Contents/Developer`.

## Checklist

- [X] Build native app bundle with full Xcode.
- [ ] Run `swift test` from `FinSyncMacOS/`.
- [ ] Run UI tests from Xcode.
- [ ] Verify no service-role or privileged backend secret is included.
- [ ] Execute manual smoke test against existing Supabase project.

## Results

- `swift build` from `FinSyncMacOS/`: PASS.
- `swift run FinSyncValidation` from `FinSyncMacOS/`: PASS.
- `xcodebuild -project FinSyncMacOS/FinSyncMacOS.xcodeproj -scheme FinSyncMacOS -destination 'platform=macOS' build`: PASS.
- Local app bundle at `FinSyncMacOS/build/FinSync.app`: created, ad-hoc signed, and opened through macOS `open`.
- `codesign --verify --deep --strict --verbose=2 build/FinSync.app`: PASS.
- `swift test`: blocked because this environment does not expose `XCTest` or Swift `Testing`; validation is covered by `FinSyncValidation` runner for domain/cache/review/forecast/audit rules.
- `xcodebuild -list -project FinSyncMacOS/FinSyncMacOS.xcodeproj`: PASS. Xcode lists app, unit test, and UI test targets; `supabase-swift` resolved as `Supabase 2.46.0`.
- Service-role secret review: PASS for repository content; no service-role key or privileged backend secret was added.
- Manual Supabase smoke test: not run because live Supabase credentials were not provided.

## Validation Runner Coverage

- Currency grouping without mixed-currency totals.
- Dashboard card-payment exclusion.
- Pending-review count.
- Protected cache auth-before-display and logout clearing.
- Review conflict and inactive category rejection.
- Forecast confidence rules for less than 3 months, 3-11 months, and 12+ months.
- Audit metadata redaction guard.
