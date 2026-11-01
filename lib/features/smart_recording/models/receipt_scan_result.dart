/// Represents the extracted text and metadata from an OCR scan of a receipt image.
class ReceiptScanResult {
  /// The local file path to the scanned receipt image.
  final String imagePath;

  /// The full raw recognized text across all blocks.
  final String rawText;

  /// List of non-empty recognized text lines in reading order.
  final List<String> lines;

  /// Timestamp when the OCR recognition occurred (UTC).
  final DateTime timestamp;

  const ReceiptScanResult({
    required this.imagePath,
    required this.rawText,
    required this.lines,
    required this.timestamp,
  });

  /// Whether the OCR process detected any readable text.
  bool get hasText => rawText.trim().isNotEmpty;

  /// Total count of recognized lines.
  int get lineCount => lines.length;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReceiptScanResult &&
          runtimeType == other.runtimeType &&
          imagePath == other.imagePath &&
          rawText == other.rawText &&
          timestamp == other.timestamp;

  @override
  int get hashCode => Object.hash(imagePath, rawText, timestamp);

  @override
  String toString() =>
      'ReceiptScanResult(path: $imagePath, lines: ${lines.length}, textLength: ${rawText.length})';
}
