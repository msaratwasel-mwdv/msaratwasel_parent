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

        return Scaffold(
          body: Stack(
            children: [
              Positioned.fill(child: _TrackingMap(tracking: tracking)),
              // Menu button at top-right (RTL)
              Positioned(
                top: MediaQuery.of(context).padding.top + AppSpacing.sm,
                right: AppSpacing.md,
                child: Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  elevation: 4,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => Scaffold.of(context).openDrawer(),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Icon(
                        Icons.menu_rounded,
                        color: AppColors.primary,
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
                    const SizedBox(width: AppSpacing.sm),
                    _Pill(
                      icon: Icons.timer_rounded,
                      label:
                          '${tracking.etaMinutes} ${context.t('minutesSuffix')}',
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
              Positioned(
                bottom: AppSpacing.xl + 12,
                right: AppSpacing.xl,
                child: _ToggleDetailsButton(
                  isOpen: detailsVisible,
                  onTap: () => setState(() => detailsVisible = !detailsVisible),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.md,
                    AppSpacing.xl,
                    AppSpacing.xl,
                  ),
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeInOut,
                    offset: detailsVisible
                        ? Offset.zero
                        : const Offset(0, 1.05),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: detailsVisible ? 1 : 0,
                      child: _BottomDetailsCard(
                        tracking: tracking,
                        isArabic: isArabic,
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

class _ToggleDetailsButton extends StatelessWidget {
  const _ToggleDetailsButton({required this.isOpen, required this.onTap});

  final bool isOpen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 6,
      shadowColor: Colors.black.withAlpha(31),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Icon(
            isOpen ? Icons.expand_more_rounded : Icons.expand_less_rounded,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _TrackingMap extends StatelessWidget {
  const _TrackingMap({required this.tracking});

  final TrackingSnapshot tracking;

  @override
  Widget build(BuildContext context) {
    final busPosition = LatLng(tracking.lat, tracking.lng);

    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('bus'),
        position: busPosition,
        infoWindow: InfoWindow(title: context.t('bus')),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
    };

    return GoogleMap(
      initialCameraPosition: CameraPosition(target: busPosition, zoom: 14),
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
    required this.onToggle,
  });

  final TrackingSnapshot tracking;
  final bool isArabic;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final paddingBottom = MediaQuery.of(context).padding.bottom;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg + paddingBottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onToggle,
            onVerticalDragUpdate: (details) {
              if (details.primaryDelta != null && details.primaryDelta! > 6) {
                onToggle();
              }
            },
            child: Center(
              child: Container(
                width: 54,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.3)
                      : AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withAlpha(31),
                ),
                child: const Icon(
                  Icons.directions_bus_filled_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.t('tracking'),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      isArabic
                          ? 'عرض مباشر للحافلة مع ETA والمسافة'
                          : 'Live bus view with ETA and distance',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? Colors.white70
                            : AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              _Pill(
                icon: Icons.access_time_filled_rounded,
                label: '${tracking.etaMinutes} ${context.t('minutesSuffix')}',
                background: AppColors.accent.withAlpha(36),
                borderColor: AppColors.accent.withAlpha(77),
                textColor: AppColors.accent,
                iconColor: AppColors.accent,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
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
              _TrackingStat(
                icon: Icons.alt_route_rounded,
                label: context.t('busStatus'),
                value: Labels.busState(tracking.busState, arabic: isArabic),
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
            color: isDark ? Colors.white.withOpacity(0.1) : AppColors.border,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
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
    this.background,
    this.borderColor,
    this.textColor,
  });

  final IconData icon;
  final String label;
  final Color iconColor;
  final bool subtle;
  final Color? background;
  final Color? borderColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color:
            background ?? (subtle ? Colors.white.withAlpha(46) : Colors.white),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color:
              borderColor ??
              (subtle ? Colors.white.withAlpha(77) : AppColors.border),
        ),
        boxShadow: subtle
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withAlpha(15),
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
              color:
                  textColor ?? (subtle ? Colors.white : AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
