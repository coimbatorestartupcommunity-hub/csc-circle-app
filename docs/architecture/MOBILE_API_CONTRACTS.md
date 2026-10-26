# Mobile API contracts

**Contract generation status:** Phase 3 implementation. Flutter initializes the existing Supabase project with PKCE and platform secure storage when URL and publishable key are injected. All four public content clients have passed anonymous Data API checks with existing published-only RLS and column grants. Member reads are prepared but not called; real Auth and live member verification await approved configuration/test credentials.

## Rules

1. Use the Supabase Flutter SDK with the existing project's public URL and publishable key.
2. Authenticate through Supabase Auth. Data API and RPC calls carry the SDK-managed bearer token; never borrow the website's cookie session.
3. Before a table read/write is implemented, record its selected columns, ownership/published predicate, relevant RLS policies, nullability, ordering, pagination and error mapping here.
4. Prefer existing invoker RPCs for stateful workflows. Never reimplement event capacity, membership approval, startup publication, admin authorization or account deletion in Flutter.
5. Treat response schema changes as versioned app contract changes; support the currently released app version during staged rollouts. Add endpoint versions only when a separate server endpoint is actually introduced.
6. Cache only public content or explicitly user-scoped records. Key private cache by Supabase user UUID, clear it on sign-out/account switch, and do not persist tokens in app state or logs.
7. Writes should be idempotent or reconcile uncertain network outcomes before retry. Use bounded exponential backoff for safe reads; never auto-retry a non-idempotent write blindly.

## Read contracts

| Domain | Candidate operation | Access contract | Status |
|---|---|---|---|
| Public updates | `community_updates`: `id,slug,title,category,summary,featured,cover_image_path,cover_image_alt,published_at`; `publication_status=published`, `featured DESC, published_at DESC`, range pagination (default 20, max 50) | `anon`/authenticated RLS only; never draft | Implemented and fixture-tested |
| Resources | `resources`: `id,slug,title,category,resource_type,summary,tags,external_url,published_at`; `publication_status=published`, `published_at DESC`, range pagination; no image/document storage paths | Existing anon column grants plus published-only RLS; no new grant | Implemented, fixture-tested, and live HTTP 200 verified (0 rows) |
| Opportunities | `opportunities`: `id,title,category,summary,organization,deadline,starts_on,application_url`; `publication_status=published`, unset or `deadline >= Asia/Kolkata current date`, deadline ascending then publish date descending; range pagination | Preserve IST deadline rule | Implemented and fixture-tested |
| Events | `events`: `id,title,category,description,cover_image,starts_at,ends_at,location,venue`; `status=published`, `starts_at ASC`, range pagination | Existing public event visibility | Implemented and fixture-tested |
| Event registration | `csc_register_event` | Authenticated active member; RPC owns capacity/duplicate/waitlist transaction | RPC source-confirmed; no production write |
| Member directory | `list_discoverable_members(p_search, p_limit, p_offset)` and `get_discoverable_member(p_member_id)` | Active membership + sharing/consent rules enforced by database | RPC source-confirmed; authenticated integration pending |
| Notification inbox | `csc_member_notification_inbox()` | Valid active session; invoker/RLS scope to caller | Typed read repository prepared; intentionally not called pending approved safe account |
| Membership claims/profile/startups | Existing owner-scoped `profiles`, `memberships`, `directory_startups` reads with explicit columns | Caller UID predicate plus RLS; no verification tokens | Typed read repository prepared; intentionally not called pending approved safe account |

## Live read-only contract verification (2026-10-26)

Checked the existing `csc-circle-production` project through Supabase MCP using metadata and catalog-only queries; no table rows were read or changed. The live project is active/healthy on PostgreSQL 17.11. Its applied migration history currently ends at `20261024130000_community_updates_cms`, matching the local web repository's latest migration.

