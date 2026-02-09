import 'dart:async';

import 'package:just_audio/just_audio.dart';

import '../domain/entities/audio_track.dart';

class AudioPlayerService {
  AudioPlayerService() : _player = AudioPlayer() {
    _indexSubscription = _player.currentIndexStream.listen((index) {
      if (index == null || index < 0 || index >= _queue.length) {
        return;
      }
      _currentTrack = _queue[index];
    });
  }

  final AudioPlayer _player;
  StreamSubscription<int?>? _indexSubscription;
  List<AudioTrack> _queue = const [];
  AudioTrack? _currentTrack;

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<int?> get currentIndexStream => _player.currentIndexStream;
  Stream<LoopMode> get loopModeStream => _player.loopModeStream;
  List<AudioTrack> get queue => _queue;
  AudioTrack? get currentTrack => _currentTrack;

  Future<void> playTrack(AudioTrack track) async {
    await setQueueAndPlay([track], initialIndex: 0);
  }

  Future<void> setQueueAndPlay(
    List<AudioTrack> tracks, {
    required int initialIndex,
  }) async {
    if (tracks.isEmpty) {
      return;
    }
    final normalizedIndex = initialIndex.clamp(0, tracks.length - 1);
    final sources = tracks.map(_audioSourceForTrack).toList();
    await _player.setAudioSources(
      sources,
      initialIndex: normalizedIndex,
      initialPosition: Duration.zero,
    );
    _queue = tracks;
    _currentTrack = tracks[normalizedIndex];
    await _player.play();
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> resume() async {
    await _player.play();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<bool> playPrevious() async {
    final index = _player.currentIndex;
    if (index == null || index <= 0) {
      return false;
    }
    await _player.seekToPrevious();
    await _player.play();
    _currentTrack = _queue[index - 1];
    return true;
  }

  Future<bool> playNext() async {
    final index = _player.currentIndex;
    if (index == null || index >= _queue.length - 1) {
      return false;
    }
    await _player.seekToNext();
    await _player.play();
    _currentTrack = _queue[index + 1];
    return true;
  }

  Future<void> setRepeatOne(bool enabled) async {
    await _player.setLoopMode(enabled ? LoopMode.one : LoopMode.off);
  }

  bool get hasPrevious {
    final index = _player.currentIndex;
    return index != null && index > 0;
  }

  bool get hasNext {
    final index = _player.currentIndex;
    return index != null && index < _queue.length - 1;
  }

  bool get isRepeatOne => _player.loopMode == LoopMode.one;

  AudioSource _audioSourceForTrack(AudioTrack track) {
    if (track.localPath != null && track.localPath!.isNotEmpty) {
      return AudioSource.file(track.localPath!);
    }
    return AudioSource.uri(Uri.parse(track.url));
  }

  Future<void> dispose() async {
    await _indexSubscription?.cancel();
    await _player.dispose();
  }
}
