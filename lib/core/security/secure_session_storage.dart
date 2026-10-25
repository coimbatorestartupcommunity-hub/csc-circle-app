import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Stores the serialized Supabase session in platform secure storage.
///
/// iOS/macOS use Keychain, Android uses the platform keystore, and Windows
/// uses the plugin's Windows secure storage implementation. This replaces the
/// SDK's default shared-preferences session storage.
class SecureSessionStorage extends LocalStorage {
  SecureSessionStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<void> initialize() async {}

  @override
  Future<String?> accessToken() =>
      _storage.read(key: supabasePersistSessionKey);

  @override
  Future<bool> hasAccessToken() =>
      _storage.containsKey(key: supabasePersistSessionKey);

  @override
  Future<void> persistSession(String persistSessionString) => _storage.write(
    key: supabasePersistSessionKey,
    value: persistSessionString,
  );

  @override
  Future<void> removePersistedSession() =>
      _storage.delete(key: supabasePersistSessionKey);
}