- `events`: public `SELECT` only when `status = 'published'`; event registrations are selectable only by their owner or a permitted administrator. Registration writes must use authenticated `csc_register_event(event uuid, objective text)`, which is `SECURITY INVOKER` and delegates to the existing guarded transaction function.
- `resources` and `community_updates`: public/anonymous and authenticated reads are constrained to `publication_status = 'published'`.
- `opportunities`: public reads require published status and an unset or non-expired deadline evaluated in `Asia/Kolkata`.
- `profiles`, `memberships`, and `membership_claims`: RLS is enabled. Profile/membership/claim access is scoped to the caller's `auth.uid()`; claim insertion also requires the initial submitted state and accuracy declaration.
- `notifications`: the member inbox/read-state policies limit rows to available in-app notifications addressed to the caller, and update checks preserve that scope.
- `list_discoverable_members` and `get_discoverable_member` are `SECURITY DEFINER`; the audited definitions set an empty search path, require an active caller and active target, return only consented fields, revoke execution from `anon`/`public`, and grant it to `authenticated`.

These checks verify current policy metadata, not successful member login or end-to-end authorization. Do not test by writing production rows. Before enabling a feature, add a local Supabase fixture/contract test and confirm behavior with an approved non-production test account.

### Runtime privilege check (2026-10-26)

The Data API was tested with the existing enabled publishable key and no user session. Events, community updates, opportunities, the exact website `RESOURCE_PUBLIC_FIELDS` projection, and the corrected native Resources projection returned HTTP 200 with empty first pages. The original native request returned HTTP 401 / `42501` because it selected `thumbnail_path`, a column not granted to `anon`; the app did not use that field, so it was removed. `anon` has column-level SELECT on the website projection, including `document_path`, `document_filename`, and `document_mime`, but no table-level SELECT. A document-path-only request also returned HTTP 200 (with zero rows), confirming that the path column is currently queryable by anonymous clients for rows allowed by RLS; no path values were retrieved. `select=*` remains denied. The current RLS policy filters `publication_status='published'`. A narrower public-view hardening proposal is documented at [`proposals/RESOURCES_PUBLIC_PROJECTION.md`](proposals/RESOURCES_PUBLIC_PROJECTION.md) and has not been applied. The view migration must be coordinated with website changes because the current web projection uses those path columns.

### Flutter implementation details

- Implementation: `lib/core/backend/public_content.dart`, `lib/core/backend/member_data_repository.dart`, `lib/features/content/public_content_page.dart`.
- Public query failures map to offline, unauthorized, forbidden, invalid-response, or generic server categories; 15-second request timeouts are applied. Public pages display explicit loading, retry, empty, and no-config preview states.
- `limit` is clamped to 1–50 and the UI uses 20-row pages. Events order oldest upcoming/start date first; updates prioritize featured and recency; resources sort by recency; opportunities sort by eligible deadline and recency.
- Member repository methods always derive the user id from the SDK session and do not accept arbitrary user ids. No member methods are referenced by the app shell yet.
- Auth uses `SupabaseAuthRepository`, SDK-managed PKCE callback handling, and `SecureSessionStorage`. Native redirect registration exists for iOS, macOS, and Android, while signup/recovery remain disabled unless `CSC_AUTH_REDIRECT_APPROVED=true` and the URL/key are present.
- Fixture tests are in `test/public_content_repository_test.dart`, `test/phase3_auth_widget_test.dart`, and `test/member_data_repository_test.dart`; they use no live member record. Device integration coverage is in `integration_test/app_smoke_test.dart` and may use the ignored local public configuration for read-only published-content requests.

## Error and retry taxonomy

Map Supabase/Auth errors to `unauthorized`, `forbidden`, `validation`, `conflict`, `notFound`, `rateLimited`, `offline`, and `server`. Preserve server-safe user messages. Network read retries use bounded exponential backoff with jitter; writes require an idempotency key or read-after-error reconciliation first.
