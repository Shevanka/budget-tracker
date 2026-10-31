import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/default_categories.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../routing/app_routes.dart';
import '../../../categories/presentation/widgets/category_picker_field.dart';
import '../../../categories/providers/categories_provider.dart';
import '../../../notification_watcher/models/draft_transaction.dart';
import '../../../notification_watcher/providers/draft_transaction_provider.dart';

/// Screen for reviewing, editing, confirming, or skipping draft transactions
/// automatically detected from bank and e-wallet notifications.
class SmartRecordingReviewScreen extends ConsumerWidget {
  const SmartRecordingReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draftsAsync = ref.watch(pendingDraftTransactionsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Transactions'),
        actions: [
          draftsAsync.maybeWhen(
            data: (drafts) {
              final recognizedDrafts =
                  drafts.where((d) => d.isRecognized && d.amount > 0).toList();
              if (recognizedDrafts.length > 1) {
                return TextButton.icon(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final count = await ref
                        .read(draftTransactionControllerProvider.notifier)
                        .confirmAll(recognizedDrafts);
                    messenger.showSnackBar(
                      SnackBar(content: Text('$count transactions confirmed')),
                    );
                  },
                  icon: const Icon(Icons.done_all_rounded, size: 20),
                  label: const Text('Confirm All'),
                );
              }
              return const SizedBox.shrink();
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: draftsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline_rounded,
                    size: 48, color: colorScheme.error),
                const SizedBox(height: 12),
                Text(
                  'Failed to load draft transactions',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        data: (drafts) {
          if (drafts.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            itemCount: drafts.length,
            separatorBuilder: (_, _) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final draft = drafts[index];
              return DraftTransactionReviewCard(
                key: ValueKey(draft.id),
                draft: draft,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.task_alt_rounded,
                size: 44,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'All Caught Up!',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No pending draft transactions from notifications or receipts. New expenses will appear here for confirmation.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// An interactive card displaying a single detected draft transaction with
/// quick category editing, confirm, edit, and skip actions.
class DraftTransactionReviewCard extends ConsumerStatefulWidget {
  final DraftTransaction draft;

  const DraftTransactionReviewCard({
    super.key,
    required this.draft,
  });

  @override
  ConsumerState<DraftTransactionReviewCard> createState() =>
      _DraftTransactionReviewCardState();
}

class _DraftTransactionReviewCardState
    extends ConsumerState<DraftTransactionReviewCard> {
  late String _selectedCategoryId;
  bool _isConfirming = false;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId =
        widget.draft.suggestedCategoryId ?? DefaultCategories.otherId;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final draft = widget.draft;
    final categoriesAsync = ref.watch(activeCategoriesProvider);

    final categoryName = categoriesAsync.maybeWhen(
      data: (categories) {
        final match = categories.where((c) => c.id == _selectedCategoryId);
        return match.isNotEmpty ? match.first.name : draft.suggestedCategoryName ?? 'Other';
      },
      orElse: () => draft.suggestedCategoryName ?? 'Other',
    );

    final isSuggested = draft.suggestedCategoryId != null &&
        _selectedCategoryId == draft.suggestedCategoryId;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Row: Source Chip + Date + Skip Button
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 14,
                        color: colorScheme.onSecondaryContainer,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        draft.source,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    DateFormat('d MMM yyyy, HH:mm')
                        .format(draft.receivedAt.toLocal()),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  tooltip: 'Skip / Discard',
                  visualDensity: VisualDensity.compact,
                  onPressed: _isDismissing ? null : _dismissDraft,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Amount & Merchant
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        draft.formattedAmount,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.expense,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.storefront_outlined,
                            size: 18,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              draft.merchant,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Category Selector Field
            CategoryPickerField(
              selectedCategoryId: _selectedCategoryId,
              categoryType: draft.type,
              onCategorySelected: (cat) {
                setState(() {
                  _selectedCategoryId = cat.id;
                });
              },
            ),
            if (isSuggested) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 14,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Auto-suggested from "$categoryName"',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),

            // Accordion: Raw Notification Details
            if (draft.rawBody != null && draft.rawBody!.isNotEmpty) ...[
              Theme(
                data: theme.copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(bottom: 8),
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  leading: Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  title: Text(
                    'Raw notification text',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        draft.rawBody!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Action Buttons: Edit, Skip, Confirm
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _openFullEditor,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _isDismissing ? null : _dismissDraft,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: colorScheme.error,
                  ),
                  child: const Text('Skip'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _isConfirming ? null : _confirmDraft,
                  icon: _isConfirming
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Confirm'),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDraft() async {
    setState(() {
      _isConfirming = true;
    });

    final messenger = ScaffoldMessenger.of(context);
    final success = await ref
        .read(draftTransactionControllerProvider.notifier)
        .confirmDraft(
          draft: widget.draft,
          categoryId: _selectedCategoryId,
        );

    if (!mounted) return;
    setState(() {
      _isConfirming = false;
    });

    if (success) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Saved: ${widget.draft.formattedAmount} at ${widget.draft.merchant}'),
        ),
      );
    } else {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Failed to confirm transaction'),
        ),
      );
    }
  }

  Future<void> _dismissDraft() async {
    setState(() {
      _isDismissing = true;
    });

    final messenger = ScaffoldMessenger.of(context);
    final success = await ref
        .read(draftTransactionControllerProvider.notifier)
        .dismissDraft(widget.draft.id);

    if (!mounted) return;
    setState(() {
      _isDismissing = false;
    });

    if (success) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Notification dismissed')),
      );
    }
  }

  void _openFullEditor() {
    context.push(
      AppRoute.addTransaction.path,
      extra: {
        'amount': widget.draft.amount,
        'source': widget.draft.source,
        'categoryId': _selectedCategoryId,
        'note': widget.draft.merchant,
        'date': widget.draft.receivedAt,
        'type': widget.draft.type,
        'notificationLogId': widget.draft.id,
      },
    );
  }
}
