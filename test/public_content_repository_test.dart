import 'dart:convert';

import 'package:csc_circle_app/core/backend/public_content.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('events request explicit published fields and an offset page', () async {
    final requests = <http.Request>[];
    final client = _fixtureClient(requests);
    final repository = SupabasePublicContentRepository(client);

    final page = await repository.events(offset: 20, limit: 10);

    expect(page.single.title, 'Founder meetup');
    final request = requests.single;
    expect(request.url.path, '/rest/v1/events');
    expect(request.url.queryParameters['select'], contains('starts_at'));
    expect(request.url.queryParameters['status'], 'eq.published');
    expect(request.url.queryParameters['offset'], '20');
    expect(request.url.queryParameters['limit'], '10');
    expect(request.url.queryParameters['order'], 'starts_at.asc.nullslast');
    await client.dispose();
  });

  test(
    'updates and resources select published rows with limited fields',
    () async {
      final requests = <http.Request>[];
      final client = _fixtureClient(requests);
      final repository = SupabasePublicContentRepository(client);

      final updates = await repository.updates(offset: 0, limit: 15);
      final resources = await repository.resources(offset: 0, limit: 15);

      expect(updates.single.slug, 'community-launch');
      expect(resources.single.tags, ['founders', 'learning']);
      expect(
        requests[0].url.queryParameters['publication_status'],
        'eq.published',
      );
      expect(
        requests[0].url.queryParameters['order'],
        'featured.desc.nullslast,published_at.desc.nullslast',
      );
      expect(
        requests[1].url.queryParameters['select'],
        isNot(contains('document_path')),
      );
      expect(
        requests[1].url.queryParameters['select'],
        isNot(contains('thumbnail_path')),
      );
      expect(
        requests[1].url.queryParameters['select'],
        'id,slug,title,category,resource_type,summary,tags,external_url,published_at',
      );
      expect(
        requests[1].url.queryParameters['publication_status'],
        'eq.published',
      );
      await client.dispose();
    },
  );

  test(
    'opportunities use published and India-date eligibility predicates',
    () async {
      final requests = <http.Request>[];
      final client = _fixtureClient(requests);
      final repository = SupabasePublicContentRepository(
        client,
        now: () => DateTime.utc(2026, 10, 26, 19),
      );

      final page = await repository.opportunities(offset: 0, limit: 8);

      expect(page.single.organization, 'CSC');
      final request = requests.single;
      expect(request.url.path, '/rest/v1/opportunities');
      expect(request.url.queryParameters['publication_status'], 'eq.published');
      expect(
        request.url.queryParameters['or'],
        '(deadline.is.null,deadline.gte.2026-10-27)',
      );
      expect(
        request.url.queryParameters['order'],
        'deadline.asc.nullslast,published_at.desc.nullslast',
      );
      await client.dispose();
    },
  );

  test('invalid fixture response maps to a safe typed failure', () async {
    final client = SupabaseClient(
      'https://fixture.invalid',
      'sb_publishable_fixture',
      httpClient: MockClient(
        (request) async =>
            http.Response('[{"id":"missing"}]', 200, request: request),
      ),
    );
    final repository = SupabasePublicContentRepository(client);

    await expectLater(
      repository.events(offset: 0),
      throwsA(
        isA<PublicContentException>().having(
          (error) => error.kind,
          'kind',
          ContentFailureKind.invalidResponse,
        ),
      ),
    );
    await client.dispose();
  });
}

SupabaseClient _fixtureClient(List<http.Request> requests) => SupabaseClient(
  'https://fixture.invalid',
  'sb_publishable_fixture',
  httpClient: MockClient((request) async {
    requests.add(request);
    final table = request.url.path.split('/').last;
    final fixtures = <String, List<Map<String, Object?>>>{
      'events': [
        {
          'id': 'event-1',
          'title': 'Founder meetup',
          'category': 'Networking',
          'description': 'A fixture event.',
          'starts_at': '2026-11-02T10:00:00Z',
          'ends_at': '2026-11-02T12:00:00Z',
          'location': 'Coimbatore',
        },
      ],
      'community_updates': [
        {
          'id': 'update-1',
          'slug': 'community-launch',
          'title': 'Community launch',
          'category': 'Announcement',
          'summary': 'A fixture update.',
          'featured': true,
          'published_at': '2026-10-26T12:00:00Z',
        },
      ],
      'resources': [
        {
          'id': 'resource-1',
          'slug': 'founder-guide',
          'title': 'Founder guide',
          'category': 'Learning',
          'resource_type': 'guide',
          'summary': 'A fixture resource.',
          'tags': ['founders', 'learning'],
          'published_at': '2026-10-26T12:00:00Z',
        },
      ],
      'opportunities': [
        {
          'id': 'opportunity-1',
          'title': 'Startup clinic',
          'category': 'Program',
          'summary': 'A fixture opportunity.',
          'organization': 'CSC',
          'deadline': '2026-11-01',
        },
      ],
    };
    return http.Response(
      jsonEncode(fixtures[table] ?? const <Map<String, Object?>>[]),
      200,
      headers: const {'content-type': 'application/json'},
      request: request,
    );
  }),
);
