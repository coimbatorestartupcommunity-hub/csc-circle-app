# Phase 3 — Authentication and member-data integration

> **Verification refresh (2026-10-26):** Local fixture-only dashboard improvements and current simulator checks are recorded below. This does not change the Phase 3 completion gate: real authorized PKCE callback exchange, session persistence, and owner/negative RLS checks remain unverified.

**Status:** IN PROGRESS — native PKCE auth UI, guarded app-link callbacks, public content clients, and member-repository fixture tests are implemented. All four public endpoints now accept the native field projections under existing anon column grants and published-only RLS; no production permission change was required. Authenticated member repositories remain prepared but are not called.

## Read-only audit completed (2026-10-26)

- Inspected the current local `csc-circle` web repository on branch `phase4/local-email-notifications-collaboration`; it contains unrelated uncommitted files and was not modified.
- Confirmed web Auth uses Supabase SSR cookie-bound clients. Native code must use a separate Supabase Flutter session and must not reuse browser-cookie API handlers.
- Supabase MCP identified one active/healthy existing project, PostgreSQL 17.11. Read-only migration metadata reports head `20261024130000_community_updates_cms`, matching the checked-out web migration.
- Read only database catalogs/table metadata and RLS policy definitions; no production member rows or credentials were retrieved, and no SQL writes were executed.
- Confirmed published-only public reads for events, resources, community updates, and date-eligible opportunities; owner-scoped profile/membership/claim policies; and caller-scoped in-app notification inbox/read-state policies.
- Confirmed `csc_register_event` is an authenticated invoker RPC and that member-directory RPCs use active-member and consent checks. The latter are `SECURITY DEFINER`, use an empty search path, and are not executable by `anon`/`public` according to the audited migrations/live function metadata.

## Implemented native integration

- `lib/main.dart` initializes only from the existing project URL and publishable key. Auth uses PKCE, `SecureSessionStorage` for the persisted session, and `SecurePkceStorage` for the PKCE verifier, both backed by `flutter_secure_storage`; no service-role key is accepted.
- `CSC_AUTH_REDIRECT_APPROVED` defaults to false. Signup and recovery require the exact `cscircle://auth-callback` redirect to be configured as approved; sign-in remains available when backend credentials exist.
- The Supabase Flutter SDK owns incoming PKCE callback processing. The app registers the `cscircle://auth-callback` scheme on iOS, macOS, and Android; no duplicate deep-link stream listener was added.
- Callback routing was smoke-checked without auth credentials: iOS Simulator opened the app for `cscircle://auth-callback`, and Android Package Manager resolves that URI to `MainActivity`. This only verifies OS routing; no authorization code was exchanged.
- Typed sign-in, signup, recovery, password update, session-expiry, and logout UI/repository flows are implemented. Signup/recovery display a clear hold state until redirect approval.
- Typed public clients now read events, updates, resources, and opportunities with explicit columns, published predicates, stable order, 1–50 row page bounds, 15-second timeouts, and mapped safe errors. Opportunities apply the Asia/Kolkata date rule. Resources prefers `csc_public_resources` and falls back to the existing path-free base-table request only if the view is missing.
- Events and updates tabs, plus Home resource/opportunity actions, use the live clients when the existing Supabase URL and publishable key are configured. Without them the app shows labeled preview states and no fabricated content.
- Read-only profile, membership, startup, and notification-inbox repository contracts are implemented in `lib/core/backend/member_data_repository.dart`. The signed-in Account destination now has Profile, Membership, Startups, Notifications, and Digital Member ID sections. It accepts dependency-injected repositories for fixture UI tests, but the production app shell does not pass one and `allowMemberReads` defaults to false, so no real member query can be made through the shipped path.
- Fixture tests cover sign-in/logout, redirect gating, recovery UI, password update, session expiry, initially restored signed-in UI, member dashboard fixtures, logout/account-switch state clearing, secure session storage, secure PKCE verifier storage, and exact public REST filters/fields/order/pagination/error behavior. No fixture uses production credentials.
- Member repository tests cover anonymous fail-closed behavior and fixture-authenticated owner scoping/RPC shape. They verify client-side contracts only; they are not a substitute for live RLS positive/negative tests.
- Account deletion requirements and a server-owned workflow proposal are documented in [`ACCOUNT_DELETION_DESIGN.md`](../architecture/ACCOUNT_DELETION_DESIGN.md). No deletion endpoint or production write was implemented.

