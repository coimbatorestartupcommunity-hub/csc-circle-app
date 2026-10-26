-- REVIEW PROPOSAL ONLY — DO NOT APPLY TO PRODUCTION.
-- Coordinate this with a website release that reads csc_public_resources and
-- resolves private media/document paths only in server-only routes.
--
-- Purpose: replace anonymous base-table column access with an explicit,
-- published-only projection. The view is owner-rights by design; its WHERE
-- clause is the complete public row-authorization boundary and is covered by
-- the companion transactional fixture test. Do not remove that predicate.
begin;

create or replace view public.csc_public_resources
with (security_barrier = true)
as
select
  r.id,
  r.slug,
  r.title,
  r.category,
  r.resource_type,
  r.summary,
  r.description,
  r.tags,
  r.audience,
  (r.cover_image_path is not null) as has_cover_image,
  (r.document_path is not null) as has_document,
  r.external_url,
  r.source_name,
  r.source_organization,
  r.source_url,
  r.author,
  r.license,
  r.attribution,
  r.seo_title,
  r.meta_description,
  r.publication_status,
  r.published_at
from public.resources as r
where r.publication_status = 'published'::public.publication_status
  and r.archived_at is null;

revoke all on public.csc_public_resources from public, anon, authenticated;
grant select on public.csc_public_resources to anon, authenticated;

-- The existing website currently selects this explicit list through its anon
-- client. Before applying this revoke, migrate its public resource reads to the
-- view and move document/image path lookup to server-only admin routes.
revoke all on public.resources from public, anon;
revoke select (
  id, slug, title, category, resource_type, summary, description, tags,
  audience, cover_image_path, document_path, document_filename,
  document_mime, external_url, source_name, source_organization, source_url,
  author, license, attribution, seo_title, meta_description,
  publication_status, published_at, updated_at
) on public.resources from public, anon;

commit;
