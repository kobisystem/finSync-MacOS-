# FinSync macOS

Native macOS desktop interface for the existing FinSync Supabase data model.

## Configuration

Set these values in the app configuration layer or environment during local validation:

- `SUPABASE_URL`
- `SUPABASE_PUBLISHABLE_KEY`

Never include a service-role key or privileged backend secret in the app bundle.

## Scope

- Reads already processed financial data from the existing Supabase backend.
- Does not create a backend.
- Does not process OFX or PDF locally.
- Does not edit immutable financial facts.
- Clears protected local cache on logout.

## Current Validation

This repository is currently validated with Swift Package Manager:

```sh
cd FinSyncMacOS
swift test
```

Full `xcodebuild` validation requires a complete Xcode installation and a generated production-ready `.xcodeproj`.

