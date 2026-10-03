import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/budget/presentation/screens/budget_setup_screen.dart';
import '../features/categories/presentation/screens/category_manager_screen.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/reports/presentation/screens/reports_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/smart_recording/presentation/screens/receipt_picker_screen.dart';
import '../features/smart_recording/presentation/screens/smart_recording_review_screen.dart';
import '../features/transactions/presentation/screens/add_edit_transaction_screen.dart';
import '../features/transactions/presentation/screens/transactions_screen.dart';
import 'app_routes.dart';
import 'scaffold_with_nested_navigation.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Central provider for GoRouter configuration.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoute.dashboard.path,
    routes: [
      // Redirect root to dashboard
      GoRoute(
        path: '/',
        redirect: (context, state) => AppRoute.dashboard.path,
      ),

      // Bottom Navigation Stateful Shell
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNestedNavigation(
            navigationShell: navigationShell,
          );
        },
        branches: [
          // Tab 0: Dashboard
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.dashboard.path,
                name: AppRoute.dashboard.name,
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),

          // Tab 1: Transactions
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.transactions.path,
                name: AppRoute.transactions.name,
                builder: (context, state) => const TransactionsScreen(),
              ),
            ],
          ),

          // Tab 2: Reports
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.reports.path,
                name: AppRoute.reports.name,
                builder: (context, state) => const ReportsScreen(),
              ),
            ],
          ),

          // Tab 3: Settings
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.settings.path,
                name: AppRoute.settings.name,
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),

      // Pushed Routes (displayed on top of the bottom navigation shell)
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoute.addTransaction.path,
        name: AppRoute.addTransaction.name,
        builder: (context, state) => const AddEditTransactionScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoute.editTransaction.path,
        name: AppRoute.editTransaction.name,
        builder: (context, state) {
          final id = state.pathParameters['id'];
          return AddEditTransactionScreen(transactionId: id);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoute.categoryManager.path,
        name: AppRoute.categoryManager.name,
        builder: (context, state) => const CategoryManagerScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoute.budgetSetup.path,
        name: AppRoute.budgetSetup.name,
        builder: (context, state) => const BudgetSetupScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoute.smartRecordingReview.path,
        name: AppRoute.smartRecordingReview.name,
        builder: (context, state) => const SmartRecordingReviewScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoute.receiptPicker.path,
        name: AppRoute.receiptPicker.name,
        builder: (context, state) => const ReceiptPickerScreen(),
      ),
    ],
  );
});
