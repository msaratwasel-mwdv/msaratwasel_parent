import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:msaratwasel_user/src/core/config/app_config.dart';
import 'package:msaratwasel_user/src/core/storage/storage_service.dart';
import 'package:msaratwasel_user/src/core/utils/result.dart';
import 'package:msaratwasel_user/src/core/services/notification_badge_service.dart';
import 'package:msaratwasel_user/src/features/auth/domain/entities/auth_user.dart';
import 'package:msaratwasel_user/src/features/students/domain/entities/student.dart';
import 'package:msaratwasel_user/src/features/tracking/domain/entities/bus_tracking.dart';
import 'package:msaratwasel_user/src/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:msaratwasel_user/src/shared/services/geocoding_service.dart';
import 'package:msaratwasel_user/src/shared/services/places_service.dart';

class MockDio extends Mock implements Dio {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('1. AuthUser and Student Localization Entities', () {
    test('AuthUser getLocalizedName handles ar and en correctly', () {
      final userWithEn = AuthUser(
        id: '1',
        name: 'سالم الشكيلي',
        nameEn: 'Salim Al-Shukaili',
        role: 'parent',
        accessToken: 'token_abc',
      );

      expect(userWithEn.getLocalizedName('ar'), 'سالم الشكيلي');
      expect(userWithEn.getLocalizedName('en'), 'Salim Al-Shukaili');

      final userWithoutEn = AuthUser(
        id: '2',
        name: 'سالم الشكيلي',
        nameEn: null,
        role: 'parent',
        accessToken: 'token_abc',
      );
      expect(userWithoutEn.getLocalizedName('en'), 'سالم الشكيلي');

      final userWithBlankEn = AuthUser(
        id: '3',
        name: 'سالم الشكيلي',
        nameEn: '   ',
        role: 'parent',
        accessToken: 'token_abc',
      );
      expect(userWithBlankEn.getLocalizedName('en'), 'سالم الشكيلي');
    });

    test('Student getLocalizedName handles ar and en correctly', () {
      final studentWithEn = Student(
        id: 's1',
        name: 'يوسف سالم',
        nameEn: 'Yousef Salim',
        grade: 'أول ابتدائي',
        busNumber: 'B-10',
      );

      expect(studentWithEn.getLocalizedName('ar'), 'يوسف سالم');
      expect(studentWithEn.getLocalizedName('en'), 'Yousef Salim');

      final studentWithoutEn = Student(
        id: 's2',
        name: 'يوسف سالم',
        nameEn: null,
        grade: 'أول ابتدائي',
        busNumber: 'B-10',
      );
      expect(studentWithoutEn.getLocalizedName('en'), 'يوسف سالم');

      final studentWithBlankEn = Student(
        id: 's3',
        name: 'يوسف سالم',
        nameEn: '  ',
        grade: 'أول ابتدائي',
        busNumber: 'B-10',
      );
      expect(studentWithBlankEn.getLocalizedName('en'), 'يوسف سالم');
    });
  });

  group('2. Result Pattern and BusTracking Entity', () {
    test('Result.when branches correctly for Success and Failure', () {
      const Result<int> successResult = Success(42);
      final successValue = successResult.when(
        success: (data) => data * 2,
        failure: (e, s) => -1,
      );
      expect(successValue, 84);

      final error = Exception('Failed operation');
      final stack = StackTrace.current;
      final Result<int> failureResult = Failure(error, stack);
      final failureValue = failureResult.when(
        success: (data) => data * 2,
        failure: (e, s) {
          expect(e, error);
          return -1;
        },
      );
      expect(failureValue, -1);
    });

    test('BusTracking copyWith sentinel and field overrides', () {
      final initialTime = DateTime(2026, 9, 4, 10, 0);
      final tracking = BusTracking(
        latitude: 23.5859,
        longitude: 58.4059,
        speed: 55.0,
        heading: 180.0,
        lastUpdate: initialTime,
        isStale: false,
        etaMinutes: 12,
        targetLatitude: 23.6000,
        targetLongitude: 58.4200,
      );

      // Omitting targetLatitude and targetLongitude preserves them
      final updated = tracking.copyWith(
        latitude: 23.5900,
        isStale: true,
        etaMinutes: 8,
      );
      expect(updated.latitude, 23.5900);
      expect(updated.isStale, true);
      expect(updated.etaMinutes, 8);
      expect(updated.targetLatitude, 23.6000);
      expect(updated.targetLongitude, 58.4200);

      // Explicitly passing null should clear nullable target coordinates
      final clearedTargets = tracking.copyWith(
        targetLatitude: null,
        targetLongitude: null,
      );
      expect(clearedTargets.targetLatitude, isNull);
      expect(clearedTargets.targetLongitude, isNull);
    });
  });

