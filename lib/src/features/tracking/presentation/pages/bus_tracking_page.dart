import 'dart:async';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import '../../../../app/state/app_controller.dart';
import '../../../../core/models/app_models.dart';
import '../../../../core/config/app_config.dart';
import '../../../../shared/localization/app_strings.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../domain/entities/bus_tracking.dart';
import '../../domain/entities/bus_tracking_group.dart';
import '../../../../shared/utils/marker_generator.dart';
import '../../../../shared/widgets/user_avatar.dart';

class BusTrackingPage extends StatefulWidget {
  const BusTrackingPage({super.key});

  @override
  State<BusTrackingPage> createState() => _BusTrackingPageState();
}

class _BusTrackingPageState extends State<BusTrackingPage> {
  GoogleMapController? _mapController;
  bool _isPanelExpanded = true;
  MapType _currentMapType = MapType.normal;

  BitmapDescriptor? _busIcon;
  BitmapDescriptor? _homeIcon;
  BitmapDescriptor? _schoolIcon;
  final Map<String, BitmapDescriptor> _studentIcons = {};
  List<Student>? _lastStudents;

  // Road-following route state
  List<LatLng> _activeRoutePoints = [];
  final Map<String, List<LatLng>> _cachedRoutesToTarget = {}; // Cache to prevent Google Maps API exhaustion and flickering

  String? _remainingTime;
  DateTime? _lastRouteFetchTime;
  LatLng? _lastFetchTarget;
  bool _isFetchingRoute = false;

  bool _followBus = true;
  LatLng? _lastBusPosition;
  String? _lastActiveTargetStudentId;
  String? _lastSelectedBusId;
  bool? _wasActive;

