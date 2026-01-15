import 'package:flutter/material.dart';
import 'package:msaratwasel_user/src/shared/theme/app_colors.dart';

class StudentMarkerWidget extends StatelessWidget {
  const StudentMarkerWidget({
    super.key,
    required this.name,
    this.imageUrl,
    this.color = Colors.white,
  });

  final String name;
  final String? imageUrl;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 50, // Slightly reduced size to look sharp
          height: 50,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(child: _buildContent()),
        ),
        // Triangle Tail
        ClipPath(
          clipper: _TriangleClipper(),
          child: Container(width: 12, height: 8, color: color),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildInitials(),
      );
    }
    return _buildInitials();
  }

  Widget _buildInitials() {
    return Container(
      alignment: Alignment.center,
      color: Colors.white,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
      ),
    );
  }
}

class _TriangleClipper extends CustomClipper<Path> {
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
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
