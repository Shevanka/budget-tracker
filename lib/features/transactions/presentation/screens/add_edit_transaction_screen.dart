import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../database/converters/transaction_type.dart';
import '../../../../routing/app_routes.dart';
import '../../../categories/presentation/widgets/category_picker_field.dart';
import '../../providers/transactions_provider.dart';

/// Screen for creating a new transaction or editing an existing one.
class AddEditTransactionScreen extends ConsumerStatefulWidget {
  const AddEditTransactionScreen({
    super.key,
    this.transactionId,
  });

  final String? transactionId;

  bool get isEditing => transactionId != null && transactionId!.isNotEmpty;

  @override
  ConsumerState<AddEditTransactionScreen> createState() =>
      _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState
    extends ConsumerState<AddEditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _sourceController = TextEditingController();
  final _noteController = TextEditingController();

  TransactionType _selectedType = TransactionType.expense;
  String? _selectedCategoryId;
  String? _categoryError;
  DateTime _selectedDate = DateTime.now();

  bool _isLoadingInitial = false;
  bool _isSaving = false;

  static const List<String> _commonSources = [
    'Cash',
    'BCA',
    'Mandiri',
    'GoPay',
    'OVO',
    'DANA',
    'ShopeePay',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _isLoadingInitial = true;
      _loadExistingTransaction();
    } else {
      _sourceController.text = 'Cash';
    }
  }

  Future<void> _loadExistingTransaction() async {
    final tx = await ref.read(transactionByIdProvider(widget.transactionId!).future);
    if (!mounted) return;

    if (tx != null) {
      setState(() {
        _selectedType = tx.type;
        _amountController.text = CurrencyFormatter.format(tx.amount).replaceFirst('Rp ', '');
        _selectedCategoryId = tx.categoryId;
        _sourceController.text = tx.source;
        _selectedDate = tx.date.toLocal();
        _noteController.text = tx.note ?? '';
        _isLoadingInitial = false;
      });
    } else {
      setState(() {
        _isLoadingInitial = false;
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _sourceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoadingInitial) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.isEditing ? 'Edit Transaction' : 'Add Transaction'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Transaction' : 'Add Transaction'),
        actions: [
          if (widget.isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete Transaction',
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Type Selector (Expense / Income)
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
                    final newType = newSelection.first;
                    if (newType != _selectedType) {
                      setState(() {
                        _selectedType = newType;
                        _selectedCategoryId = null;
                        _categoryError = null;
                      });
                    }
                  },
                ),
                const SizedBox(height: 24),

                // Amount Field
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    const CurrencyInputFormatter(),
                  ],
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _selectedType == TransactionType.expense
                        ? AppColors.expense
                        : AppColors.income,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    prefixText: 'Rp ',
                    prefixStyle: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _selectedType == TransactionType.expense
                          ? AppColors.expense
                          : AppColors.income,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerLow,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an amount';
                    }
                    final parsed = CurrencyFormatter.tryParse(value);
                    if (parsed == null || parsed <= 0) {
                      return 'Please enter a valid amount greater than 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Category Picker
                CategoryPickerField(
                  selectedCategoryId: _selectedCategoryId,
                  categoryType: _selectedType,
                  errorMessage: _categoryError,
                  onCategorySelected: (cat) {
                    setState(() {
                      _selectedCategoryId = cat.id;
                      _categoryError = null;
                    });
                  },
                ),
                const SizedBox(height: 20),

                // Source Input & Quick Chips
                TextFormField(
                  controller: _sourceController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Payment Method / Source',
                    hintText: 'e.g. Cash, BCA, GoPay',
                    prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerLow,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please specify the payment method or source';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _commonSources.map((source) {
                      final isSelected = _sourceController.text.trim().toLowerCase() ==
                          source.toLowerCase();
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(source),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() {
                              _sourceController.text = source;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),

                // Date Picker Tile
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.5),
                      ),
                      borderRadius: BorderRadius.circular(16),
                      color: colorScheme.surfaceContainerLow,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          color: colorScheme.onSurfaceVariant,
                          size: 22,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Transaction Date',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat('EEEE, d MMMM yyyy').format(_selectedDate),
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.edit_calendar_outlined,
                          size: 20,
                          color: colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Note Field
                TextFormField(
                  controller: _noteController,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Note (Optional)',
                    hintText: 'e.g. Lunch with colleagues',
                    prefixIcon: const Icon(Icons.notes_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerLow,
                  ),
                ),
                const SizedBox(height: 20),

                // Receipt Scanner Action Button
                OutlinedButton.icon(
                  onPressed: () => context.push(AppRoute.receiptPicker.path),
                  icon: const Icon(Icons.document_scanner_outlined),
                  label: const Text('Scan Receipt (OCR)'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Save Button
                FilledButton(
                  onPressed: _isSaving ? null : _saveTransaction,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : Text(
                          widget.isEditing ? 'Update Transaction' : 'Save Transaction',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDate.hour,
          _selectedDate.minute,
        );
      });
    }
  }

  Future<void> _saveTransaction() async {
    setState(() {
      _categoryError = _selectedCategoryId == null ? 'Please select a category' : null;
    });

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || _selectedCategoryId == null) {
      return;
    }

    final amount = CurrencyFormatter.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final controller = ref.read(transactionControllerProvider.notifier);

    if (widget.isEditing) {
      final success = await controller.updateTransaction(
        id: widget.transactionId!,
        amount: amount,
        type: _selectedType,
        categoryId: _selectedCategoryId!,
        source: _sourceController.text.trim(),
        date: _selectedDate,
        note: _noteController.text.trim().isNotEmpty
            ? _noteController.text.trim()
            : null,
      );

      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });

      final messenger = ScaffoldMessenger.of(context);
      if (success) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Transaction updated')),
        );
        if (context.canPop()) {
          context.pop();
        }
      } else {
        messenger.showSnackBar(
          const SnackBar(content: Text('Failed to update transaction')),
        );
      }
    } else {
      final created = await controller.createTransaction(
        amount: amount,
        type: _selectedType,
        categoryId: _selectedCategoryId!,
        source: _sourceController.text.trim(),
        date: _selectedDate,
        note: _noteController.text.trim().isNotEmpty
            ? _noteController.text.trim()
            : null,
      );

      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });

      final messenger = ScaffoldMessenger.of(context);
      if (created != null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Transaction saved')),
        );
        if (context.canPop()) {
          context.pop();
        }
      } else {
        messenger.showSnackBar(
          const SnackBar(content: Text('Failed to save transaction')),
        );
      }
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Transaction'),
          content: const Text(
            'Are you sure you want to delete this transaction?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.expense,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      final controller = ref.read(transactionControllerProvider.notifier);
      final deletedTx =
          await controller.deleteTransactionWithUndo(widget.transactionId!);

      if (!mounted) return;

      final messenger = ScaffoldMessenger.of(context);
      if (deletedTx != null) {
        if (context.canPop()) {
          context.pop();
        }
        messenger.showSnackBar(
          SnackBar(
            content: const Text('Transaction deleted'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                controller.restoreTransaction(deletedTx);
              },
            ),
          ),
        );
      } else {
        messenger.showSnackBar(
          const SnackBar(content: Text('Failed to delete transaction')),
        );
      }
    }
  }
}
