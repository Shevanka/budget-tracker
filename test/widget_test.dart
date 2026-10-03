import 'package:budget_tracker/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('BudgetTrackerApp smoke test renders navigation and dashboard',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: BudgetTrackerApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Dashboard is the initial screen
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Dashboard Overview'), findsOneWidget);

    // Verify 4 NavigationDestination tabs are present in NavigationBar
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Transactions'), findsOneWidget);
    expect(find.text('Reports'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
