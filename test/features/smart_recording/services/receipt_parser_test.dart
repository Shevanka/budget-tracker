import 'package:budget_tracker/core/constants/default_categories.dart';
import 'package:budget_tracker/features/smart_recording/models/receipt_scan_result.dart';
import 'package:budget_tracker/features/smart_recording/services/receipt_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = ReceiptParser();
  final defaultTimestamp = DateTime.utc(2026, 11, 1, 10, 0);

  group('ReceiptParser Service Tests (Phase 9.2)', () {
    // -------------------------------------------------------------------------
    // Merchant Extraction Tests
    // -------------------------------------------------------------------------
    group('Merchant Name Extraction', () {
      test('identifies Indomaret and strips address and legal prefixes', () {
        const lines = [
          'SELAMAT DATANG',
          'PT. INDOMARCO PRISMATAMA',
          'INDOMARET POINT KEMANG',
          'JL. KEMANG RAYA NO. 12',
          'TELP: 021-7192837',
          'NPWP: 01.234.567.8-000.000',
        ];

        final merchant = parser.extractMerchant(lines);
        expect(merchant, equals('INDOMARET POINT KEMANG'));
      });

      test('identifies Alfamart with branch name', () {
        const lines = [
          'PT. SUMBER ALFARIA TRIJAYA, TBK',
          'ALFAMART FATMAWATI 2',
          'JL. RS FATMAWATI',
          'TGL: 28/10/2026',
        ];

        final merchant = parser.extractMerchant(lines);
        expect(merchant, equals('ALFAMART FATMAWATI 2'));
      });

      test('identifies coffee shop / restaurant brands', () {
        const lines = [
          'STRUK PEMBAYARAN',
          'KOPI KENANGAN',
          'MALL KELAPA GADING LT. 2',
        ];

        final merchant = parser.extractMerchant(lines);
        expect(merchant, equals('KOPI KENANGAN'));
      });

      test('identifies petrol station brand', () {
        const lines = [
          'BUKTI TRANSAKSI',
          'SPBU PERTAMINA 31.123.01',
          'JL. MT HARYONO',
        ];

        final merchant = parser.extractMerchant(lines);
        expect(merchant, equals('SPBU PERTAMINA 31.123.01'));
      });

      test('falls back to first non-ignorable uppercase store title', () {
        const lines = [
          'SELAMAT DATANG',
          'TOKO BUKU BINTANG TERANG',
          'JL. PAHLAWAN NO. 8',
        ];

        final merchant = parser.extractMerchant(lines);
        expect(merchant, equals('TOKO BUKU BINTANG TERANG'));
      });

      test('returns null when lines are empty or only contains noise/symbols', () {
        expect(parser.extractMerchant([]), isNull);
        expect(
          parser.extractMerchant(['===', '---', '123456', 'SELAMAT DATANG']),
          isNull,
        );
      });
    });

    // -------------------------------------------------------------------------
    // Total Amount Extraction Tests
    // -------------------------------------------------------------------------
    group('Total Amount Extraction', () {
      test('extracts amount from TOTAL line with dot thousand separator', () {
        const lines = [
          'ROTI TAWAR    15.000',
          'SUSU UHT      18.000',
          'TOTAL         33.000',
          'TUNAI         50.000',
          'KEMBALI       17.000',
        ];

        final amount = parser.extractTotalAmount(lines);
        expect(amount, equals(33000));
      });

      test('prioritizes GRAND TOTAL over SUBTOTAL', () {
        const lines = [
          'NASI GORENG SPECIAL   35.000',
          'ES TEH MANIS           5.000',
          'SUBTOTAL              40.000',
          'PB1 10%                4.000',
          'GRAND TOTAL           44.000',
          'BAYAR CASH            50.000',
          'KEMBALIAN              6.000',
        ];

        final amount = parser.extractTotalAmount(lines);
        expect(amount, equals(44000));
      });

      test('extracts TOTAL BELANJA and handles comma cents', () {
        const lines = [
          'MINYAK GORENG 2L      36.500,00',
          'BERAS 5KG             68.000,00',
          'TOTAL BELANJA        104.500,00',
          'CASH                 110.000,00',
        ];

        final amount = parser.extractTotalAmount(lines);
        expect(amount, equals(104500));
      });

      test('handles two-line total layout (label on line i, amount on line i+1)', () {
        const lines = [
          'WARUNG TEKKO',
          'AYAM BAKAR    25.000',
          'TOTAL BAYAR',
          'Rp 25.000',
          'TERIMA KASIH',
        ];

        final amount = parser.extractTotalAmount(lines);
        expect(amount, equals(25000));
      });

      test('ignores TOTAL ITEM / TOTAL QTY line', () {
        const lines = [
          'ITEM A         10.000',
          'ITEM B         20.000',
          'TOTAL ITEM: 2',
          'TOTAL HARGA    30.000',
        ];

        final amount = parser.extractTotalAmount(lines);
        expect(amount, equals(30000));
      });

      test('returns null when no amount lines exist', () {
        expect(parser.extractTotalAmount([]), isNull);
        expect(
          parser.extractTotalAmount(['SELAMAT DATANG', 'TERIMA KASIH']),
          isNull,
        );
      });
    });

    // -------------------------------------------------------------------------
    // Date & Timestamp Extraction Tests
    // -------------------------------------------------------------------------
    group('Date Extraction', () {
      test('extracts DD/MM/YYYY date and time', () {
        const lines = [
          'INDOMARET',
          '28/10/2026 14:35:20',
          'TOTAL 35.000',
        ];

        final date = parser.extractDate(lines);
        expect(date, isNotNull);
        expect(date!.year, equals(2026));
        expect(date.month, equals(10));
        expect(date.day, equals(28));
        expect(date.hour, equals(14));
        expect(date.minute, equals(35));
      });

      test('extracts DD-MM-YY short year format', () {
        const lines = [
          'ALFAMART',
          'TGL: 29-10-26 19:20',
          'TOTAL 18.000',
        ];

        final date = parser.extractDate(lines);
        expect(date, isNotNull);
        expect(date!.year, equals(2026));
        expect(date.month, equals(10));
        expect(date.day, equals(29));
      });

      test('extracts Indonesian textual month (e.g. 30-Okt-2026)', () {
        const lines = [
          'KOPI KENANGAN',
          'WAKTU: 30-Okt-2026 11:45',
          'TOTAL 36.300',
        ];

        final date = parser.extractDate(lines);
        expect(date, isNotNull);
        expect(date!.year, equals(2026));
        expect(date.month, equals(10));
        expect(date.day, equals(30));
        expect(date.hour, equals(11));
        expect(date.minute, equals(45));
      });

      test('extracts YYYY-MM-DD ISO date format', () {
        const lines = [
          'SPBU PERTAMINA',
          '2026-10-27 08:15',
          'TOTAL 150.000',
        ];

        final date = parser.extractDate(lines);
        expect(date, isNotNull);
        expect(date!.year, equals(2026));
        expect(date.month, equals(10));
        expect(date.day, equals(27));
      });

      test('returns null when no valid date is present', () {
        expect(parser.extractDate([]), isNull);
        expect(parser.extractDate(['INDOMARET', 'TOTAL 45.000']), isNull);
      });
    });

    // -------------------------------------------------------------------------
    // End-to-End Real Indonesian Receipt Parsing
    // -------------------------------------------------------------------------
    group('Full Receipt End-to-End Parsing', () {
      test('parses full Indomaret receipt', () {
        const rawReceipt = '''
INDOMARET POINT
JL. PANGLIMA POLIM NO. 42
TELP: 021-7234567
NPWP: 01.337.994.6-092.000
================================
28.10.2026 14:35 2.1.48/01/Cashier
ROTI TAWAR SARI ROTI    15.000
AQUA AIR MINERAL 600ML   3.500
INDOMIE GORENG 5X        15.500
--------------------------------
TOTAL BELANJA           34.000
TUNAI                   50.000
KEMBALI                 16.000
================================
TERIMA KASIH
''';

        final scanResult = ReceiptScanResult(
          imagePath: '/receipts/indomaret.jpg',
          rawText: rawReceipt,
          lines: rawReceipt.split('\n').map((l) => l.trim()).toList(),
          timestamp: defaultTimestamp,
        );

        final parsed = parser.parse(scanResult);

        expect(parsed.isRecognized, isTrue);
        expect(parsed.merchant, equals('INDOMARET POINT'));
        expect(parsed.amount, equals(34000));
        expect(parsed.formattedAmount, equals('Rp 34.000'));
        expect(parsed.date?.day, equals(28));
        expect(parsed.date?.month, equals(10));
        expect(parsed.date?.year, equals(2026));
        expect(parsed.suggestedCategoryId, equals(DefaultCategories.shoppingId));
      });

      test('parses full Kopi Kenangan receipt with food category', () {
        const rawReceipt = '''
KOPI KENANGAN
MALL KELAPA GADING 3 LT. 2
STRUK : 928103
WAKTU : 30-Okt-2026 11:45
--------------------------------
1 KOPI KENANGAN MANTAN   18.000
1 TOAST COKLAT KLASIK    15.000
SUBTOTAL                 33.000
PB1 10%                   3.300
GRAND TOTAL              36.300
QRIS BCA                 36.300
--------------------------------
THANK YOU FOR VISITING!
''';

        final parsed = parser.parseText(rawText: rawReceipt);

        expect(parsed.isRecognized, isTrue);
        expect(parsed.merchant, equals('KOPI KENANGAN'));
        expect(parsed.amount, equals(36300));
        expect(parsed.date?.month, equals(10));
        expect(parsed.date?.day, equals(30));
        expect(parsed.suggestedCategoryId, equals(DefaultCategories.foodId));
      });

      test('parses SPBU Pertamina receipt with transport category', () {
        const rawReceipt = '''
SPBU PERTAMINA 31.123.01
JL. MT HARYONO KAV 10
JAKARTA SELATAN
27/10/2026 08:15:30
--------------------------------
PERTAMAX
LITER    : 25.00 LTR
HARGA/LT : 12.800
TOTAL    : Rp 320.000
CASH     : Rp 350.000
KEMBALI  : Rp 30.000
--------------------------------
PASTIKAN KENDARAAN ANDA MATI
''';

        final parsed = parser.parseText(rawText: rawReceipt);

        expect(parsed.isRecognized, isTrue);
        expect(parsed.merchant, equals('SPBU PERTAMINA 31.123.01'));
        expect(parsed.amount, equals(320000));
        expect(parsed.date?.day, equals(27));
        expect(parsed.suggestedCategoryId, equals(DefaultCategories.transportId));
      });

      test('handles incomplete or blurred receipt gracefully without throwing', () {
        const blurryReceipt = '''
=== STRUK PEMBAYARAN ===
SELAMAT DATANG
TERIMA KASIH
''';

        final parsed = parser.parseText(
          rawText: blurryReceipt,
          fallbackDate: defaultTimestamp,
        );

        expect(parsed.isRecognized, isFalse);
        expect(parsed.amount, isNull);
        expect(parsed.formattedAmount, equals('-'));
        expect(parsed.date, equals(defaultTimestamp));
      });
    });
  });
}
