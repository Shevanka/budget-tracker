import 'package:budget_tracker/core/constants/default_categories.dart';
import 'package:budget_tracker/database/converters/transaction_type.dart';
import 'package:budget_tracker/features/notification_watcher/constants/watched_apps.dart';
import 'package:budget_tracker/features/notification_watcher/services/notification_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = NotificationParser();
  final testTimestamp = DateTime.utc(2026, 10, 31, 15, 30);

  group('Phase 8.6: Real Indonesian Notification Samples & Edge Cases', () {
    // ---------------------------------------------------------------------------
    // 1. Bank Central Asia (BCA)
    // ---------------------------------------------------------------------------
    group('1. BCA Real Notification Samples', () {
      test('parses debit purchase with trailing comma cents and account suffix', () {
        const body = 'Pembelian di INDOMARET Rp 45.000,00 di rek *1234';
        final parsed = parser.parse(
          body: body,
          appPackage: WatchedApps.bca.packageNames.first,
          timestamp: testTimestamp,
        );

        expect(parsed, isNotNull);
        expect(parsed!.source, equals('BCA'));
        expect(parsed.amount, equals(45000));
        expect(parsed.merchant, equals('INDOMARET'));
        expect(parsed.suggestedCategoryId, equals(DefaultCategories.shoppingId));
        expect(parsed.type, equals(TransactionType.expense));
      });

      test('parses BCA QRIS merchant payment', () {
        const body = 'Pembayaran QRIS di KOPI KENANGAN Rp 28.000 berhasil';
        final parsed = parser.parse(
          body: body,
          appPackage: WatchedApps.bca.packageNames.last,
          timestamp: testTimestamp,
        );

        expect(parsed, isNotNull);
        expect(parsed!.source, equals('BCA'));
        expect(parsed.amount, equals(28000));
        expect(parsed.merchant, equals('KOPI KENANGAN'));
        expect(parsed.suggestedCategoryId, equals(DefaultCategories.foodId));
      });

      test('parses BCA QRIS payment with "ke" destination and decimal dot', () {
        const body = 'Pembayaran QRIS ke STARBUCKS INDONESIA Rp 58.500 berhasil';
        final parsed = parser.parse(
          body: body,
          appPackage: 'com.bca.mybca',
          timestamp: testTimestamp,
        );

        expect(parsed, isNotNull);
        expect(parsed!.amount, equals(58500));
        expect(parsed.merchant, equals('STARBUCKS INDONESIA'));
        expect(parsed.suggestedCategoryId, equals(DefaultCategories.foodId));
      });

      test('parses BCA e-commerce payment with account masked suffix', () {
        const body = 'Pembelian di TOKOPEDIA Rp 254.300 di rek *5678';
        final parsed = parser.parse(
          body: body,
          appPackage: 'com.bca',
          timestamp: testTimestamp,
        );

        expect(parsed, isNotNull);
        expect(parsed!.amount, equals(254300));
        expect(parsed.merchant, equals('TOKOPEDIA'));
        expect(parsed.suggestedCategoryId, equals(DefaultCategories.shoppingId));
      });

      test('parses BCA petrol station purchase', () {
        const body = 'Pembayaran QRIS di SPBU PERTAMINA 34-12345 Rp 150.000 berhasil';
        final parsed = parser.parse(
          body: body,
          appPackage: 'com.bca.mybca',
          timestamp: testTimestamp,
        );

        expect(parsed, isNotNull);
        expect(parsed!.amount, equals(150000));
        expect(parsed.merchant, equals('SPBU PERTAMINA 34-12345'));
        expect(parsed.suggestedCategoryId, equals(DefaultCategories.transportId));
      });

      test('parses multi-part BCA notification with app title and body', () {
        final parsed = parser.parse(
          title: 'm-BCA',
          body: 'Pembelian di KARTIKA SARI Rp 135.000,00 di rek *9999',
          appPackage: 'com.bca',
          timestamp: testTimestamp,
        );

        expect(parsed, isNotNull);
        expect(parsed!.amount, equals(135000));
        expect(parsed.merchant, equals('KARTIKA SARI'));
        expect(parsed.suggestedCategoryId, equals(DefaultCategories.foodId));
      });
    });

    // ---------------------------------------------------------------------------
    // 2. Bank Mandiri (Livin' by Mandiri)
    // ---------------------------------------------------------------------------
    group('2. Bank Mandiri Real Notification Samples', () {
      test('parses Mandiri QRIS payment at coffee shop', () {
        const body = 'Pembayaran QRIS sebesar Rp 35.000 di WARUNG KOPI berhasil.';
        final parsed = parser.parse(
          body: body,
          appPackage: WatchedApps.mandiri.packageNames.first,
          timestamp: testTimestamp,
        );

        expect(parsed, isNotNull);
        expect(parsed!.source, equals('Mandiri'));
        expect(parsed.amount, equals(35000));
        expect(parsed.merchant, equals('WARUNG KOPI'));
        expect(parsed.suggestedCategoryId, equals(DefaultCategories.foodId));
      });

      test('parses Mandiri debit card transaction at convenience store', () {
        const body = 'Transaksi debit sebesar Rp 120.000 di ALFAMART telah berhasil.';
        final parsed = parser.parse(
          body: body,
          appPackage: 'id.co.bankmandiri.livin',
          timestamp: testTimestamp,
        );

        expect(parsed, isNotNull);
        expect(parsed!.amount, equals(120000));
        expect(parsed.merchant, equals('ALFAMART'));
        expect(parsed.suggestedCategoryId, equals(DefaultCategories.shoppingId));
      });

      test('parses Mandiri QRIS at FORE COFFEE with "telah berhasil"', () {
        const body = 'Pembayaran QRIS sebesar Rp 18.000 di FORE COFFEE telah berhasil.';
        final parsed = parser.parse(
          body: body,
          appPackage: 'id.co.bankmandiri.livin',
          timestamp: testTimestamp,
        );

        expect(parsed, isNotNull);
        expect(parsed!.amount, equals(18000));
        expect(parsed.merchant, equals('FORE COFFEE'));
        expect(parsed.suggestedCategoryId, equals(DefaultCategories.foodId));
      });

      test('parses Mandiri supermarket debit transaction', () {
        const body = 'Transaksi debit sebesar Rp 450.000 di HYPERMART telah berhasil.';
        final parsed = parser.parse(
          body: body,
          appPackage: 'id.co.bankmandiri.livin',
          timestamp: testTimestamp,
        );

        expect(parsed, isNotNull);
        expect(parsed!.amount, equals(450000));
        expect(parsed.merchant, equals('HYPERMART'));
        expect(parsed.suggestedCategoryId, equals(DefaultCategories.shoppingId));
      });

      test('parses Mandiri purchase at fast food', () {
        const body = 'Pembelian sebesar Rp 85.000 di MCDONALDS telah berhasil.';
        final parsed = parser.parse(
          body: body,
          appPackage: 'id.co.bankmandiri.livin',
          timestamp: testTimestamp,
        );

        expect(parsed, isNotNull);
        expect(parsed!.amount, equals(85000));
        expect(parsed.merchant, equals('MCDONALDS'));
        expect(parsed.suggestedCategoryId, equals(DefaultCategories.foodId));
      });
    });

    // ---------------------------------------------------------------------------
    // 3. BNI (Mobile Banking / wondr by BNI)
    // ---------------------------------------------------------------------------
    group('3. BNI Real Notification Samples', () {
      test('parses BNI QRIS without "sebesar"', () {
        const body = 'Transaksi QRIS Rp 45.000 di KOPI JANJI JIWA berhasil';
        final parsed = parser.parse(
          body: body,
          appPackage: WatchedApps.bni.packageNames.first,
          timestamp: testTimestamp,
        );

        expect(parsed, isNotNull);
        expect(parsed!.source, equals('BNI'));
        expect(parsed.amount, equals(45000));
        expect(parsed.merchant, equals('KOPI JANJI JIWA'));
        expect(parsed.suggestedCategoryId, equals(DefaultCategories.foodId));
      });

      test('parses BNI purchase with trailing date timestamp', () {
        const body = 'Pembelian sebesar Rp 150.000 di INDOMARET pada 03/10/2026 berhasil';
        final parsed = parser.parse(
          body: body,
          appPackage: WatchedApps.bni.packageNames.last,
          timestamp: testTimestamp,
        );

        expect(parsed, isNotNull);
        expect(parsed!.amount, equals(150000));
        expect(parsed.merchant, equals('INDOMARET'));
        expect(parsed.suggestedCategoryId, equals(DefaultCategories.shoppingId));
      });

      test('parses BNI outgoing transfer to person', () {
        const body = 'Transfer keluar sebesar Rp 250.000 di BUDI SANTOSO berhasil';
        final parsed = parser.parse(
          body: body,
          appPackage: 'id.co.bni.wondr',
          timestamp: testTimestamp,
        );

        expect(parsed, isNotNull);
        expect(parsed!.amount, equals(250000));
        expect(parsed.merchant, equals('BUDI SANTOSO'));
      });

      test('parses BNI bookstore purchase without "sebesar"', () {
        const body = 'Pembelian Rp 89.000 di GRAMEDIA berhasil';
        final parsed = parser.parse(
          body: body,
          appPackage: 'id.co.bni.mobilebanking',
          timestamp: testTimestamp,
        );

        expect(parsed, isNotNull);
        expect(parsed!.amount, equals(89000));
        expect(parsed.merchant, equals('GRAMEDIA'));
        expect(parsed.suggestedCategoryId, equals(DefaultCategories.shoppingId));
      });
    });

    // ---------------------------------------------------------------------------
    // 4. BTN (BTN Mobile)
    // ---------------------------------------------------------------------------
    group('4. BTN Mobile Real Notification Samples', () {
      test('parses BTN QRIS payment at food stall', () {
        const body = 'Transaksi QRIS sebesar Rp 32.500 di BAKSO RUSUK berhasil';
        final parsed = parser.parse(
          body: body,
          appPackage: WatchedApps.btn.packageNames.first,
          timestamp: testTimestamp,
        );

        expect(parsed, isNotNull);
        expect(parsed!.source, equals('BTN'));
        expect(parsed.amount, equals(32500));
        expect(parsed.merchant, equals('BAKSO RUSUK'));
        expect(parsed.suggestedCategoryId, equals(DefaultCategories.foodId));
      });

      test('parses BTN debit with account number prefix', () {
        const body = 'Debit rek 12345 sebesar Rp 85.000 di INDOMARET berhasil';
        final parsed = parser.parse(
          body: body,
          appPackage: 'id.co.btn.mobilebanking',
          timestamp: testTimestamp,
        );

        expect(parsed, isNotNull);
        expect(parsed!.amount, equals(85000));
        expect(parsed.merchant, equals('INDOMARET'));
        expect(parsed.suggestedCategoryId, equals(DefaultCategories.shoppingId));
      });

      test('parses BTN payment at Superindo grocery store', () {
        const body = 'Pembayaran sebesar Rp 64.000 di SUPERINDO berhasil';
        final parsed = parser.parse(
          body: body,
          appPackage: 'id.co.btn.mobilebanking',
          timestamp: testTimestamp,
        );

        expect(parsed, isNotNull);
        expect(parsed!.amount, equals(64000));
        expect(parsed.merchant, equals('SUPERINDO'));
        expect(parsed.suggestedCategoryId, equals(DefaultCategories.shoppingId));
      });

      test('parses BTN QRIS to bakery with destination prefix "ke"', () {
        const body = 'Transaksi QRIS Rp 22.000 ke ROTI O berhasil.';
        final parsed = parser.parse(
          body: body,
          appPackage: 'id.co.btn.mobilebanking',
          timestamp: testTimestamp,
        );

        expect(parsed, isNotNull);
        expect(parsed!.amount, equals(22000));
        expect(parsed.merchant, equals('ROTI O'));
        expect(parsed.suggestedCategoryId, equals(DefaultCategories.foodId));
      });
    });

    // ---------------------------------------------------------------------------
    // 5. SeaBank
    // ---------------------------------------------------------------------------
    group('5. SeaBank Real Notification Samples', () {
      test('parses SeaBank QRIS payment with trailing period', () {
        const body = 'Pembayaran QRIS sebesar Rp 25.000 ke POINT COFFEE berhasil.';
        final parsed = parser.parse(
          body: body,
          appPackage: WatchedApps.seaBank.packageNames.first,
          timestamp: testTimestamp,
        );

        expect(parsed, isNotNull);
        expect(parsed!.source, equals('SeaBank'));
        expect(parsed.amount, equals(25000));
        expect(parsed.merchant, equals('POINT COFFEE'));
        expect(parsed.suggestedCategoryId, equals(DefaultCategories.foodId));
      });

      test('parses SeaBank Japanese restaurant payment', () {
        const body = 'Pembayaran QRIS sebesar Rp 55.000 di HOKBEN berhasil.';
        final parsed = parser.parse(
          body: body,
          appPackage: 'com.seabank.id',
          timestamp: testTimestamp,
        );

        expect(parsed, isNotNull);
        expect(parsed!.amount, equals(55000));
        expect(parsed.merchant, equals('HOKBEN'));
        expect(parsed.suggestedCategoryId, equals(DefaultCategories.foodId));
      });

      test('parses SeaBank ice cream payment', () {
        const body = 'Pembayaran sebesar Rp 35.000 ke MIXUE berhasil.';
        final parsed = parser.parse(
          body: body,
          appPackage: 'com.seabank.id',
          timestamp: testTimestamp,
        );

        expect(parsed, isNotNull);
        expect(parsed!.amount, equals(35000));
        expect(parsed.merchant, equals('MIXUE'));
        expect(parsed.suggestedCategoryId, equals(DefaultCategories.foodId));
      });
    });

    // ---------------------------------------------------------------------------
    // 6. ShopeePay
    // ---------------------------------------------------------------------------
    group('6. ShopeePay Real Notification Samples', () {
      test('parses ShopeePay QRIS with exclamation mark', () {
        const body = 'Pembayaran QRIS sebesar Rp 30.000 di JANJI JIWA berhasil!';
        final parsed = parser.parse(
          body: body,
          appPackage: WatchedApps.shopeePay.packageNames.first,
          timestamp: testTimestamp,
        );

        expect(parsed, isNotNull);
        expect(parsed!.source, equals('ShopeePay'));
        expect(parsed.amount, equals(30000));
        expect(parsed.merchant, equals('JANJI JIWA'));
        expect(parsed.suggestedCategoryId, equals(DefaultCategories.foodId));
      });

      test('parses ShopeePay "Kamu berhasil membayar" notification', () {
        const body = 'Kamu berhasil membayar Rp 75.000 ke Kopi Tuku.';
        final parsed = parser.parse(
          body: body,
          appPackage: 'com.shopeepay.id',
          timestamp: testTimestamp,
        );

        expect(parsed, isNotNull);
        expect(parsed!.amount, equals(75000));
        expect(parsed.merchant, equals('Kopi Tuku'));
        expect(parsed.suggestedCategoryId, equals(DefaultCategories.foodId));
      });

      test('parses ShopeePay retail payment with "menggunakan ShopeePay" suffix', () {
        const body = 'Pembayaran sebesar Rp 150.000 di WATSONS menggunakan ShopeePay berhasil!';
        final parsed = parser.parse(
          body: body,
          appPackage: 'com.shopee.id',
          timestamp: testTimestamp,
        );

        expect(parsed, isNotNull);
        expect(parsed!.amount, equals(150000));
        expect(parsed.merchant, equals('WATSONS'));
        expect(parsed.suggestedCategoryId, equals(DefaultCategories.shoppingId));
      });

      test('parses ShopeePay convenience store purchase', () {
        const body = 'Kamu berhasil membayar Rp 43.500 ke LAWSON INDONESIA.';
        final parsed = parser.parse(
          body: body,
          appPackage: 'com.shopeepay.id',
          timestamp: testTimestamp,
        );

        expect(parsed, isNotNull);
        expect(parsed!.amount, equals(43500));
        expect(parsed.merchant, equals('LAWSON INDONESIA'));
        expect(parsed.suggestedCategoryId, equals(DefaultCategories.foodId));
      });
    });

    // ---------------------------------------------------------------------------
    // 7. GoPay (Gojek / GoPay App)
    // ---------------------------------------------------------------------------
    group('7. GoPay Real Notification Samples', () {
      test('parses GoFood delivery payment with hyphenated merchant', () {
        const body = 'Kamu berhasil bayar Rp 38.000 ke Gofood - Ayam Geprek Bensu.';
        final parsed = parser.parse(
          body: body,
          appPackage: WatchedApps.goPay.packageNames.first,
          timestamp: testTimestamp,
        );

        expect(parsed, isNotNull);
        expect(parsed!.source, equals('GoPay'));
        expect(parsed.amount, equals(38000));
        expect(parsed.merchant, equals('Gofood - Ayam Geprek Bensu'));
        expect(parsed.suggestedCategoryId, equals(DefaultCategories.foodId));
      });

      test('parses GoPay retail payment with "pakai GoPay" suffix', () {
        const body = 'Kamu telah membayar Rp 15.000 di ALFAMART pakai GoPay.';
        final parsed = parser.parse(
          body: body,
          appPackage: 'id.co.gopay',
          timestamp: testTimestamp,
        );

        expect(parsed, isNotNull);
        expect(parsed!.amount, equals(15000));
        expect(parsed.merchant, equals('ALFAMART'));
        expect(parsed.suggestedCategoryId, equals(DefaultCategories.shoppingId));
      });

      test('parses Goride motorcycle ride payment', () {
        const body = 'Kamu berhasil bayar Rp 24.000 ke Goride.';
        final parsed = parser.parse(
          body: body,
          appPackage: 'com.gojek.app',
          timestamp: testTimestamp,
        );

        expect(parsed, isNotNull);
        expect(parsed!.amount, equals(24000));
        expect(parsed.merchant, equals('Goride'));
        expect(parsed.suggestedCategoryId, equals(DefaultCategories.transportId));
      });

      test('parses Gocar car ride payment', () {
        const body = 'Kamu bayar Rp 110.000 ke Gocar.';
        final parsed = parser.parse(
          body: body,
          appPackage: 'com.gojek.app',
          timestamp: testTimestamp,
        );

        expect(parsed, isNotNull);
        expect(parsed!.amount, equals(110000));
        expect(parsed.merchant, equals('Gocar'));
        expect(parsed.suggestedCategoryId, equals(DefaultCategories.transportId));
      });

      test('parses GoPay QRIS at cafe', () {
        const body = 'Pembayaran QRIS sebesar Rp 29.000 di KOPI KENANGAN berhasil';
        final parsed = parser.parse(
          body: body,
          appPackage: 'id.co.gopay',
          timestamp: testTimestamp,
        );

        expect(parsed, isNotNull);
        expect(parsed!.amount, equals(29000));
        expect(parsed.merchant, equals('KOPI KENANGAN'));
        expect(parsed.suggestedCategoryId, equals(DefaultCategories.foodId));
      });
    });

    // ---------------------------------------------------------------------------
    // 8. OVO
    // ---------------------------------------------------------------------------
    group('8. OVO Real Notification Samples', () {
      test('parses OVO payment with "Transaksi berhasil!" prefix', () {
        const body = 'Transaksi berhasil! Pembayaran sebesar Rp 45.000 di Chatime berhasil.';
        final parsed = parser.parse(
          body: body,
          appPackage: WatchedApps.ovo.packageNames.first,
          timestamp: testTimestamp,
        );

        expect(parsed, isNotNull);
        expect(parsed!.source, equals('OVO'));
        expect(parsed.amount, equals(45000));
        expect(parsed.merchant, equals('Chatime'));
        expect(parsed.suggestedCategoryId, equals(DefaultCategories.foodId));
      });

      test('parses OVO short "Berhasil bayar" pattern', () {
        const body = 'Berhasil bayar Rp 20.000 di Kopi Kenangan.';
        final parsed = parser.parse(
          body: body,
          appPackage: 'ovo.id',
          timestamp: testTimestamp,
        );

        expect(parsed, isNotNull);
        expect(parsed!.amount, equals(20000));
        expect(parsed.merchant, equals('Kopi Kenangan'));
        expect(parsed.suggestedCategoryId, equals(DefaultCategories.foodId));
      });

      test('parses OVO payment at fast food restaurant', () {
        const body = 'Transaksi berhasil! Pembayaran sebesar Rp 84.000 di BURGER KING berhasil.';
        final parsed = parser.parse(
          body: body,
          appPackage: 'ovo.id',
          timestamp: testTimestamp,
        );

        expect(parsed, isNotNull);
        expect(parsed!.amount, equals(84000));
        expect(parsed.merchant, equals('BURGER KING'));
        expect(parsed.suggestedCategoryId, equals(DefaultCategories.foodId));
      });

      test('parses OVO payment with GrabFood merchant', () {
        const body = 'Pembayaran sebesar Rp 95.000 ke GRABFOOD berhasil.';
        final parsed = parser.parse(
          body: body,
          appPackage: 'ovo.id',
          timestamp: testTimestamp,
        );

        expect(parsed, isNotNull);
        expect(parsed!.amount, equals(95000));
        expect(parsed.merchant, equals('GRABFOOD'));
        expect(parsed.suggestedCategoryId, equals(DefaultCategories.foodId));
      });
    });

    // ---------------------------------------------------------------------------
    // 9. DANA
    // ---------------------------------------------------------------------------
    group('9. DANA Real Notification Samples', () {
      test('parses DANA payment with "Kamu telah bayar" pattern', () {
        const body = 'Pembayaran berhasil! Kamu telah bayar Rp 35.000 ke Kopi Kenangan.';
        final parsed = parser.parse(
          body: body,
          appPackage: WatchedApps.dana.packageNames.first,
          timestamp: testTimestamp,
        );

        expect(parsed, isNotNull);
        expect(parsed!.source, equals('DANA'));
        expect(parsed.amount, equals(35000));
        expect(parsed.merchant, equals('Kopi Kenangan'));
        expect(parsed.suggestedCategoryId, equals(DefaultCategories.foodId));
      });

      test('parses DANA electricity bill payment to PLN', () {
        const body = 'Bayar Rp 50.000 ke PLN Prabayar berhasil.';
        final parsed = parser.parse(
          body: body,
          appPackage: 'id.dana',
          timestamp: testTimestamp,
        );

        expect(parsed, isNotNull);
        expect(parsed!.amount, equals(50000));
        expect(parsed.merchant, equals('PLN Prabayar'));
        expect(parsed.suggestedCategoryId, equals(DefaultCategories.billsId));
      });

      test('parses DANA entertainment movie tickets at XXI', () {
        const body = 'Pembayaran berhasil! Kamu telah bayar Rp 80.000 di XXI CINEMA.';
        final parsed = parser.parse(
          body: body,
          appPackage: 'id.dana',
          timestamp: testTimestamp,
        );

        expect(parsed, isNotNull);
        expect(parsed!.amount, equals(80000));
        expect(parsed.merchant, equals('XXI CINEMA'));
        expect(parsed.suggestedCategoryId, equals(DefaultCategories.entertainmentId));
      });

      test('parses DANA health insurance premium to BPJS', () {
        const body = 'Bayar Rp 25.000 ke BPJS KESEHATAN berhasil.';
        final parsed = parser.parse(
          body: body,
          appPackage: 'id.dana',
          timestamp: testTimestamp,
        );

        expect(parsed, isNotNull);
        expect(parsed!.amount, equals(25000));
        expect(parsed.merchant, equals('BPJS KESEHATAN'));
        expect(parsed.suggestedCategoryId, equals(DefaultCategories.billsId));
      });

      test('parses DANA travel booking to Tiket.com', () {
        const body = 'Bayar Rp 120.000 ke TIKET.COM berhasil.';
        final parsed = parser.parse(
          body: body,
          appPackage: 'id.dana',
          timestamp: testTimestamp,
        );

        expect(parsed, isNotNull);
        expect(parsed!.amount, equals(120000));
        expect(parsed.merchant, equals('TIKET.COM'));
        expect(parsed.suggestedCategoryId, equals(DefaultCategories.transportId));
      });
    });

    // ---------------------------------------------------------------------------
    // 10. Non-Transactional, Security & Promotional Alerts (Negative Tests)
    // ---------------------------------------------------------------------------
    group('10. Non-Transactional & Negative Alerts (Must Return Null)', () {
      test('rejects security OTP & 2FA verification notifications', () {
        const otpAlerts = [
          'JANGAN BERIKAN KODE OTP 492019 kepada siapapun termasuk pihak BCA.',
          'Kode verifikasi Livin by Mandiri Anda adalah 839201. Berlaku 5 menit.',
          'OTP BNI wondr: 729103. Jangan bagikan ke siapapun.',
          'Kode OTP DANA Anda adalah 5521. JANGAN PERNAH MEMBERIKAN KODE INI KE SIAPAPUN.',
          'Kode keamanan OVO Anda: 6291. Hati-hati penipuan.',
          'ShopeePay OTP: 401928 berlaku hingga 15:00 WIB.',
        ];

        for (final alert in otpAlerts) {
          expect(parser.parse(body: alert), isNull, reason: 'Failed for OTP: $alert');
        }
      });

      test('rejects marketing, promo, cashback, and banner notifications', () {
        const promoAlerts = [
          'Diskon hingga 70% dan cashback Rp 50.000 menantimu di promo Shopee 12.12!',
          'Voucher diskon Rp 15.000 sudah masuk ke kantongmu. Yuk jajan di GoFood!',
          'Dapatkan saldo cashback hingga Rp 25.000 dengan bayar tagihan di DANA.',
          'Promo Gajian OVO! Cashback s.d. 30.000 OVO Points di merchant favorit.',
          'Bunga tabungan SeaBank hingga 6% cair setiap hari! Cek saldomu sekarang.',
          'Nikmati bebas biaya transfer antar bank hingga 100x per bulan.',
          'Yuk selesaikan transaksi belanja kamu sebelum promo berakhir!',
        ];

        for (final promo in promoAlerts) {
          expect(parser.parse(body: promo), isNull, reason: 'Failed for Promo: $promo');
        }
      });

      test('rejects account security and settings notifications', () {
        const accountNotifs = [
          'Login berhasil pada perangkat iPhone 13 di Jakarta.',
          'PIN Anda telah berhasil diubah pada 31/10/2026 14:20.',
          'Kartu debit Anda telah berhasil diaktifkan.',
          'Permintaan ubah password Anda telah diproses.',
          'Nomor handphone Anda telah berhasil diperbarui.',
        ];

        for (final notif in accountNotifs) {
          expect(parser.parse(body: notif), isNull, reason: 'Failed for Account Alert: $notif');
        }
      });

      test('rejects zero, negative, or invalid amounts', () {
        expect(parser.parse(body: 'Pembelian di WARUNG Rp 0 berhasil'), isNull);
        expect(parser.parse(body: 'Pembayaran Rp -25.000 di TOKO'), isNull);
        expect(parser.parse(body: 'Transaksi sebesar Rp 0 di INDOMARET'), isNull);
        expect(parser.parse(body: 'Pembayaran QRIS Rp abc.def berhasil'), isNull);
      });
    });

    // ---------------------------------------------------------------------------
    // 11. Edge Cases & Robustness
    // ---------------------------------------------------------------------------
    group('11. Robustness & Edge Cases', () {
      test('handles non-breaking spaces and multi-whitespace gracefully', () {
        const bodyWithSpaces = 'Pembayaran  QRIS   di   KOPI KENANGAN   Rp   28.000   berhasil';
        final parsed = parser.parse(body: bodyWithSpaces, appPackage: 'com.bca');

        expect(parsed, isNotNull);
        expect(parsed!.amount, equals(28000));
        expect(parsed.merchant, equals('KOPI KENANGAN'));
      });

      test('handles lowercased and mixed-case text', () {
        const lowerBody = 'kamu berhasil bayar rp 38.000 ke gofood - ayam geprek bensu.';
        final parsed = parser.parse(body: lowerBody, appPackage: 'com.gojek.app');

        expect(parsed, isNotNull);
        expect(parsed!.amount, equals(38000));
        expect(parsed.merchant, equals('gofood - ayam geprek bensu'));
      });

      test('handles large Indonesian amounts (e.g. tens of millions)', () {
        const bigAmountBody = 'Transaksi debit sebesar Rp 15.500.000 di TOKOPEDIA telah berhasil.';
        final parsed = parser.parse(body: bigAmountBody, appPackage: 'id.co.bankmandiri.livin');

        expect(parsed, isNotNull);
        expect(parsed!.amount, equals(15500000));
        expect(parsed.merchant, equals('TOKOPEDIA'));
        expect(parsed.formattedAmount, equals('Rp 15.500.000'));
      });
    });
  });
}
