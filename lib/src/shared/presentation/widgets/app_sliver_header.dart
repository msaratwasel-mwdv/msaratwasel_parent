import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:msaratwasel_user/src/shared/theme/app_colors.dart';

class AppSliverHeader extends StatelessWidget {
  const AppSliverHeader({
    super.key,
    required this.title,
    this.hasLeading = false,
    this.leading,
  });

  final String title;
  final bool hasLeading;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return CupertinoSliverNavigationBar(
      largeTitle: Text(
        title,
        style: TextStyle(
          fontFamily: GoogleFonts.cairo().fontFamily,
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
    );
  }
}
