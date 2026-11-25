import 'package:budget_tracker/core/constants/default_categories.dart';
import 'package:budget_tracker/features/smart_recording/services/receipt_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = ReceiptParser();

  group('ReceiptParser Noise Filtering & Line Item Extraction Tests', () {
    test('isNoiseLine correctly detects all categories of non-transaction noise', () {
      // 1. Separators & pure symbols
      expect(parser.isNoiseLine('================================'), isTrue);
      expect(parser.isNoiseLine('--------------------------------'), isTrue);
      expect(parser.isNoiseLine('********************************'), isTrue);
      expect(parser.isNoiseLine('||||| |||| || ||||||||||||||||||'), isTrue);

      // 2. Barcodes
      expect(parser.isNoiseLine('8992761001239'), isTrue);
      expect(parser.isNoiseLine('081234567890123'), isTrue);

      // 3. Addresses
      expect(parser.isNoiseLine('JL. JENDERAL SUDIRMAN KAV 52-53'), isTrue);
      expect(parser.isNoiseLine('JALAN RS FATMAWATI NO. 12'), isTrue);
      expect(parser.isNoiseLine('RUKO MALL OF INDONESIA BLOK A NO. 12'), isTrue);
      expect(parser.isNoiseLine('MALL KELAPA GADING LT. 2 UNIT 105'), isTrue);
      expect(parser.isNoiseLine('KEL. KEBAYORAN LAMA, KEC. KEBAYORAN BARU'), isTrue);
      expect(parser.isNoiseLine('JAKARTA SELATAN 12340'), isTrue);
      expect(parser.isNoiseLine('INDONESIA'), isTrue);

      // 4. Contact & Website
      expect(parser.isNoiseLine('TELP: 021-7192837'), isTrue);
      expect(parser.isNoiseLine('PHONE: (021) 5678900'), isTrue);
      expect(parser.isNoiseLine('CALL CENTER 1500280'), isTrue);
      expect(parser.isNoiseLine('WA: 0812-3456-7890'), isTrue);
      expect(parser.isNoiseLine('WWW.INDOMARET.CO.ID'), isTrue);
      expect(parser.isNoiseLine('EMAIL: CS@ALFAMART.CO.ID'), isTrue);

      // 5. Tax & Legal IDs
      expect(parser.isNoiseLine('NPWP: 01.336.238.9-054.000'), isTrue);
      expect(parser.isNoiseLine('NPPKP: 01.336.238.9-054.000'), isTrue);
      expect(parser.isNoiseLine('TAX ID: 99128374'), isTrue);

      // 6. POS / Cashier / Metadata
      expect(parser.isNoiseLine('KASIR: RINI / POS 03'), isTrue);
      expect(parser.isNoiseLine('CASHIER: BUDI SANTOSO'), isTrue);
      expect(parser.isNoiseLine('OPERATOR: ANDI (SHIFT 1)'), isTrue);
      expect(parser.isNoiseLine('TERMINAL# 002'), isTrue);
      expect(parser.isNoiseLine('TRX NO: 20261105-0042'), isTrue);
      expect(parser.isNoiseLine('INVOICE NO: INV/2026/XI/05'), isTrue);
      expect(parser.isNoiseLine('NO. STRUK: 102938'), isTrue);
      expect(parser.isNoiseLine('TABLE 14 / DINE IN'), isTrue);

      // 7. Footer / Policy / Wi-Fi
      expect(parser.isNoiseLine('TERIMA KASIH TELAH BERBELANJA'), isTrue);
      expect(parser.isNoiseLine('THANK YOU FOR YOUR VISIT'), isTrue);
      expect(parser.isNoiseLine('SELAMAT DATANG'), isTrue);
      expect(parser.isNoiseLine('SELAMAT MENIKMATI'), isTrue);
      expect(parser.isNoiseLine('BARANG YANG SUDAH DIBELI TIDAK DAPAT DITUKAR'), isTrue);
      expect(parser.isNoiseLine('KRITIK & SARAN: SMS 0811-123456'), isTrue);
      expect(parser.isNoiseLine('WIFI: KOPI_FREE / PASSWORD: KOPI123'), isTrue);
      expect(parser.isNoiseLine('DOWNLOAD APLIKASI KAMI DI PLAY STORE'), isTrue);

      // 8. Payment & Change
      expect(parser.isNoiseLine('TUNAI: 100.000'), isTrue);
      expect(parser.isNoiseLine('CASH: 50.000'), isTrue);
      expect(parser.isNoiseLine('KEMBALI: 52.500'), isTrue);
      expect(parser.isNoiseLine('KEMBALIAN: 2.500'), isTrue);
      expect(parser.isNoiseLine('DEBIT BCA: ************1234'), isTrue);
      expect(parser.isNoiseLine('AUTH CODE: 981240'), isTrue);
      expect(parser.isNoiseLine('TOTAL ITEM: 4'), isTrue);

      // Non-noise item lines should NOT be marked as noise
      expect(parser.isNoiseLine('ULTRA MILK COKLAT 250ML 7.500'), isFalse);
      expect(parser.isNoiseLine('CHITATO SAPI PANGGANG 11.500'), isFalse);
      expect(parser.isNoiseLine('KOPI KENANGAN MANTAN 24.000'), isFalse);
    });

    test('extracts itemized products and prices from authentic noisy supermarket receipt', () {
      const noisyReceipt = '''
PT. SUMBER ALFARIA TRIJAYA, TBK
ALFAMART FATMAWATI 2
JL. RS FATMAWATI NO. 12
NPWP: 01.336.238.9-054.000
TELP: 021-7192837
================================
TGL: 05/11/2026 14:30   POS# 01
KASIR: RINI SEPTIANI
CHITATO SAPI PANGGANG       11.500
ULTRA MILK COKLAT 250ML      7.200
TANGO WAFER COKLAT           8.800
AQUA 1500ML                  6.500
SARI ROTI SOBEK COKLAT      16.000
--------------------------------
SUBTOTAL                    50.000
DISKON MEMBER               -2.500
TOTAL BELANJA               47.500
TUNAI                       50.000
KEMBALIAN                    2.500
PPN 11%                      4.707
================================
KRITIK & SARAN: 1500959
TERIMA KASIH TELAH BERBELANJA
WIFI: ALFA_FREE PASS: 12345
''';

      final parsed = parser.parseText(rawText: noisyReceipt);

      expect(parsed.isRecognized, isTrue);
      expect(parsed.merchant, equals('ALFAMART FATMAWATI 2'));
      expect(parsed.amount, equals(47500));
      expect(parsed.suggestedCategoryId, equals(DefaultCategories.shoppingId));

      // Items extracted
      expect(parsed.items.length, equals(5));
      expect(parsed.items[0].name, equals('CHITATO SAPI PANGGANG'));
      expect(parsed.items[0].totalPrice, equals(11500));
      expect(parsed.items[1].name, equals('ULTRA MILK COKLAT 250ML'));
      expect(parsed.items[1].totalPrice, equals(7200));
      expect(parsed.items[2].name, equals('TANGO WAFER COKLAT'));
      expect(parsed.items[2].totalPrice, equals(8800));
      expect(parsed.items[3].name, equals('AQUA 1500ML'));
      expect(parsed.items[3].totalPrice, equals(6500));
      expect(parsed.items[4].name, equals('SARI ROTI SOBEK COKLAT'));
      expect(parsed.items[4].totalPrice, equals(16000));

      expect(parsed.itemsSummary, contains('5 item: CHITATO SAPI PANGGANG, ULTRA MILK COKLAT 250ML, TANGO WAFER COKLAT'));

      // Clean lines should NOT contain NPWP, address, phone, or cashier
      final cleanText = parsed.cleanLines.join('\n');
      expect(cleanText, isNot(contains('NPWP')));
      expect(cleanText, isNot(contains('JL. RS FATMAWATI')));
      expect(cleanText, isNot(contains('TELP')));
      expect(cleanText, isNot(contains('KASIR: RINI')));
      expect(cleanText, isNot(contains('WIFI: ALFA_FREE')));
      expect(cleanText, contains('CHITATO SAPI PANGGANG (Rp 11.500)'));
      expect(cleanText, contains('Total Belanja: Rp 47.500'));
    });

    test('distinguishes TOTAL from TUNAI and KEMBALI when paid with cash', () {
      const receiptWithCash = '''
KOPI KENANGAN
MALL KELAPA GADING LT. 2
JL. BOULEVARD RAYA
NPWP: 02.123.456.7-001.000
--------------------------------
1 KOPI KENANGAN MANTAN (L)  24.000
1 ROTI COKLAT KLASIK         12.000
--------------------------------
TOTAL                       36.000
TUNAI                      100.000
KEMBALI                     64.000
================================
TERIMA KASIH
''';

      final parsed = parser.parseText(rawText: receiptWithCash);

      expect(parsed.isRecognized, isTrue);
      expect(parsed.merchant, equals('KOPI KENANGAN'));
      // Amount MUST be 36.000, NOT 100.000 (Tunai) and NOT 64.000 (Kembali)
      expect(parsed.amount, equals(36000));
      expect(parsed.items.length, equals(2));
      expect(parsed.items[0].name, equals('KOPI KENANGAN MANTAN (L)'));
      expect(parsed.items[0].totalPrice, equals(24000));
      expect(parsed.items[1].name, equals('ROTI COKLAT KLASIK'));
      expect(parsed.items[1].totalPrice, equals(12000));
    });

    test('rejects store addresses and cashier lines as merchant candidate when store name is not known brand', () {
      const receiptUnknownBrand = '''
SELAMAT DATANG
JL. RAYA SERPONG BLOK AA NO. 5
RUKO GOLDEN MADRID LT. 1
KASIR: SITI 02
TOKO ELEKTRONIK JAYA ABADI
NPWP: 01.999.888.7-011.000
--------------------------------
KABEL HDMI 2M               45.000
CHARGER TYPE C 20W          75.000
--------------------------------
GRAND TOTAL                120.000
QRIS BCA                   120.000
================================
BARANG YANG SUDAH DIBELI TIDAK BISA DITUKAR
''';

      final parsed = parser.parseText(rawText: receiptUnknownBrand);

      expect(parsed.isRecognized, isTrue);
      // Merchant must be the genuine store name, NOT the address or cashier!
      expect(parsed.merchant, equals('TOKO ELEKTRONIK JAYA ABADI'));
      expect(parsed.amount, equals(120000));
      expect(parsed.items.length, equals(2));
      expect(parsed.items[0].name, equals('KABEL HDMI 2M'));
      expect(parsed.items[0].totalPrice, equals(45000));
      expect(parsed.items[1].name, equals('CHARGER TYPE C 20W'));
      expect(parsed.items[1].totalPrice, equals(75000));
    });
  });
}
