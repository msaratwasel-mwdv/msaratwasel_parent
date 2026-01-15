import 'package:flutter/material.dart';
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

class TrackingPage extends StatefulWidget {
  const TrackingPage({super.key});

  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  bool detailsVisible = true;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final tracking = controller.currentTracking;
        final isArabic = controller.locale.languageCode == 'ar';
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Scaffold(
          body: Stack(
            children: [
              Positioned.fill(
                child: _TrackingMap(students: controller.students),
              ),
              // Menu button at top-right (RTL)
              Positioned(
                top: MediaQuery.of(context).padding.top + AppSpacing.sm,
                right: AppSpacing.md,
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
                right: AppSpacing.lg + 60, // Offset for menu button (RTL)
                left: AppSpacing.lg,
                child: Row(
                  children: [
                    _Pill(
                      icon: Icons.circle,
                      iconColor: Colors.greenAccent,
                      label: Labels.busState(
                        tracking.busState,
                        arabic: isArabic,
                      ),
                    ),
                    const Spacer(),
                    _Pill(
                      icon: Icons.my_location_rounded,
                      label: isArabic ? 'تحديث' : 'Refresh',
                      subtle: true,
                    ),
                  ],
                ),
              ),
              // Card aligns to bottom - no external sliding, internal animation used
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    0,
                    AppSpacing.xl,
                    AppSpacing.xl,
                  ),
                  child: _BottomDetailsCard(
                    tracking: tracking,
                    isArabic: isArabic,
                    isOpen: detailsVisible,
                    onToggle: () =>
                        setState(() => detailsVisible = !detailsVisible),
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

  @override
  void initState() {
    super.initState();
    _loadMarkers();
  }

  @override
  void didUpdateWidget(covariant _TrackingMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.students != widget.students) {
      _loadMarkers();
    }
  }

  Future<void> _loadMarkers() async {
    final newMarkers = <String, BitmapDescriptor>{};
    for (final student in widget.students) {
      try {
        final marker =
            await StudentMarkerWidget(
              name: student.name,
              imageUrl: student.avatarUrl,
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

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final markers = <Marker>{};

    // Calculate bounding box to include all buses
    LatLngBounds? bounds;

    for (var i = 0; i < widget.students.length; i++) {
      final student = widget.students[i];
      final tracking = controller.trackingForStudent(student.id);

      // Offset logic:
      // If multiple students are on the same bus (same lat/lng), apply a small offset.
      // We can use a simple deterministic offset based on index.
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

      // Update bounds
      if (bounds == null) {
        bounds = LatLngBounds(southwest: position, northeast: position);
      } else {
        bounds = LatLngBounds(
          southwest: LatLng(
            position.latitude < bounds.southwest.latitude
                ? position.latitude
                : bounds.southwest.latitude,
            position.longitude < bounds.southwest.longitude
                ? position.longitude
                : bounds.southwest.longitude,
          ),
          northeast: LatLng(
            position.latitude > bounds.northeast.latitude
                ? position.latitude
                : bounds.northeast.latitude,
            position.longitude > bounds.northeast.longitude
                ? position.longitude
                : bounds.northeast.longitude,
          ),
        );
      }
    }

    final primaryTracking = controller.currentTracking;
    final primaryPos = LatLng(primaryTracking.lat, primaryTracking.lng);

    return GoogleMap(
      initialCameraPosition: CameraPosition(target: primaryPos, zoom: 14),
      markers: markers,
      myLocationEnabled: true,
      zoomControlsEnabled: false,
      compassEnabled: true,
      mapToolbarEnabled: false,
    );
  }
}

class _BottomDetailsCard extends StatelessWidget {
  const _BottomDetailsCard({
    required this.tracking,
    required this.isArabic,
    required this.isOpen,
    required this.onToggle,
  });

  final TrackingSnapshot tracking;
  final bool isArabic;
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
                  child: const CircleAvatar(
                    radius: 24,
                    backgroundImage: NetworkImage(
                      'https://i.pravatar.cc/150?u=driver',
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.t('driverName'), // "Mohamed Abdullah"
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '0551234567',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? Colors.white70
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
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
