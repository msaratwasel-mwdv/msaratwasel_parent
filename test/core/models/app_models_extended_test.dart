import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:msaratwasel_user/src/core/models/app_models.dart';
import 'package:msaratwasel_user/src/features/chat/data/models/chat_models.dart';


void main() {
  group('Parent App Domain Models & Serialization Extended Suite', () {
    test('1. Student.deriveStudentStatus covers all 5-step cycle timestamp paths', () {
      final now = DateTime.now();

      // Path 1: arrivedHomeTime is set
      expect(
        Student.deriveStudentStatus('onBus', 'to_home', arrivedHomeTime: now),
        StudentStatus.arrivedHome,
      );

      // Path 2: onBusToHomeTime set with atHome/arrivedHome raw status
      expect(
        Student.deriveStudentStatus('atHome', 'to_home', onBusToHomeTime: now),
        StudentStatus.arrivedHome,
      );
      expect(
        Student.deriveStudentStatus('onBus', 'to_home', onBusToHomeTime: now),
        StudentStatus.onBusToHome,
      );

      // Path 3: atSchoolTime set with return direction
      expect(
        Student.deriveStudentStatus('onBus', 'to_home', atSchoolTime: now),
        StudentStatus.onBusToHome,
      );
      expect(
        Student.deriveStudentStatus('atSchool', 'to_school', atSchoolTime: now),
        StudentStatus.atSchool,
      );

      // Path 4: onBusToSchoolTime set
      expect(
        Student.deriveStudentStatus('atSchool', 'to_school', onBusToSchoolTime: now),
        StudentStatus.atSchool,
      );
      expect(
        Student.deriveStudentStatus('onBus', 'to_school', onBusToSchoolTime: now),
        StudentStatus.onBusToSchool,
      );

      // Path 5: waitingAtHomeTime set
      expect(
        Student.deriveStudentStatus('onBus', 'to_school', waitingAtHomeTime: now),
        StudentStatus.onBusToSchool,
      );
      expect(
        Student.deriveStudentStatus('waiting', 'to_school', waitingAtHomeTime: now),
        StudentStatus.waitingAtHome,
      );
    });

    test('2. Student.deriveStudentStatus covers fallback raw status branches', () {
      // onBus with directions
      expect(Student.deriveStudentStatus('onBus', 'to_school'), StudentStatus.onBusToSchool);
      expect(Student.deriveStudentStatus('onBus', 'forth'), StudentStatus.onBusToSchool);
      expect(Student.deriveStudentStatus('onBus', 'morning'), StudentStatus.onBusToSchool);
      expect(Student.deriveStudentStatus('onBus', 'to_home'), StudentStatus.onBusToHome);
      expect(Student.deriveStudentStatus('onBus', 'back'), StudentStatus.onBusToHome);
      expect(Student.deriveStudentStatus('onBus', 'unknown_dir'), StudentStatus.onBus);

      // atHome with directions
      expect(Student.deriveStudentStatus('atHome', 'to_home'), StudentStatus.arrivedHome);
      expect(Student.deriveStudentStatus('atHome', 'to_school'), StudentStatus.waitingAtHome);

      // waiting with directions
      expect(Student.deriveStudentStatus('waiting', 'to_school'), StudentStatus.waitingAtHome);
      expect(Student.deriveStudentStatus('waiting', 'to_home'), StudentStatus.onBusToHome);

      // Other statuses
      expect(Student.deriveStudentStatus('atSchool', null), StudentStatus.atSchool);
      expect(Student.deriveStudentStatus('notBoarded', null), StudentStatus.notBoarded);
      expect(Student.deriveStudentStatus('late', null), StudentStatus.late);
      expect(Student.deriveStudentStatus('unrecognized', null), StudentStatus.waitingAtHome);
    });

    test('3. Student display helpers and location validation', () {
      const studentWithFullData = Student(
        id: 'st-1',
        name: 'علي أحمد',
        nameEn: 'Ali Ahmed',
        grade: 'الصف الرابع',
        gradeEn: 'Grade 4',
        schoolId: 'sch-1',
        studentCode: 'CODE-99',
        bus: BusInfo(id: 'b1', number: '1', plate: '123'),
        status: StudentStatus.atSchool,
        homeLocation: LatLng(24.7136, 46.6753),
      );

      expect(studentWithFullData.displayName, 'علي أحمد');
      expect(studentWithFullData.getLocalizedName('ar'), 'علي أحمد');
      expect(studentWithFullData.getLocalizedName('en'), 'Ali Ahmed');
      expect(studentWithFullData.getLocalizedGrade('ar'), 'الصف الرابع');
      expect(studentWithFullData.getLocalizedGrade('en'), 'Grade 4');
      expect(studentWithFullData.hasLocation, isTrue);

      // Fallback display names
      const studentNoName = Student(
        id: 'st-2',
        name: '',
        grade: '1',
        schoolId: 's',
        studentCode: 'CODE-55',
        bus: BusInfo(id: 'b', number: '1', plate: 'p'),
        status: StudentStatus.atHome,
      );
      expect(studentNoName.displayName, 'CODE-55');

      const studentIdOnly = Student(
        id: 'st-3',
        name: '   ',
        studentCode: '',
        grade: '1',
        schoolId: 's',
        bus: BusInfo(id: 'b', number: '1', plate: 'p'),
        status: StudentStatus.atHome,
        homeLocation: LatLng(0, 0),
      );
      expect(studentIdOnly.displayName, 'st-3');
      expect(studentIdOnly.hasLocation, isFalse);
    });

    test('4. BusStaffInfo and BusInfo serialization & copyWith', () {
      final staffJson = {
        'id': '10',
        'name': 'محمد السائق',
        'name_en': 'Mohammed Driver',
        'phone': '0555555555',
      };
      final staff = BusStaffInfo.fromJson(staffJson);
      expect(staff.id, 10);
      expect(staff.getLocalizedName('ar'), 'محمد السائق');
      expect(staff.getLocalizedName('en'), 'Mohammed Driver');

      final busJson = {
        'id': 'bus-1',
        'bus_number': '101',
        'plate_number': 'أ ب ج 1234',
        'trip_status': 'in_transit',
        'driver': staffJson,
        'latitude': '24.71',
        'longitude': '46.67',
        'total_students': '25',
        'on_board_count': '20',
        'speed_kmh': '48.5',
        'eta_minutes': '12',
      };
      final bus = BusInfo.fromJson(busJson);
      expect(bus.id, 'bus-1');
      expect(bus.driver?.name, 'محمد السائق');
      expect(bus.totalStudents, 25);
      expect(bus.speed, 48.5);

      final updatedBus = bus.copyWith(speed: 60.0, onBoardCount: 22);
      expect(updatedBus.speed, 60.0);
      expect(updatedBus.onBoardCount, 22);
      expect(updatedBus.id, 'bus-1');
    });

    test('5. NotificationTypeX.label covers all notification types in Ar and En', () {
      for (final type in NotificationType.values) {
        final arLabel = type.label(true);
        final enLabel = type.label(false);
        expect(arLabel, isNotEmpty);
        expect(enLabel, isNotEmpty);
        expect(arLabel, isNot(enLabel));
      }
    });

    test('6. AppNotification.parseType maps legacy and modern event keys', () {
      expect(AppNotification.parseType('bus_boarding_morning'), NotificationType.checkIn);
      expect(AppNotification.parseType('check_out'), NotificationType.checkOut);
      expect(AppNotification.parseType('bus_approaching'), NotificationType.approach);
      expect(AppNotification.parseType('bus_arrived'), NotificationType.arrival);
      expect(AppNotification.parseType('bus_delay'), NotificationType.delay);
      expect(AppNotification.parseType('route_change'), NotificationType.routeChange);
      expect(AppNotification.parseType('student_absence'), NotificationType.absence);
      expect(AppNotification.parseType('absence_approved'), NotificationType.absenceApproved);
      expect(AppNotification.parseType('absence_rejected'), NotificationType.absenceRejected);
      expect(AppNotification.parseType('late_boarding'), NotificationType.lateBoarding);
      expect(AppNotification.parseType('school_alert'), NotificationType.schoolAlert);
      expect(AppNotification.parseType('admin_announcement'), NotificationType.adminAnnouncement);
      expect(AppNotification.parseType('supervisor_message'), NotificationType.supervisorMessage);
      expect(AppNotification.parseType('new_message'), NotificationType.chat);
      expect(AppNotification.parseType('location_request'), NotificationType.locationRequest);
      expect(AppNotification.parseType('location_approved'), NotificationType.locationApproved);
      expect(AppNotification.parseType('trip_started'), NotificationType.tripStarted);
      expect(AppNotification.parseType('trip_ended'), NotificationType.tripEnded);
      expect(AppNotification.parseType('school_attendance'), NotificationType.schoolAttendance);
      expect(AppNotification.parseType('unknown_event'), NotificationType.schoolAlert);
    });

    test('7. AppNotification translation fallback for absence messages', () {
      final notif = AppNotification(
        id: 'n-abs',
        title: 'تنبيه غياب',
        body: 'الطالب أحمد لم يحضر في الحافلة اليوم',
        type: NotificationType.absence,
        time: DateTime.now(),
      );

      expect(notif.getDisplayBody(false), contains('لم يحضر في الحافلة اليوم'));
      expect(notif.getDisplayBody(true), contains('did not attend the bus today'));
    });

    test('8. LocationChangeRequest status helpers', () {
      final pendingReq = LocationChangeRequest.fromJson({
        'id': '1',
        'student_id': '10',
        'student_name': 'خالد',
        'status': 'pending',
        'new_latitude': '24.75',
        'new_longitude': '46.75',
        'new_address': 'حي الملقا',
      });
      expect(pendingReq.isPending, isTrue);
      expect(pendingReq.isApproved, isFalse);
      expect(pendingReq.newLatitude, 24.75);

      final approvedReq = LocationChangeRequest.fromJson({
        'id': '2',
        'student_id': '10',
        'status': 'approved',
      });
      expect(approvedReq.isApproved, isTrue);

      final rejectedReq = LocationChangeRequest.fromJson({
        'id': '3',
        'student_id': '10',
        'status': 'rejected',
        'rejection_reason': 'الشارع مغلق لأعمال الصيانة',
      });
      expect(rejectedReq.isRejected, isTrue);
      expect(rejectedReq.rejectionReason, 'الشارع مغلق لأعمال الصيانة');
    });

    test('9. Chat models (ChatContact, ChatConversation, ChatMessage) serialization', () {
      final contactJson = {
        'id': 5,
        'name': 'مشرفة فاطمة',
        'role': 'supervisor',
        'phone': '0501234567',
        'chat_description': 'مشرفة حافلة 3',
      };
      final contact = ChatContact.fromJson(contactJson);
      expect(contact.id, 5);
      expect(contact.name, 'مشرفة فاطمة');

      final conversationJson = {
        'id': 12,
        'type': 'private',
        'participants': [
          {'id': 1, 'name': 'ولي الأمر', 'role': 'guardian'},
          {'id': 5, 'name': 'مشرفة فاطمة', 'role': 'supervisor'},
        ],
        'unread_count': 2,
        'last_message': {
          'id': 100,
          'conversation_id': 12,
          'sender': {'id': 5, 'name': 'مشرفة فاطمة', 'role': 'supervisor'},
          'body': 'السلام عليكم',
          'type': 'text',
          'is_mine': false,
          'created_at': '2026-09-04T08:00:00.000Z',
        },
      };

      final conversation = ChatConversation.fromJson(conversationJson);
      expect(conversation.id, 12);
      expect(conversation.unreadCount, 2);
      expect(conversation.otherParticipant(1)?.name, 'مشرفة فاطمة');
      expect(conversation.lastMessage?.body, 'السلام عليكم');

      final copy = conversation.copyWith(unreadCount: 0);
      expect(copy.unreadCount, 0);
      expect(copy.id, 12);
    });

    test('10. Student copyWith covers all updated fields', () {
      const student = Student(
        id: 's1',
        name: 'علي',
        grade: 'الرابع',
        schoolId: 'sch1',
        bus: BusInfo(id: 'b1', number: '10', plate: 'أ ب ج 1'),
        status: StudentStatus.waitingAtHome,
      );

      final updated = student.copyWith(
        name: 'علي المحدث',
        nameEn: 'Ali Updated',
        grade: 'الخامس',
        gradeEn: 'Grade 5',
        schoolId: 'sch2',
        nationalId: '1234567890',
        gender: 'male',
        studentCode: 'CODE123',
        bus: const BusInfo(id: 'b1', number: '10', plate: 'أ ب ج 1'),
        status: StudentStatus.onBusToSchool,
        avatarUrl: 'https://example.com/avatar.png',
        tripCount: 15,
        attendancePercentage: 98,
        homeLocation: const LatLng(24.7, 46.7),
        forthLocation: const LatLng(24.71, 46.71),
        backLocation: const LatLng(24.72, 46.72),
        locationNote: 'قرب المسجد',
        schoolName: 'مدرسة النجاح',
        schoolLocation: 'الرياض',
        schoolCoords: const LatLng(24.8, 46.8),
        waitingAtHomeTime: DateTime(2026, 9, 4, 6, 30),
        onBusToSchoolTime: DateTime(2026, 9, 4, 7, 0),
        atSchoolTime: DateTime(2026, 9, 4, 7, 30),
        onBusToHomeTime: DateTime(2026, 9, 4, 13, 0),
        arrivedHomeTime: DateTime(2026, 9, 4, 13, 30),
        etaMinutes: 12,
        pendingLocation: {'lat': 24.75, 'lng': 46.75},
      );

      expect(updated.name, 'علي المحدث');
      expect(updated.nameEn, 'Ali Updated');
      expect(updated.grade, 'الخامس');
      expect(updated.gradeEn, 'Grade 5');
      expect(updated.schoolId, 'sch2');
      expect(updated.nationalId, '1234567890');
      expect(updated.gender, 'male');
      expect(updated.studentCode, 'CODE123');
      expect(updated.bus?.id, 'b1');
      expect(updated.status, StudentStatus.onBusToSchool);
      expect(updated.avatarUrl, 'https://example.com/avatar.png');
      expect(updated.tripCount, 15);
      expect(updated.attendancePercentage, 98);
      expect(updated.homeLocation?.latitude, 24.7);
      expect(updated.forthLocation?.latitude, 24.71);
      expect(updated.backLocation?.latitude, 24.72);
      expect(updated.locationNote, 'قرب المسجد');
      expect(updated.schoolName, 'مدرسة النجاح');
      expect(updated.schoolCoords?.latitude, 24.8);
      expect(updated.waitingAtHomeTime, DateTime(2026, 9, 4, 6, 30));
      expect(updated.onBusToSchoolTime, DateTime(2026, 9, 4, 7, 0));
      expect(updated.atSchoolTime, DateTime(2026, 9, 4, 7, 30));
      expect(updated.onBusToHomeTime, DateTime(2026, 9, 4, 13, 0));
      expect(updated.arrivedHomeTime, DateTime(2026, 9, 4, 13, 30));
      expect(updated.etaMinutes, 12);
      expect(updated.pendingLocation?['lat'], 24.75);
    });

    test('11. BusInfo and BusStaffInfo edge cases and copyWith', () {
      final staffInt = BusStaffInfo.fromJson({'id': 10, 'name': 'أحمد'});
      expect(staffInt.id, 10);
      final staffStr = BusStaffInfo.fromJson({'id': '20', 'name': 'محمد'});
      expect(staffStr.id, 20);
      final staffNull = BusStaffInfo.fromJson({'name': 'خالد'});
      expect(staffNull.id, 0);

      const bus = BusInfo(id: 'b1', number: '1', plate: 'ABC');
      final updatedBus = bus.copyWith(
        onBoardCount: 15,
        speed: 45.5,
        totalStudents: 30,
        status: 'in_progress',
      );
      expect(updatedBus.onBoardCount, 15);
      expect(updatedBus.speed, 45.5);
      expect(updatedBus.totalStudents, 30);
    });

    test('12. AppNotification fromMap with string json data, fromFcm, and toJson roundtrip', () {
      final stringDataMap = {
        'id': 'n-str',
        'data': '{"title_ar":"تنبيه اختبار","body":"تفاصيل الرسالة","type":"delay","sender_name":"المدرسة","sender_name_en":"School","target_screen":"notifications"}',
      };
      final notifFromMap = AppNotification.fromMap(stringDataMap);
      expect(notifFromMap.title, 'تنبيه اختبار');
      expect(notifFromMap.type, NotificationType.delay);
      expect(notifFromMap.getDisplaySender(false), 'المدرسة');
      expect(notifFromMap.getDisplaySender(true), 'School');

      final fcmMsg = RemoteMessage(
        messageId: 'fcm-123',
        data: {
          'id': 'db-99',
          'type': 'trip_started',
          'title_ar': 'انطلقت الرحلة',
          'body': 'الحافلة في الطريق الآن',
          'sender': 'السائق فهد',
          'data': '{"category":"trip","target_screen":"tracking"}',
        },
      );
      final notifFromFcm = AppNotification.fromFcm(fcmMsg);
      expect(notifFromFcm.id, 'db-99');
      expect(notifFromFcm.type, NotificationType.tripStarted);
      expect(notifFromFcm.category, 'trip');
      expect(notifFromFcm.targetScreen, 'tracking');

      final json = notifFromFcm.toJson();
      final roundtrip = AppNotification.fromJson(json);
      expect(roundtrip.id, notifFromFcm.id);
      expect(roundtrip.title, notifFromFcm.title);
      expect(roundtrip.type, notifFromFcm.type);
      expect(roundtrip.category, notifFromFcm.category);
    });

    test('13. AttendanceEntry and TripEntry helpers', () {
      final now = DateTime.now();
      final att = AttendanceEntry(
        date: now,
        direction: AttendanceDirection.outbound,
        status: 'present',
        note: 'حضور مبكر',
      );
      expect(att.status, 'present');
      expect(att.note, 'حضور مبكر');

      final checkIn = DateTime(2026, 9, 4, 7, 0);
      final arrival = DateTime(2026, 9, 4, 7, 45);
      final trip = TripEntry(
        date: now,
        checkIn: checkIn,
        checkOut: checkIn,
        arrival: arrival,
        delayed: false,
        events: ['boarding', 'arrived'],
      );
      expect(trip.boardingTime, checkIn);
      expect(trip.dropOffTime, arrival);
    });
  });
}
