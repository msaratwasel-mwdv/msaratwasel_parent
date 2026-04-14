import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

final AppLogger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 5,
    lineLength: 80,
    colors: true,
    printEmojis: true,
    dateTimeFormat: DateTimeFormat.none,
  ),
  level: kReleaseMode ? Level.off : Level.trace,
);
