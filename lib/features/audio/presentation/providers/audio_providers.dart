import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/sqlite/app_database.dart';
import '../../../quran/domain/entities/surah.dart';
import '../../data/audio_player_service.dart';
import '../../data/audio_repository_impl.dart';
import '../../domain/entities/audio_track.dart';
import '../../domain/repositories/audio_repository.dart';

final audioPlayerServiceProvider = Provider<AudioPlayerService>((ref) {
  final service = AudioPlayerService();
  ref.onDispose(() async {
    await service.dispose();
  });
  return service;
});

final audioRepositoryProvider = Provider<AudioRepository>((ref) {
  final playerService = ref.watch(audioPlayerServiceProvider);
  final database = ref.watch(appDatabaseProvider);
  final dio = ref.watch(dioProvider);
  return AudioRepositoryImpl(
    playerService: playerService,
    database: database,
    dio: dio,
  );
});

final audioQueueProvider = StateProvider<List<AudioTrack>>((ref) => const []);
final audioManualCurrentTrackProvider = StateProvider<AudioTrack?>(
  (ref) => null,
);

final audioPlayerStateProvider = StreamProvider<PlayerState>((ref) {
  final service = ref.watch(audioPlayerServiceProvider);
  return service.playerStateStream;
});

final audioPositionProvider = StreamProvider<Duration>((ref) {
  final service = ref.watch(audioPlayerServiceProvider);
  return service.positionStream;
});

final audioDurationProvider = StreamProvider<Duration?>((ref) {
  final service = ref.watch(audioPlayerServiceProvider);
  return service.durationStream;
});

final audioCurrentIndexProvider = StreamProvider<int?>((ref) {
  final service = ref.watch(audioPlayerServiceProvider);
  return service.currentIndexStream;
});

final audioLoopModeProvider = StreamProvider<LoopMode>((ref) {
  final service = ref.watch(audioPlayerServiceProvider);
  return service.loopModeStream;
});

final downloadedSurahIdsProvider = FutureProvider.family<Set<int>, String>((
  ref,
  reciterId,
) async {
  final repository = ref.watch(audioRepositoryProvider);
  return repository.getDownloadedSurahIds(reciterId: reciterId);
});

final audioCurrentTrackProvider = Provider<AudioTrack?>((ref) {
  final service = ref.watch(audioPlayerServiceProvider);
  final queue = ref.watch(audioQueueProvider);
  final manualTrack = ref.watch(audioManualCurrentTrackProvider);
  final indexState = ref.watch(audioCurrentIndexProvider);
  final index = indexState.asData?.value;

  if (index != null && index >= 0 && index < queue.length) {
    return queue[index];
  }
  if (manualTrack != null) {
    return manualTrack;
  }
  if (service.currentTrack != null) {
    return service.currentTrack;
  }
  if (queue.isNotEmpty) {
    return queue.first;
  }
  return null;
});

final audioActionsProvider = Provider<AudioActions>((ref) {
  return AudioActions(ref);
});

class AudioActions {
  AudioActions(this._ref);

  final Ref _ref;

  Future<void> playUrl({
    required String url,
    required String title,
    String? artist,
    String? reciterId,
    int? surahId,
  }) async {
    final track = AudioTrack(
      url: url,
      title: title,
      artist: artist,
      reciterId: reciterId,
      surahId: surahId,
    );
    _ref.read(audioQueueProvider.notifier).state = [track];
    _ref.read(audioManualCurrentTrackProvider.notifier).state = track;
    await _ref
        .read(audioRepositoryProvider)
        .playQueue(tracks: [track], startIndex: 0);
  }

  Future<void> playSurahQueue({
    required List<SurahSummary> surahs,
    required String reciterId,
    required String reciterName,
    required int startSurahId,
  }) async {
    final queue = surahs
        .where((surah) => surah.audioFull[reciterId] != null)
        .map(
          (surah) => AudioTrack(
            url: surah.audioFull[reciterId]!,
            title: surah.nameLatin,
            artist: reciterName,
            reciterId: reciterId,
            surahId: surah.surahId,
          ),
        )
        .toList();

    if (queue.isEmpty) {
      return;
    }

    final startIndex = queue.indexWhere(
      (track) => track.surahId == startSurahId,
    );
    final normalizedStart = startIndex < 0 ? 0 : startIndex;
    _ref.read(audioQueueProvider.notifier).state = queue;
    _ref.read(audioManualCurrentTrackProvider.notifier).state =
        queue[normalizedStart];
    await _ref
        .read(audioRepositoryProvider)
        .playQueue(tracks: queue, startIndex: normalizedStart);
  }

  Future<void> pause() async {
    await _ref.read(audioRepositoryProvider).pause();
  }

  Future<void> resume() async {
    await _ref.read(audioRepositoryProvider).resume();
  }

  Future<void> togglePlayPause() async {
    final state = _ref.read(audioPlayerStateProvider).asData?.value;
    if (state?.playing ?? false) {
      await pause();
    } else {
      await resume();
    }
  }

  Future<void> seek(Duration position) async {
    await _ref.read(audioRepositoryProvider).seek(position);
  }

  Future<bool> previous() async {
    final result = await _ref.read(audioRepositoryProvider).previous();
    if (result) {
      _ref.read(audioManualCurrentTrackProvider.notifier).state = _ref
          .read(audioPlayerServiceProvider)
          .currentTrack;
    }
    return result;
  }

  Future<bool> next() async {
    final result = await _ref.read(audioRepositoryProvider).next();
    if (result) {
      _ref.read(audioManualCurrentTrackProvider.notifier).state = _ref
          .read(audioPlayerServiceProvider)
          .currentTrack;
    }
    return result;
  }

  Future<void> setRepeatOne(bool enabled) async {
    await _ref.read(audioRepositoryProvider).setRepeatOne(enabled);
  }

  Future<void> removeDownload({
    required String reciterId,
    required int surahId,
  }) async {
    await _ref
        .read(audioRepositoryProvider)
        .removeDownload(reciterId: reciterId, surahId: surahId);
  }

  Future<String> downloadSurah({
    required String reciterId,
    required int surahId,
    required String url,
    void Function(int received, int total)? onProgress,
  }) {
    return _ref
        .read(audioRepositoryProvider)
        .downloadSurah(
          reciterId: reciterId,
          surahId: surahId,
          url: url,
          onProgress: onProgress,
        );
  }
}
