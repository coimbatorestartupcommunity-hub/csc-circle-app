# Resources public-access proposal

**Status:** Prepared for security review only. None of the proposal SQL or tests has been applied or run. Do not copy these files into an executable migration directory until the project owner approves the public access contract.

## Current live access contract

Read-only catalog and Data API inspection on 2026-10-26 confirmed:

- RLS is enabled (not forced) on `public.resources`.
- The permissive `resources_public_read` SELECT policy applies to role `public` and filters `publication_status = 'published'`. The enum has `draft`, `pending`, `published`, and `archived` values; the public policy excludes the first, second, and fourth. An `archived_at IS NULL` condition is not present in the policy.
- `anon` has **no table-level SELECT**, but it does have a column-level SELECT grant for the website’s existing explicit public projection. Those grants include `document_path`, `document_filename`, and `document_mime`, as well as `cover_image_path`, `external_url`, `updated_at`, and public content fields. It does not have `thumbnail_path`, `document_size`, `publication_consent`, `archived_at`, `created_by`, `updated_by`, or `created_at`.
- `authenticated` has table-level SELECT; its access remains governed by the existing RLS policies.
- There are no existing views dependent on `public.resources` in the checked public schema.
- A no-session REST request using the native field list failed with `42501` because Flutter selected `thumbnail_path`. Removing this unused field from the native projection returned HTTP 200 with zero published rows. The website’s exact `RESOURCE_PUBLIC_FIELDS` query also returned HTTP 200 with zero rows. `select=*` returned HTTP 401 / `42501`, as expected without table-level access. A `document_path`-only query returned HTTP 200 (zero rows), confirming that path column is currently granted to anon even though the path itself was not returned in this check.

## Website dependency comparison

`src/lib/services/cms-public.ts` uses an anonymous Supabase client for public resources. Its actual `RESOURCE_PUBLIC_FIELDS` constant is an explicit projection, not `select=*`; it selects the existing anon-granted columns and filters `publication_status='published'`. The website page code consumes the result through server-only helpers. `/api/cms/image` validates a published resource by filtering on `cover_image_path`, then uses `createAdminClient()` to read the private object. `/api/resources/[slug]/download` uses the anon helper to obtain `document_path`, then a server-only admin client to issue a short-lived storage URL. Admin CMS reads use `createAdminClient()` and `select('*')`; they are service-role/server-side and do not depend on anon column grants. Although values are not meant to be sent to the browser, the anonymous Data API currently permits clients to query these path columns directly.

The user-supplied column grant would **not** satisfy the current website projection: it omits fields used by the public site, including `description`, `audience`, `cover_image_path`, document metadata, attribution/source/SEO fields, `publication_status`, and `updated_at`. The current table-wide grant would make `select=*` possible and expose extra internal columns. The Flutter client does not render `thumbnail_path`, so granting that column to make the old native query work is unnecessary; the client now drops it.

The proposed future projection removes storage paths and audit/consent metadata from direct anonymous base-table access. This requires coordinated website **and native app** changes. The native client now prefers `csc_public_resources` and falls back to its existing explicit, path-free base-table projection only when the view is not installed (`PGRST205`/`42P01`). It does not fall back for permission, network, or other errors. This lets a new app version work both before and after the additive view deployment. Older app versions still query the base table, so CSC must not revoke the existing grants until its supported-version policy permits it.

The website change must update `src/lib/services/cms-public.ts` to read `csc_public_resources` and return a public type containing only content plus `has_cover_image` / `has_document`; no storage path can be placed in client props, HTML, JSON, logs, or URLs. The current `cmsImageUrl(path)` emits the raw storage path as a `?path=` URL parameter, so change image handling in `src/app/api/cms/image/route.ts` to accept a validated resource slug instead. Verify the published projection, then use server-only `createAdminClient()` to retrieve `cover_image_path` with explicit `publication_status='published'` and `archived_at IS NULL` predicates, validate the storage key against the existing strict path pattern, and download privately. Change `src/app/api/resources/[slug]/download/route.ts` to verify the same published projection first, then fetch document path/name through the server-only admin client with the same eligibility predicates, validate the path, and issue the existing short-lived signed URL with `Cache-Control: private, no-store`. Return 404 for missing, unpublished, archived, or malformed records. Check page/RSC output, browser network URLs, analytics, and server logs to ensure path values never reach a browser. The view has no `document_path`, `document_filename`, `document_mime`, `cover_image_path`, `created_by`, `updated_by`, `created_at`, or `updated_at` fields.

The view explicitly constrains both `publication_status='published'` and `archived_at IS NULL`; its owner-rights behavior intentionally does not rely on base-table RLS, so this predicate is a security boundary. The pgTAP fixture includes draft, pending, archived-status, and published-with-archived-timestamp rows and expects only the active published row to be visible.

## Files and test gate

- [`20261026170000_public_resources_projection.sql`](20261026170000_public_resources_projection.sql): additive view and grants only.
- [`20261026170001_public_resources_projection.test.sql`](20261026170001_public_resources_projection.test.sql): transactional pgTAP fixture covering public published visibility, draft/archive exclusion, base-table denial, and storage/internal-field omission.
- [`20261026170002_revoke_anon_resources_base_access.sql`](20261026170002_revoke_anon_resources_base_access.sql): a separate, later revoke step. It breaks old app builds and must remain unapplied until the web/native rollout and supported-version sunset are approved.
- [`20261026170003_restore_anon_resources_base_access.rollback.sql`](20261026170003_restore_anon_resources_base_access.rollback.sql): restores only the exact existing anonymous column list (no table-wide SELECT).

## Coordinated rollout and rollback

1. CSC reviews and approves the public projection and version-support plan. Keep the production grants untouched.
2. In an existing approved non-production branch/environment, apply the additive view migration only. Verify the view exposes only active published fixtures, and confirm draft, pending, archived-status and archived-timestamp fixtures are absent. Direct base-table paths remain accessible under today's grants at this stage; verify their denial only after the later revoke step.
3. Deploy website code using the view and server-only path lookups. Verify listing, detail, images, downloads, draft/archived 404s, and that serialized page output contains no storage paths.
4. Release the view-preferring native app. Verify both view mode and missing-view compatibility mode on iOS, Android, and desktop. Retain old base-table grants while supported old builds exist. The new client falls back only for missing-view errors, never for forbidden/network errors.
5. Only after the owner-approved app-version sunset and web rollout, apply the separate revoke proposal. Re-run positive/negative Data API and website tests. Do not use table-wide SELECT.

Rollback before revocation: revert web/app clients to the base table; the original grants are still present. Rollback after revocation: first apply the exact-column restore SQL in `20261026170003_restore_anon_resources_base_access.rollback.sql`, verify the current site/app requests, then revert clients. Keep the curated view until no deployed client uses it; dropping it is a separate reviewed step. No rollback step grants table-wide SELECT.

All SQL remains proposal-only. Run tests only in an explicitly approved existing non-production branch/environment; the pgTAP fixture uses synthetic rows inside a transaction and rolls back. Never create a duplicate database for testing or run these files in production without explicit approval.
