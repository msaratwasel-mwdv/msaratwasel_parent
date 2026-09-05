import 'package:flutter_test/flutter_test.dart';
import 'package:msaratwasel_user/src/core/models/app_models.dart';
import 'package:msaratwasel_user/src/features/absence/domain/entities/absence_request.dart';

void main() {
  group('Models Serialization & Deserialization Baseline Suite', () {
    test('1. AppNotification.fromMap extracts fields and bilingual text correctly', () {
      final map = {
        'id': '101',
        'correlation_id': 'cid_xyz',
        'title': 'عنوان الإشعار / Notification Title',
        'body': 'نص الرسالة / Message Body',
        'type': 'arrival',
        'created_at': '2026-09-04T01:00:00.000Z',
        'read': false,
        'category': 'student_status',
        'target_screen': 'map_page',
        'data': {'student_id': 'st_5'},
      };

      final notif = AppNotification.fromMap(map);

      expect(notif.id, '101');
      expect(notif.correlationId, 'cid_xyz');
      expect(notif.type, NotificationType.arrival);
      expect(notif.category, 'student_status');
      expect(notif.targetScreen, 'map_page');
      expect(notif.read, isFalse);

      // Verify bilingual separation
      expect(notif.getDisplayTitle(false), 'عنوان الإشعار');
      expect(notif.getDisplayTitle(true), 'Notification Title');
      expect(notif.getDisplayBody(false), 'نص الرسالة');
      expect(notif.getDisplayBody(true), 'Message Body');
    });

    test('2. AppNotification.fromMap handles nested data and missing correlationId', () {
      final rawWithNested = {
        'id': '202',
        'type': 'check_in',
        'data': {
          'title': 'صعود الطالب',
          'message': 'صعد أحمد الحافلة',
          'correlation_id': 'nested_cid_456',
        },
      };

      final notif = AppNotification.fromMap(rawWithNested);

      expect(notif.id, '202');
      expect(notif.correlationId, 'nested_cid_456');
      expect(notif.type, NotificationType.checkIn);
      expect(notif.title, 'صعود الطالب');
      expect(notif.body, 'صعد أحمد الحافلة');
    });

    test('3. AppNotification.toJson serializes all fields properly', () {
      final notif = AppNotification(
        id: 'json_test_1',
        correlationId: 'cid_test',
        title: 'إشعار تجريبي',
        body: 'محتوى تجريبي',
        type: NotificationType.delay,
        time: DateTime.parse('2026-09-04T00:00:00.000Z'),
        read: true,
        category: 'bus_tracking',
        targetScreen: 'bus_page',
        unreadCount: 3,
        data: {'key': 'value'},
      );

      final json = notif.toJson();

      expect(json['id'], 'json_test_1');
      expect(json['correlation_id'], 'cid_test');
      expect(json['type'], 'delay');
      expect(json['read'], isTrue);
      expect(json['category'], 'bus_tracking');
      expect(json['target_screen'], 'bus_page');
      expect(json['unread_count'], 3);
    });

    test('4. Student.fromJson parses student with bus information and derives status properly', () {
      final studentMap = {
        'id': 'st_99',
        'name': 'سارة محمد',
        'grade': 'الثاني الابتدائي',
        'school_id': 'sch_1',
        'status': 'onBus',
        'suggested_direction': 'to_school',
        'bus': {
          'id': 'bus_5',
          'bus_number': '5',
          'plate_number': '9876 ب',
          'driver': {'name': 'خالد', 'phone': '99887766'},
        },
        'trip_count': 15,
        'attendance_percentage': 95,
      };

      final student = Student.fromJson(studentMap);

      expect(student.id, 'st_99');
      expect(student.name, 'سارة محمد');
      expect(student.status, StudentStatus.onBusToSchool);
      expect(student.bus.id, 'bus_5');
      expect(student.bus.number, '5');
      expect(student.bus.driver?.name, 'خالد');
      expect(student.tripCount, 15);
      expect(student.attendancePercentage, 95);
    });

    test('5. AbsenceRequest model handles studentIds and type mapping', () {
      final request = AbsenceRequest(
        studentIds: ['st_1', 'st_2'],
        type: AbsenceType.morning,
        date: DateTime.parse('2026-09-05'),
        note: 'ظرف عائلي',
      );

      expect(request.studentIds, ['st_1', 'st_2']);
      expect(request.type, AbsenceType.morning);
      expect(request.note, 'ظرف عائلي');
    });
  });
}
