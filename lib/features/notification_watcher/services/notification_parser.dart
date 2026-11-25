import '../../../core/utils/currency_formatter.dart';
import '../constants/watched_apps.dart';
import '../models/notification_parser_rule.dart';
import '../models/parsed_notification.dart';
import 'category_suggester.dart';

/// Service responsible for parsing incoming Android notifications from Indonesian
/// banks and e-wallets into structured [ParsedNotification] objects.
class NotificationParser {
  const NotificationParser();

  /// Registry of parser rules for supported Indonesian financial institutions.
  static final List<NotificationParserRule> rules = [
    // 1. BCA (BCA Mobile, myBCA, Blu) - Merchant first
    NotificationParserRule(
      source: 'BCA',
      packageNames: WatchedApps.bca.packageNames,
      regex: RegExp(
        r'(?:Pembelian|Pembayaran(?:\s+QRIS)?|Transaksi(?:\s+debit)?)\s+(?:di|ke)\s+(.+?)\s+(?:sebesar\s+)?(?:Rp\.?|IDR)\s*([\d.,]+)',
        caseSensitive: false,
      ),
      merchantGroupIndex: 1,
      amountGroupIndex: 2,
    ),
    // 1b. BCA - Amount first
    NotificationParserRule(
      source: 'BCA',
      packageNames: WatchedApps.bca.packageNames,
      regex: RegExp(
        r'(?:Pembelian|Pembayaran(?:\s+QRIS)?|Transaksi(?:\s+debit)?|Transfer\s+keluar).*?(?:sebesar\s+)?(?:Rp\.?|IDR)\s*([\d.,]+)\s+(?:di|ke)\s+(.+?)(?:\s+(?:berhasil|sukses)|\s*\.$|$)',
        caseSensitive: false,
      ),
      amountGroupIndex: 1,
      merchantGroupIndex: 2,
    ),

    // 2. Mandiri (Livin') - Amount first
    NotificationParserRule(
      source: 'Mandiri',
      packageNames: WatchedApps.mandiri.packageNames,
      regex: RegExp(
        r'(?:Transaksi\s+debit|Pembayaran(?:\s+QRIS)?|Transfer\s+keluar|Pembelian)\s+(?:sebesar\s+)?(?:Rp\.?|IDR)\s*([\d.,]+)\s+(?:di|ke)\s+(.+?)(?:\s+(?:telah\s+)?(?:berhasil|sukses)|\s*\.$|$)',
        caseSensitive: false,
      ),
      amountGroupIndex: 1,
      merchantGroupIndex: 2,
    ),
    // 2b. Mandiri (Livin') - Merchant first
    NotificationParserRule(
      source: 'Mandiri',
      packageNames: WatchedApps.mandiri.packageNames,
      regex: RegExp(
        r'(?:Transaksi\s+debit|Pembayaran(?:\s+QRIS)?|Transfer\s+keluar|Pembelian).*?\s+(?:di|ke)\s+(.+?)\s+(?:sebesar\s+)?(?:Rp\.?|IDR)\s*([\d.,]+)',
        caseSensitive: false,
      ),
      merchantGroupIndex: 1,
      amountGroupIndex: 2,
    ),

    // 3. BNI (Mobile / wondr) - Amount first
    NotificationParserRule(
      source: 'BNI',
      packageNames: WatchedApps.bni.packageNames,
      regex: RegExp(
        r'(?:Transaksi(?:\s+QRIS)?|Pembelian|Transfer\s+keluar|Pembayaran)\s+(?:sebesar\s+)?(?:Rp\.?|IDR)\s*([\d.,]+)\s+(?:di|ke)\s+(.+?)(?:\s+pada|\s+(?:telah\s+)?(?:berhasil|sukses)|\s*\.$|$)',
        caseSensitive: false,
      ),
      amountGroupIndex: 1,
      merchantGroupIndex: 2,
    ),
    // 3b. BNI (Mobile / wondr) - Merchant first
    NotificationParserRule(
      source: 'BNI',
      packageNames: WatchedApps.bni.packageNames,
      regex: RegExp(
        r'(?:Transaksi(?:\s+QRIS)?|Pembelian|Transfer\s+keluar|Pembayaran).*?\s+(?:di|ke)\s+(.+?)\s+(?:sebesar\s+)?(?:Rp\.?|IDR)\s*([\d.,]+)',
        caseSensitive: false,
      ),
      merchantGroupIndex: 1,
      amountGroupIndex: 2,
    ),

    // 4. BRI (BRImo) - Amount first
    NotificationParserRule(
      source: 'BRI',
      packageNames: WatchedApps.bri.packageNames,
      regex: RegExp(
        r'(?:Transaksi(?:\s+QRIS)?|Debit|Pembayaran|Pembelian|Transfer\s+keluar)\s+(?:sebesar\s+)?(?:Rp\.?|IDR)\s*([\d.,]+)\s+(?:di|ke)\s+(.+?)(?:\s+(?:berhasil|sukses)|\s*\.$|$)',
        caseSensitive: false,
      ),
      amountGroupIndex: 1,
      merchantGroupIndex: 2,
    ),
    // 4b. BRI (BRImo) - Merchant first
    NotificationParserRule(
      source: 'BRI',
      packageNames: WatchedApps.bri.packageNames,
      regex: RegExp(
        r'(?:Transaksi(?:\s+QRIS)?|Debit|Pembayaran|Pembelian|Transfer\s+keluar).*?\s+(?:di|ke)\s+(.+?)\s+(?:sebesar\s+)?(?:Rp\.?|IDR)\s*([\d.,]+)',
        caseSensitive: false,
      ),
      merchantGroupIndex: 1,
      amountGroupIndex: 2,
    ),

    // 5. BTN Mobile
    NotificationParserRule(
      source: 'BTN',
      packageNames: WatchedApps.btn.packageNames,
      regex: RegExp(
        r'(?:Transaksi(?:\s+QRIS)?|Debit(?:\s+rek\s+\d+)?|Pembayaran|Pembelian|Transfer\s+keluar)\s+(?:sebesar\s+)?(?:Rp\.?|IDR)\s*([\d.,]+)\s+(?:di|ke)\s+(.+?)(?:\s+(?:berhasil|sukses)|\s+tgl|\s*\.$|$)',
        caseSensitive: false,
      ),
      amountGroupIndex: 1,
      merchantGroupIndex: 2,
    ),

    // 6. Bank Jago
    NotificationParserRule(
      source: 'Bank Jago',
      packageNames: WatchedApps.jago.packageNames,
      regex: RegExp(
        r'(?:Kamu\s+(?:telah\s+)?(?:membayar|bayar)|Pembayaran(?:\s+QRIS)?|Transaksi\s+keluar).*?(?:sebesar\s+)?(?:Rp\.?|IDR)\s*([\d.,]+)\s+(?:ke|di)\s+(.+?)(?:\s+(?:berhasil|sukses)|\s*\.$|$)',
        caseSensitive: false,
      ),
      amountGroupIndex: 1,
      merchantGroupIndex: 2,
    ),
    NotificationParserRule(
      source: 'Bank Jago',
      packageNames: WatchedApps.jago.packageNames,
      regex: RegExp(
        r'(?:Kamu\s+(?:telah\s+)?(?:membayar|bayar)|Pembayaran(?:\s+QRIS)?|Transaksi\s+keluar).*?\s+(?:ke|di)\s+(.+?)\s+(?:sebesar\s+)?(?:Rp\.?|IDR)\s*([\d.,]+)',
        caseSensitive: false,
      ),
      merchantGroupIndex: 1,
      amountGroupIndex: 2,
    ),

    // 7. SeaBank
    NotificationParserRule(
      source: 'SeaBank',
      packageNames: WatchedApps.seaBank.packageNames,
      regex: RegExp(
        r'(?:Pembayaran(?:\s+QRIS)?|Transfer\s+keluar|Transaksi)\s+(?:sebesar\s+)?(?:Rp\.?|IDR)\s*([\d.,]+)\s+(?:ke|di)\s+(.+?)(?:\s+(?:telah\s+)?(?:berhasil|sukses)|\s*\.$|$)',
        caseSensitive: false,
      ),
      amountGroupIndex: 1,
      merchantGroupIndex: 2,
    ),

    // 8. ShopeePay - Amount first
    NotificationParserRule(
      source: 'ShopeePay',
      packageNames: WatchedApps.shopeePay.packageNames,
      regex: RegExp(
        r'(?:Pembayaran(?:\s+QRIS)?(?:\s+sebesar)?|Kamu\s+berhasil\s+membayar|Transaksi\s+berhasil).*?(?:Rp\.?|IDR)\s*([\d.,]+)\s+(?:di|ke)\s+(.+?)(?:\s+menggunakan|\s+berhasil|!|\s*\.$|$)',
        caseSensitive: false,
      ),
      amountGroupIndex: 1,
      merchantGroupIndex: 2,
    ),
    // 8b. ShopeePay - Merchant first
    NotificationParserRule(
      source: 'ShopeePay',
      packageNames: WatchedApps.shopeePay.packageNames,
      regex: RegExp(
        r'(?:Pembayaran(?:\s+QRIS)?(?:\s+sebesar)?|Kamu\s+berhasil\s+membayar|Transaksi\s+berhasil).*?\s+(?:di|ke)\s+(.+?)\s+(?:sebesar\s+)?(?:Rp\.?|IDR)\s*([\d.,]+)',
        caseSensitive: false,
      ),
      merchantGroupIndex: 1,
      amountGroupIndex: 2,
    ),

    // 9. GoPay (Gojek / standalone GoPay) - Amount first
    NotificationParserRule(
      source: 'GoPay',
      packageNames: WatchedApps.goPay.packageNames,
      regex: RegExp(
        r'(?:Kamu\s+(?:berhasil\s+bayar|telah\s+membayar|bayar)|Pembayaran(?:\s+QRIS)?(?:\s+sebesar)?).*?(?:Rp\.?|IDR)\s*([\d.,]+)\s+(?:ke|di)\s+(.+?)(?:\s+pakai|\s+berhasil|\s*\.$|$)',
        caseSensitive: false,
      ),
      amountGroupIndex: 1,
      merchantGroupIndex: 2,
    ),
    // 9b. GoPay - Merchant first
    NotificationParserRule(
      source: 'GoPay',
      packageNames: WatchedApps.goPay.packageNames,
      regex: RegExp(
        r'(?:Kamu\s+(?:berhasil\s+bayar|telah\s+membayar|bayar)|Pembayaran(?:\s+QRIS)?(?:\s+sebesar)?).*?\s+(?:ke|di)\s+(.+?)\s+(?:sebesar\s+)?(?:Rp\.?|IDR)\s*([\d.,]+)',
        caseSensitive: false,
      ),
      merchantGroupIndex: 1,
      amountGroupIndex: 2,
    ),

    // 10. OVO - Amount first
    NotificationParserRule(
      source: 'OVO',
      packageNames: WatchedApps.ovo.packageNames,
      regex: RegExp(
        r'(?:Transaksi\s+berhasil!\s+)?(?:Pembayaran(?:\s+sebesar)?|Berhasil\s+bayar).*?(?:Rp\.?|IDR)\s*([\d.,]+)\s+(?:di|ke)\s+(.+?)(?:\s+berhasil|\s*\.$|$)',
        caseSensitive: false,
      ),
      amountGroupIndex: 1,
      merchantGroupIndex: 2,
    ),
    // 10b. OVO - Merchant first
    NotificationParserRule(
      source: 'OVO',
      packageNames: WatchedApps.ovo.packageNames,
      regex: RegExp(
        r'(?:Transaksi\s+berhasil!\s+)?(?:Pembayaran(?:\s+sebesar)?|Berhasil\s+bayar).*?\s+(?:di|ke)\s+(.+?)\s+(?:sebesar\s+)?(?:Rp\.?|IDR)\s*([\d.,]+)',
        caseSensitive: false,
      ),
      merchantGroupIndex: 1,
      amountGroupIndex: 2,
    ),

    // 11. DANA - Amount first
    NotificationParserRule(
      source: 'DANA',
      packageNames: WatchedApps.dana.packageNames,
      regex: RegExp(
        r'(?:Pembayaran\s+berhasil!\s+Kamu\s+telah\s+bayar|Bayar|Pembayaran).*?(?:Rp\.?|IDR)\s*([\d.,]+)\s+(?:ke|di)\s+(.+?)(?:\s+berhasil|\s*\.$|$)',
        caseSensitive: false,
      ),
      amountGroupIndex: 1,
      merchantGroupIndex: 2,
    ),
    // 11b. DANA - Merchant first
    NotificationParserRule(
      source: 'DANA',
      packageNames: WatchedApps.dana.packageNames,
      regex: RegExp(
        r'(?:Pembayaran\s+berhasil!\s+Kamu\s+telah\s+bayar|Bayar|Pembayaran).*?\s+(?:ke|di)\s+(.+?)\s+(?:sebesar\s+)?(?:Rp\.?|IDR)\s*([\d.,]+)',
        caseSensitive: false,
      ),
      merchantGroupIndex: 1,
      amountGroupIndex: 2,
    ),

    // 12. Flip
    NotificationParserRule(
      source: 'Flip',
      packageNames: WatchedApps.flip.packageNames,
      regex: RegExp(
        r'(?:Transaksi\s+transfer|Kirim\s+uang|Transfer)\s+(?:sebesar\s+)?(?:Rp\.?|IDR)\s*([\d.,]+)\s+(?:ke|di)\s+(.+?)(?:\s+berhasil|\s*\.$|$)',
        caseSensitive: false,
      ),
      amountGroupIndex: 1,
      merchantGroupIndex: 2,
    ),
  ];

