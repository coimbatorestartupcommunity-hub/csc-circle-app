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

  static bool get hasBackend =>
      supabaseUrl.startsWith('https://') && supabasePublishableKey.isNotEmpty;
}
