import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/storage/sqlite/app_database.dart';

class CloudSyncService {
  CloudSyncService({
    required AppDatabase database,
    required SupabaseClient? supabaseClient,
  }) : _database = database,
       _supabaseClient = supabaseClient;

  final AppDatabase _database;
  final SupabaseClient? _supabaseClient;

  Future<void> syncPendingQueue() async {
    if (_supabaseClient == null) {
      return;
    }

    final items = await _database.getPendingSyncItems(limit: 50);
    for (final item in items) {
      final id = item['id'] as int? ?? 0;
      final entityType = item['entity_type'] as String? ?? '';
      final operation = item['operation'] as String? ?? '';
      final retryCount = item['retry_count'] as int? ?? 0;
      final payload =
          jsonDecode(item['payload_json'] as String? ?? '{}')
              as Map<String, dynamic>;

      try {
        await _syncOne(
          entityType: entityType,
          operation: operation,
          payload: payload,
        );
        await _database.removeSyncItem(id);
      } catch (_) {
        await _database.postponeSyncItem(id: id, retryCount: retryCount + 1);
      }
    }
  }

  Future<void> _syncOne({
    required String entityType,
    required String operation,
    required Map<String, dynamic> payload,
  }) async {
    final userId = payload['user_id'] as String? ?? '';
    if (userId.isEmpty || userId == 'guest') {
      return;
    }

    if (entityType == 'bookmark') {
      if (operation == 'delete') {
        await _supabaseClient!
            .from('bookmarks_cloud')
            .delete()
            .eq('user_id', userId)
            .eq('surah_id', payload['surah_id'])
            .eq('ayah_number', payload['ayah_number']);
      } else {
        await _supabaseClient!.from('bookmarks_cloud').upsert(<String, dynamic>{
          'user_id': userId,
          'surah_id': payload['surah_id'],
          'ayah_number': payload['ayah_number'],
        });
      }
      return;
    }

    if (entityType == 'note') {
      await _supabaseClient!.from('notes_cloud').upsert(<String, dynamic>{
        'user_id': userId,
        'surah_id': payload['surah_id'],
        'ayah_number': payload['ayah_number'],
        'note_text': payload['note_text'],
        'updated_at': DateTime.now().toIso8601String(),
        'is_deleted': false,
      });
      return;
    }

    if (entityType == 'learning_progress') {
      await _supabaseClient!.from('user_progress').upsert(<String, dynamic>{
        'user_id': userId,
        'surah_id': payload['surah_id'],
        'difficulty': payload['difficulty'],
        'stage_status': payload['score'] == payload['max_score']
            ? 'completed'
            : 'in_progress',
        'score': payload['score'],
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
  }
}
