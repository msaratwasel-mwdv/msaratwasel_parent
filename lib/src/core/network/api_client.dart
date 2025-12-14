import 'package:dio/dio.dart';

import 'package:msaratwasel_user/src/core/config/app_config.dart';
import 'package:msaratwasel_user/src/core/storage/storage_service.dart';

import 'interceptors.dart';

class ApiClient {
  ApiClient({Dio? dio, StorageService? storage})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: AppConfig.apiBaseUrl,
              connectTimeout: AppConfig.defaultTimeout,
              receiveTimeout: AppConfig.defaultTimeout,
            ),
          ) {
    if (storage != null) {
      _dio.interceptors.add(AuthInterceptor(storage));
    }
    _dio.interceptors.add(LoggingInterceptor());
  }

  final Dio _dio;

  Dio get client => _dio;
}
