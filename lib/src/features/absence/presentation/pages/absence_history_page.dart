import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/shared/presentation/widgets/app_sliver_header.dart';
import 'package:msaratwasel_user/src/shared/theme/app_colors.dart';
import 'package:msaratwasel_user/src/shared/theme/app_spacing.dart';
import 'package:msaratwasel_user/src/features/absence/domain/entities/absence_request.dart';
import 'package:msaratwasel_user/src/shared/localization/app_strings.dart';

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
            title: context.t('absenceLog'),
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
          ),
          if (history.isEmpty)
             SliverFillRemaining(
              child: Center(
                child: Text(context.t('noAbsenceHistory')),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.md),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final req = history[index];
                    return _buildHistoryCard(context, req, isDark);
                  },
                  childCount: history.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, AbsenceRequest req, bool isDark) {
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
                req.studentName ?? context.t('student'),
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              _buildStatusBadge(context, req.status),
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
                _getTypeLabel(context, req.type),
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
              context.t('rejectionReason'),
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

  Widget _buildStatusBadge(BuildContext context, String? status) {
    Color color;
    String label;

    switch (status) {
      case 'approved':
        color = Colors.green;
        label = context.t('statusApproved');
        break;
      case 'rejected':
        color = Colors.red;
        label = context.t('statusRejected');
        break;
      case 'pending':
      default:
        color = Colors.orange;
        label = context.t('statusPending');
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

  String _getTypeLabel(BuildContext context, AbsenceType type) {
    switch (type) {
      case AbsenceType.morning:
        return context.t('morningOnly');
      case AbsenceType.returnOnly:
        return context.t('eveningOnly');
      case AbsenceType.both:
        return context.t('fullDay');
    }
  }
}
