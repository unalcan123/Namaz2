import 'package:dio/dio.dart';
import '../../../core/errors.dart';
import 'models.dart';

class EzanApi {
  final Dio _dio;
  EzanApi(this._dio);

  Future<List<Ulke>> getUlkeler() async {
    try {
      final r = await _dio.get("/ulkeler");
      final list = (r.data as List).cast<Map<String, dynamic>>();
      return list.map(Ulke.fromJson).toList();
    } on DioException catch (e) {
      throw AppException("Ülkeler alınamadı: ${e.message}");
    }
  }

  Future<List<Sehir>> getSehirler(String ulkeId) async {
    try {
      final r = await _dio.get("/sehirler/$ulkeId");
      final list = (r.data as List).cast<Map<String, dynamic>>();
      return list.map(Sehir.fromJson).toList();
    } on DioException catch (e) {
      throw AppException("Şehirler alınamadı: ${e.message}");
    }
  }

  Future<List<Ilce>> getIlceler(String sehirId) async {
    try {
      final r = await _dio.get("/ilceler/$sehirId");
      final list = (r.data as List).cast<Map<String, dynamic>>();
      return list.map(Ilce.fromJson).toList();
    } on DioException catch (e) {
      throw AppException("İlçeler alınamadı: ${e.message}");
    }
  }

  Future<List<Vakit>> getVakitler(String ilceId) async {
    try {
      final r = await _dio.get("/vakitler/${ilceId.trim()}");
      final list = (r.data as List).cast<Map<String, dynamic>>();
      return list.map(Vakit.fromJson).toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw AppException("Bu ilçe için vakit bulunamadı. Lütfen başka ilçe seçin.");
      }
      throw AppException("Vakitler alınamadı: ${e.message}");
    }
  }
}
