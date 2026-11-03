import '../../../core/utils/currency_formatter.dart';
import '../../notification_watcher/services/category_suggester.dart';
import '../models/parsed_receipt.dart';
import '../models/receipt_scan_result.dart';

/// Service responsible for parsing raw OCR text lines from receipts
/// into structured [ParsedReceipt] instances with merchant, total, date, and suggested category.
class ReceiptParser {
  const ReceiptParser();

  /// Parses a [ReceiptScanResult] into a [ParsedReceipt].
  ParsedReceipt parse(ReceiptScanResult scanResult) {
    return parseText(
      rawText: scanResult.rawText,
      lines: scanResult.lines,
      imagePath: scanResult.imagePath,
      fallbackDate: scanResult.timestamp,
    );
  }

  /// Parses raw text and lines directly.
  ParsedReceipt parseText({
    required String rawText,
    List<String>? lines,
    String? imagePath,
    DateTime? fallbackDate,
  }) {
    final splitLines = lines ??
        rawText
            .split(RegExp(r'\r?\n'))
            .map((l) => l.trim())
            .where((l) => l.isNotEmpty)
            .toList();

    final merchant = extractMerchant(splitLines);
    final amount = extractTotalAmount(splitLines);
    final date = extractDate(splitLines) ?? fallbackDate?.toUtc();

    // Suggest category from merchant name or entire receipt text
    final categorySuggestion = CategorySuggester.suggest(merchant) ??
        CategorySuggester.suggest(rawText);

    return ParsedReceipt(
      merchant: merchant,
      amount: amount,
      date: date,
      suggestedCategoryId: categorySuggestion?.categoryId,
      suggestedCategoryName: categorySuggestion?.categoryName,
      rawText: rawText,
      imagePath: imagePath ?? '',
      lines: splitLines,
    );
  }

  /// Extracts the merchant or store name from the top header lines of the receipt.
  String? extractMerchant(List<String> lines) {
    if (lines.isEmpty) return null;

    final headerCandidates = lines.take(8).toList();

    // 1. Look for known Indonesian merchant brand keywords first
    // Prefer store name lines over corporate legal entity lines (PT. / CV.)
    String? legalEntityCandidate;
    for (final line in headerCandidates) {
      final clean = line.trim();
      if (_isIgnorableHeader(clean)) continue;

      final isLegalEntity = RegExp(r'^(?:PT\.?|CV\.?)\s+', caseSensitive: false).hasMatch(clean);

      if (_matchesKnownBrand(clean)) {
        if (!isLegalEntity) {
          return _cleanMerchantName(clean);
        } else {
          legalEntityCandidate ??= _cleanMerchantName(clean);
        }
      }
    }

    if (legalEntityCandidate != null) {
      return legalEntityCandidate;
    }

    // 2. Fall back to the first non-ignorable uppercase or capitalized title line
    for (final line in headerCandidates) {
      final clean = line.trim();
      if (_isIgnorableHeader(clean)) continue;

      // Skip lines that are mostly numbers, dates, or symbols
      if (RegExp(r'^[\d\s.,\-/:;=]+$').hasMatch(clean)) continue;

      // Must have at least 3 alphabetic letters
      final lettersOnly = clean.replaceAll(RegExp(r'[^a-zA-Z]'), '');
      if (lettersOnly.length < 3) continue;

      return _cleanMerchantName(clean);
    }

    return null;
  }

