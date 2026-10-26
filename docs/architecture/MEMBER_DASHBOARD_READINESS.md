# Member dashboard integration readiness

**Status:** Dashboard UI implemented with repository injection and fixture-backed tests. The production opt-in stays false and no live member endpoint is called from the app. Live owner and denial tests require explicitly approved isolated identities.

## Planned signed-in Account destination

The signed-in Account screen (`lib/features/member/member_dashboard_page.dart`) contains all five sections below and loads them independently when an explicitly injected repository is enabled. Widget tests inject fixture values; the normal app shell does not provide a member repository and `allowMemberReads` defaults to false.

| Section | Prepared operation | UI state and privacy behavior |
|---|---|---|
| Profile | `myProfile()` from the SDK session | Name/contact fields from the caller-owned profile only; skeleton, retry, and unavailable states; never query by a caller-supplied user ID. |
| Membership | `myMembership()` | Membership status and dates for the caller only; show a clear “contact CSC” state when no record exists instead of inferring eligibility. |
| Startups | `myStartups()` | Only startups linked to the caller’s verified membership; distinguish empty from denied/offline. |
| Notifications | `myNotificationInbox()` | Caller-addressed in-app items only; do not mark read until the owner-approved write contract is tested. |
| Digital ID | Derived from approved member fields only | Do not render or cache an ID until its contract, fields, expiry/revocation behavior, and screenshot/privacy handling are approved. |

On sign-out, account switch, or session expiry, the auth flow removes the dashboard subtree; a user-ID keyed dashboard is recreated for a changed session. This clears in-memory member values before showing the signed-out form. There is no member cache yet. Public content may remain cached under its separate public cache policy.

## Enablement gate

Before wiring these reads into the screen:

1. Confirm Supabase Auth provider, callback allowlist, and application identifiers through authorized project configuration access.
2. Approve one isolated test identity and confirm Auth triggers/side effects. Do not use an unrelated production member.
3. Under that identity, verify positive owner reads for each intended table/RPC and verify anonymous access is denied. With a second explicitly approved test identity, verify cross-user reads return no rows/denial. Test missing membership and expired-session behavior.
4. Keep write actions hidden/disabled until each corresponding server/RPC/RLS contract has a reviewed isolated write test. Notification read-state changes and event registrations are writes.
5. Record evidence and exact account/platform/config in Phase 3 status before enabling member calls by default.

Current repository behavior is fail-closed: the app shell does not inject or invoke member repositories, the account screen shows paused section states rather than fabricated member records, and the client derives ownership from the authenticated SDK session. The fixture records are synthetic test-only values and are never enabled in production.

## Fixture verification refresh (2026-10-26)

The fixture-only dashboard now has explicit offline/retry behavior, safe permission/general error messages, empty states for each section, accessible live error announcements and labeled loading indicators, and compact 320 px / 2× text coverage. Tests also verify failed sign-in and failed logout, session expiry clearing, account-switch replacement, and member-ID masking. `flutter analyze` passed and all 43 tests passed. These results validate UI behavior only; `allowMemberReads` remains false in the production shell and no live member repository call was made. Do not enable reads until all live owner-positive, anonymous-negative, and cross-user-negative checks above pass with approved isolated identities.
