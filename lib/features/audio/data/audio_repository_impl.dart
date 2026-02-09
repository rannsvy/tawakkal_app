import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/storage/sqlite/app_database.dart';
import '../domain/entities/audio_track.dart';
import '../domain/repositories/audio_repository.dart';
import 'audio_player_service.dart';

class AudioRepositoryImpl implements AudioRepository {
  AudioRepositoryImpl({
    required AudioPlayerService playerService,
    required AppDatabase database,
    required Dio dio,
  }) : _playerService = playerService,
       _database = database,
       _dio = dio;

  final AudioPlayerService _playerService;
  final AppDatabase _database;
  final Dio _dio;

  @override
  Future<void> playUrl(AudioTrack track) async {
    await playQueue(tracks: [track], startIndex: 0);
  }

  @override
  Future<void> playQueue({
    required List<AudioTrack> tracks,
    required int startIndex,
  }) async {
    if (tracks.isEmpty) {
      return;
    }
    final playableTracks = await Future.wait(tracks.map(_resolvePlayableTrack));
    await _playerService.setQueueAndPlay(
      playableTracks,
      initialIndex: startIndex.clamp(0, playableTracks.length - 1),
    );
  }

  @override
  Future<void> pause() {
    return _playerService.pause();
  }

  @override
  Future<void> resume() {
    return _playerService.resume();
  }

  @override
  Future<void> seek(Duration position) {
    return _playerService.seek(position);
  }

  @override
  Future<bool> previous() {
    return _playerService.playPrevious();
  }

  @override
  Future<bool> next() {
    return _playerService.playNext();
  }

  @override
  Future<void> setRepeatOne(bool enabled) {
    return _playerService.setRepeatOne(enabled);
  }

  @override
  Future<Set<int>> getDownloadedSurahIds({required String reciterId}) async {
    final ids = await _database.getDownloadedSurahIds(reciterId: reciterId);
    return ids.toSet();
  }

  @override
  Future<void> removeDownload({
    required String reciterId,
    required int surahId,
  }) async {
    final filePath = await _database.getDownloadedAudioPath(
      reciterId: reciterId,
      surahId: surahId,
    );
    if (filePath != null && filePath.isNotEmpty) {
      final file = File(filePath);
      if (file.existsSync()) {
        await file.delete();
      }
    }
    await _database.deleteDownloadedAudio(
      reciterId: reciterId,
      surahId: surahId,
    );
  }

  Future<AudioTrack> _resolvePlayableTrack(AudioTrack track) async {
    if (track.reciterId != null && track.surahId != null) {
      final downloadedPath = await getDownloadedPath(
        reciterId: track.reciterId!,
        surahId: track.surahId!,
      );
      if (downloadedPath != null && File(downloadedPath).existsSync()) {
        return AudioTrack(
          url: track.url,
          title: track.title,
          artist: track.artist,
          reciterId: track.reciterId,
          surahId: track.surahId,
          localPath: downloadedPath,
        );
      }
    }
    return track;
  }

  @override
  Future<String?> getDownloadedPath({
    required String reciterId,
    required int surahId,
  }) async {
    final path = await _database.getDownloadedAudioPath(
      reciterId: reciterId,
      surahId: surahId,
    );
    if (path == null || path.isEmpty) {
      return null;
    }
    if (!File(path).existsSync()) {
      return null;
    }
    return path;
  }

  @override
  Future<String> downloadSurah({
    required String reciterId,
    required int surahId,
    required String url,
    void Function(int received, int total)? onProgress,
  }) async {
    final appDir = await getApplicationDocumentsDirectory();
    final directory = Directory(p.join(appDir.path, 'audio', reciterId));
    if (!directory.existsSync()) {
      await directory.create(recursive: true);
    }

    final filename = '${surahId.toString().padLeft(3, '0')}.mp3';
    final filePath = p.join(directory.path, filename);
    await _dio.download(url, filePath, onReceiveProgress: onProgress);

    final file = File(filePath);
    if (!file.existsSync()) {
      throw Exception('File audio tidak ditemukan setelah proses unduh.');
    }

    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw Exception('File audio kosong setelah diunduh.');
    }
    final checksum = sha256.convert(bytes).toString();
    await _database.upsertDownloadedAudio(
      reciterId: reciterId,
      surahId: surahId,
      filePath: filePath,
      checksum: checksum,
      sizeBytes: bytes.length,
    );

    return filePath;
  }
}
