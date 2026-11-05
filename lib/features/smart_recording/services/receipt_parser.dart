import '../../../core/utils/currency_formatter.dart';
import '../../notification_watcher/services/category_suggester.dart';
import '../models/parsed_receipt.dart';
import '../models/receipt_item.dart';
import '../models/receipt_scan_result.dart';

/// Service responsible for parsing raw OCR text lines from receipts
/// into structured [ParsedReceipt] instances with merchant, total, date,
/// suggested category, filtered clean lines, and itemized transaction rows.
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

  /// Parses raw text and lines into a structured [ParsedReceipt].
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
    final items = extractItems(splitLines);
    final cleanLines = extractCleanLines(splitLines, merchant, date, items, amount);

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
      items: items,
      cleanLines: cleanLines,
    );
  }

  /// Extracts the merchant or store name from the top header lines of the receipt.
  /// Rejects address lines, tax IDs, cashier details, and non-store noise.
  String? extractMerchant(List<String> lines) {
    if (lines.isEmpty) return null;

    final headerCandidates = lines.take(8).toList();

    // 1. Look for known Indonesian merchant brand keywords first
    String? legalEntityCandidate;
    for (final line in headerCandidates) {
      final clean = line.trim();

      final isLegalEntity = RegExp(
        r'^(?:PT\.?|CV\.?|UD\.?)\s+',
        caseSensitive: false,
      ).hasMatch(clean);

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

    // 2. Fall back to the first non-noise, non-summary uppercase or capitalized store line
    for (final line in headerCandidates) {
      final clean = line.trim();
      if (isNoiseLine(clean) || isSummaryLine(clean)) continue;

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
      final upper = line
          .toUpperCase()
          .replaceAll('T0TAL', 'TOTAL')
          .replaceAll('TOT4L', 'TOTAL');

      // Skip item count, quantity lines, payment amounts (tunai/cash), change (kembali), and barcodes
      if (_isIgnorableAmountLine(upper) || _isBarcodeLine(upper)) continue;

      // 1. High priority: Lines containing explicit total keywords
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
      if (upper.contains('TOTAL') ||
          upper.contains('JUMLAH') ||
          upper.contains('TAGIHAN')) {
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

  /// Extracts individual transaction items (products / services and line totals)
  /// while ignoring noise, header, address, and summary lines.
  List<ReceiptItem> extractItems(List<String> lines) {
    final items = <ReceiptItem>[];

    // Find bounding indices for item rows: after header, before total/summary
    var startIdx = 0;
    for (var i = 0; i < lines.length && i < 8; i++) {
      final upper = lines[i].trim().toUpperCase();
      if (_isSeparator(lines[i]) ||
          upper.contains('KASIR') ||
          upper.contains('CASHIER') ||
          upper.contains('TGL') ||
          upper.contains('DATE') ||
          upper.contains('NO. STRUK')) {
        startIdx = i + 1;
      }
    }

    var endIdx = lines.length;
    for (var i = lines.length - 1; i >= 0; i--) {
      final upper = lines[i].trim().toUpperCase();
      if (isSummaryLine(upper) ||
          upper.startsWith('TUNAI') ||
          upper.startsWith('CASH') ||
          upper.startsWith('KEMBALI') ||
          upper.startsWith('KEMBALIAN') ||
          upper.contains('DEBIT') ||
          upper.contains('QRIS')) {
        endIdx = i;
      }
    }

    if (startIdx >= endIdx) {
      startIdx = 0;
      endIdx = lines.length;
    }

    for (var i = startIdx; i < endIdx; i++) {
      final line = lines[i].trim();
      if (isNoiseLine(line) || isSummaryLine(line)) continue;

      // Item Pattern 1: Multi-line weighing or qty item:
      // Line i:   "APEL FUJI RRT"
      // Line i+1: "0.850 KG @ 38.000   32.300"
      if (i + 1 < endIdx) {
        final nextLine = lines[i + 1].trim();
        final qtyPriceMatch = RegExp(
          r'^(?:([\d.,]+)\s*(?:KG|PCS|X)?\s*[@xX]\s*([\d.,]+))\s+([\d.,]+)$',
          caseSensitive: false,
        ).firstMatch(nextLine);

        if (qtyPriceMatch != null) {
          final totalPrice = CurrencyFormatter.tryParse(qtyPriceMatch.group(3)!);
          if (totalPrice != null && totalPrice > 0) {
            final name = _cleanItemName(line);
            if (name.isNotEmpty && _hasAlphabeticWords(name)) {
              final qty = int.tryParse(qtyPriceMatch.group(1)!.replaceAll(RegExp(r'[^0-9]'), ''));
              final unitPrice = CurrencyFormatter.tryParse(qtyPriceMatch.group(2)!);
              items.add(ReceiptItem(
                name: name,
                quantity: qty,
                unitPrice: unitPrice,
                totalPrice: totalPrice,
              ));
              i++; // Skip the next line as it was consumed
              continue;
            }
          }
        }
      }

      // Item Pattern 2: Single line item with name and price at end
      // e.g. "CHITATO SAPI PANGGANG  11.500" or "1 KOPI KENANGAN 24.000" or "2 X ROTI 30.000"
      final itemMatch = RegExp(
        r'^(?:(\d+)(?:\s*[xX@\.]|\s+)\s*)?(.+?)\s+([\d]{1,3}(?:[.,]\d{3})*(?:[.,]\d{2})?|\d{3,})\s*$',
      ).firstMatch(line);

      if (itemMatch != null) {
        final rawQty = itemMatch.group(1);
        final rawName = itemMatch.group(2)!.trim();
        final rawPrice = itemMatch.group(3)!;

        // Verify name doesn't match noise or summary
        if (!isNoiseLine(rawName) && !isSummaryLine(rawName)) {
          final totalPrice = CurrencyFormatter.tryParse(rawPrice);
          if (totalPrice != null && totalPrice > 0 && totalPrice < 100000000) {
            final cleanName = _cleanItemName(rawName);
            if (cleanName.isNotEmpty && _hasAlphabeticWords(cleanName)) {
              final qty = rawQty != null ? int.tryParse(rawQty) : null;
              items.add(ReceiptItem(
                name: cleanName,
                quantity: qty,
                totalPrice: totalPrice,
              ));
            }
          }
        }
      }
    }

    return items;
  }

  /// Extracts cleaned transaction lines, filtering out non-transaction noise
  /// such as NPWP, store addresses, phone numbers, cashiers, and footer greetings.
  List<String> extractCleanLines(
    List<String> lines,
    String? merchant,
    DateTime? date,
    List<ReceiptItem> items,
    int? totalAmount,
  ) {
    final clean = <String>[];

    if (merchant != null && merchant.isNotEmpty) {
      clean.add('Merchant: $merchant');
    }

    if (date != null) {
      clean.add('Tanggal: ${date.day}/${date.month}/${date.year}');
    }

    if (items.isNotEmpty) {
      clean.add('--- Daftar Item ---');
      for (final item in items) {
        final qtyStr = item.quantity != null ? '${item.quantity}x ' : '';
        clean.add('$qtyStr${item.name} (${item.formattedTotalPrice})');
      }
    }

    if (totalAmount != null && totalAmount > 0) {
      clean.add('--- Total ---');
      clean.add('Total Belanja: ${CurrencyFormatter.format(totalAmount)}');
    }

    return clean;
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

    // Pattern 3: Textual month (e.g., 30-Okt-2026, 28 Oktober 2026, 15 Nov 26, 14:35)
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
  // Noise & Summary Line Classification
  // ---------------------------------------------------------------------------

  /// Determines whether a line contains non-transaction noise
  /// (store addresses, tax/NPWP, cashier/POS metadata, footer greetings, barcodes, etc.).
  bool isNoiseLine(String line) {
    final clean = line.trim();
    if (clean.isEmpty) return true;

    final upper = clean.toUpperCase();

    // 1. Separators and pure symbols
    if (_isSeparator(clean)) return true;

    // 2. Barcodes and long serial numbers (> 10 consecutive digits)
    if (_isBarcodeLine(clean)) return true;

    // 3. Store addresses
    if (_isAddressLine(upper)) return true;

    // 4. Contact, hotline, website, social media, emails
    if (_isContactOrWebLine(upper)) return true;

    // 5. Tax ID, NPWP, legal registration numbers
    if (_isTaxOrLegalId(upper)) return true;

    // 6. POS, Cashier, Terminal, Invoice/Bill metadata
    if (_isMetadataLine(upper)) return true;

    // 7. Footer greetings, return policies, Wi-Fi passwords, promotional apps
    if (_isFooterOrPolicyLine(upper)) return true;

    // 8. Payment noise (Tunai, Kembali, Card Details, Auth code)
    if (_isPaymentNoiseLine(upper)) return true;

    return false;
  }

  /// Determines whether a line represents an expense summary row
  /// (Subtotal, Total, Discount, Tax, Service charge, Rounding).
  bool isSummaryLine(String line) {
    final upper = line.trim().toUpperCase();
    return upper.contains('GRAND TOTAL') ||
        upper.contains('TOTAL BELANJA') ||
        upper.contains('TOTAL HARGA') ||
        upper.contains('TOTAL BAYAR') ||
        upper.contains('TOTAL AKHIR') ||
        upper.contains('TOTAL TAGIHAN') ||
        upper.contains('SUBTOTAL') ||
        upper.contains('SUB TOTAL') ||
        upper.contains('JUMLAH') ||
        upper.contains('TAGIHAN') ||
        upper.contains('TOTAL') ||
        upper.contains('DISKON') ||
        upper.contains('HEMAT') ||
        upper.contains('POTONGAN') ||
        upper.contains('PROMO') ||
        upper.contains('PPN') ||
        upper.contains('PAJAK') ||
        upper.contains('TAX') ||
        upper.contains('PB1') ||
        upper.contains('SERVICE CHARGE') ||
        upper.contains('PEMBULATAN') ||
        upper.contains('ROUNDING') ||
        upper.contains('ONGKIR') ||
        upper.contains('DELIVERY FEE');
  }

  static bool _isSeparator(String line) {
    return RegExp(r'^[\s\-_=\*\.\~\#\:\/\\\|]{2,}$').hasMatch(line) ||
        RegExp(r'^[\|\s]+$').hasMatch(line);
  }

  static bool _isBarcodeLine(String line) {
    final digitsOnly = line.replaceAll(RegExp(r'[\s\-]'), '');
    return RegExp(r'^\d{10,24}$').hasMatch(digitsOnly);
  }

  static bool _isAddressLine(String upper) {
    if (upper.startsWith('JL.') ||
        upper.startsWith('JL ') ||
        upper.startsWith('JLN.') ||
        upper.startsWith('JALAN') ||
        upper.startsWith('GANG') ||
        upper.startsWith('GG.')) {
      return true;
    }
    if (upper.contains('KEL.') ||
        upper.contains('KELURAHAN') ||
        upper.contains('KEC.') ||
        upper.contains('KECAMATAN') ||
        upper.startsWith('KOTA ') ||
        upper.contains('KOTA ADM') ||
        upper.contains('KAB.') ||
        upper.contains('KABUPATEN') ||
        upper.contains('PROVINSI')) {
      return true;
    }
    if (upper.contains('RUKO ') ||
        upper.contains('GEDUNG ') ||
        upper.contains('KOMPLEK ') ||
        upper.contains('LANTAI ') ||
        upper.contains('LT.') ||
        upper.contains('LG ') ||
        upper.contains('UNIT ') ||
        upper.contains('KAV.') ||
        upper.contains('KAVELING') ||
        upper.contains('RT.') ||
        upper.contains('RW.') ||
        upper.contains('RT/') ||
        upper.contains('RW/')) {
      return true;
    }
    // Location with Postal code e.g. "JAKARTA SELATAN 12340"
    if (RegExp(
      r'\b(?:JAKARTA|SURABAYA|BANDUNG|MEDAN|SEMARANG|BEKASI|TANGERANG|DEPOK|BOGOR|BALI)\b.*?\d{5}',
      caseSensitive: false,
    ).hasMatch(upper)) {
      return true;
    }
    if (upper == 'INDONESIA') return true;

    return false;
  }

  static bool _isContactOrWebLine(String upper) {
    if (upper.contains('TELP') ||
        upper.contains('TELEPON') ||
        upper.contains('PHONE') ||
        upper.contains('HOTLINE') ||
        upper.contains('CALL CENTER') ||
        upper.contains('CUSTOMER CARE') ||
        upper.contains('CS:') ||
        upper.contains('FAX') ||
        upper.contains('WA:') ||
        upper.contains('WHATSAPP') ||
        upper.contains('SMS:')) {
      return true;
    }
    if (upper.contains('WWW.') ||
        upper.contains('HTTP://') ||
        upper.contains('HTTPS://') ||
        upper.contains('.COM') ||
        upper.contains('.CO.ID') ||
        upper.contains('.NET') ||
        upper.contains('@') ||
        upper.contains('EMAIL')) {
      return true;
    }
    return false;
  }

  static bool _isTaxOrLegalId(String upper) {
    return upper.contains('NPWP') ||
        upper.contains('NPPKP') ||
        upper.contains('TAX ID') ||
        upper.contains('SIUP') ||
        upper.contains('TDP');
  }

  static bool _isMetadataLine(String upper) {
    return upper.contains('KASIR') ||
        upper.contains('CASHIER') ||
        upper.contains('OPERATOR') ||
        upper.contains('POS#') ||
        upper.contains('POS #') ||
        upper.contains('POS ') ||
        upper.contains('TERMINAL#') ||
        upper.contains('TERMINAL ') ||
        upper.contains('SHIFT') ||
        upper.contains('REG:') ||
        upper.contains('REGISTER') ||
        upper.contains('NO. STRUK') ||
        upper.contains('NO STRUK') ||
        upper.contains('TRX#') ||
        upper.contains('TRX NO') ||
        upper.contains('NO. TRX') ||
        upper.contains('INVOICE') ||
        upper.contains('INV#') ||
        upper.contains('INV:') ||
        upper.contains('RECEIPT#') ||
        upper.contains('RECEIPT ID') ||
        upper.contains('BILL NO') ||
        upper.contains('BILL#') ||
        upper.contains('ORDER NO') ||
        upper.contains('ORDER ID') ||
        upper.contains('MEJA') ||
        upper.contains('TABLE') ||
        upper.contains('DINE IN') ||
        upper.contains('TAKE AWAY') ||
        upper.contains('TAKEAWAY');
  }

  static bool _isFooterOrPolicyLine(String upper) {
    return upper.contains('TERIMA KASIH') ||
        upper.contains('THANK YOU') ||
        upper.contains('SELAMAT DATANG') ||
        upper.contains('SELAMAT MENIKMATI') ||
        upper.contains('SELAMAT BELANJA') ||
        upper.contains('BARANG YANG SUDAH DIBELI') ||
        upper.contains('TIDAK DAPAT DITUKAR') ||
        upper.contains('TIDAK BISA DITUKAR') ||
        upper.contains('DIKEMBALIKAN') ||
        upper.contains('KRITIK') ||
        upper.contains('SARAN') ||
        upper.contains('SUGGESTION') ||
        upper.contains('FEEDBACK') ||
        upper.contains('WIFI') ||
        upper.contains('PASSWORD') ||
        upper.contains('DOWNLOAD') ||
        upper.contains('PLAY STORE') ||
        upper.contains('APP STORE') ||
        upper.contains('GARANSI') ||
        upper.contains('SIMPAN STRUK') ||
        upper.contains('BUKTI TRANSAKSI') ||
        upper.contains('BUKTI PEMBAYARAN') ||
        upper.contains('SALINAN') ||
        upper.contains('STRUK INI') ||
        upper.contains('MEMBER ID') ||
        upper.contains('MEMBER CARD') ||
        upper.contains('POIN:') ||
        upper.contains('POINTS') ||
        upper.contains('LINKAJA') ||
        upper.contains('LAYANAN KONSUMEN');
  }

  static bool _isPaymentNoiseLine(String upper) {
    return upper.startsWith('TUNAI') ||
        upper.startsWith('CASH') ||
        upper.startsWith('KEMBALI') ||
        upper.startsWith('KEMBALIAN') ||
        upper.startsWith('CHANGE') ||
        upper.contains('DEBIT BCA') ||
        upper.contains('DEBIT MANDIRI') ||
        upper.contains('DEBIT BRI') ||
        upper.contains('DEBIT BNI') ||
        upper.contains('KARTU DEBIT') ||
        upper.contains('KARTU KREDIT') ||
        upper.contains('CREDIT CARD') ||
        upper.contains('CARD NO') ||
        upper.contains('CARD#') ||
        upper.contains('PAN:') ||
        upper.contains('EXP DATE') ||
        upper.contains('AUTH CODE') ||
        upper.contains('AUTH#') ||
        upper.contains('APPR CODE') ||
        upper.contains('MID:') ||
        upper.contains('TID:') ||
        upper.contains('BATCH NO') ||
        upper.contains('BATCH#') ||
        upper.contains('REF NO') ||
        upper.contains('TRACE NO') ||
        upper.contains('TOTAL ITEM') ||
        upper.contains('TOTAL QTY') ||
        upper.contains('TOTAL PCS') ||
        upper.contains('ITEM DIJUAL') ||
        upper.contains('JUMLAH BARANG');
  }

  // ---------------------------------------------------------------------------
  // Helper Methods
  // ---------------------------------------------------------------------------

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

    // Strip legal entity prefixes and suffixes
    cleaned = cleaned.replaceAll(RegExp(r'^(?:PT\.?|CV\.?|UD\.?)\s+', caseSensitive: false), '');
    cleaned = cleaned.replaceAll(RegExp(r',\s*TBK\.?$', caseSensitive: false), '');

    // Strip leading/trailing decorative symbols
    cleaned = cleaned.replaceAll(RegExp(r'^[\*\=\-\.\~#\s]+|[\*\=\-\.\~#\s]+$'), '').trim();

    // Strip trailing store number tags (e.g. #0412)
    cleaned = cleaned.replaceAll(RegExp(r'\s+#\d+.*$'), '');
    cleaned = cleaned.replaceAll(RegExp(r'[\.,;:*=\-_]+$'), '').trim();

    return cleaned.isEmpty ? 'Store' : cleaned;
  }

  String _cleanItemName(String raw) {
    var cleaned = raw.trim();
    cleaned = cleaned.replaceAll(RegExp(r'^\d+\s+'), '');
    cleaned = cleaned.replaceAll(RegExp(r'^[\*\=\-\.\~#\s\d]+[xX@\.]\s*'), '');
    cleaned = cleaned.replaceAll(RegExp(r'^[\*\=\-\.\~#\s]+|[\*\=\-\.\~#\s]+$'), '').trim();
    return cleaned;
  }

  bool _hasAlphabeticWords(String text) {
    final letters = text.replaceAll(RegExp(r'[^a-zA-Z]'), '');
    return letters.length >= 2;
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
        if (amount != null && amount > 0 && amount < 100000000) {
          return amount;
        }
      }
    }

    // 2. Look for Indonesian number formats e.g. '18.000', '125.500,00', 'Rp 45.000'
    final matches = RegExp(
      r'(?:Rp\.?|IDR)?\s*([\d]{1,3}(?:[.,]\d{3})*(?:[.,]\d{2})?|\d+)',
    ).allMatches(line);

    int? largestAmount;

    for (final match in matches) {
      final rawNum = match.group(1);
      if (rawNum != null) {
        // Skip barcode-length numbers
        if (rawNum.replaceAll(RegExp(r'[^0-9]'), '').length > 9) continue;

        final amount = CurrencyFormatter.tryParse(rawNum);
        if (amount != null && amount > 0 && amount < 100000000) {
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
