import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../models/receipt_scan_result.dart';

/// Abstract service interface for running OCR on a receipt image.
abstract class ReceiptOcrService {
  const ReceiptOcrService();

  /// Processes the image at [imagePath] and returns the extracted [ReceiptScanResult].
  Future<ReceiptScanResult> processImage(String imagePath);

  /// Disposes ML Kit resources.
  Future<void> dispose();
}

/// Production implementation using Google ML Kit on-device text recognition.
class DefaultReceiptOcrService implements ReceiptOcrService {
  final TextRecognizer _recognizer;
  bool _isDisposed = false;

  DefaultReceiptOcrService([TextRecognizer? recognizer])
      : _recognizer = recognizer ??
            TextRecognizer(script: TextRecognitionScript.latin);

  @override
  Future<ReceiptScanResult> processImage(String imagePath) async {
    if (_isDisposed) {
      throw StateError(
        'Cannot process image after ReceiptOcrService has been disposed.',
      );
    }

    final inputImage = InputImage.fromFilePath(imagePath);
    final recognizedText = await _recognizer.processImage(inputImage);

    final lines = <String>[];
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final text = line.text.trim();
        if (text.isNotEmpty) {
          lines.add(text);
        }
      }
    }

    return ReceiptScanResult(
      imagePath: imagePath,
      rawText: recognizedText.text,
      lines: lines,
      timestamp: DateTime.now().toUtc(),
    );
  }

  @override
  Future<void> dispose() async {
    if (!_isDisposed) {
      _isDisposed = true;
      await _recognizer.close();
    }
  }
}
