-- REVIEW PROPOSAL ONLY — DO NOT APPLY TO PRODUCTION WITHOUT CSC APPROVAL.
-- Apply only after the website and minimum-supported native app version both
-- read public resources through public.csc_public_resources and route all
-- private storage lookups through server-only code.
--
-- This revocation breaks older native clients that still query
-- public.resources directly. Keep the existing grants until CSC approves an
-- app-version sunset/minimum-version policy and confirms rollout completion.
begin;

revoke all on public.resources from public, anon;
revoke select (
  id, slug, title, category, resource_type, summary, description, tags,
  audience, cover_image_path, document_path, document_filename,
  document_mime, external_url, source_name, source_organization, source_url,
  author, license, attribution, seo_title, meta_description,
  publication_status, published_at, updated_at
) on public.resources from public, anon;

commit;