  /// Fallback regex patterns for generic or updated banking notifications.
  static final List<NotificationParserRule> fallbackRules = [
    NotificationParserRule(
      source: 'Bank / E-Wallet',
      packageNames: const [],
      regex: RegExp(
        r'(?:pembayaran|transaksi|debit|transfer|bayar|beli|pembelian).*?(?:sebesar\s+)?(?:rp\.?|idr)\s*([\d.,]+)\s*(?:ke|di|pada|untuk)\s+(.+?)(?:\s+pada|\s+berhasil|\s+sukses|\.|\!|$)',
        caseSensitive: false,
      ),
      amountGroupIndex: 1,
      merchantGroupIndex: 2,
    ),
    NotificationParserRule(
      source: 'Bank / E-Wallet',
      packageNames: const [],
      regex: RegExp(
        r'(?:pembayaran|transaksi|debit|transfer|bayar|beli|pembelian).*?\s+(?:ke|di|pada|untuk)\s+(.+?)\s+(?:sebesar\s+)?(?:rp\.?|idr)\s*([\d.,]+)',
        caseSensitive: false,
      ),
      merchantGroupIndex: 1,
      amountGroupIndex: 2,
    ),
    NotificationParserRule(
      source: 'Bank / E-Wallet',
      packageNames: const [],
      regex: RegExp(
        r'(?:kamu\s+telah\s+berhasil|berhasil|sukses).*?(?:rp\.?|idr)\s*([\d.,]+).*?(?:di|ke)\s+(.+?)(?:\.|\!|$)',
        caseSensitive: false,
      ),
      amountGroupIndex: 1,
      merchantGroupIndex: 2,
    ),
    NotificationParserRule(
      source: 'Bank / E-Wallet',
      packageNames: const [],
      regex: RegExp(
        r'(?:kamu\s+telah\s+berhasil|berhasil|sukses).*?(?:di|ke)\s+(.+?).*?(?:rp\.?|idr)\s*([\d.,]+)',
        caseSensitive: false,
      ),
      merchantGroupIndex: 1,
      amountGroupIndex: 2,
    ),
  ];

