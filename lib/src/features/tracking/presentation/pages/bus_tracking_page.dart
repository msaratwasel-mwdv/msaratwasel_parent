import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:ui' as ui;

import '../../../../app/state/app_controller.dart';
import '../../../../core/models/app_models.dart';
import '../../../../shared/localization/app_strings.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../domain/entities/bus_tracking.dart';
import '../../domain/entities/bus_tracking_group.dart';

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

  @override
  void initState() {
    super.initState();
    _loadCustomMarkers();
  }

  Future<void> _loadCustomMarkers() async {
    try {
      _busIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/images/bus_marker.png',
      );
      _homeIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(40, 40)),
        'assets/images/home_marker.png',
      );
    } catch (e) {
      debugPrint('Markers not found, using defaults');
    }
    if (mounted) setState(() {});
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
        15.5,
      ),
    );
  }

  Future<void> _centerOnMe() async {
    if (_mapController == null) return;
    try {
      final position = await Geolocator.getCurrentPosition();
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          15.5,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t('failedToDetermineLocation'))),
        );
      }
    }
  }

  void _toggleMapType() {
    setState(() {
      _currentMapType = _currentMapType == MapType.normal
          ? MapType.hybrid
          : MapType.normal;
    });
  }

  Future<void> _launchNavigation(BusTracking? tracking) async {
    if (tracking == null) return;
    final url =
        'google.navigation:q=${tracking.latitude},${tracking.longitude}';
    final fallbackUrl =
        'https://www.google.com/maps/search/?api=1&query=${tracking.latitude},${tracking.longitude}';

    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        await launchUrl(
          Uri.parse(fallbackUrl),
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      debugPrint('Could not launch navigation: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final selectedGroup = controller.selectedGroup;
    final allGroups = controller.allTripGroups;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;

    return Directionality(
      textDirection: controller.locale.languageCode == 'ar'
          ? ui.TextDirection.rtl
          : ui.TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Stack(
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
                ],
              ),
            ),
            _buildMapControls(selectedGroup?.tracking),
            _DataDrivenPanel(
              group: selectedGroup,
              isExpanded: _isPanelExpanded,
              onToggle: () =>
                  setState(() => _isPanelExpanded = !_isPanelExpanded),
              parentStudents: controller.students,
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
          anchor: const Offset(0.5, 0.5),
          rotation: tracking.heading ?? 0,
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
                  _homeIcon ??
                  BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueOrange,
                  ),
              infoWindow: InfoWindow(title: student.name),
            ),
          );
          routePoints.add(pos);
        }
      }

      if (routePoints.length > 1) {
        polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: routePoints,
            color: const Color(0xFF1A73E8), // Vibrant blue
            width: 6,
            patterns: [PatternItem.dash(20), PatternItem.gap(10)],
            jointType: JointType.round,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
          ),
        );
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: tracking != null
            ? LatLng(tracking.latitude, tracking.longitude)
            : const LatLng(15.3694, 44.1910),
        zoom: 14,
      ),
      onMapCreated: (c) {
        _mapController = c;
        if (isDark) {
          _setDarkMapStyle(c);
        }
      },
      markers: markers,
      polylines: polylines,
      mapType: _currentMapType,
      zoomControlsEnabled: false,
      myLocationButtonEnabled: false,
      mapToolbarEnabled: false,
    );
  }

  void _setDarkMapStyle(GoogleMapController controller) {
    const String darkStyle = '''
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
    controller.setMapStyle(darkStyle);
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
                icon: Icons.directions_bus,
                label: context.t('bus'),
                onPressed: () => _centerOnBus(tracking),
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

  static const String _mapStyle =
      '[{"featureType":"poi","stylers":[{"visibility":"off"}]},{"featureType":"transit","stylers":[{"visibility":"off"}]}]';
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
      height: 92,
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
              width: 145,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : colors.card,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? AppColors.primary.withAlpha(60)
                        : Colors.black.withAlpha(5),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Index Badge
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withAlpha(30)
                          : colors.surfaceContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : colors.text,
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Info Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isSelected) ...[
                          Text(
                            context.t('activeNow'),
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 7.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 1),
                        ],
                        Text(
                          '${context.t('updated')}: ${group.tracking != null ? "${group.tracking!.lastUpdate.hour}:${group.tracking!.lastUpdate.minute.toString().padLeft(2, "0")}" : "---"}',
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white.withAlpha(180)
                                : colors.text70,
                            fontSize: 7,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${context.t('bus')} $busDisplayName',
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : colors.text,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${context.t('driver')}: ${group.driver?.name ?? '---'}',
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white.withAlpha(200)
                                : colors.text70,
                            fontSize: 8.5,
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
                        ? Colors.white
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

  const _DataDrivenPanel({
    required this.group,
    required this.isExpanded,
    required this.onToggle,
    required this.parentStudents,
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
      height: isExpanded ? 600 : 235,
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
                      color: Colors.green.withAlpha(20),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircleAvatar(
                          backgroundColor: Colors.green,
                          radius: 2,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isTripActive
                              ? context.t('activeNow')
                              : context.t('inactive'),
                          style: const TextStyle(
                            color: Colors.green,
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
                      color: (Theme.of(context).brightness == Brightness.dark ? AppColors.dark : AppColors.light).text70,
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
                    color: (Theme.of(context).brightness == Brightness.dark ? AppColors.dark : AppColors.light).text,
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
                        color: (Theme.of(context).brightness == Brightness.dark ? AppColors.dark : AppColors.light).text,
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
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsRow(BuildContext context) {
    final tracking = group?.tracking;
    final total = group?.totalStudentsCount ?? 0;

    // Guardian's children only for boarded/notBoarded
    final myStudents = group?.students ?? [];
    final boarded = myStudents
        .where(
          (s) =>
              s.status == StudentStatus.onBusToSchool ||
              s.status == StudentStatus.onBusToHome ||
              s.status == StudentStatus.onBus,
        )
        .length;
    final notBoarded = myStudents.length - boarded;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isDark ? Colors.white.withAlpha(10) : AppColors.border,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _MetricItem(
            icon: Icons.people_outline,
            label: context.t('totalStudents'),
            value:
                (group?.totalStudentsCount != null &&
                    group!.totalStudentsCount! > 0)
                ? '${group?.totalStudentsCount}'
                : '${group?.students.length ?? 0}',
            iconColor: Colors.blue,
          ),
          _MetricItem(
            icon: Icons.timer_outlined,
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
            icon: Icons.speed_outlined,
            label: context.t('speed'),
            value: '${(tracking?.speed ?? 0).toInt()} ${context.t('kmh')}',
            iconColor: Colors.redAccent,
          ),
          _MetricItem(
            icon: Icons.auto_graph_outlined,
            label: context.t('etaLabel'),
            value: tracking?.etaMinutes != null
                ? '${tracking!.etaMinutes} ${context.t('minutesSuffix')}'
                : '--',
            iconColor: Colors.purple,
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
                style: TextStyle(
                  color: colors.text70,
                  fontSize: 13,
                ),
              ),
            ),
          )
        else
          ...students.map((s) => _StudentCard(student: s, isCompact: isCompact)),
      ],
    );
  }

  Widget _buildActionFooter(BuildContext context) {
    return Column(
      children: [
        const Divider(height: 30),
        Row(
          children: [
            _ActionTile(
              icon: Icons.list_alt_rounded,
              label: context.t('tripDetails'),
              color: Colors.grey.shade100,
              textColor: Colors.black,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.t('tripDetailsComingSoon'))),
                );
              },
            ),
            const SizedBox(width: 8),
            _ActionTile(
              icon: Icons.phone_in_talk_rounded,
              label: context.t('quickCall'),
              color: const Color(0xFFE8F5E9),
              textColor: Colors.green,
              onPressed: () => _showQuickCall(context, group),
            ),
            const SizedBox(width: 8),
            _ActionTile(
              icon: Icons.chat_bubble_rounded,
              label: context.t('chat'),
              color: const Color(0xFFE3F2FD),
              textColor: Colors.blue,
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
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: colors.surfaceContainer,
              ),
              clipBehavior: Clip.antiAlias,
              child: staff.imageUrl != null && staff.imageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: staff.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          const Icon(Icons.person, size: 16, color: Colors.grey),
                      errorWidget: (context, url, error) =>
                          Icon(fallbackIcon, size: 16, color: Colors.grey),
                    )
                  : Icon(fallbackIcon, size: 16, color: Colors.grey),
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
                    staff.name,
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
  const _StudentCard({required this.student, this.isCompact = false});

  @override
  Widget build(BuildContext context) {
    final bool hasBoarded =
        student.status == StudentStatus.onBusToSchool ||
        student.status == StudentStatus.onBusToHome;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: EdgeInsets.all(isCompact ? 6 : 8),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Colors.white.withAlpha(10) : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: CachedNetworkImage(
              imageUrl: student.avatarUrl ?? '',
              width: isCompact ? 32 : 40,
              height: isCompact ? 32 : 40,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(
                color: colors.surfaceContainer,
                child: Icon(
                  Icons.person,
                  color: Colors.grey,
                  size: isCompact ? 18 : 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.displayName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isCompact ? 11 : 13,
                    color: colors.text,
                  ),
                ),
                Text(
                  student.grade,
                  style: TextStyle(
                    color: colors.text70,
                    fontSize: isCompact ? 9 : 11,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (hasBoarded ? Colors.green : Colors.orange).withAlpha(
                    10,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text(
                      hasBoarded
                          ? context.t('boarded')
                          : context.t('notBoardedYet'),
                      style: TextStyle(
                        color: hasBoarded ? Colors.green : Colors.orange,
                        fontSize: isCompact ? 9 : 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      hasBoarded ? Icons.check_circle : Icons.error_outline,
                      color: hasBoarded ? Colors.green : Colors.orange,
                      size: isCompact ? 12 : 14,
                    ),
                  ],
                ),
              ),
              if (!isCompact) const SizedBox(height: 2),
              if (!isCompact)
                Text(
                  hasBoarded ? 'وقت الركوب 9:10 ص' : 'لم يتم الركوب بعد',
                  style: TextStyle(color: colors.text70, fontSize: 10),
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
        icon: Icon(
          icon,
          color: colors.text,
          size: 22,
        ),
        onPressed: onPressed,
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  const _CircleIconButton({required this.icon, required this.onPressed});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: colors.text, size: 18),
        onPressed: onPressed,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(),
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
              leading: const CircleAvatar(
                backgroundColor: Colors.blue,
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: Text(
                '${context.t('driver')}: ${driver.name}',
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
              leading: const CircleAvatar(
                backgroundColor: Colors.purple,
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: Text(
                '${context.t('supervisor')}: ${supervisor.name}',
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

