import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../routing/app_routes.dart';
import '../../providers/transactions_provider.dart';
import '../widgets/daily_group_header.dart';
import '../widgets/transaction_list_tile.dart';
import '../widgets/transactions_empty_state.dart';

/// Main screen displaying the chronological, date-grouped list of transactions with daily totals.
class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupedAsync = ref.watch(groupedTransactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
      ),
      body: groupedAsync.when(
        data: (groups) {
          if (groups.isEmpty) {
            return const TransactionsEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 96),
            itemCount: groups.length,
            itemBuilder: (context, groupIndex) {
              final group = groups[groupIndex];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DailyGroupHeader(group: group),
                  Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .outlineVariant
                            .withValues(alpha: 0.5),
                      ),
                    ),
                    child: Column(
                      children: [
                        for (int i = 0; i < group.items.length; i++) ...[
                          TransactionListTile(item: group.items[i]),
                          if (i < group.items.length - 1)
                            Divider(
                              height: 1,
                              indent: 72,
                              endIndent: 16,
                              color: Theme.of(context)
                                  .colorScheme
                                  .outlineVariant
                                  .withValues(alpha: 0.3),
                            ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Failed to load transactions',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoute.addTransaction.path),
        icon: const Icon(Icons.add),
        label: const Text('Add Transaction'),
      ),
    );
  }
}