  /// Parses a notification body with an optional package name, title, and timestamp.
  ///
  /// Returns a valid [ParsedNotification] if a rule matches and amounts are valid,
  /// or `null` if the notification does not represent a supported expense transaction.
  ParsedNotification? parse({
    required String body,
    String? title,
    String? appPackage,
    DateTime? timestamp,
  }) {
    final cleanBody = _normalizeText(body);
    if (cleanBody.isEmpty) return null;

    final cleanTitle = title != null ? _normalizeText(title) : '';
    final combinedText = cleanTitle.isNotEmpty ? '$cleanTitle $cleanBody' : cleanBody;
    final now = timestamp ?? DateTime.now();

    // 1. If package name is known, prioritize rules belonging to that package.
    if (appPackage != null && appPackage.isNotEmpty) {
      final matchingPackageRules = rules.where((r) => r.matchesPackage(appPackage)).toList();

      for (final rule in matchingPackageRules) {
        final result = _tryMatchRule(rule, cleanBody, combinedText, appPackage, now);
        if (result != null) return result;
      }
    }

    // 2. Try all primary institution rules (handles cross-app testing or unlisted variants).
    for (final rule in rules) {
      final result = _tryMatchRule(rule, cleanBody, combinedText, appPackage, now);
      if (result != null) return result;
    }

    // 3. Fallback generic rules.
    final institutionSource = WatchedApps.findByPackage(appPackage)?.name;
    for (final rule in fallbackRules) {
      final customRule = institutionSource != null
          ? NotificationParserRule(
              source: institutionSource,
              packageNames: rule.packageNames,
              regex: rule.regex,
              amountGroupIndex: rule.amountGroupIndex,
              merchantGroupIndex: rule.merchantGroupIndex,
              defaultType: rule.defaultType,
            )
          : rule;

      final result = _tryMatchRule(customRule, cleanBody, combinedText, appPackage, now);
      if (result != null) return result;
    }

    return null;
  }

