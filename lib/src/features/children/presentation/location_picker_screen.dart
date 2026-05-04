import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:msaratwasel_user/src/shared/localization/app_strings.dart';
import 'package:msaratwasel_user/src/shared/theme/app_colors.dart';
import 'package:msaratwasel_user/src/shared/theme/app_spacing.dart';
import 'package:msaratwasel_user/src/features/children/presentation/location_picker_controller.dart';

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
  late final LocationPickerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = LocationPickerController(
      initialLocation: widget.initialLocation,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Scaffold(
          resizeToAvoidBottomInset: false,
          body: Stack(
            children: [
              // 1. Map Layer
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _controller.selectedLocation,
                  zoom: 14,
                ),
                onMapCreated: _controller.setMapController,
                onLongPress: widget.isReadOnly ? null : _controller.onLongPress,
                onCameraMove: (position) {
                  // We update position target for the marker but don't geocode every time
                  // unless we want a center-pin behavior. The user asked for onLongPress
                  // for manual pin drop.
                },
                markers: {
                  Marker(
                    markerId: const MarkerId('selected-location'),
                    position: _controller.selectedLocation,
                    draggable: !widget.isReadOnly,
                    onDragEnd: (newPosition) => _controller.onLongPress(newPosition),
                  ),
                },
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                padding: EdgeInsets.only(
                  top: topPadding + 80,
                  bottom: widget.isReadOnly ? 0 : 220,
                ),
              ),

              // 2. Loading Feedback for Geocoding
              if (_controller.isGeocoding)
                Positioned(
                  bottom: widget.isReadOnly ? 100 : 310,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            context.t('fetchingAddress'),
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // 3. Header (Search Bar)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildHeader(context, isDark, topPadding),
              ),

              // 4. My Location Button
              Positioned(
                right: AppSpacing.lg,
                bottom: widget.isReadOnly ? AppSpacing.lg : 250,
                child: FloatingActionButton(
                  heroTag: 'my_location_btn',
                  onPressed: () => _controller.moveToMyLocation(context),
                  backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  elevation: 4,
                  child: const Icon(
                    Icons.my_location_rounded,
                    color: AppColors.primary,
                  ),
                ),
              ),

              // 5. Bottom Confirmation Sheet
              if (!widget.isReadOnly)
                _buildBottomActions(context, isDark),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, double topPadding) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: topPadding + AppSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Container(
            decoration: BoxDecoration(
              color: (isDark ? const Color(0xFF1E293B) : Colors.white).withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: AppColors.primary,
                  onPressed: () => Navigator.pop(context),
                ),
                Container(height: 24, width: 1, color: isDark ? Colors.white24 : Colors.black12),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: TextField(
                    controller: _controller.searchController,
                    onChanged: _controller.onSearchChanged,
                    readOnly: widget.isReadOnly,
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: context.t('searchLocation'),
                      hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                if (_controller.searchController.text.isNotEmpty && !widget.isReadOnly)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    color: Colors.grey,
                    onPressed: () => _controller.onSearchChanged(''),
                  ),
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: AppSpacing.md),
                  child: _controller.isSearching
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.search_rounded, color: AppColors.primary),
                ),
              ],
            ),
          ),
        ),

        // Suggestions Overlay
        if (_controller.predictions.isNotEmpty)
          _buildSuggestions(isDark),
      ],
    );
  }

  Widget _buildSuggestions(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 250),
        decoration: BoxDecoration(
          color: (isDark ? const Color(0xFF1E293B) : Colors.white).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)],
        ),
        child: ListView.separated(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          itemCount: _controller.predictions.length,
          separatorBuilder: (_, __) => Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
          itemBuilder: (context, index) {
            final p = _controller.predictions[index];
            return ListTile(
              dense: true,
              leading: const Icon(Icons.location_on_outlined, color: Colors.grey, size: 20),
              title: Text(p.mainText, style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.bold)),
              subtitle: Text(p.secondaryText, style: TextStyle(color: isDark ? Colors.white60 : Colors.grey, fontSize: 12)),
              onTap: () => _controller.selectPlace(p),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context, bool isDark) {
    return Positioned(
      left: AppSpacing.lg,
      right: AppSpacing.lg,
      bottom: AppSpacing.xl + MediaQuery.of(context).viewInsets.bottom,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Note Field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)],
            ),
            child: TextField(
              controller: _controller.noteController,
              style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: context.t('locationNoteHint'),
                hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey),
                border: InputBorder.none,
                icon: Icon(Icons.note_alt_outlined, color: isDark ? Colors.white70 : Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Confirm Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context, {
                  'location': _controller.selectedLocation,
                  'note': _controller.noteController.text.trim(),
                  'label': _controller.addressLabel,
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(context.t('confirmLocation'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
