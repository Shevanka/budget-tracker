import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../routing/app_routes.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.dashboard, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Dashboard Overview',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text('Monthly income, expense, and budget summary'),
            const SizedBox(height: 24),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoute.addTransaction.path),
        tooltip: 'Add Transaction',
        child: const Icon(Icons.add),
      ),
    );
  }
}
