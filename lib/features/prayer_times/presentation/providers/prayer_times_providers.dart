import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/sqlite/app_database.dart';
import '../../../quran/presentation/providers/quran_providers.dart';
import '../../data/prayer_times_repository.dart';
import '../../domain/entities/prayer_models.dart';

final prayerTimesRepositoryProvider = Provider<PrayerTimesRepository>((ref) {
  final database = ref.watch(appDatabaseProvider);
  final api = ref.watch(quranApiProvider);
  return PrayerTimesRepository(database: database, api: api);
});

final prayerLocationProvider =
    AsyncNotifierProvider<PrayerLocationController, WorshipLocation>(
      PrayerLocationController.new,
    );

class PrayerLocationController extends AsyncNotifier<WorshipLocation> {
  @override
  Future<WorshipLocation> build() async {
    final repository = ref.read(prayerTimesRepositoryProvider);
    final saved = await repository.getSavedLocation();
    if (saved != null) {
      return saved;
    }
    try {
      final auto = await repository.resolveAutoLocation();
      await repository.saveLocation(auto);
      return auto;
    } catch (_) {
      const fallback = WorshipLocation(
        mode: WorshipLocationMode.manual,
        latitude: -6.2088,
        longitude: 106.8456,
        provinsi: 'DKI Jakarta',
        kabkota: 'Kota Jakarta',
        label: 'Jakarta',
      );
      await repository.saveLocation(fallback);
      return fallback;
    }
  }

  Future<void> useCurrentLocation() async {
    final repository = ref.read(prayerTimesRepositoryProvider);
    final auto = await repository.resolveAutoLocation();
    await repository.saveLocation(auto);
    state = AsyncData(auto);
  }

  Future<void> saveManualLocation({
    required double latitude,
    required double longitude,
    String? provinsi,
    String? kabkota,
    String? label,
  }) async {
    final repository = ref.read(prayerTimesRepositoryProvider);
    final manual = WorshipLocation(
      mode: WorshipLocationMode.manual,
      latitude: latitude,
      longitude: longitude,
      provinsi: provinsi,
      kabkota: kabkota,
      label: label,
    );
    await repository.saveLocation(manual);
    state = AsyncData(manual);
  }
}

final prayerScheduleProvider = FutureProvider<PrayerSchedule>((ref) async {
  final repository = ref.watch(prayerTimesRepositoryProvider);
  final location = await ref.watch(prayerLocationProvider.future);
  return repository.getScheduleForDate(
    location: location,
    date: DateTime.now(),
  );
});

final prayerMomentTickProvider = StreamProvider<DateTime>((ref) async* {
  while (true) {
    yield DateTime.now();
    await Future<void>.delayed(const Duration(seconds: 1));
  }
});

final prayerMomentProvider = Provider<PrayerMoment?>((ref) {
  ref.watch(prayerMomentTickProvider);
  final schedule = ref.watch(prayerScheduleProvider).asData?.value;
  if (schedule == null) {
    return null;
  }
  final repository = ref.watch(prayerTimesRepositoryProvider);
  return repository.resolvePrayerMoment(today: schedule, now: DateTime.now());
});

final prayerProvincesProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.watch(prayerTimesRepositoryProvider);
  return repository.getProvinces();
});

final prayerKabkotaProvider = FutureProvider.family<List<String>, String>((
  ref,
  provinsi,
) async {
  final repository = ref.watch(prayerTimesRepositoryProvider);
  return repository.getKabkota(provinsi: provinsi);
});

final prayerTimesActionsProvider = Provider<PrayerTimesActions>((ref) {
  return PrayerTimesActions(ref);
});

class PrayerTimesActions {
  PrayerTimesActions(this._ref);

  final Ref _ref;

  Future<void> refreshToday({bool force = true}) async {
    final location = await _ref.read(prayerLocationProvider.future);
    await _ref
        .read(prayerTimesRepositoryProvider)
        .getScheduleForDate(
          location: location,
          date: DateTime.now(),
          forceRefresh: force,
        );
    _ref.invalidate(prayerScheduleProvider);
  }
}
