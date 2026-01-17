import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:msaratwasel_user/src/core/config/api_keys.dart';

class PlacesService {
  final Dio _dio = Dio();
  // Using ApiKeys for centralized key management
  final String _apiKey = ApiKeys.googleMaps;

  Future<List<PlacePrediction>> getPredictions(
    String input,
    String lang,
  ) async {
    if (input.isEmpty) return [];

    try {
      final response = await _dio.get(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json',
        queryParameters: {
          'input': input,
          'key': _apiKey,
          'language': lang,
          'components': 'country:sa', // Limit to Saudi Arabia for relevance
        },
      );

      if (response.statusCode == 200) {
        final predictions = response.data['predictions'] as List;
        return predictions.map((p) => PlacePrediction.fromJson(p)).toList();
      }
    } catch (e) {
      // ignore silently for UI smoothness
    }
    return [];
  }

  Future<LatLng?> getPlaceDetails(String placeId) async {
    try {
      final response = await _dio.get(
        'https://maps.googleapis.com/maps/api/place/details/json',
        queryParameters: {
          'place_id': placeId,
          'key': _apiKey,
          'fields': 'geometry', // minimal fields to save cost
        },
      );

      if (response.statusCode == 200) {
        final result = response.data['result'];
        final location = result['geometry']['location'];
        return LatLng(location['lat'], location['lng']);
      }
    } catch (e) {
      // ignore
    }
    return null;
  }
}

class PlacePrediction {
  final String description;
  final String placeId;
  final String mainText;
  final String secondaryText;

  PlacePrediction({
    required this.description,
    required this.placeId,
    required this.mainText,
    required this.secondaryText,
  });

  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    final structured = json['structured_formatting'] ?? {};
    return PlacePrediction(
      description: json['description'] ?? '',
      placeId: json['place_id'] ?? '',
      mainText: structured['main_text'] ?? '',
      secondaryText: structured['secondary_text'] ?? '',
    );
  }
}
