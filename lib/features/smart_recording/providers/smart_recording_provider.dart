import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/parsed_receipt.dart';
import '../models/receipt_scan_result.dart';
import '../services/image_picker_wrapper.dart';
import '../services/receipt_ocr_service.dart';
import '../services/receipt_parser.dart';

/// Base class representing state transitions for the receipt scanner.
sealed class ReceiptScannerState {
  const ReceiptScannerState();
}

/// Scanner is ready for user to capture or select an image.
class ReceiptScannerIdle extends ReceiptScannerState {
  const ReceiptScannerIdle();
}

/// The image picker (camera or gallery) is active.
class ReceiptScannerPicking extends ReceiptScannerState {
  final ReceiptImageSource source;
  const ReceiptScannerPicking(this.source);
}

/// ML Kit OCR text recognition is running on the captured image.
class ReceiptScannerProcessing extends ReceiptScannerState {
  final String imagePath;
  final ReceiptImageSource source;
  const ReceiptScannerProcessing({
    required this.imagePath,
    required this.source,
  });
}

/// Text recognition completed successfully.
class ReceiptScannerSuccess extends ReceiptScannerState {
  final ReceiptScanResult result;
  const ReceiptScannerSuccess(this.result);
}

/// An error occurred during image capture or OCR.
class ReceiptScannerError extends ReceiptScannerState {
  final String message;
  const ReceiptScannerError(this.message);
}

/// User dismissed camera or gallery picker without selecting an image.
class ReceiptScannerCancelled extends ReceiptScannerState {
  const ReceiptScannerCancelled();
}

/// State notifier managing receipt camera/gallery capture and OCR text recognition.
class ReceiptScannerNotifier extends Notifier<ReceiptScannerState> {
  @override
  ReceiptScannerState build() => const ReceiptScannerIdle();

  /// Captures or picks an image from [source], runs ML Kit OCR, and updates state.
  Future<ReceiptScanResult?> scanFromSource(ReceiptImageSource source) async {
    state = ReceiptScannerPicking(source);
    try {
      final picker = ref.read(imagePickerWrapperProvider);
      final imagePath = await picker.pickImage(source: source);

      if (imagePath == null) {
        state = const ReceiptScannerCancelled();
        return null;
      }

      state = ReceiptScannerProcessing(imagePath: imagePath, source: source);

      final ocrService = ref.read(receiptOcrServiceProvider);
      final result = await ocrService.processImage(imagePath);

      state = ReceiptScannerSuccess(result);
      ref.read(latestScanResultProvider.notifier).state = result;
      return result;
    } catch (e) {
      state = ReceiptScannerError(e.toString());
      return null;
    }
  }

  /// Resets scanner to idle state.
  void reset() {
    state = const ReceiptScannerIdle();
  }
}

/// Provides the active [ImagePickerWrapper] instance.
final imagePickerWrapperProvider = Provider<ImagePickerWrapper>((ref) {
  return DefaultImagePickerWrapper();
});

/// Provides the active [ReceiptOcrService] instance.
final receiptOcrServiceProvider = Provider<ReceiptOcrService>((ref) {
  final service = DefaultReceiptOcrService();
  ref.onDispose(service.dispose);
  return service;
});

/// Manages the state of the receipt scanning and OCR process.
final receiptScannerProvider =
    NotifierProvider<ReceiptScannerNotifier, ReceiptScannerState>(
  ReceiptScannerNotifier.new,
);

/// Holds the most recently scanned [ReceiptScanResult].
final latestScanResultProvider = StateProvider<ReceiptScanResult?>((ref) => null);

/// Provides the active [ReceiptParser] instance.
final receiptParserProvider = Provider<ReceiptParser>((ref) {
  return const ReceiptParser();
});

/// Automatically derives a [ParsedReceipt] from [latestScanResultProvider].
final latestParsedReceiptProvider = Provider<ParsedReceipt?>((ref) {
  final scanResult = ref.watch(latestScanResultProvider);
  if (scanResult == null) return null;
  final parser = ref.watch(receiptParserProvider);
  return parser.parse(scanResult);
});
