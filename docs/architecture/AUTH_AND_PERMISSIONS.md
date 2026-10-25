# Authentication and permissions

## Identity

The Supabase Auth user UUID is the account identity. It is not proof of CSC membership. The app reads membership state from authorized database results and never grants access based on email domain, editable user metadata, or locally cached role names.

## Session handling

Use Supabase Flutter Auth with PKCE for OAuth and the platform secure-storage integration for refresh tokens. Deep-link schemes and OAuth redirects must be allowlisted by the project owner before real provider login is considered ready. Sign-out and account switching clear user-partitioned cache; revoked or expired sessions fail closed.

## Data permissions

- Public clients use only the publishable Supabase key.
- Exposed-table access requires both explicit grants and row policies; each query is checked against current migrations.
- Member-owned records remain scoped to `auth.uid()`; membership eligibility and publication consent are checked server-side.
- Only vetted invoker RPCs may perform multi-step or race-sensitive operations.
- Admin capabilities are omitted from the initial mobile surface.
- Service-role key, browser cookies, and admin roles never enter app configuration or logs.

## Account lifecycle

The website source audit did not identify a member-facing account-deletion request contract. App Store submission remains blocked until CSC provides a functioning deletion-request endpoint or an approved secure workflow and public retention explanation. Destructive deletion is always confirmed by the account owner.
