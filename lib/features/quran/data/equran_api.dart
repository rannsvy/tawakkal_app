import 'package:dio/dio.dart';

class EquranApi {
  EquranApi(this._dio);

  final Dio _dio;

  Future<List<Map<String, dynamic>>> fetchSurahList() async {
    final response = await _dio.get<Map<String, dynamic>>('/surat');
    final data = response.data?['data'] as List<dynamic>? ?? const [];
    return data
        .whereType<Map<dynamic, dynamic>>()
        .map(
          (item) => item.map((key, value) => MapEntry(key.toString(), value)),
        )
        .toList();
  }

  Future<Map<String, dynamic>> fetchSurahDetail(int surahId) async {
    final response = await _dio.get<Map<String, dynamic>>('/surat/$surahId');
    final data = response.data?['data'] as Map<String, dynamic>? ?? const {};
    return data;
  }

  Future<Map<String, dynamic>> fetchTafsir(int surahId) async {
    final response = await _dio.get<Map<String, dynamic>>('/tafsir/$surahId');
    final data = response.data?['data'] as Map<String, dynamic>? ?? const {};
    return data;
  }
}
