# Agent handoff

**Updated:** 2026-10-26 (Asia/Kolkata)
**Current phase:** Phase 2 complete; Phase 3 native integration in progress.

## Current repository state

- Checkout: `/Users/vikash/Projects/csc-circle-app`, branch `main`, remote `origin` is the CSC Circle app repository.
- Preserve all existing work. `devtools_options.yaml` is a pre-existing untracked local file and is intentionally excluded from the app change commit.
- Phase 1 remains complete. Phase 2 changes add persisted onboarding/appearance/motion preferences, branded introduction animations, adaptive materials/controls, responsive/a11y improvements, 19 widget tests, 2 goldens, and cross-platform integration smoke coverage.
- Phase 3 implementation adds typed Supabase PKCE auth UI/session transitions, callback scheme registration, four explicit-field public content clients, content-page loading/empty/error states, and a fixture-driven signed-in dashboard with Profile, Membership, Startups, Notifications, and masked Digital Member ID sections. The app shell keeps member reads disabled and injects no member repository.
- Supabase session JSON and the PKCE verifier now both use platform secure storage. Fixture tests verify separate session/verifier key behavior; callback exchange and process-restart persistence still need an approved isolated identity/device test.
- `dart_defines.json` is local and Git-ignored. Supabase MCP verified the existing project URL and an enabled publishable key match it; neither value is in source control or these docs.
- Member fixture tests cover anonymous fail-closed behavior and SDK-session owner scoping/RPC shape. Dashboard fixtures cover all sections, sign-out, session expiry, and account switching; client contract tests are not live member RLS verification. The full suite now has 37 tests.
- An Android direct-launch screenshot initially caught the system launch view before the first Flutter frame. The actual app was subsequently foregrounded with `flutter run`; the first-run onboarding rendered and is captured in `docs/evidence/android36-first-launch.png`. iOS standalone launch through Flutter likewise showed the first-run onboarding.

## Latest verification

