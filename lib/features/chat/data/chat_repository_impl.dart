import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/entities/chat_context.dart';
import '../domain/entities/chat_message.dart';
import '../domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl({
    required Dio httpClient,
    required SupabaseClient? supabaseClient,
  }) : _httpClient = httpClient,
       _supabaseClient = supabaseClient;

  final Dio _httpClient;
  final SupabaseClient? _supabaseClient;

  @override
  Future<String> sendMessage({
    required String message,
    required List<ChatMessage> conversationHistory,
    ChatContext? surahContext,
  }) async {
    final endpoint = AppConfig.aiChatEndpoint.trim();
    if (endpoint.isEmpty) {
      throw const AppException(
        'AI chat endpoint is not configured. Set CHAT_AI_TAWAKKAL_ENDPOINT or AI_CHAT_ENDPOINT.',
      );
    }

    final trimmedHistory = conversationHistory.length <= 10
        ? conversationHistory
        : conversationHistory.sublist(conversationHistory.length - 10);

    final requestBody = <String, dynamic>{
      'message': message,
      'conversation_history': trimmedHistory
          .map((entry) => entry.toApiJson())
          .toList(growable: false),
      if (surahContext != null) 'surah_context': surahContext.toJson(),
      'provider': AppConfig.aiProvider,
      'model': AppConfig.aiModel,
    };

    final accessToken = _supabaseClient?.auth.currentSession?.accessToken;
    final useAnonFirst = _useAnonAuthFirstForEndpoint(endpoint);
    final headers = _buildRequestHeaders(useSessionToken: !useAnonFirst);

    try {
      return await _sendChatRequest(
        endpoint: endpoint,
        requestBody: requestBody,
        headers: headers,
      );
    } on DioException catch (error) {
      DioException finalError = error;

      // For chat-ai-tawakkal we use anon-first to avoid known user-JWT 401 noise.
      // For other endpoints, keep existing user-first retry strategy.
      final shouldRetryAuthFallback =
          !useAnonFirst &&
          error.response?.statusCode == 401 &&
          accessToken != null &&
          accessToken.isNotEmpty &&
          AppConfig.supabaseAnonKey.isNotEmpty;
      if (shouldRetryAuthFallback) {
        try {
          // Refresh token first, because some 401s are stale session JWTs.
          await _supabaseClient?.auth.refreshSession();
          final refreshedUserHeaders = _buildRequestHeaders(
            useSessionToken: true,
          );
          return await _sendChatRequest(
            endpoint: endpoint,
            requestBody: requestBody,
            headers: refreshedUserHeaders,
          );
        } on DioException catch (refreshError) {
          // If a fresh user JWT still fails, continue with anon fallback.
          finalError = refreshError;
        } catch (_) {
          // Ignore refresh failures and continue with anon fallback.
        }

        try {
          final fallbackHeaders = _buildRequestHeaders(useSessionToken: false);
          return await _sendChatRequest(
            endpoint: endpoint,
            requestBody: requestBody,
            headers: fallbackHeaders,
          );
        } on DioException catch (retryError) {
          finalError = retryError;
        }
      }

      debugPrint(
        '[ChatRepository] AI chat request failed '
        'status=${finalError.response?.statusCode} body=${_compactLog(finalError.response?.data)}',
      );

      final responseMap = _coerceToMap(finalError.response?.data);
      final responseError = responseMap?['error'];
      if (responseError is String && responseError.trim().isNotEmpty) {
        throw AppException(responseError.trim());
      }

      throw const AppException(
        'Unable to reach Tawakkal AI right now. Please try again.',
      );
    } on AppException {
      rethrow;
    } catch (error, stackTrace) {
      debugPrint('[ChatRepository] Unexpected error:\n$error\n$stackTrace');
      throw const AppException(
        'Unexpected AI chat error occurred. Please try again.',
      );
    }
  }

  Future<String> _sendChatRequest({
    required String endpoint,
    required Map<String, dynamic> requestBody,
    required Map<String, String> headers,
  }) async {
    final response = await _httpClient.postUri(
      Uri.parse(endpoint),
      data: requestBody,
      options: Options(
        headers: headers,
        connectTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 45),
      ),
    );

    final responseMap = _coerceToMap(response.data);
    final reply = responseMap?['reply'];
    if (reply is String && reply.trim().isNotEmpty) {
      return reply.trim();
    }

    final errorMessage = responseMap?['error'];
    if (errorMessage is String && errorMessage.trim().isNotEmpty) {
      throw AppException(errorMessage.trim());
    }

    throw const AppException('Invalid response from AI chat endpoint.');
  }

  Map<String, String> _buildRequestHeaders({required bool useSessionToken}) {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (AppConfig.supabaseAnonKey.isNotEmpty) {
      headers['apikey'] = AppConfig.supabaseAnonKey;
    }

    final accessToken = _supabaseClient?.auth.currentSession?.accessToken;
    if (useSessionToken && accessToken != null && accessToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $accessToken';
    } else if (AppConfig.supabaseAnonKey.isNotEmpty) {
      headers['Authorization'] = 'Bearer ${AppConfig.supabaseAnonKey}';
    }
    return headers;
  }

  bool _useAnonAuthFirstForEndpoint(String endpoint) {
    try {
      final uri = Uri.parse(endpoint);
      final segments = uri.pathSegments.where((part) => part.isNotEmpty);
      if (segments.isEmpty) {
        return false;
      }
      return segments.last.toLowerCase() == 'chat-ai-tawakkal';
    } catch (_) {
      return false;
    }
  }

  Map<String, dynamic>? _coerceToMap(Object? source) {
    if (source is Map<String, dynamic>) {
      return source;
    }
    if (source is Map) {
      return source.map((key, value) => MapEntry(key.toString(), value));
    }
    if (source is String) {
      try {
        final decoded = jsonDecode(source);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        if (decoded is Map) {
          return decoded.map((key, value) => MapEntry(key.toString(), value));
        }
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  String _compactLog(Object? source) {
    if (source == null) {
      return 'null';
    }

    String value;
    if (source is String) {
      value = source;
    } else {
      try {
        value = jsonEncode(source);
      } catch (_) {
        value = source.toString();
      }
    }

    if (value.length <= 900) {
      return value;
    }
    return '${value.substring(0, 900)}...';
  }
}
