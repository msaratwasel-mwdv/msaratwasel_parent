import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:msaratwasel_user/src/core/config/api_keys.dart';

class PlacesService {
  final Dio _dio;
  final String _apiKey = ApiKeys.googleMaps;

  PlacesService({Dio? dio}) : _dio = dio ?? Dio();

  /// Fetches autocomplete predictions using the Places API (New).
  ///
  /// [query]: The search input.
  /// [sessionToken]: A UUID for cost grouping.
  Future<List<PlacePrediction>> getPredictions(
    String query,
    String sessionToken, {
    CancelToken? cancelToken,
  }) async {
    print('🔍 PlacesService: Fetching predictions for "$query"');

    try {
      final response = await _dio.post(
        'https://places.googleapis.com/v1/places:autocomplete',
        data: {
          'input': query,
          'sessionToken': sessionToken,
          'locationBias': {
            'circle': {
              'center': {'latitude': 23.5859, 'longitude': 58.4059},
              'radius': 5000.0,
            }
          },
        },
        cancelToken: cancelToken,
        options: Options(
          headers: {
            'X-Goog-Api-Key': _apiKey,
            'Content-Type': 'application/json',
            'X-Android-Package': 'com.msaratwasel.user',
          },
        ),
      );

      if (response.statusCode == 200) {
        final suggestions = response.data['suggestions'] as List?;
        if (suggestions == null) return [];
        return suggestions
            .where((s) => s['placePrediction'] != null)
            .map((s) => PlacePrediction.fromNewApiJson(s['placePrediction']))
            .toList();
      }
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) {
        print('🔍 PlacesService: Request cancelled');
      } else {
        print('❌ PlacesService Error: $e');
      }
    }
    return [];
  }

  /// Fetches place details (Coordinates) using the Places API (New).
  Future<LatLng?> getPlaceDetails(
    String placeId,
    String sessionToken, {
    CancelToken? cancelToken,
  }) async {
    print('🔍 PlacesService: Fetching details for $placeId');
    try {
      final response = await _dio.get(
        'https://places.googleapis.com/v1/places/$placeId',
        queryParameters: {
          'sessionToken': sessionToken,
        },
        cancelToken: cancelToken,
        options: Options(
          headers: {
            'X-Goog-Api-Key': _apiKey,
            'X-Goog-FieldMask': 'id,displayName,location',
            'X-Android-Package': 'com.msaratwasel.user',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final location = data['location'];
        if (location != null) {
          return LatLng(location['latitude'], location['longitude']);
        }
      }
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) {
        print('🔍 PlacesService: Details request cancelled');
      } else {
        print('❌ PlacesService Details Error: $e');
      }
    }
    return null;
  }
}

class PlacePrediction {
  final String placeId;
  final String mainText;
  final String secondaryText;
  final String fullText;

  PlacePrediction({
    required this.placeId,
    required this.mainText,
    required this.secondaryText,
    required this.fullText,
  });

  factory PlacePrediction.fromNewApiJson(Map<String, dynamic> json) {
    final structured = json['structuredFormat'] ?? {};
    return PlacePrediction(
      placeId: json['placeId'] ?? '',
      mainText: structured['mainText']?['text'] ?? '',
      secondaryText: structured['secondaryText']?['text'] ?? '',
      fullText: json['text']?['text'] ?? '',
    );
  }

  // Keep old factory for compatibility during refactor if needed
  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    final structured = json['structured_formatting'] ?? {};
    return PlacePrediction(
      placeId: json['place_id'] ?? '',
      mainText: structured['main_text'] ?? '',
      secondaryText: structured['secondary_text'] ?? '',
      fullText: json['description'] ?? '',
    );
  }
}
