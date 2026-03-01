import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../prayer_times/presentation/providers/prayer_times_providers.dart';
import '../../domain/entities/qibla_state.dart';

final qiblaHeadingProvider = StreamProvider<double?>((ref) {
  final stream = FlutterCompass.events;
  if (stream == null) {
    return Stream<double?>.value(null);
  }
  return stream.map((event) {
    final heading = event.heading;
    if (heading == null || heading.isNaN) {
      return null;
    }
    return heading;
  });
});

final qiblaStateProvider = Provider<AsyncValue<QiblaState>>((ref) {
  final locationState = ref.watch(prayerLocationProvider);
  final headingState = ref.watch(qiblaHeadingProvider);

  return locationState.whenData((location) {
    final bearing = Qibla.qibla(
      Coordinates(location.latitude, location.longitude),
    );
    final heading = headingState.asData?.value;
    return QiblaState(
      bearingToKaaba: bearing,
      deviceHeading: heading,
      compassAvailable: heading != null,
    );
  });
});
