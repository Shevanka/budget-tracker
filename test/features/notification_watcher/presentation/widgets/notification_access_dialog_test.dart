import 'package:budget_tracker/features/notification_watcher/presentation/widgets/notification_access_dialog.dart';
import 'package:budget_tracker/features/notification_watcher/providers/notification_watcher_provider.dart';
import 'package:budget_tracker/features/notification_watcher/services/notification_listener_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockNotificationListenerWrapper extends Mock
    implements NotificationListenerWrapper {}

void main() {
  late MockNotificationListenerWrapper mockWrapper;

  setUp(() {
    mockWrapper = MockNotificationListenerWrapper();
    when(() => mockWrapper.isPermissionGranted()).thenAnswer((_) async => false);
    when(() => mockWrapper.requestPermission()).thenAnswer((_) async => true);
  });

  Widget buildTestWidget() {
    return ProviderScope(
      overrides: [
        notificationListenerWrapperProvider.overrideWithValue(mockWrapper),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => NotificationAccessDialog.show(context),
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      ),
    );
  }

  group('NotificationAccessDialog Widget Tests', () {
    testWidgets('renders dialog with title, explanation, privacy points, and steps',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Akses Notifikasi'), findsOneWidget);
      expect(find.text('Pencatatan Otomatis'), findsOneWidget);
      expect(find.text('Privasi & Offline 100%'), findsOneWidget);
      expect(find.text('Efisien & Hemat Baterai'), findsOneWidget);
      expect(find.text('Langkah Aktivasi:'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);
      expect(find.text('Buka Pengaturan'), findsOneWidget);
    });

    testWidgets('tapping Batal closes the dialog without requesting permission',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      expect(find.text('Akses Notifikasi'), findsNothing);
      verifyNever(() => mockWrapper.requestPermission());
    });

    testWidgets('tapping Buka Pengaturan triggers requestPermission and closes dialog',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Buka Pengaturan'));
      await tester.pumpAndSettle();

      expect(find.text('Akses Notifikasi'), findsNothing);
      verify(() => mockWrapper.requestPermission()).called(1);
    });
  });
}
