import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.dispose);
  return db;
});

class AppDatabase {
  AppDatabase();

  static const _dbName = 'tawakkal.db';
  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _open();
    return _database!;
  }

  Future<Database> _open() async {
    final directory = await getApplicationDocumentsDirectory();
    final dbPath = p.join(directory.path, _dbName);
    return openDatabase(
      dbPath,
      version: 3,
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createQuizQuestionHistoryTables(db);
        }
        if (oldVersion < 3) {
          await _createWorshipFeatureTables(db);
        }
      },
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE surahs (
        surah_id INTEGER PRIMARY KEY,
        name_ar TEXT NOT NULL,
        name_latin TEXT NOT NULL,
        ayah_count INTEGER NOT NULL,
        revelation_place TEXT NOT NULL,
        meaning TEXT,
        description_id TEXT,
        audio_full_json TEXT,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ayahs (
        surah_id INTEGER NOT NULL,
        ayah_number INTEGER NOT NULL,
        text_ar TEXT NOT NULL,
        text_latin TEXT NOT NULL,
        text_id TEXT NOT NULL,
        text_en TEXT,
        audio_urls_json TEXT,
        PRIMARY KEY (surah_id, ayah_number)
      )
    ''');

    await db.execute('''
      CREATE TABLE tafsir_id (
        surah_id INTEGER NOT NULL,
        ayah_number INTEGER NOT NULL,
        tafsir_text TEXT NOT NULL,
        source TEXT NOT NULL,
        PRIMARY KEY (surah_id, ayah_number, source)
      )
    ''');

    await db.execute('''
      CREATE TABLE bookmarks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_local_id TEXT NOT NULL,
        surah_id INTEGER NOT NULL,
        ayah_number INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        synced_at TEXT,
        UNIQUE (user_local_id, surah_id, ayah_number)
      )
    ''');

    await db.execute('''
      CREATE TABLE notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_local_id TEXT NOT NULL,
        surah_id INTEGER NOT NULL,
        ayah_number INTEGER NOT NULL,
        note_text TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        synced_at TEXT,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        UNIQUE (user_local_id, surah_id, ayah_number)
      )
    ''');

    await db.execute('''
      CREATE TABLE downloaded_audio (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        reciter_id TEXT NOT NULL,
        surah_id INTEGER NOT NULL,
        file_path TEXT NOT NULL,
        checksum TEXT NOT NULL,
        size_bytes INTEGER NOT NULL,
        downloaded_at TEXT NOT NULL,
        UNIQUE (reciter_id, surah_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE quiz_cache (
        quiz_id TEXT PRIMARY KEY,
        surah_id INTEGER NOT NULL,
        difficulty TEXT NOT NULL,
        language TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        source_version INTEGER NOT NULL DEFAULT 1,
        expires_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE learning_progress_local (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_local_id TEXT NOT NULL,
        surah_id INTEGER NOT NULL,
        difficulty TEXT NOT NULL,
        current_stage TEXT NOT NULL,
        xp_earned INTEGER NOT NULL DEFAULT 0,
        last_activity_at TEXT NOT NULL,
        sync_state TEXT NOT NULL DEFAULT 'pending',
        UNIQUE (user_local_id, surah_id, difficulty)
      )
    ''');

    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        operation TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        retry_count INTEGER NOT NULL DEFAULT 0,
        next_retry_at TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE profile_progress (
        user_local_id TEXT PRIMARY KEY,
        xp_total INTEGER NOT NULL DEFAULT 0,
        current_streak INTEGER NOT NULL DEFAULT 0,
        longest_streak INTEGER NOT NULL DEFAULT 0,
        last_active_date TEXT
      )
    ''');

    await _createQuizQuestionHistoryTables(db);
    await _createWorshipFeatureTables(db);
  }

  Future<void> _createQuizQuestionHistoryTables(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS quiz_question_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_local_id TEXT NOT NULL,
        surah_id INTEGER NOT NULL,
        difficulty TEXT NOT NULL,
        language TEXT NOT NULL,
        question_signature TEXT NOT NULL,
        ayah_ref_primary TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_quiz_question_history_user_created
      ON quiz_question_history(user_local_id, created_at DESC)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_quiz_question_history_scope
      ON quiz_question_history(user_local_id, surah_id, difficulty, language, created_at DESC)
    ''');
  }

  Future<void> _createWorshipFeatureTables(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS daily_verse_cache (
        date_key TEXT PRIMARY KEY,
        surah_id INTEGER NOT NULL,
        ayah_number INTEGER NOT NULL,
        text_ar TEXT NOT NULL,
        text_latin TEXT NOT NULL,
        text_id TEXT NOT NULL,
        source TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS worship_location (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        mode TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        provinsi TEXT,
        kabkota TEXT,
        label TEXT,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS prayer_schedule_cache (
        location_key TEXT NOT NULL,
        date_key TEXT NOT NULL,
        imsak TEXT NOT NULL,
        subuh TEXT NOT NULL,
        terbit TEXT NOT NULL,
        dhuha TEXT NOT NULL,
        dzuhur TEXT NOT NULL,
        ashar TEXT NOT NULL,
        maghrib TEXT NOT NULL,
        isya TEXT NOT NULL,
        source TEXT NOT NULL,
        fetched_at TEXT NOT NULL,
        PRIMARY KEY (location_key, date_key)
      )
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_prayer_schedule_cache_date
      ON prayer_schedule_cache(date_key)
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS tasbih_state (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        count INTEGER NOT NULL DEFAULT 0,
        target INTEGER NOT NULL DEFAULT 33,
        today_cycles INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS tasbih_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date_key TEXT NOT NULL,
        target INTEGER NOT NULL,
        final_count INTEGER NOT NULL,
        completed_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> upsertSurahs(List<Map<String, Object?>> rows) async {
    final db = await database;
    await db.transaction((txn) async {
      for (final row in rows) {
        await txn.insert(
          'surahs',
          row,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<List<Map<String, Object?>>> getSurahs() async {
    final db = await database;
    return db.query('surahs', orderBy: 'surah_id ASC');
  }

  Future<void> upsertSurahDetail({
    required Map<String, Object?> surahRow,
    required List<Map<String, Object?>> ayahRows,
    required List<Map<String, Object?>> tafsirRows,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert(
        'surahs',
        surahRow,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await txn.delete(
        'ayahs',
        where: 'surah_id = ?',
        whereArgs: [surahRow['surah_id']],
      );
      for (final ayah in ayahRows) {
        await txn.insert('ayahs', ayah);
      }
      await txn.delete(
        'tafsir_id',
        where: 'surah_id = ?',
        whereArgs: [surahRow['surah_id']],
      );
      for (final tafsir in tafsirRows) {
        await txn.insert('tafsir_id', tafsir);
      }
    });
  }

  Future<Map<String, Object?>?> getSurah(int surahId) async {
    final db = await database;
    final rows = await db.query(
      'surahs',
      where: 'surah_id = ?',
      whereArgs: [surahId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return rows.first;
  }

  Future<List<Map<String, Object?>>> getAyahs(int surahId) async {
    final db = await database;
    return db.query(
      'ayahs',
      where: 'surah_id = ?',
      whereArgs: [surahId],
      orderBy: 'ayah_number ASC',
    );
  }

  Future<List<Map<String, Object?>>> getTafsir(int surahId) async {
    final db = await database;
    return db.query(
      'tafsir_id',
      where: 'surah_id = ?',
      whereArgs: [surahId],
      orderBy: 'ayah_number ASC',
    );
  }

  Future<void> setBookmark({
    required String userLocalId,
    required int surahId,
    required int ayahNumber,
    required bool bookmarked,
  }) async {
    final db = await database;
    if (bookmarked) {
      await db.insert('bookmarks', <String, Object?>{
        'user_local_id': userLocalId,
        'surah_id': surahId,
        'ayah_number': ayahNumber,
        'created_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      return;
    }
    await db.delete(
      'bookmarks',
      where: 'user_local_id = ? AND surah_id = ? AND ayah_number = ?',
      whereArgs: [userLocalId, surahId, ayahNumber],
    );
  }

  Future<List<Map<String, Object?>>> getBookmarks({
    required String userLocalId,
  }) async {
    final db = await database;
    return db.query(
      'bookmarks',
      columns: ['surah_id', 'ayah_number', 'created_at'],
      where: 'user_local_id = ?',
      whereArgs: [userLocalId],
      orderBy: 'created_at DESC',
    );
  }

  Future<bool> isBookmarked({
    required String userLocalId,
    required int surahId,
    required int ayahNumber,
  }) async {
    final db = await database;
    final rows = await db.query(
      'bookmarks',
      where: 'user_local_id = ? AND surah_id = ? AND ayah_number = ?',
      whereArgs: [userLocalId, surahId, ayahNumber],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<void> saveNote({
    required String userLocalId,
    required int surahId,
    required int ayahNumber,
    required String noteText,
  }) async {
    final db = await database;
    await db.insert('notes', <String, Object?>{
      'user_local_id': userLocalId,
      'surah_id': surahId,
      'ayah_number': ayahNumber,
      'note_text': noteText,
      'updated_at': DateTime.now().toIso8601String(),
      'is_deleted': 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getNote({
    required String userLocalId,
    required int surahId,
    required int ayahNumber,
  }) async {
    final db = await database;
    final rows = await db.query(
      'notes',
      where:
          'user_local_id = ? AND surah_id = ? AND ayah_number = ? AND is_deleted = 0',
      whereArgs: [userLocalId, surahId, ayahNumber],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return rows.first['note_text'] as String?;
  }

  Future<void> upsertDownloadedAudio({
    required String reciterId,
    required int surahId,
    required String filePath,
    required String checksum,
    required int sizeBytes,
  }) async {
    final db = await database;
    await db.insert('downloaded_audio', <String, Object?>{
      'reciter_id': reciterId,
      'surah_id': surahId,
      'file_path': filePath,
      'checksum': checksum,
      'size_bytes': sizeBytes,
      'downloaded_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getDownloadedAudioPath({
    required String reciterId,
    required int surahId,
  }) async {
    final db = await database;
    final rows = await db.query(
      'downloaded_audio',
      where: 'reciter_id = ? AND surah_id = ?',
      whereArgs: [reciterId, surahId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return rows.first['file_path'] as String?;
  }

  Future<List<int>> getDownloadedSurahIds({required String reciterId}) async {
    final db = await database;
    final rows = await db.query(
      'downloaded_audio',
      columns: ['surah_id'],
      where: 'reciter_id = ?',
      whereArgs: [reciterId],
    );
    return rows
        .map((row) => (row['surah_id'] as int?) ?? 0)
        .where((surahId) => surahId > 0)
        .toList();
  }

  Future<void> deleteDownloadedAudio({
    required String reciterId,
    required int surahId,
  }) async {
    final db = await database;
    await db.delete(
      'downloaded_audio',
      where: 'reciter_id = ? AND surah_id = ?',
      whereArgs: [reciterId, surahId],
    );
  }

  Future<void> putQuizCache({
    required String quizId,
    required int surahId,
    required String difficulty,
    required String language,
    required Map<String, Object?> payload,
    required DateTime expiresAt,
  }) async {
    final db = await database;
    await db.insert('quiz_cache', <String, Object?>{
      'quiz_id': quizId,
      'surah_id': surahId,
      'difficulty': difficulty,
      'language': language,
      'payload_json': jsonEncode(payload),
      'source_version': 1,
      'expires_at': expiresAt.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, Object?>?> getQuizCache({
    required int surahId,
    required String difficulty,
    required String language,
  }) async {
    final db = await database;
    final rows = await db.query(
      'quiz_cache',
      where: 'surah_id = ? AND difficulty = ? AND language = ?',
      whereArgs: [surahId, difficulty, language],
      orderBy: 'expires_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return rows.first;
  }

  Future<Map<String, Object?>?> getDailyVerse({required String dateKey}) async {
    final db = await database;
    final rows = await db.query(
      'daily_verse_cache',
      where: 'date_key = ?',
      whereArgs: [dateKey],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return rows.first;
  }

  Future<void> upsertDailyVerse({
    required String dateKey,
    required int surahId,
    required int ayahNumber,
    required String textAr,
    required String textLatin,
    required String textId,
    required String source,
  }) async {
    final db = await database;
    await db.insert('daily_verse_cache', <String, Object?>{
      'date_key': dateKey,
      'surah_id': surahId,
      'ayah_number': ayahNumber,
      'text_ar': textAr,
      'text_latin': textLatin,
      'text_id': textId,
      'source': source,
      'created_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, Object?>?> getWorshipLocation() async {
    final db = await database;
    final rows = await db.query('worship_location', where: 'id = 1', limit: 1);
    if (rows.isEmpty) {
      return null;
    }
    return rows.first;
  }

  Future<void> upsertWorshipLocation({
    required String mode,
    required double latitude,
    required double longitude,
    String? provinsi,
    String? kabkota,
    String? label,
  }) async {
    final db = await database;
    await db.insert('worship_location', <String, Object?>{
      'id': 1,
      'mode': mode,
      'latitude': latitude,
      'longitude': longitude,
      'provinsi': provinsi,
      'kabkota': kabkota,
      'label': label,
      'updated_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, Object?>?> getPrayerScheduleByDate({
    required String locationKey,
    required String dateKey,
  }) async {
    final db = await database;
    final rows = await db.query(
      'prayer_schedule_cache',
      where: 'location_key = ? AND date_key = ?',
      whereArgs: [locationKey, dateKey],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return rows.first;
  }

  Future<List<Map<String, Object?>>> getPrayerScheduleByMonth({
    required String locationKey,
    required int year,
    required int month,
  }) async {
    final db = await database;
    final prefix =
        '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';
    return db.query(
      'prayer_schedule_cache',
      where: 'location_key = ? AND date_key LIKE ?',
      whereArgs: [locationKey, '$prefix-%'],
      orderBy: 'date_key ASC',
    );
  }

  Future<void> upsertPrayerScheduleBatch({
    required String locationKey,
    required List<Map<String, String>> rows,
    required String source,
  }) async {
    if (rows.isEmpty) {
      return;
    }
    final db = await database;
    final fetchedAt = DateTime.now().toIso8601String();
    await db.transaction((txn) async {
      for (final row in rows) {
        await txn.insert('prayer_schedule_cache', <String, Object?>{
          'location_key': locationKey,
          'date_key': row['date_key'] ?? '',
          'imsak': row['imsak'] ?? '',
          'subuh': row['subuh'] ?? '',
          'terbit': row['terbit'] ?? '',
          'dhuha': row['dhuha'] ?? '',
          'dzuhur': row['dzuhur'] ?? '',
          'ashar': row['ashar'] ?? '',
          'maghrib': row['maghrib'] ?? '',
          'isya': row['isya'] ?? '',
          'source': source,
          'fetched_at': fetchedAt,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<Map<String, Object?>> getOrCreateTasbihState() async {
    final db = await database;
    final rows = await db.query('tasbih_state', where: 'id = 1', limit: 1);
    if (rows.isNotEmpty) {
      return rows.first;
    }
    final initial = <String, Object?>{
      'id': 1,
      'count': 0,
      'target': 33,
      'today_cycles': 0,
      'updated_at': DateTime.now().toIso8601String(),
    };
    await db.insert('tasbih_state', initial);
    return initial;
  }

  Future<void> upsertTasbihState({
    required int count,
    required int target,
    required int todayCycles,
  }) async {
    final db = await database;
    await db.insert('tasbih_state', <String, Object?>{
      'id': 1,
      'count': count,
      'target': target,
      'today_cycles': todayCycles,
      'updated_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertTasbihHistory({
    required String dateKey,
    required int target,
    required int finalCount,
  }) async {
    final db = await database;
    await db.insert('tasbih_history', <String, Object?>{
      'date_key': dateKey,
      'target': target,
      'final_count': finalCount,
      'completed_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, Object?>>> getTasbihHistoryByDate({
    required String dateKey,
  }) async {
    final db = await database;
    return db.query(
      'tasbih_history',
      where: 'date_key = ?',
      whereArgs: [dateKey],
      orderBy: 'completed_at DESC, id DESC',
    );
  }

  Future<int> countTasbihCompletions({String? dateKey}) async {
    final db = await database;
    final rows = await db.rawQuery(
      dateKey == null
          ? 'SELECT COUNT(*) AS count FROM tasbih_history'
          : 'SELECT COUNT(*) AS count FROM tasbih_history WHERE date_key = ?',
      dateKey == null ? const <Object?>[] : <Object?>[dateKey],
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  Future<void> putQuizQuestionHistoryBatch({
    required String userLocalId,
    required int surahId,
    required String difficulty,
    required String language,
    required List<String> signatures,
    List<String> ayahRefs = const <String>[],
    int keepRecent = 500,
  }) async {
    if (signatures.isEmpty) {
      return;
    }
    final db = await database;
    final nowIso = DateTime.now().toIso8601String();
    await db.transaction((txn) async {
      for (var i = 0; i < signatures.length; i++) {
        final signature = signatures[i].trim();
        if (signature.isEmpty) {
          continue;
        }
        await txn.insert('quiz_question_history', <String, Object?>{
          'user_local_id': userLocalId,
          'surah_id': surahId,
          'difficulty': difficulty,
          'language': language,
          'question_signature': signature,
          'ayah_ref_primary': i < ayahRefs.length ? ayahRefs[i] : null,
          'created_at': nowIso,
        });
      }

      if (keepRecent > 0) {
        await txn.execute(
          '''
          DELETE FROM quiz_question_history
          WHERE user_local_id = ?
            AND id NOT IN (
              SELECT id FROM quiz_question_history
              WHERE user_local_id = ?
              ORDER BY created_at DESC, id DESC
              LIMIT ?
            )
          ''',
          <Object?>[userLocalId, userLocalId, keepRecent],
        );
      }
    });
  }

  Future<List<String>> getRecentQuizQuestionSignatures({
    required String userLocalId,
    required int surahId,
    required String difficulty,
    required String language,
    int limit = 30,
  }) async {
    final db = await database;
    final rows = await db.query(
      'quiz_question_history',
      columns: ['question_signature'],
      where:
          'user_local_id = ? AND surah_id = ? AND difficulty = ? AND language = ?',
      whereArgs: [userLocalId, surahId, difficulty, language],
      orderBy: 'created_at DESC, id DESC',
      limit: limit,
    );
    return rows
        .map((row) => row['question_signature'] as String? ?? '')
        .where((value) => value.trim().isNotEmpty)
        .toList(growable: false);
  }

  Future<void> upsertLearningProgress({
    required String userLocalId,
    required int surahId,
    required String difficulty,
    required String currentStage,
    required int xpEarned,
  }) async {
    final db = await database;
    await db.insert('learning_progress_local', <String, Object?>{
      'user_local_id': userLocalId,
      'surah_id': surahId,
      'difficulty': difficulty,
      'current_stage': currentStage,
      'xp_earned': xpEarned,
      'last_activity_at': DateTime.now().toIso8601String(),
      'sync_state': 'pending',
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> countCompletedLearningUnits({required String userLocalId}) async {
    final db = await database;
    final rows = await db.rawQuery(
      '''
      SELECT COUNT(*) AS count
      FROM learning_progress_local
      WHERE user_local_id = ?
        AND current_stage = ?
      ''',
      <Object?>[userLocalId, 'completed'],
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  Future<Map<String, Object?>> getOrCreateProfileProgress(
    String userLocalId,
  ) async {
    final db = await database;
    final rows = await db.query(
      'profile_progress',
      where: 'user_local_id = ?',
      whereArgs: [userLocalId],
      limit: 1,
    );
    if (rows.isNotEmpty) {
      return rows.first;
    }
    final row = <String, Object?>{
      'user_local_id': userLocalId,
      'xp_total': 0,
      'current_streak': 0,
      'longest_streak': 0,
      'last_active_date': null,
    };
    await db.insert('profile_progress', row);
    return row;
  }

  Future<Map<String, Object?>> applyDailyProgress({
    required String userLocalId,
    required int xpDelta,
  }) async {
    final db = await database;
    return db.transaction((txn) async {
      final rows = await txn.query(
        'profile_progress',
        where: 'user_local_id = ?',
        whereArgs: [userLocalId],
        limit: 1,
      );

      int xpTotal = 0;
      int currentStreak = 0;
      int longestStreak = 0;
      DateTime? lastActiveDate;

      if (rows.isNotEmpty) {
        final row = rows.first;
        xpTotal = (row['xp_total'] as int?) ?? 0;
        currentStreak = (row['current_streak'] as int?) ?? 0;
        longestStreak = (row['longest_streak'] as int?) ?? 0;
        final last = row['last_active_date'] as String?;
        if (last != null && last.isNotEmpty) {
          lastActiveDate = DateTime.tryParse(last);
        }
      }

      final today = DateTime.now();
      final normalizedToday = DateTime(today.year, today.month, today.day);
      if (lastActiveDate == null) {
        currentStreak = 1;
      } else {
        final previous = DateTime(
          lastActiveDate.year,
          lastActiveDate.month,
          lastActiveDate.day,
        );
        final dayDiff = normalizedToday.difference(previous).inDays;
        if (dayDiff == 0) {
          currentStreak = currentStreak == 0 ? 1 : currentStreak;
        } else if (dayDiff == 1) {
          currentStreak += 1;
        } else {
          currentStreak = 1;
        }
      }
      if (currentStreak > longestStreak) {
        longestStreak = currentStreak;
      }
      xpTotal += xpDelta;

      final updated = <String, Object?>{
        'user_local_id': userLocalId,
        'xp_total': xpTotal,
        'current_streak': currentStreak,
        'longest_streak': longestStreak,
        'last_active_date': normalizedToday.toIso8601String(),
      };

      await txn.insert(
        'profile_progress',
        updated,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return updated;
    });
  }

  Future<void> enqueueSync({
    required String entityType,
    required String entityId,
    required String operation,
    required Map<String, Object?> payload,
  }) async {
    final db = await database;
    await db.insert('sync_queue', <String, Object?>{
      'entity_type': entityType,
      'entity_id': entityId,
      'operation': operation,
      'payload_json': jsonEncode(payload),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, Object?>>> getPendingSyncItems({
    int limit = 30,
  }) async {
    final db = await database;
    return db.query(
      'sync_queue',
      where: 'next_retry_at IS NULL OR next_retry_at <= ?',
      whereArgs: [DateTime.now().toIso8601String()],
      orderBy: 'created_at ASC',
      limit: limit,
    );
  }

  Future<void> removeSyncItem(int id) async {
    final db = await database;
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> postponeSyncItem({
    required int id,
    required int retryCount,
  }) async {
    final db = await database;
    final delayMinutes = retryCount * 2;
    final next = DateTime.now().add(Duration(minutes: delayMinutes));
    await db.update(
      'sync_queue',
      <String, Object?>{
        'retry_count': retryCount,
        'next_retry_at': next.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> dispose() async {
    await _database?.close();
    _database = null;
  }
}
