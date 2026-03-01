import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/colors.dart';
import '../../../../shared/widgets/async_state_view.dart';
import '../../../../shared/widgets/rich_info_card.dart';
import '../../../../shared/widgets/rich_page_background.dart';
import '../../../prayer_times/presentation/providers/prayer_times_providers.dart';
import '../../domain/entities/qibla_state.dart';
import '../providers/qibla_providers.dart';

class QiblaPage extends ConsumerWidget {
  const QiblaPage({super.key});

  static const routeName = 'qibla-page';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qiblaState = ref.watch(qiblaStateProvider);
    final locationState = ref.watch(prayerLocationProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Arah Kiblat')),
      body: RichPageBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            RichInfoCard(
              borderRadius: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lokasi',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    locationState.asData?.value.label ??
                        'Gunakan lokasi untuk akurasi arah kiblat.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: () async {
                          try {
                            await ref
                                .read(prayerLocationProvider.notifier)
                                .useCurrentLocation();
                            ref.invalidate(prayerScheduleProvider);
                          } catch (error) {
                            if (!context.mounted) {
                              return;
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Gagal memakai lokasi: $error'),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.my_location_rounded),
                        label: const Text('Lokasi Saat Ini'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => context.push('/prayer-times'),
                        icon: const Icon(Icons.settings_rounded),
                        label: const Text('Atur Lokasi'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AsyncStateView(
              value: qiblaState,
              onRetry: () {
                ref.invalidate(prayerLocationProvider);
                ref.invalidate(qiblaHeadingProvider);
              },
              builder: (state) {
                return RichInfoCard(
                  borderRadius: 24,
                  child: Column(
                    children: [
                      _QiblaCompass(state: state),
                      const SizedBox(height: 12),
                      Text(
                        'Arah kiblat: ${state.bearingToKaaba.toStringAsFixed(1)}°',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: TawakkalColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        state.compassAvailable
                            ? 'Putar perangkat hingga panah sejajar dengan penanda kiblat.'
                            : 'Sensor kompas tidak tersedia. Gunakan angka derajat sebagai panduan.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: TawakkalColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _QiblaCompass extends StatelessWidget {
  const _QiblaCompass({required this.state});

  final QiblaState state;

  @override
  Widget build(BuildContext context) {
    final offset = state.directionOffset;
    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: TawakkalColors.primary.withValues(alpha: 0.4),
              ),
            ),
          ),
          _CompassLabel(text: 'N', top: 12),
          _CompassLabel(text: 'S', bottom: 12),
          _CompassLabel(text: 'E', right: 12),
          _CompassLabel(text: 'W', left: 12),
          Transform.rotate(
            angle: ((offset ?? state.bearingToKaaba) * math.pi) / 180,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.navigation_rounded,
                  size: 58,
                  color: TawakkalColors.primary,
                ),
                Text(
                  'Kiblat',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: TawakkalColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          if (state.deviceHeading != null)
            Positioned(
              bottom: 20,
              child: Text(
                'Heading: ${state.deviceHeading!.toStringAsFixed(1)}°',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: TawakkalColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CompassLabel extends StatelessWidget {
  const _CompassLabel({
    required this.text,
    this.left,
    this.right,
    this.top,
    this.bottom,
  });

  final String text;
  final double? left;
  final double? right;
  final double? top;
  final double? bottom;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: TawakkalColors.textSecondary,
        ),
      ),
    );
  }
}
