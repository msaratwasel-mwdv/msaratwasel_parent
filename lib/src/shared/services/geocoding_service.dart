import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:msaratwasel_user/src/core/config/api_keys.dart';

class GeocodingService {
  final Dio _dio;
  final String _apiKey = ApiKeys.googleMaps;

  GeocodingService({Dio? dio}) : _dio = dio ?? Dio();

  /// Performs reverse geocoding with Address Descriptors (Landmarks).
  ///
  /// Falls back to formatted_address if address_descriptors are not available.
  Future<String> reverseGeocode(LatLng location, {CancelToken? cancelToken}) async {
    print('🔍 GeocodingService: Reverse geocoding for ${location.latitude}, ${location.longitude}');
    try {
      final response = await _dio.get(
        'https://maps.googleapis.com/maps/api/geocode/json',
        queryParameters: {
          'latlng': '${location.latitude},${location.longitude}',
          'key': _apiKey,
          'extra_computations': 'ADDRESS_DESCRIPTORS',
        },
        cancelToken: cancelToken,
        options: Options(
          headers: {
            'X-Android-Package': 'com.msaratwasel.user',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == 'OK') {
          final results = data['results'] as List;
          if (results.isEmpty) return 'Unknown Location';

          final firstResult = results.first;
          final addressDescriptors = firstResult['address_descriptors'];

          if (addressDescriptors != null) {
            final landmarks = addressDescriptors['landmarks'] as List?;
            if (landmarks != null && landmarks.isNotEmpty) {
              final landmark = landmarks.first;
              final name = landmark['display_name']['text'];
              final spatialRelationship = landmark['spatial_relationship'];
              
              final relation = _mapSpatialRelationship(spatialRelationship);
              return '$relation $name';
            }
          }

          return firstResult['formatted_address'] ?? 'Unknown Location';
        }
      }
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) {
        print('🔍 GeocodingService: Request cancelled');
      } else {
        print('❌ GeocodingService Error: $e');
      }
    }
    return 'Unknown Location';
  }

  String _mapSpatialRelationship(String? relationship) {
    switch (relationship) {
      case 'NEAR': return 'Near';
      case 'WITHIN': return 'In';
      case 'BESIDE': return 'Beside';
      case 'ACROSS_THE_ROAD': return 'Across from';
      case 'DOWN_THE_ROAD': return 'Down from';
      case 'AROUND_THE_CORNER': return 'Around the corner from';
      case 'BEHIND': return 'Behind';
      default: return 'Near';
    }
  }
}
