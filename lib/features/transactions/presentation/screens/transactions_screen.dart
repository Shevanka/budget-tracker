import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../routing/app_routes.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Transactions History',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text('View and filter all income and expenses'),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.push(AppRoute.addTransaction.path),
              icon: const Icon(Icons.add),
              label: const Text('New Transaction'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoute.addTransaction.path),
        tooltip: 'New Transaction',
        child: const Icon(Icons.add),
      ),
    );
  }
}
