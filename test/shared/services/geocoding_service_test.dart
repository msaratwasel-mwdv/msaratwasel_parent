import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:msaratwasel_user/src/shared/services/geocoding_service.dart';
import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late GeocodingService geocodingService;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    geocodingService = GeocodingService(dio: mockDio);
  });

  group('GeocodingService', () {
    const testLocation = LatLng(23.5859, 58.4059);

    test('returns landmark name when address_descriptors are present', () async {
      when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => Response(
                data: {
                  'status': 'OK',
                  'results': [
                    {
                      'address_descriptors': {
                        'landmarks': [
                          {
                            'display_name': {'text': 'Grand Mosque'},
                            'spatial_relationship': 'NEAR'
                          }
                        ]
                      },
                      'formatted_address': 'Some Address, Muscat'
                    }
                  ]
                },
                statusCode: 200,
                requestOptions: RequestOptions(path: ''),
              ));

      final result = await geocodingService.reverseGeocode(testLocation);
      expect(result, equals('Near Grand Mosque'));
    });

    test('falls back to formatted_address when address_descriptors are missing', () async {
      when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => Response(
                data: {
                  'status': 'OK',
                  'results': [
                    {
                      'formatted_address': 'Fallback Address, Muscat'
                    }
                  ]
                },
                statusCode: 200,
                requestOptions: RequestOptions(path: ''),
              ));

      final result = await geocodingService.reverseGeocode(testLocation);
      expect(result, equals('Fallback Address, Muscat'));
    });

    test('returns Unknown Location on failure', () async {
      when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
          .thenThrow(DioException(requestOptions: RequestOptions(path: '')));

      final result = await geocodingService.reverseGeocode(testLocation);
      expect(result, equals('Unknown Location'));
    });
  });
}
