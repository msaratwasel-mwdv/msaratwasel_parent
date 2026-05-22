import 'package:flutter/material.dart';

/// A widget that displays an icon and automatically flips it horizontally
/// when the text direction is Right-to-Left (Arabic).
class DirectionalIcon extends StatelessWidget {
  final IconData icon;
  final double? size;
  final Color? color;

  const DirectionalIcon(
    this.icon, {
    super.key,
    this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isRTL = Directionality.of(context) == TextDirection.rtl;
    
    // Check if the icon data itself supports auto-mirroring
    // If not, we flip it manually
    if (icon.matchTextDirection) {
      return Icon(
        icon,
        size: size,
        color: color,
      );
    }

    return Transform.flip(
      flipX: isRTL,
      child: Icon(
        icon,
        size: size,
        color: color,
      ),
    );
  }
}
