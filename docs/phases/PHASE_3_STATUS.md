# Phase 3 — Authentication and member-data integration

**Status:** IN PROGRESS — native PKCE auth UI, guarded app-link callbacks, public content clients, and member-repository fixture tests are implemented. All four public endpoints now accept the native field projections under existing anon column grants and published-only RLS; no production permission change was required. Authenticated member repositories remain prepared but are not called.

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
- Member repository tests cover anonymous fail-closed behavior and fixture-authenticated owner scoping/RPC shape. They verify client-side contracts only; they are not a substitute for live RLS positive/negative tests.
- Account deletion requirements and a server-owned workflow proposal are documented in [`ACCOUNT_DELETION_DESIGN.md`](../architecture/ACCOUNT_DELETION_DESIGN.md). No deletion endpoint or production write was implemented.

## Verification (2026-10-26)

- `flutter analyze`: PASS — no issues after the latest source changes.
- `flutter test --reporter expanded`: PASS — 32 tests, including Auth/session, public REST, and member repository fixtures.
- iPhone 17 / iOS 26.4: PASS — `flutter test integration_test/app_smoke_test.dart -d 43708308-5A8E-47D4-9313-698791EF168A` ran one integration test covering first-run onboarding, Skip persistence, Home, and Discover navigation. Xcode simulator build/install passed.
- Android 16 / API 36: PASS — `flutter build apk --debug` succeeded; installed and launched the normal debug app with `flutter run -d emulator-5554 --debug`. Screenshot inspection confirmed Flutter onboarding and the `Public preview` state. After clearing an old stale ADB logcat process, `flutter test integration_test/app_smoke_test.dart -d emulator-5554` passed one test covering onboarding, Skip persistence, Home and Discover navigation.
- macOS 27.2: PASS — configured `flutter build macos --debug` succeeded; `flutter run -d macos --debug --dart-define-from-file=dart_defines.json` launched the app and the CSC Circle window rendered its signed-out Account screen.
- Windows CI: PASS — [run 40237973967](https://github.com/coimbatorestartupcommunity-hub/csc-circle-app/actions/runs/40237973967) for implementation commit `b5780a8`; Dart analysis, widget tests, Windows desktop build, and unsigned artifact upload all passed.
- Latest Windows CI: PASS — [run 40241934577](https://github.com/coimbatorestartupcommunity-hub/csc-circle-app/actions/runs/40241934577) for commit `f1a5582`; analysis, all widget tests, Windows desktop build, and unsigned artifact upload passed.
- Authenticated Supabase Auth/session/callback and member-data calls: NOT RUN. No approved provider/redirect settings or isolated test identity were available. No Auth request, member query, or production write was made.

## Additional live checks (2026-10-26)

- Supabase project metadata confirmed the existing `csc-circle-production` project is active/healthy. Its API URL and an enabled publishable key match the ignored local `dart_defines.json`; the file is Git-ignored and neither value was printed or committed.
- Supabase Auth dashboard settings could not be inspected: the authorized browser profile redirected to Supabase sign-in. Provider enablement, application identifiers, and the exact `cscircle://auth-callback` allowlist state therefore remain unverified. The local compile-time approval flag remains `false`; signup/recovery are not enabled.
- Live Resources authorization review found RLS enabled and `resources_public_read` scoped to `publication_status='published'`. `anon` has no table-level SELECT but already has column-level SELECT for the website’s explicit public projection. The original Flutter query failed because it also requested unused `thumbnail_path`, which is not granted. Removing that field makes the native projection return HTTP 200 under the existing policy. The website’s explicit projection also returns HTTP 200; `select=*` is denied. No grant or policy was changed.
- The current anonymous column grants include `document_path`, `document_filename`, and `document_mime`, which the server-only website helper selects to determine download availability. No path values were returned in these checks, but the columns are directly queryable by anonymous clients for published rows. A coordinated public-view and server-route hardening proposal is recorded under `docs/architecture/proposals/`; it is not applied.
- iOS 26.4 simulator integration with the local config passed all four public content checks: Events, Updates, Resources, and Opportunities returned HTTP 200 with empty published pages. The same integration passed on Android 16 / API 36 after repairing emulator DNS with a cold boot (no snapshot load) and a configured DNS server; no emulator data wipe was performed.
- `flutter analyze`: PASS after adding member fixture tests and live-content integration coverage. `flutter test --reporter expanded`: PASS — 32 tests.
- Configured iOS 26.4 and Android 16 device integration: PASS — both ran first-launch onboarding/navigation and exercised all four live content clients. Each endpoint returned HTTP 200 with zero published rows; this verifies connectivity and the empty state, not populated content rendering.
- Configured builds: iOS Simulator app build PASS; Android debug APK build/install PASS; macOS debug build PASS after the current Resources projection change. macOS launch was previously observed on the signed-out Account screen; this turn reran the build, not the UI launch.

## Remaining safe implementation order

1. Review the prepared public projection plus coordinated website updates to move `document_path`/image path resolution into server-only routes. Current app access needs no permission change. The website's existing explicit public projection is already permitted and includes storage-path columns; no change may be applied until CSC approves the contract and coordinates the web release.
2. Obtain authorized dashboard access or owner confirmation for enabled providers, registered app identifiers, and exact `cscircle://auth-callback` allowlisting. Keep the compile-time signup/recovery gate false until the callback has been tested.
3. Approve an isolated test identity and scope. Prefer a dedicated test environment if already available; otherwise explicitly approve a clearly labeled test Auth identity in the existing project and confirm any Auth trigger side effects before creating it.
4. With that identity/config, test sign-in, callback code exchange, session restoration, logout/revocation, provider errors, and expired-session behavior on iOS, Android, and macOS. Then run positive owner-data and negative cross-user/anonymous checks under real RLS before wiring member UI.
5. Obtain owner approval for the account-deletion policy and server contract described in `ACCOUNT_DELETION_DESIGN.md` before implementing or submitting the feature.
6. Keep all production writes (claims, profile/startup edits, registrations, uploads, notification updates, deletion) disabled until each exact RPC/RLS contract and isolated write test are reviewed and approved.

## Current blockers and limits

- The Auth dashboard required sign-in, so enabled providers, app IDs, and redirect allowlisting remain unknown. No real Auth request or test identity creation was attempted.
- The Resources client is fixed without a database change: it no longer selects the unused, ungranted `thumbnail_path`. Live native and website projections returned HTTP 200 with zero rows; `select=*` remains denied. Anonymous column privileges currently include `document_path` and related metadata for published rows. The proposal in `../architecture/proposals/RESOURCES_PUBLIC_PROJECTION.md` is a review artifact only; its migration and pgTAP fixture were not run.
- No live member data or production writes were used. Fixture tests and RLS metadata do not replace authenticated positive/negative integration tests.
- Account deletion has no verified member-facing/server contract; store readiness remains blocked until the owner approves the workflow and retention text.

## Member dashboard readiness

The signed-in Account destination should be integrated through the existing typed repositories only after an approved isolated identity passes live RLS checks. The planned sections and data sources are documented in [`MEMBER_DASHBOARD_READINESS.md`](../architecture/MEMBER_DASHBOARD_READINESS.md). Until that gate passes, the shell does not call profile, membership, startup, notification, or membership-status endpoints and displays no fabricated member data.

The account-deletion owner decision checklist is in [`ACCOUNT_DELETION_DESIGN.md`](../architecture/ACCOUNT_DELETION_DESIGN.md): approve a record-by-record retention disposition, timing and cancellation rules, identity re-authentication, holds/support handling, user-facing privacy copy, and the exact server contract and authorization/recovery tests.

See [`CSC_WEB_AUDIT.md`](../architecture/CSC_WEB_AUDIT.md), [`MOBILE_API_CONTRACTS.md`](../architecture/MOBILE_API_CONTRACTS.md), and [`AUTH_AND_PERMISSIONS.md`](../architecture/AUTH_AND_PERMISSIONS.md).
