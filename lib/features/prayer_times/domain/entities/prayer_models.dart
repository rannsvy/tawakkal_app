enum WorshipLocationMode { auto, manual }

class WorshipLocation {
  const WorshipLocation({
    required this.mode,
    required this.latitude,
    required this.longitude,
    this.provinsi,
    this.kabkota,
    this.label,
  });

  final WorshipLocationMode mode;
  final double latitude;
  final double longitude;
  final String? provinsi;
  final String? kabkota;
  final String? label;

  String get locationKey {
    final provincePart = (provinsi ?? '').trim().toLowerCase();
    final cityPart = (kabkota ?? '').trim().toLowerCase();
    if (provincePart.isNotEmpty && cityPart.isNotEmpty) {
      return 'id:$provincePart|$cityPart';
    }
    final lat = latitude.toStringAsFixed(4);
    final lng = longitude.toStringAsFixed(4);
    return 'geo:$lat,$lng';
  }
}

class PrayerSchedule {
  const PrayerSchedule({
    required this.dateKey,
    required this.imsak,
    required this.subuh,
    required this.terbit,
    required this.dhuha,
    required this.dzuhur,
    required this.ashar,
    required this.maghrib,
    required this.isya,
    required this.source,
  });

  final String dateKey;
  final String imsak;
  final String subuh;
  final String terbit;
  final String dhuha;
  final String dzuhur;
  final String ashar;
  final String maghrib;
  final String isya;
  final String source;

  Map<String, String> get timeline => <String, String>{
    'Imsak': imsak,
    'Subuh': subuh,
    'Terbit': terbit,
    'Dhuha': dhuha,
    'Dzuhur': dzuhur,
    'Ashar': ashar,
    'Maghrib': maghrib,
    'Isya': isya,
  };
}

class PrayerMoment {
  const PrayerMoment({
    required this.currentLabel,
    required this.nextLabel,
    required this.nextTime,
  });

  final String currentLabel;
  final String nextLabel;
  final DateTime nextTime;
}
