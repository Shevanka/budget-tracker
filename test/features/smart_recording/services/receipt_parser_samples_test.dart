import 'package:budget_tracker/core/constants/default_categories.dart';
import 'package:budget_tracker/features/smart_recording/services/receipt_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = ReceiptParser();

  group('Phase 9.6: OCR Parser Real-World Sample Receipts Suite', () {
    // -------------------------------------------------------------------------
    // 1. Retail, Grocery & Supermarkets
    // -------------------------------------------------------------------------
    group('Indonesian Retail & Supermarket Receipts', () {
      test('parses authentic Alfamart receipt with discount and PPN', () {
        const alfamartReceipt = '''
PT. SUMBER ALFARIA TRIJAYA, TBK
ALFAMART TEBET TIMUR
JL. TEBET TIMUR RAYA NO. 15
NPWP: 01.336.238.9-054.000
================================
01/11/2026 18:22:10   KASIR: RINI
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
''';

        final parsed = parser.parseText(rawText: alfamartReceipt);

        expect(parsed.isRecognized, isTrue);
        expect(parsed.merchant, equals('ALFAMART TEBET TIMUR'));
        expect(parsed.amount, equals(47500));
        expect(parsed.formattedAmount, equals('Rp 47.500'));
        expect(parsed.date?.day, equals(1));
        expect(parsed.date?.month, equals(11));
        expect(parsed.date?.year, equals(2026));
        expect(parsed.date?.hour, equals(18));
        expect(parsed.date?.minute, equals(22));
        expect(parsed.suggestedCategoryId, equals(DefaultCategories.shoppingId));
      });

      test('parses Super Indo supermarket receipt with weighing items and member card', () {
        const superIndoReceipt = '''
PT. LION SUPER INDO
SUPER INDO PANCORAN
JL. RAYA PASAR MINGGU NO. 32
TGL: 25-10-2026 10:15
--------------------------------
APEL FUJI RRT
  0.850 KG @ 38.000        32.300
DAGING GILING SAPI
  0.500 KG @ 110.000       55.000
INDOMIE GORENG KRTN       115.000
--------------------------------
SUBTOTAL                  202.300
DISKON PROMO HARI INI     -15.000
TOTAL AKHIR               187.300
DEBIT BCA                 187.300
TOTAL ITEM: 3
================================
SIMPAN STRUK INI SEBAGAI BUKTI
''';

        final parsed = parser.parseText(rawText: superIndoReceipt);

        expect(parsed.isRecognized, isTrue);
        expect(parsed.merchant, equals('SUPER INDO PANCORAN'));
        expect(parsed.amount, equals(187300));
        expect(parsed.formattedAmount, equals('Rp 187.300'));
        expect(parsed.date?.day, equals(25));
        expect(parsed.date?.month, equals(10));
        expect(parsed.date?.year, equals(2026));
        expect(parsed.suggestedCategoryId, equals(DefaultCategories.shoppingId));
      });

      test('parses Hypermart department store receipt', () {
        const hypermartReceipt = '''
HYPERMART CYBERPARK
JL. BOULEVARD DIPONEGORO NO. 100
2026-10-29 16:40
--------------------------------
MAMA LIME 780ML             14.500
TISU PASEO 250S             18.900
BERAS TOPI KOKI 5KG         72.500
MINYAK SANIA 2L             34.000
TOTAL HARGA                139.900
QRIS SHOPEEPAY             139.900
================================
SELAMAT DATANG KEMBALI
''';

        final parsed = parser.parseText(rawText: hypermartReceipt);

        expect(parsed.isRecognized, isTrue);
        expect(parsed.merchant, equals('HYPERMART CYBERPARK'));
        expect(parsed.amount, equals(139900));
        expect(parsed.date?.day, equals(29));
        expect(parsed.date?.month, equals(10));
        expect(parsed.suggestedCategoryId, equals(DefaultCategories.shoppingId));
      });

      test('parses Lawson station convenience store receipt', () {
        const lawsonReceipt = '''
LAWSON STATION CIPETE
JL. CIPETE RAYA NO. 8
31-Okt-2026 21:05
--------------------------------
1 ODEN SPICY               18.000
1 KARAAGE STICK            16.000
1 ICE COFFEE LATTE         18.000
TOTAL                      52.000
CASH                       60.000
CHANGE                      8.000
''';

        final parsed = parser.parseText(rawText: lawsonReceipt);

        expect(parsed.isRecognized, isTrue);
        expect(parsed.merchant, equals('LAWSON STATION CIPETE'));
        expect(parsed.amount, equals(52000));
        expect(parsed.date?.day, equals(31));
        expect(parsed.date?.month, equals(10));
        expect(parsed.suggestedCategoryId, equals(DefaultCategories.foodId));
      });
    });

    // -------------------------------------------------------------------------
    // 2. Food & Dining / Cafes / Restaurants
    // -------------------------------------------------------------------------
    group('Food, Beverage & Restaurant Receipts', () {
      test('parses Starbucks receipt with tax and card payment', () {
        const starbucksReceipt = '''
STARBUCKS COFFEE SENAYAN CITY
GROUND FLOOR UNIT 12
JAKARTA PUSAT
================================
ORDER # 1042
DATE: 28/10/2026 15:30
1 GR CAFFE LATTE           58.000
  OAT MILK UPCHARGE         7.000
1 BUTTER CROISSANT         35.000
--------------------------------
SUBTOTAL                  100.000
PB1 10%                    10.000
GRAND TOTAL               110.000
CREDIT CARD BCA           110.000
================================
THANK YOU FOR VISITING STARBUCKS
''';

        final parsed = parser.parseText(rawText: starbucksReceipt);

        expect(parsed.isRecognized, isTrue);
        expect(parsed.merchant, equals('STARBUCKS COFFEE SENAYAN CITY'));
        expect(parsed.amount, equals(110000));
        expect(parsed.date?.day, equals(28));
        expect(parsed.date?.month, equals(10));
        expect(parsed.suggestedCategoryId, equals(DefaultCategories.foodId));
      });

      test('parses McDonald\'s fast food receipt with multi-line total and PB1', () {
        const mcdReceipt = '''
PT. REKSO NASIONAL FOOD
MCDONALD'S SARINAH THAMRIN
TELP: 021-3903123
TANGGAL: 30-10-2026 12:45
================================
1 PA KET PANAS 1           42.500
1 MCFLURRY OREO            14.000
1 APPLE PIE                13.500
--------------------------------
TOTAL HARGA                70.000
PB1 (10%)                   7.000
TOTAL BAYAR                77.000
GOPAY                      77.000
--------------------------------
NILAI SUDAH TERMASUK PAJAK
''';

        final parsed = parser.parseText(rawText: mcdReceipt);

        expect(parsed.isRecognized, isTrue);
        expect(parsed.merchant, equals('MCDONALD\'S SARINAH THAMRIN'));
        expect(parsed.amount, equals(77000));
        expect(parsed.date?.day, equals(30));
        expect(parsed.date?.month, equals(10));
        expect(parsed.suggestedCategoryId, equals(DefaultCategories.foodId));
      });

      test('parses KFC receipt with drive-thru ordering', () {
        const kfcReceipt = '''
KFC KEMANG RAYA
JAKARTA SELATAN
DATE: 29.10.2026 19:15
================================
1 SUPER BESAR 1            45.000
1 PERKEDEL                  8.500
1 MOCHA FLOAT              12.500
--------------------------------
SUBTOTAL                   66.000
TAX 10%                     6.600
TOTAL BAYAR                72.600
TUNAI                     100.000
KEMBALI                    27.400
''';

        final parsed = parser.parseText(rawText: kfcReceipt);

        expect(parsed.isRecognized, isTrue);
        expect(parsed.merchant, equals('KFC KEMANG RAYA'));
        expect(parsed.amount, equals(72600));
        expect(parsed.date?.day, equals(29));
        expect(parsed.date?.month, equals(10));
        expect(parsed.suggestedCategoryId, equals(DefaultCategories.foodId));
      });

      test('parses HokBen Japanese fast food receipt', () {
        const hokbenReceipt = '''
HOKBEN MALL ARTHA GADING
LT. LG UNIT 45
27/10/2026 13:10
--------------------------------
1 HOKA HEMAT 2             31.500
1 PREMIUM SET              62.000
2 COLD OCHA                16.000
--------------------------------
SUBTOTAL                  109.500
PB1 10%                    10.950
TOTAL                     120.450
DANA                      120.450
''';

        final parsed = parser.parseText(rawText: hokbenReceipt);

        expect(parsed.isRecognized, isTrue);
        expect(parsed.merchant, equals('HOKBEN MALL ARTHA GADING'));
        expect(parsed.amount, equals(120450));
        expect(parsed.date?.day, equals(27));
        expect(parsed.suggestedCategoryId, equals(DefaultCategories.foodId));
      });

      test('parses Solaria dine-in receipt with service charge and PB1', () {
        const solariaReceipt = '''
SOLARIA GRAND INDONESIA
LEVEL 3A WEST MALL
TELP: 021-23580123
================================
MEJA : 42
TGL  : 26/10/2026 19:30
1 NASI GORENG SEAFOOD      48.000
1 MIE AYAM BAKSO           38.000
2 ES TEH MANIS             18.000
--------------------------------
SUB TOTAL                 104.000
SERVICE 5%                  5.200
PB1 10%                    10.920
TOTAL TAGIHAN             120.120
QRIS MANDIRI              120.120
================================
TERIMA KASIH ATAS KUNJUNGANNYA
''';

        final parsed = parser.parseText(rawText: solariaReceipt);

        expect(parsed.isRecognized, isTrue);
        expect(parsed.merchant, equals('SOLARIA GRAND INDONESIA'));
        expect(parsed.amount, equals(120120));
        expect(parsed.date?.day, equals(26));
        expect(parsed.suggestedCategoryId, equals(DefaultCategories.foodId));
      });

      test('parses authentic Padang restaurant receipt (RM Sederhana)', () {
        const padangReceipt = '''
RM SEDERHANA SAHARJO
JL. DR. SAHARJO NO. 115 TEBET
WAKTU: 28-Okt-2026 12:30
--------------------------------
2 NASI PUTIH               20.000
2 RENDANG DAGING           50.000
1 AYAM POP                 24.000
1 GULAI CINCANG            28.000
2 ES JERUK                 24.000
--------------------------------
TOTAL                     146.000
BAYAR TUNAI               150.000
KEMBALIAN                   4.000
''';

        final parsed = parser.parseText(rawText: padangReceipt);

        expect(parsed.isRecognized, isTrue);
        expect(parsed.merchant, equals('RM SEDERHANA SAHARJO'));
        expect(parsed.amount, equals(146000));
        expect(parsed.suggestedCategoryId, equals(DefaultCategories.foodId));
      });

      test('parses Bakmi GM noodle restaurant receipt', () {
        const bakmiReceipt = '''
BAKMI GM MELAWAI
JL. MELAWAI RAYA NO. 18
24/10/2026 13:45
--------------------------------
1 BAKMI SPESIAL GM         39.000
1 PANGSIT GORENG ISI 5     22.000
1 ES LIANG TEH             12.000
--------------------------------
TOTAL BAYAR                73.000
OVO                        73.000
''';

        final parsed = parser.parseText(rawText: bakmiReceipt);

        expect(parsed.isRecognized, isTrue);
        expect(parsed.merchant, equals('BAKMI GM MELAWAI'));
        expect(parsed.amount, equals(73000));
        expect(parsed.suggestedCategoryId, equals(DefaultCategories.foodId));
      });

      test('parses Fore Coffee app pickup receipt', () {
        const foreReceipt = '''
FORE COFFEE PACIFIC PLACE
LG FLOOR UNIT 05
29-10-2026 09:15
--------------------------------
1 AREN LATTE REGULAR       29.000
1 BUTTER CROISSANT         32.000
--------------------------------
SUBTOTAL                   61.000
VOUCHER DISKON            -15.000
GRAND TOTAL                46.000
SHOPEEPAY                  46.000
''';

        final parsed = parser.parseText(rawText: foreReceipt);

        expect(parsed.isRecognized, isTrue);
        expect(parsed.merchant, equals('FORE COFFEE PACIFIC PLACE'));
        expect(parsed.amount, equals(46000));
        expect(parsed.suggestedCategoryId, equals(DefaultCategories.foodId));
      });
    });

    // -------------------------------------------------------------------------
    // 3. Transport & Fuel Stations
    // -------------------------------------------------------------------------
    group('Transport & Petrol Station Receipts', () {
      test('parses Shell fuel station receipt', () {
        const shellReceipt = '''
SHELL GATOT SUBROTO
JL. JEND. GATOT SUBROTO KAV 22
28/10/2026 07:45:10
================================
POMPA 03
PRODUK     : SHELL V-POWER
VOLUME     : 22.50 LTR
HARGA/LTR  : 14.850
--------------------------------
TOTAL HARGA: Rp 334.125
PEMBAYARAN : DEBIT BCA
NO. KARTU  : **** **** **** 1234
================================
TERIMA KASIH TELAH MEMILIH SHELL
''';

        final parsed = parser.parseText(rawText: shellReceipt);

        expect(parsed.isRecognized, isTrue);
        expect(parsed.merchant, equals('SHELL GATOT SUBROTO'));
        expect(parsed.amount, equals(334125));
        expect(parsed.date?.day, equals(28));
        expect(parsed.suggestedCategoryId, equals(DefaultCategories.transportId));
      });

      test('parses SPBU Pertamina motorcycle fuel receipt', () {
        const pertaminaMotorReceipt = '''
SPBU PERTAMINA 34.12345
JL. FATMAWATI NO. 45
29/10/2026 17:50
--------------------------------
PERTAMAX (RON 92)
LITER : 4.25 LTR
TOTAL : Rp 55.000
TUNAI : Rp 100.000
KEMBALI : Rp 45.000
''';

        final parsed = parser.parseText(rawText: pertaminaMotorReceipt);

        expect(parsed.isRecognized, isTrue);
        expect(parsed.merchant, equals('SPBU PERTAMINA 34.12345'));
        expect(parsed.amount, equals(55000));
        expect(parsed.suggestedCategoryId, equals(DefaultCategories.transportId));
      });
    });

    // -------------------------------------------------------------------------
    // 4. Health & Medical / Pharmacy Receipts
    // -------------------------------------------------------------------------
    group('Pharmacy & Healthcare Receipts', () {
      test('parses Apotek Kimia Farma prescription receipt', () {
        const kimiaFarmaReceipt = '''
PT. KIMIA FARMA APOTEK
APOTEK KIMIA FARMA MATRAMAN
JL. MATRAMAN RAYA NO. 23
27-10-2026 14:20
--------------------------------
1 PANADOL EXTRA TAB 10S    15.000
1 IMBOOST FORCE KAPLET     42.000
1 BETADINE KUMUR 100ML     28.500
--------------------------------
SUBTOTAL                   85.500
TOTAL TAGIHAN              85.500
CASH                      100.000
KEMBALIAN                  14.500
''';

        final parsed = parser.parseText(rawText: kimiaFarmaReceipt);

        expect(parsed.isRecognized, isTrue);
        expect(parsed.merchant, equals('APOTEK KIMIA FARMA MATRAMAN'));
        expect(parsed.amount, equals(85500));
        expect(parsed.suggestedCategoryId, equals(DefaultCategories.healthId));
      });

      test('parses Apotek K-24 24-hour drugstore receipt', () {
        const k24Receipt = '''
APOTEK K-24 CIPETE
JL. RS FATMAWATI NO. 12
30/10/2026 23:15
--------------------------------
1 FLU & BATUK SIRUP        24.000
1 TERMOMETER DIGITAL       35.000
TOTAL                      59.000
QRIS BCA                   59.000
''';

        final parsed = parser.parseText(rawText: k24Receipt);

        expect(parsed.isRecognized, isTrue);
        expect(parsed.merchant, equals('APOTEK K-24 CIPETE'));
        expect(parsed.amount, equals(59000));
        expect(parsed.suggestedCategoryId, equals(DefaultCategories.healthId));
      });

      test('parses Guardian beauty and personal care receipt', () {
        const guardianReceipt = '''
GUARDIAN KOTA KASABLANKA
LG UNIT 24
26-Okt-2026 16:30
--------------------------------
1 SENSI MASK 3PLY 50S      32.000
1 CETAPHIL CLEANSER 125ML  89.000
--------------------------------
TOTAL BELANJA             121.000
DEBIT MANDIRI             121.000
''';

        final parsed = parser.parseText(rawText: guardianReceipt);

        expect(parsed.isRecognized, isTrue);
        expect(parsed.merchant, equals('GUARDIAN KOTA KASABLANKA'));
        expect(parsed.amount, equals(121000));
        expect(parsed.suggestedCategoryId, equals(DefaultCategories.shoppingId));
      });

      test('parses Watsons personal care receipt', () {
        const watsonsReceipt = '''
WATSONS MALL TAMAN ANGGREK
LT. 1 UNIT 102
25/10/2026 15:45
--------------------------------
1 NIVEA BODY SERUM         48.000
1 BIRE WATERY ESSENCE      92.000
TOTAL                     140.000
TUNAI                     150.000
KEMBALI                    10.000
''';

        final parsed = parser.parseText(rawText: watsonsReceipt);

        expect(parsed.isRecognized, isTrue);
        expect(parsed.merchant, equals('WATSONS MALL TAMAN ANGGREK'));
        expect(parsed.amount, equals(140000));
        expect(parsed.suggestedCategoryId, equals(DefaultCategories.shoppingId));
      });
    });

    // -------------------------------------------------------------------------
    // 5. Books, Hardware & Lifestyle Receipts
    // -------------------------------------------------------------------------
    group('Books & Hardware Lifestyle Receipts', () {
      test('parses Gramedia bookstore receipt', () {
        const gramediaReceipt = '''
GRAMEDIA MATRAMAN
JL. MATRAMAN RAYA NO. 46-48
NPWP: 01.312.456.7-002.000
28/10/2026 17:15
--------------------------------
1 NOVEL SEBUAH SENI       98.000
1 PILOT G2 PULPEN         22.000
--------------------------------
TOTAL BELANJA            120.000
QRIS BCA                 120.000
''';

        final parsed = parser.parseText(rawText: gramediaReceipt);

        expect(parsed.isRecognized, isTrue);
        expect(parsed.merchant, equals('GRAMEDIA MATRAMAN'));
        expect(parsed.amount, equals(120000));
        expect(parsed.suggestedCategoryId, equals(DefaultCategories.shoppingId));
      });

      test('parses Ace Hardware home improvement receipt', () {
        const aceReceipt = '''
ACE HARDWARE GANDARIA CITY
LG FLOOR
27-10-2026 14:10
--------------------------------
KRISBOW KABEL ROLL 10M    149.000
BATERAI ENERGIZER 4S       42.000
--------------------------------
TOTAL                    191.000
CASH                     200.000
CHANGE                     9.000
''';

        final parsed = parser.parseText(rawText: aceReceipt);

        expect(parsed.isRecognized, isTrue);
        expect(parsed.merchant, equals('ACE HARDWARE GANDARIA CITY'));
        expect(parsed.amount, equals(191000));
        expect(parsed.suggestedCategoryId, equals(DefaultCategories.shoppingId));
      });

      test('parses MR. DIY accessories receipt', () {
        const mrDiyReceipt = '''
MR DIY PLAZA BLOK M
LT. 2 UNIT 28
29/10/2026 19:40
--------------------------------
KABEL DATA TYPE-C         25.000
GANTUNGAN BAJU STAINLESS  18.000
--------------------------------
TOTAL BELANJA             43.000
OVO                       43.000
''';

        final parsed = parser.parseText(rawText: mrDiyReceipt);

        expect(parsed.isRecognized, isTrue);
        expect(parsed.merchant, equals('MR DIY PLAZA BLOK M'));
        expect(parsed.amount, equals(43000));
        expect(parsed.suggestedCategoryId, equals(DefaultCategories.shoppingId));
      });
    });

    // -------------------------------------------------------------------------
    // 6. Noisy OCR Artefacts, Edge Cases & Robustness
    // -------------------------------------------------------------------------
    group('OCR Artefacts & Noisy Edge Cases', () {
      test('recovers from OCR zero substitution in "T0TAL" keyword', () {
        const noisyOcrZero = '''
WARUNG KOPI SARI
JL. TEBET UTARA NO. 4
28/10/2026
KOPI HITAM          10.000
ROTI BAKAR          15.000
T0TAL HARGA         25.000
TUNAI               50.000
''';

        final parsed = parser.parseText(rawText: noisyOcrZero);

        expect(parsed.isRecognized, isTrue);
        expect(parsed.amount, equals(25000));
        expect(parsed.merchant, equals('WARUNG KOPI SARI'));
      });

      test('recovers from OCR number 4 substitution in "TOT4L BAYAR"', () {
        const noisyOcrFour = '''
TOKO KELONTONG BERKAH
JL. SURABAYA NO. 1
29/10/2026
BERAS 5KG           65.000
TOT4L BAYAR         65.000
''';

        final parsed = parser.parseText(rawText: noisyOcrFour);

        expect(parsed.isRecognized, isTrue);
        expect(parsed.amount, equals(65000));
      });

      test('strips noisy borders (***, ===, ---, ~~~) around merchant name', () {
        const decorativeMerchant = '''
*** KOPI TUKU CIPETE ***
JL. CIPETE RAYA NO. 7
WAKTU: 25-10-2026 09:30
ES KOPI TETANGGA    20.000
TOTAL               20.000
''';

        final parsed = parser.parseText(rawText: decorativeMerchant);

        expect(parsed.isRecognized, isTrue);
        expect(parsed.merchant, equals('KOPI TUKU CIPETE'));
        expect(parsed.amount, equals(20000));
        expect(parsed.suggestedCategoryId, equals(DefaultCategories.foodId));
      });

      test('handles colon and space variations e.g. "TOTAL : Rp . 85.000"', () {
        const colonVariations = '''
WARUNG MAKAN SEDAP
30/10/2026
TOTAL : Rp . 85.000
BAYAR : 100.000
KEMBALI : 15.000
''';

        final parsed = parser.parseText(rawText: colonVariations);

        expect(parsed.isRecognized, isTrue);
        expect(parsed.amount, equals(85000));
      });

      test('parses full Indonesian month name with comma e.g. "28 Oktober 2026, 14:35"', () {
        const fullDateMonth = '''
INDOMARET POINT
28 Oktober 2026, 14:35
TOTAL 35.000
''';

        final parsed = parser.parseText(rawText: fullDateMonth);

        expect(parsed.isRecognized, isTrue);
        expect(parsed.date?.year, equals(2026));
        expect(parsed.date?.month, equals(10));
        expect(parsed.date?.day, equals(28));
        expect(parsed.date?.hour, equals(14));
        expect(parsed.date?.minute, equals(35));
      });

      test('parses date with slash format "2026/12/31 23:59"', () {
        const slashIsoDate = '''
ALFAMART
2026/12/31 23:59
TOTAL 45.000
''';

        final parsed = parser.parseText(rawText: slashIsoDate);

        expect(parsed.isRecognized, isTrue);
        expect(parsed.date?.year, equals(2026));
        expect(parsed.date?.month, equals(12));
        expect(parsed.date?.day, equals(31));
        expect(parsed.date?.hour, equals(23));
        expect(parsed.date?.minute, equals(59));
      });

      test('parses date with textual November format e.g. "12 November 2026"', () {
        const novemberDate = '''
STARBUCKS
12 November 2026 10:00
TOTAL 65.000
''';

        final parsed = parser.parseText(rawText: novemberDate);

        expect(parsed.isRecognized, isTrue);
        expect(parsed.date?.year, equals(2026));
        expect(parsed.date?.month, equals(11));
        expect(parsed.date?.day, equals(12));
      });

      test('handles completely non-receipt random text gracefully', () {
        const randomArticle = '''
Laporan Cuaca Jakarta Hari Ini:
Badan Meteorologi Klimatologi dan Geofisika memperkirakan hujan lebat disertai petir
di sebagian besar wilayah Jakarta Selatan dan Jakarta Timur pada sore hari.
Warga diimbau waspada terhadap genangan air.
''';

        final parsed = parser.parseText(rawText: randomArticle);

        expect(parsed.isRecognized, isFalse);
        expect(parsed.amount, isNull);
        expect(parsed.formattedAmount, equals('-'));
      });

      test('handles empty or blank string without throwing exceptions', () {
        final parsedEmpty = parser.parseText(rawText: '');
        expect(parsedEmpty.isRecognized, isFalse);
        expect(parsedEmpty.merchant, isNull);
        expect(parsedEmpty.amount, isNull);

        final parsedWhitespace = parser.parseText(rawText: '   \n  \n\t  ');
        expect(parsedWhitespace.isRecognized, isFalse);
        expect(parsedWhitespace.merchant, isNull);
        expect(parsedWhitespace.amount, isNull);
      });
    });
  });
}
