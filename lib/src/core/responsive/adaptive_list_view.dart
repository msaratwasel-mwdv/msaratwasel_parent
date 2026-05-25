import 'package:flutter/material.dart';

/// [AdaptiveListView] يقوم بالتبديل تلقائياً بين القائمة العادية (ListView)
/// والشبكة (GridView) لمنع تمدد العناصر بشكل غير مريح في الشاشات الواسعة.
/// يدعم حفظ حالة التمرير باستخدام [storageKey].
class AdaptiveListView extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final String storageKey; // مفتاح فريد لحفظ مكان التمرير
  final double maxExtent;
  final double childAspectRatio;
  final double breakpoint;
  final EdgeInsetsGeometry? padding;

  const AdaptiveListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.storageKey,
    this.maxExtent = 350.0,
    this.childAspectRatio = 1.0,
    this.breakpoint = 600.0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < breakpoint) {
          return ListView.builder(
            key: PageStorageKey(storageKey), // حفظ مكان التمرير
            padding: padding,
            itemCount: itemCount,
            itemBuilder: itemBuilder,
          );
        } else {
          return GridView.builder(
            key: PageStorageKey(storageKey), // حفظ مكان التمرير
            padding: padding ?? const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: maxExtent,
              childAspectRatio: childAspectRatio,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: itemCount,
            itemBuilder: itemBuilder,
          );
        }
      },
    );
  }
}
