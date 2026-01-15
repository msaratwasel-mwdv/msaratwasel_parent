import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/shared/theme/app_colors.dart';
import 'package:msaratwasel_user/src/shared/theme/app_spacing.dart';

class ParentProfilePage extends StatefulWidget {
  const ParentProfilePage({super.key});

  @override
  State<ParentProfilePage> createState() => _ParentProfilePageState();
}

class _ParentProfilePageState extends State<ParentProfilePage> {
  final ImagePicker _picker = ImagePicker();
  File? _avatarFile;
  String _name = '';
  String _phone = '';
  String _email = '';
  bool _initializedFromLocale = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initializedFromLocale) return;

    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    _name = isArabic ? "عبدالله الأحمد" : "Abdullah Al-Ahmad";
    _phone = "0501234567";
    _email = "abdullah@example.com";
    _initializedFromLocale = true;
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final file = await _picker.pickImage(
      source: source,
      maxWidth: 1400,
      imageQuality: 85,
    );
    if (file == null) return;

    setState(() => _avatarFile = File(file.path));
  }

  void _showPhotoOptions() {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: Text(isArabic ? "التقاط صورة" : "Take a photo"),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: Text(
                isArabic ? "اختيار من المعرض" : "Choose from gallery",
              ),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBackgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final ImageProvider avatarImage = _avatarFile != null
        ? FileImage(_avatarFile!)
        : const NetworkImage(
            "https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=400",
          );

    return CustomScrollView(
      slivers: [
        // Navigation Bar
        CupertinoSliverNavigationBar(
          backgroundColor: scaffoldBackgroundColor,
          border: null,
          largeTitle: Platform.isAndroid
              ? Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    isArabic ? "الملف الشخصي" : "Profile",
                    style: TextStyle(
                      height: 1.2,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                )
              : Text(
                  isArabic ? "الملف الشخصي" : "Profile",
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
          leading: Material(
            color: Colors.transparent,
            child: IconButton(
              icon: Icon(
                Icons.menu_rounded,
                color: isDark ? Colors.white : AppColors.primary,
              ),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          trailing: Material(
            color: Colors.transparent,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.camera_alt_rounded,
                    color: AppColors.primary,
                  ),
                  onPressed: _showPhotoOptions,
                ),
              ],
            ),
          ),
        ),

        // Content
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Profile Header
              _ProfileHeader(
                name: _name,
                isArabic: isArabic,
                isDark: isDark,
                avatar: avatarImage,
                onChangePhoto: _showPhotoOptions,
              ),

              const SizedBox(height: AppSpacing.xl),

              // Personal Information Section
              _SectionTitle(
                title: isArabic ? "المعلومات الشخصية" : "Personal Information",
                icon: Icons.person_outline,
                isDark: isDark,
              ),
              const SizedBox(height: AppSpacing.md),

              _InfoCard(
                icon: Icons.badge_outlined,
                label: isArabic ? "الرقم المدني" : "Civil ID",
                value: "123456",
                isDark: isDark,
              ),
              const SizedBox(height: AppSpacing.sm),

              _InfoCard(
                icon: Icons.phone_outlined,
                label: isArabic ? "رقم الهاتف" : "Phone Number",
                value: _phone,
                isDark: isDark,
              ),
              const SizedBox(height: AppSpacing.sm),

              _InfoCard(
                icon: Icons.email_outlined,
                label: isArabic ? "البريد الإلكتروني" : "Email",
                value: _email,
                isDark: isDark,
              ),

              const SizedBox(height: AppSpacing.xl),

              // Children Section
              _SectionTitle(
                title: isArabic ? "الأبناء" : "Children",
                icon: Icons.family_restroom_rounded,
                isDark: isDark,
                action: TextButton.icon(
                  onPressed: () {
                    // Navigate to children screen
                    final controller = AppScope.of(context);
                    controller.setNavIndex(1);
                    Navigator.of(context).pop(); // Close drawer if open
                  },
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: Text(isArabic ? "عرض الكل" : "View All"),
                  style: TextButton.styleFrom(
                    foregroundColor: isDark
                        ? Colors.blue.shade200
                        : AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              _ChildQuickCard(
                name: isArabic ? "سارة أحمد" : "Sarah Ahmed",
                grade: isArabic ? "الصف الرابع" : "Grade 4",
                avatar:
                    "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200",
                isDark: isDark,
                isArabic: isArabic,
              ),
              const SizedBox(height: AppSpacing.sm),

              _ChildQuickCard(
                name: isArabic ? "عبدالله محمد" : "Abdullah Mohammed",
                grade: isArabic ? "الصف الأول" : "Grade 1",
                avatar:
                    "https://images.unsplash.com/photo-1503023345310-bd7c1de61c7d?w=200",
                isDark: isDark,
                isArabic: isArabic,
              ),

              const SizedBox(height: AppSpacing.xl),

              // Logout Button
              _ProfileActionButton(
                icon: Icons.logout_rounded,
                label: isArabic ? "تسجيل الخروج" : "Logout",
                color: AppColors.error,
                isDark: isDark,
                isHorizontal: true,
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(isArabic ? "تسجيل الخروج" : "Logout"),
                      content: Text(
                        isArabic
                            ? "هل أنت متأكد من تسجيل الخروج؟"
                            : "Are you sure you want to logout?",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(isArabic ? "إلغاء" : "Cancel"),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text(
                            isArabic ? "تسجيل الخروج" : "Logout",
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              SizedBox(
                height: MediaQuery.of(context).padding.bottom + AppSpacing.xl,
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.isArabic,
    required this.isDark,
    required this.avatar,
    required this.onChangePhoto,
  });

  final String name;
  final bool isArabic;
  final bool isDark;
  final ImageProvider avatar;
  final VoidCallback onChangePhoto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 3,
                  ),
                ),
                child: CircleAvatar(radius: 50, backgroundImage: avatar),
              ),
              Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: onChangePhoto,
                  customBorder: const CircleBorder(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isArabic ? "ولي الأمر" : "Parent",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.icon,
    required this.isDark,
    this.action,
  });

  final String title;
  final IconData icon;
  final bool isDark;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: isDark ? Colors.white : AppColors.primary, size: 22),
        const SizedBox(width: AppSpacing.sm),
        Text(
          title,
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (action != null) ...[const Spacer(), action!],
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: isDark ? Colors.white : AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChildQuickCard extends StatelessWidget {
  const _ChildQuickCard({
    required this.name,
    required this.grade,
    required this.avatar,
    required this.isDark,
    required this.isArabic,
  });

  final String name;
  final String grade;
  final String avatar;
  final bool isDark;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 24, backgroundImage: NetworkImage(avatar)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  grade,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: isDark ? Colors.white60 : AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _ProfileActionButton extends StatelessWidget {
  const _ProfileActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
    this.isHorizontal = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;
  final bool isHorizontal;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.2),
            ),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: isHorizontal
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: isDark
                            ? Colors.white
                            : color, // Ensure Logout/Action icons are visible
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: isDark ? Colors.white : color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      label,
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
