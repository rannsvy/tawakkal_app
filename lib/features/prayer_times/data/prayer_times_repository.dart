import 'dart:math' as math;

import 'package:adhan_dart/adhan_dart.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/storage/sqlite/app_database.dart';
import '../../quran/data/equran_api.dart';
import '../domain/entities/prayer_models.dart';

class PrayerTimesRepository {
  PrayerTimesRepository({required AppDatabase database, required EquranApi api})
    : _database = database,
      _api = api;

  final AppDatabase _database;
  final EquranApi _api;

  Future<List<String>> getProvinces() {
    return _api.fetchPrayerProvinces();
  }

  Future<List<String>> getKabkota({required String provinsi}) {
    return _api.fetchPrayerKabkota(provinsi: provinsi);
  }

  Future<WorshipLocation?> getSavedLocation() async {
    final row = await _database.getWorshipLocation();
    if (row == null) {
      return null;
    }
    final modeRaw = row['mode'] as String? ?? 'manual';
    final mode = modeRaw == 'auto'
        ? WorshipLocationMode.auto
        : WorshipLocationMode.manual;
    return WorshipLocation(
      mode: mode,
      latitude: ((row['latitude'] as num?) ?? 0).toDouble(),
      longitude: ((row['longitude'] as num?) ?? 0).toDouble(),
      provinsi: row['provinsi'] as String?,
      kabkota: row['kabkota'] as String?,
      label: row['label'] as String?,
    );
  }

