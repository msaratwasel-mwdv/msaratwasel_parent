import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:msaratwasel_user/src/features/absence/data/repositories/absence_repository_impl.dart';
import 'package:msaratwasel_user/src/features/absence/domain/entities/absence_request.dart';
import 'package:msaratwasel_user/src/features/students/data/repositories/students_repository_impl.dart';
import 'package:msaratwasel_user/src/features/students/domain/entities/student.dart';
import 'package:msaratwasel_user/src/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:msaratwasel_user/src/features/profile/domain/entities/profile.dart';
import 'package:msaratwasel_user/src/features/tracking/data/repositories/tracking_repository_impl.dart';
import 'package:msaratwasel_user/src/features/tracking/domain/entities/bus_position.dart';
import 'package:msaratwasel_user/src/features/chat/data/repositories/chat_repository.dart';
import 'package:msaratwasel_user/src/features/chat/data/models/chat_models.dart';
import 'package:msaratwasel_user/src/features/complaints/data/repositories/complaints_repository_impl.dart';
import 'package:msaratwasel_user/src/features/complaints/domain/entities/complaint.dart';
import 'package:msaratwasel_user/src/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:msaratwasel_user/src/features/auth/domain/entities/auth_user.dart';
import 'package:msaratwasel_user/src/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:msaratwasel_user/src/features/dashboard/domain/entities/child_summary.dart';
import 'package:msaratwasel_user/src/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:msaratwasel_user/src/core/models/app_models.dart' hide Student;

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
  });

  group('AbsenceRepositoryImpl Suite', () {
    late AbsenceRepositoryImpl repo;

    setUp(() {
      repo = AbsenceRepositoryImpl(dio: mockDio);
    });

    test('1. submitAbsence sends correct POST payload for each student', () async {
      when(() => mockDio.post(
            any(),
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: 'parent/absence-requests'),
            statusCode: 200,
          ));

      final request = AbsenceRequest(
        studentIds: ['s1', 's2'],
        type: AbsenceType.morning,
        date: DateTime(2026, 9, 10),
        note: 'Doctor appointment',
      );

      await repo.submitAbsence(request);

      verify(() => mockDio.post(
            'parent/absence-requests',
            data: {
              'student_id': 's1',
              'date': '2026-09-10',
              'type': 'morning',
              'reason': 'Doctor appointment',
            },
          )).called(1);

      verify(() => mockDio.post(
            'parent/absence-requests',
            data: {
              'student_id': 's2',
              'date': '2026-09-10',
              'type': 'morning',
              'reason': 'Doctor appointment',
            },
          )).called(1);
    });

    test('2. fetchHistory parses list of AbsenceRequest correctly', () async {
      when(() => mockDio.get('parent/absence-requests')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: 'parent/absence-requests'),
          statusCode: 200,
          data: {
            'data': [
              {
                'id': 10,
                'student_id': 50,
                'student_name': 'Omar',
                'type': 'afternoon',
                'date': '2026-09-12',
                'reason': 'Family event',
                'status': 'approved',
                'rejection_reason': null,
              },
              {
                'id': 11,
                'student_id': 51,
                'student_name': 'Sara',
                'type': 'full_day',
                'date': '2026-09-13',
                'reason': 'Flu',
                'status': 'pending',
                'rejection_reason': null,
              }
            ]
          },
        ),
      );

      final history = await repo.fetchHistory();

      expect(history.length, 2);
      expect(history[0].id, '10');
      expect(history[0].studentIds, ['50']);
      expect(history[0].studentName, 'Omar');
      expect(history[0].type, AbsenceType.returnOnly);
      expect(history[0].status, 'approved');

      expect(history[1].id, '11');
      expect(history[1].type, AbsenceType.both);
    });
  });

  group('StudentsRepositoryImpl Suite', () {
    late StudentsRepositoryImpl repo;

    setUp(() {
      repo = StudentsRepositoryImpl(dio: mockDio);
    });

    test('3. fetchStudents returns parsed Student list', () async {
      when(() => mockDio.get('parent/children')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: 'parent/children'),
          statusCode: 200,
          data: {
            'data': [
              {
                'id': 'st_1',
                'name': 'Fahad',
                'grade': '4A',
                'bus': {'number': '12', 'plate': 'ABC-1234'},
                'image_url': 'https://api.msaratwasel.com/photos/f1.jpg',
              }
            ]
          },
        ),
      );

      final students = await repo.fetchStudents();

      expect(students.length, 1);
      expect(students.first.id, 'st_1');
      expect(students.first.name, 'Fahad');
      expect(students.first.grade, '4A');
      expect(students.first.busNumber, '12');
    });

    test('4. addStudent posts national_id to parent/children/link', () async {
      when(() => mockDio.post(
            'parent/children/link',
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: 'parent/children/link'),
            statusCode: 200,
          ));

      final student = Student(
        id: '1099887766',
        name: 'New Child',
        grade: '1B',
        busNumber: '5',
      );

      await repo.addStudent(student);

      verify(() => mockDio.post(
            'parent/children/link',
            data: {'national_id': '1099887766'},
          )).called(1);
    });
  });

  group('ProfileRepositoryImpl Suite', () {
    late ProfileRepositoryImpl repo;

    setUp(() {
      repo = ProfileRepositoryImpl(dio: mockDio);
    });

    test('5. fetchProfile parses user Profile from API response', () async {
      when(() => mockDio.get('parent/profile')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: 'parent/profile'),
          statusCode: 200,
          data: {
            'data': {
              'name': 'Abu Nasser',
              'phone': '0555555555',
              'email': 'parent@example.com',
              'image_url': 'https://api.msaratwasel.com/avatars/user.jpg',
            }
          },
        ),
      );

      final profile = await repo.fetchProfile();

      expect(profile.name, 'Abu Nasser');
      expect(profile.phone, '0555555555');
      expect(profile.email, 'parent@example.com');
      expect(profile.languageCode, 'ar');
    });

    test('6. updateProfile sends POST with updated phone and email', () async {
      when(() => mockDio.post(
            'parent/profile/update',
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: 'parent/profile/update'),
            statusCode: 200,
          ));

      final profile = Profile(
        name: 'Abu Nasser',
        phone: '0551112222',
        email: 'new_email@example.com',
        languageCode: 'ar',
      );

      await repo.updateProfile(profile);

      verify(() => mockDio.post(
            'parent/profile/update',
            data: {'phone': '0551112222', 'email': 'new_email@example.com'},
          )).called(1);
    });
  });

  group('TrackingRepositoryImpl Suite', () {
    late TrackingRepositoryImpl repo;

    setUp(() {
      repo = TrackingRepositoryImpl(dio: mockDio);
    });

    test('7. fetchLivePosition parses BusPosition coordinates and ETA', () async {
      when(() => mockDio.get('bus/bus_77/location')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: 'bus/bus_77/location'),
          statusCode: 200,
          data: {
            'latitude': 24.7136,
            'longitude': 46.6753,
            'eta_minutes': 8,
            'bus_number': 'Bus 77',
          },
        ),
      );

      final position = await repo.fetchLivePosition('bus_77');

      expect(position.lat, 24.7136);
      expect(position.lng, 46.6753);
      expect(position.etaMinutes, 8);
      expect(position.busNumber, 'Bus 77');
    });
  });

  group('ChatRepository & Models Suite', () {
    late ChatRepository repo;

    setUp(() {
      repo = ChatRepository(dio: mockDio);
    });

    test('8. ChatContact fromJson and getContacts', () async {
      when(() => mockDio.get('chat/contacts')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: 'chat/contacts'),
          statusCode: 200,
          data: {
            'data': [
              {
                'id': 1,
                'name': 'Driver Khaled',
                'role': 'سائق',
                'phone': '0550000001',
                'chat_description': 'سائق باص رقم 5',
                'avatar_url': null,
              }
            ]
          },
        ),
      );

      final contacts = await repo.getContacts();

      expect(contacts.length, 1);
      expect(contacts.first.id, 1);
      expect(contacts.first.name, 'Driver Khaled');
      expect(contacts.first.role, 'سائق');
    });

    test('9. ChatConversation fromJson, otherParticipant and getConversations', () async {
      when(() => mockDio.get('chat/conversations')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: 'chat/conversations'),
          statusCode: 200,
          data: {
            'data': [
              {
                'id': 10,
                'type': 'private',
                'unread_count': 3,
                'updated_at': '2026-09-04T08:00:00.000Z',
                'participants': [
                  {'id': 100, 'name': 'Parent', 'role': 'ولي أمر'},
                  {'id': 200, 'name': 'Supervisor', 'role': 'مشرف'},
                ],
                'last_message': {
                  'id': 500,
                  'conversation_id': 10,
                  'sender': {'id': 200, 'name': 'Supervisor', 'role': 'مشرف'},
                  'body': 'Bus arrived at the gate',
                  'created_at': '2026-09-04T08:00:00.000Z',
                }
              }
            ]
          },
        ),
      );

      final conversations = await repo.getConversations();

      expect(conversations.length, 1);
      final conv = conversations.first;
      expect(conv.id, 10);
      expect(conv.unreadCount, 3);
      expect(conv.lastMessage?.body, 'Bus arrived at the gate');

      final other = conv.otherParticipant(100);
      expect(other?.id, 200);
      expect(other?.name, 'Supervisor');
    });

    test('10. sendMessage sends POST payload and parses ChatMessage response', () async {
      when(() => mockDio.post(
            'chat/conversations/10/messages',
            data: {'body': 'Thank you', 'type': 'text'},
          )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: 'chat/conversations/10/messages'),
          statusCode: 200,
          data: {
            'data': {
              'id': 501,
              'conversation_id': 10,
              'body': 'Thank you',
              'type': 'text',
              'is_mine': true,
              'created_at': '2026-09-04T08:05:00.000Z',
              'sender': {'id': 100, 'name': 'Parent', 'role': 'ولي أمر'},
            }
          },
        ),
      );

      final sent = await repo.sendMessage(10, 'Thank you');

      expect(sent.id, 501);
      expect(sent.body, 'Thank you');
      expect(sent.isMine, isTrue);
      expect(sent.conversationId, 10);
    });
  });

  group('ComplaintsRepositoryImpl Suite', () {
    late ComplaintsRepositoryImpl repo;

    setUp(() {
      repo = ComplaintsRepositoryImpl(dio: mockDio);
    });

    test('11. submitComplaint sends POST to guardian/complaints with correct payload', () async {
      when(() => mockDio.post(
            'guardian/complaints',
            data: any(named: 'data'),
          )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: 'guardian/complaints'),
          statusCode: 200,
        ),
      );

      final complaint = Complaint(
        type: ComplaintType.complaint,
        message: 'The bus was 25 minutes late today',
        studentId: 'st_99',
      );

      await repo.submitComplaint(complaint);

      verify(() => mockDio.post(
            'guardian/complaints',
            data: {
              'type': 'complaint',
              'message': 'The bus was 25 minutes late today',
              'student_id': 'st_99',
            },
          )).called(1);
    });
  });

  group('AuthRepositoryImpl Suite', () {
    late AuthRepositoryImpl repo;

    setUp(() {
      repo = AuthRepositoryImpl(dio: mockDio);
    });

    test('12. login sends credentials and maps AuthUser entity correctly', () async {
      when(() => mockDio.post(
            'auth/login',
            data: any(named: 'data'),
          )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: 'auth/login'),
          statusCode: 200,
          data: {
            'data': {
              'user': {
                'id': 88,
                'name': 'خالد محمد',
                'name_en': 'Khaled Mohammed',
                'role': 'guardian',
              },
              'token': 'secret_jwt_parent_token',
            }
          },
        ),
      );

      final user = await repo.login(
        civilId: '1098765432',
        password: 'password123',
      );

      expect(user.id, '88');
      expect(user.name, 'خالد محمد');
      expect(user.nameEn, 'Khaled Mohammed');
      expect(user.role, 'guardian');
      expect(user.accessToken, 'secret_jwt_parent_token');

      verify(() => mockDio.post(
            'auth/login',
            data: {
              'national_id': '1098765432',
              'password': 'password123',
              'device_name': 'mobile_device',
              'app_context': 'parent',
            },
          )).called(1);
    });

    test('13. requestPasswordReset sends national_id to reset-request', () async {
      when(() => mockDio.post(
            'auth/password/reset-request',
            data: any(named: 'data'),
          )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: 'auth/password/reset-request'),
          statusCode: 200,
        ),
      );

      await repo.requestPasswordReset(phoneOrUsername: '1098765432');

      verify(() => mockDio.post(
            'auth/password/reset-request',
            data: {'national_id': '1098765432'},
          )).called(1);
    });

    test('14. updateLanguage posts language code to profile language endpoint', () async {
      when(() => mockDio.post(
            'auth/profile/language',
            data: any(named: 'data'),
          )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: 'auth/profile/language'),
          statusCode: 200,
        ),
      );

      await repo.updateLanguage('ar');

      verify(() => mockDio.post(
            'auth/profile/language',
            data: {'language': 'ar'},
          )).called(1);
    });
  });

  group('DashboardRepositoryImpl Suite', () {
    late DashboardRepositoryImpl repo;

    setUp(() {
      repo = DashboardRepositoryImpl(dio: mockDio);
    });

    test('15. fetchChildrenSummary maps child summary and bus trip status correctly', () async {
      when(() => mockDio.get('parent/children')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: 'parent/children'),
          statusCode: 200,
          data: {
            'data': [
              {
                'id': 101,
                'name': 'ياسر',
                'status': 'onBus',
                'image_url': 'https://api.msaratwasel.com/avatars/yasser.png',
                'bus': {'trip_status': 'in_progress'},
              },
              {
                'id': 102,
                'name': 'لمى',
                'status': 'atSchool',
                'image_url': null,
                'bus': null,
              }
            ]
          },
        ),
      );

      final summaries = await repo.fetchChildrenSummary();

      expect(summaries.length, 2);
      expect(summaries[0].id, '101');
      expect(summaries[0].name, 'ياسر');
      expect(summaries[0].status, 'onBus');
      expect(summaries[0].busStatus, 'in_progress');
      expect(summaries[0].etaMinutes, 0);
      expect(summaries[0].avatarUrl, contains('yasser.png'));

      expect(summaries[1].id, '102');
      expect(summaries[1].name, 'لمى');
      expect(summaries[1].status, 'atSchool');
      expect(summaries[1].busStatus, '');
    });
  });

  group('NotificationRepositoryImpl Suite', () {
    late NotificationRepositoryImpl repo;

    setUp(() {
      repo = NotificationRepositoryImpl(dio: mockDio);
    });

    test('16. fetchNotifications parses notifications when data is nested in map', () async {
      when(() => mockDio.get('guardian/notifications')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: 'guardian/notifications'),
          statusCode: 200,
          data: {
            'notifications': {
              'data': [
                {
                  'id': 'notif_1',
                  'title': 'بدء الرحلة',
                  'body': 'انطلقت الحافلة',
                  'type': 'trip_started',
                  'read': false,
                  'created_at': '2026-09-04T07:00:00.000Z',
                }
              ]
            },
            'unread_count': 5,
          },
        ),
      );

      final result = await repo.fetchNotifications();

      expect(result.unreadCount, 5);
      expect(result.notifications.length, 1);
      expect(result.notifications.first.id, 'notif_1');
      expect(result.notifications.first.title, 'بدء الرحلة');
    });

    test('17. fetchNotifications parses direct list and handles error safely', () async {
      when(() => mockDio.get('guardian/notifications')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: 'guardian/notifications'),
          statusCode: 200,
          data: {
            'notifications': [
              {
                'id': 'notif_2',
                'title': 'وصل الطالب',
                'body': 'وصل الطالب إلى المدرسة',
                'type': 'student_arrived_school',
                'status': 'read',
                'created_at': '2026-09-04T07:45:00.000Z',
              }
            ],
            'unread_count': 0,
          },
        ),
      );

      final result = await repo.fetchNotifications();

      expect(result.unreadCount, 0);
      expect(result.notifications.length, 1);
      expect(result.notifications.first.id, 'notif_2');

      // Failure path: when dio throws exception
      when(() => mockDio.get('guardian/notifications')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: 'guardian/notifications'),
          error: 'Connection timeout',
        ),
      );

      final errorResult = await repo.fetchNotifications();
      expect(errorResult.notifications, isEmpty);
      expect(errorResult.unreadCount, 0);
    });
  });
}

