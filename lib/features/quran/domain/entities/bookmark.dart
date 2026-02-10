import 'package:equatable/equatable.dart';

class BookmarkedAyah extends Equatable {
  const BookmarkedAyah({
    required this.surahId,
    required this.ayahNumber,
    required this.createdAt,
  });

  final int surahId;
  final int ayahNumber;
  final DateTime createdAt;

  @override
  List<Object?> get props => [surahId, ayahNumber, createdAt];
}