  group('3. AppConfig Full Specification Suite', () {
    test('AppConfig constants and getters', () {
      expect(AppConfig.apiBaseUrl.isNotEmpty, isTrue);
      expect(AppConfig.reverbHost.isNotEmpty, isTrue);
      expect(AppConfig.reverbPort, anyOf(443, 8080));
      expect(AppConfig.reverbKey, 'masarat-wasel-key');
      expect(AppConfig.defaultTimeout, const Duration(seconds: 30));
      expect(AppConfig.markerImageTimeout, const Duration(seconds: 2));
    });

    test('AppConfig.normalizeImageUrl URL normalization rules', () {
      expect(AppConfig.normalizeImageUrl(null), isNull);
      expect(AppConfig.normalizeImageUrl(''), isNull);
      expect(
        AppConfig.normalizeImageUrl('https://example.com/avatar.png'),
        'https://example.com/avatar.png',
      );
      expect(
        AppConfig.normalizeImageUrl('http://example.com/avatar.png'),
        'http://example.com/avatar.png',
      );

      // Relative path with leading slash
      final normalizedWithSlash = AppConfig.normalizeImageUrl('/avatars/user.jpg');
      expect(normalizedWithSlash, contains('/storage/avatars/user.jpg'));

      // Relative path already containing storage/
      final normalizedWithStorage = AppConfig.normalizeImageUrl('storage/avatars/user.jpg');
      expect(normalizedWithStorage, contains('/storage/avatars/user.jpg'));

      // Plain relative path
      final normalizedPlain = AppConfig.normalizeImageUrl('avatars/user.jpg');
      expect(normalizedPlain, contains('/storage/avatars/user.jpg'));
    });
  });

  group('4. StorageService Clear and Edge Cases', () {
    late StorageService storageService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
      storageService = StorageService();
    });

    test('clearAll removes all saved user data and tokens', () async {
      await storageService.saveAccessToken('token_123');
      await storageService.saveUserData(
        id: 10,
        name: 'Parent Name',
        nameEn: 'Parent Name En',
        phone: '96812345678',
        email: 'parent@example.com',
        nationalId: '123456',
        avatarUrl: 'https://example.com/photo.png',
      );

      final dataBefore = await storageService.readUserData();
      expect(dataBefore['id'], 10);
      expect(dataBefore['name'], 'Parent Name');

      await storageService.clearAll();

      final dataAfter = await storageService.readUserData();
      expect(dataAfter['id'], isNull);
      expect(dataAfter['name'], isNull);
      expect(await storageService.readAccessToken(), isNull);
    });

