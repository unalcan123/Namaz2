import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_config.dart';

// Dio instance'ını oluşturan ve yapılandıran fonksiyon
Dio createDio() {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
    ),
  );

  // Sadece debug modda loglama yapmak için interceptor eklenir
  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: false,
        requestBody: false,
        responseHeader: false,
        responseBody: false, // ✅ KAPALI KALACAK
        error: true,
        logPrint: (o) => debugPrint("DIO> $o"),
      ),
    );
  }

  return dio;
}
