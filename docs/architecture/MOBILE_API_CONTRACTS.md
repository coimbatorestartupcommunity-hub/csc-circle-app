# Mobile API contracts

**Contract generation status:** Phase 1 inventory only; no API client calls have been added yet.

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

## Error and retry taxonomy

Map Supabase/Auth errors to `unauthorized`, `forbidden`, `validation`, `conflict`, `notFound`, `rateLimited`, `offline`, and `server`. Preserve server-safe user messages. Network read retries use bounded exponential backoff with jitter; writes require an idempotency key or read-after-error reconciliation first.
