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
            markers: tracking != null
                ? {
                    Marker(
                      markerId: const MarkerId('bus'),
                      position: LatLng(tracking.lat, tracking.lng),
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                    ),
                  }
                : {},
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
