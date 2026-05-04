import 'package:flutter_test/flutter_test.dart';
import 'package:msaratwasel_user/src/shared/services/places_service.dart';
import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late PlacesService placesService;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    placesService = PlacesService(dio: mockDio);
    registerFallbackValue(Options());
  });

  group('PlacesService', () {
    const sessionToken = 'test-token';

    test('getPredictions uses correct endpoint and includes session token', () async {
      when(() => mockDio.post(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response(
            data: {
              'suggestions': [
                {
                  'placePrediction': {
                    'placeId': 'p1',
                    'text': {'text': 'Muscat, Oman'},
                    'structuredFormat': {
                      'mainText': {'text': 'Muscat'},
                      'secondaryText': {'text': 'Oman'}
                    }
                  }
                }
              ]
            },
            statusCode: 200,
            requestOptions: RequestOptions(path: ''),
          ));

      final results = await placesService.getPredictions('Muscat', sessionToken);
      
      expect(results.length, 1);
      expect(results.first.mainText, 'Muscat');
      
      verify(() => mockDio.post(
        'https://places.googleapis.com/v1/places:autocomplete',
        data: any(named: 'data', that: containsPair('sessionToken', sessionToken)),
        options: any(named: 'options'),
      )).called(1);
    });

    test('getPlaceDetails uses correct field mask and session token', () async {
      when(() => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response(
            data: {
              'location': {'latitude': 23.0, 'longitude': 58.0}
            },
            statusCode: 200,
            requestOptions: RequestOptions(path: ''),
          ));

      final result = await placesService.getPlaceDetails('p1', sessionToken);
      
      expect(result, isNotNull);
      expect(result!.latitude, 23.0);
      
      verify(() => mockDio.get(
        'https://places.googleapis.com/v1/places/p1',
        queryParameters: any(named: 'queryParameters', that: containsPair('sessionToken', sessionToken)),
        options: any(named: 'options', that: isA<Options>().having(
          (o) => o.headers?['X-Goog-FieldMask'], 'field mask', 'id,displayName,location'
        )),
      )).called(1);
    });
  });
}
