import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:intl/date_symbol_data_local.dart';
import 'package:msaratwasel_user/src/core/storage/storage_service.dart';
import 'package:msaratwasel_user/src/core/utils/active_conversation_tracker.dart';
import 'package:msaratwasel_user/src/core/utils/result.dart';
import 'package:msaratwasel_user/src/shared/utils/date_utils.dart';
import 'package:msaratwasel_user/src/shared/utils/labels.dart';
import 'package:msaratwasel_user/src/features/about/data/repositories/about_repository_impl.dart';
import 'package:msaratwasel_user/src/features/communication/data/repositories/communication_repository_impl.dart';
import 'package:msaratwasel_user/src/features/communication/domain/entities/message_thread.dart';
import 'package:msaratwasel_user/src/features/language/data/repositories/language_repository_impl.dart';
import 'package:msaratwasel_user/src/features/students/data/repositories/students_repository_impl.dart';
import 'package:msaratwasel_user/src/features/students/domain/entities/student.dart' as student_domain;
import 'package:msaratwasel_user/src/core/models/app_models.dart' hide Student;
import 'package:msaratwasel_user/src/app/state/app_controller.dart';

class MockDio extends Mock implements Dio {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockDio mockDio;

  setUpAll(() async {
    await initializeDateFormatting('en', null);
    await initializeDateFormatting('ar', null);
  });

  setUp(() {
    mockDio = MockDio();
  });

