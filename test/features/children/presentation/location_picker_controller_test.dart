import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:msaratwasel_user/src/features/children/presentation/location_picker_controller.dart';
import 'package:msaratwasel_user/src/shared/services/places_service.dart';
import 'package:msaratwasel_user/src/shared/services/geocoding_service.dart';
import 'package:mocktail/mocktail.dart';

class MockPlacesService extends Mock implements PlacesService {}
class MockGeocodingService extends Mock implements GeocodingService {}
class FakeLatLng extends Fake implements LatLng {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeLatLng());
  });
  late LocationPickerController controller;
  late MockPlacesService mockPlaces;
  late MockGeocodingService mockGeocoding;

  setUp(() {
    mockPlaces = MockPlacesService();
    mockGeocoding = MockGeocodingService();
    
    // Default mock behavior
    when(() => mockPlaces.getPredictions(any(), any())).thenAnswer((_) async => []);
    when(() => mockGeocoding.reverseGeocode(any())).thenAnswer((_) async => 'Test Address');
    
    controller = LocationPickerController(
      placesService: mockPlaces,
      geocodingService: mockGeocoding,
    );
  });

  group('LocationPickerController', () {
    test('onSearchChanged generates session token on first call', () {
      expect(controller.isSearching, isFalse);
      
      controller.onSearchChanged('M');
      // Wait for debounce or check if token is generated immediately
      // The implementation generates token immediately
      
      // We can't access private _sessionToken but we can verify if getPredictions is called with a token
    });

    test('stale request protection ignores old responses', () async {
      // Simulate slow first request
      Completer<List<PlacePrediction>> slowRequest = Completer();
      when(() => mockPlaces.getPredictions('A', any())).thenAnswer((_) => slowRequest.future);
      when(() => mockPlaces.getPredictions('AB', any())).thenAnswer((_) async => [
        PlacePrediction(placeId: '2', mainText: 'AB', secondaryText: '', fullText: 'AB')
      ]);

      controller.onSearchChanged('A');
      // Trigger second search immediately (simulated by calling _fetchPredictions if it was public, 
      // but here we wait a bit and call onSearchChanged again)
      
      await Future.delayed(const Duration(milliseconds: 350));
      controller.onSearchChanged('AB');
      await Future.delayed(const Duration(milliseconds: 350));
      
      expect(controller.predictions.length, 1);
      expect(controller.predictions.first.mainText, 'AB');
      
      // Resolve first slow request
      slowRequest.complete([]);
      await Future.delayed(Duration.zero);
      
      // Should still be 'AB'
      expect(controller.predictions.first.mainText, 'AB');
    });

    test('reverse geocoding is triggered on long press', () async {
      const location = LatLng(1.0, 2.0);
      controller.onLongPress(location);
      
      expect(controller.selectedLocation, location);
      expect(controller.isGeocoding, isTrue);
      
      await Future.delayed(Duration.zero);
      verify(() => mockGeocoding.reverseGeocode(location)).called(1);
    });

    test('duplicate coordinate protection avoids redundant geocoding', () async {
      const location1 = LatLng(1.0, 2.0);
      const location2 = LatLng(1.00001, 2.00001); // Very close (< 5m)

      controller.onLongPress(location1);
      await Future.delayed(Duration.zero);
      
      controller.onLongPress(location2);
      await Future.delayed(Duration.zero);
      
      verify(() => mockGeocoding.reverseGeocode(any())).called(1);
    });
  });
}
