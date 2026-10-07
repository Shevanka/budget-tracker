import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/default_categories.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../database/app_database.dart';
import '../../../../database/converters/transaction_type.dart';
import '../../providers/categories_provider.dart';
import '../widgets/add_edit_category_sheet.dart';

/// Screen allowing users to list, add, edit, and soft-delete categories.
class CategoryManagerScreen extends ConsumerStatefulWidget {
  const CategoryManagerScreen({super.key});

  @override
  ConsumerState<CategoryManagerScreen> createState() =>
      _CategoryManagerScreenState();
}

class _CategoryManagerScreenState extends ConsumerState<CategoryManagerScreen> {
  TransactionType _selectedType = TransactionType.expense;
  bool _showInactive = false;

  void _openAddCategorySheet() {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AddEditCategorySheet(
        initialType: _selectedType,
      ),
    );
  }

  void _openEditCategorySheet(Category category) {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AddEditCategorySheet(
        category: category,
      ),
    );
  }

  Future<void> _confirmDeleteCategory(Category category) async {
    final count = await ref
        .read(categoryControllerProvider.notifier)
        .getTransactionCount(category.id);
    if (!mounted) return;

    if (count > 0) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Cannot Delete Category'),
          content: Text(
            'Cannot delete "${category.name}" because it is linked to $count '
            'transaction${count == 1 ? '' : 's'}.\n\n'
            'Please reassign or delete these transactions before deleting this category.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
          'Are you sure you want to delete "${category.name}"?\n\n'
          'Existing transactions will preserve this category, but it will no longer be available for new transactions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref
            .read(categoryControllerProvider.notifier)
            .softDeleteCategory(category.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Category "${category.name}" deleted'),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () {
                  ref
                      .read(categoryControllerProvider.notifier)
                      .restoreCategory(category.id);
                },
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete category: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _restoreCategory(Category category) async {
    await ref
        .read(categoryControllerProvider.notifier)
        .restoreCategory(category.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Category "${category.name}" restored'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final categoriesAsync = ref.watch(
      categoriesByFilterProvider((
        type: _selectedType,
        includeInactive: _showInactive,
      )),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Category Manager'),
        actions: [
          IconButton(
            icon: Icon(
              _showInactive ? Icons.visibility : Icons.visibility_off_outlined,
            ),
            tooltip: _showInactive ? 'Hide inactive' : 'Show inactive',
            onPressed: () {
              setState(() {
                _showInactive = !_showInactive;
              });
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddCategorySheet,
        icon: const Icon(Icons.add),
        label: const Text('Add Category'),
      ),
      body: Column(
        children: [
          // Segmented Tab for Expense vs Income
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SegmentedButton<TransactionType>(
              segments: const [
                ButtonSegment<TransactionType>(
                  value: TransactionType.expense,
                  label: Text('Expense Categories'),
                  icon: Icon(Icons.arrow_downward, color: AppColors.expense),
                ),
                ButtonSegment<TransactionType>(
                  value: TransactionType.income,
                  label: Text('Income Categories'),
                  icon: Icon(Icons.arrow_upward, color: AppColors.income),
                ),
              ],
              selected: {_selectedType},
              onSelectionChanged: (selection) {
                setState(() {
                  _selectedType = selection.first;
                });
              },
            ),
          ),

          // Categories List
          Expanded(
            child: categoriesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (err, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                    const SizedBox(height: 12),
                    Text(
                      'Failed to load categories',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    FilledButton.tonal(
                      onPressed: () => ref.invalidate(categoriesByFilterProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (categories) {
                if (categories.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.category_outlined,
                            size: 64,
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No ${_selectedType.name} categories',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap the button below to add your first ${_selectedType.name} category.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: _openAddCategorySheet,
                            icon: const Icon(Icons.add),
                            label: Text(
                              'Add ${_selectedType == TransactionType.income ? 'Income' : 'Expense'} Category',
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                  itemCount: categories.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final catColor = Color(cat.color);
                    final catIcon = DefaultCategories.getIconData(cat.icon);

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: cat.isActive
                              ? colorScheme.outlineVariant.withValues(alpha: 0.6)
                              : colorScheme.outlineVariant.withValues(alpha: 0.3),
                        ),
                      ),
                      color: cat.isActive
                          ? colorScheme.surface
                          : colorScheme.surfaceContainerLow.withValues(alpha: 0.5),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        onTap: () => _openEditCategorySheet(cat),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: cat.isActive
                                ? catColor.withValues(alpha: 0.15)
                                : colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            catIcon,
                            color: cat.isActive ? catColor : colorScheme.outline,
                            size: 24,
                          ),
                        ),
                        title: Text(
                          cat.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            decoration: cat.isActive
                                ? TextDecoration.none
                                : TextDecoration.lineThrough,
                            color: cat.isActive
                                ? colorScheme.onSurface
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                        subtitle: Row(
                          children: [
                            if (cat.isDefault) ...[
                              Container(
                                margin: const EdgeInsets.only(top: 4, right: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Default',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                            if (!cat.isActive) ...[
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.errorContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Inactive',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onErrorContainer,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (cat.isActive) ...[
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                tooltip: 'Edit',
                                iconSize: 20,
                                onPressed: () => _openEditCategorySheet(cat),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: colorScheme.error,
                                ),
                                tooltip: 'Delete',
                                iconSize: 20,
                                onPressed: () => _confirmDeleteCategory(cat),
                              ),
                            ] else ...[
                              IconButton(
                                icon: Icon(
                                  Icons.restore,
                                  color: colorScheme.primary,
                                ),
                                tooltip: 'Restore',
                                iconSize: 20,
                                onPressed: () => _restoreCategory(cat),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
