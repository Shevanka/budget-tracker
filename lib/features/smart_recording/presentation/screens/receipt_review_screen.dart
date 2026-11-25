import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/default_categories.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../database/converters/transaction_type.dart';
import '../../../../routing/app_routes.dart';
import '../../../categories/presentation/widgets/category_picker_field.dart';
import '../../../transactions/providers/transactions_provider.dart';
import '../../models/parsed_receipt.dart';
import '../../providers/smart_recording_provider.dart';

/// Screen for reviewing, editing, and confirming parsed receipt data
/// before saving it directly to the database or passing it to the transaction editor.
class ReceiptReviewScreen extends ConsumerStatefulWidget {
  final ParsedReceipt? initialReceipt;

  const ReceiptReviewScreen({
    super.key,
    this.initialReceipt,
  });

  @override
  ConsumerState<ReceiptReviewScreen> createState() => _ReceiptReviewScreenState();
}

class _ReceiptReviewScreenState extends ConsumerState<ReceiptReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _merchantController = TextEditingController();
  final _sourceController = TextEditingController(text: 'Cash');

  String? _selectedCategoryId;
  String? _categoryError;
  DateTime _selectedDate = DateTime.now();
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
    final receipt = widget.initialReceipt;
    if (receipt != null) {
      _initFromReceipt(receipt);
    }
  }

  void _initFromReceipt(ParsedReceipt receipt) {
    if (receipt.amount != null && receipt.amount! > 0) {
      _amountController.text = CurrencyFormatter.format(
        receipt.amount!,
        includeSymbol: false,
      );
    }
    if (receipt.merchant != null && receipt.merchant!.isNotEmpty) {
      final summary = receipt.itemsSummary;
      _merchantController.text = summary.isNotEmpty
          ? '${receipt.merchant} ($summary)'
          : receipt.merchant!;
    }
    if (receipt.date != null) {
      _selectedDate = receipt.date!.toLocal();
    }
    _selectedCategoryId = receipt.suggestedCategoryId ?? DefaultCategories.otherId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    _sourceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final receipt = widget.initialReceipt ?? ref.watch(latestParsedReceiptProvider);

    if (receipt == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Tinjau Data Struk'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 64,
                  color: colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'Tidak ada data struk yang dipilih',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => context.pushReplacement(AppRoute.receiptPicker.path),
                  icon: const Icon(Icons.document_scanner_outlined),
                  label: const Text('Pindai Struk Sekarang'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final hasLocalImage = !kIsWeb &&
        receipt.imagePath.isNotEmpty &&
        File(receipt.imagePath).existsSync();

    final isCategorySuggested = receipt.suggestedCategoryId != null &&
        _selectedCategoryId == receipt.suggestedCategoryId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tinjau Data Struk'),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new_rounded),
            tooltip: 'Buka di Form Lengkap',
            onPressed: () => _openFullEditor(receipt),
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
                // 1. Receipt Thumbnail & Detected Badge Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: hasLocalImage
                            ? Image.file(
                                File(receipt.imagePath),
                                fit: BoxFit.cover,
                              )
                            : Icon(
                                Icons.receipt_long_rounded,
                                size: 30,
                                color: colorScheme.primary,
                              ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  size: 16,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Teks Berhasil Dikenali',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              receipt.items.isNotEmpty
                                  ? '${receipt.items.length} item belanja teridentifikasi'
                                  : '${receipt.lines.length} baris teks terdeteksi dari OCR ML Kit',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Amount Input
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    const CurrencyInputFormatter(),
                  ],
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.expense,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Total Belanja',
                    prefixText: 'Rp ',
                    prefixStyle: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.expense,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerLow,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Masukkan jumlah belanja';
                    }
                    final parsed = CurrencyFormatter.tryParse(value);
                    if (parsed == null || parsed <= 0) {
                      return 'Jumlah belanja harus lebih dari 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // 3. Merchant / Toko Name
                TextFormField(
                  controller: _merchantController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Nama Toko / Merchant',
                    hintText: 'Contoh: Indomaret, Kopi Kenangan',
                    prefixIcon: const Icon(Icons.storefront_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerLow,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Masukkan nama toko atau catatan transaksi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Itemized products list if available
                if (receipt.items.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.shopping_bag_outlined,
                              size: 18,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Daftar Item Belanja (${receipt.items.length} item)',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...receipt.items.map((item) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.quantity != null
                                        ? '${item.quantity}x ${item.name}'
                                        : item.name,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  item.formattedTotalPrice,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // 4. Category Picker & AI Suggestion Badge
                CategoryPickerField(
                  selectedCategoryId: _selectedCategoryId,
                  categoryType: TransactionType.expense,
                  errorMessage: _categoryError,
                  onCategorySelected: (cat) {
                    setState(() {
                      _selectedCategoryId = cat.id;
                      _categoryError = null;
                    });
                  },
                ),
                if (isCategorySuggested && receipt.suggestedCategoryName != null) ...[
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          size: 14,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Saran otomatis untuk ${receipt.suggestedCategoryName}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.primary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                // 5. Payment Source Input & Quick Chips
                TextFormField(
                  controller: _sourceController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Metode Pembayaran',
                    hintText: 'Contoh: Cash, BCA, GoPay',
                    prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerLow,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Pilih atau isi metode pembayaran';
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
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 48),
                          child: ChoiceChip(
                            label: Text(source),
                            selected: isSelected,
                            onSelected: (_) {
                              setState(() {
                                _sourceController.text = source;
                              });
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),

                // 6. Transaction Date Picker
                Semantics(
                  button: true,
                  label: 'Ubah Tanggal Transaksi: ${DateFormat('EEEE, d MMMM yyyy').format(_selectedDate)}',
                  child: InkWell(
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
                                  'Tanggal Transaksi',
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
                ),
                const SizedBox(height: 20),

                // 7. Accordion: Raw OCR Output
                if (receipt.rawText.isNotEmpty) ...[
                  Theme(
                    data: theme.copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: const EdgeInsets.only(bottom: 8),
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      leading: Icon(
                        Icons.text_snippet_outlined,
                        size: 20,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      title: Text(
                        'Teks Mentah Struk (OCR)',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      children: [
                        Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxHeight: 180),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colorScheme.outlineVariant
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                          child: SingleChildScrollView(
                            child: Text(
                              receipt.rawText,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // 8. Action Buttons: Confirm & Save
                FilledButton.icon(
                  onPressed: _isSaving ? null : _saveTransaction,
                  icon: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Icon(Icons.check_circle_outline_rounded),
                  label: Text(
                    _isSaving ? 'Menyimpan...' : 'Konfirmasi & Simpan Transaksi',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Button: Use Data / Return to Caller
                OutlinedButton.icon(
                  onPressed: () => _returnToCaller(receipt),
                  icon: const Icon(Icons.edit_note_rounded),
                  label: const Text('Gunakan Data di Form Tambah'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Button: Cancel / Retake
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('Batal'),
                ),
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
      _categoryError = _selectedCategoryId == null ? 'Pilih kategori belanja' : null;
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
    final created = await controller.createTransaction(
      amount: amount,
      type: TransactionType.expense,
      categoryId: _selectedCategoryId!,
      source: _sourceController.text.trim(),
      date: _selectedDate,
      note: _merchantController.text.trim(),
    );

    if (!mounted) return;
    setState(() {
      _isSaving = false;
    });

    final messenger = ScaffoldMessenger.of(context);
    if (created != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Transaksi disimpan: ${CurrencyFormatter.format(amount)} (${_merchantController.text.trim()})',
          ),
        ),
      );
      if (context.canPop()) {
        context.pop(created);
      }
    } else {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Gagal menyimpan transaksi'),
        ),
      );
    }
  }

  void _returnToCaller(ParsedReceipt originalReceipt) {
    final amount = CurrencyFormatter.tryParse(_amountController.text);
    final updatedReceipt = ParsedReceipt(
      merchant: _merchantController.text.trim(),
      amount: amount ?? originalReceipt.amount,
      date: _selectedDate,
      suggestedCategoryId: _selectedCategoryId,
      suggestedCategoryName: originalReceipt.suggestedCategoryName,
      rawText: originalReceipt.rawText,
      imagePath: originalReceipt.imagePath,
      lines: originalReceipt.lines,
      items: originalReceipt.items,
      cleanLines: originalReceipt.cleanLines,
    );

    if (context.canPop()) {
      context.pop(updatedReceipt);
    }
  }

  void _openFullEditor(ParsedReceipt receipt) {
    final amount = CurrencyFormatter.tryParse(_amountController.text) ?? receipt.amount;
    context.push(
      AppRoute.addTransaction.path,
      extra: {
        'amount': amount,
        'source': _sourceController.text.trim(),
        'categoryId': _selectedCategoryId,
        'note': _merchantController.text.trim(),
        'date': _selectedDate,
        'type': TransactionType.expense,
      },
    );
  }
}
