import 'dart:developer' as developer;
import 'package:dio/dio.dart';

import 'package:msaratwasel_user/src/core/storage/storage_service.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage);

  final StorageService _storage;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.readAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    super.onRequest(options, handler);
  }
}

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    developer.log('🌐 DIO [REQ]: ${options.method} ${options.uri}', name: 'NETWORK');
    if (options.data != null) {
      developer.log('📦 DIO [BODY]: ${options.data}', name: 'NETWORK');
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    developer.log('✅ DIO [RES]: ${response.statusCode} ${response.requestOptions.uri}', name: 'NETWORK');
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    developer.log('❌ DIO [ERR]: ${err.response?.statusCode} ${err.requestOptions.uri}', name: 'NETWORK', error: err);
    super.onError(err, handler);
  }
}
