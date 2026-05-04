import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import 'package:msaratwasel_user/src/shared/services/places_service.dart';
import 'package:msaratwasel_user/src/shared/services/geocoding_service.dart';

/// A production-ready controller for picking locations.
///
/// Handles search, autocomplete, and map navigation with robust lifecycle management
/// to prevent "used after disposed" errors and stale data updates.
class LocationPickerController extends ChangeNotifier {
  LocationPickerController({
    PlacesService? placesService,
    GeocodingService? geocodingService,
    LatLng? initialLocation,
  })  : _placesService = placesService ?? PlacesService(),
        _geocodingService = geocodingService ?? GeocodingService(),
        _selectedLocation = initialLocation ?? const LatLng(23.5859, 58.4059) {
    if (initialLocation != null) {
      _reverseGeocode(initialLocation);
    }
  }

  final PlacesService _placesService;
  final GeocodingService _geocodingService;
  final Uuid _uuid = const Uuid();

  GoogleMapController? _mapController;
  final TextEditingController searchController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  LatLng _selectedLocation;
  LatLng get selectedLocation => _selectedLocation;

  String? _sessionToken;
  Timer? _debounce;
  int _requestCount = 0;
  bool _isDisposed = false;

  // Dio cancellation tokens for active requests
  CancelToken? _autocompleteToken;
  CancelToken? _detailsToken;
  CancelToken? _geocodingToken;

  List<PlacePrediction> _predictions = [];
  List<PlacePrediction> get predictions => _predictions;

  bool _isSearching = false;
  bool get isSearching => _isSearching;

  bool _isGeocoding = false;
  bool get isGeocoding => _isGeocoding;

  String? _addressLabel;
  String? get addressLabel => _addressLabel;

  LatLng? _lastGeocodedLatLng;
  static const double _geocodeThresholdMeters = 5.0;

  /// Registers the GoogleMapController. 
  /// Disposes it immediately if the parent controller is already disposed.
  void setMapController(GoogleMapController controller) {
    if (_isDisposed) {
      controller.dispose();
      return;
    }
    _mapController = controller;
  }

  /// Safety wrapper for notifyListeners to prevent crashes after disposal.
  void _safeNotifyListeners() {
    if (!_isDisposed) notifyListeners();
  }

  /// Handles search input changes with debounce and session token management.
  void onSearchChanged(String query) {
    if (_isDisposed) return;
    
    _debounce?.cancel();
    if (query.isEmpty) {
      _predictions = [];
      _isSearching = false;
      _sessionToken = null;
      _autocompleteToken?.cancel();
      _safeNotifyListeners();
      return;
    }

    _sessionToken ??= _uuid.v4();
    _debounce = Timer(const Duration(milliseconds: 300), () => _fetchPredictions(query));
  }

  Future<void> _fetchPredictions(String query) async {
    if (_isDisposed) return;

    final currentRequest = ++_requestCount;
    _isSearching = true;
    _safeNotifyListeners();

    // Cancel previous autocomplete request to save bandwidth and prevent stale responses
    _autocompleteToken?.cancel();
    _autocompleteToken = CancelToken();

    try {
      final results = await _placesService.getPredictions(
        query, 
        _sessionToken!, 
        cancelToken: _autocompleteToken,
      );

      // Guard: Halt if disposed or if a newer request has already been started
      if (_isDisposed || currentRequest != _requestCount) return;

      _predictions = results;
      _isSearching = false;
      _safeNotifyListeners();
    } catch (e) {
      if (_isDisposed) return;
      _isSearching = false;
      _safeNotifyListeners();
    }
  }

  /// Handles place selection from autocomplete results.
  Future<void> selectPlace(PlacePrediction prediction) async {
    if (_isDisposed) return;

    final token = _sessionToken ?? _uuid.v4();
    _isSearching = true;
    _predictions = [];
    searchController.text = prediction.mainText;
    _safeNotifyListeners();

    _detailsToken?.cancel();
    _detailsToken = CancelToken();

    try {
      final location = await _placesService.getPlaceDetails(
        prediction.placeId, 
        token,
        cancelToken: _detailsToken,
      );
      
      if (_isDisposed) return;

      // Clear session after final billable call
      _sessionToken = null;
      _isSearching = false;

      if (location != null) {
        _updateLocation(location, label: prediction.fullText);
        _animateToLocation(location);
      } else {
        _safeNotifyListeners();
      }
    } catch (e) {
      if (_isDisposed) return;
      _isSearching = false;
      _safeNotifyListeners();
    }
  }

  /// Handles manual pin drop via long press.
  void onLongPress(LatLng location) {
    if (_isDisposed) return;
    _updateLocation(location);
    _reverseGeocode(location);
  }

  /// Moves camera to user's current location with permissions check.
  Future<void> moveToMyLocation(BuildContext context) async {
    if (_isDisposed) return;

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (context.mounted) _showSnackBar(context, 'Location services are disabled.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (context.mounted) _showSnackBar(context, 'Location permissions are denied.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (context.mounted) _showSnackBar(context, 'Location permissions are permanently denied.');
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      if (_isDisposed) return;

      final latLng = LatLng(position.latitude, position.longitude);
      
      _animateToLocation(latLng);
      _updateLocation(latLng);
      _reverseGeocode(latLng);
    } catch (e) {
      if (!_isDisposed && context.mounted) {
        _showSnackBar(context, 'Could not fetch current location.');
      }
    }
  }

  void _updateLocation(LatLng location, {String? label}) {
    if (_isDisposed) return;
    _selectedLocation = location;
    if (label != null) {
      _addressLabel = label;
      searchController.text = label;
    }
    _safeNotifyListeners();
  }

  /// Performs reverse geocoding with threshold-based protection.
  Future<void> _reverseGeocode(LatLng location) async {
    if (_isDisposed) return;

    // Protection against tiny map jitters causing redundant API calls
    if (_lastGeocodedLatLng != null) {
      final distance = Geolocator.distanceBetween(
        _lastGeocodedLatLng!.latitude,
        _lastGeocodedLatLng!.longitude,
        location.latitude,
        location.longitude,
      );
      if (distance < _geocodeThresholdMeters) return;
    }

    _isGeocoding = true;
    _lastGeocodedLatLng = location;
    _safeNotifyListeners();

    _geocodingToken?.cancel();
    _geocodingToken = CancelToken();

    try {
      final address = await _geocodingService.reverseGeocode(
        location,
        cancelToken: _geocodingToken,
      );
      
      if (_isDisposed) return;

      _addressLabel = address;
      searchController.text = address;
      _isGeocoding = false;
      _safeNotifyListeners();
    } catch (e) {
      if (_isDisposed) return;
      _isGeocoding = false;
      _safeNotifyListeners();
    }
  }

  void _animateToLocation(LatLng location) {
    if (_isDisposed) return;
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(location, 16));
  }

  void _showSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _debounce?.cancel();
    _autocompleteToken?.cancel();
    _detailsToken?.cancel();
    _geocodingToken?.cancel();
    searchController.dispose();
    noteController.dispose();
    _mapController?.dispose();
    super.dispose();
  }
}
