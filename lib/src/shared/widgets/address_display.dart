import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:msaratwasel_user/src/shared/localization/app_strings.dart';
import 'package:msaratwasel_user/src/shared/theme/app_colors.dart';
import 'package:msaratwasel_user/src/shared/services/geocoding_service.dart';

class AddressDisplay extends StatefulWidget {
  final double lat;
  final double lng;
  final TextStyle? style;
  final Color? iconColor;

  const AddressDisplay({
    super.key,
    required this.lat,
    required this.lng,
    this.style,
    this.iconColor,
  });

  @override
  State<AddressDisplay> createState() => _AddressDisplayState();
}

class _AddressDisplayState extends State<AddressDisplay> {
  String? _address;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchAddress();
  }

  @override
  void didUpdateWidget(covariant AddressDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lat != widget.lat || oldWidget.lng != widget.lng) {
      _fetchAddress();
    }
  }

  Future<void> _fetchAddress() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      // Delay to avoid over-fetching if tracking updates rapidly
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      
      final service = GeocodingService();
      final address = await service.reverseGeocode(LatLng(widget.lat, widget.lng));
      if (mounted) {
        setState(() {
          _address = address;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text(
            context.t('fetchingAddress') ?? 'Fetching address...',
            style: widget.style ?? const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      );
    }

    if (_address == null || _address!.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.location_on_rounded,
          size: 16,
          color: widget.iconColor ?? AppColors.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _address!,
            style: widget.style ?? TextStyle(
              color: isDark ? Colors.white70 : AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}
