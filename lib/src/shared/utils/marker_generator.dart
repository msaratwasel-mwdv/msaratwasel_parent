import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/config/app_config.dart';

class MarkerGenerator {
  /// Creates a [BitmapDescriptor] from a student's data.
  static Future<BitmapDescriptor> createStudentMarker({
    required String name,
    String? imageUrl,
    required Color color,
    String? authToken,
    required double size,
  }) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);

    // Use a higher resolution for the drawing

    final double canvasSize = size * 1.5; // Extra space for shadow and tail
    final double radius = size / 2;
    final Offset center = Offset(canvasSize / 2, (canvasSize * 0.4));

    // 0. Draw Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withAlpha(50)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final shadowPath = Path();
    shadowPath.moveTo(canvasSize / 2, canvasSize * 0.92);
    shadowPath.lineTo(canvasSize / 2 - (radius * 0.5), canvasSize * 0.62);
    shadowPath.lineTo(canvasSize / 2 + (radius * 0.5), canvasSize * 0.62);
    shadowPath.close();
    canvas.drawPath(shadowPath, shadowPaint);
    canvas.drawCircle(center.translate(0, 1), radius, shadowPaint);

    // 1. Draw Tail (Triangle)
    final paint = Paint()..color = color;
    final path = Path();
    path.moveTo(canvasSize / 2, canvasSize * 0.9); // Tip
    path.lineTo(canvasSize / 2 - (radius * 0.4), canvasSize * 0.6);
    path.lineTo(canvasSize / 2 + (radius * 0.4), canvasSize * 0.6);
    path.close();
    canvas.drawPath(path, paint);

    // 2. Draw Main Circle
    canvas.drawCircle(center, radius, paint);

    // 3. Draw White Border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.12;
    canvas.drawCircle(center, radius, borderPaint);

    // 4. Draw Content (Image or Initial)
    ui.Image? profileImage;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
        final completer = Completer<ui.Image>();
        final Map<String, String>? headers =
            authToken != null && authToken.isNotEmpty
            ? {'Authorization': 'Bearer $authToken'}
            : null;

        final stream = NetworkImage(
          imageUrl,
          headers: headers,
        ).resolve(ImageConfiguration.empty);
        final listener = ImageStreamListener(
          (ImageInfo info, bool syncCall) {
            if (!completer.isCompleted) completer.complete(info.image);
          },
          onError: (e, stack) {
            if (!completer.isCompleted) completer.completeError(e);
          },
        );
        stream.addListener(listener);
        profileImage = await completer.future.timeout(
          AppConfig.markerImageTimeout,
        );
        stream.removeListener(listener);
      } catch (e) {
        debugPrint('Failed to load marker image for $name: $e');
      }
    }

    if (profileImage != null) {
      // Draw Circular Image
      final Path clipPath = Path()
        ..addOval(Rect.fromCircle(center: center, radius: radius * 0.9));
      canvas.save();
      canvas.clipPath(clipPath);

      final src = Rect.fromLTWH(
        0,
        0,
        profileImage.width.toDouble(),
        profileImage.height.toDouble(),
      );
      final dst = Rect.fromCircle(center: center, radius: radius * 0.9);
      canvas.drawImageRect(
        profileImage,
        src,
        dst,
        Paint()..filterQuality = ui.FilterQuality.high,
      );
      canvas.restore();
    } else {
      // Draw Initial
      final String text = name.isNotEmpty ? name[0].toUpperCase() : '?';
      final textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontSize: radius,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          center.dx - textPainter.width / 2,
          center.dy - textPainter.height / 2,
        ),
      );
    }

    // Convert to BitmapDescriptor
    final picture = pictureRecorder.endRecording();
    final img = await picture.toImage(canvasSize.toInt(), canvasSize.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) return BitmapDescriptor.defaultMarker;
    return BitmapDescriptor.bytes(byteData.buffer.asUint8List());
  }

  /// Simple version for School Marker
  static Future<BitmapDescriptor> createSchoolMarker({
    required Color color,
    required double size,
  }) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final double pixelRatio =
        ui.PlatformDispatcher.instance.views.first.devicePixelRatio;
    final double canvasSize = size * pixelRatio;
    final center = Offset(canvasSize / 2, canvasSize / 2);
    final radius = canvasSize / 2;

    final paint = Paint()..color = color;
    canvas.drawCircle(center, radius, paint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.school.codePoint),
        style: TextStyle(
          fontSize: radius * 1.2,
          fontFamily: Icons.school.fontFamily,
          package: Icons.school.fontPackage,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );

    final picture = pictureRecorder.endRecording();
    final img = await picture.toImage(canvasSize.toInt(), canvasSize.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) return BitmapDescriptor.defaultMarker;
    return BitmapDescriptor.bytes(byteData.buffer.asUint8List());
  }

  /// Creates a beautiful Bus Marker
  static Future<BitmapDescriptor> createBusMarker({
    required Color color,
    required double size,
  }) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);

    final double canvasSize = size * 1.5;
    final double radius = size / 2;
    final center = Offset(canvasSize / 2, canvasSize * 0.4);

    // 1. Draw Tail (Nail)
    final paint = Paint()..color = color;
    final path = Path();
    path.moveTo(canvasSize / 2, canvasSize * 0.9); // Tip
    path.lineTo(canvasSize / 2 - (radius * 0.4), canvasSize * 0.6);
    path.lineTo(canvasSize / 2 + (radius * 0.4), canvasSize * 0.6);
    path.close();
    canvas.drawPath(path, paint);

    // 2. Draw Main Circle
    canvas.drawCircle(center, radius, paint);

    // 3. Draw White Border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.15;
    canvas.drawCircle(center, radius, borderPaint);

    // 4. Draw Bus Icon
    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.directions_bus.codePoint),
        style: TextStyle(
          fontSize: radius * 1.1,
          fontFamily: Icons.directions_bus.fontFamily,
          package: Icons.directions_bus.fontPackage,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );

    final picture = pictureRecorder.endRecording();
    final img = await picture.toImage(canvasSize.toInt(), canvasSize.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) return BitmapDescriptor.defaultMarker;
    return BitmapDescriptor.bytes(byteData.buffer.asUint8List());
  }

  /// Simple version for Home Marker
  static Future<BitmapDescriptor> createHomeMarker({
    required Color color,
    required double size,
  }) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final double pixelRatio =
        ui.PlatformDispatcher.instance.views.first.devicePixelRatio;
    final double canvasSize = size * pixelRatio;
    final center = Offset(canvasSize / 2, canvasSize / 2);
    final radius = canvasSize / 2;

    final paint = Paint()..color = color;
    canvas.drawCircle(center, radius, paint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.home.codePoint),
        style: TextStyle(
          fontSize: radius * 1.2,
          fontFamily: Icons.home.fontFamily,
          package: Icons.home.fontPackage,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );

    final picture = pictureRecorder.endRecording();
    final img = await picture.toImage(canvasSize.toInt(), canvasSize.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) return BitmapDescriptor.defaultMarker;
    return BitmapDescriptor.bytes(byteData.buffer.asUint8List());
  }
}
