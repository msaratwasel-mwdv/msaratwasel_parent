import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/shared/localization/app_strings.dart';
import 'package:msaratwasel_user/src/shared/theme/app_colors.dart';
import 'package:msaratwasel_user/src/shared/theme/app_spacing.dart';
import 'package:provider/provider.dart';

class BusTrackingPage extends StatelessWidget {
  const BusTrackingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final tracking = controller.currentTracking;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('trackBus')),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: tracking != null ? LatLng(tracking.lat, tracking.lng) : const LatLng(24.7136, 46.6753),
              zoom: 14,
            ),
            markers: {
              if (tracking != null)
                Marker(
                  markerId: const MarkerId('bus'),
                  position: LatLng(tracking.lat, tracking.lng),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                  infoWindow: const InfoWindow(title: 'الحافلة'),
                ),
              if (controller.currentStudent?.homeLocation != null)
                Marker(
                  markerId: const MarkerId('home'),
                  position: controller.currentStudent!.homeLocation!,
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                  infoWindow: const InfoWindow(title: 'موقع المنزل'),
                ),
            },
          ),
          if (tracking != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 5)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (controller.currentStudent?.homeLocation == null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_off_rounded, color: Colors.orange, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'يرجى تحديد موقع المنزل في الملف الشخصي لعرض الوقت والمسافة المتبقية بدقة.',
                                style: TextStyle(color: Colors.orange.shade800, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (tracking.tripType != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.route_rounded, color: AppColors.primary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'نوع الرحلة: ${tracking.tripType == 'forth' ? 'ذهاب (للمدرسة)' : 'عودة (للمنزل)'}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _StatusItem(label: context.t('arrival'), value: '${tracking.etaMinutes} ${context.t('minutesSuffix')}'),
                        _StatusItem(label: context.t('speed'), value: '${tracking.speedKmh.toInt()} ${context.t('kmh')}'),
                        _StatusItem(label: context.t('distance'), value: '${tracking.distanceKm.toStringAsFixed(1)} ${context.t('km')}'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatusItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}
