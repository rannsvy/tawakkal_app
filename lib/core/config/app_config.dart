import 'package:flutter/services.dart';

class AppConfig {
  static const String appName = 'Tawakkal';
  static const String oauthCallbackScheme = 'tawakkalapp';
  static const String oauthCallbackHost = 'login-callback';
  static const String oauthCallbackUrl =
      '$oauthCallbackScheme://$oauthCallbackHost';

  static const String equranBaseUrl = 'https://equran.id/api/v2';
  static const String defaultLanguage = 'id';
  static const String fallbackReciterKey = '05';

  static const String _supabaseUrlDefine = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  static const String _supabaseAnonKeyDefine = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );
  static const String _chatAiEndpointDefine = String.fromEnvironment(
    'CHAT_AI_TAWAKKAL_ENDPOINT',
    defaultValue: '',
  );
  static const String _legacyChatAiEndpointDefine = String.fromEnvironment(
    'AI_CHAT_ENDPOINT',
    defaultValue: '',
  );
  static const String _aiQuizEndpointDefine = String.fromEnvironment(
    'AI_QUIZ_ENDPOINT',
    defaultValue: '',
  );
  static const String _aiProviderDefine = String.fromEnvironment(
    'AI_PROVIDER',
    defaultValue: 'xiaomi',
  );
  static const String _aiModelDefine = String.fromEnvironment(
    'AI_MODEL',
    defaultValue: 'mimo-v2.5-pro',
  );
  static const bool _aiQuizAlwaysFreshDefine = bool.fromEnvironment(
    'AI_QUIZ_ALWAYS_FRESH',
    defaultValue: true,
  );
  static const int _aiQuizRecentSignatureLimitDefine = int.fromEnvironment(
    'AI_QUIZ_RECENT_SIGNATURE_LIMIT',
    defaultValue: 30,
  );

  static const String _runtimeEnvAssetPath = 'assets/env/runtime.env';
  static bool _isInitialized = false;
  static Map<String, String> _runtimeEnv = const <String, String>{};

  static Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }
    _runtimeEnv = await _loadRuntimeEnv();
    _isInitialized = true;
  }

  static Future<Map<String, String>> _loadRuntimeEnv() async {
    try {
      final envText = await rootBundle.loadString(_runtimeEnvAssetPath);
      final result = <String, String>{};
      for (final rawLine in envText.split(RegExp(r'\r?\n'))) {
        final line = rawLine.trim();
        if (line.isEmpty || line.startsWith('#')) {
          continue;
        }
        final separatorIndex = line.indexOf('=');
        if (separatorIndex <= 0) {
          continue;
        }
        final key = line.substring(0, separatorIndex).trim();
        var value = line.substring(separatorIndex + 1).trim();
        if (value.length >= 2 &&
            ((value.startsWith('"') && value.endsWith('"')) ||
                (value.startsWith("'") && value.endsWith("'")))) {
          value = value.substring(1, value.length - 1);
        }
        if (key.isNotEmpty && value.isNotEmpty) {
          result[key] = value;
        }
      }
      return result;
    } catch (_) {
      return const <String, String>{};
    }
  }

  static String _resolveString(
    String key,
    String defineValue, {
    String defaultValue = '',
  }) {
    if (defineValue.isNotEmpty) {
      return defineValue;
    }
    final runtimeValue = _runtimeEnv[key];
    if (runtimeValue != null && runtimeValue.isNotEmpty) {
      return runtimeValue;
    }
    return defaultValue;
  }

  static bool _resolveBool(String key, bool defineValue) {
    final raw = _runtimeEnv[key];
    if (raw == null || raw.isEmpty) {
      return defineValue;
    }
    final normalized = raw.trim().toLowerCase();
    return normalized == '1' ||
        normalized == 'true' ||
        normalized == 'yes' ||
        normalized == 'on';
  }

  static int _resolveInt(String key, int defineValue) {
    final raw = _runtimeEnv[key];
    if (raw == null || raw.isEmpty) {
      return defineValue;
    }
    return int.tryParse(raw.trim()) ?? defineValue;
  }

  static String get supabaseUrl =>
      _resolveString('SUPABASE_URL', _supabaseUrlDefine);
  static String get supabaseAnonKey =>
      _resolveString('SUPABASE_ANON_KEY', _supabaseAnonKeyDefine);
  static bool get hasSupabaseCredentials =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static String get aiChatEndpoint {
    final primary = _resolveString(
      'CHAT_AI_TAWAKKAL_ENDPOINT',
      _chatAiEndpointDefine,
    );
    if (primary.isNotEmpty) {
      return primary;
    }
    return _resolveString('AI_CHAT_ENDPOINT', _legacyChatAiEndpointDefine);
  }

  static String get aiQuizEndpoint =>
      _resolveString('AI_QUIZ_ENDPOINT', _aiQuizEndpointDefine);
  static String get aiProvider =>
      _resolveString('AI_PROVIDER', _aiProviderDefine, defaultValue: 'xiaomi');
  static String get aiModel =>
      _resolveString('AI_MODEL', _aiModelDefine, defaultValue: 'mimo-v2.5-pro');
  static bool get aiQuizAlwaysFresh =>
      _resolveBool('AI_QUIZ_ALWAYS_FRESH', _aiQuizAlwaysFreshDefine);
  static int get aiQuizRecentSignatureLimit => _resolveInt(
    'AI_QUIZ_RECENT_SIGNATURE_LIMIT',
    _aiQuizRecentSignatureLimitDefine,
  );

  @Deprecated('Use aiModel instead.')
  static String get openAiModel => aiModel;
}
