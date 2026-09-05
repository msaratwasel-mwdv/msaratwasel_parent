import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:msaratwasel_user/src/shared/utils/marker_generator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MarkerGenerator Suite', () {
    test('1. createStudentMarker with initials when imageUrl is null', () async {
      final marker = await MarkerGenerator.createStudentMarker(
        name: 'أحمد',
        color: Colors.blue,
        size: 40.0,
      );
      expect(marker, isA<BitmapDescriptor>());
    });

    test('2. createStudentMarker with empty name fallback', () async {
      final marker = await MarkerGenerator.createStudentMarker(
        name: '',
        color: Colors.red,
        size: 30.0,
      );
      expect(marker, isA<BitmapDescriptor>());
    });

    test('3. createStudentMarker with imageUrl that fails to load falls back to initial', () async {
      final marker = await MarkerGenerator.createStudentMarker(
        name: 'سارة',
        imageUrl: 'https://invalid-non-existent-domain.test/avatar.png',
        authToken: 'test_token',
        color: Colors.purple,
        size: 36.0,
      );
      expect(marker, isA<BitmapDescriptor>());
    });

    test('4. createSchoolMarker generates descriptor', () async {
      final marker = await MarkerGenerator.createSchoolMarker(
        color: Colors.green,
        size: 40.0,
      );
      expect(marker, isA<BitmapDescriptor>());
    });

    test('5. createBusMarker generates descriptor', () async {
      final marker = await MarkerGenerator.createBusMarker(
        color: Colors.amber,
        size: 44.0,
      );
      expect(marker, isA<BitmapDescriptor>());
    });

    test('6. createHomeMarker generates descriptor', () async {
      final marker = await MarkerGenerator.createHomeMarker(
        color: Colors.teal,
        size: 38.0,
      );
      expect(marker, isA<BitmapDescriptor>());
    });

    test('7. createPointMarker generates descriptor', () async {
      final marker = await MarkerGenerator.createPointMarker(
        color: Colors.indigo,
        size: 20.0,
      );
      expect(marker, isA<BitmapDescriptor>());
    });
  });
}
