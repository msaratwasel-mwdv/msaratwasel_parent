import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:msaratwasel_user/src/features/children/presentation/location_picker_controller.dart';
import 'package:msaratwasel_user/src/shared/services/places_service.dart';
import 'package:msaratwasel_user/src/shared/services/geocoding_service.dart';

class MockPlacesService extends Mock implements PlacesService {}
class MockGeocodingService extends Mock implements GeocodingService {}
class MockGoogleMapController extends Mock implements GoogleMapController {}

class FakeLatLng extends Fake implements LatLng {}
class FakeCameraUpdate extends Fake implements CameraUpdate {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(FakeLatLng());
    registerFallbackValue(FakeCameraUpdate());
  });

  late LocationPickerController controller;
  late MockPlacesService mockPlaces;
  late MockGeocodingService mockGeocoding;

  setUp(() {
    mockPlaces = MockPlacesService();
    mockGeocoding = MockGeocodingService();

    when(
      () => mockPlaces.getPredictions(
        any(),
        any(),
        cancelToken: any(named: 'cancelToken'),
      ),
    ).thenAnswer((_) async => []);

    when(
      () => mockGeocoding.reverseGeocode(
        any(),
        cancelToken: any(named: 'cancelToken'),
      ),
    ).thenAnswer((_) async => 'Test Address');

    controller = LocationPickerController(
      placesService: mockPlaces,
      geocodingService: mockGeocoding,
    );
  });

  tearDown(() {
    try {
      controller.dispose();
    } catch (_) {}
  });

  group('LocationPickerController Initialization & Defaults', () {
    test('defaults to Muscat coordinates if initialLocation is null', () {
      expect(controller.selectedLocation.latitude, closeTo(23.5859, 0.001));
      expect(controller.selectedLocation.longitude, closeTo(58.4059, 0.001));
      expect(controller.addressLabel, isNull);
    });

    test('triggers reverseGeocode on non-null initialLocation', () async {
      const initial = LatLng(24.0, 55.0);
      final customController = LocationPickerController(
        placesService: mockPlaces,
        geocodingService: mockGeocoding,
        initialLocation: initial,
      );

      expect(customController.selectedLocation, initial);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(customController.addressLabel, 'Test Address');
      expect(customController.searchController.text, 'Test Address');
      customController.dispose();
    });
  });

  group('Search & Autocomplete', () {
    test('onSearchChanged with empty string resets predictions and cancels state', () {
      controller.onSearchChanged('');
      expect(controller.predictions, isEmpty);
      expect(controller.isSearching, isFalse);
    });

    test('onSearchChanged fetches predictions after debounce', () async {
      final samplePredictions = [
        PlacePrediction(
          placeId: 'place_1',
          mainText: 'Sultan Qaboos Grand Mosque',
          secondaryText: 'Muscat, Oman',
          fullText: 'Sultan Qaboos Grand Mosque, Muscat, Oman',
        ),
      ];

      when(
        () => mockPlaces.getPredictions(
          'Mosque',
          any(),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((_) async => samplePredictions);

      controller.onSearchChanged('Mosque');
      await Future.delayed(const Duration(milliseconds: 350));

      expect(controller.predictions.length, 1);
      expect(controller.predictions.first.mainText, 'Sultan Qaboos Grand Mosque');
      expect(controller.isSearching, isFalse);
    });

    test('stale request protection ignores old responses', () async {
      Completer<List<PlacePrediction>> slowRequest = Completer();
      when(
        () => mockPlaces.getPredictions(
          'A',
          any(),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((_) => slowRequest.future);

      when(
        () => mockPlaces.getPredictions(
          'AB',
          any(),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer(
        (_) async => [
          PlacePrediction(
            placeId: '2',
            mainText: 'AB',
            secondaryText: '',
            fullText: 'AB',
          ),
        ],
      );

      controller.onSearchChanged('A');
      await Future.delayed(const Duration(milliseconds: 350));
      controller.onSearchChanged('AB');
      await Future.delayed(const Duration(milliseconds: 350));

      expect(controller.predictions.length, 1);
      expect(controller.predictions.first.mainText, 'AB');

      slowRequest.complete([]);
      await Future.delayed(Duration.zero);
      expect(controller.predictions.first.mainText, 'AB');
    });

    test('handles error thrown by getPredictions gracefully', () async {
      when(
        () => mockPlaces.getPredictions(
          'ErrorQuery',
          any(),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenThrow(Exception('Network error'));

      controller.onSearchChanged('ErrorQuery');
      await Future.delayed(const Duration(milliseconds: 350));

      expect(controller.isSearching, isFalse);
      expect(controller.predictions, isEmpty);
    });
  });

  group('Place Selection', () {
    test('selectPlace updates location, addressLabel and animates camera', () async {
      final mockMap = MockGoogleMapController();
      when(() => mockMap.animateCamera(any())).thenAnswer((_) async {});
      controller.setMapController(mockMap);

      final pred = PlacePrediction(
        placeId: 'p_100',
        mainText: 'Mall of Oman',
        secondaryText: 'Bawshar',
        fullText: 'Mall of Oman, Bawshar',
      );

      when(
        () => mockPlaces.getPlaceDetails(
          'p_100',
          any(),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((_) async => const LatLng(23.59, 58.41));

      await controller.selectPlace(pred);

      expect(controller.selectedLocation.latitude, 23.59);
      expect(controller.selectedLocation.longitude, 58.41);
      expect(controller.addressLabel, 'Mall of Oman, Bawshar');
      expect(controller.searchController.text, 'Mall of Oman, Bawshar');
      verify(() => mockMap.animateCamera(any())).called(1);
    });

    test('selectPlace handles null location details gracefully', () async {
      final pred = PlacePrediction(
        placeId: 'p_null',
        mainText: 'Unknown Place',
        secondaryText: '',
        fullText: 'Unknown Place',
      );

      when(
        () => mockPlaces.getPlaceDetails(
          'p_null',
          any(),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((_) async => null);

      await controller.selectPlace(pred);
      expect(controller.isSearching, isFalse);
    });

    test('selectPlace handles exceptions gracefully', () async {
      final pred = PlacePrediction(
        placeId: 'p_err',
        mainText: 'Error Place',
        secondaryText: '',
        fullText: 'Error Place',
      );

      when(
        () => mockPlaces.getPlaceDetails(
          'p_err',
          any(),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenThrow(Exception('API error'));

      await controller.selectPlace(pred);
      expect(controller.isSearching, isFalse);
    });
  });

  group('Pin Drop & Reverse Geocoding', () {
    test('reverse geocoding is triggered on long press', () async {
      const location = LatLng(1.0, 2.0);
      controller.onLongPress(location);

      expect(controller.selectedLocation, location);
      expect(controller.isGeocoding, isTrue);

      await Future.delayed(Duration.zero);
      verify(
        () => mockGeocoding.reverseGeocode(
          location,
          cancelToken: any(named: 'cancelToken'),
        ),
      ).called(1);
    });

    test('duplicate coordinate protection avoids redundant geocoding', () async {
      const location1 = LatLng(1.0, 2.0);
      const location2 = LatLng(1.00001, 2.00001);

      controller.onLongPress(location1);
      await Future.delayed(Duration.zero);

      controller.onLongPress(location2);
      await Future.delayed(Duration.zero);

      verify(
        () => mockGeocoding.reverseGeocode(
          any(),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).called(1);
    });

    test('reverseGeocode handles errors without crashing', () async {
      when(
        () => mockGeocoding.reverseGeocode(
          any(),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenThrow(Exception('Geocoding service unavailable'));

      const location = LatLng(15.0, 45.0);
      controller.onLongPress(location);
      await Future.delayed(Duration.zero);

      expect(controller.isGeocoding, isFalse);
    });
  });

  group('Map Controller & Lifecycle', () {
    test('setMapController disposes immediately if controller is already disposed', () {
      final mockMap = MockGoogleMapController();
      when(() => mockMap.dispose()).thenReturn(null);

      controller.dispose();
      controller.setMapController(mockMap);

      verify(() => mockMap.dispose()).called(1);
    });

    test('methods are safe to call after dispose', () {
      controller.dispose();
      expect(() => controller.onSearchChanged('test'), returnsNormally);
      expect(() => controller.onLongPress(const LatLng(1, 1)), returnsNormally);
      expect(() => controller.selectPlace(PlacePrediction(
        placeId: '1', mainText: '', secondaryText: '', fullText: '',
      )), returnsNormally);
    });
  });

  group('Current Location (Geolocator Platform Mock)', () {
    testWidgets('shows snackbar when location services are disabled', (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter.baseflow.com/geolocator'),
        (MethodCall call) async {
          if (call.method == 'isLocationServiceEnabled') return false;
          return null;
        },
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => controller.moveToMyLocation(context),
              child: const Text('Locate'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Locate'));
      await tester.pumpAndSettle();

      expect(find.text('Location services are disabled.'), findsOneWidget);
    });

    testWidgets('shows snackbar when location permissions are denied', (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter.baseflow.com/geolocator'),
        (MethodCall call) async {
          if (call.method == 'isLocationServiceEnabled') return true;
          if (call.method == 'checkPermission') return 0; // denied
          if (call.method == 'requestPermission') return 0; // denied again
          return null;
        },
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => controller.moveToMyLocation(context),
              child: const Text('Locate'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Locate'));
      await tester.pumpAndSettle();

      expect(find.text('Location permissions are denied.'), findsOneWidget);
    });

    testWidgets('shows snackbar when location permissions are deniedForever', (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter.baseflow.com/geolocator'),
        (MethodCall call) async {
          if (call.method == 'isLocationServiceEnabled') return true;
          if (call.method == 'checkPermission') return 1; // deniedForever
          return null;
        },
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => controller.moveToMyLocation(context),
              child: const Text('Locate'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Locate'));
      await tester.pumpAndSettle();

      expect(find.text('Location permissions are permanently denied.'), findsOneWidget);
    });

    testWidgets('successfully fetches location and moves camera', (tester) async {
      final mockMap = MockGoogleMapController();
      when(() => mockMap.animateCamera(any())).thenAnswer((_) async {});
      controller.setMapController(mockMap);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter.baseflow.com/geolocator'),
        (MethodCall call) async {
          if (call.method == 'isLocationServiceEnabled') return true;
          if (call.method == 'checkPermission') return 2; // whileInUse
          if (call.method == 'getCurrentPosition') {
            return {
              'latitude': 23.6000,
              'longitude': 58.4200,
              'timestamp': 1000,
              'altitude': 0.0,
              'accuracy': 5.0,
              'heading': 0.0,
              'speed': 0.0,
              'speed_accuracy': 0.0,
              'is_mocked': false,
            };
          }
          return null;
        },
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => controller.moveToMyLocation(context),
              child: const Text('Locate'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Locate'));
      await tester.pumpAndSettle();

      expect(controller.selectedLocation.latitude, 23.6000);
      expect(controller.selectedLocation.longitude, 58.4200);
      verify(() => mockMap.animateCamera(any())).called(1);
    });
  });
}
