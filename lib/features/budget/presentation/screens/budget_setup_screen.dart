import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/default_categories.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../database/app_database.dart';
import '../../../../database/converters/transaction_type.dart';
import '../../../../database/database_provider.dart';
import '../../../categories/providers/categories_provider.dart';
import '../../providers/budget_provider.dart';

/// Screen allowing the user to configure total budget and per-category spending limits
/// for any selected month.
class BudgetSetupScreen extends ConsumerStatefulWidget {
  const BudgetSetupScreen({
    super.key,
    this.initialYearMonth,
  });

  /// The month to display initially in 'YYYY-MM' format (defaults to current month).
  final String? initialYearMonth;

  @override
  ConsumerState<BudgetSetupScreen> createState() => _BudgetSetupScreenState();
}

class _BudgetSetupScreenState extends ConsumerState<BudgetSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _totalLimitController = TextEditingController();

  late String _yearMonth;
  String? _currentBudgetId;
  bool _isLoading = true;
  bool _isSaving = false;

  /// Ordered list of categories currently configured for this budget.
  final List<Category> _selectedCategories = [];

  /// Controllers for each category limit, keyed by category ID.
  final Map<String, TextEditingController> _categoryControllers = {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _yearMonth = widget.initialYearMonth ??
        '${now.year}-${now.month.toString().padLeft(2, '0')}';
    _totalLimitController.addListener(_onFieldChanged);
    _loadBudgetForMonth(_yearMonth);
  }

  @override
  void dispose() {
    _totalLimitController.removeListener(_onFieldChanged);
    _totalLimitController.dispose();
    for (final controller in _categoryControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onFieldChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  /// Loads budget data for [ym] ('YYYY-MM') from the database into form controllers.
  Future<void> _loadBudgetForMonth(String ym) async {
    setState(() => _isLoading = true);

    final budgetDao = ref.read(budgetDaoProvider);
    final categoryDao = ref.read(categoryDaoProvider);

    final budget = await budgetDao.getBudgetForMonth(ym);

    // Dispose previous category controllers
    for (final controller in _categoryControllers.values) {
      controller.dispose();
    }
    _categoryControllers.clear();
    _selectedCategories.clear();

    if (budget != null) {
      _currentBudgetId = budget.id;
      _totalLimitController.text =
          CurrencyFormatter.format(budget.totalLimit, includeSymbol: false);

      final budgetCategories = await budgetDao.getBudgetCategories(budget.id);
      final allCategories = await categoryDao.getAllCategories();
      final catMap = {for (final c in allCategories) c.id: c};

      for (final bc in budgetCategories) {
        final cat = catMap[bc.categoryId];
        if (cat != null) {
          _selectedCategories.add(cat);
          final controller = TextEditingController(
            text: CurrencyFormatter.format(bc.limitAmount, includeSymbol: false),
          );
          controller.addListener(_onFieldChanged);
          _categoryControllers[cat.id] = controller;
        }
      }
    } else {
      _currentBudgetId = null;
      _totalLimitController.clear();
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _changeMonth(String nextYm) {
    if (_yearMonth == nextYm) return;
    setState(() {
      _yearMonth = nextYm;
    });
    _loadBudgetForMonth(nextYm);
  }

  void _goToPreviousMonth() {
    final parts = _yearMonth.split('-');
    var year = int.parse(parts[0]);
    var month = int.parse(parts[1]) - 1;
    if (month < 1) {
      month = 12;
      year--;
    }
    _changeMonth('$year-${month.toString().padLeft(2, '0')}');
  }

  void _goToNextMonth() {
    final parts = _yearMonth.split('-');
    var year = int.parse(parts[0]);
    var month = int.parse(parts[1]) + 1;
    if (month > 12) {
      month = 1;
      year++;
    }
    _changeMonth('$year-${month.toString().padLeft(2, '0')}');
  }

  String _formatMonthYear(String ym) {
    try {
      final parts = ym.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      return DateFormat('MMMM yyyy').format(DateTime(year, month));
    } catch (_) {
      return ym;
    }
  }

  int get _parsedTotalLimit =>
      CurrencyFormatter.tryParse(_totalLimitController.text) ?? 0;

  int get _parsedCategoryTotal {
    int sum = 0;
    for (final controller in _categoryControllers.values) {
      sum += CurrencyFormatter.tryParse(controller.text) ?? 0;
    }
    return sum;
  }

  int get _unallocatedAmount => _parsedTotalLimit - _parsedCategoryTotal;

  bool get _isOverallocated =>
      _parsedCategoryTotal > _parsedTotalLimit && _parsedTotalLimit > 0;

  Future<void> _openAddCategorySheet() async {
    final allExpenseCategories = await ref.read(
      activeCategoriesByTypeProvider(TransactionType.expense).future,
    );

    final alreadySelectedIds = _selectedCategories.map((c) => c.id).toSet();
    final availableCategories = allExpenseCategories
        .where((c) => !alreadySelectedIds.contains(c.id))
        .toList();

    if (!mounted) return;

    if (availableCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All expense categories have already been added.'),
        ),
      );
      return;
    }

    final chosen = await showModalBottomSheet<Category>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        'Select Category to Budget',
                        style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(sheetContext).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: availableCategories.length,
                    itemBuilder: (ctx, index) {
                      final category = availableCategories[index];
                      final catColor = Color(category.color);
                      final catIcon = DefaultCategories.getIconData(category.icon);

                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: catColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(catIcon, color: catColor, size: 22),
                        ),
                        title: Text(
                          category.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        onTap: () => Navigator.of(sheetContext).pop(category),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (chosen != null && mounted) {
      setState(() {
        _selectedCategories.add(chosen);
        final controller = TextEditingController();
        controller.addListener(_onFieldChanged);
        _categoryControllers[chosen.id] = controller;
      });
    }
  }

  void _removeCategory(Category category) {
    setState(() {
      _selectedCategories.removeWhere((c) => c.id == category.id);
      final controller = _categoryControllers.remove(category.id);
      controller?.dispose();
    });
  }

  Future<void> _confirmDeleteBudget() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Budget'),
        content: Text(
          'Are you sure you want to delete the budget for ${_formatMonthYear(_yearMonth)}?\n\n'
          'All category limits for this month will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogCtx).colorScheme.error,
              foregroundColor: Theme.of(dialogCtx).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted && _currentBudgetId != null) {
      try {
        await ref
            .read(budgetControllerProvider.notifier)
            .deleteBudget(_currentBudgetId!);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Budget for ${_formatMonthYear(_yearMonth)} deleted'),
            ),
          );
          _loadBudgetForMonth(_yearMonth);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete budget: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final totalLimit = _parsedTotalLimit;
    if (totalLimit <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a total budget amount greater than 0.'),
        ),
      );
      return;
    }

    final categoryLimits = <String, int>{};
    for (final cat in _selectedCategories) {
      final controller = _categoryControllers[cat.id];
      if (controller != null) {
        final amount = CurrencyFormatter.tryParse(controller.text) ?? 0;
        if (amount > 0) {
          categoryLimits[cat.id] = amount;
        }
      }
    }

    setState(() => _isSaving = true);
    try {
      await ref.read(budgetControllerProvider.notifier).saveBudget(
            yearMonth: _yearMonth,
            totalLimit: totalLimit,
            categoryLimits: categoryLimits,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Budget for ${_formatMonthYear(_yearMonth)} saved'),
          ),
        );
        _loadBudgetForMonth(_yearMonth);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save budget: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Setup'),
        actions: [
          if (_currentBudgetId != null)
            IconButton(
              icon: Icon(Icons.delete_outline, color: colorScheme.error),
              tooltip: 'Delete Budget',
              onPressed: _confirmDeleteBudget,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Month Switcher Header
                      Card(
                        elevation: 0,
                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left),
                                tooltip: 'Previous month',
                                onPressed: _goToPreviousMonth,
                              ),
                              Text(
                                _formatMonthYear(_yearMonth),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.chevron_right),
                                tooltip: 'Next month',
                                onPressed: _goToNextMonth,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Header Title & Description
                      Text(
                        'Monthly Budget Setup',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Configure total budget and per-category spending limits',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Section 1: Total Budget Input
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.account_balance_wallet_outlined,
                                      color: colorScheme.primary, size: 22),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Total Monthly Budget',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _totalLimitController,
                                keyboardType: TextInputType.number,
                                inputFormatters: const [
                                  CurrencyInputFormatter(),
                                ],
                                decoration: const InputDecoration(
                                  labelText: 'Total Budget Amount',
                                  prefixText: 'Rp ',
                                  hintText: '0',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Please enter a total budget';
                                  }
                                  final amount = CurrencyFormatter.tryParse(val);
                                  if (amount == null || amount <= 0) {
                                    return 'Please enter an amount greater than 0';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Section 2: Allocation Tracker & Live Summary
                      _buildAllocationSummaryCard(theme, colorScheme),
                      const SizedBox(height: 16),

                      // Section 3: Per-Category Limits List
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    'Category Limits',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.secondaryContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${_selectedCategories.length}',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onSecondaryContainer,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: _openAddCategorySheet,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Category'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      if (_selectedCategories.isEmpty)
                        Card(
                          elevation: 0,
                          color: colorScheme.surfaceContainerLow,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.category_outlined,
                                  size: 40,
                                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No category limits configured',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tap "+ Add Category" to set individual spending limits for specific expense categories.',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _selectedCategories.length,
                          separatorBuilder: (ctx, idx) => const SizedBox(height: 8),
                          itemBuilder: (ctx, index) {
                            final category = _selectedCategories[index];
                            final controller = _categoryControllers[category.id]!;
                            final catColor = Color(category.color);
                            final catIcon =
                                DefaultCategories.getIconData(category.icon);

                            return Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: colorScheme.outlineVariant
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: catColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(catIcon, color: catColor, size: 22),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        category.name,
                                        style: theme.textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      flex: 4,
                                      child: TextFormField(
                                        controller: controller,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: const [
                                          CurrencyInputFormatter(),
                                        ],
                                        decoration: const InputDecoration(
                                          prefixText: 'Rp ',
                                          hintText: '0',
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 10,
                                          ),
                                          border: OutlineInputBorder(),
                                        ),
                                        validator: (val) {
                                          if (val != null && val.trim().isNotEmpty) {
                                            final amt =
                                                CurrencyFormatter.tryParse(val);
                                            if (amt == null || amt <= 0) {
                                              return '> 0';
                                            }
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete_outline,
                                        color: colorScheme.error,
                                        size: 20,
                                      ),
                                      tooltip: 'Remove',
                                      onPressed: () => _removeCategory(category),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(
            onPressed: _isSaving ? null : _saveBudget,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Save Budget',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildAllocationSummaryCard(ThemeData theme, ColorScheme colorScheme) {
    final total = _parsedTotalLimit;
    final allocated = _parsedCategoryTotal;
    final unallocated = _unallocatedAmount;
    final isOver = _isOverallocated;

    final ratio = total > 0 ? (allocated / total).clamp(0.0, 1.0) : 0.0;
    final progressColor = isOver
        ? AppColors.budgetDanger
        : (allocated == total && total > 0
            ? AppColors.budgetSafe
            : colorScheme.primary);

    return Card(
      elevation: 0,
      color: isOver
          ? colorScheme.errorContainer.withValues(alpha: 0.3)
          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isOver
              ? colorScheme.error.withValues(alpha: 0.6)
              : colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Allocation Summary',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${(ratio * 100).toInt()}% allocated',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: progressColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 8,
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _buildSummaryColumn(
                    label: 'Allocated',
                    amount: CurrencyFormatter.format(allocated),
                    color: colorScheme.onSurface,
                    theme: theme,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryColumn(
                    label: isOver ? 'Over Budget' : 'Unallocated',
                    amount: CurrencyFormatter.format(isOver ? (allocated - total) : unallocated),
                    color: isOver
                        ? AppColors.budgetDanger
                        : (unallocated > 0 ? AppColors.budgetSafe : colorScheme.onSurfaceVariant),
                    theme: theme,
                    alignEnd: true,
                  ),
                ),
              ],
            ),

            // Warning Banner if category limits exceed total budget (as specified in master plan)
            if (isOver) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: colorScheme.onErrorContainer, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Warning: Category limits (${CurrencyFormatter.format(allocated)}) exceed the total budget (${CurrencyFormatter.format(total)}) by ${CurrencyFormatter.format(allocated - total)}.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onErrorContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryColumn({
    required String label,
    required String amount,
    required Color color,
    required ThemeData theme,
    bool alignEnd = false,
  }) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          amount,
          style: theme.textTheme.titleSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
