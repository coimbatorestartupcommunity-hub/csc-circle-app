import 'package:csc_circle_app/core/security/secure_session_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test(
    'session storage persists and removes the Supabase session key',
    () async {
      final secureStore = _MemorySecureStore();
      final storage = SecureSessionStorage(storage: secureStore);

      await storage.initialize();
      expect(await storage.hasAccessToken(), isFalse);
      await storage.persistSession('fixture-session-json');

      expect(await storage.hasAccessToken(), isTrue);
      expect(await storage.accessToken(), 'fixture-session-json');
      expect(secureStore.values, contains(supabasePersistSessionKey));

      await storage.removePersistedSession();
      expect(await storage.hasAccessToken(), isFalse);
    },
  );

  test('PKCE verifier uses a separate secure-storage key namespace', () async {
    final secureStore = _MemorySecureStore();
    final sessions = SecureSessionStorage(storage: secureStore);
    final pkce = SecurePkceStorage(storage: secureStore);

    await sessions.persistSession('fixture-session-json');
    await pkce.setItem(key: 'auth-code-verifier', value: 'fixture-verifier');

    expect(
      secureStore.values.keys,
      containsAll([
        supabasePersistSessionKey,
        'CSC_SUPABASE_PKCE:auth-code-verifier',
      ]),
    );
    expect(await pkce.getItem(key: 'auth-code-verifier'), 'fixture-verifier');

    await pkce.removeItem(key: 'auth-code-verifier');
    expect(await pkce.getItem(key: 'auth-code-verifier'), isNull);
    expect(await sessions.accessToken(), 'fixture-session-json');
  });
}

class _MemorySecureStore extends FlutterSecureStorage {
  final Map<String, String> values = {};

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => values[key];

  @override
  Future<bool> containsKey({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => values.containsKey(key);

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    values.remove(key);
  }
}
