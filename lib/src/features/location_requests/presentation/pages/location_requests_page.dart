import 'package:flutter/material.dart';
import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/core/models/app_models.dart';
import 'package:msaratwasel_user/src/shared/localization/app_strings.dart';
import 'package:msaratwasel_user/src/shared/theme/app_colors.dart';
import 'package:msaratwasel_user/src/shared/theme/app_spacing.dart';
import 'package:msaratwasel_user/src/shared/presentation/widgets/app_sliver_header.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class LocationRequestsPage extends StatefulWidget {
  const LocationRequestsPage({super.key});

  @override
  State<LocationRequestsPage> createState() => _LocationRequestsPageState();
}

class _LocationRequestsPageState extends State<LocationRequestsPage> {
  @override
  void initState() {
    super.initState();
    // Refresh history when entering the page to ensure latest status
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPendingNotification();
      AppScope.of(context).loadLocationRequestsFromApi();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPendingNotification();
    });
  }

  void _checkPendingNotification() {
    if (!mounted) return;
    final appScope = AppScope.of(context);
    final pendingId = appScope.pendingNotificationId;
    if (pendingId != null) {
      // Consume the pending notification
      appScope.clearPendingNotificationId();
      // Force refresh data
      appScope.loadLocationRequestsFromApi();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appScope = AppScope.of(context);
    final requests = appScope.locationRequests;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? null : const Color(0xFFF8F9FD),
      child: CustomScrollView(
        slivers: [
          AppSliverHeader(
            title: context.t('locationRequests'),
          ),
          SliverFillRemaining(
            child: RefreshIndicator(
                    onRefresh: () => appScope.loadLocationRequestsFromApi(),
                    color: isDark
                        ? Theme.of(context).colorScheme.secondary
                        : AppColors.primary,
                    backgroundColor: isDark
                        ? const Color(0xFF1E293B)
                        : Colors.white,
                    child: requests.isEmpty
                        ? _buildEmptyState(context)
                        : _buildRequestsList(context, requests, isDark),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off_outlined,
            size: 64,
            color: Theme.of(context).disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            context.t('noLocationRequests'),
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).disabledColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsList(
    BuildContext context,
    List<LocationChangeRequest> requests,
    bool isDark,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return _buildRequestCard(context, request, isDark);
      },
    );
  }

  Widget _buildRequestCard(
    BuildContext context,
    LocationChangeRequest request,
    bool isDark,
  ) {

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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Builder(
                      builder: (context) {
                        final student = AppScope.of(context).students.where((s) => s.id == request.studentId).firstOrNull;
                        final displayName = student != null 
                          ? student.getLocalizedName(Localizations.localeOf(context).languageCode)
                          : request.studentName;
                        
                        return Text(
                          displayName,
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        );
                      }
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat(
                            'yyyy-MM-dd HH:mm',
                          ).format(request.createdAt),
                          style: GoogleFonts.cairo(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(context, request.status),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark 
                      ? Colors.white.withValues(alpha: 0.1) 
                      : AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.location_on,
                  size: 16,
                  color: isDark ? Colors.white : AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.t('newLocation'),
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${request.newLatitude?.toStringAsFixed(6) ?? '0.000000'}, ${request.newLongitude?.toStringAsFixed(6) ?? '0.000000'}',
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (request.rejectionReason != null &&
              request.rejectionReason!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 14,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        context.t('rejectionReason'),
                        style: GoogleFonts.cairo(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    request.rejectionReason!,
                    style: GoogleFonts.cairo(
                      color: Colors.red[700],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, String status) {
    final color = _getStatusColor(status);
    final label = _getStatusText(context, status);

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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(BuildContext context, String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return context.t('statusApproved');
      case 'rejected':
        return context.t('statusRejected');
      case 'pending':
        return context.t('statusPending');
      default:
        return status;
    }
  }
}
