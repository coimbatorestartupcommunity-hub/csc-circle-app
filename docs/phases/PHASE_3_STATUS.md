# Phase 3 — Authentication and member-data integration

**Status:** IN PROGRESS — existing website and production Supabase contracts have a read-only audit baseline. Native Auth UI and data features are not yet implemented.

## Read-only audit completed (2026-10-26)

- Inspected the current local `csc-circle` web repository on branch `phase4/local-email-notifications-collaboration`; it contains unrelated uncommitted files and was not modified.
- Confirmed web Auth uses Supabase SSR cookie-bound clients. Native code must use a separate Supabase Flutter session and must not reuse browser-cookie API handlers.
- Supabase MCP identified one active/healthy existing project, PostgreSQL 17.11. Read-only migration metadata reports head `20261024130000_community_updates_cms`, matching the checked-out web migration.
- Read only database catalogs/table metadata and RLS policy definitions; no production member rows or credentials were retrieved, and no SQL writes were executed.
- Confirmed published-only public reads for events, resources, community updates, and date-eligible opportunities; owner-scoped profile/membership/claim policies; and caller-scoped in-app notification inbox/read-state policies.
- Confirmed `csc_register_event` is an authenticated invoker RPC and that member-directory RPCs use active-member and consent checks. The latter are `SECURITY DEFINER`, use an empty search path, and are not executable by `anon`/`public` according to the audited migrations/live function metadata.

## Native integration baseline

- `lib/main.dart` conditionally initializes `supabase_flutter` with PKCE and `SecureSessionStorage` backed by `flutter_secure_storage`.
- Only compile-time URL and publishable-key inputs exist; the service-role/secret key is not part of the Flutter build configuration.
- Without both compile-time values, the app remains in a clearly labeled public preview.
- Auth screens, universal/app links, provider configuration checks, and Data API/RPC calls are still absent. The initialization path has been build-verified but a real login/session cycle has not been run.

## Safe implementation order

1. Confirm the environment-specific Supabase URL/publishable key are injected through local/CI secret handling without committing values. Never request or package a service-role key.
2. Get project-owner confirmation of enabled providers, Auth redirect allowlist, bundle/application identifiers, and one non-production test account. Test only sign-in, sign-out, and reads that cannot mutate production member data.
3. Implement typed Auth state/sign-in/recovery UI and app-link callback handling with PKCE and secure storage, including expired-session and offline states. Validate redirect URIs on iOS, Android, and desktop.
4. Add local fixture/contract tests before connecting read-only public content. Use explicit columns, published predicates, bounded pagination, and the error taxonomy in [`MOBILE_API_CONTRACTS.md`](../architecture/MOBILE_API_CONTRACTS.md).
5. Add authenticated member reads only after testing with an approved safe account. Keep membership eligibility, consent, and authorization decisions in RLS/RPC; do not trust client metadata.
6. Defer all production writes (claims, profile/startup edits, registrations, uploads, notification updates) until the exact RPC/RLS contract and an explicit non-production test path are verified.

## Current blockers and limits

- No safe test account or verified provider/redirect configuration was available, so no real Auth request was attempted.
- No live member data or production writes were used. RLS metadata checks do not replace authenticated positive/negative integration tests.
- Account deletion has no verified member-facing contract in the existing source audit; store readiness remains blocked until the owner provides an approved deletion path and retention text.

See [`CSC_WEB_AUDIT.md`](../architecture/CSC_WEB_AUDIT.md), [`MOBILE_API_CONTRACTS.md`](../architecture/MOBILE_API_CONTRACTS.md), and [`AUTH_AND_PERMISSIONS.md`](../architecture/AUTH_AND_PERMISSIONS.md).
