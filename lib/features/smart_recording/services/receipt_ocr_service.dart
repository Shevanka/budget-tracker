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

    final allLines = <TextLine>[];
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final text = line.text.trim();
        if (text.isNotEmpty) {
          allLines.add(line);
        }
      }
    }

    final reconstructedLines = _reconstructLinesSpatially(allLines);

    return ReceiptScanResult(
      imagePath: imagePath,
      rawText: recognizedText.text,
      lines: reconstructedLines.isNotEmpty
          ? reconstructedLines
          : recognizedText.text
              .split(RegExp(r'\r?\n'))
              .map((l) => l.trim())
              .where((l) => l.isNotEmpty)
              .toList(),
      timestamp: DateTime.now().toUtc(),
    );
  }

  /// Reconstructs lines spatially using bounding box coordinates.
  /// Solves the common multi-column OCR issue where item names and prices
  /// belong to separate vertical TextBlocks by grouping them horizontally.
  List<String> _reconstructLinesSpatially(List<TextLine> textLines) {
    if (textLines.isEmpty) return const [];

    final hasValidBoxes = textLines.any(
      (l) => l.boundingBox.width > 0 && l.boundingBox.height > 0,
    );

    if (!hasValidBoxes) {
      return textLines.map((l) => l.text.trim()).toList();
    }

    // Sort all lines primarily by vertical center
    final sorted = List<TextLine>.of(textLines)
      ..sort((a, b) {
        final aCenterY = a.boundingBox.top + a.boundingBox.height / 2;
        final bCenterY = b.boundingBox.top + b.boundingBox.height / 2;
        return aCenterY.compareTo(bCenterY);
      });

    // Group lines into horizontal rows where vertical overlap occurs
    final rows = <List<TextLine>>[];
    for (final line in sorted) {
      final lineBox = line.boundingBox;
      final lineCenterY = lineBox.top + lineBox.height / 2;
      final lineHeight = lineBox.height > 0 ? lineBox.height : 20.0;

      var placed = false;
      for (final row in rows) {
        final rowFirstBox = row.first.boundingBox;
        final rowCenterY = rowFirstBox.top + rowFirstBox.height / 2;
        final rowHeight = rowFirstBox.height > 0 ? rowFirstBox.height : 20.0;
        final maxH = lineHeight > rowHeight ? lineHeight : rowHeight;

        // If centers are within 65% of the line height, consider them on the same physical line
        if ((lineCenterY - rowCenterY).abs() <= maxH * 0.65) {
          row.add(line);
          placed = true;
          break;
        }
      }

      if (!placed) {
        rows.add([line]);
      }
    }

    // Sort rows from top to bottom by the row's minimum top
    rows.sort((a, b) {
      final aTop = a.map((l) => l.boundingBox.top).reduce((v, e) => v < e ? v : e);
      final bTop = b.map((l) => l.boundingBox.top).reduce((v, e) => v < e ? v : e);
      return aTop.compareTo(bTop);
    });

    // Within each row, sort segments from left to right and join with space
    final result = <String>[];
    for (final row in rows) {
      row.sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));
      final lineText = row
          .map((l) => l.text.trim())
          .where((t) => t.isNotEmpty)
          .join('   ');
      if (lineText.isNotEmpty) {
        result.add(lineText);
      }
    }

    return result;
  }

  @override
  Future<void> dispose() async {
    if (!_isDisposed) {
      _isDisposed = true;
      await _recognizer.close();
    }
  }
}
