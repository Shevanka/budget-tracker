import 'package:budget_tracker/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppEmptyState Widget Tests', () {
    testWidgets('renders icon, title, and message correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppEmptyState(
              icon: Icons.inbox_rounded,
              title: 'No Data Found',
              message: 'Try searching with different keywords.',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.inbox_rounded), findsOneWidget);
      expect(find.text('No Data Found'), findsOneWidget);
      expect(find.text('Try searching with different keywords.'), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('renders action button and triggers callback when tapped', (tester) async {
      var actionTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppEmptyState(
              icon: Icons.add_shopping_cart,
              title: 'Empty Cart',
              message: 'Add items to begin shopping.',
              actionLabel: 'Browse Items',
              actionIcon: Icons.explore_rounded,
              onAction: () => actionTriggered = true,
            ),
          ),
        ),
      );

      expect(find.text('Browse Items'), findsOneWidget);
      expect(find.byIcon(Icons.explore_rounded), findsOneWidget);

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(actionTriggered, isTrue);
    });
  });

  group('AppErrorState Widget Tests', () {
    testWidgets('renders default title and optional message in centered mode', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppErrorState(
              message: 'Network connection lost.',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Network connection lost.'), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
      expect(find.byType(Card), findsNothing);
    });

    testWidgets('renders in card mode with retry button and triggers callback', (tester) async {
      var retryTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppErrorState(
              isCard: true,
              title: 'Database Query Failed',
              message: 'SQLite locked by background transaction.',
              retryLabel: 'Try Again',
              onRetry: () => retryTriggered = true,
            ),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
      expect(find.text('Database Query Failed'), findsOneWidget);
      expect(find.text('SQLite locked by background transaction.'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      await tester.tap(find.text('Try Again'));
      await tester.pumpAndSettle();

      expect(retryTriggered, isTrue);
    });
  });

  group('AppLoadingState Widget Tests', () {
    testWidgets('renders progress indicator and optional message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppLoadingState(
              message: 'Memuat data...',
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Memuat data...'), findsOneWidget);
    });

    testWidgets('applies height constraint when specified', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppLoadingState(
              height: 180,
              message: 'Syncing with database...',
            ),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(
        find.ancestor(
          of: find.byType(CircularProgressIndicator),
          matching: find.byType(SizedBox),
        ).first,
      );

      expect(sizedBox.height, equals(36.0)); // Inner indicator size
      expect(find.text('Syncing with database...'), findsOneWidget);
    });
  });
}
