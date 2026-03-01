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

  Future<List<String>> fetchPrayerProvinces() async {
    final response = await _dio.get<Map<String, dynamic>>('/shalat/provinsi');
    final data = response.data?['data'] as List<dynamic>? ?? const [];
    return data
        .whereType<Object>()
        .map((item) => item.toString())
        .where((value) => value.trim().isNotEmpty)
        .toList(growable: false);
  }

  Future<List<String>> fetchPrayerKabkota({required String provinsi}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/shalat/kabkota',
      data: <String, Object?>{'provinsi': provinsi},
    );
    final data = response.data?['data'] as List<dynamic>? ?? const [];
    return data
        .whereType<Object>()
        .map((item) => item.toString())
        .where((value) => value.trim().isNotEmpty)
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> fetchPrayerMonthSchedule({
    required String provinsi,
    required String kabkota,
    required int year,
    required int month,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/shalat',
      data: <String, Object?>{
        'provinsi': provinsi,
        'kabkota': kabkota,
        'tahun': year,
        'bulan': month,
      },
    );
    final data = response.data?['data'] as Map<String, dynamic>? ?? const {};
    final jadwal = data['jadwal'] as List<dynamic>? ?? const [];
    return jadwal
        .whereType<Map<dynamic, dynamic>>()
        .map(
          (item) => item.map((key, value) => MapEntry(key.toString(), value)),
        )
        .toList(growable: false);
  }
}
