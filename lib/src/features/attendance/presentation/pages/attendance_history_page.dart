import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:msaratwasel_user/src/shared/localization/app_strings.dart';
import 'package:msaratwasel_user/src/shared/theme/app_colors.dart';
import 'package:msaratwasel_user/src/shared/theme/app_spacing.dart';
import 'package:msaratwasel_user/src/shared/presentation/widgets/app_sliver_header.dart';
import 'package:msaratwasel_user/src/features/attendance/presentation/widgets/child_selector.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart' as intl;

class AttendanceHistoryPage extends StatefulWidget {
  const AttendanceHistoryPage({super.key});

  @override
  State<AttendanceHistoryPage> createState() => _AttendanceHistoryPageState();
}

class _AttendanceHistoryPageState extends State<AttendanceHistoryPage> {
  // Mock Data
  final List<AttendanceChild> _children = [
    AttendanceChild(id: '1', name: 'أحمد', grade: 'الخامس - أ'),
    AttendanceChild(id: '2', name: 'سارة', grade: 'الثاني - ب'),
  ];

  late AttendanceChild _selectedChild;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Mock Attendance Logs for Calendar
  // Map Key: DateTime(year, month, day) - normalize time
  final Map<DateTime, Map<String, dynamic>> _attendanceEvents = {};

  @override
  void initState() {
    super.initState();
    _selectedChild = _children.first;
    _generateMockData();
  }

  void _generateMockData() {
    // Generate some random data for the current month
    final now = DateTime.now();
    // Helper to normalize date to midnight
    DateTime normalize(DateTime date) =>
        DateTime(date.year, date.month, date.day);

    _attendanceEvents[normalize(now.subtract(const Duration(days: 0)))] = {
      'status': 'present',
      'label': 'حاضر',
    }; // Today
    _attendanceEvents[normalize(now.subtract(const Duration(days: 2)))] = {
      'status': 'absent',
      'label': 'غياب',
    };
    _attendanceEvents[normalize(now.subtract(const Duration(days: 3)))] = {
      'status': 'present',
      'label': 'حاضر',
    };
    _attendanceEvents[normalize(now.subtract(const Duration(days: 4)))] = {
      'status': 'present',
      'label': 'حاضر',
    };
    _attendanceEvents[normalize(now.subtract(const Duration(days: 5)))] = {
      'status': 'excused',
      'label': 'عذر',
    };
    // Weekend logic is handled by calendar builder, events are extra
  }

  void _onChildSelected(AttendanceChild child) {
    setState(() {
      _selectedChild = child;
      // In a real app, fetch new data for this child here
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Calculate stats for the viewed month
    int presentCount = 0;
    int absentCount = 0;

    _attendanceEvents.forEach((date, event) {
      if (date.month == _focusedDay.month) {
        if (event['status'] == 'present') presentCount++;
        if (event['status'] == 'absent') absentCount++;
      }
    });

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
                  ChildSelector(
                    children: _children,
                    selectedChild: _selectedChild,
                    onChildSelected: _onChildSelected,
                  ),

                  const SizedBox(height: AppSpacing.lg),
                  // Summary Cards
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          title: context.t('absentDays'),
                          count: absentCount,
                          color: const Color(0xFFEF5350),
                          icon: Icons.cancel_rounded,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _SummaryCard(
                          title: context.t('presentDays'),
                          count: presentCount,
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
                                  setState(() {
                                    _focusedDay = DateTime(
                                      _focusedDay.year,
                                      _focusedDay.month - 1,
                                    );
                                  });
                                },
                              ),
                              Text(
                                intl.DateFormat.yMMMM('ar').format(_focusedDay),
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
                                  setState(() {
                                    _focusedDay = DateTime(
                                      _focusedDay.year,
                                      _focusedDay.month + 1,
                                    );
                                  });
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
                              return SizedBox(
                                height: 380, // Approximate height for content
                                child: Stack(
                                  children: [
                                    Positioned(
                                      right: 0, // Align to Start (Since RTL)
                                      top: 0,
                                      bottom: 0,
                                      width: constraints.maxWidth * (7 / 5),
                                      child: TableCalendar(
                                        firstDay: DateTime.utc(2023, 1, 1),
                                        lastDay: DateTime.utc(2030, 12, 31),
                                        focusedDay: _focusedDay,
                                        locale: 'ar',
                                        startingDayOfWeek:
                                            StartingDayOfWeek.sunday,
                                        weekendDays: const [],
                                        calendarFormat: CalendarFormat.month,
                                        availableCalendarFormats: const {
                                          CalendarFormat.month: 'شهر',
                                        },
                                        headerVisible:
                                            false, // Use custom header
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
                                        rowHeight:
                                            60, // Slightly reduced to fit nicely
                                        calendarBuilders: CalendarBuilders(
                                          // We don't need to hide weekends manually anymore since they are clipped off-screen
                                          defaultBuilder:
                                              (context, day, focusedDay) {
                                                return _buildDateCell(
                                                  day,
                                                  isDark: isDark,
                                                );
                                              },
                                          todayBuilder:
                                              (context, day, focusedDay) {
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
                                        onDaySelected:
                                            (selectedDay, focusedDay) {
                                              setState(() {
                                                _selectedDay = selectedDay;
                                                _focusedDay = focusedDay;
                                              });
                                            },
                                        onPageChanged: (focusedDay) {
                                          setState(() {
                                            _focusedDay = focusedDay;
                                          });
                                        },
                                        selectedDayPredicate: (day) =>
                                            isSameDay(_selectedDay, day),
                                      ),
                                    ),
                                  ],
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
    Color dotColor = Colors.transparent;

    if (event['status'] == 'present') {
      bg = const Color(0xFFE8F5E9); // Light Green
      text = const Color(0xFF2E7D32); // Dark Green
      dotColor = const Color(0xFF2E7D32);
    } else if (event['status'] == 'absent') {
      bg = const Color(0xFFFFEBEE); // Light Red
      text = const Color(0xFFC62828); // Dark Red
      dotColor = const Color(0xFFC62828);
    } else if (event['status'] == 'excused') {
      bg = Colors.grey[100]!;
      text = Colors.grey[700]!;
      dotColor = Colors.grey[500]!;
    }

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bg), // To match sizing
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 6,
            child: Text(
              '${day.day}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: const Color(
                  0xFF1E293B,
                ), // Date always dark in design? Or match text? Screenshot shows black date for events.
                fontSize: 16,
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            child: Text(
              event['label'],
              style: GoogleFonts.cairo(
                fontSize: 10,
                color: text,
                fontWeight: FontWeight.bold,
                height: 1.0,
              ),
            ),
          ),
          Positioned(
            bottom: 6,
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
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
