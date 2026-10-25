import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/csc_circle_app.dart';
import 'core/config/app_config.dart';
import 'core/security/secure_session_storage.dart';
import 'core/backend/public_content.dart';
import 'features/auth/auth_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (AppConfig.hasBackend) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabasePublishableKey,
      authOptions: FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        localStorage: SecureSessionStorage(),
      ),
    );
  }

  final client = AppConfig.hasBackend ? Supabase.instance.client : null;
  runApp(
    CscCircleApp(
      backendConfigured: client != null,
      authRepository: client == null
          ? null
          : SupabaseAuthRepository(
              client: client,
              emailRedirectUri: AppConfig.approvedAuthRedirectUri,
            ),
      publicContentRepository: client == null
          ? null
          : SupabasePublicContentRepository(client),
    ),
  );
}
