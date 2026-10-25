# Mobile API contracts

**Contract generation status:** Phase 3 audit baseline. `main.dart` conditionally initializes the Supabase Flutter client with PKCE and platform secure storage, but no Auth screen or Data API/RPC calls have been added yet.

## Rules

1. Use the Supabase Flutter SDK with the existing project's public URL and publishable key.
2. Authenticate through Supabase Auth. Data API and RPC calls carry the SDK-managed bearer token; never borrow the website's cookie session.
3. Before a table read/write is implemented, record its selected columns, ownership/published predicate, relevant RLS policies, nullability, ordering, pagination and error mapping here.
4. Prefer existing invoker RPCs for stateful workflows. Never reimplement event capacity, membership approval, startup publication, admin authorization or account deletion in Flutter.
5. Treat response schema changes as versioned app contract changes; support the currently released app version during staged rollouts. Add endpoint versions only when a separate server endpoint is actually introduced.
6. Cache only public content or explicitly user-scoped records. Key private cache by Supabase user UUID, clear it on sign-out/account switch, and do not persist tokens in app state or logs.
7. Writes should be idempotent or reconcile uncertain network outcomes before retry. Use bounded exponential backoff for safe reads; never auto-retry a non-idempotent write blindly.

## Candidate read contracts (not yet wired)

| Domain | Candidate operation | Access contract | Status |
|---|---|---|---|
| Public updates | Published-only `community_updates` select with explicit field list, ordered featured/date, bounded page | `anon`/authenticated RLS only; never draft | Source-confirmed; Flutter fixture tests pending |
| Resources | Published `resources` select; detail/download uses verified website route | Publication RLS and server-side document check | Source-confirmed; client not wired |
| Opportunities | Published and date-eligible select | Preserve IST deadline rule | Source-confirmed; client not wired |
| Events | Published event list with explicit fields | Existing public event visibility | Source-confirmed; schema fixture pending |
| Event registration | `csc_register_event` | Authenticated active member; RPC owns capacity/duplicate/waitlist transaction | RPC source-confirmed; no production write |
| Member directory | `list_discoverable_members(p_search, p_limit, p_offset)` and `get_discoverable_member(p_member_id)` | Active membership + sharing/consent rules enforced by database | RPC source-confirmed; authenticated integration pending |
| Notification inbox | `csc_member_notification_inbox()` | Valid active session; invoker/RLS scope to caller | RPC source-confirmed; authenticated integration pending |
| Membership claims/profile/startups | Existing member RPCs and owner-scoped tables | Per-action policy and consent checks required | Not wired; more schema review required |

## Live read-only contract verification (2026-10-26)

Checked the existing `csc-circle-production` project through Supabase MCP using metadata and catalog-only queries; no table rows were read or changed. The live project is active/healthy on PostgreSQL 17.11. Its applied migration history currently ends at `20261024130000_community_updates_cms`, matching the local web repository's latest migration.

- `events`: public `SELECT` only when `status = 'published'`; event registrations are selectable only by their owner or a permitted administrator. Registration writes must use authenticated `csc_register_event(event uuid, objective text)`, which is `SECURITY INVOKER` and delegates to the existing guarded transaction function.
- `resources` and `community_updates`: public/anonymous and authenticated reads are constrained to `publication_status = 'published'`.
- `opportunities`: public reads require published status and an unset or non-expired deadline evaluated in `Asia/Kolkata`.
- `profiles`, `memberships`, and `membership_claims`: RLS is enabled. Profile/membership/claim access is scoped to the caller's `auth.uid()`; claim insertion also requires the initial submitted state and accuracy declaration.
- `notifications`: the member inbox/read-state policies limit rows to available in-app notifications addressed to the caller, and update checks preserve that scope.
- `list_discoverable_members` and `get_discoverable_member` are `SECURITY DEFINER`; the audited definitions set an empty search path, require an active caller and active target, return only consented fields, revoke execution from `anon`/`public`, and grant it to `authenticated`.

These checks verify current policy metadata, not successful member login or end-to-end authorization. Do not test by writing production rows. Before enabling a feature, add a local Supabase fixture/contract test and confirm behavior with an approved non-production test account.

## Error and retry taxonomy

Map Supabase/Auth errors to `unauthorized`, `forbidden`, `validation`, `conflict`, `notFound`, `rateLimited`, `offline`, and `server`. Preserve server-safe user messages. Network read retries use bounded exponential backoff with jitter; writes require an idempotency key or read-after-error reconciliation first.
