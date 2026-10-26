-- REVIEW PROPOSAL ONLY — pgTAP fixture test; never run against production.
-- Run only in an explicitly approved existing non-production test branch or
-- isolated environment after applying 20261026170000_public_resources_projection.sql.
-- Do not create a duplicate database for this test and never run it in production.
begin;
select plan(6);

insert into public.resources (
  slug, title, category, resource_type, summary, description, tags,
  document_path, document_filename, document_mime, document_size,
  publication_consent, attribution, publication_status, archived_at
) values
  (
    'phase3_projection_test_published', 'Published fixture',
    'Fixture', 'document', 'Fixture summary',
    'Fixture description long enough to pass publication validation.', '[]'::jsonb,
    'resource-docs/00000000-0000-0000-0000-000000000001.pdf',
    'fixture.pdf', 'application/pdf', 128, true, 'CSC test fixture',
    'published', null
  ),
  (
    'phase3_projection_test_draft', 'Draft fixture',
    'Fixture', 'article', 'Draft summary', 'Draft description', '[]'::jsonb,
    null, null, null, null, false, null, 'draft', null
  ),
  (
    'phase3_projection_test_archived', 'Archived fixture',
    'Fixture', 'article', 'Archived summary', 'Archived description', '[]'::jsonb,
    null, null, null, null, false, null, 'archived', now()
  );

select ok(
  has_table_privilege('anon', 'public.csc_public_resources', 'SELECT'),
  'anon can read the curated public projection'
);
select ok(
  not has_table_privilege('anon', 'public.resources', 'SELECT'),
  'anon cannot read the base table'
);
select ok(
  not has_column_privilege('anon', 'public.resources', 'document_path', 'SELECT'),
  'anon cannot read private document paths'
);
select ok(
  not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'csc_public_resources'
      and column_name in (
        'document_path', 'document_filename', 'document_mime', 'document_size',
        'cover_image_path', 'created_by', 'updated_by', 'created_at',
        'updated_at', 'archived_at', 'publication_consent'
      )
  ),
  'the projection omits storage paths and internal metadata'
);

set local role anon;
select results_eq(
  $$
    select slug, has_document, has_cover_image
    from public.csc_public_resources
    where slug like 'phase3_projection_test_%'
    order by slug
  $$,
  $$ values ('phase3_projection_test_published', true, false) $$,
  'anon sees a published fixture and no draft or archived fixtures'
);
select throws_ok(
  $$ select document_path from public.resources limit 1 $$,
  '42501',
  'permission denied for table resources',
  'anon cannot select the private base-table path'
);
reset role;

select * from finish();
rollback;