  /// Extracts the total financial expense amount (in whole Rupiah) from the receipt lines.
  int? extractTotalAmount(List<String> lines) {
    if (lines.isEmpty) return null;

    int? candidateTotal;
    int? subtotal;

    // Scan backwards from bottom to top as totals are typically in the footer
    for (var i = lines.length - 1; i >= 0; i--) {
      final line = lines[i].trim();
      final upper = line.toUpperCase().replaceAll('T0TAL', 'TOTAL').replaceAll('TOT4L', 'TOTAL');

      // Skip item count, quantity lines, payment amounts (tunai/cash), and change (kembali)
      if (_isIgnorableAmountLine(upper)) continue;

      // 1. High priority: Lines containing 'GRAND TOTAL', 'TOTAL BELANJA', 'TOTAL HARGA', 'TOTAL BAYAR', 'TOTAL AKHIR'
      if (upper.contains('GRAND TOTAL') ||
          upper.contains('TOTAL BELANJA') ||
          upper.contains('TOTAL HARGA') ||
          upper.contains('TOTAL BAYAR') ||
          upper.contains('TOTAL AKHIR') ||
          upper.contains('TOTAL TAGIHAN')) {
        final amount = _parseAmountFromLine(line) ??
            (i + 1 < lines.length ? _parseAmountFromLine(lines[i + 1]) : null);
        if (amount != null && amount > 0) {
          return amount;
        }
      }

      // 2. Medium priority: General 'TOTAL' or 'JUMLAH'
      if (upper.contains('TOTAL') || upper.contains('JUMLAH') || upper.contains('TAGIHAN')) {
        final amount = _parseAmountFromLine(line) ??
            (i + 1 < lines.length ? _parseAmountFromLine(lines[i + 1]) : null);
        if (amount != null && amount > 0 && candidateTotal == null) {
          candidateTotal = amount;
        }
      }

      // 3. Low priority fallback: 'SUBTOTAL' or 'SUB TOTAL'
      if (upper.contains('SUBTOTAL') || upper.contains('SUB TOTAL')) {
        final amount = _parseAmountFromLine(line);
        if (amount != null && amount > 0 && subtotal == null) {
          subtotal = amount;
        }
      }
    }

    return candidateTotal ?? subtotal;
  }

