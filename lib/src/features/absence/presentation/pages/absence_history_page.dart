import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/shared/presentation/widgets/app_sliver_header.dart';
import 'package:msaratwasel_user/src/shared/theme/app_colors.dart';
import 'package:msaratwasel_user/src/shared/theme/app_spacing.dart';
import 'package:msaratwasel_user/src/features/absence/domain/entities/absence_request.dart';

class AbsenceHistoryPage extends StatefulWidget {
  const AbsenceHistoryPage({super.key});

  @override
  State<AbsenceHistoryPage> createState() => _AbsenceHistoryPageState();
}

class _AbsenceHistoryPageState extends State<AbsenceHistoryPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppScope.of(context).loadAbsenceRequestsFromApi();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final history = controller.absenceRequests;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? null : const Color(0xFFF8F9FD),
      body: CustomScrollView(
        slivers: [
          AppSliverHeader(
            title: 'سجل الغياب',
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : AppColors.primary),
              onPressed: () => AppScope.of(context).moveBack(),
            ),
          ),
          if (history.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text('لا يوجد طلبات غياب سابقة'),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.md),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final req = history[index];
                    return _buildHistoryCard(req, isDark);
                  },
                  childCount: history.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(AbsenceRequest req, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                req.studentName ?? 'طالب',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              _buildStatusBadge(req.status),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                "${req.date.year}-${req.date.month}-${req.date.day}",
                style: GoogleFonts.cairo(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.access_time, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                _getTypeLabel(req.type),
                style: GoogleFonts.cairo(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
          if (req.note != null && req.note!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              req.note!,
              style: GoogleFonts.cairo(fontSize: 14),
            ),
          ],
          if (req.status == 'rejected' && req.rejectionReason != null) ...[
            const Divider(height: 24),
            Text(
              'سبب الرفض:',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 13),
            ),
            Text(
              req.rejectionReason!,
              style: GoogleFonts.cairo(color: Colors.red[700], fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String? status) {
    Color color;
    String label;

    switch (status) {
      case 'approved':
        color = Colors.green;
        label = 'مقبول';
        break;
      case 'rejected':
        color = Colors.red;
        label = 'مرفوض';
        break;
      case 'pending':
      default:
        color = Colors.orange;
        label = 'قيد الانتظار';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.cairo(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getTypeLabel(AbsenceType type) {
    switch (type) {
      case AbsenceType.morning:
        return 'صباحي فقط';
      case AbsenceType.returnOnly:
        return 'مسائي فقط';
      case AbsenceType.both:
        return 'يوم كامل';
    }
  }
}