  @override
  void initState() {
    super.initState();
    _loadCustomMarkers();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = AppScope.of(context);
    final selectedGroup = controller.selectedGroup;
    final authToken = controller.token;

    final isActive = selectedGroup?.isActiveTrip ?? false;
    if (_wasActive == true && !isActive) {
      _wasActive = isActive;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                controller.locale.languageCode == 'ar'
                    ? 'تم إنهاء الرحلة بنجاح.'
                    : 'The trip has been completed successfully.',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      });
      return;
    }
    _wasActive = isActive;

    // Reset and clear route state instantly when switching buses
    if (_lastSelectedBusId != selectedGroup?.busId) {
      _lastSelectedBusId = selectedGroup?.busId;
      _activeRoutePoints = [];

      _remainingTime = null;
      _lastRouteFetchTime = null;
      _lastFetchTarget = null;
      _lastBusPosition = null;
      _lastActiveTargetStudentId = null;
    }

    // Detect student list changes and update markers
    if (_lastStudents != selectedGroup?.students) {
      _lastStudents = selectedGroup?.students;
      if (_lastStudents != null) {
        _updateStudentMarkers(_lastStudents!, authToken);
      }
    }

    final tracking = selectedGroup?.tracking;
    if (tracking != null) {
      _fetchRoadFollowingRoute();

      // Auto-detect active target student and switch context when target changes
      if (tracking.targetLatitude != null && tracking.targetLongitude != null) {
        final targetLatLng = LatLng(tracking.targetLatitude!, tracking.targetLongitude!);
        Student? activeStudent;
        int activeIndex = -1;
        for (int i = 0; i < controller.students.length; i++) {
          final s = controller.students[i];
          if (_isStudentActiveTarget(s, targetLatLng)) {
            activeStudent = s;
            activeIndex = i;
            break;
          }
        }
        if (activeStudent != null) {
          if (_lastActiveTargetStudentId != activeStudent.id) {
            _lastActiveTargetStudentId = activeStudent.id;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              controller.selectStudent(activeIndex);
            });
          }
        } else {
          _lastActiveTargetStudentId = null;
        }
      } else {
        _lastActiveTargetStudentId = null;
      }

      final newPos = LatLng(tracking.latitude, tracking.longitude);
      if (_lastBusPosition != newPos) {
        _lastBusPosition = newPos;
        if (_followBus && _mapController != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _centerOnBus(tracking);
          });
        }
      }
    }
  }

  Future<void> _loadCustomMarkers() async {
    try {
      // Generate a nice bus marker using our generator
      _busIcon = await MarkerGenerator.createBusMarker(
        color: AppColors.primary,
        size: 30.0,
      );

      _homeIcon = await MarkerGenerator.createHomeMarker(
        color: Colors.orange,
        size: 25.0,
      );

      // Generate a nice school marker using our generator
      _schoolIcon = await MarkerGenerator.createSchoolMarker(
        color: Colors.purple,
        size: 25.0,
      );
    } catch (e) {
      debugPrint('Markers not found, using defaults: $e');
    }
    if (mounted) setState(() {});
  }

  LatLng? _parseLatLng(String? location) {
    if (location == null || location.isEmpty) return null;
    try {
      final parts = location.split(',');
      if (parts.length == 2) {
        final lat = double.tryParse(parts[0].trim());
        final lng = double.tryParse(parts[1].trim());
        if (lat != null && lng != null) {
          return LatLng(lat, lng);
        }
      }
    } catch (e) {
      debugPrint('Error parsing LatLng: $e');
    }
    return null;
  }

  Future<void> _updateStudentMarkers(
    List<Student> students,
    String authToken,
  ) async {
    if (!mounted) return;
    final languageCode = AppScope.of(context).locale.languageCode;
    for (final student in students) {
      if (!_studentIcons.containsKey(student.id)) {
        final studentName = student.getLocalizedName(languageCode);
        try {
          // Create marker for student using our generator
          final icon = await MarkerGenerator.createStudentMarker(
            name: studentName,
            imageUrl: student.avatarUrl,
            authToken: authToken,
            color: AppColors.accent,
            size: 22.0,
          );

          _studentIcons[student.id] = icon;
          if (mounted) setState(() {});
        } catch (e) {
          debugPrint('Error creating marker for $studentName: $e');
        }
      }
    }
  }

  void _centerOnBus(BusTracking? tracking) {
    if (_mapController == null) return;
    if (tracking == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t('busLocationNotAvailable'))),
      );
      return;
    }
    _mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(tracking.latitude, tracking.longitude),
        16.0,
      ),
    );
  }

  Future<void> _fetchRoadFollowingRoute() async {
    final controller = AppScope.of(context);
    final group = controller.selectedGroup;
    if (group == null || group.tracking == null) {
      if (_activeRoutePoints.isNotEmpty) {
        setState(() {
          _activeRoutePoints = [];

          _remainingTime = null;
        });
      }
      return;
    }

    final tracking = group.tracking!;
    final busPos = LatLng(tracking.latitude, tracking.longitude);

    // Determine target (final destination for this parent's perspective)
    // STRICT BINDING: STRICTLY only follow the driver's active destination target. No static/fallback lines!
    LatLng? target;
    if (tracking.targetLatitude != null && tracking.targetLongitude != null) {
      target = LatLng(tracking.targetLatitude!, tracking.targetLongitude!);
    }

    if (target == null) {
      if (_activeRoutePoints.isNotEmpty) {
        setState(() {
          _activeRoutePoints = [];

          _remainingTime = null;
        });
      }
      return;
    }

    if (_isFetchingRoute) return;

    final cacheKey = "${target.latitude},${target.longitude}";

    // Fast transition: If we have a cached route to this destination, show it immediately 
    if (_activeRoutePoints.isEmpty && _cachedRoutesToTarget.containsKey(cacheKey)) {
      if (mounted) {
        setState(() {
          _activeRoutePoints = _cachedRoutesToTarget[cacheKey]!;
        });
      }
    }

    // Throttle: Don't fetch more than once every 15 seconds unless target changed
    final now = DateTime.now();
    if (_lastRouteFetchTime != null &&
        now.difference(_lastRouteFetchTime!).inSeconds < 15 &&
        _lastFetchTarget == target) {
      return;
    }

    _isFetchingRoute = true;

    try {
      final dio = Dio();
      final response = await dio.get(
        'https://maps.googleapis.com/maps/api/directions/json',
        queryParameters: {
          'origin': '${busPos.latitude},${busPos.longitude}',
          'destination': '${target.latitude},${target.longitude}',
          'key': AppConfig.googleMapsApiKey,
          'mode': 'driving',
        },
      );

      if (response.statusCode == 200 && response.data['status'] == 'OK') {
        final route = response.data['routes'][0];
        final leg = route['legs'][0];
        final points = PolylinePoints.decodePolyline(
          route['overview_polyline']['points'],
        );

        if (mounted) {
          setState(() {
            _activeRoutePoints =
                points.map((p) => LatLng(p.latitude, p.longitude)).toList();
            _cachedRoutesToTarget[cacheKey] = _activeRoutePoints; // Save to cache

            _remainingTime = leg['duration']['text'];
            _lastRouteFetchTime = now;
            _lastFetchTarget = target;
          });
        }
      }
    } catch (e) {
      debugPrint('⚠️ [Tracking] Error fetching road route: $e');
    } finally {
      _isFetchingRoute = false;
    }
  }

  void _fitMapBounds(BusTrackingGroup? group) {
    if (_mapController == null || group == null || group.tracking == null)
      return;

    final List<LatLng> points = [];
    points.add(LatLng(group.tracking!.latitude, group.tracking!.longitude));

    for (final student in group.students) {
      if (student.hasLocation) {
        points.add(student.homeLocation!);
      }
      final schoolPos = _parseLatLng(student.schoolLocation);
      if (schoolPos != null) {
        points.add(schoolPos);
      }
    }

    if (points.length < 2) return;

    double? minLat, maxLat, minLng, maxLng;
    for (final point in points) {
      if (minLat == null || point.latitude < minLat) minLat = point.latitude;
      if (maxLat == null || point.latitude > maxLat) maxLat = point.latitude;
      if (minLng == null || point.longitude < minLng) minLng = point.longitude;
      if (maxLng == null || point.longitude > maxLng) maxLng = point.longitude;
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat!, minLng!),
          northeast: LatLng(maxLat!, maxLng!),
        ),
        80.0, // padding
      ),
    );
  }

  void _toggleMapType() {
    setState(() {
      _currentMapType = _currentMapType == MapType.normal
          ? MapType.hybrid
          : MapType.normal;
    });
  }

  Widget _buildInactiveTripAlert(BuildContext context) {
    final bool isArabic = AppScope.of(context).locale.languageCode == 'ar';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD), // Soft Amber background
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFEBAA), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFFFE8A1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFF856404), // Dark Amber
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic
                      ? 'لا توجد رحلة نشطة حالياً لهذه الحافلة'
                      : 'No active trip currently for this bus',
                  style: const TextStyle(
                    color: Color(0xFF856404),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isArabic
                      ? 'الموقع المعروض هو آخر موقع تم تسجيله للحافلة.'
                      : 'The displayed location is the last registered coordinate of the bus.',
                  style: const TextStyle(
                    color: Color(0xFF856404),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getNextStopName(BuildContext context, BusTrackingGroup group) {
    final tracking = group.tracking;
    final isArabic = AppScope.of(context).locale.languageCode == 'ar';
    if (tracking == null) return isArabic ? 'المدرسة' : 'School';

    if (tracking.targetLatitude != null && tracking.targetLongitude != null) {
      final targetLatLng = LatLng(tracking.targetLatitude!, tracking.targetLongitude!);
      for (final s in group.students) {
        if (_isStudentActiveTarget(s, targetLatLng)) {
          return s.getLocalizedName(AppScope.of(context).locale.languageCode);
        }
      }
    }
    return isArabic ? 'المدرسة' : 'School';
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final selectedGroup = controller.selectedGroup;
    final allGroups = controller.allTripGroups;

    return Directionality(
      textDirection: controller.locale.languageCode == 'ar'
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Stack(
          children: [
            _buildMap(selectedGroup),
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildTopNavBar(context),
                  ),
                  const SizedBox(height: 10),
                  _DynamicBusSelector(
                    groups: allGroups,
                    selectedId: selectedGroup?.busId,
                    onSelect: (id) => controller.selectBus(id),
                  ),
                  if (selectedGroup != null && !selectedGroup.isActiveTrip) ...[
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildInactiveTripAlert(context),
                    ),
                  ],
                ],
              ),
            ),
            if (selectedGroup != null && selectedGroup.isActiveTrip && _followBus && selectedGroup.tracking != null)
              Align(
                alignment: const Alignment(0, -0.22),
                child: SpeechBubble(
                  title: controller.locale.languageCode == 'ar' ? 'الوجهة القادمة' : 'Next Destination',
                  description: _getNextStopName(context, selectedGroup),
                  time: _remainingTime ?? (selectedGroup.tracking?.etaMinutes != null ? '${selectedGroup.tracking!.etaMinutes} ${context.t('minutesSuffix')}' : '--'),
                ),
              ),
            _buildMapControls(selectedGroup?.tracking),
            _DataDrivenPanel(
              group: selectedGroup,
              isExpanded: _isPanelExpanded,
              onToggle: () =>
                  setState(() => _isPanelExpanded = !_isPanelExpanded),
              parentStudents: controller.students,
              remainingTime: _remainingTime,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopNavBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;
    return ClipRRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: colors.scaffold.withAlpha(isDark ? 150 : 180),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _CircleHeaderButton(
                icon: Icons.menu,
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
              Text(
                context.t('busTracking'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colors.text,
                ),
              ),
              const SizedBox(width: 44), // Placeholder to keep title centered
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMap(BusTrackingGroup? group) {
    final tracking = group?.tracking;
    final Set<Marker> markers = {};
    final Set<Polyline> polylines = {};

    if (tracking != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('bus'),
          position: LatLng(tracking.latitude, tracking.longitude),
          icon:
              _busIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          anchor: const Offset(0.5, 0.9), // Anchor at the tip of the "nail"
          rotation: 0, // Keep pin upright for clarity
        ),
      );

      final List<LatLng> routePoints = [
        LatLng(tracking.latitude, tracking.longitude),
      ];
      for (var student in group?.students ?? []) {
        if (student.hasLocation) {
          final pos = student.homeLocation!;
          markers.add(
            Marker(
              markerId: MarkerId('student_${student.id}'),
              position: pos,
              icon:
                  _studentIcons[student.id] ??
                  _homeIcon ??
                  BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueOrange,
                  ),
              anchor: const Offset(0.5, 0.9), // Anchor at the tip of the pin
              infoWindow: InfoWindow(
                title: student.getLocalizedName(AppScope.of(context).locale.languageCode),
                snippet: context.t('homeLocation'),
              ),
            ),
          );
          routePoints.add(pos);
        }

        // Add School Marker if available
        if (student.schoolLocation != null) {
          final schoolPos = _parseLatLng(student.schoolLocation);
          if (schoolPos != null) {
            markers.add(
              Marker(
                markerId: MarkerId('school_${student.schoolId}'),
                position: schoolPos,
                icon:
                    _schoolIcon ??
                    BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueMagenta,
                    ),
                infoWindow: InfoWindow(
                  title: student.schoolName ?? context.t('school'),
                ),
              ),
            );
          }
        }
      }
      final firstStudent = group?.students.isNotEmpty == true
          ? group!.students.first
          : null;

      LatLng? target;
      if (tracking.targetLatitude != null && tracking.targetLongitude != null) {
        target = LatLng(tracking.targetLatitude!, tracking.targetLongitude!);
      }
      final fallbackDestination = target ?? firstStudent?.schoolCoords;

      final bool isTripActive = group?.isActiveTrip ?? false;

      if (isTripActive) {
        if (_activeRoutePoints.isNotEmpty) {
          polylines.add(
            Polyline(
              polylineId: const PolylineId('route'),
              points: _activeRoutePoints,
              color: const Color(0xFF1A73E8), // Vibrant blue
              width: 6,
              jointType: JointType.round,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
            ),
          );
        } else if (fallbackDestination != null) {
          polylines.add(
            Polyline(
              polylineId: const PolylineId('route'),
              points: [LatLng(tracking.latitude, tracking.longitude), fallbackDestination],
              color: const Color(0xFF1A73E8), // Vibrant blue
              width: 6,
              jointType: JointType.round,
              patterns: [PatternItem.dash(20), PatternItem.gap(10)], // Dotted straight line fallback
            ),
          );
        }
      }

      // Add School Marker if available (using first student's school as reference)
      if (firstStudent != null && firstStudent.schoolCoords != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('school'),
            position: firstStudent.schoolCoords!,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
            infoWindow: InfoWindow(title: firstStudent.schoolName ?? 'School'),
          ),
        );
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Listener(
      onPointerDown: (_) {
        if (_followBus) {
          setState(() {
            _followBus = false;
          });
        }
      },
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: tracking != null
              ? LatLng(tracking.latitude, tracking.longitude)
              : const LatLng(15.3694, 44.1910),
          zoom: 14,
        ),
        trafficEnabled: true,
        onMapCreated: (c) {
          _mapController = c;
          // Fit bounds on first load if we have a group
          if (group != null) {
            Future.delayed(const Duration(milliseconds: 500), () {
              _fitMapBounds(group);
            });
          }
        },
        style: isDark ? _darkMapStyle : null,
        markers: markers,
        polylines: polylines,
        mapType: _currentMapType,
        zoomControlsEnabled: false,
        myLocationButtonEnabled: false,
        mapToolbarEnabled: false,
      ),
    );
  }

  Widget _buildMapControls(BusTracking? tracking) {
    return Positioned(
      bottom: _isPanelExpanded ? 600 : 200,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Left: Centering Controls
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MapActionFab(
                icon: Icons.directions_bus_filled,
                label: context.t('bus'),
                onPressed: () {
                  setState(() {
                    _followBus = true;
                  });
                  _centerOnBus(tracking);
                },
              ),
              const SizedBox(height: 12),
              _MapActionFab(
                icon: Icons.zoom_out_map,
                label: context.t('showAll'),
                onPressed: () {
                  setState(() {
                    _followBus = false;
                  });
                  _fitMapBounds(AppScope.of(context).selectedGroup);
                },
              ),
            ],
          ),
          // Right: Layer & Navigation Controls
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MapActionFab(
                icon: _currentMapType == MapType.normal
                    ? Icons.layers_outlined
                    : Icons.layers,
                onPressed: _toggleMapType,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static const String _darkMapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [{"color": "#242f3e"}]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [{"color": "#242f3e"}]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#746855"}]
  },
  {
    "featureType": "administrative.locality",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#d59563"}]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#d59563"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [{"color": "#38414e"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#212a37"}]
  },
  {
    "featureType": "road",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#9ca5b3"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [{"color": "#746855"}]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [{"color": "#17263c"}]
  }
]
''';
}

class _DynamicBusSelector extends StatelessWidget {
  final List<BusTrackingGroup> groups;
  final String? selectedId;
  final Function(String) onSelect;

  const _DynamicBusSelector({
    required this.groups,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 105, // Increased height to prevent overflow
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: groups.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final group = groups[index];
          final isSelected = group.busId == selectedId;
          final String busDisplayName =
              (group.busNumber != null &&
                  group.busNumber!.isNotEmpty &&
                  group.busNumber != '-')
              ? group.busNumber!
              : group.busId;

          final isDark = Theme.of(context).brightness == Brightness.dark;
          final colors = isDark ? AppColors.dark : AppColors.light;

          return GestureDetector(
            onTap: () => onSelect(group.busId),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 160, // Slightly wider
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected 
                    ? (isDark ? Colors.white : AppColors.primary) 
                    : colors.card,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? AppColors.primary.withAlpha(50)
                        : Colors.black.withAlpha(5),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: isSelected
                      ? Colors.white.withAlpha(20)
                      : (isDark
                            ? Colors.white.withAlpha(10)
                            : Colors.grey.shade100),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  // Index Badge
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withAlpha(40)
                          : colors.surfaceContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: isSelected 
                            ? (isDark ? AppColors.textPrimary : Colors.white) 
                            : colors.text,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Info Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (group.isActiveTrip) ...[
                          Text(
                            context.t('activeNow'),
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 1),
                        ],
                        Text(
                          '${context.t('updated')}: ${group.tracking != null ? "${group.tracking!.lastUpdate.hour}:${group.tracking!.lastUpdate.minute.toString().padLeft(2, "0")}" : "---"}',
                          style: TextStyle(
                            color: isSelected
                                ? (isDark ? AppColors.textSecondary : Colors.white.withAlpha(180))
                                : colors.text70,
                            fontSize: 8.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${context.t('bus')} $busDisplayName',
                          style: TextStyle(
                            color: isSelected 
                                ? (isDark ? AppColors.textPrimary : Colors.white) 
                                : colors.text,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${context.t('driver')}: ${group.driver?.getLocalizedName(AppScope.of(context).locale.languageCode) ?? '---'}',
                          style: TextStyle(
                            color: isSelected
                                ? (isDark ? AppColors.textSecondary : Colors.white.withAlpha(200))
                                : colors.text70,
                            fontSize: 9,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Bus Icon
                  Icon(
                    Icons.directions_bus_filled_rounded,
                    color: isSelected
                        ? (isDark ? AppColors.textPrimary : Colors.white)
                        : colors.text.withAlpha(180),
                    size: 18,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DataDrivenPanel extends StatelessWidget {
  final BusTrackingGroup? group;
  final bool isExpanded;
  final VoidCallback onToggle;
  final List<Student> parentStudents;
  final String? remainingTime;

  const _DataDrivenPanel({
    required this.group,
    required this.isExpanded,
    required this.onToggle,
    required this.parentStudents,
    this.remainingTime,
  });

  @override
  Widget build(BuildContext context) {
    if (group == null) return _buildNoTripState(context);
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      bottom: 0,
      left: 0,
      right: 0,
      height: isExpanded ? MediaQuery.of(context).size.height * 0.75 : 235,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black45
                  : Colors.black12,
              blurRadius: 15,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            // Handle Bar for UX
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(80),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            // Fixed Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildHeader(context),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    _buildMetricsRow(context),
                    if (isExpanded) ...[
                      const SizedBox(height: 16),
                      _buildStudentsSection(context),
                      _buildActionFooter(context),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final tracking = group?.tracking;
    final driver = group?.driver;
    final supervisor = group?.supervisor;
    final bool isTripActive = group?.isActiveTrip ?? false;

    return Row(
      children: [
        // 1. Status & Bus Section (Right Side)
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Row 1: Status Badges
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: (isTripActive ? Colors.green : Colors.grey).withAlpha(20),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          backgroundColor: isTripActive ? Colors.green : Colors.grey,
                          radius: 2,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isTripActive
                              ? context.t('activeNow')
                              : context.t('inactive'),
                          style: TextStyle(
                            color: isTripActive ? Colors.green : Colors.grey,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${context.t('updated')}: ${tracking != null ? "${tracking.lastUpdate.hour > 12 ? tracking.lastUpdate.hour - 12 : tracking.lastUpdate.hour}:${tracking.lastUpdate.minute.toString().padLeft(2, "0")} ${tracking.lastUpdate.hour >= 12 ? context.t('pm') : context.t('am')}" : "---"}',
                    style: TextStyle(
                      color:
                          (Theme.of(context).brightness == Brightness.dark
                                  ? AppColors.dark
                                  : AppColors.light)
                              .text70,
                      fontSize: 8.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Row 2: Bus Info
              Row(
                children: [
                  Icon(
                    Icons.directions_bus_filled,
                    color:
                        (Theme.of(context).brightness == Brightness.dark
                                ? AppColors.dark
                                : AppColors.light)
                            .text,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      (group?.busNumber != null && group?.busNumber != '-')
                          ? group!.busNumber!
                          : (group?.busId ?? '---'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color:
                            (Theme.of(context).brightness == Brightness.dark
                                    ? AppColors.dark
                                    : AppColors.light)
                                .text,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 2. Staff Section (Left Side - Stacked Vertically with Avatars)
        if (driver != null) ...[
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            width: 1,
            height: 60,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withAlpha(20)
                : Colors.grey.shade200,
          ),
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Driver Row
                _buildCompactStaffRow(
                  driver,
                  context.t('driver'),
                  Icons.person,
                ),
                if (supervisor != null) ...[
                  const SizedBox(height: 10),
                  _buildCompactStaffRow(
                    supervisor,
                    context.t('supervisor'),
                    Icons.person_pin,
                  ),
                ],
              ],
            ),
          ),
        ],

        // 3. Toggle Button
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onToggle,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white 
                  : AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
              color: Theme.of(context).brightness == Brightness.dark 
                  ? AppColors.textPrimary 
                  : Colors.white,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsRow(BuildContext context) {
    final tracking = group?.tracking;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(5) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withAlpha(10) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          _MetricItem(
            icon: Icons.group_outlined,
            label: context.t('totalStudents'),
            value:
                (group?.totalStudentsCount != null &&
                    group!.totalStudentsCount! > 0)
                ? '${group?.totalStudentsCount}'
                : '${group?.students.length ?? 0}',
            iconColor: Colors.blue,
          ),
          _MetricItem(
            icon: Icons.schedule,
            label: context.t('startedAt'),
            value: group?.startTime != null
                ? (() {
                    final hour = group!.startTime!.hour;
                    final minute = group!.startTime!.minute.toString().padLeft(
                      2,
                      "0",
                    );
                    final period = hour >= 12
                        ? context.t('pm')
                        : context.t('am');
                    final displayHour = hour == 0
                        ? 12
                        : (hour > 12 ? hour - 12 : hour);
                    return "$displayHour:$minute $period";
                  })()
                : '--:--',
            iconColor: Colors.orange,
          ),
          _MetricItem(
            icon: Icons.speed,
            label: context.t('speed'),
            value: '${(tracking?.speed ?? 0).toInt()} ${context.t('kmh')}',
            iconColor: Colors.green,
          ),
          _MetricItem(
            icon: Icons.auto_graph_rounded,
            label: context.t('etaLabel'),
            value: remainingTime ??
                (tracking?.etaMinutes != null
                    ? '${tracking!.etaMinutes} ${context.t('minutesSuffix')}'
                    : '--'),
            iconColor: isDark ? Colors.white : AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsSection(BuildContext context) {
    // Use group students first; fallback to parent's full student list
    List<Student> students = group?.students ?? [];
    if (students.isEmpty) {
      students = parentStudents;
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;
    final isCompact =
        students.length > 3; // Use compact view if more than 3 students
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.group, size: 18, color: colors.text),
            const SizedBox(width: 6),
            Text(
              '${context.t('myKidsOnBus')} (${students.length})',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: colors.text,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (students.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                context.t('noStudentsOnBus'),
                style: TextStyle(color: colors.text70, fontSize: 13),
              ),
            ),
          )
        else
          ...students.asMap().entries.map(
            (entry) {
              final s = entry.value;
              final controller = AppScope.of(context);
              final isCurrent = controller.currentStudent?.id == s.id;
              final tracking = group?.tracking;
              final target = (tracking?.targetLatitude != null && tracking?.targetLongitude != null)
                  ? LatLng(tracking!.targetLatitude!, tracking.targetLongitude!)
                  : null;
              final isActive = _isStudentActiveTarget(s, target);
              
              return _StudentCard(
                student: s, 
                isCompact: isCompact,
                isActiveTarget: isActive,
                isSelected: isCurrent,
              );
            }
          ),
      ],
    );
  }

  Widget _buildActionFooter(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            _ActionTile(
              icon: Icons.phone_in_talk_rounded,
              label: context.t('quickCall'),
              color: isDark ? Colors.green.withAlpha(30) : Colors.green.withAlpha(15),
              textColor: isDark ? Colors.greenAccent : Colors.green,
              onPressed: () => _showQuickCall(context, group),
            ),
            const SizedBox(width: 12),
            _ActionTile(
              icon: Icons.chat_bubble_rounded,
              label: context.t('chat'),
              color: isDark ? Colors.white.withAlpha(30) : AppColors.primary.withAlpha(15),
              textColor: isDark ? Colors.white : AppColors.primary,
              onPressed: () {
                AppScope.of(context).setNavIndex(5);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompactStaffRow(
    BusStaffInfo staff,
    String label,
    IconData fallbackIcon,
  ) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final colors = isDark ? AppColors.dark : AppColors.light;
        return Row(
          children: [
            UserAvatar(
              name: staff.getLocalizedName(AppScope.of(context).locale.languageCode),
              avatarUrl: staff.imageUrl,
              radius: 16,
              fontSize: 10,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 8,
                      color: colors.text70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    staff.getLocalizedName(AppScope.of(context).locale.languageCode),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: colors.text,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNoTripState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black26 : Colors.black12,
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          children: [
            const Icon(Icons.bus_alert, size: 40, color: Colors.orange),
            const SizedBox(height: 8),
            Text(
              context.t('noActiveTrips'),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: colors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  const _MetricItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 8,
                color: colors.text70,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: colors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final Student student;
  final bool isCompact;
  final bool isActiveTarget;
  final bool isSelected;

  const _StudentCard({
    required this.student,
    this.isCompact = false,
    this.isActiveTarget = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final String localeStr = Localizations.localeOf(context).languageCode;
    final bool isArabic = localeStr == 'ar';
    final bool isFemale = student.gender?.toLowerCase() == 'female';

    final String statusText;
    final Color statusColor;
    final IconData statusIcon;
    final String subtitleText;

    switch (student.status) {
      case StudentStatus.onBusToSchool:
      case StudentStatus.onBusToHome:
      case StudentStatus.onBus:
        statusText = isArabic
            ? (isFemale ? 'ركبت الحافلة' : 'ركب الحافلة')
            : context.t('boarded');
        statusColor = Colors.green;
        statusIcon = Icons.directions_bus_rounded;
        final DateTime? boardingTime = student.status == StudentStatus.onBusToHome
            ? student.onBusToHomeTime
            : student.onBusToSchoolTime;
        if (boardingTime != null) {
          subtitleText = "${context.t('boardingTime')} ${DateFormat('hh:mm a', localeStr).format(boardingTime)}";
        } else {
          subtitleText = context.t('boardingTime');
        }
        break;

      case StudentStatus.atSchool:
        statusText = isArabic
            ? (isFemale ? 'وصلت المدرسة' : 'وصل المدرسة')
            : context.t('arrivedSchool');
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_rounded;
        if (student.atSchoolTime != null) {
          final String arrivedWord = isArabic
              ? (isFemale ? 'وصلت' : 'وصل')
              : context.t('arrived');
          subtitleText = "$arrivedWord ${DateFormat('hh:mm a', localeStr).format(student.atSchoolTime!)}";
        } else {
          subtitleText = isArabic
              ? (isFemale ? 'وصلت المدرسة' : 'وصل المدرسة')
              : context.t('arrivedSchool');
        }
        break;

      case StudentStatus.arrivedHome:
      case StudentStatus.atHome:
        statusText = isArabic
            ? (isFemale ? 'وصلت المنزل' : 'وصل المنزل')
            : context.t('arrivedHome');
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_rounded;
        if (student.arrivedHomeTime != null) {
          final String arrivedWord = isArabic
              ? (isFemale ? 'وصلت' : 'وصل')
              : context.t('arrived');
          subtitleText = "$arrivedWord ${DateFormat('hh:mm a', localeStr).format(student.arrivedHomeTime!)}";
        } else {
          subtitleText = isArabic
              ? (isFemale ? 'وصلت المنزل' : 'وصل المنزل')
              : context.t('arrivedHome');
        }
        break;

      case StudentStatus.late:
        statusText = context.t('late');
        statusColor = Colors.red;
        statusIcon = Icons.access_time_filled_rounded;
        subtitleText = context.t('waitingForBoarding');
        break;

      case StudentStatus.waitingAtHome:
      case StudentStatus.notBoarded:
        statusText = isArabic
            ? (isFemale ? 'لم تركب بعد' : 'لم يركب بعد')
            : context.t('notBoardedYet');
        statusColor = Colors.orange;
        statusIcon = Icons.error_outline_rounded;
        subtitleText = context.t('waitingForBoarding');
        break;
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActiveTarget
            ? (isDark ? AppColors.primary.withAlpha(20) : AppColors.primary.withAlpha(8))
            : isSelected
                ? (isDark ? Colors.white.withAlpha(10) : Colors.grey.shade50)
                : (isDark ? Colors.white.withAlpha(5) : Colors.white),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActiveTarget
              ? Colors.green
              : isSelected
                  ? AppColors.primary
                  : (isDark ? Colors.white.withAlpha(10) : Colors.grey.shade100),
          width: (isActiveTarget || isSelected) ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar with shadow
          UserAvatar(
            name: student.getLocalizedName(AppScope.of(context).locale.languageCode),
            avatarUrl: student.avatarUrl,
            radius: 22,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.getLocalizedName(AppScope.of(context).locale.languageCode),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: colors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  student.getLocalizedGrade(AppScope.of(context).locale.languageCode),
                  style: TextStyle(color: colors.text70, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (isActiveTarget) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withAlpha(50)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.my_location_rounded,
                        color: Colors.green,
                        size: 11,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isArabic ? 'يتجه إليه الآن' : 'Heading here now',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(
                    15,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      statusIcon,
                      color: statusColor,
                      size: 14,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitleText,
                style: TextStyle(
                  color: colors.text70,
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onPressed;
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.textColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: textColor, size: 18),
              const SizedBox(width: 6),
              FittedBox(
                child: Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleHeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  const _CircleHeaderButton({required this.icon, required this.onPressed});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;
    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: colors.text, size: 22),
        onPressed: onPressed,
      ),
    );
  }
}

class _MapActionFab extends StatelessWidget {
  final IconData icon;
  final String? label;
  final VoidCallback onPressed;
  const _MapActionFab({
    required this.icon,
    this.label,
    required this.onPressed,
  });
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onPressed,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, size: 24, color: colors.text),
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 4),
          Text(
            label!,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: colors.text,
            ),
          ),
        ],
      ],
    );
  }
}

void _showQuickCall(BuildContext context, BusTrackingGroup? group) {
  final driver = group?.driver;
  final supervisor = group?.supervisor;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final colors = isDark ? AppColors.dark : AppColors.light;

  showModalBottomSheet(
    context: context,
    backgroundColor: colors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
    ),
    builder: (ctx) => Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.t('quickCall'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colors.text,
            ),
          ),
          const SizedBox(height: 20),
          if (driver != null)
            ListTile(
              leading: UserAvatar(
                name: driver.getLocalizedName(AppScope.of(context).locale.languageCode),
                avatarUrl: driver.imageUrl,
                token: AppScope.of(context).token,
              ),
              title: Text(
                '${context.t('driver')}: ${driver.getLocalizedName(AppScope.of(context).locale.languageCode)}',
                style: TextStyle(color: colors.text),
              ),
              subtitle: Text(
                driver.phone ?? '',
                style: TextStyle(color: colors.text70),
              ),
              trailing: const Icon(Icons.phone, color: Colors.green),
              onTap: () async {
                Navigator.pop(ctx);
                final uri = Uri.parse('tel:${driver.phone}');
                if (await canLaunchUrl(uri)) await launchUrl(uri);
              },
            ),
          if (supervisor != null)
            ListTile(
              leading: UserAvatar(
                name: supervisor.getLocalizedName(AppScope.of(context).locale.languageCode),
                avatarUrl: supervisor.imageUrl,
                token: AppScope.of(context).token,
              ),
              title: Text(
                '${context.t('supervisor')}: ${supervisor.getLocalizedName(AppScope.of(context).locale.languageCode)}',
                style: TextStyle(color: colors.text),
              ),
              subtitle: Text(
                supervisor.phone ?? '',
                style: TextStyle(color: colors.text70),
              ),
              trailing: const Icon(Icons.phone, color: Colors.green),
              onTap: () async {
                Navigator.pop(ctx);
                final uri = Uri.parse('tel:${supervisor.phone}');
                if (await canLaunchUrl(uri)) await launchUrl(uri);
              },
            ),
          if (driver == null && supervisor == null)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                context.t('noContactData'),
                style: TextStyle(color: colors.text70),
              ),
            ),
        ],
      ),
    ),
  );
}

bool _isStudentActiveTarget(Student student, LatLng? target) {
  if (target == null) return false;
  
  final home = student.homeLocation;
  if (home != null) {
    final latDiff = (home.latitude - target.latitude).abs();
    final lngDiff = (home.longitude - target.longitude).abs();
    if (latDiff < 0.00015 && lngDiff < 0.00015) {
      return true;
    }
  }

  final school = student.schoolCoords;
  if (school != null) {
    final latDiff = (school.latitude - target.latitude).abs();
    final lngDiff = (school.longitude - target.longitude).abs();
    if (latDiff < 0.00015 && lngDiff < 0.00015) {
      return true;
    }
  }
  
  final schoolStr = student.schoolLocation;
  if (schoolStr != null && schoolStr.isNotEmpty) {
    try {
      final parts = schoolStr.split(',');
      if (parts.length == 2) {
        final lat = double.tryParse(parts[0].trim());
        final lng = double.tryParse(parts[1].trim());
        if (lat != null && lng != null) {
          final latDiff = (lat - target.latitude).abs();
          final lngDiff = (lng - target.longitude).abs();
          if (latDiff < 0.00015 && lngDiff < 0.00015) {
            return true;
          }
        }
      }
    } catch (_) {}
  }
  
  return false;
}

class SpeechBubble extends StatelessWidget {
  final String title;
  final String description;
  final String time;

  const SpeechBubble({
    super.key,
    required this.title,
    required this.description,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF1A73E8),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                time,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        ClipPath(
          clipper: TriangleClipper(),
          child: Container(
            color: Colors.white,
            width: 16,
            height: 8,
          ),
        ),
      ],
    );
  }
}

class TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

