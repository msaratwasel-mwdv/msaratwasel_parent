import 'package:flutter/material.dart';

/// [MouseInteractionRegion] يضيف تفاعلات بصرية ذكية عند استخدام الفأرة (Desktop/Web).
/// يقوم بتغيير شكل المؤشر وإضافة تأثير تكبير (Scaling) بسيط عند الحوم فوق العنصر.
class MouseInteractionRegion extends StatefulWidget {
  final Widget child;
  final MouseCursor cursor;
  final Function(bool isHovered)? onHoverChanged;
  final double hoverScale;

  const MouseInteractionRegion({
    super.key,
    required this.child,
    this.cursor = SystemMouseCursors.click,
    this.onHoverChanged,
    this.hoverScale = 1.02,
  });

  @override
  State<MouseInteractionRegion> createState() => _MouseInteractionRegionState();
}

class _MouseInteractionRegionState extends State<MouseInteractionRegion> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.cursor,
      onEnter: (_) => _handleHover(true),
      onExit: (_) => _handleHover(false),
      child: AnimatedScale(
        scale: _isHovered ? widget.hoverScale : 1.0,
        duration: const Duration(milliseconds: 100),
        child: widget.child,
      ),
    );
  }

  void _handleHover(bool value) {
    setState(() => _isHovered = value);
    if (widget.onHoverChanged != null) widget.onHoverChanged!(value);
  }
}
