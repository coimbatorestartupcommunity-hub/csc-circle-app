# Phase 3 — Authentication and member-data integration

**Status:** IN PROGRESS — native PKCE auth UI, guarded app-link callbacks, and read-only public content clients are implemented. Authenticated member repositories are prepared but intentionally not called until a safe account is approved.

## Read-only audit completed (2026-10-26)

- Inspected the current local `csc-circle` web repository on branch `phase4/local-email-notifications-collaboration`; it contains unrelated uncommitted files and was not modified.
- Confirmed web Auth uses Supabase SSR cookie-bound clients. Native code must use a separate Supabase Flutter session and must not reuse browser-cookie API handlers.
- Supabase MCP identified one active/healthy existing project, PostgreSQL 17.11. Read-only migration metadata reports head `20261024130000_community_updates_cms`, matching the checked-out web migration.
- Read only database catalogs/table metadata and RLS policy definitions; no production member rows or credentials were retrieved, and no SQL writes were executed.
- Confirmed published-only public reads for events, resources, community updates, and date-eligible opportunities; owner-scoped profile/membership/claim policies; and caller-scoped in-app notification inbox/read-state policies.
- Confirmed `csc_register_event` is an authenticated invoker RPC and that member-directory RPCs use active-member and consent checks. The latter are `SECURITY DEFINER`, use an empty search path, and are not executable by `anon`/`public` according to the audited migrations/live function metadata.

## Implemented native integration

- `lib/main.dart` initializes only from the existing project URL and publishable key. Auth uses PKCE and `SecureSessionStorage` backed by `flutter_secure_storage`; no service-role key is accepted.
- `CSC_AUTH_REDIRECT_APPROVED` defaults to false. Signup and recovery require the exact `cscircle://auth-callback` redirect to be configured as approved; sign-in remains available when backend credentials exist.
- The Supabase Flutter SDK owns incoming PKCE callback processing. The app registers the `cscircle://auth-callback` scheme on iOS, macOS, and Android; no duplicate deep-link stream listener was added.
- Callback routing was smoke-checked without auth credentials: iOS Simulator opened the app for `cscircle://auth-callback`, and Android Package Manager resolves that URI to `MainActivity`. This only verifies OS routing; no authorization code was exchanged.
- Typed sign-in, signup, recovery, password update, session-expiry, and logout UI/repository flows are implemented. Signup/recovery display a clear hold state until redirect approval.
- Typed public clients now read events, updates, resources, and opportunities with explicit columns, published predicates, stable order, 1–50 row page bounds, 15-second timeouts, and mapped safe errors. Opportunities apply the Asia/Kolkata date rule.
- Events and updates tabs, plus Home resource/opportunity actions, use the live clients when the existing Supabase URL and publishable key are configured. Without them the app shows labeled preview states and no fabricated content.
- Read-only profile, membership, startup, and notification-inbox repository contracts are prepared in `lib/core/backend/member_data_repository.dart`. The app shell does not invoke them and the profile UI does not fetch member data.
- Fixture tests cover auth/session UI transitions and the exact public REST filters, fields, ordering, dates, pagination, and invalid response handling. No fixture uses production credentials.

## Verification (2026-10-26)

- `flutter analyze`: PASS — no issues (final source check).
- `flutter test --reporter expanded`: PASS — 29 tests, including six fixture-based Auth/session tests and public REST contract tests.
- iPhone 17 / iOS 26.4: PASS — `flutter test integration_test/app_smoke_test.dart -d 43708308-5A8E-47D4-9313-698791EF168A` ran one integration test covering first-run onboarding, Skip persistence, Home, and Discover navigation. Xcode simulator build/install passed.
- Android 16 / API 36: PASS — `flutter build apk --debug` succeeded; installed and launched the normal debug app with `flutter run -d emulator-5554 --debug`. Screenshot inspection confirmed Flutter onboarding and the `Public preview` state. After clearing an old stale ADB logcat process, `flutter test integration_test/app_smoke_test.dart -d emulator-5554` passed one test covering onboarding, Skip persistence, Home and Discover navigation.
- macOS 27.2: PASS — `flutter build macos --debug` succeeded; opened `build/macos/Build/Products/Debug/CSC Circle.app` and confirmed the running app shows the Home page and labeled public-preview state.
- Windows CI: PASS — [run 40237973967](https://github.com/coimbatorestartupcommunity-hub/csc-circle-app/actions/runs/40237973967) for implementation commit `b5780a8`; Dart analysis, widget tests, Windows desktop build, and unsigned artifact upload all passed.
- Live Supabase Auth/content: NOT RUN. No project URL/publishable key was injected into these platform builds and no approved safe account/redirect configuration was available. No Auth request, member query, or production write was made.

## Remaining safe implementation order

1. Inject the environment-specific Supabase URL and publishable key through local/CI secret handling, never committed files. Never request or package a service-role key.
2. Get project-owner confirmation of enabled providers, exact Auth redirect allowlist, application identifiers, and one non-production safe account. Then perform only approved sign-in, sign-out, and public/member reads.
3. Validate callback handling and session persistence on iOS, Android, and desktop after that redirect approval; keep email signup/recovery gated meanwhile.
4. Add member-data read UI only after safe-account RLS/RPC positive and negative tests. Keep membership eligibility, consent, and authorization decisions in RLS/RPC.
5. Defer all production writes (claims, profile/startup edits, registrations, uploads, notification updates) until the exact RPC/RLS contract and an explicit non-production test path are verified.

## Current blockers and limits

- No safe test account or verified provider/redirect configuration was available, so no real Auth request was attempted.
- No live member data or production writes were used. RLS metadata checks do not replace authenticated positive/negative integration tests.
- Account deletion has no verified member-facing contract in the existing source audit; store readiness remains blocked until the owner provides an approved deletion path and retention text.

See [`CSC_WEB_AUDIT.md`](../architecture/CSC_WEB_AUDIT.md), [`MOBILE_API_CONTRACTS.md`](../architecture/MOBILE_API_CONTRACTS.md), and [`AUTH_AND_PERMISSIONS.md`](../architecture/AUTH_AND_PERMISSIONS.md).
