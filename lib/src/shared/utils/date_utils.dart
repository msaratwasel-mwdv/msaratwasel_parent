import 'package:intl/intl.dart';

String formatTime(
  DateTime date, {
  String pattern = 'h:mm a',
  String locale = 'ar',
}) {
  return DateFormat(pattern, locale).format(date);
}

String formatDateShort(DateTime date, {String locale = 'ar'}) {
  return DateFormat('d MMM', locale).format(date);
}

String formatDateLong(DateTime date, {String locale = 'ar'}) {
  return DateFormat('EEEE, d MMMM', locale).format(date);
}

String formatDate(DateTime date, {String locale = 'ar'}) {
  return DateFormat('EEEE, d MMMM', locale).format(date);
}

String timeOnly(DateTime date, {String locale = 'ar'}) {
  return DateFormat('h:mm a', locale).format(date);
}

String timeAgo(DateTime date, {String locale = 'ar'}) {
  final diff = DateTime.now().difference(date);
  final lang = locale.startsWith('en') ? 'en' : 'ar';

  if (diff.inSeconds < 60) return lang == 'en' ? 'just now' : 'قبل ثوانٍ';
  if (diff.inMinutes < 60) {
    final value = diff.inMinutes;
    return lang == 'en' ? '$value min ago' : 'قبل $value دقيقة';
  }
  if (diff.inHours < 24) {
    final value = diff.inHours;
    return lang == 'en' ? '$value h ago' : 'قبل $value ساعة';
  }
  final value = diff.inDays;
  return lang == 'en' ? '$value d ago' : 'قبل $value يوم';
}
