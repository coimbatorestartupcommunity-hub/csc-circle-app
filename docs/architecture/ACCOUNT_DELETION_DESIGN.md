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

### Exact owner decisions still required

- **Data disposition:** for profiles/contact details, memberships and claims, startups, notification content/read state, event registrations, uploaded files, audit/security records, and backups, decide delete, retain, or anonymize; identify legal/operational basis and retention duration for every retained category.
- **Timing:** choose request processing SLA, any grace period, whether and until when a request can be cancelled, and how partial failure is surfaced and resumed.
- **Identity assurance:** specify recent-auth age, accepted re-authentication providers, verified channel for confirmation, and support-assisted recovery for inaccessible accounts.
- **Holds and shared records:** define who may place/release a hold, how holds are disclosed, and what happens to registrations, safety reports, and other shared records that cannot be removed without affecting others.
- **Server contract:** approve the endpoint/RPC owner, request/status schema, idempotency behavior, rate limits, audit events, session revocation order, retry/resume semantics, and authorization/negative tests. The client must never submit a target user ID or receive elevated credentials.
- **User disclosures:** approve in-app, privacy-policy, and store-facing copy, including retained data, processing delay, cancellation, support contact, and completion notification.

No choice above is assumed by this design. Until CSC records these decisions and approves the endpoint contract, account deletion remains unavailable in the app.
