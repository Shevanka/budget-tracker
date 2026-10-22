import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../routing/app_routes.dart';
import '../../../budget/providers/budget_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../widgets/widgets.dart';

/// The main dashboard screen displaying the active month selector,
/// net balance card, income & expense summaries, and quick action buttons.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final month = ref.read(selectedDashboardMonthProvider);
        ref.read(budgetControllerProvider.notifier).ensureBudgetForMonth(month);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedMonth = ref.watch(selectedDashboardMonthProvider);
    final monthNotifier = ref.read(selectedDashboardMonthProvider.notifier);
    final summaryAsync = ref.watch(monthlyFinancialSummaryProvider(selectedMonth));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoute.budgetSetup.path),
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Budget Setup',
          ),
          IconButton(
            onPressed: () => context.push(AppRoute.categoryManager.path),
            icon: const Icon(Icons.category_outlined),
            tooltip: 'Categories',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(monthlyFinancialSummaryProvider(selectedMonth));
          ref.invalidate(monthlyBudgetStatusProvider(selectedMonth));
          ref.invalidate(previousAvailableBudgetProvider(selectedMonth));
          ref.invalidate(recentTransactionsForMonthProvider(selectedMonth));
          await ref
              .read(budgetControllerProvider.notifier)
              .ensureBudgetForMonth(selectedMonth);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Month Selector Header
              MonthSelectorHeader(
                selectedYearMonth: selectedMonth,
                onPrevious: monthNotifier.previousMonth,
                onNext: monthNotifier.nextMonth,
                onResetCurrent: monthNotifier.resetToCurrentMonth,
              ),
              const SizedBox(height: 16),

              // Financial Summary Cards
              summaryAsync.when(
                loading: () => const SizedBox(
                  height: 220,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, _) => Card(
                  color: colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(Icons.error_outline, color: colorScheme.error),
                        const SizedBox(height: 8),
                        Text(
                          'Failed to load financial summary',
                          style: TextStyle(color: colorScheme.onErrorContainer),
                        ),
                        const SizedBox(height: 8),
                        FilledButton.tonal(
                          onPressed: () => ref.invalidate(
                            monthlyFinancialSummaryProvider(selectedMonth),
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (summary) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Net Balance Card
                    BalanceCard(summary: summary),
                    const SizedBox(height: 12),

                    // Income & Expense Dual Summary Card
                    IncomeExpenseSummaryCard(summary: summary),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Budget Progress Section
              DashboardBudgetSection(selectedYearMonth: selectedMonth),

              const SizedBox(height: 20),

              // Recent Transactions Section
              DashboardRecentTransactions(selectedYearMonth: selectedMonth),

              const SizedBox(height: 24),

              // Quick Actions
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: () => context.push(AppRoute.addTransaction.path),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Transaction'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.push(AppRoute.budgetSetup.path),
                    icon: const Icon(Icons.tune),
                    label: const Text('Setup Budget'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoute.addTransaction.path),
        tooltip: 'Add Transaction',
        child: const Icon(Icons.add),
      ),
    );
  }
}
