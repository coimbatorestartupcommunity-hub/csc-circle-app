# CSC Circle web and backend audit for the native client

**Latest read-only recheck:** 2026-10-26. The original source audit below was rechecked against the current local web checkout and live Supabase project metadata/policies; no member rows were read and no writes were made.

**Source inspected:** local `csc-circle` checkout, branch `phase4/local-email-notifications-collaboration`; its current worktree has unrelated uncommitted files and was left untouched. Findings below describe source and existing audit evidence, not a fresh production transaction.

## Observed architecture

- The website uses Supabase Auth with `@supabase/ssr` and cookie-bound Next.js clients. Its public client uses the publishable key; the server-only admin client exists for privileged website work.
- Most member-facing website handlers obtain the user from the server cookie session and call RLS-protected tables or vetted RPCs. A mobile app cannot reuse those cookie routes as-is.
- Existing business RPCs include `csc_register_event`, `list_discoverable_members`, `get_discoverable_member`, `csc_member_notification_inbox`, profile preference, startup revision, and admin-action functions. Client calls must remain authenticated and server-side RLS/RPC checks remain authoritative.
- Public content has published-only database visibility. The Resources, Opportunities, and Community Updates CMS routes are data-driven and public content reads use the publishable key. Draft media remains in a private Storage bucket and is served by website routes only after a published-record check.
- `member-portraits` is private. The existing audit records an 8 MiB object limit and image/PDF MIME allowlist; private member and startup media is exposed through scoped website routes and consent checks.
- Existing deployment and migration evidence is documented in the website repository, but a fresh live smoke check could not be run from this environment. The web tool could not access the canonical hostname, and no production write was attempted.

## Feature and access matrix

| Capability | Web route / source | Existing boundary | Mobile readiness |
|---|---|---|---|
| Home, About, Help, Terms, Privacy, Security, Contact | Public marketing routes | Static/SSR site content | Read-only content can be replicated in app; links should point to canonical website |
| Sign up, sign in, recovery | `/signup`, `/login`, `/forgot-password`, `/reset-password` | Supabase Auth through website cookie callbacks | Use Supabase Flutter Auth and PKCE deep links; real provider callback/redirect allowlist still needs owner configuration and device validation |
| Membership claim/status and member profile | `/member/*` | RLS tables, member route handlers, scoped RPCs | RLS-backed authenticated client is viable; confirm each query against current SQL before adding it |
| Member identity card and verification | `/member/id-card`, `/api/verify/member` | Membership status and server verification route | No stable mobile verification endpoint documented; avoid copying website cookie routes or trusting a client-supplied status |
| Member/founder directory | `/directory`, `/members*` | Published rows and `list_discoverable_members` / `get_discoverable_member`, active-member gates | Authenticated RPCs are suitable after contract/fixture review; pagination is offset-based with 30-row web limit |
| Startup profile and revisions | `/member/startups*`, `/directory*` | Owner-scoped profile writes, revision RPCs, private Storage, publication consent | Complex validation, media verification and revision workflow; defer writes until typed contract and RLS tests exist |
| Events, RSVP, registration, pass/check-in | `/events*`, `/member/events`, `/api/rsvp`, `/api/registrations` | Published event visibility and race-safe `csc_register_event` RPC | Registration RPC is the supported transaction boundary; do not implement capacity locally. No mobile check-in or write contract verified |
| Collaborations | `/collaborations` | Published content and private media delivery routes | Read-only content feasible after row/asset schema review; media route is not a direct bucket URL |
| Updates | `/updates`, `/updates/[slug]` | `community_updates`, published-only RLS; CMS writes behind `content.manage` | Public reads feasible; draft rows must remain hidden. Video publication requires separate approval |
| Resources | `/resources`, `/resources/[slug]` | Published-only table reads; download route checks publication | Public listing is feasible; download should use the authorized website route or a verified published asset URL |
| Opportunities | `/opportunities`, `/opportunities/[slug]` | Published rows with deadline eligibility enforced in SQL | Read-only queries must keep deadline rule; draft/expired content hidden |
| In-app notifications | `/member/notifications` | `csc_member_notification_inbox` and owner-scoped `notifications` updates | Inbox RPC suitable for authenticated read; writes should only mark own rows read; live push provider is not configured/verified |
| Admin CMS and roles | `/admin/*` | permission checks, audited RPCs, server-side service-role operations | Exclude from first app release unless a separate secure mobile-admin scope is approved |
| Account deletion | No verified member-facing delete request contract found in sampled routes | No documented mobile-safe endpoint identified | Required capability is not ready; implement a secure request pathway before store submission, with retention text and confirmation |

## Release risks and open checks

1. The app must not ship `SUPABASE_SECRET_KEY`, service-role credentials, or web cookies. Only the project URL and publishable key may be embedded.
2. Confirm OAuth providers, callback URI allowlist, and iOS Sign in with Apple review implications before enabling Google OAuth on Apple platforms.
3. Keep server-only operations (membership approval, event capacity, account deletion, media publication, notifications, admin actions) out of direct client writes unless a verified invoker RPC enforces the policy.
4. The website worktree contains user changes; it is not a clean integration branch. Do not edit it in place.
5. Production auth/RLS/storage metadata should be rechecked read-only with an authenticated owner session before release. No transaction was run here.

## Live metadata and policy recheck (2026-10-26)

- Supabase MCP returned one existing project named `csc-circle-production`, active/healthy, running PostgreSQL 17.11. No project was created or changed.
- The remote migration history ends at `20261024130000_community_updates_cms`, which matches the latest migration in the checked-out web repository.
- Catalog-only policy checks confirmed RLS for the audited public/member tables. Published content reads are restricted by publication status; opportunities additionally exclude expired deadlines using `Asia/Kolkata` date semantics. Profile, membership, and claim self-access is tied to `auth.uid()`. Notifications are constrained by recipient, in-app channel, and available status.
- Live function metadata confirmed `csc_register_event` is `SECURITY INVOKER`; directory list/detail RPCs are `SECURITY DEFINER`. Their local migration definitions enforce active-member/consent rules, empty search path, and authenticated-only grants. No authenticated request or member-record write was performed.
- Flutter bootstrap has an initial PKCE + secure-storage configuration path, but no Auth UI, callback/deep-link setup, or Data API client operations. Build configuration is currently absent by default, preserving public-preview behavior.

This is a metadata/source audit, not a full authorization penetration test or owner-authenticated feature smoke test. Recheck the project with an approved non-production account before enabling member-facing functionality.
