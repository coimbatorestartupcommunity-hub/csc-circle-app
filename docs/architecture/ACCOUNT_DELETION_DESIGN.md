# Native account deletion design

**Status:** Design only. No deletion UI, endpoint, database mutation, or Auth Admin operation has been implemented or called.

## Proposed user flow

1. Show **Delete account** in the signed-in account settings and explain which CSC Circle data is removed, retained, or made anonymous before the user confirms.
2. Require a recent authenticated session. If it is stale, request re-authentication through Supabase Auth; never ask for or store the account password in a custom deletion form.
3. Require an explicit confirmation step (re-entering a short confirmation phrase or equivalent) and submit an idempotent request bound to the current `auth.uid()`. The client must not send an arbitrary target user ID.
4. The server re-checks the caller, recent-auth requirement, request rate, outstanding legal/operational holds, and the approved data-retention plan. It records a request and returns a request ID and status.
5. A server-owned workflow performs the approved deletion/anonymization sequence, revokes sessions, and removes the Supabase Auth identity only after dependent records are handled. The native client never calls the Auth Admin API or directly deletes rows.
6. Show request status and provide cancellation only if the approved policy allows it. Send confirmation through a verified channel without exposing sensitive profile or membership data.

## Security and privacy requirements

- Enforce authorization and ownership on the server from the verified session; ignore client-supplied identity/role claims.
- Make requests idempotent and resistant to CSRF/replay, account enumeration, and duplicate submissions. Apply rate limits and audit events without logging credentials or sensitive member fields.
- Revoke refresh tokens/sessions as part of the workflow; fail closed if cleanup is incomplete and make retry/resume safe.
- Define a field-by-field disposition for profiles, memberships, claims, startups, notifications, event registrations, uploaded files, audit records, and backups. Specify any required retention, anonymization, and deletion timing before implementation.
- Do not cascade-delete shared community records or erase data needed to honor another person’s registration, safety, or audit history without an approved policy.
- Explain identity verification, consequences, any processing delay, data retained and why, support contact, and whether a request can be cancelled in the app and public privacy/account-deletion pages.
- Keep service-role credentials server-side. Use an existing approved server endpoint or a narrowly scoped server-side function; do not grant the mobile publishable key elevated access.

## Owner decisions and implementation gate

CSC must approve the retention/deletion matrix, processing and cancellation policy, user-facing copy, identity re-authentication method, support/escalation path, and the exact server endpoint/RPC plus its authorization tests. Review the relevant privacy policy and store account-deletion requirements before shipping. Then test the complete workflow against an isolated test identity and disposable fixture data, including authorization failure, retries, session revocation, and partial-failure recovery. No production deletion test is allowed without explicit authorization.