  Future<WorshipLocation> resolveAutoLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Layanan lokasi nonaktif.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Izin lokasi ditolak.');
    }

    final position = await Geolocator.getCurrentPosition();
    String? label;
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final mark = placemarks.first;
        final locality = mark.locality ?? mark.subAdministrativeArea;
        final admin = mark.administrativeArea;
        final country = mark.country;
        label = [
          locality,
          admin,
          country,
        ].where((part) => (part ?? '').trim().isNotEmpty).join(', ');
      }
    } catch (_) {
      // Reverse geocoding is best-effort only.
    }

    return WorshipLocation(
      mode: WorshipLocationMode.auto,
      latitude: position.latitude,
      longitude: position.longitude,
      label: label,
    );
  }

  Future<void> saveLocation(WorshipLocation location) async {
    await _database.upsertWorshipLocation(
      mode: location.mode == WorshipLocationMode.auto ? 'auto' : 'manual',
      latitude: location.latitude,
      longitude: location.longitude,
      provinsi: location.provinsi,
      kabkota: location.kabkota,
      label: location.label,
    );
  }

  Future<PrayerSchedule> getScheduleForDate({
    required WorshipLocation location,
    required DateTime date,
    bool forceRefresh = false,
  }) async {
    final dateKey = _dateKey(date);
    final locationKey = location.locationKey;

    if (!forceRefresh) {
      final cached = await _database.getPrayerScheduleByDate(
        locationKey: locationKey,
        dateKey: dateKey,
      );
      if (cached != null) {
        return _scheduleFromRow(cached);
      }
    }

    final hasIndonesiaRegion =
        (location.provinsi ?? '').trim().isNotEmpty &&
        (location.kabkota ?? '').trim().isNotEmpty;
    if (hasIndonesiaRegion) {
      try {
        final monthCached = await _database.getPrayerScheduleByMonth(
          locationKey: locationKey,
          year: date.year,
          month: date.month,
        );
        final hasCurrentDate = monthCached.any(
          (row) => (row['date_key'] as String?) == dateKey,
        );
        if (!hasCurrentDate || forceRefresh) {
          final remoteRows = await _api.fetchPrayerMonthSchedule(
            provinsi: location.provinsi!,
            kabkota: location.kabkota!,
            year: date.year,
            month: date.month,
          );
          await _database.upsertPrayerScheduleBatch(
            locationKey: locationKey,
            source: 'equran',
            rows: remoteRows
                .map(
                  (row) => <String, String>{
                    'date_key': row['tanggal_lengkap']?.toString() ?? '',
                    'imsak': row['imsak']?.toString() ?? '',
                    'subuh': row['subuh']?.toString() ?? '',
                    'terbit': row['terbit']?.toString() ?? '',
                    'dhuha': row['dhuha']?.toString() ?? '',
                    'dzuhur': row['dzuhur']?.toString() ?? '',
                    'ashar': row['ashar']?.toString() ?? '',
                    'maghrib': row['maghrib']?.toString() ?? '',
                    'isya': row['isya']?.toString() ?? '',
                  },
                )
                .where((row) => (row['date_key'] ?? '').trim().isNotEmpty)
                .toList(growable: false),
          );
        }
        final resolved = await _database.getPrayerScheduleByDate(
          locationKey: locationKey,
          dateKey: dateKey,
        );
        if (resolved != null) {
          return _scheduleFromRow(resolved);
        }
      } catch (_) {
        // Fallback to local calculation below.
      }
    }

    final local = _calculateLocally(location: location, date: date);
    await _database.upsertPrayerScheduleBatch(
      locationKey: locationKey,
      source: 'local_calc',
      rows: [
        <String, String>{
          'date_key': local.dateKey,
          'imsak': local.imsak,
          'subuh': local.subuh,
          'terbit': local.terbit,
          'dhuha': local.dhuha,
          'dzuhur': local.dzuhur,
          'ashar': local.ashar,
          'maghrib': local.maghrib,
          'isya': local.isya,
        },
      ],
    );
    return local;
  }

  PrayerSchedule _calculateLocally({
    required WorshipLocation location,
    required DateTime date,
  }) {
    final params = CalculationMethodParameters.muslimWorldLeague();
    params.madhab = Madhab.shafi;
    final prayerTimes = PrayerTimes(
      date: DateTime(date.year, date.month, date.day),
      coordinates: Coordinates(location.latitude, location.longitude),
      calculationParameters: params,
    );
    final imsak = prayerTimes.fajr.subtract(const Duration(minutes: 10));
    final dhuha = prayerTimes.sunrise.add(const Duration(minutes: 20));
    return PrayerSchedule(
      dateKey: _dateKey(date),
      imsak: _formatTime(imsak),
      subuh: _formatTime(prayerTimes.fajr),
      terbit: _formatTime(prayerTimes.sunrise),
      dhuha: _formatTime(dhuha),
      dzuhur: _formatTime(prayerTimes.dhuhr),
      ashar: _formatTime(prayerTimes.asr),
      maghrib: _formatTime(prayerTimes.maghrib),
      isya: _formatTime(prayerTimes.isha),
      source: 'local_calc',
    );
  }

  PrayerMoment resolvePrayerMoment({
    required PrayerSchedule today,
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    final todayDate = _dateFromKey(today.dateKey);

    final schedule = <({String label, DateTime time})>[
      (label: 'Subuh', time: _parseTime(todayDate, today.subuh)),
      (label: 'Dzuhur', time: _parseTime(todayDate, today.dzuhur)),
      (label: 'Ashar', time: _parseTime(todayDate, today.ashar)),
      (label: 'Maghrib', time: _parseTime(todayDate, today.maghrib)),
      (label: 'Isya', time: _parseTime(todayDate, today.isya)),
    ];

    for (var i = 0; i < schedule.length; i++) {
      final item = schedule[i];
      if (reference.isBefore(item.time)) {
        final currentLabel = i == 0 ? 'Menunggu Subuh' : schedule[i - 1].label;
        return PrayerMoment(
          currentLabel: currentLabel,
          nextLabel: item.label,
          nextTime: item.time,
        );
      }
    }

    final tomorrowSubuh = _parseTime(
      todayDate.add(const Duration(days: 1)),
      today.subuh,
    );
    return PrayerMoment(
      currentLabel: 'Isya',
      nextLabel: 'Subuh',
      nextTime: tomorrowSubuh,
    );
  }

  PrayerSchedule _scheduleFromRow(Map<String, Object?> row) {
    return PrayerSchedule(
      dateKey: row['date_key'] as String? ?? '',
      imsak: row['imsak'] as String? ?? '',
      subuh: row['subuh'] as String? ?? '',
      terbit: row['terbit'] as String? ?? '',
      dhuha: row['dhuha'] as String? ?? '',
      dzuhur: row['dzuhur'] as String? ?? '',
      ashar: row['ashar'] as String? ?? '',
      maghrib: row['maghrib'] as String? ?? '',
      isya: row['isya'] as String? ?? '',
      source: row['source'] as String? ?? 'cache',
    );
  }

  String _dateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  DateTime _dateFromKey(String key) {
    final parsed = DateTime.tryParse(key);
    if (parsed != null) {
      return DateTime(parsed.year, parsed.month, parsed.day);
    }
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime _parseTime(DateTime date, String value) {
    final parts = value.split(':');
    final hour = parts.isNotEmpty ? int.tryParse(parts.first) ?? 0 : 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return DateTime(
      date.year,
      date.month,
      date.day,
      hour.clamp(0, 23),
      minute.clamp(0, 59),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String fallbackLabelForCoordinates(double latitude, double longitude) {
    final lat = latitude.toStringAsFixed(math.min(4, 6));
    final lng = longitude.toStringAsFixed(math.min(4, 6));
    return '$lat, $lng';
  }
}
