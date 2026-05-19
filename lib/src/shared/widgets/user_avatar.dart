import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:msaratwasel_user/src/shared/theme/app_colors.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.avatarUrl,
    this.radius = 24.0,
    this.token,
    this.fontSize,
    this.fallbackIcon,
  });

  final String name;
  final String? avatarUrl;
  final double radius;
  final String? token;
  final double? fontSize;
  final IconData? fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final bool hasAvatar = avatarUrl != null && avatarUrl!.isNotEmpty;
    final Map<String, String>? headers = token != null && token!.isNotEmpty
        ? {'Authorization': 'Bearer $token'}
        : null;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Widget placeholder = fallbackIcon != null
        ? Icon(
            fallbackIcon,
            color: isDark ? Colors.white : AppColors.primary,
            size: fontSize ?? (radius * 1.2),
          )
        : Text(
            name.isNotEmpty ? name[0] : '?',
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.primary,
              fontSize: fontSize ?? (radius * 0.8),
              fontWeight: FontWeight.w800,
            ),
          );

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: (isDark ? Colors.white : AppColors.primary).withValues(alpha: 0.15),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasAvatar
          ? CachedNetworkImage(
              imageUrl: avatarUrl!,
              httpHeaders: headers,
              fit: BoxFit.cover,
              placeholder: (context, url) => Center(
                child: SizedBox(
                  width: radius,
                  height: radius,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: (context, url, error) => Center(child: placeholder),
            )
          : Center(child: placeholder),
    );
  }
}
