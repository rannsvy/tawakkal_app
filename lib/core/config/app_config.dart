class AppConfig {
  static const String appName = 'Tawakkal';
  static const String oauthCallbackScheme = 'tawakkalapp';
  static const String oauthCallbackHost = 'login-callback';
  static const String oauthCallbackUrl =
      '$oauthCallbackScheme://$oauthCallbackHost';

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

  static String get aiChatEndpoint {
    const primary = String.fromEnvironment(
      'CHAT_AI_TAWAKKAL_ENDPOINT',
      defaultValue: '',
    );
    if (primary.isNotEmpty) {
      return primary;
    }
    return const String.fromEnvironment('AI_CHAT_ENDPOINT', defaultValue: '');
  }

  static const String aiQuizEndpoint = String.fromEnvironment(
    'AI_QUIZ_ENDPOINT',
    defaultValue: '',
  );
  static const String aiProvider = String.fromEnvironment(
    'AI_PROVIDER',
    defaultValue: 'nvidia',
  );
  static const String aiModel = String.fromEnvironment(
    'AI_MODEL',
    defaultValue: 'z-ai/glm4.7',
  );
  static const bool aiQuizAlwaysFresh = bool.fromEnvironment(
    'AI_QUIZ_ALWAYS_FRESH',
    defaultValue: true,
  );
  static const int aiQuizRecentSignatureLimit = int.fromEnvironment(
    'AI_QUIZ_RECENT_SIGNATURE_LIMIT',
    defaultValue: 30,
  );

  @Deprecated('Use aiModel instead.')
  static const String openAiModel = aiModel;
}
