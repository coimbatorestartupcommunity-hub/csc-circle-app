# Resources public-access proposal

**Status:** Prepared for security review only. Neither SQL file has been applied or run. Do not copy these files into an executable migration directory until the project owner approves the public access contract.

## Current live access contract

Read-only catalog and Data API inspection on 2026-10-26 confirmed:

- RLS is enabled (not forced) on `public.resources`.
- The permissive `resources_public_read` SELECT policy applies to role `public` and filters `publication_status = 'published'`. The enum has `draft`, `pending`, `published`, and `archived` values; the public policy excludes the first, second, and fourth. An `archived_at IS NULL` condition is not present in the policy.
- `anon` has **no table-level SELECT**, but it does have a column-level SELECT grant for the website’s existing explicit public projection. Those grants include `document_path`, `document_filename`, and `document_mime`, as well as `cover_image_path`, `external_url`, `updated_at`, and public content fields. It does not have `thumbnail_path`, `document_size`, `publication_consent`, `archived_at`, `created_by`, `updated_by`, or `created_at`.
- `authenticated` has table-level SELECT; its access remains governed by the existing RLS policies.
- There are no existing views dependent on `public.resources` in the checked public schema.
- A no-session REST request using the native field list failed with `42501` because Flutter selected `thumbnail_path`. Removing this unused field from the native projection returned HTTP 200 with zero published rows. The website’s exact `RESOURCE_PUBLIC_FIELDS` query also returned HTTP 200 with zero rows. `select=*` returned HTTP 401 / `42501`, as expected without table-level access. A `document_path`-only query returned HTTP 200 (zero rows), confirming that path column is currently granted to anon even though the path itself was not returned in this check.

## Website dependency comparison

`src/lib/services/cms-public.ts` uses an anonymous Supabase client for public resources. Its actual `RESOURCE_PUBLIC_FIELDS` constant is an explicit projection, not `select=*`; it selects the existing anon-granted columns and filters `publication_status='published'`. The public listing/detail pages use `cover_image_path`, `document_path`, and `document_filename` server-side to choose image/download actions. `/api/cms/image` validates a published resource by filtering on `cover_image_path`; `/api/resources/[slug]/download` uses the anon public-read helper to obtain `document_path`, then a server-only admin client to issue a short-lived storage URL. Admin CMS reads use `createAdminClient()` and `select('*')`; they are service-role/server-side and do not depend on anon column grants.

The user-supplied column grant would **not** satisfy the current website projection: it omits fields used by the public site, including `description`, `audience`, `cover_image_path`, document metadata, attribution/source/SEO fields, `publication_status`, and `updated_at`. The current table-wide grant would make `select=*` possible and expose extra internal columns. The Flutter client does not render `thumbnail_path`, so granting that column to make the old native query work is unnecessary; the client now drops it.

The proposed future projection removes storage paths and audit/consent metadata from direct anonymous base-table access. Applying it requires a coordinated website change first: read a curated `csc_public_resources` view, use `has_cover_image` / `has_document` booleans for public rendering, resolve image paths by resource slug only inside the server route, and read `document_path`/`document_filename` only through a server-only admin query after confirming the resource is still published. Then the migration can revoke all anon base-table column grants and leave only view SELECT. The view explicitly constrains both `publication_status='published'` and `archived_at IS NULL`; its owner-rights behavior intentionally does not rely on table RLS. Review this narrow view boundary carefully before approval.

## Files and test gate

- [`20261026170000_public_resources_projection.sql`](20261026170000_public_resources_projection.sql): proposed projection and revocation migration.
- [`20261026170001_public_resources_projection.test.sql`](20261026170001_public_resources_projection.test.sql): transactional pgTAP fixture covering public published visibility, draft/archive exclusion, base-table denial, and storage/internal-field omission.

Run the fixture only in an explicitly approved existing non-production test branch/environment after the website has moved to the view. It inserts synthetic rows inside a transaction and rolls back. Do not create a duplicate database for this test or run it against production. No test has been run against production. The current native app fix needs no permission change and continues to use the existing published-only RLS policy.
