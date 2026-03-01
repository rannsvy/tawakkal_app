import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tawakkal_app/features/qibla/domain/entities/qibla_state.dart';

void main() {
  test('calculates reasonable qibla bearing for Jakarta', () {
    const jakarta = Coordinates(-6.2088, 106.8456);
    final bearing = Qibla.qibla(jakarta);

    expect(bearing, greaterThan(290));
    expect(bearing, lessThan(296));
  });

  test('computes directional offset from device heading', () {
    const state = QiblaState(
      bearingToKaaba: 295.0,
      deviceHeading: 120.0,
      compassAvailable: true,
    );

    expect(state.directionOffset, closeTo(175.0, 0.001));
  });
}
