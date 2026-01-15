// dart:io removed

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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

    return CupertinoSliverNavigationBar(
      largeTitle: Platform.isAndroid
          ? Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                title,
                style: TextStyle(
                  height: 1.2,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            )
          : Text(
              title,
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
      backgroundColor: theme.scaffoldBackgroundColor.withValues(alpha: 0.9),
      border: null,
      stretch: true,
      leading:
          leading ??
          (hasLeading
              ? Material(
                  color: Colors.transparent,
                  child: BackButton(
                    color: isDark ? Colors.white : AppColors.primary,
                  ),
                )
              : null),
      trailing: trailing,
    );
  }
}
