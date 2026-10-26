-- REVIEW PROPOSAL ONLY — do not run without approval.
-- Rollback for 20261026170002_revoke_anon_resources_base_access.sql.
-- Restore the exact pre-revocation website column list before reverting any
-- web/mobile clients to public.resources. Do not grant table-wide SELECT.
begin;

grant select (
  id, slug, title, category, resource_type, summary, description, tags,
  audience, cover_image_path, document_path, document_filename,
  document_mime, external_url, source_name, source_organization, source_url,
  author, license, attribution, seo_title, meta_description,
  publication_status, published_at, updated_at
) on public.resources to anon;

commit;
