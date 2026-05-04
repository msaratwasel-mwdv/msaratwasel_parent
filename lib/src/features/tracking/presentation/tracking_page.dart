import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/core/models/app_models.dart';
import 'package:msaratwasel_user/src/shared/localization/app_strings.dart';
import 'package:msaratwasel_user/src/shared/theme/app_colors.dart';
import 'package:msaratwasel_user/src/shared/theme/app_spacing.dart';
import 'package:msaratwasel_user/src/shared/utils/date_utils.dart'
    as date_utils;
import 'package:msaratwasel_user/src/shared/utils/labels.dart';
import 'package:msaratwasel_user/src/features/tracking/presentation/widgets/student_marker_widget.dart';
import 'package:widget_to_marker/widget_to_marker.dart';
import 'package:msaratwasel_user/src/shared/widgets/address_display.dart';

class TrackingPage extends StatefulWidget {
  const TrackingPage({super.key});

  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  bool detailsVisible = true;
  AppController? _appController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _appController = AppScope.of(context);
    _appController?.startTrackingPoll();
  }

  @override
  void dispose() {
    _appController?.stopTrackingPoll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final tracking = controller.currentTracking;
        final isArabic = controller.locale.languageCode == 'ar';
        final isDark = Theme.of(context).brightness == Brightness.dark;

        // While children are loading, show a placeholder
        if (tracking == null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(isArabic ? 'جاري تحميل بيانات التتبع...' : 'Loading tracking data...'),
                ],
              ),
            ),
          );
        }

        // At this point tracking is non-null (narrowed)
        final trackingData = tracking;

        return Scaffold(
          body: Stack(
            children: [
              Positioned.fill(
                child: _TrackingMap(students: controller.students),
              ),
              // Menu button (Adaptive Start position)
              PositionedDirectional(
                top: MediaQuery.of(context).padding.top + AppSpacing.sm,
                start: AppSpacing.md,
                child: Material(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  shape: const CircleBorder(),
                  elevation: 4,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => Scaffold.of(context).openDrawer(),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Icon(
                        Icons.menu_rounded,
                        color: isDark ? Colors.white : AppColors.primary,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + AppSpacing.lg,
                right: isArabic
                    ? AppSpacing.lg + 60
                    : AppSpacing.lg,
                left: isArabic ? AppSpacing.lg : AppSpacing.lg + 60,
                child: Row(
                  children: [
                    _Pill(
                      icon: Icons.circle,
                      iconColor: Colors.greenAccent,
                      label: Labels.busState(
                        trackingData.busState,
                        arabic: isArabic,
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () => controller.startTrackingPoll(),
                      child: _Pill(
                        icon: Icons.refresh_rounded,
                        label: isArabic ? 'تحديث' : 'Refresh',
                        subtle: false,
                      ),
                    ),
                  ],
                ),
              ),
              // Card aligns to bottom
              Align(
                alignment: Alignment.bottomCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.45,
                  ),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xl,
                        0,
                        AppSpacing.xl,
                        AppSpacing.xl,
                      ),
                      child: _BottomDetailsCard(
                        tracking: trackingData,
                        isArabic: isArabic,
                        busNumber: trackingData.busNumber ??
                            controller.currentStudent?.bus.number ??
                            'N/A',
                        plateNumber: trackingData.plateNumber ??
                            controller.currentStudent?.bus.plate ??
                            'N/A',
                        isOpen: detailsVisible,
                        onToggle: () =>
                            setState(() => detailsVisible = !detailsVisible),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TrackingMap extends StatefulWidget {
  const _TrackingMap({required this.students});

  final List<Student> students;

  @override
  State<_TrackingMap> createState() => _TrackingMapState();
}

class _TrackingMapState extends State<_TrackingMap> {
  final Map<String, BitmapDescriptor> _markers = {};
  bool _markersLoaded = false;

  @override
  void initState() {
    super.initState();
    // Don't call _loadMarkers here - context is not ready for inherited widgets
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_markersLoaded) {
      _markersLoaded = true;
      final token = AppScope.of(context).token;
      _loadMarkers(token);
    }
  }

  @override
  void didUpdateWidget(covariant _TrackingMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.students != widget.students) {
      final token = AppScope.of(context).token;
      _loadMarkers(token);
    }
  }

  Future<void> _loadMarkers(String token) async {
    final newMarkers = <String, BitmapDescriptor>{};
    for (final student in widget.students) {
      try {
        final marker =
            await StudentMarkerWidget(
              name: student.name,
              imageUrl: student.avatarUrl,
              authToken: token,
            ).toBitmapDescriptor(
              logicalSize: const Size(100, 100),
              imageSize: const Size(200, 200),
            );
        newMarkers[student.id] = marker;
      } catch (e) {
        debugPrint('Error generating marker for ${student.name}: $e');
        // Fallback to default
        newMarkers[student.id] = BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueAzure,
        );
      }
    }

    if (mounted) {
      setState(() {
        _markers.clear();
        _markers.addAll(newMarkers);
      });
    }
  }

  GoogleMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final markers = <Marker>{};

    for (var i = 0; i < widget.students.length; i++) {
      final student = widget.students[i];
      final tracking = controller.trackingForStudent(student.id);

      // Skip students without real backend tracking data.
      // Do NOT show a bus marker unless location comes from backend.
      if (tracking == null) continue;

      // Offset logic:
      // If multiple students are on the same bus (same lat/lng), apply a small offset.
      // 0.00005 degrees is roughly 5 meters.
      final double offset = (i % 2 == 0 ? 1 : -1) * (i * 0.00005);
      final position = LatLng(tracking.lat + offset, tracking.lng + offset);

      markers.add(
        Marker(
          markerId: MarkerId('student_${student.id}'),
          position: position,
          infoWindow: InfoWindow(
            title: student.name,
            snippet: tracking.busState == BusState.enRoute
                ? 'Lat: ${tracking.lat}, Lng: ${tracking.lng}'
                : null,
          ),
          icon:
              _markers[student.id] ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );
    }

    final primaryTracking = controller.currentTracking;
    // Muscat coordinates used ONLY as initial map camera center for UI rendering.
    // This is NOT injected into tracking state or used as bus location.
    final primaryPos = primaryTracking != null
        ? LatLng(primaryTracking.lat, primaryTracking.lng)
        : const LatLng(23.5880, 58.3829); // Muscat — camera center only

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: primaryPos, zoom: 15),
          onCameraMove: (pos) => {}, // Logic to track if user is manual
          markers: markers,
          polylines: {
            if (primaryTracking != null &&
                primaryTracking.polylinePoints.isNotEmpty)
              Polyline(
                polylineId: const PolylineId('route'),
                points: primaryTracking.polylinePoints,
                color: AppColors.primary,
                width: 4,
                jointType: JointType.round,
                startCap: Cap.roundCap,
                endCap: Cap.roundCap,
              ),
          },
          myLocationEnabled: true,
          myLocationButtonEnabled: false, // Disable default button
          zoomControlsEnabled: false,
          compassEnabled: true,
          mapToolbarEnabled: false,
          onMapCreated: (controller) {
            _mapController = controller;
          },
        ),
        // Custom Location FAB
        PositionedDirectional(
          bottom: 230, // Position above the bottom card area
          end: AppSpacing.md,
          child: Material(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            shape: const CircleBorder(),
            elevation: 4,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                _mapController?.animateCamera(
                  CameraUpdate.newLatLng(primaryPos),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  Icons.my_location_rounded,
                  color: isDark ? Colors.white : AppColors.primary,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BottomDetailsCard extends StatelessWidget {
  const _BottomDetailsCard({
    required this.tracking,
    required this.isArabic,
    required this.busNumber,
    required this.plateNumber,
    required this.isOpen,
    required this.onToggle,
  });

  final TrackingSnapshot tracking;
  final bool isArabic;
  final String busNumber;
  final String plateNumber;
  final bool isOpen;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final paddingBottom = MediaQuery.of(context).padding.bottom;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // HEADER SECTION (Always Visible)
          SizedBox(
            height: 36, // Area for the drag handle
            child: Center(
              child: Container(
                width: 54,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.3)
                      : AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Driver Info
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? Colors.white24 : Colors.transparent,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    backgroundImage: (tracking.driverImageUrl != null && tracking.driverImageUrl!.isNotEmpty)
                        ? CachedNetworkImageProvider(
                            tracking.driverImageUrl!,
                            headers: AppScope.of(context).token.isNotEmpty
                                ? {'Authorization': 'Bearer ${AppScope.of(context).token}'}
                                : null,
                          )
                        : null,
                    child: (tracking.driverImageUrl == null || tracking.driverImageUrl!.isEmpty)
                        ? Icon(
                            Icons.person_rounded,
                            color: AppColors.primary,
                            size: 28,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tracking.driverName ?? context.t('driverName'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${context.t('busNumber')} $busNumber • $plateNumber',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark
                                ? Colors.white70
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // Toggle Button
                Material(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.grey.shade100,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onToggle,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Icon(
                        isOpen
                            ? Icons.keyboard_arrow_down_rounded
                            : Icons.keyboard_arrow_up_rounded,
                        color: isDark ? Colors.white : AppColors.primary,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // EXPANDABLE BODY SECTION
          AnimatedCrossFade(
            firstChild: const SizedBox(height: AppSpacing.md),
            secondChild: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.lg + paddingBottom,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      _TrackingStat(
                        icon: Icons.speed_rounded,
                        label: context.t('speed'),
                        value:
                            '${tracking.speedKmh.toStringAsFixed(0)} ${context.t('kmh')}',
                      ),
                      const SizedBox(width: AppSpacing.md),
                      _TrackingStat(
                        icon: Icons.route_rounded,
                        label: context.t('distance'),
                        value:
                            '${tracking.distanceKm.toStringAsFixed(1)} ${context.t('km')}',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      _TrackingStat(
                        icon: Icons.people_alt_rounded,
                        label: context.t('studentsOnBus'),
                        value: tracking.studentsOnBoard.toString(),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      // REPLACED Bus Status with Remaining Time
                      _TrackingStat(
                        icon: Icons.timer_rounded,
                        label: context.t('remainingTime'),
                        value:
                            '${tracking.etaMinutes} ${context.t('minutesSuffix')}',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AddressDisplay(lat: tracking.lat, lng: tracking.lng),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    '${context.t('updated')} ${date_utils.timeAgo(tracking.updatedAt, locale: isArabic ? 'ar' : 'en')}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark ? Colors.white60 : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            crossFadeState: isOpen
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
            alignment: Alignment.topCenter,
            sizeCurve: Curves.easeInOut,
          ),
        ],
      ),
    );
  }
}

class _TrackingStat extends StatelessWidget {
  const _TrackingStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Card(
        elevation: 0,
        color: isDark ? const Color(0xFF334155) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : AppColors.border,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? Colors.white70
                            : AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.icon,
    required this.label,
    this.iconColor = Colors.white,
    this.subtle = false,
  });

  final IconData icon;
  final String label;
  final Color iconColor;
  final bool subtle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: subtle ? Colors.white.withValues(alpha: 0.18) : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: subtle
              ? Colors.white.withValues(alpha: 0.3)
              : AppColors.border,
        ),
        boxShadow: subtle
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: subtle ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
