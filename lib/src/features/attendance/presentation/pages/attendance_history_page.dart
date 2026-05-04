import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:msaratwasel_user/src/shared/localization/app_strings.dart';
import 'package:msaratwasel_user/src/shared/theme/app_colors.dart';
import 'package:msaratwasel_user/src/shared/theme/app_spacing.dart';
import 'package:msaratwasel_user/src/shared/presentation/widgets/app_sliver_header.dart';
import 'package:msaratwasel_user/src/features/attendance/presentation/widgets/child_selector.dart';
import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/core/network/api_client.dart';
import 'package:msaratwasel_user/src/core/storage/storage_service.dart';
import 'package:msaratwasel_user/src/core/models/app_models.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart' as intl;

class AttendanceHistoryPage extends StatefulWidget {
  const AttendanceHistoryPage({super.key});

  @override
  State<AttendanceHistoryPage> createState() => _AttendanceHistoryPageState();
}

class _AttendanceHistoryPageState extends State<AttendanceHistoryPage> {
  Student? _selectedChild;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isLoading = false;

  final Map<DateTime, Map<String, dynamic>> _attendanceEvents = {};
  int _presentCount = 0;
  int _absentCount = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_selectedChild == null) {
      final students = AppScope.of(context).students;
      if (students.isNotEmpty) {
        _selectedChild = students.first;
        _fetchAttendanceData();
      }
    }
  }

  Future<void> _fetchAttendanceData() async {
    if (_selectedChild == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final storage = StorageService();
      final apiClient = ApiClient(storage: storage);
      final response = await apiClient.client.get(
        '/parent/children/${_selectedChild!.id}/attendance',
        queryParameters: {
          'year': _focusedDay.year,
          'month': _focusedDay.month,
        },
      );

      final data = response.data['data'];
      final logs = data['logs'] as Map<String, dynamic>;
      final summary = data['summary'] as Map<String, dynamic>;

      _attendanceEvents.clear();
      logs.forEach((dateStr, val) {
        final parts = dateStr.split('-');
        if (parts.length == 3) {
          final date = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
          _attendanceEvents[date] = val as Map<String, dynamic>;
        }
      });

      _presentCount = summary['present_days'] ?? 0;
      _absentCount = summary['absent_days'] ?? 0;
    } catch (e) {
      // Ignored for UI
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onChildSelected(Student child) {
    if (_selectedChild?.id == child.id) return;
    setState(() {
      _selectedChild = child;
    });
    _fetchAttendanceData();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = AppScope.of(context).locale;
    final isArabic = locale.languageCode == 'ar';

    final students = AppScope.of(context).students;

    return Scaffold(
      backgroundColor: isDark
          ? Theme.of(context).scaffoldBackgroundColor
          : const Color(0xFFF8F9FD),
      body: CustomScrollView(
        slivers: [
          AppSliverHeader(
            title: context.t('attendanceHistory'),
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
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Child Selector shared widget
                  if (students.isNotEmpty)
                    ChildSelector(
                      children: students,
                      selectedChild: _selectedChild,
                      onChildSelected: _onChildSelected,
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Text(
                        isArabic ? 'لا يوجد أبناء مسجلون' : 'No children found',
                        textAlign: TextAlign.center,
                      ),
                    ),

                  const SizedBox(height: AppSpacing.lg),
                  // Summary Cards
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          title: context.t('absentDays'),
                          count: _absentCount,
                          color: const Color(0xFFEF5350),
                          icon: Icons.cancel_rounded,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _SummaryCard(
                          title: context.t('presentDays'),
                          count: _presentCount,
                          color: const Color(0xFF00C853),
                          icon: Icons.check_circle_rounded,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Calendar View
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        // Custom Header
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.chevron_left_rounded,
                                  size: 30,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                ),
                                onPressed: () {
                                  if (!_isLoading) {
                                    setState(() {
                                      _focusedDay = DateTime(
                                        _focusedDay.year,
                                        _focusedDay.month - 1,
                                      );
                                    });
                                    _fetchAttendanceData();
                                  }
                                },
                              ),
                              Text(
                                intl.DateFormat.yMMMM(
                                  locale.languageCode,
                                ).format(_focusedDay),
                                style: GoogleFonts.cairo(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.chevron_right_rounded,
                                  size: 30,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                ),
                                onPressed: () {
                                  if (!_isLoading) {
                                    setState(() {
                                      _focusedDay = DateTime(
                                        _focusedDay.year,
                                        _focusedDay.month + 1,
                                      );
                                    });
                                    _fetchAttendanceData();
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        // Clipped & Zoomed Calendar Grid
                        ClipRect(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              // We want 5 days to fill the width.
                              // Standard calendar has 7 days.
                              // So we make the calendar width = constraints.maxWidth * (7/5)
                              // Alignment.centerRight keeps Sunday-Thursday visible (in RTL logic)
                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const NeverScrollableScrollPhysics(),
                                child: SizedBox(
                                  // Force width to show 5 days
                                  width: constraints.maxWidth * (7 / 5),
                                  child: _isLoading
                                      ? const Center(child: Padding(
                                        padding: EdgeInsets.all(32.0),
                                        child: CircularProgressIndicator(),
                                      ))
                                      : TableCalendar(
                                      firstDay: DateTime.utc(2020, 1, 1),
                                    lastDay: DateTime.utc(2030, 12, 31),
                                    focusedDay: _focusedDay,
                                    locale: locale.languageCode,
                                    startingDayOfWeek: StartingDayOfWeek.sunday,
                                    weekendDays: const [DateTime.friday, DateTime.saturday],
                                    calendarFormat: CalendarFormat.month,
                                    availableCalendarFormats: {
                                      CalendarFormat.month: isArabic
                                          ? 'شهر'
                                          : 'Month',
                                    },
                                    headerVisible: false, // Use custom header
                                    daysOfWeekHeight: 40,
                                    daysOfWeekStyle: DaysOfWeekStyle(
                                      weekdayStyle: GoogleFonts.cairo(
                                        color: const Color(0xFF64748B),
                                        fontWeight: FontWeight.bold,
                                      ),
                                      weekendStyle: GoogleFonts.cairo(
                                        color: const Color(0xFFEF5350),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    // Adjusted rowHeight to be standard and square-like
                                    rowHeight: 54,
                                    calendarBuilders: CalendarBuilders(
                                      // We don't need to hide weekends manually anymore since they are clipped off-screen
                                      defaultBuilder:
                                          (context, day, focusedDay) {
                                            if (day.weekday == DateTime.friday || day.weekday == DateTime.saturday) {
                                              return _buildDateCell(day, isDark: isDark);
                                            }
                                            return _buildDateCell(
                                              day,
                                              isDark: isDark,
                                            );
                                          },
                                      todayBuilder: (context, day, focusedDay) {
                                        return _buildDateCell(
                                          day,
                                          isDark: isDark,
                                          isToday: true,
                                        );
                                      },
                                      selectedBuilder:
                                          (context, day, focusedDay) {
                                            return _buildDateCell(
                                              day,
                                              isDark: isDark,
                                              isSelected: true,
                                            );
                                          },
                                      prioritizedBuilder:
                                          (context, day, focusedDay) {
                                            final normalizedDay = DateTime(
                                              day.year,
                                              day.month,
                                              day.day,
                                            );
                                            final event =
                                                _attendanceEvents[normalizedDay];
                                            if (event != null) {
                                              return _buildEventCell(
                                                day,
                                                event,
                                                isDark,
                                              );
                                            }
                                            return null;
                                          },
                                    ),
                                    onDaySelected: (selectedDay, focusedDay) {
                                      setState(() {
                                        _selectedDay = selectedDay;
                                        _focusedDay = focusedDay;
                                      });
                                    },
                                    onPageChanged: (focusedDay) {
                                      setState(() {
                                        _focusedDay = focusedDay;
                                      });
                                      _fetchAttendanceData();
                                    },
                                    selectedDayPredicate: (day) =>
                                        isSameDay(_selectedDay, day),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateCell(
    DateTime day, {
    required bool isDark,
    bool isToday = false,
    bool isSelected = false,
  }) {
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.transparent : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(color: const Color(0xFF0F172A), width: 1.5)
            : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 8,
            child: Text(
              '${day.day}',
              style: TextStyle(
                color: isToday
                    ? AppColors.primary
                    : (isDark ? Colors.white : const Color(0xFF1E293B)),
                fontWeight: isToday || isSelected
                    ? FontWeight.bold
                    : FontWeight.normal,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCell(
    DateTime day,
    Map<String, dynamic> event,
    bool isDark,
  ) {
    Color bg = Colors.transparent;
    Color text = isDark ? Colors.white : AppColors.textPrimary;

    if (event['status'] == 'present') {
      bg = const Color(0xFFE8F5E9); // Light Green
      text = const Color(0xFF2E7D32); // Dark Green
    } else if (event['status'] == 'absent') {
      bg = const Color(0xFFFFEBEE); // Light Red
      text = const Color(0xFFC62828); // Dark Red
    }

    return Container(
      margin: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Center(
        child: Text(
          '${day.day}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: text,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.count,
    required this.color,
    required this.icon,
    required this.isDark,
  });

  final String title;
  final int count;
  final Color color;
  final IconData icon;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90, // Fixed height to match design
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey[200]!),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                count.toString(),
                style: GoogleFonts.cairo(
                  fontSize: 22, // Bigger number
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              Icon(icon, color: color, size: 22),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.cairo(
              fontSize: 12,
              color: isDark ? Colors.white70 : const Color(0xFF94A3B8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