  /// Convenience signature matching the specification plan:
  /// `ParsedNotification? parseNotification(String body, String appPackage)`.
  ParsedNotification? parseNotification(String body, String appPackage) {
    return parse(body: body, appPackage: appPackage);
  }

  ParsedNotification? _tryMatchRule(
    NotificationParserRule rule,
    String body,
    String combinedText,
    String? appPackage,
    DateTime timestamp,
  ) {
    // Try matching body first, then combined text
    var match = rule.regex.firstMatch(body);
    var matchedText = body;

    if (match == null && combinedText != body) {
      match = rule.regex.firstMatch(combinedText);
      matchedText = combinedText;
    }

    if (match == null) return null;

    final rawMerchant = match.group(rule.merchantGroupIndex);
    final rawAmount = match.group(rule.amountGroupIndex);

    if (rawAmount == null || rawMerchant == null) return null;

    final amount = CurrencyFormatter.tryParse(rawAmount);
    if (amount == null || amount <= 0) return null;

    final cleanedMerchant = _cleanMerchant(rawMerchant);
    final suggestion = CategorySuggester.suggest(cleanedMerchant) ??
        CategorySuggester.suggest(matchedText);

    return ParsedNotification(
      amount: amount,
      merchant: cleanedMerchant,
      type: rule.defaultType,
      source: rule.source,
      suggestedCategoryId: suggestion?.categoryId,
      suggestedCategoryName: suggestion?.categoryName,
      rawText: matchedText,
      appPackage: appPackage,
      timestamp: timestamp,
    );
  }

