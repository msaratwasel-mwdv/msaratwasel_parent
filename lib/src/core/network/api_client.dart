import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import 'package:msaratwasel_user/src/core/config/app_config.dart';
import 'package:msaratwasel_user/src/core/storage/storage_service.dart';

import 'dart:ui' as ui;
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
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          try {
            options.headers['Accept-Language'] = ui.PlatformDispatcher.instance.locale.languageCode;
          } catch (_) {
            options.headers['Accept-Language'] = 'ar';
          }
          return handler.next(options);
        },
      ),
    );
    if (storage != null) {
      _dio.interceptors.add(AuthInterceptor(storage));
    }
    if (kDebugMode) {
      _dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          error: true,
          compact: true,
          maxWidth: 90,
        ),
      );
    }
  }

  final Dio _dio;

  Dio get client => _dio;
}