## Verification (2026-10-26)

- `flutter analyze`: PASS — no issues after the dashboard and secure PKCE storage changes.
- `flutter test --reporter expanded`: PASS — 37 tests, including dashboard, session/PKCE storage, Auth, public REST, and member repository fixtures.
- iPhone 17 / iOS 26.4: PASS — current `flutter test integration_test/app_smoke_test.dart -d 43708308-5A8E-47D4-9313-698791EF168A --dart-define-from-file=dart_defines.json` passed, including all four public reads; Resources exercised missing-view fallback and returned its empty published state.
- Android 16 / API 36: PASS — current `flutter test integration_test/app_smoke_test.dart -d emulator-5554 --dart-define-from-file=dart_defines.json` passed, including all four public reads; Resources exercised missing-view fallback and returned its empty published state. The earlier emulator DNS repair is documented above; no data wipe was performed.
- macOS 27.2: PASS — current configured debug build passed and `flutter run -d macos --debug --dart-define-from-file=dart_defines.json` launched the app; Supabase initialization completed. This verifies startup, not real sign-in.
- Windows CI: PASS — [run 40237973967](https://github.com/coimbatorestartupcommunity-hub/csc-circle-app/actions/runs/40237973967) for implementation commit `b5780a8`; Dart analysis, widget tests, Windows desktop build, and unsigned artifact upload all passed.
- Latest Windows CI: PASS — [run 40241934577](https://github.com/coimbatorestartupcommunity-hub/csc-circle-app/actions/runs/40241934577) for commit `f1a5582`; analysis, all widget tests, Windows desktop build, and unsigned artifact upload passed.
- Current Windows CI: PASS — [run 40272355891](https://github.com/coimbatorestartupcommunity-hub/csc-circle-app/actions/runs/40272355891) for source commit `d91bf7b`; Dart analysis, widget tests, Windows desktop build, and unsigned artifact upload passed.
- Current Phase 3 implementation Windows CI: PASS — [run 40280620907](https://github.com/coimbatorestartupcommunity-hub/csc-circle-app/actions/runs/40280620907) for commit `e120995`; analysis, all widget tests, Windows desktop build, and artifact upload passed.
- Authenticated Supabase Auth/session/callback and member-data calls: NOT RUN. No approved provider/redirect settings or isolated test identity were available. No Auth request, member query, or production write was made.

- Windows CI for current source changes: PASS — run `40280620907` verifies dashboard, secure PKCE verifier storage, and view-first Resources changes in `e120995`.

## Additional live checks (2026-10-26)

- Supabase project metadata confirmed the existing `csc-circle-production` project is active/healthy. Its API URL and an enabled publishable key match the ignored local `dart_defines.json`; the file is Git-ignored and neither value was printed or committed.
- Supabase Auth dashboard settings could not be inspected: the authorized browser profile redirected to Supabase sign-in. Provider enablement, application identifiers, and the exact `cscircle://auth-callback` allowlist state therefore remain unverified. The local compile-time approval flag remains `false`; signup/recovery are not enabled.
- Live Resources authorization review found RLS enabled and `resources_public_read` scoped to `publication_status='published'`. `anon` has no table-level SELECT but already has column-level SELECT for the website’s explicit public projection. The original Flutter query failed because it also requested unused `thumbnail_path`, which is not granted. Removing that field makes the native projection return HTTP 200 under the existing policy. The website’s explicit projection also returns HTTP 200; `select=*` is denied. No grant or policy was changed.
- The current anonymous column grants include `document_path`, `document_filename`, and `document_mime`, which the server-only website helper selects to determine download availability. No path values were returned in these checks, but the columns are directly queryable by anonymous clients for published rows. A coordinated public-view and server-route hardening proposal is recorded under `docs/architecture/proposals/`; it is not applied.
- A fresh read-only catalog check confirms `public.csc_public_resources` does not exist in the current production project. The native view-first client therefore uses its missing-view fallback against the currently granted path-free base-table projection; iOS and Android integration both passed this path.
- iOS 26.4 simulator integration with the local config passed all four public content checks: Events, Updates, Resources, and Opportunities returned HTTP 200 with empty published pages. The same integration passed on Android 16 / API 36 after repairing emulator DNS with a cold boot (no snapshot load) and a configured DNS server; no emulator data wipe was performed.
- `flutter analyze`: PASS after adding member fixture tests and live-content integration coverage. `flutter test --reporter expanded`: PASS — 37 tests.
- Configured iOS 26.4 and Android 16 device integration: PASS — both ran first-launch onboarding/navigation and exercised all four live content clients. Each endpoint returned HTTP 200 with zero published rows; this verifies connectivity and the empty state, not populated content rendering.
- Configured builds: current iOS Simulator integration build/install PASS; Android debug APK build/install PASS; macOS configured debug build and launch PASS. The macOS run confirmed Supabase initialization and rendered the CSC Circle app window.
- Current iOS and Android integration also confirms the native Resources fallback when the proposed view is absent. The view/migration remains unapplied; positive and negative pgTAP authorization tests are prepared only.

## Native authentication readiness review

- `main.dart` uses PKCE for Supabase Auth, secure platform storage for both the persisted session and short-lived PKCE verifier, and SDK-managed callback processing. The approved redirect remains null unless the exact callback is approved by the compile-time flag.
- Current identifiers read from source: iOS `dev.cscircle.csc-circle-app`, Android `dev.cscircle.csc_circle_app`, macOS `dev.cscircle.csc-circle-app`. They are repository configuration, not owner-confirmed final/provider-registered identifiers. Exact owner verification steps are in [`NATIVE_AUTH_VERIFICATION.md`](../architecture/NATIVE_AUTH_VERIFICATION.md).
- Fixture/UI and secure-storage coverage is summarized in [`NATIVE_AUTH_VERIFICATION.md`](../architecture/NATIVE_AUTH_VERIFICATION.md). It does not validate a real PKCE exchange, Keychain/Keystore restore after process restart, real provider configuration, or live RLS.
- Signup/recovery remain gated. No Auth account was created and no production member record was read.

## Remaining safe implementation order

1. Review the staged public projection plus coordinated website and native rollout in [`../architecture/proposals/RESOURCES_PUBLIC_PROJECTION.md`](../architecture/proposals/RESOURCES_PUBLIC_PROJECTION.md). The native client now prefers the view and uses its path-free base-table query only when the view is missing. Preserve current permissions and old-app compatibility until the approved release/sunset; apply no production SQL without approval.
2. Complete the provider, redirect, and app-ID checklist in [`../architecture/NATIVE_AUTH_VERIFICATION.md`](../architecture/NATIVE_AUTH_VERIFICATION.md). Keep the compile-time signup/recovery gate false until the exact callback has been allowlisted and tested.
3. Approve an isolated test identity and scope. Prefer a dedicated test environment if already available; otherwise explicitly approve a clearly labeled test Auth identity in the existing project and confirm any Auth trigger side effects before creating it.
4. With that identity/config, test sign-in, callback code exchange, session restoration, logout/revocation, provider errors, and expired-session behavior on iOS, Android, and macOS. Then run positive owner-data and negative cross-user/anonymous checks under real RLS before wiring member UI.
5. Obtain owner approval for the account-deletion policy and server contract described in `ACCOUNT_DELETION_DESIGN.md` before implementing or submitting the feature.
6. Keep all production writes (claims, profile/startup edits, registrations, uploads, notification updates, deletion) disabled until each exact RPC/RLS contract and isolated write test are reviewed and approved.

## Current blockers and limits

- The Auth dashboard required sign-in, so enabled providers, app IDs, and redirect allowlisting remain unknown. No real Auth request or test identity creation was attempted.
- The Resources client is fixed without a database change: it no longer selects the unused, ungranted `thumbnail_path`. Live native and website projections returned HTTP 200 with zero rows; `select=*` remains denied. Anonymous column privileges currently include `document_path` and related metadata for published rows. The proposal in `../architecture/proposals/RESOURCES_PUBLIC_PROJECTION.md` is a review artifact only; its migration and pgTAP fixture were not run.
- No live member data or production writes were used. Fixture tests and RLS metadata do not replace authenticated positive/negative integration tests.
- Account deletion has no verified member-facing/server contract; store readiness remains blocked until the owner approves the workflow and retention text.

## Exact CSC approvals required

1. **Auth providers:** confirm which email/OAuth providers CSC permits and that each is enabled/configured in the existing Supabase project.
2. **Redirect:** authorized dashboard operator allowlists and verifies `cscircle://auth-callback`; keep `CSC_AUTH_REDIRECT_APPROVED=false` until callback code exchange succeeds.
3. **Application IDs:** confirm the repository IDs in [`NATIVE_AUTH_VERIFICATION.md`](../architecture/NATIVE_AUTH_VERIFICATION.md) are final and match Apple/Google registrations and Supabase provider settings.
4. **Test identities:** explicitly approve two isolated identities (owner and cross-user), their scope, and Auth trigger/email side effects before creating or using them.
5. **Resources rollout:** approve the view contract, non-production verification branch, website/native deployment order, supported native-version sunset, and the later base-grant revoke. The proposal remains unapplied and must not run independently of both clients.
6. **Account deletion:** approve record retention/disposition, timelines/cancellation, identity verification, support/hold handling, user-facing copy, and the server endpoint/negative-test contract in `ACCOUNT_DELETION_DESIGN.md`.

Until items 1–4 are complete, real authentication and member RLS tests remain blocked. Items 5–6 are separate release/security approvals; no production migrations, permission changes, writes, or account deletion were performed.

## Member dashboard readiness

The signed-in Account destination is implemented with fixture-driven sections and injected repository support. The shipped default remains fail-closed: it does not instantiate or call profile, membership, startup, notification, or membership-status endpoints and displays no fabricated member data. The data sources and live-RLS gate are documented in [`MEMBER_DASHBOARD_READINESS.md`](../architecture/MEMBER_DASHBOARD_READINESS.md).

The account-deletion owner decision checklist is in [`ACCOUNT_DELETION_DESIGN.md`](../architecture/ACCOUNT_DELETION_DESIGN.md): approve a record-by-record retention disposition, timing and cancellation rules, identity re-authentication, holds/support handling, user-facing privacy copy, and the exact server contract and authorization/recovery tests.

See [`CSC_WEB_AUDIT.md`](../architecture/CSC_WEB_AUDIT.md), [`MOBILE_API_CONTRACTS.md`](../architecture/MOBILE_API_CONTRACTS.md), and [`AUTH_AND_PERMISSIONS.md`](../architecture/AUTH_AND_PERMISSIONS.md).

## Verification refresh (2026-10-26)

- Added fixture coverage for failed sign-in and failed logout, dashboard empty states, offline startup failure and retry, account switching, and 320 px wide layout at 2× text scaling. Dashboard errors now expose a live accessibility region, section titles are announced as headers, progress states are labeled, and retry controls work without returning a Future from `setState`.
- Added a Resources repository regression test: view absence (`PGRST205`/`42P01`) may use the compatibility query, while permission-denied (`403`/`42501`) and server errors do not fall back.
- `flutter analyze`: PASS — no issues found.
- `flutter test --reporter expanded`: PASS — 43 tests.
- iPhone 17 / iOS 26.4: PASS — `integration_test/app_smoke_test.dart` built, installed and launched on `43708308-5A8E-47D4-9313-698791EF168A`; first screen/navigation/public content smoke test passed.
- Android 16 / API 36: PASS — `integration_test/app_smoke_test.dart` built, installed and launched on `emulator-5554`; first screen/navigation/public content smoke test passed.
- macOS 27.2: PASS — `flutter run -d macos --debug --dart-define-from-file=dart_defines.json` built and launched the app; Supabase client initialization completed. No authentication operation was attempted.
- Windows CI: PASS — [run 40285404436](https://github.com/coimbatorestartupcommunity-hub/csc-circle-app/actions/runs/40285404436) for implementation commit `f113f94`; Dart analysis, 43 widget tests, Windows desktop build, and unsigned artifact upload all passed.
- Provider toggles and redirect allowlist remain unverified. Available Supabase project metadata did not include Authentication provider/URL configuration, and the dashboard requires an authorized interactive login. No callback exchange, Auth request, identity creation, live member read, migration, or production write was made.
- Current app IDs were inspected and documented in [`NATIVE_AUTH_VERIFICATION.md`](../architecture/NATIVE_AUTH_VERIFICATION.md). No identifier was changed. The Windows runner has no package identity/AUMID or registered callback protocol. Release/signing/privacy/account-deletion decisions are listed in [`RELEASE_READINESS_CHECKLIST.md`](../architecture/RELEASE_READINESS_CHECKLIST.md).
- The current Resources base-table compatibility route remains available. The proposed curated view, website server-route change, grants/revocation, and rollback remain coordinated review artifacts only; no SQL was applied. The native client falls back only when the view is genuinely absent, not on authorization or server errors.