  String _cleanMerchant(String raw) {
    var cleaned = raw.trim();

    // Strip trailing status words: sukses, berhasil, selesai
    cleaned = cleaned.replaceAll(
      RegExp(r'\s+(?:telah\s+)?(?:berhasil|sukses|selesai)[.!]?$', caseSensitive: false),
      '',
    ).trim();

    // Strip trailing punctuation: ., ! ; : -
    cleaned = cleaned.replaceAll(RegExp(r'[\.,!;:\-]+$'), '').trim();

    // Strip trailing account identifiers like 'di rek *1234' or 'rek *1234'
    cleaned = cleaned.replaceAll(RegExp(r'\s+(?:di\s+)?rek(?:\.|\s+)\*?\d+.*$', caseSensitive: false), '').trim();

    // Strip trailing time/date remnants like 'pada 03/10/2026'
    cleaned = cleaned.replaceAll(RegExp(r'\s+pada\s+\d{1,2}[/-]\d{1,2}[/-]\d{2,4}.*$', caseSensitive: false), '').trim();

    // Strip trailing payment methods like 'pakai GoPay', 'menggunakan ShopeePay', 'dengan OVO'
    cleaned = cleaned.replaceAll(RegExp(r'\s+(?:pakai|menggunakan|dengan|melalui)\s+.*$', caseSensitive: false), '').trim();

    return cleaned.isEmpty ? 'Unknown' : cleaned;
  }

  String _normalizeText(String input) {
    return input.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
