class AppConfig {
  const AppConfig._();

  static const supabaseUrl = String.fromEnvironment('CSC_SUPABASE_URL');
  static const supabasePublishableKey = String.fromEnvironment(
    'CSC_SUPABASE_PUBLISHABLE_KEY',
  );
  static const siteUrl = String.fromEnvironment(
    'CSC_SITE_URL',
    defaultValue: 'https://csc.logicintelligencetechnologies.in',
  );
  static const authRedirectUriText = String.fromEnvironment(
    'CSC_AUTH_REDIRECT_URI',
    defaultValue: 'cscircle://auth-callback',
  );
  static const authRedirectApproved = bool.fromEnvironment(
    'CSC_AUTH_REDIRECT_APPROVED',
    defaultValue: false,
  );

  static Uri? get approvedAuthRedirectUri {
    if (!authRedirectApproved || !hasBackend) return null;
    final uri = Uri.tryParse(authRedirectUriText);
    if (uri == null ||
        uri.scheme != 'cscircle' ||
        uri.host != 'auth-callback' ||
        uri.hasQuery ||
        uri.hasFragment) {
      return null;
    }
    return uri;
  }

  static bool get hasBackend =>
      supabaseUrl.startsWith('https://') && supabasePublishableKey.isNotEmpty;
}
