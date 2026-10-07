import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/default_categories.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../database/app_database.dart';
import '../../../../database/converters/transaction_type.dart';
import '../../providers/categories_provider.dart';

/// Modal bottom sheet for creating or editing a category.
class AddEditCategorySheet extends ConsumerStatefulWidget {
  const AddEditCategorySheet({
    super.key,
    this.category,
    this.initialType = TransactionType.expense,
  });

  /// The existing category to edit, or `null` if creating a new category.
  final Category? category;

  /// Default type when creating a new category.
  final TransactionType initialType;

  /// Curated palette of vibrant category colors.
  static const List<int> availableColors = [
    0xFF43A047, // Green
    0xFF2E7D32, // Dark Green
    0xFF00897B, // Teal
    0xFF00ACC1, // Cyan
    0xFF1E88E5, // Blue
    0xFF3949AB, // Indigo
    0xFF5E35B1, // Deep Purple
    0xFF8E24AA, // Purple
    0xFFD81B60, // Pink
    0xFFE53935, // Red
    0xFFF4511E, // Deep Orange
    0xFFFB8C00, // Orange
    0xFFFFB300, // Amber
    0xFF6D4C41, // Brown
    0xFF546E7A, // Blue Grey
    0xFF424242, // Grey
  ];

  /// Curated collection of Material icons for expense and income categories.
  static const List<IconData> availableIcons = [
    Icons.restaurant,
    Icons.fastfood,
    Icons.local_cafe,
    Icons.shopping_bag,
    Icons.shopping_cart,
    Icons.directions_car,
    Icons.directions_bus,
    Icons.local_gas_station,
    Icons.receipt_long,
    Icons.home,
    Icons.medical_services,
    Icons.fitness_center,
    Icons.movie,
    Icons.sports_esports,
    Icons.flight,
    Icons.school,
    Icons.card_giftcard,
    Icons.pets,
    Icons.payments,
    Icons.trending_up,
    Icons.savings,
    Icons.work,
    Icons.account_balance,
    Icons.phone_android,
  ];

  @override
  ConsumerState<AddEditCategorySheet> createState() =>
      _AddEditCategorySheetState();
}

class _AddEditCategorySheetState extends ConsumerState<AddEditCategorySheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  late TransactionType _selectedType;
  late int _selectedColor;
  late IconData _selectedIcon;
  bool _isSaving = false;

  bool get isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    final cat = widget.category;
    _nameController = TextEditingController(text: cat?.name ?? '');
    _selectedType = cat?.type ?? widget.initialType;
    _selectedColor = cat?.color ?? AddEditCategorySheet.availableColors.first;
    _selectedIcon = cat != null
        ? DefaultCategories.getIconData(cat.icon)
        : (_selectedType == TransactionType.income
            ? Icons.payments
            : Icons.restaurant);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final name = _nameController.text.trim();
      final iconStr = _selectedIcon.codePoint.toString();
      final controller = ref.read(categoryControllerProvider.notifier);

      if (isEditing) {
        await controller.updateCategory(
          id: widget.category!.id,
          name: name,
          icon: iconStr,
          color: _selectedColor,
          type: _selectedType,
        );
      } else {
        await controller.createCategory(
          name: name,
          icon: iconStr,
          color: _selectedColor,
          type: _selectedType,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save category: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Bottom sheet handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Sheet Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing ? 'Edit Category' : 'Add Category',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Live Preview Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(_selectedColor).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Color(_selectedColor).withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Color(_selectedColor),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Color(_selectedColor).withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          _selectedIcon,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ValueListenableBuilder<TextEditingValue>(
                              valueListenable: _nameController,
                              builder: (context, value, _) {
                                final text = value.text.trim();
                                return Text(
                                  text.isEmpty ? 'Category Name' : text,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: text.isEmpty
                                        ? colorScheme.onSurfaceVariant
                                        : colorScheme.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                );
                              },
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _selectedType == TransactionType.income
                                    ? AppColors.income.withValues(alpha: 0.15)
                                    : AppColors.expense.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _selectedType == TransactionType.income
                                    ? 'Income Category'
                                    : 'Expense Category',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: _selectedType == TransactionType.income
                                      ? AppColors.income
                                      : AppColors.expense,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Transaction Type Segmented Selector
                SegmentedButton<TransactionType>(
                  segments: const [
                    ButtonSegment<TransactionType>(
                      value: TransactionType.expense,
                      label: Text('Expense'),
                      icon: Icon(Icons.arrow_downward, color: AppColors.expense),
                    ),
                    ButtonSegment<TransactionType>(
                      value: TransactionType.income,
                      label: Text('Income'),
                      icon: Icon(Icons.arrow_upward, color: AppColors.income),
                    ),
                  ],
                  selected: {_selectedType},
                  onSelectionChanged: (newSelection) {
                    setState(() {
                      _selectedType = newSelection.first;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Name Input Field
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Category Name',
                    hintText: 'e.g. Groceries, Streaming, Freelance',
                    prefixIcon: Icon(Icons.label_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a category name';
                    }
                    if (value.trim().length > 40) {
                      return 'Category name must be 40 characters or less';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Color Selection
                Text(
                  'Color',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 48,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: AddEditCategorySheet.availableColors.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final colorInt = AddEditCategorySheet.availableColors[index];
                      final isSelected = colorInt == _selectedColor;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedColor = colorInt);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Color(colorInt),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? colorScheme.onSurface
                                  : Colors.transparent,
                              width: isSelected ? 3 : 1,
                            ),
                            boxShadow: [
                              if (isSelected)
                                BoxShadow(
                                  color: Color(colorInt).withValues(alpha: 0.5),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                            ],
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 22,
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Icon Selection
                Text(
                  'Icon',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: AddEditCategorySheet.availableIcons.map((icon) {
                      final isSelected = icon == _selectedIcon;
                      return InkWell(
                        onTap: () {
                          setState(() => _selectedIcon = icon);
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Color(_selectedColor)
                                : colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? Color(_selectedColor)
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            icon,
                            color: isSelected
                                ? Colors.white
                                : colorScheme.onSurfaceVariant,
                            size: 22,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _isSaving ? null : _save,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(isEditing ? 'Save Changes' : 'Create Category'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