  /// Extracts the transaction date and optional time from the receipt lines.
  DateTime? extractDate(List<String> lines) {
    if (lines.isEmpty) return null;

    // Pattern 1: DD/MM/YYYY or DD-MM-YYYY or DD.MM.YYYY
    final dmyPattern = RegExp(
      r'\b(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{2,4})(?:\s+(\d{1,2})[:\.](\d{2})(?:[:\.](\d{2}))?)?',
    );

    // Pattern 2: YYYY-MM-DD or YYYY/MM/DD
    final ymdPattern = RegExp(
      r'\b(\d{4})[\/\-](\d{1,2})[\/\-](\d{1,2})(?:\s+(\d{1,2})[:\.](\d{2})(?:[:\.](\d{2}))?)?',
    );

    // Pattern 3: Textual month (e.g., 30-Okt-2026, 28 Oktober 2026, 15 Nov 26, 28 Oktober 2026, 14:35)
    final textMonthPattern = RegExp(
      r'\b(\d{1,2})[\s\/\-]+([a-zA-Z]{3,9})[\s\/\-]+(\d{2,4})(?:[\s,]+(\d{1,2})[:\.](\d{2}))?',
      caseSensitive: false,
    );

    for (final line in lines) {
      // Try Textual month pattern first
      final textMatch = textMonthPattern.firstMatch(line);
      if (textMatch != null) {
        final day = int.tryParse(textMatch.group(1)!);
        final monthStr = textMatch.group(2)!.toLowerCase();
        final rawYear = int.tryParse(textMatch.group(3)!);
        final hour = int.tryParse(textMatch.group(4) ?? '0') ?? 0;
        final minute = int.tryParse(textMatch.group(5) ?? '0') ?? 0;

        final month = _parseMonthName(monthStr);
        if (day != null && month != null && rawYear != null) {
          final year = rawYear < 100 ? 2000 + rawYear : rawYear;
          if (_isValidDate(year, month, day)) {
            return DateTime.utc(year, month, day, hour, minute);
          }
        }
      }

      // Try YYYY-MM-DD pattern
      final ymdMatch = ymdPattern.firstMatch(line);
      if (ymdMatch != null) {
        final year = int.tryParse(ymdMatch.group(1)!);
        final month = int.tryParse(ymdMatch.group(2)!);
        final day = int.tryParse(ymdMatch.group(3)!);
        final hour = int.tryParse(ymdMatch.group(4) ?? '0') ?? 0;
        final minute = int.tryParse(ymdMatch.group(5) ?? '0') ?? 0;

        if (year != null && month != null && day != null) {
          if (_isValidDate(year, month, day)) {
            return DateTime.utc(year, month, day, hour, minute);
          }
        }
      }

      // Try DD/MM/YYYY pattern
      final dmyMatch = dmyPattern.firstMatch(line);
      if (dmyMatch != null) {
        final day = int.tryParse(dmyMatch.group(1)!);
        final month = int.tryParse(dmyMatch.group(2)!);
        final rawYear = int.tryParse(dmyMatch.group(3)!);
        final hour = int.tryParse(dmyMatch.group(4) ?? '0') ?? 0;
        final minute = int.tryParse(dmyMatch.group(5) ?? '0') ?? 0;

        if (day != null && month != null && rawYear != null) {
          final year = rawYear < 100 ? 2000 + rawYear : rawYear;
          if (_isValidDate(year, month, day)) {
            return DateTime.utc(year, month, day, hour, minute);
          }
        }
      }
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // Helper Methods
  // ---------------------------------------------------------------------------

  bool _isIgnorableHeader(String line) {
    final upper = line.toUpperCase();
    return upper.startsWith('SELAMAT DATANG') ||
        upper.startsWith('TERIMA KASIH') ||
        upper.startsWith('THANK YOU') ||
        upper.startsWith('STRUK') ||
        upper.startsWith('BUKTI') ||
        upper.startsWith('FAKTUR') ||
        upper.startsWith('TAX INVOICE') ||
        upper.startsWith('SALINAN') ||
        upper.startsWith('TELP') ||
        upper.startsWith('FAX') ||
        upper.startsWith('NPWP') ||
        upper.startsWith('JL.') ||
        upper.startsWith('JALAN') ||
        upper.startsWith('ORDER NO') ||
        upper.startsWith('MEJA') ||
        upper.startsWith('TABLE') ||
        upper.startsWith('CASHIER') ||
        upper.startsWith('KASIR');
  }

  bool _matchesKnownBrand(String line) {
    final lower = line.toLowerCase();
    const knownBrands = [
      'indomaret',
      'alfamart',
      'alfamidi',
      'superindo',
      'super indo',
      'hypermart',
      'carrefour',
      'transmart',
      'watsons',
      'guardian',
      'kopi kenangan',
      'janji jiwa',
      'starbucks',
      'point coffee',
      'fore coffee',
      'tuku',
      'mcdonald',
      'kfc',
      'hokben',
      'solaria',
      'burger king',
      'pizza hut',
      'pertamina',
      'shell',
      'gramedia',
      'mixue',
      'lawson',
      'kartika sari',
      'kimia farma',
      'k-24',
      'k24',
      'apotek',
      'ace hardware',
      'mr diy',
      'mr. diy',
      'ikea',
      'jco',
      'chatime',
      'dunkin',
      'bakmi gm',
      'sederhana',
      'padang',
      'sushi tei',
      'marugame',
      'yoshinoya',
      'a&w',
    ];

    for (final brand in knownBrands) {
      if (lower.contains(brand)) return true;
    }
    return false;
  }

  String _cleanMerchantName(String raw) {
    var cleaned = raw.trim();

    // Strip legal entity prefixes if desired, or keep clean store title
    cleaned = cleaned.replaceAll(RegExp(r'^PT\.?\s+', caseSensitive: false), '');
    cleaned = cleaned.replaceAll(RegExp(r'^CV\.?\s+', caseSensitive: false), '');
    cleaned = cleaned.replaceAll(RegExp(r',\s*TBK\.?$', caseSensitive: false), '');

    // Strip leading/trailing decorative symbols (e.g., ***, ===, ---, ~~~)
    cleaned = cleaned.replaceAll(RegExp(r'^[\*\=\-\.\~#\s]+|[\*\=\-\.\~#\s]+$'), '').trim();

    // Strip trailing symbols or store numbers if formatted as '#1234'
    cleaned = cleaned.replaceAll(RegExp(r'\s+#\d+.*$'), '');
    cleaned = cleaned.replaceAll(RegExp(r'[\.,;:*=\-_]+$'), '').trim();

    return cleaned.isEmpty ? 'Store' : cleaned;
  }

  bool _isIgnorableAmountLine(String upper) {
    if (upper.contains('TOTAL BAYAR') ||
        upper.contains('TOTAL BELANJA') ||
        upper.contains('GRAND TOTAL') ||
        upper.contains('TOTAL AKHIR') ||
        upper.contains('TOTAL HARGA') ||
        upper.contains('TOTAL TAGIHAN')) {
      return false;
    }
    return upper.contains('TOTAL ITEM') ||
        upper.contains('TOTAL QTY') ||
        upper.contains('TOTAL PCS') ||
        upper.startsWith('TUNAI') ||
        upper.startsWith('CASH') ||
        upper.startsWith('KEMBALI') ||
        upper.startsWith('KEMBALIAN') ||
        upper.startsWith('CHANGE') ||
        upper.startsWith('DISKON') ||
        upper.startsWith('HEMAT') ||
        upper.startsWith('POTONGAN');
  }

  int? _parseAmountFromLine(String line) {
    // 1. Try to find the amount directly following total/tagihan/jumlah keyword
    final keywordPattern = RegExp(
      r'(?:TOTAL|T0TAL|TOT4L|JUMLAH|TAGIHAN|SUBTOTAL|GRAND\s*TOTAL)(?:\s+(?:BAYAR|BELANJA|HARGA|AKHIR|TAGIHAN|NETTO))?\s*[:=]?\s*(?:Rp\.?|IDR)?\s*([\d]{1,3}(?:[.,]\d{3})*(?:[.,]\d{2})?|\d+)',
      caseSensitive: false,
    );
    final kwMatch = keywordPattern.firstMatch(line);
    if (kwMatch != null) {
      final rawNum = kwMatch.group(1);
      if (rawNum != null) {
        final amount = CurrencyFormatter.tryParse(rawNum);
        if (amount != null && amount > 0) {
          return amount;
        }
      }
    }

    // 2. Look for Indonesian number formats e.g. '18.000', '125.500,00', 'Rp 45.000'
    final matches = RegExp(r'(?:Rp\.?|IDR)?\s*([\d]{1,3}(?:[.,]\d{3})*(?:[.,]\d{2})?|\d+)')
        .allMatches(line);

    int? largestAmount;

    for (final match in matches) {
      final rawNum = match.group(1);
      if (rawNum != null) {
        final amount = CurrencyFormatter.tryParse(rawNum);
        if (amount != null && amount > 0) {
          // Track highest valid amount found on the line
          if (largestAmount == null || amount > largestAmount) {
            largestAmount = amount;
          }
        }
      }
    }

    return largestAmount;
  }

  int? _parseMonthName(String text) {
    final lower = text.toLowerCase();
    if (lower.startsWith('jan')) return 1;
    if (lower.startsWith('feb')) return 2;
    if (lower.startsWith('mar')) return 3;
    if (lower.startsWith('apr')) return 4;
    if (lower.startsWith('mei') || lower.startsWith('may')) return 5;
    if (lower.startsWith('jun')) return 6;
    if (lower.startsWith('jul')) return 7;
    if (lower.startsWith('agu') || lower.startsWith('ags') || lower.startsWith('aug')) return 8;
    if (lower.startsWith('sep')) return 9;
    if (lower.startsWith('okt') || lower.startsWith('oct')) return 10;
    if (lower.startsWith('nop') || lower.startsWith('nov')) return 11;
    if (lower.startsWith('des') || lower.startsWith('dec')) return 12;
    return null;
  }

  bool _isValidDate(int year, int month, int day) {
    if (year < 2000 || year > 2099) return false;
    if (month < 1 || month > 12) return false;
    if (day < 1 || day > 31) return false;
    return true;
  }
}