    test('saveUserData with partial null fields', () async {
      await storageService.saveUserData(
        id: 20,
        name: 'Simple User',
        nameEn: null,
        phone: null,
        email: null,
        nationalId: null,
        avatarUrl: null,
      );

      final userData = await storageService.readUserData();
      expect(userData['id'], 20);
      expect(userData['name'], 'Simple User');
      expect(userData['name_en'], isNull);
      expect(userData['phone'], isNull);
    });
  });

  group('5. NotificationRepositoryImpl Suite', () {
    late MockDio mockDio;
    late NotificationRepositoryImpl repo;

    setUp(() {
      mockDio = MockDio();
      repo = NotificationRepositoryImpl(dio: mockDio);
    });

    test('fetchNotifications with notifications map and unread count', () async {
      when(() => mockDio.get('guardian/notifications')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: 'guardian/notifications'),
          statusCode: 200,
          data: {
            'notifications': {
              'data': [
                {
                  'id': 'notif_1',
                  'title': 'حافلة قادمة',
                  'body': 'الحافلة على وشك الوصول',
                  'type': 'bus_arrival',
                  'created_at': '2026-09-04T12:00:00Z',
                  'read_at': null,
                }
              ],
            },
            'unread_count': 3,
          },
        ),
      );

      final result = await repo.fetchNotifications();
      expect(result.unreadCount, 3);
      expect(result.notifications.length, 1);
      expect(result.notifications.first.id, 'notif_1');
    });

    test('fetchNotifications with direct list and exception catch', () async {
      when(() => mockDio.get('guardian/notifications')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: 'guardian/notifications'),
          statusCode: 200,
          data: {
            'notifications': [
              {
                'id': 'notif_2',
                'title': 'تنبيه',
                'body': 'تم صعود الطالب',
                'type': 'student_boarded',
                'created_at': '2026-09-04T12:30:00Z',
              }
            ],
            'unread_count': 1,
          },
        ),
      );

      final result = await repo.fetchNotifications();
      expect(result.notifications.length, 1);
      expect(result.unreadCount, 1);

      // Non-200 response
      when(() => mockDio.get('guardian/notifications')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: 'guardian/notifications'),
          statusCode: 500,
          data: {},
        ),
      );
      final failedResult = await repo.fetchNotifications();
      expect(failedResult.notifications, isEmpty);
      expect(failedResult.unreadCount, 0);

      // DioException
      when(() => mockDio.get('guardian/notifications')).thenThrow(
        DioException(requestOptions: RequestOptions(path: '')),
      );
      final errorResult = await repo.fetchNotifications();
      expect(errorResult.notifications, isEmpty);
      expect(errorResult.unreadCount, 0);
    });
  });

  group('6. GeocodingService and PlacesService Extended Tests', () {
    late MockDio mockDio;

    setUp(() {
      mockDio = MockDio();
    });

    test('GeocodingService handles various spatial relationships and cancel token', () async {
      final relationships = {
        'WITHIN': 'In',
        'BESIDE': 'Beside',
        'ACROSS_THE_ROAD': 'Across from',
        'DOWN_THE_ROAD': 'Down from',
        'AROUND_THE_CORNER': 'Around the corner from',
        'BEHIND': 'Behind',
        'UNKNOWN_RELATION': 'Near',
      };

      final geocoding = GeocodingService(dio: mockDio);

      for (final entry in relationships.entries) {
        when(
          () => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            cancelToken: any(named: 'cancelToken'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 200,
            data: {
              'status': 'OK',
              'results': [
                {
                  'address_descriptors': {
                    'landmarks': [
                      {
                        'display_name': {'text': 'Sultan Qaboos Port'},
                        'spatial_relationship': entry.key,
                      }
                    ],
                  },
                }
              ],
            },
          ),
        );

        final res = await geocoding.reverseGeocode(const LatLng(23.6, 58.5));
        expect(res, '${entry.value} Sultan Qaboos Port');
      }

      // Test DioException cancel handling
      when(
        () => mockDio.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          cancelToken: any(named: 'cancelToken'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.cancel,
        ),
      );

      final cancelRes = await geocoding.reverseGeocode(const LatLng(23.6, 58.5));
      expect(cancelRes, 'Unknown Location');
    });

    test('PlacesService handles PlacePrediction models and edge cases', () async {
      final places = PlacesService(dio: mockDio);

      // Old fromJson factory
      final oldPred = PlacePrediction.fromJson({
        'place_id': 'old_p1',
        'structured_formatting': {
          'main_text': 'Muttrah Souq',
          'secondary_text': 'Muscat',
        },
        'description': 'Muttrah Souq, Muscat',
      });
      expect(oldPred.placeId, 'old_p1');
      expect(oldPred.mainText, 'Muttrah Souq');
      expect(oldPred.secondaryText, 'Muscat');
      expect(oldPred.fullText, 'Muttrah Souq, Muscat');

      // Null location in place details
      when(
        () => mockDio.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          cancelToken: any(named: 'cancelToken'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: {'location': null},
        ),
      );

      final nullLoc = await places.getPlaceDetails('p_none', 'sess_1');
      expect(nullLoc, isNull);

      // DioException cancel in details
      when(
        () => mockDio.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          cancelToken: any(named: 'cancelToken'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.cancel,
        ),
      );

      final cancelDetails = await places.getPlaceDetails('p_cancel', 'sess_2');
      expect(cancelDetails, isNull);

      // Empty suggestions in getPredictions
      when(
        () => mockDio.post(
          any(),
          data: any(named: 'data'),
          cancelToken: any(named: 'cancelToken'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: {'suggestions': null},
        ),
      );

      final noSuggestions = await places.getPredictions('nonexistent', 'sess_3');
      expect(noSuggestions, isEmpty);
    });
  });
}
