import 'package:equatable/equatable.dart';

class AudioTrack extends Equatable {
  const AudioTrack({
    required this.url,
    required this.title,
    this.artist,
    this.localPath,
    this.reciterId,
    this.surahId,
  });

  final String url;
  final String title;
  final String? artist;
  final String? localPath;
  final String? reciterId;
  final int? surahId;

  bool get isDownloaded => localPath != null && localPath!.isNotEmpty;

  @override
  List<Object?> get props => [
    url,
    title,
    artist,
    localPath,
    reciterId,
    surahId,
  ];
}
