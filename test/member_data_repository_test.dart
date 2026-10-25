import 'dart:convert';

import 'package:csc_circle_app/core/backend/member_data_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  const ownerId = 'safe-fixture-user-1';

  test('anonymous member reads fail before making any request', () async {
    final requests = <http.Request>[];
    final client = _client(requests, ownerId: ownerId);
    final repository = SupabaseMemberDataRepository(client);

    await expectLater(
      repository.myProfile(),
      throwsA(isA<MemberAccessException>()),
    );
    await expectLater(
      repository.myMembership(),
      throwsA(isA<MemberAccessException>()),
    );
    await expectLater(
      repository.myStartups(),
      throwsA(isA<MemberAccessException>()),
    );
    await expectLater(
      repository.myNotificationInbox(),
      throwsA(isA<MemberAccessException>()),
    );
    expect(requests, isEmpty);
    await client.dispose();
  });

  test('authenticated profile read is scoped to the session owner', () async {
    final requests = <http.Request>[];
    final client = _client(requests, ownerId: ownerId);
    await _signInFixture(client, ownerId);
    final repository = SupabaseMemberDataRepository(client);

    final profile = await repository.myProfile();

    expect(profile?.userId, ownerId);
    final request = requests.last;
    expect(request.url.path, '/rest/v1/profiles');
    expect(request.url.queryParameters['id'], 'eq.$ownerId');
    expect(request.headers['authorization'], startsWith('Bearer '));
    await client.dispose();
  });

  test(
    'notification inbox uses the caller-scoped RPC without target IDs',
    () async {
      final requests = <http.Request>[];
      final client = _client(requests, ownerId: ownerId);
      await _signInFixture(client, ownerId);
      final repository = SupabaseMemberDataRepository(client);

      final inbox = await repository.myNotificationInbox();

      expect(inbox.items, isEmpty);
      final request = requests.last;
      expect(request.url.path, '/rest/v1/rpc/csc_member_notification_inbox');
      expect(request.method, 'POST');
      expect(request.url.queryParameters, isEmpty);
      expect(request.headers['authorization'], startsWith('Bearer '));
      await client.dispose();
    },
  );
}

SupabaseClient _client(
  List<http.Request> requests, {
  required String ownerId,
}) => SupabaseClient(
  'https://fixture.invalid',
  'sb_publishable_fixture',
  httpClient: MockClient((request) async {
    requests.add(request);
    if (request.url.path == '/auth/v1/token') {
      return http.Response(
        jsonEncode(_sessionResponse(ownerId)),
        200,
        headers: const {'content-type': 'application/json'},
        request: request,
      );
    }
    if (request.url.path == '/rest/v1/profiles') {
      return http.Response(
        jsonEncode([
          {
            'id': ownerId,
            'display_name': 'Fixture member',
            'about_me': '',
            'profile_completion': 0,
          },
        ]),
        200,
        headers: const {'content-type': 'application/json'},
        request: request,
      );
    }
    if (request.url.path == '/rest/v1/rpc/csc_member_notification_inbox') {
      return http.Response(
        jsonEncode({'items': <Object>[], 'unreadCount': 0}),
        200,
        headers: const {'content-type': 'application/json'},
        request: request,
      );
    }
    return http.Response('[]', 200, request: request);
  }),
);

Future<void> _signInFixture(SupabaseClient client, String userId) async {
  await client.auth.signInWithPassword(
    email: 'fixture@example.invalid',
    password: 'fixture-only-password',
  );
  expect(client.auth.currentUser?.id, userId);
}

Map<String, Object?> _sessionResponse(String userId) {
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  final payload = base64Url
      .encode(
        utf8.encode(
          jsonEncode({
            'sub': userId,
            'role': 'authenticated',
            'aud': 'authenticated',
            'iat': now,
            'exp': now + 3600,
          }),
        ),
      )
      .replaceAll('=', '');
  return {
    'access_token': 'fixture.$payload.signature',
    'token_type': 'bearer',
    'expires_in': 3600,
    'refresh_token': 'fixture-refresh-token',
    'user': {
      'id': userId,
      'aud': 'authenticated',
      'role': 'authenticated',
      'email': 'fixture@example.invalid',
      'app_metadata': <String, Object?>{},
      'user_metadata': <String, Object?>{},
      'created_at': DateTime.now().toUtc().toIso8601String(),
    },
  };
}
