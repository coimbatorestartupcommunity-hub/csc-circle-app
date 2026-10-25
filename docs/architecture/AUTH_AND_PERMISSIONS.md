# Authentication and permissions

## Identity

The Supabase Auth user UUID is the account identity. It is not proof of CSC membership. The app reads membership state from authorized database results and never grants access based on email domain, editable user metadata, or locally cached role names.

## Session handling

Use Supabase Flutter Auth with PKCE for OAuth and the platform secure-storage integration for refresh tokens. Deep-link schemes and OAuth redirects must be allowlisted by the project owner before real provider login is considered ready. Sign-out and account switching clear user-partitioned cache; revoked or expired sessions fail closed.

The current Flutter bootstrap already conditionally initializes `supabase_flutter` with `AuthFlowType.pkce` and `SecureSessionStorage` backed by `flutter_secure_storage`. Configuration accepts only compile-time `CSC_SUPABASE_URL` and `CSC_SUPABASE_PUBLISHABLE_KEY`; no service-role/secret key is included. With either value absent, the app stays in its explicitly labeled public preview. Auth UI, callback/deep-link handling, and authenticated data calls are not implemented yet.

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

The website source audit did not identify a member-facing account-deletion request contract. App Store submission remains blocked until CSC provides a functioning deletion-request endpoint or an approved secure workflow and public retention explanation. Destructive deletion is always confirmed by the account owner.
