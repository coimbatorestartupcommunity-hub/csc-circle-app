# Phase 3 — Authentication and member-data integration

**Status:** IN PROGRESS — native PKCE auth UI, guarded app-link callbacks, public content clients, and member-repository fixture tests are implemented. Three public endpoints are live-readable; the Resources table is currently denied to the `anon` role by missing table-level SELECT privilege. Authenticated member repositories remain prepared but are not called.

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
- Authenticated Supabase Auth/session/callback and member-data calls: NOT RUN. No approved provider/redirect settings or isolated test identity were available. No Auth request, member query, or production write was made.

## Additional live checks (2026-10-26)

- Supabase project metadata confirmed the existing `csc-circle-production` project is active/healthy. Its API URL and an enabled publishable key match the ignored local `dart_defines.json`; the file is Git-ignored and neither value was printed or committed.
- Supabase Auth dashboard settings could not be inspected: the authorized browser profile redirected to Supabase sign-in. Provider enablement, application identifiers, and the exact `cscircle://auth-callback` allowlist state therefore remain unverified. The local compile-time approval flag remains `false`; signup/recovery are not enabled.
- Anonymous Data API GETs using the publishable key and the repository's explicit field sets/visibility/date filters returned: `events` HTTP 200 (0 rows in first page), `community_updates` HTTP 200 (0), `opportunities` HTTP 200 (0), and `resources` HTTP 401 / PostgreSQL `42501` (permission denied). A read-only catalog query found the `resources_public_read` policy for `public`, but the table grants `SELECT` to `authenticated` only; there is no `anon`/`PUBLIC` SELECT grant. The page correctly shows a safe retry/error state. No grant or policy was changed.
- iOS 26.4 simulator integration with the local config passed all four public content checks: Events, Updates, and Opportunities reach their empty states; Resources shows the mapped forbidden/retry state. The same integration passed on Android 16 / API 36.
- `flutter analyze`: PASS after adding member fixture tests and live-content integration coverage. `flutter test --reporter expanded`: PASS — 32 tests.
- Configured iOS 26.4 and Android 16 device integration: PASS — both ran first-launch onboarding/navigation and exercised all four live content clients. Events, Updates, and Opportunities returned empty published pages; Resources displayed its expected safe forbidden/retry state.
- Configured builds: iOS Simulator app build PASS; Android debug APK build/install PASS; macOS debug build and launch PASS.

## Remaining safe implementation order

1. Have the project owner review and approve the exact read-only production grant needed for the existing `resources_public_read` policy to be reachable by anonymous clients (`GRANT SELECT ON TABLE public.resources TO anon;`). Do not apply it until approval; re-run the filtered Data API request afterward.
2. Obtain authorized dashboard access or owner confirmation for enabled providers, registered app identifiers, and exact `cscircle://auth-callback` allowlisting. Keep the compile-time signup/recovery gate false until the callback has been tested.
3. Approve an isolated test identity and scope. Prefer a dedicated test environment if already available; otherwise explicitly approve a clearly labeled test Auth identity in the existing project and confirm any Auth trigger side effects before creating it.
4. With that identity/config, test sign-in, callback code exchange, session restoration, logout/revocation, provider errors, and expired-session behavior on iOS, Android, and macOS. Then run positive owner-data and negative cross-user/anonymous checks under real RLS before wiring member UI.
5. Obtain owner approval for the account-deletion policy and server contract described in `ACCOUNT_DELETION_DESIGN.md` before implementing or submitting the feature.
6. Keep all production writes (claims, profile/startup edits, registrations, uploads, notification updates, deletion) disabled until each exact RPC/RLS contract and isolated write test are reviewed and approved.

## Current blockers and limits

- The Auth dashboard required sign-in, so enabled providers, app IDs, and redirect allowlisting remain unknown. No real Auth request or test identity creation was attempted.
- The Resources production table lacks an `anon` SELECT grant despite the public-read policy; an owner-approved grant is needed for the existing anonymous public endpoint to work.
- No live member data or production writes were used. Fixture tests and RLS metadata do not replace authenticated positive/negative integration tests.
- Account deletion has no verified member-facing/server contract; store readiness remains blocked until the owner approves the workflow and retention text.

See [`CSC_WEB_AUDIT.md`](../architecture/CSC_WEB_AUDIT.md), [`MOBILE_API_CONTRACTS.md`](../architecture/MOBILE_API_CONTRACTS.md), and [`AUTH_AND_PERMISSIONS.md`](../architecture/AUTH_AND_PERMISSIONS.md).
