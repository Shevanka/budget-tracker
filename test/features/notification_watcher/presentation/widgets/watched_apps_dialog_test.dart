import 'package:budget_tracker/features/notification_watcher/constants/watched_apps.dart';
import 'package:budget_tracker/features/notification_watcher/presentation/widgets/watched_apps_dialog.dart';
import 'package:budget_tracker/features/notification_watcher/providers/notification_watcher_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildTestDialog({
    Set<String>? initialEnabledAppIds,
  }) {
    return ProviderScope(
      overrides: [
        if (initialEnabledAppIds != null)
          enabledWatchedAppIdsProvider.overrideWith(
            () => _PreloadedWatchedAppsNotifier(initialEnabledAppIds),
          ),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: WatchedAppsDialog(),
        ),
      ),
    );
  }

  group('WatchedAppsDialog Widget Tests', () {
    testWidgets('renders all 18 banks & e-wallets grouped by category', (tester) async {
      await tester.pumpWidget(buildTestDialog());
      await tester.pumpAndSettle();

      expect(find.text('Aplikasi Dipantau'), findsOneWidget);
      expect(find.text('18 dari 18 aktif'), findsOneWidget);
      expect(find.text('Pilih Semua'), findsOneWidget);
      expect(find.text('Hapus Semua'), findsOneWidget);

      expect(find.text('Perbankan'), findsOneWidget);

      // Verify specific banks exist
      expect(find.text(WatchedApps.bca.name), findsOneWidget);
      expect(find.text(WatchedApps.mandiri.name), findsOneWidget);
      expect(find.text(WatchedApps.bni.name), findsOneWidget);
      expect(find.text(WatchedApps.bri.name), findsOneWidget);

      // Scroll to check SeaBank
      await tester.scrollUntilVisible(
        find.text(WatchedApps.seaBank.name),
        50,
      );
      expect(find.text(WatchedApps.seaBank.name), findsOneWidget);

      // Scroll to check e-wallets
      await tester.scrollUntilVisible(
        find.text(WatchedApps.shopeePay.name),
        50,
      );
      expect(find.text(WatchedApps.shopeePay.name), findsOneWidget);
    });

    testWidgets('unchecking an app toggles its state', (tester) async {
      await tester.pumpWidget(buildTestDialog());
      await tester.pumpAndSettle();

      // Find BCA checkbox
      final bcaFinder = find.widgetWithText(CheckboxListTile, WatchedApps.bca.name);
      expect(bcaFinder, findsOneWidget);

      var bcaTile = tester.widget<CheckboxListTile>(bcaFinder);
      expect(bcaTile.value, isTrue);

      // Tap BCA
      await tester.tap(bcaFinder);
      await tester.pumpAndSettle();

      bcaTile = tester.widget<CheckboxListTile>(bcaFinder);
      expect(bcaTile.value, isFalse);
      expect(find.text('17 dari 18 aktif'), findsOneWidget);
    });

    testWidgets('tapping Hapus Semua deselects all apps', (tester) async {
      await tester.pumpWidget(buildTestDialog());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Hapus Semua'));
      await tester.pumpAndSettle();

      expect(find.text('0 dari 18 aktif'), findsOneWidget);

      final checkboxes = tester.widgetList<CheckboxListTile>(find.byType(CheckboxListTile));
      for (final cb in checkboxes) {
        expect(cb.value, isFalse);
      }
    });

    testWidgets('tapping Pilih Semua re-enables all apps', (tester) async {
      await tester.pumpWidget(
        buildTestDialog(initialEnabledAppIds: const {}),
      );
      await tester.pumpAndSettle();

      expect(find.text('0 dari 18 aktif'), findsOneWidget);

      await tester.tap(find.text('Pilih Semua'));
      await tester.pumpAndSettle();

      expect(find.text('18 dari 18 aktif'), findsOneWidget);
    });

    testWidgets('show static method opens dialog and Selesai button dismisses', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => WatchedAppsDialog.show(context),
                  child: const Text('Open Dialog'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(WatchedAppsDialog), findsOneWidget);

      // Tap Selesai
      await tester.tap(find.text('Selesai'));
      await tester.pumpAndSettle();

      expect(find.byType(WatchedAppsDialog), findsNothing);
    });
  });
}

class _PreloadedWatchedAppsNotifier extends EnabledWatchedAppsNotifier {
  final Set<String> _initial;
  _PreloadedWatchedAppsNotifier(this._initial);

  @override
  Set<String> build() => _initial;
}
