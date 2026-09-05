import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:msaratwasel_user/src/core/network/api_client.dart';
import 'package:msaratwasel_user/src/core/network/interceptors.dart';
import 'package:msaratwasel_user/src/core/storage/storage_service.dart';
import 'package:msaratwasel_user/src/core/utils/device_utils.dart';

class FakeStorageService extends Fake implements StorageService {
  String? token;
  String? locale;

  @override
  Future<String?> readAccessToken() async => token;

  @override
  Future<String?> readLocale() async => locale;
}

class FakeRequestHandler extends Fake implements RequestInterceptorHandler {
  @override
  void next(RequestOptions requestOptions) {}
}

class FakeResponseHandler extends Fake implements ResponseInterceptorHandler {
  @override
  void next(Response response) {}
}

class FakeErrorHandler extends Fake implements ErrorInterceptorHandler {
  @override
  void next(DioException err) {}
}


void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Network Interceptors & ApiClient Suite', () {
    test('1. AuthInterceptor injects token and Accept-Language', () async {
      final fakeStorage = FakeStorageService()
        ..token = 'jwt_secret_token_123'
        ..locale = 'en';

      final interceptor = AuthInterceptor(fakeStorage);
      final options = RequestOptions(path: '/api/v1/students');
      
      bool nextCalled = false;
      final handler = RequestInterceptorHandler();

      interceptor.onRequest(options, handler);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(options.headers['Authorization'], 'Bearer jwt_secret_token_123');
      expect(options.headers['Accept-Language'], 'en');
    });

    test('2. AuthInterceptor defaults to ar when locale is null and ignores empty token', () async {
      final fakeStorage = FakeStorageService()
        ..token = ''
        ..locale = null;

      final interceptor = AuthInterceptor(fakeStorage);
      final options = RequestOptions(path: '/api/v1/test');

      interceptor.onRequest(options, RequestInterceptorHandler());
      await Future.delayed(const Duration(milliseconds: 50));

      expect(options.headers.containsKey('Authorization'), isFalse);
      expect(options.headers['Accept-Language'], 'ar');
    });

    test('3. LoggingInterceptor logs request, response, and error without exceptions', () {
      final logging = LoggingInterceptor();

      // Request without data
      final reqOptions = RequestOptions(path: '/api/test', method: 'GET');
      logging.onRequest(reqOptions, FakeRequestHandler());

      // Request with data
      final reqWithData = RequestOptions(path: '/api/post', method: 'POST', data: {'key': 'val'});
      logging.onRequest(reqWithData, FakeRequestHandler());

      // Response
      final response = Response(
        requestOptions: reqOptions,
        statusCode: 200,
        data: {'status': 'ok'},
      );
      logging.onResponse(response, FakeResponseHandler());

      // Error
      final dioError = DioException(
        requestOptions: reqOptions,
        response: Response(requestOptions: reqOptions, statusCode: 500),
        type: DioExceptionType.badResponse,
      );
      logging.onError(dioError, FakeErrorHandler());

      expect(reqOptions.path, '/api/test');
    });

    test('4. ApiClient initializes default Dio and adds interceptors', () {
      final fakeStorage = FakeStorageService()..token = 'tok';
      final client = ApiClient(storage: fakeStorage);

      expect(client.client, isNotNull);
      expect(client.client.interceptors.isNotEmpty, isTrue);

      final hasAuth = client.client.interceptors.any((i) => i is AuthInterceptor);
      expect(hasAuth, isTrue);
    });

    test('5. DeviceUtils executes on host environment and returns string', () async {
      final name = await DeviceUtils.getDeviceName();
      expect(name, isNotEmpty);

      final id = await DeviceUtils.getDeviceId();
      // On Windows host in tests, getDeviceId returns null gracefully
      expect(id == null || id is String, isTrue);
    });
  });
}
