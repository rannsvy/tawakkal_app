class AppConfig {
  static const String appName = 'Tawakkal';

  static const String equranBaseUrl = 'https://equran.id/api/v2';
  static const String defaultLanguage = 'id';
  static const String fallbackReciterKey = '05';

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );
  static bool get hasSupabaseCredentials =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static const String aiQuizEndpoint = String.fromEnvironment(
    'AI_QUIZ_ENDPOINT',
    defaultValue: '',
  );
  static const String openAiModel = String.fromEnvironment(
    'OPENAI_MODEL',
    defaultValue: 'gpt-4.1-mini',
  );
}
