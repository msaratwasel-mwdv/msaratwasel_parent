import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/features/children/presentation/location_picker_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppController controller;

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/google_maps'),
      (MethodCall call) async {
        return null;
      },
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity_status'),
      (call) async => null,
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/geolocator'),
      (MethodCall call) async {
        if (call.method == 'isLocationServiceEnabled') return true;
        if (call.method == 'checkPermission') return 2; // whileInUse
        if (call.method == 'getCurrentPosition') {
          return {
            'latitude': 23.5859,
            'longitude': 58.4059,
            'timestamp': 1000,
            'altitude': 0.0,
            'accuracy': 5.0,
            'heading': 0.0,
            'speed': 0.0,
            'speed_accuracy': 0.0,
            'is_mocked': false,
          };
        }
        return null;
      },
    );
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'user_id': 101,
      'user_name': 'Parent Test',
      'app_locale': 'ar',
      'has_seen_onboarding': true,
    });
    FlutterSecureStorage.setMockInitialValues({
      'access_token': 'test_token',
    });
  });

  tearDown(() {
    controller.stopTrackingPoll();
    controller.dispose();
  });

  Widget buildTestableWidget({
    required AppController appCtrl,
    LatLng? initialLocation,
    bool isReadOnly = false,
    ThemeMode themeMode = ThemeMode.light,
    void Function(dynamic result)? onResult,
  }) {
    return AppScope(
      controller: appCtrl,
      child: MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: themeMode,
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                final res = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LocationPickerScreen(
                      initialLocation: initialLocation,
                      isReadOnly: isReadOnly,
                    ),
                  ),
                );
                onResult?.call(res);
              },
              child: const Text('Open Picker'),
            ),
          ),
        ),
      ),
    );
  }

  group('LocationPickerScreen Widget Tests', () {
    testWidgets('renders screen with search, map, note field, and confirms without note', (tester) async {
      await tester.runAsync(() async {
        controller = AppController();
        await controller.bootstrap();
        controller.stopTrackingPoll();
      });

      dynamic returnedResult;
      await tester.pumpWidget(buildTestableWidget(
        appCtrl: controller,
        initialLocation: const LatLng(23.58, 58.40),
        onResult: (res) => returnedResult = res,
      ));

      // Open screen
      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      // Check search field
      expect(find.byType(TextField), findsNWidgets(2)); // Search field and Note field
      expect(find.byType(FloatingActionButton), findsOneWidget);

      // Tap confirm button without note
      final confirmBtn = find.text('تأكيد الموقع');
      expect(confirmBtn, findsOneWidget);
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Verify returned result contains location map
      expect(returnedResult, isNotNull);
      expect(returnedResult['note'], '');
      expect(returnedResult['location'], isA<LatLng>());
    });

    testWidgets('confirms with note via confirmation dialog', (tester) async {
      await tester.runAsync(() async {
        controller = AppController();
        await controller.bootstrap();
        controller.stopTrackingPoll();
      });

      dynamic returnedResult;
      await tester.pumpWidget(buildTestableWidget(
        appCtrl: controller,
        initialLocation: const LatLng(23.58, 58.40),
        onResult: (res) => returnedResult = res,
      ));

      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      // Enter note in second TextField
      final noteField = find.byType(TextField).last;
      await tester.enterText(noteField, 'بجوار المسجد الكبير');
      await tester.pump();

      // Tap confirm button
      await tester.tap(find.text('تأكيد الموقع'));
      await tester.pumpAndSettle();

      // Confirmation dialog should be visible
      expect(find.descendant(of: find.byType(AlertDialog), matching: find.text('بجوار المسجد الكبير')), findsOneWidget);
      expect(find.text('الملاحظة:'), findsOneWidget);

      // Tap dialog confirm
      final dialogConfirm = find.widgetWithText(ElevatedButton, 'تأكيد');
      expect(dialogConfirm, findsOneWidget);
      await tester.tap(dialogConfirm);
      await tester.pumpAndSettle();

      expect(returnedResult, isNotNull);
      expect(returnedResult['note'], 'بجوار المسجد الكبير');
    });

    testWidgets('cancels dialog when cancel button tapped', (tester) async {
      await tester.runAsync(() async {
        controller = AppController();
        await controller.bootstrap();
        controller.stopTrackingPoll();
      });

      await tester.pumpWidget(buildTestableWidget(
        appCtrl: controller,
        initialLocation: const LatLng(23.58, 58.40),
      ));

      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      final noteField = find.byType(TextField).last;
      await tester.enterText(noteField, 'ملاحظة خاصة');
      await tester.pump();

      await tester.tap(find.text('تأكيد الموقع'));
      await tester.pumpAndSettle();

      expect(find.text('الملاحظة:'), findsOneWidget);

      // Tap cancel in dialog
      final dialogCancel = find.widgetWithText(TextButton, 'إلغاء');
      await tester.tap(dialogCancel);
      await tester.pumpAndSettle();

      // Dialog is dismissed, still on LocationPickerScreen
      expect(find.text('تأكيد الموقع'), findsOneWidget);
    });

    testWidgets('renders in read-only mode and dark theme', (tester) async {
      await tester.runAsync(() async {
        controller = AppController();
        await controller.bootstrap();
        controller.stopTrackingPoll();
      });

      await tester.pumpWidget(buildTestableWidget(
        appCtrl: controller,
        initialLocation: const LatLng(23.58, 58.40),
        isReadOnly: true,
        themeMode: ThemeMode.dark,
      ));

      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      // Only search TextField in readOnly mode (note field is not rendered)
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('تأكيد الموقع'), findsNothing);

      // Tap back button
      final backBtn = find.byIcon(Icons.arrow_back_ios_new_rounded);
      expect(backBtn, findsOneWidget);
      await tester.tap(backBtn);
      await tester.pumpAndSettle();

      // Back on initial screen
      expect(find.text('Open Picker'), findsOneWidget);
    });

    testWidgets('interacts with search bar clear button and my location button', (tester) async {
      await tester.runAsync(() async {
        controller = AppController();
        await controller.bootstrap();
        controller.stopTrackingPoll();
      });

      await tester.pumpWidget(buildTestableWidget(
        appCtrl: controller,
        initialLocation: const LatLng(23.58, 58.40),
      ));

      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, 'مسقط');
      await tester.pump();

      // Clear button should appear
      final clearBtn = find.byIcon(Icons.close_rounded);
      expect(clearBtn, findsOneWidget);
      await tester.tap(clearBtn);
      await tester.pump();

      // Tap floating my location button
      final myLocationFab = find.byIcon(Icons.my_location_rounded);
      await tester.tap(myLocationFab);
      await tester.pumpAndSettle();
    });
  });
}
