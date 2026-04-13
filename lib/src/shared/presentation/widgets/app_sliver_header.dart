import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:msaratwasel_user/src/app/state/app_controller.dart'; // Ensure this exists for AppScope
import 'package:msaratwasel_user/src/shared/theme/app_colors.dart';

class AppSliverHeader extends StatelessWidget {
  const AppSliverHeader({
    super.key,
    required this.title,
    this.hasLeading = false,
    this.leading,
    this.trailing,
  });

  final String title;
  final bool hasLeading;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Get navigation state
    final controller = AppScope.of(context);
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    final isHome = controller.navIndex == 0;

    // Decide what leading widget to show
    Widget? activeLeading;
    if (leading != null) {
      activeLeading = leading;
    } else if (canPop) {
      // Regular pushed page
      activeLeading = Material(
        color: Colors.transparent,
        child: BackButton(
          color: isDark ? Colors.white : AppColors.primary,
        ),
      );
    } else {
      // Any tab (home or not) -> Show Menu (hamburger icon)
      activeLeading = Material(
        color: Colors.transparent,
        child: IconButton(
          icon: Icon(
            Icons.menu_rounded,
            color: isDark ? Colors.white : AppColors.primary,
          ),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      );
    }

    return CupertinoSliverNavigationBar(
      largeTitle: Platform.isAndroid
          ? Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                title,
                style: TextStyle(
                  height: 1.2,
                  color: isDark ? Colors.white : AppColors.primary,
                ),
              ),
            )
          : Text(
              title,
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.primary,
              ),
            ),
      backgroundColor: theme.scaffoldBackgroundColor.withValues(alpha: 0.9),
      border: null,
      stretch: true,
      leading: activeLeading,
      trailing: trailing,
    );
  }
}