  group('AboutRepositoryImpl Suite', () {
    late AboutRepositoryImpl repo;

    setUp(() {
      repo = AboutRepositoryImpl(dio: mockDio);
    });

    test('1. fetchAbout calls guardian/about and completes normally on 200', () async {
      when(() => mockDio.get('guardian/about')).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: 'guardian/about'),
            statusCode: 200,
            data: {'school': 'Al-Amal School', 'version': '1.0.0'},
          ));

      await expectLater(repo.fetchAbout(), completes);
      verify(() => mockDio.get('guardian/about')).called(1);
    });

    test('2. fetchAbout bubbles DioException on network/server failure', () async {
      when(() => mockDio.get('guardian/about')).thenThrow(DioException(
        requestOptions: RequestOptions(path: 'guardian/about'),
        type: DioExceptionType.connectionTimeout,
        error: 'Timeout connecting to server',
      ));

      expect(() => repo.fetchAbout(), throwsA(isA<DioException>()));
    });
  });

  group('CommunicationRepositoryImpl Suite', () {
    late CommunicationRepositoryImpl repo;

    setUp(() {
      repo = CommunicationRepositoryImpl(dio: mockDio);
    });

    test('3. fetchThread fetches thread and maps participants and messages', () async {
      final threadJson = {
        'data': {
          'id': 'thread_101',
          'participants': [
            {'name': 'Teacher Sarah'},
            {'name': 'Guardian Ali'},
          ],
          'messages': [
            {
              'id': 'm1',
              'sender_name': 'Teacher Sarah',
              'body': 'Good morning, please note the early dismissal.',
              'created_at': '2026-09-04T08:30:00.000Z',
              'is_incoming': true,
            },
            {
              'id': 'm2',
              'sender_name': 'Guardian Ali',
              'body': 'Understood, thank you.',
              'created_at': '2026-09-04T08:35:00.000Z',
              'is_incoming': false,
            },
          ],
        },
      };

      when(() => mockDio.get('guardian/communication/threads/thread_101'))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: 'guardian/communication/threads/thread_101'),
                statusCode: 200,
                data: threadJson,
              ));

      final thread = await repo.fetchThread('thread_101');

      expect(thread.id, 'thread_101');
      expect(thread.participants, ['Teacher Sarah', 'Guardian Ali']);
      expect(thread.messages.length, 2);
      expect(thread.messages[0].id, 'm1');
      expect(thread.messages[0].sender, 'Teacher Sarah');
      expect(thread.messages[0].text, 'Good morning, please note the early dismissal.');
      expect(thread.messages[0].incoming, isTrue);
      expect(thread.messages[1].id, 'm2');
      expect(thread.messages[1].incoming, isFalse);
    });

    test('4. fetchThread handles null or empty fields safely', () async {
      final minimalJson = {
        'data': {
          'id': 999,
          'participants': null,
          'messages': null,
        },
      };

      when(() => mockDio.get('guardian/communication/threads/999'))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: 'guardian/communication/threads/999'),
                statusCode: 200,
                data: minimalJson,
              ));

      final thread = await repo.fetchThread('999');

      expect(thread.id, '999');
      expect(thread.participants, isEmpty);
      expect(thread.messages, isEmpty);
    });

    test('5. sendMessage posts body to guardian/communication/threads/{id}/messages', () async {
      when(() => mockDio.post(
            'guardian/communication/threads/thread_55/messages',
            data: {'body': 'Hello there'},
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: 'guardian/communication/threads/thread_55/messages'),
            statusCode: 200,
          ));

      await expectLater(
        repo.sendMessage(threadId: 'thread_55', text: 'Hello there'),
        completes,
      );

      verify(() => mockDio.post(
            'guardian/communication/threads/thread_55/messages',
            data: {'body': 'Hello there'},
          )).called(1);
    });
  });

  group('LanguageRepositoryImpl Suite', () {
    late LanguageRepositoryImpl repo;
    late StorageService storageService;

    setUp(() {
      SharedPreferences.setMockInitialValues({'app_locale': 'en'});
      storageService = StorageService();
      repo = LanguageRepositoryImpl(storageService: storageService);
    });

    test('6. setLocale and getSavedLocale persist and retrieve locale correctly', () async {
      expect(await repo.getSavedLocale(), 'en');

      await repo.setLocale('ar');
      expect(await repo.getSavedLocale(), 'ar');
    });
  });

  group('StudentsRepositoryImpl Extended Suite', () {
    late StudentsRepositoryImpl repo;

    setUp(() {
      repo = StudentsRepositoryImpl(dio: mockDio);
    });

    test('7. fetchStudent filters and returns single student from children endpoint', () async {
      final childrenJson = {
        'data': [
          {
            'id': 'st_1',
            'name': 'Sami',
            'grade': 'Grade 4',
            'bus': {'number': 'B12'},
            'image_url': 'https://example.com/sami.jpg',
          },
          {
            'id': 'st_2',
            'name': 'Lina',
            'grade': 'Grade 2',
            'bus': {'number': 'B14'},
            'image_url': null,
          },
        ],
      };

      when(() => mockDio.get('parent/children')).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: 'parent/children'),
            statusCode: 200,
            data: childrenJson,
          ));

      final student = await repo.fetchStudent('st_2');
      expect(student.id, 'st_2');
      expect(student.name, 'Lina');
      expect(student.grade, 'Grade 2');
      expect(student.busNumber, 'B14');
    });

    test('8. addStudent posts national_id to parent/children/link', () async {
      when(() => mockDio.post(
            'parent/children/link',
            data: {'national_id': '1099887766'},
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: 'parent/children/link'),
            statusCode: 200,
          ));

      final studentToAdd = student_domain.Student(
        id: '1099887766',
        name: 'New Student',
        grade: 'Grade 1',
        busNumber: 'B1',
      );

      await expectLater(repo.addStudent(studentToAdd), completes);
      verify(() => mockDio.post(
            'parent/children/link',
            data: {'national_id': '1099887766'},
          )).called(1);
    });
  });

  group('ActiveConversationTracker Suite', () {
    test('9. ActiveConversationTracker lifecycle set and clear', () {
      ActiveConversationTracker.clearActiveConversation();
      expect(ActiveConversationTracker.activeConversationId, isNull);

      ActiveConversationTracker.setActiveConversation('conversation_999');
      expect(ActiveConversationTracker.activeConversationId, 'conversation_999');

      ActiveConversationTracker.clearActiveConversation();
      expect(ActiveConversationTracker.activeConversationId, isNull);
    });
  });

  group('Result<T> Sealed Class Suite', () {
    test('10. Success and Failure branches execute properly in when()', () {
      const Result<int> successResult = Success(100);
      final successValue = successResult.when(
        success: (data) => data * 2,
        failure: (e, s) => -1,
      );
      expect(successValue, 200);

      final stack = StackTrace.current;
      final Result<int> failureResult = Failure(Exception('Network down'), stack);
      final failureValue = failureResult.when(
        success: (data) => 'Success: $data',
        failure: (e, s) => 'Failed: $e',
      );
      expect(failureValue, contains('Network down'));
    });
  });

  group('DateUtils Formatting Suite', () {
    test('11. formatTime, formatDateShort, formatDateLong, timeOnly', () {
      final date = DateTime(2026, 9, 4, 14, 30);

      final formattedShort = formatDateShort(date, locale: 'en');
      expect(formattedShort, contains('4 Sep'));

      final formattedLong = formatDateLong(date, locale: 'en');
      expect(formattedLong, contains('September'));

      final formattedDate = formatDate(date, locale: 'en');
      expect(formattedDate, contains('September'));

      final formattedTimeOnly = timeOnly(date, locale: 'en');
      expect(formattedTimeOnly, contains('2:30'));

      final formattedTimeCustom = formatTime(date, pattern: 'HH:mm', locale: 'en');
      expect(formattedTimeCustom, '14:30');
    });

    test('12. timeAgo relative formatting across intervals and locales', () {
      final now = DateTime.now();

      // < 60 seconds
      final secondsAgo = now.subtract(const Duration(seconds: 25));
      expect(timeAgo(secondsAgo, locale: 'en'), 'just now');
      expect(timeAgo(secondsAgo, locale: 'ar'), 'قبل ثوانٍ');

      // 10 minutes ago
      final minutesAgo = now.subtract(const Duration(minutes: 10));
      expect(timeAgo(minutesAgo, locale: 'en'), '10 min ago');
      expect(timeAgo(minutesAgo, locale: 'ar'), 'قبل 10 دقيقة');

      // 3 hours ago
      final hoursAgo = now.subtract(const Duration(hours: 3));
      expect(timeAgo(hoursAgo, locale: 'en'), '3 h ago');
      expect(timeAgo(hoursAgo, locale: 'ar'), 'قبل 3 ساعة');

      // 2 days ago
      final daysAgo = now.subtract(const Duration(days: 2));
      expect(timeAgo(daysAgo, locale: 'en'), '2 d ago');
      expect(timeAgo(daysAgo, locale: 'ar'), 'قبل 2 يوم');
    });
  });

  group('Labels Suite', () {
    testWidgets('13. Labels maps studentStatus, busState, and attendanceDirection strings', (tester) async {
      final controller = AppController();
      controller.setLocale(const Locale('ar'));

      await tester.pumpWidget(
        AppScope(
          controller: controller,
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Builder(
                  builder: (context) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(Labels.studentStatus(context, StudentStatus.waitingAtHome)),
                        Text(Labels.studentStatus(context, StudentStatus.arrivedHome)),
                        Text(Labels.studentStatus(context, StudentStatus.onBusToSchool)),
                        Text(Labels.studentStatus(context, StudentStatus.atSchool)),
                        Text(Labels.studentStatus(context, StudentStatus.notBoarded)),
                        Text(Labels.studentStatus(context, StudentStatus.late)),
                        Text(Labels.busState(context, BusState.pending)),
                        Text(Labels.busState(context, BusState.enRoute)),
                        Text(Labels.busState(context, BusState.atSchool)),
                        Text(Labels.busState(context, BusState.atHome)),
                        Text(Labels.attendanceDirection(context, AttendanceDirection.outbound)),
                        Text(Labels.attendanceDirection(context, AttendanceDirection.inbound)),
                        Text(Labels.attendanceDirection(context, AttendanceDirection.fullDay)),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Expect Arabic labels
      expect(find.text('في المنزل'), findsAtLeastNWidgets(1));
      expect(find.text('في الحافلة'), findsOneWidget);
      expect(find.text('في المدرسة'), findsOneWidget);
      expect(find.text('لم يصعد'), findsOneWidget);
      expect(find.text('متأخر'), findsOneWidget);
      expect(find.text('الرحلة قيد الانتظار'), findsOneWidget);
      expect(find.text('في الطريق'), findsOneWidget);
      expect(find.text('وصلت المدرسة'), findsOneWidget);
      expect(find.text('وصلت المنزل'), findsNWidgets(2));
      expect(find.text('ذهاب'), findsOneWidget);
      expect(find.text('عودة'), findsOneWidget);
      expect(find.text('يوم كامل'), findsOneWidget);
    });
  });
}
