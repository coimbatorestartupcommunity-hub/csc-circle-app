# Authentication and permissions

## Identity

The Supabase Auth user UUID is the account identity. It is not proof of CSC membership. The app reads membership state from authorized database results and never grants access based on email domain, editable user metadata, or locally cached role names.

## Session handling

Use Supabase Flutter Auth with PKCE and platform secure storage for both the persisted session and short-lived PKCE verifier. Deep-link schemes and OAuth redirects must be allowlisted by the project owner before real provider login is considered ready. Sign-out, session expiry, and account switching remove the member dashboard subtree and its in-memory user data; no persistent member cache is implemented. Revoked or expired sessions fail closed.

The current Flutter bootstrap conditionally initializes `supabase_flutter` with `AuthFlowType.pkce`, `SecureSessionStorage`, and `SecurePkceStorage`, all backed by `flutter_secure_storage`. Configuration accepts only compile-time `CSC_SUPABASE_URL` and `CSC_SUPABASE_PUBLISHABLE_KEY`; no service-role/secret key is included. With either value absent, the app stays in its explicitly labeled public preview. Native Auth UI, SDK-managed callback handling, and a fixture-driven but live-data-gated member dashboard are implemented. Real sign-in, secure session restoration on a device, and member reads remain gated on project-owner-confirmed provider/redirect configuration and approved safe test identities.

The web app uses `@supabase/ssr` clients bound to request cookies. Those cookies, web callback routes, and server-only admin clients are not mobile session mechanisms. The native app must obtain its own Supabase Auth session, persist it in platform secure storage, and let the SDK attach the bearer token to Data API/RPC calls. Provider enablement, callback allowlists, and a safe test account are not yet verified.

## Data permissions

- Public clients use only the publishable Supabase key.
- Exposed-table access requires both explicit grants and row policies; each query is checked against current migrations.
- Member-owned records remain scoped to `auth.uid()`; membership eligibility and publication consent are checked server-side.
- Only vetted invoker RPCs may perform multi-step or race-sensitive operations.
- Admin capabilities are omitted from the initial mobile surface.
- Service-role key, browser cookies, and admin roles never enter app configuration or logs.

The 2026-10-26 read-only live policy audit is recorded in [`MOBILE_API_CONTRACTS.md`](MOBILE_API_CONTRACTS.md). It confirms RLS on the audited member/content tables, published-only public content reads, caller-scoped member records, and the consent-gated active-member directory RPC. Metadata verification is not an authenticated end-to-end test.

## Account lifecycle

The website source audit did not identify a member-facing account-deletion request contract. See [`ACCOUNT_DELETION_DESIGN.md`](ACCOUNT_DELETION_DESIGN.md) for the proposed secure workflow and unresolved owner decisions. Do not implement destructive deletion until CSC approves its retention policy and server-side contract.
