import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:msaratwasel_user/src/shared/localization/app_strings.dart';
import 'package:msaratwasel_user/src/shared/theme/app_colors.dart';
import 'package:msaratwasel_user/src/shared/theme/app_spacing.dart';
import 'package:msaratwasel_user/src/shared/services/places_service.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({
    super.key,
    this.initialLocation,
    this.isReadOnly = false,
  });

  final LatLng? initialLocation;
  final bool isReadOnly;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  late LatLng _selectedLocation;
  // Default to Riyadh center if no location provided
  static const LatLng _defaultLocation = LatLng(24.7136, 46.6753);
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final PlacesService _placesService = PlacesService();

  GoogleMapController? _mapController;
  Timer? _debounce;
  List<PlacePrediction> _predictions = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation ?? _defaultLocation;
  }

  @override
  void dispose() {
    _noteController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (widget.isReadOnly) return;
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.isEmpty) {
        setState(() => _predictions = []);
        return;
      }

      setState(() => _isSearching = true);
      // Determine language based on context (simplified check here, mostly likely Ar or En)
      final isArabic = Localizations.localeOf(context).languageCode == 'ar';
      final results = await _placesService.getPredictions(
        query,
        isArabic ? 'ar' : 'en',
      );

      if (mounted) {
        setState(() {
          _predictions = results;
          _isSearching = false;
        });
      }
    });
  }

  Future<void> _selectPlace(PlacePrediction place) async {
    // Hide keyboard
    FocusManager.instance.primaryFocus?.unfocus();
    // Clear predictions
    setState(() {
      _predictions = [];
      _searchController.text = place.mainText;
    });

    final location = await _placesService.getPlaceDetails(place.placeId);
    if (location != null && _mapController != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(location, 16));
      setState(() => _selectedLocation = location);
    }
  }

  Future<void> _moveToMyLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Show error or request to enable
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition();
      final latLng = LatLng(position.latitude, position.longitude);

      if (_mapController != null) {
        _mapController!.animateCamera(CameraUpdate.newLatLngZoom(latLng, 16));
        if (!widget.isReadOnly) {
          setState(() => _selectedLocation = latLng);
        }
      }
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 1. Map Layer
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedLocation,
              zoom: 14,
            ),
            onMapCreated: (controller) => _mapController = controller,
            onCameraMove: (position) {
              if (!widget.isReadOnly) {
                _selectedLocation = position.target;
              }
            },
            markers: widget.isReadOnly
                ? {
                    Marker(
                      markerId: const MarkerId('selected-location'),
                      position: _selectedLocation,
                    ),
                  }
                : {},
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            padding: EdgeInsets.only(
              top: topPadding + 80,
              bottom: widget.isReadOnly ? 0 : 200,
            ),
          ),

          // 2. Center Pin (Static) - Only if NOT Read Only
          if (!widget.isReadOnly) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 40),
                child: Icon(
                  Icons.location_pin,
                  size: 56,
                  color: AppColors.primary,
                ),
              ),
            ),
            Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ],

          // 3. Header (Search or Title)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: widget.isReadOnly
                // Read Only Header
                ? Container(
                    padding: EdgeInsets.only(
                      top: topPadding + AppSpacing.md,
                      bottom: AppSpacing.md,
                      left: AppSpacing.lg,
                      right: AppSpacing.lg,
                    ),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color:
                                (isDark
                                        ? const Color(0xFF1E293B)
                                        : Colors.white)
                                    .withValues(alpha: 0.95),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_rounded),
                            color: AppColors.primary,
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color:
                                (isDark
                                        ? const Color(0xFF1E293B)
                                        : Colors.white)
                                    .withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(50),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Text(
                            context.t('homeLocation'),
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                // Search Bar for Picker
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: topPadding + AppSpacing.md),
                      // Search Bar
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color:
                                (isDark
                                        ? const Color(0xFF1E293B)
                                        : Colors.white)
                                    .withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(
                              50,
                            ), // Stadium Shape
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                            border: isDark
                                ? Border.all(
                                    color: Colors.white.withValues(alpha: 0.1),
                                  )
                                : null,
                          ),
                          child: Row(
                            children: [
                              // Trailing Back Button (Left in LTR, Right in RTL automatically handled by Row)
                              IconButton(
                                icon: const Icon(Icons.arrow_back_rounded),
                                color: AppColors.primary,
                                onPressed: () => Navigator.pop(context),
                              ),

                              // Separator
                              Container(
                                height: 24,
                                width: 1,
                                color: isDark ? Colors.white24 : Colors.black12,
                              ),
                              const SizedBox(width: AppSpacing.md),

                              // Input Field
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  onChanged: _onSearchChanged,
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: context.t('searchLocation'),
                                    hintStyle: TextStyle(
                                      color: isDark
                                          ? Colors.white38
                                          : Colors.grey,
                                      fontWeight: FontWeight.normal,
                                    ),
                                    // Crucial: No internal borders
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    errorBorder: InputBorder.none,
                                    disabledBorder: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),

                              // Trailing Icons (Clear or Search/Loading)
                              if (_searchController.text.isNotEmpty)
                                IconButton(
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    size: 20,
                                  ),
                                  color: Colors.grey,
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _predictions = []);
                                  },
                                ),

                              Padding(
                                padding: const EdgeInsetsDirectional.only(
                                  end: AppSpacing.md,
                                ),
                                child: _isSearching
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.search_rounded,
                                        color: AppColors.primary,
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Predictions List Overlay
                      if (_predictions.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.sm,
                          ),
                          child: Container(
                            constraints: const BoxConstraints(maxHeight: 250),
                            decoration: BoxDecoration(
                              color:
                                  (isDark
                                          ? const Color(0xFF1E293B)
                                          : Colors.white)
                                      .withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ListView.separated(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: _predictions.length,
                              separatorBuilder: (context, index) => Divider(
                                height: 1,
                                color: isDark ? Colors.white10 : Colors.black12,
                              ),
                              itemBuilder: (context, index) {
                                final p = _predictions[index];
                                return ListTile(
                                  dense: true,
                                  leading: const Icon(
                                    Icons.location_on_outlined,
                                    color: Colors.grey,
                                    size: 20,
                                  ),
                                  title: Text(
                                    p.mainText,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white
                                          : AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    p.secondaryText,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white60
                                          : Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                  onTap: () => _selectPlace(p),
                                );
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
          ),

          // 4. My Location Button
          Positioned(
            right: AppSpacing.lg,
            bottom: widget.isReadOnly ? AppSpacing.lg : 240, // Adjust position
            child: FloatingActionButton(
              heroTag: 'my_location_btn',
              onPressed: _moveToMyLocation,
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              elevation: 4,
              child: const Icon(
                Icons.my_location_rounded,
                color: AppColors.primary,
              ),
            ),
          ),

          // 5. Bottom Sheet (Confirmation) - Only if NOT Read Only
          if (!widget.isReadOnly)
            Positioned(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: AppSpacing.xl + MediaQuery.of(context).viewInsets.bottom,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: isDark
                          ? Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                            )
                          : null,
                    ),
                    child: TextField(
                      controller: _noteController,
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: context.t('locationNoteHint'),
                        hintStyle: TextStyle(
                          color: isDark ? Colors.white38 : Colors.grey,
                        ),
                        border: InputBorder.none,
                        icon: Icon(
                          Icons.note_alt_outlined,
                          color: isDark ? Colors.white70 : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, {
                          'location': _selectedLocation,
                          'note': _noteController.text.trim(),
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        shadowColor: AppColors.primary.withValues(alpha: 0.4),
                      ),
                      child: Text(
                        context.t('confirmLocation'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
