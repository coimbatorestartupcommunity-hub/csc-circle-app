# Member dashboard integration readiness

**Status:** UI integration plan only. Member repositories are typed and fixture-tested, but no live member endpoint is called from the app. Live owner and denial tests require an explicitly approved isolated identity.

## Planned signed-in Account destination

Keep the existing signed-out Account and authentication navigation intact. After a valid Supabase session is established, load the following independently so one unavailable section does not hide the rest:

| Section | Prepared operation | UI state and privacy behavior |
|---|---|---|
| Profile | `myProfile()` from the SDK session | Name/contact fields from the caller-owned profile only; skeleton, retry, and unavailable states; never query by a caller-supplied user ID. |
| Membership | `myMembership()` | Membership status and dates for the caller only; show a clear “contact CSC” state when no record exists instead of inferring eligibility. |
| Startups | `myStartups()` | Only startups linked to the caller’s verified membership; distinguish empty from denied/offline. |
| Notifications | `myNotificationInbox()` | Caller-addressed in-app items only; do not mark read until the owner-approved write contract is tested. |
| Digital ID | Derived from approved member fields only | Do not render or cache an ID until its contract, fields, expiry/revocation behavior, and screenshot/privacy handling are approved. |

On sign-out or account switch, clear in-memory member state and any user-scoped cache before showing the signed-out account screen. Public content may remain cached under its separate public cache policy. Session expiry must transition through the existing auth/session-expired flow and must not leave the previous member’s details visible.

## Enablement gate

Before wiring these reads into the screen:

1. Confirm Supabase Auth provider, callback allowlist, and application identifiers through authorized project configuration access.
2. Approve one isolated test identity and confirm Auth triggers/side effects. Do not use an unrelated production member.
3. Under that identity, verify positive owner reads for each intended table/RPC and verify anonymous access is denied. With a second explicitly approved test identity, verify cross-user reads return no rows/denial. Test missing membership and expired-session behavior.
4. Keep write actions hidden/disabled until each corresponding server/RPC/RLS contract has a reviewed isolated write test. Notification read-state changes and event registrations are writes.
5. Record evidence and exact account/platform/config in Phase 3 status before enabling member calls by default.

Current repository behavior is fail-closed: the app shell does not invoke member repositories, the account screen does not show fabricated member records, and the client derives ownership from the authenticated SDK session.
