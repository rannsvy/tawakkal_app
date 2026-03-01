import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/sqlite/app_database.dart';
import '../../../quran/presentation/providers/quran_providers.dart';
import '../../data/daily_verse_repository.dart';
import '../../domain/entities/daily_verse.dart';

final dailyVerseRepositoryProvider = Provider<DailyVerseRepository>((ref) {
  final database = ref.watch(appDatabaseProvider);
  final quranRepository = ref.watch(quranRepositoryProvider);
  return DailyVerseRepository(
    database: database,
    quranRepository: quranRepository,
  );
});

final todayDailyVerseProvider = FutureProvider<DailyVerse>((ref) async {
  final repository = ref.watch(dailyVerseRepositoryProvider);
  return repository.getTodayVerse();
});
