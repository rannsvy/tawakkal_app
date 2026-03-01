import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tawakkal_app/core/storage/sqlite/app_database.dart';
import 'package:tawakkal_app/features/prayer_times/data/prayer_times_repository.dart';
import 'package:tawakkal_app/features/prayer_times/domain/entities/prayer_models.dart';
import 'package:tawakkal_app/features/quran/data/equran_api.dart';

void main() {
  test('uses Equran monthly cache for Indonesia location', () async {
    final db = _FakePrayerDatabase();
    final api = _FakeEquranApi();
    final repository = PrayerTimesRepository(database: db, api: api);
    final location = WorshipLocation(
      mode: WorshipLocationMode.manual,
      latitude: -6.2,
      longitude: 106.8,
      provinsi: 'DKI Jakarta',
      kabkota: 'Kota Jakarta',
      label: 'Jakarta',
    );

    final schedule = await repository.getScheduleForDate(
      location: location,
      date: DateTime(2026, 3, 1),
    );

    expect(schedule.source, 'equran');
    expect(schedule.subuh, '04:43');
    expect(api.monthCalls, 1);

    api.shouldThrow = true;
    final second = await repository.getScheduleForDate(
      location: location,
      date: DateTime(2026, 3, 1),
    );
    expect(second.subuh, '04:43');
    expect(api.monthCalls, 1);
  });

  test('falls back to local calculation for non-Indonesia location', () async {
    final db = _FakePrayerDatabase();
    final api = _FakeEquranApi()..shouldThrow = true;
    final repository = PrayerTimesRepository(database: db, api: api);
    final location = WorshipLocation(
      mode: WorshipLocationMode.manual,
      latitude: 37.7749,
      longitude: -122.4194,
      label: 'San Francisco',
    );

    final schedule = await repository.getScheduleForDate(
      location: location,
      date: DateTime(2026, 3, 1),
    );

    expect(schedule.source, 'local_calc');
    expect(schedule.subuh, matches(RegExp(r'^\d{2}:\d{2}$')));
    expect(schedule.maghrib, matches(RegExp(r'^\d{2}:\d{2}$')));
  });
}

class _FakePrayerDatabase extends AppDatabase {
  final Map<String, Map<String, Object?>> _rows =
      <String, Map<String, Object?>>{};

  @override
  Future<Map<String, Object?>?> getPrayerScheduleByDate({
    required String locationKey,
    required String dateKey,
  }) async {
    return _rows['$locationKey::$dateKey'];
  }

  @override
  Future<List<Map<String, Object?>>> getPrayerScheduleByMonth({
    required String locationKey,
    required int year,
    required int month,
  }) async {
    final prefix =
        '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';
    return _rows.entries
        .where(
          (entry) =>
              entry.key.startsWith('$locationKey::') &&
              (entry.value['date_key'] as String? ?? '').startsWith(prefix),
        )
        .map((entry) => entry.value)
        .toList(growable: false);
  }

  @override
  Future<void> upsertPrayerScheduleBatch({
    required String locationKey,
    required List<Map<String, String>> rows,
    required String source,
  }) async {
    for (final row in rows) {
      final dateKey = row['date_key'] ?? '';
      _rows['$locationKey::$dateKey'] = <String, Object?>{
        'location_key': locationKey,
        'date_key': dateKey,
        'imsak': row['imsak'] ?? '',
        'subuh': row['subuh'] ?? '',
        'terbit': row['terbit'] ?? '',
        'dhuha': row['dhuha'] ?? '',
        'dzuhur': row['dzuhur'] ?? '',
        'ashar': row['ashar'] ?? '',
        'maghrib': row['maghrib'] ?? '',
        'isya': row['isya'] ?? '',
        'source': source,
      };
    }
  }
}

class _FakeEquranApi extends EquranApi {
  _FakeEquranApi() : super(Dio());

  int monthCalls = 0;
  bool shouldThrow = false;

  @override
  Future<List<Map<String, dynamic>>> fetchPrayerMonthSchedule({
    required String provinsi,
    required String kabkota,
    required int year,
    required int month,
  }) async {
    if (shouldThrow) {
      throw Exception('offline');
    }
    monthCalls += 1;
    return <Map<String, dynamic>>[
      <String, dynamic>{
        'tanggal_lengkap': '2026-03-01',
        'imsak': '04:33',
        'subuh': '04:43',
        'terbit': '05:55',
        'dhuha': '06:22',
        'dzuhur': '12:09',
        'ashar': '15:12',
        'maghrib': '18:15',
        'isya': '19:24',
      },
      <String, dynamic>{
        'tanggal_lengkap': '2026-03-02',
        'imsak': '04:32',
        'subuh': '04:42',
        'terbit': '05:54',
        'dhuha': '06:21',
        'dzuhur': '12:09',
        'ashar': '15:12',
        'maghrib': '18:14',
        'isya': '19:23',
      },
    ];
  }
}
