import 'package:flutter/material.dart';

import 'package:msaratwasel_user/src/features/attendance/presentation/absence_request_page.dart';
import 'package:msaratwasel_user/src/shared/theme/app_colors.dart';
import 'package:msaratwasel_user/src/shared/theme/app_spacing.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('مسارات واصل')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'انطلق بتطبيق منظم',
                  style: textTheme.headlineSmall?.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'الملفات الأساسية جاهزة، ويمكنك البدء في بناء المزايا مباشرة.',
                  style: textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Wrap(
                  spacing: AppSpacing.lg,
                  runSpacing: AppSpacing.lg,
                  children: const [
                    _InfoCard(
                      icon: Icons.layers_outlined,
                      title: 'هيكل واضح',
                      description:
                          'تنظيم الثيم، الصفحات، والمكونات في أماكن ثابتة.',
                    ),
                    _InfoCard(
                      icon: Icons.palette_rounded,
                      title: 'ثيم جاهز',
                      description: 'ألوان، أحجام، وأنماط خط موحدة لكل الشاشات.',
                    ),
                    _InfoCard(
                      icon: Icons.bolt_rounded,
                      title: 'جاهز للتطوير',
                      description:
                          'ابدأ إضافة الميزات بدون إعادة ترتيب المشروع.',
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AbsenceRequestPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.access_time_rounded),
                  label: const Text('إدارة الغياب والحضور'),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'أفكار أولية:',
                  style: textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Card(
                  child: Column(
                    children: const [
                      _IdeaTile(
                        title: 'إضافة شاشة دخول/تسجيل',
                        subtitle: 'إنشاء صفحات المصادقة وربطها بالثيم الجديد.',
                        icon: Icons.login_rounded,
                      ),
                      Divider(height: 1),
                      _IdeaTile(
                        title: 'صفحة لوحة التحكم',
                        subtitle:
                            'عرض ملخص سريع للحالات والمهام الأكثر استخداماً.',
                        icon: Icons.dashboard_customize_rounded,
                      ),
                      Divider(height: 1),
                      _IdeaTile(
                        title: 'مكتبة مكونات مشتركة',
                        subtitle:
                            'أزرار، حقول إدخال، وبطاقات قابلة لإعادة الاستخدام.',
                        icon: Icons.widgets_outlined,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      width: 260,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                description,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IdeaTile extends StatelessWidget {
  const _IdeaTile({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(
        title,
        style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        subtitle,
        style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textSecondary,
      ),
    );
  }
}
