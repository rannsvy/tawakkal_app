import '../entities/audio_track.dart';

abstract class AudioRepository {
  Future<void> playUrl(AudioTrack track);
  Future<void> playQueue({
    required List<AudioTrack> tracks,
    required int startIndex,
  });
  Future<void> pause();
  Future<void> resume();
  Future<void> seek(Duration position);
  Future<bool> previous();
  Future<bool> next();
  Future<void> setRepeatOne(bool enabled);
  Future<Set<int>> getDownloadedSurahIds({required String reciterId});
  Future<void> removeDownload({
    required String reciterId,
    required int surahId,
  });
  Future<String?> getDownloadedPath({
    required String reciterId,
    required int surahId,
  });
  Future<String> downloadSurah({
    required String reciterId,
    required int surahId,
    required String url,
    void Function(int received, int total)? onProgress,
  });
}
