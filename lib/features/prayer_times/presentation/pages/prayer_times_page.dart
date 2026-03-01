import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/colors.dart';
import '../../../../shared/widgets/async_state_view.dart';
import '../../../../shared/widgets/rich_info_card.dart';
import '../../../../shared/widgets/rich_page_background.dart';
import '../../domain/entities/prayer_models.dart';
import '../providers/prayer_times_providers.dart';

class PrayerTimesPage extends ConsumerWidget {
  const PrayerTimesPage({super.key});

  static const routeName = 'prayer-times-page';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationState = ref.watch(prayerLocationProvider);
    final scheduleState = ref.watch(prayerScheduleProvider);
    final moment = ref.watch(prayerMomentProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal Shalat'),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: () async {
              await ref
                  .read(prayerTimesActionsProvider)
                  .refreshToday(force: true);
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RichPageBackground(
        child: RefreshIndicator(
          onRefresh: () => ref.read(prayerTimesActionsProvider).refreshToday(),
          child: ListView(
            physics: const ClampingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _LocationCard(
                locationState: locationState,
                onUseCurrent: () async {
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
                      SnackBar(content: Text('Gagal memakai lokasi: $error')),
                    );
                  }
                },
                onManual: () async {
                  final location = locationState.asData?.value;
                  await showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) {
                      return _ManualLocationSheet(initial: location);
                    },
                  );
                  ref.invalidate(prayerScheduleProvider);
                },
              ),
              const SizedBox(height: 12),
              RichInfoCard(
                borderRadius: 20,
                gradient: isDark
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1A2724), Color(0xFF202F2B)],
                      )
                    : const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFFFFFF), Color(0xFFF0F6F4)],
                      ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      moment == null
                          ? 'Memuat status shalat...'
                          : 'Status Saat Ini',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? TawakkalColors.textPrimaryDark
                            : TawakkalColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (moment != null) ...[
                      Text(
                        'Sekarang: ${moment.currentLabel}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: TawakkalColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Berikutnya: ${moment.nextLabel} (${_formatHhMm(moment.nextTime)})',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: TawakkalColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _countdownLabel(moment.nextTime),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? TawakkalColors.textPrimaryDark
                              : TawakkalColors.textPrimaryLight,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AsyncStateView(
                value: scheduleState,
                onRetry: () => ref.invalidate(prayerScheduleProvider),
                builder: (schedule) {
                  return RichInfoCard(
                    borderRadius: 20,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              'Jadwal Hari Ini',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const Spacer(),
                            _SourceChip(source: schedule.source),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...schedule.timeline.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _PrayerRow(
                              label: entry.key,
                              value: entry.value,
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatHhMm(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _countdownLabel(DateTime nextTime) {
    final diff = nextTime.difference(DateTime.now());
    final safe = diff.isNegative ? Duration.zero : diff;
    final hours = safe.inHours;
    final minutes = safe.inMinutes.remainder(60);
    final seconds = safe.inSeconds.remainder(60);
    return 'Waktu tersisa ${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.locationState,
    required this.onUseCurrent,
    required this.onManual,
  });

  final AsyncValue<WorshipLocation> locationState;
  final Future<void> Function() onUseCurrent;
  final Future<void> Function() onManual;

  @override
  Widget build(BuildContext context) {
    final location = locationState.asData?.value;
    return RichInfoCard(
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lokasi',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            location == null
                ? 'Memuat lokasi...'
                : location.label ??
                      '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 2),
          Text(
            location == null
                ? ''
                : (location.mode == WorshipLocationMode.auto
                      ? 'Mode: Otomatis'
                      : 'Mode: Manual'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: TawakkalColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: () {
                  unawaited(onUseCurrent());
                },
                icon: const Icon(Icons.my_location_rounded),
                label: const Text('Lokasi Saat Ini'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  unawaited(onManual());
                },
                icon: const Icon(Icons.edit_location_alt_rounded),
                label: const Text('Atur Manual'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SourceChip extends StatelessWidget {
  const _SourceChip({required this.source});

  final String source;

  @override
  Widget build(BuildContext context) {
    final text = source == 'equran' ? 'Equran' : 'Kalkulasi Lokal';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: TawakkalColors.primary.withValues(alpha: 0.16),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: TawakkalColors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PrayerRow extends StatelessWidget {
  const _PrayerRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: TawakkalColors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _ManualLocationSheet extends ConsumerStatefulWidget {
  const _ManualLocationSheet({required this.initial});

  final WorshipLocation? initial;

  @override
  ConsumerState<_ManualLocationSheet> createState() =>
      _ManualLocationSheetState();
}

class _ManualLocationSheetState extends ConsumerState<_ManualLocationSheet> {
  late final TextEditingController _latController;
  late final TextEditingController _lngController;
  String? _selectedProvinsi;
  String? _selectedKabkota;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _latController = TextEditingController(
      text: widget.initial?.latitude.toStringAsFixed(6) ?? '',
    );
    _lngController = TextEditingController(
      text: widget.initial?.longitude.toStringAsFixed(6) ?? '',
    );
    _selectedProvinsi = widget.initial?.provinsi;
    _selectedKabkota = widget.initial?.kabkota;
  }

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final provincesState = ref.watch(prayerProvincesProvider);
    final kabkotaState = _selectedProvinsi == null
        ? const AsyncData<List<String>>(<String>[])
        : ref.watch(prayerKabkotaProvider(_selectedProvinsi!));

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + keyboard),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lokasi Manual',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _latController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: const InputDecoration(labelText: 'Latitude'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _lngController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: const InputDecoration(labelText: 'Longitude'),
            ),
            const SizedBox(height: 10),
            provincesState.when(
              data: (items) => DropdownButtonFormField<String>(
                initialValue:
                    _selectedProvinsi != null &&
                        items.contains(_selectedProvinsi)
                    ? _selectedProvinsi
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Provinsi (opsional)',
                ),
                items: items
                    .map(
                      (value) => DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  setState(() {
                    _selectedProvinsi = value;
                    _selectedKabkota = null;
                  });
                },
              ),
              loading: () => const LinearProgressIndicator(minHeight: 2),
              error: (_, _) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 8),
            kabkotaState.when(
              data: (items) => DropdownButtonFormField<String>(
                initialValue:
                    _selectedKabkota != null && items.contains(_selectedKabkota)
                    ? _selectedKabkota
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Kabupaten/Kota (opsional)',
                ),
                items: items
                    .map(
                      (value) => DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      ),
                    )
                    .toList(growable: false),
                onChanged: _selectedProvinsi == null
                    ? null
                    : (value) {
                        setState(() {
                          _selectedKabkota = value;
                        });
                      },
              ),
              loading: () => const LinearProgressIndicator(minHeight: 2),
              error: (_, _) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving
                    ? null
                    : () async {
                        final lat = double.tryParse(_latController.text.trim());
                        final lng = double.tryParse(_lngController.text.trim());
                        if (lat == null || lng == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Latitude/longitude tidak valid.'),
                            ),
                          );
                          return;
                        }
                        setState(() {
                          _saving = true;
                        });
                        try {
                          final label =
                              _selectedKabkota ??
                              _selectedProvinsi ??
                              '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
                          await ref
                              .read(prayerLocationProvider.notifier)
                              .saveManualLocation(
                                latitude: lat,
                                longitude: lng,
                                provinsi: _selectedProvinsi,
                                kabkota: _selectedKabkota,
                                label: label,
                              );
                          if (!context.mounted) {
                            return;
                          }
                          Navigator.of(context).pop();
                        } finally {
                          if (mounted) {
                            setState(() {
                              _saving = false;
                            });
                          }
                        }
                      },
                child: Text(_saving ? 'Menyimpan...' : 'Simpan Lokasi'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
