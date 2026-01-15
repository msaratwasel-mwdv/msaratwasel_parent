import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MarkerGenerator {
  /// Creates a [BitmapDescriptor] from a widget.
  ///
  /// This function renders the provided widget into an image and then converts
  /// it into a [BitmapDescriptor] suitable for use as a Google Maps marker.
  static Future<BitmapDescriptor> createCustomMarkerBitmap(
    String label, {
    String? imageUrl,
    required Size size,
    required BuildContext context,
  }) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final sizePx = Size(
      size.width * 2,
      size.height * 2,
    ); // Higher resolution canvas
    final double width = sizePx.width;
    final double height = sizePx.height;
    final double radius = width / 2;

    final paint = Paint()..color = Colors.blueAccent;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Draw Pin Shape
    final path = Path();
    // Start at bottom center (the tip of the pin)
    path.moveTo(width / 2, height);
    // Curve to the right side
    path.quadraticBezierTo(width / 2, height * 0.75, width, height * 0.45);
    // Top circle arc
    path.arcToPoint(
      Offset(0, height * 0.45),
      radius: Radius.circular(width / 2),
      clockwise: false,
    );
    // Curve back to bottom center
    path.quadraticBezierTo(width / 2, height * 0.75, width / 2, height);
    path.close();

    // Draw Shadow
    canvas.drawPath(
      path.shift(const Offset(0, 4)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Draw Pin Background (White)
    paint.color = Colors.white;
    canvas.drawPath(path, paint);

    // Draw Inner White Circle
    final double innerRadius = radius * 0.85; // Slightly larger white area
    // Center of the top circle part
    final topCenter = Offset(width / 2, height * 0.4);

    paint.color = Colors.white;
    canvas.drawCircle(topCenter, innerRadius, paint);

    // Load and Draw Image or Initials
    ui.Image? profileImage;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
        final completer = Completer<ui.Image>();
        final stream = NetworkImage(imageUrl).resolve(ImageConfiguration.empty);
        final listener = ImageStreamListener((ImageInfo info, bool syncCall) {
          completer.complete(info.image);
        });
        stream.addListener(listener);
        profileImage = await completer.future.timeout(
          const Duration(seconds: 3),
        );
        stream.removeListener(listener);
      } catch (e) {
        // Fallback to initials if image load fails
        debugPrint('Failed to load marker image: $e');
      }
    }

    if (profileImage != null) {
      // Draw Avatar
      final Path clipPath = Path()
        ..addOval(
          Rect.fromCircle(center: topCenter, radius: innerRadius * 0.9),
        );
      canvas.save();
      canvas.clipPath(clipPath);

      // Scale image to fit
      final src = Rect.fromLTWH(
        0,
        0,
        profileImage.width.toDouble(),
        profileImage.height.toDouble(),
      );
      final dst = Rect.fromCircle(center: topCenter, radius: innerRadius * 0.9);
      canvas.drawImageRect(profileImage, src, dst, Paint());
      canvas.restore();
    } else {
      // Draw Initials
      final String text = label.isNotEmpty ? label[0].toUpperCase() : '?';
      textPainter.text = TextSpan(
        text: text,
        style: TextStyle(
          fontSize: innerRadius,
          fontWeight: FontWeight.bold,
          color: Colors.blueAccent,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          topCenter.dx - textPainter.width / 2,
          topCenter.dy - textPainter.height / 2,
        ),
      );
    }

    // Convert canvas to image
    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(
      sizePx.width.toInt(),
      sizePx.height.toInt(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      return BitmapDescriptor.defaultMarker;
    }

    return BitmapDescriptor.bytes(byteData.buffer.asUint8List());
  }
}
