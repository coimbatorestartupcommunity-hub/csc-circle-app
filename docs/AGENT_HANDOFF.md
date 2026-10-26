# Agent handoff

**Updated:** 2026-10-26 (Asia/Kolkata)
**Current phase:** Phase 2 complete; Phase 3 native integration in progress.

## Current repository state

- Checkout: `/Users/vikash/Projects/csc-circle-app`, branch `main`, remote `origin` is the CSC Circle app repository.
- Preserve all existing work. `devtools_options.yaml` is a pre-existing untracked local file and is intentionally excluded from the app change commit.
- Phase 1 remains complete. Phase 2 changes add persisted onboarding/appearance/motion preferences, branded introduction animations, adaptive materials/controls, responsive/a11y improvements, 19 widget tests, 2 goldens, and cross-platform integration smoke coverage.
- Phase 3 implementation adds typed Supabase PKCE auth UI/session transitions, callback scheme registration, four explicit-field public content clients, content-page loading/empty/error states, and prepared-but-not-called member read repositories. Signup/recovery stay gated on redirect approval, and no member records are fetched without an approved safe test account.
- `dart_defines.json` is local and Git-ignored. Supabase MCP verified the existing project URL and an enabled publishable key match it; neither value is in source control or these docs.
- Member fixture tests cover anonymous fail-closed behavior and SDK-session owner scoping/RPC shape. They are client contract tests, not live member RLS verification. The full suite now has 32 tests.
- An Android direct-launch screenshot initially caught the system launch view before the first Flutter frame. The actual app was subsequently foregrounded with `flutter run`; the first-run onboarding rendered and is captured in `docs/evidence/android36-first-launch.png`. iOS standalone launch through Flutter likewise showed the first-run onboarding.

## Latest verification

- `flutter analyze`: PASS — no issues.
- `flutter test --reporter expanded`: PASS — 32 tests including Auth/content/member fixture coverage.
- Anonymous live Data API checks with the publishable key: Events, Updates, Opportunities, the website's explicit Resources projection, and the corrected native Resources projection return HTTP 200 with zero rows. The original Flutter request failed because it selected unused `thumbnail_path`; the client no longer requests it. No permission change was made. Table-wide `select=*` remains denied.
- Catalog inspection confirms `anon` has existing column grants for the website projection, including private document path/metadata fields, while lacking table-level SELECT. The public RLS policy filters to `publication_status='published'`; `archived` status is excluded. A coordinated public-view migration and pgTAP proposal is documented under `architecture/proposals/` and has not been run.
- Configured iPhone 17 / iOS 26.4 integration: PASS — onboarding/navigation plus all four public content screens; each live query returned HTTP 200 with zero rows and displayed the empty state.
- Configured Android API 36 integration: PASS — same four public content screens, each returning HTTP 200 with zero rows. The emulator initially had broken DNS; a cold boot with snapshot loading disabled and DNS configured restored host resolution without wiping data. Debug APK built and installed.
- macOS 27.2 configured debug build passed before the latest Resources field correction; rerun is pending. `flutter run -d macos` previously launched a CSC Circle window at the signed-out Account screen.
- Windows Actions PASS for implementation commit `b5780a8` in [run 40237973967](https://github.com/coimbatorestartupcommunity-hub/csc-circle-app/actions/runs/40237973967), and latest [run 40241934577](https://github.com/coimbatorestartupcommunity-hub/csc-circle-app/actions/runs/40241934577) for `f1a5582` passed analysis, all widget tests, Windows desktop build, and artifact upload.
- Current Windows Actions PASS: [run 40272355891](https://github.com/coimbatorestartupcommunity-hub/csc-circle-app/actions/runs/40272355891) verified source commit `d91bf7b` through analysis, widget tests, Windows desktop build, and artifact upload.

## Phase 2 limitations

- iOS Simulator runtime interaction via Xcode MCP requires iOS 27+, while the available iPhone 17 runtime is iOS 26.4.1. iOS Flutter semantics and integration are tested, but direct iOS VoiceOver cursor movement is not verified.
- No native Liquid Glass bridge; use accurate wording for Flutter Cupertino/translucent materials.
- A profile-mode Android cold launch logged 119 skipped frames on its first frame. The emulator's `gfxinfo` did not expose Flutter surface timing afterward, so trustworthy cold-start/frame-time data remains outstanding. Source review found only finite reveal/page animations, cached/downsampled imagery, and no full-screen or perpetual blur; responsive widget coverage reports no overflow.
- Supabase dashboard redirected to sign-in, leaving provider enablement, application IDs, and the `cscircle://auth-callback` allowlist unverified. No Auth request or test identity was created. No member data or production writes were used.
- Account deletion remains design-only in [`ACCOUNT_DELETION_DESIGN.md`](architecture/ACCOUNT_DELETION_DESIGN.md). No server endpoint or destructive call exists.
- Phase 3 status and contracts are documented in [`PHASE_3_STATUS.md`](phases/PHASE_3_STATUS.md) and [`MOBILE_API_CONTRACTS.md`](architecture/MOBILE_API_CONTRACTS.md).

## Current next actions

1. Review the least-privilege view proposal and required website server-route changes in [`RESOURCES_PUBLIC_PROJECTION.md`](architecture/proposals/RESOURCES_PUBLIC_PROJECTION.md). The app currently works against existing column grants without any permission change; the website's anonymous projection already includes document path fields.
2. Obtain authorized provider/app-ID/redirect confirmation plus approval for a safe test identity, then test sign-in/callback/session/logout and positive/negative member RLS on iOS, Android, and macOS. Keep signup/recovery gated.
3. Get approval for the account-deletion policy and server contract in [`ACCOUNT_DELETION_DESIGN.md`](architecture/ACCOUNT_DELETION_DESIGN.md). No production writes or permission changes have been made.
4. Preserve Phase 2 performance and platform limitations in `docs/phases/PHASE_2_COMPLETE.md`; avoid claiming native Liquid Glass or unverified iOS VoiceOver behavior.

## Member dashboard and account deletion

- Dashboard integration is prepared in [`MEMBER_DASHBOARD_READINESS.md`](architecture/MEMBER_DASHBOARD_READINESS.md). Do not invoke member repositories until an approved isolated account passes live owner-read and anonymous/cross-user denial checks.
- Account deletion remains design-only. CSC owner decisions and security gates are enumerated in [`ACCOUNT_DELETION_DESIGN.md`](architecture/ACCOUNT_DELETION_DESIGN.md); no endpoint, Auth Admin operation, or production write exists.
