import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/widgets.dart';
import '../../../../routing/app_routes.dart';
import '../../models/receipt_scan_result.dart';
import '../../providers/smart_recording_provider.dart';
import '../../services/image_picker_wrapper.dart';

/// Screen allowing the user to capture a receipt via camera or pick from gallery,
/// triggering on-device ML Kit OCR text recognition.
class ReceiptPickerScreen extends ConsumerWidget {
  const ReceiptPickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = ref.watch(receiptScannerProvider);
    final notifier = ref.read(receiptScannerProvider.notifier);

    ref.listen<ReceiptScannerState>(receiptScannerProvider, (_, next) {
      if (next is ReceiptScannerError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memproses struk: ${next.message}'),
            backgroundColor: colorScheme.error,
          ),
        );
      } else if (next is ReceiptScannerCancelled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengambilan gambar dibatalkan.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    });

    final isProcessing = state is ReceiptScannerPicking || state is ReceiptScannerProcessing;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Receipt'),
        actions: [
          if (state is ReceiptScannerSuccess)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Pindai Ulang',
              onPressed: notifier.reset,
            ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header card
                _buildHeaderCard(context),
                const SizedBox(height: 20),

                // Success Preview or Guidelines
                if (state is ReceiptScannerSuccess)
                  _buildSuccessResultCard(context, ref, state.result, notifier)
                else ...[
                  if (state is ReceiptScannerError) ...[
                    AppErrorState(
                      isCard: true,
                      title: 'Pemindaian Gagal',
                      message: state.message,
                      onRetry: notifier.reset,
                      retryLabel: 'Ulangi Pemindaian',
                    ),
                    const SizedBox(height: 16),
                  ],
                  _buildScanningTipsCard(context),
                  const SizedBox(height: 24),
                  _buildActionButtons(context, notifier, isProcessing),
                ],
              ],
            ),
          ),

          // Loading / OCR Processing Overlay
          if (isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: Center(
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 24,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          state is ReceiptScannerPicking
                              ? 'Membuka kamera / galeri...'
                              : 'Membaca teks dari struk...',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'On-device ML Kit Text Recognition',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              color: colorScheme.onPrimary,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Receipt Scanner',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Capture a photo or pick an image from gallery to extract transaction details.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanningTipsCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Tips Pemindaian Struk',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTipRow(
              context,
              icon: Icons.wb_sunny_outlined,
              text: 'Pastikan pencahayaan terang dan tidak ada bayangan gelap.',
            ),
            const SizedBox(height: 8),
            _buildTipRow(
              context,
              icon: Icons.crop_free_rounded,
              text: 'Ratakan struk dan posisikan tegak lurus di depan kamera.',
            ),
            const SizedBox(height: 8),
            _buildTipRow(
              context,
              icon: Icons.check_circle_outline_rounded,
              text: 'Pastikan nama toko, tanggal, dan total belanja terlihat jelas.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipRow(
    BuildContext context, {
    required IconData icon,
    required String text,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    ReceiptScannerNotifier notifier,
    bool isProcessing,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: isProcessing
              ? null
              : () => notifier.scanFromSource(ReceiptImageSource.camera),
          icon: const Icon(Icons.camera_alt_rounded),
          label: const Text('Ambil Foto Kamera'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: isProcessing
              ? null
              : () => notifier.scanFromSource(ReceiptImageSource.gallery),
          icon: const Icon(Icons.photo_library_rounded),
          label: const Text('Pilih dari Galeri'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessResultCard(
    BuildContext context,
    WidgetRef ref,
    ReceiptScanResult result,
    ReceiptScannerNotifier notifier,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final lines = result.lines;
    final hasText = result.hasText;
    final parsed = ref.watch(latestParsedReceiptProvider);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  hasText
                      ? Icons.check_circle_rounded
                      : Icons.warning_amber_rounded,
                  color: hasText ? Colors.green : colorScheme.error,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hasText
                        ? 'Teks Berhasil Dikenali (${lines.length} baris)'
                        : 'Tidak Ada Teks Terdeteksi',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (hasText) ...[
              if (parsed != null && parsed.isRecognized) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Toko / Merchant:',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            parsed.merchant ?? '-',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Belanja:',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            parsed.formattedAmount,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (parsed.suggestedCategoryName != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Kategori Disarankan:',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                parsed.suggestedCategoryName!,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSecondaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Text(
                'Pratinjau Hasil OCR:',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 180),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: lines.length,
                  itemBuilder: (context, index) {
                    return Text(
                      lines[index],
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  if (parsed != null) {
                    context.push(AppRoute.receiptReview.path, extra: parsed);
                  } else {
                    Navigator.of(context).pop(result);
                  }
                },
                icon: const Icon(Icons.rate_review_outlined),
                label: const Text('Tinjau & Konfirmasi Data'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop(parsed ?? result);
                },
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Gunakan Data Struk'),
              ),
            ] else ...[
              Text(
                'ML Kit tidak dapat mendeteksi teks pada gambar ini. Pastikan struk cukup terang dan tidak buram, lalu coba pindai ulang.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: notifier.reset,
                icon: const Icon(Icons.replay_rounded),
                label: const Text('Coba Lagi'),
              ),
            ],
            const SizedBox(height: 8),
            TextButton(
              onPressed: notifier.reset,
              child: const Text('Pindai Foto Lain'),
            ),
          ],
        ),
      ),
    );
  }
}
