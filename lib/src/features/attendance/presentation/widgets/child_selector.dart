import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:msaratwasel_user/src/shared/localization/app_strings.dart';
import 'package:msaratwasel_user/src/shared/theme/app_colors.dart';
import 'package:msaratwasel_user/src/shared/theme/app_spacing.dart';

// View Model for the child
class AttendanceChild {
  final String id;
  final String name;
  final String? imageUrl;
  final String grade;

  AttendanceChild({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.grade,
  });
}

class ChildSelector extends StatelessWidget {
  const ChildSelector({
    super.key,
    required this.children,
    required this.selectedChild,
    required this.onChildSelected,
  });

  final List<AttendanceChild> children;
  final AttendanceChild selectedChild;
  final ValueChanged<AttendanceChild> onChildSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            context.t('chooseStudent'),
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: children.length,
          separatorBuilder: (context, index) =>
              const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) {
            final child = children[index];
            final isSelected = child.id == selectedChild.id;

            // Unified Selected Style (Light/Tinted style matching RequestAbsencePage)
            // Background: Primary with low opacity (Higher opacity in dark mode for visibility)
            final selectedBgColor = AppColors.primary.withValues(
              alpha: isDark ? 0.30 : 0.08,
            );
            // Border: Primary with medium opacity (Bright border in dark mode)
            final selectedBorderColor = AppColors.primary.withValues(
              alpha: isDark ? 0.8 : 0.5,
            );
            // Text: Primary color (or white in dark mode)
            final selectedTextColor = isDark ? Colors.white : AppColors.primary;
            // Icon: White inside the avatar (avatar bg is primary)
            final selectedIconColor = Colors.white;
            // Avatar Background: Solid Primary
            final selectedAvatarBg = AppColors.primary;
            // Checkmark: Primary color
            final selectedCheckmarkColor = isDark
                ? Colors.white
                : AppColors.primary;

            return GestureDetector(
              onTap: () => onChildSelected(child),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? selectedBgColor
                      : (isDark
                            ? const Color(0xFF1E293B) // Dark Card Color
                            : Colors.white),
                  borderRadius: BorderRadius.circular(
                    24,
                  ), // Match the 24 radius from RequestAbsencePage
                  border: Border.all(
                    color: isSelected
                        ? selectedBorderColor
                        : (isDark ? Colors.white10 : Colors.grey[200]!),
                    width: isSelected ? 1.5 : 1,
                  ),
                  boxShadow: [
                    if (!isSelected && !isDark)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            isSelected // Avatar border ring
                            ? selectedAvatarBg
                            : (isDark ? Colors.grey[800] : Colors.grey[100]),
                      ),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: isSelected
                            ? selectedAvatarBg
                            : Colors.transparent,
                        child: Icon(
                          Icons.person,
                          color: isSelected
                              ? selectedIconColor
                              : (isDark ? Colors.white70 : Colors.grey[600]),
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        child.name,
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w600,
                          color: isSelected
                              ? selectedTextColor
                              : (isDark
                                    ? Colors.white70
                                    : AppColors.textPrimary),
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle_rounded,
                        color: selectedCheckmarkColor,
                        size: 28,
                      )
                    else
                      Container(
                        // Match the unselected radio circle style
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? Colors.white24 : Colors.grey[300]!,
                            width: 2,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