- `flutter analyze`: PASS — no issues after dashboard, PKCE storage, and view-first Resources changes.
- `flutter test --reporter expanded`: PASS — 37 tests including Auth/content/member/dashboard/secure-storage fixtures.
- Anonymous live Data API checks with the publishable key: Events, Updates, Opportunities, the website's explicit Resources projection, and the corrected native Resources projection return HTTP 200 with zero rows. The original Flutter request failed because it selected unused `thumbnail_path`; the client no longer requests it. No permission change was made. Table-wide `select=*` remains denied.
- Catalog inspection confirms `anon` has existing column grants for the website projection, including private document path/metadata fields, while lacking table-level SELECT. The public RLS policy filters to `publication_status='published'`; `archived` status is excluded. A coordinated public-view migration and pgTAP proposal is documented under `architecture/proposals/` and has not been run.
- Configured iPhone 17 / iOS 26.4 integration: PASS — onboarding/navigation plus all four public content screens; Resources used the view-missing compatibility path and the live base-table query returned HTTP 200 with zero rows.
- Configured Android API 36 integration: PASS — same four public content screens and view-missing Resources compatibility path. The emulator initially had broken DNS; a cold boot with snapshot loading disabled and DNS configured restored host resolution without wiping data. Debug APK built and installed.
- macOS 27.2 configured debug build and app launch PASS; Supabase initialization completed and the app window rendered. No real sign-in was attempted.
- Windows Actions PASS for implementation commit `b5780a8` in [run 40237973967](https://github.com/coimbatorestartupcommunity-hub/csc-circle-app/actions/runs/40237973967), and latest [run 40241934577](https://github.com/coimbatorestartupcommunity-hub/csc-circle-app/actions/runs/40241934577) for `f1a5582` passed analysis, all widget tests, Windows desktop build, and artifact upload.
- Current Windows Actions PASS: [run 40272355891](https://github.com/coimbatorestartupcommunity-hub/csc-circle-app/actions/runs/40272355891) verified source commit `d91bf7b` through analysis, widget tests, Windows desktop build, and artifact upload.
- Current Windows Actions PASS: [run 40280620907](https://github.com/coimbatorestartupcommunity-hub/csc-circle-app/actions/runs/40280620907) verified commit `e120995` through analysis, all 37 widget tests, Windows desktop build, and artifact upload.

## Phase 2 limitations

- iOS Simulator runtime interaction via Xcode MCP requires iOS 27+, while the available iPhone 17 runtime is iOS 26.4.1. iOS Flutter semantics and integration are tested, but direct iOS VoiceOver cursor movement is not verified.
- No native Liquid Glass bridge; use accurate wording for Flutter Cupertino/translucent materials.
- A profile-mode Android cold launch logged 119 skipped frames on its first frame. The emulator's `gfxinfo` did not expose Flutter surface timing afterward, so trustworthy cold-start/frame-time data remains outstanding. Source review found only finite reveal/page animations, cached/downsampled imagery, and no full-screen or perpetual blur; responsive widget coverage reports no overflow.
- Supabase dashboard redirected to sign-in, leaving provider enablement, application IDs, and the `cscircle://auth-callback` allowlist unverified. No Auth request or test identity was created. No member data or production writes were used.
- Current source IDs are listed in [`NATIVE_AUTH_VERIFICATION.md`](architecture/NATIVE_AUTH_VERIFICATION.md); CSC still needs to confirm they are final and registered. That checklist covers provider/redirect verification and test identities.
- Account deletion remains design-only in [`ACCOUNT_DELETION_DESIGN.md`](architecture/ACCOUNT_DELETION_DESIGN.md). No server endpoint or destructive call exists.
- Phase 3 status and contracts are documented in [`PHASE_3_STATUS.md`](phases/PHASE_3_STATUS.md) and [`MOBILE_API_CONTRACTS.md`](architecture/MOBILE_API_CONTRACTS.md).
- Native provider/redirect/application-ID checks are listed in [`NATIVE_AUTH_VERIFICATION.md`](architecture/NATIVE_AUTH_VERIFICATION.md). The Resources staged web/native rollout and rollback are recorded in [`RESOURCES_PUBLIC_PROJECTION.md`](architecture/proposals/RESOURCES_PUBLIC_PROJECTION.md).

## Current next actions

1. Review the staged least-privilege view proposal, website server-route changes, rollback, and minimum supported app-version requirements in [`RESOURCES_PUBLIC_PROJECTION.md`](architecture/proposals/RESOURCES_PUBLIC_PROJECTION.md). The app prefers the view and falls back only if it is missing. No migration or production permission change has been applied.
2. Obtain authorized provider/app-ID/redirect confirmation plus approval for a safe test identity, then test sign-in/callback/session/logout and positive/negative member RLS on iOS, Android, and macOS. Keep signup/recovery gated.
3. Get approval for the account-deletion policy and server contract in [`ACCOUNT_DELETION_DESIGN.md`](architecture/ACCOUNT_DELETION_DESIGN.md). No production writes or permission changes have been made.
4. Preserve Phase 2 performance and platform limitations in `docs/phases/PHASE_2_COMPLETE.md`; avoid claiming native Liquid Glass or unverified iOS VoiceOver behavior.

## Member dashboard and account deletion

- Dashboard integration is prepared in [`MEMBER_DASHBOARD_READINESS.md`](architecture/MEMBER_DASHBOARD_READINESS.md). Do not invoke member repositories until an approved isolated account passes live owner-read and anonymous/cross-user denial checks.
- Account deletion remains design-only. CSC owner decisions and security gates are enumerated in [`ACCOUNT_DELETION_DESIGN.md`](architecture/ACCOUNT_DELETION_DESIGN.md); no endpoint, Auth Admin operation, or production write exists.

## Verification refresh (2026-10-26)

- Latest local checks: `flutter analyze` PASS; `flutter test --reporter expanded` PASS (43 tests).
- iPhone 17 / iOS 26.4 `integration_test/app_smoke_test.dart`: PASS (build, install, launch and navigation/content smoke test).
- Android 16 / API 36 `integration_test/app_smoke_test.dart`: PASS (debug build, install, launch and navigation/content smoke test).
- macOS 27.2 `flutter run -d macos --debug --dart-define-from-file=dart_defines.json`: PASS (build/launch; Supabase initialized).
- No authentication request, callback exchange, real identity, or member repository call was made. Supabase provider and callback allowlist settings remain unavailable in the authorized project metadata; dashboard access requires the owner/operator to authenticate. Signup/recovery and member reads remain gated.
- Fixture additions cover offline retry, empty states, permission/error messaging, large text on compact width, sign-in/logout failures, session expiry, account-switch clearing, and Resources view errors that must not trigger fallback. The Resources view and grant/revoke plan remains coordinated across both repos and unapplied.
- No Windows workflow has yet run for this uncommitted refresh. Previous passing run `40280620907` is evidence for `e120995`, not for these changes; push the reviewed changes and confirm the new CI result.
- `NATIVE_AUTH_VERIFICATION.md` records current iOS/macOS bundle IDs and Android application ID without changing them, plus the unassigned Windows identity/protocol. `RELEASE_READINESS_CHECKLIST.md` tracks signing, deletion, privacy, supported versions, and security testing.
- Preserve untracked local `devtools_options.yaml` and ignored `dart_defines.json`; do not stage them.
