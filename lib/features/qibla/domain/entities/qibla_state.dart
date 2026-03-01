class QiblaState {
  const QiblaState({
    required this.bearingToKaaba,
    this.deviceHeading,
    required this.compassAvailable,
  });

  final double bearingToKaaba;
  final double? deviceHeading;
  final bool compassAvailable;

  double? get directionOffset {
    if (deviceHeading == null) {
      return null;
    }
    return (bearingToKaaba - deviceHeading! + 360) % 360;
  }
}
