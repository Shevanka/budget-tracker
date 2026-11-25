import 'package:flutter_test/flutter_test.dart';
import 'package:budget_tracker/features/notification_watcher/constants/watched_apps.dart';
import 'package:budget_tracker/features/notification_watcher/services/notification_parser.dart';

void main() {
  group('Modern Indonesian Financial Notifications & Multi-format Parser', () {
    const parser = NotificationParser();

    test('parses modern GoPay standalone app notifications (amount first)', () {
      final parsed = parser.parse(
        body: 'Kamu bayar Rp25.000 di Kopi Kenangan pakai GoPay',
        title: 'Transaksi Berhasil',
        appPackage: 'com.gojek.gopay',
      );
      expect(parsed, isNotNull);
      expect(parsed!.amount, equals(25000));
      expect(parsed.merchant, equals('Kopi Kenangan'));
      expect(parsed.source, equals('GoPay'));
    });

    test('parses modern GoPay app notifications (merchant first)', () {
      final parsed = parser.parse(
        body: 'Pembayaran ke Chatime sebesar Rp 30.000 berhasil',
        title: 'GoPay',
        appPackage: 'com.gojek.gopay',
      );
      expect(parsed, isNotNull);
      expect(parsed!.amount, equals(30000));
      expect(parsed.merchant, equals('Chatime'));
      expect(parsed.source, equals('GoPay'));
    });

    test('parses modern myBCA Omni notification (amount first)', () {
      final parsed = parser.parse(
        body: 'Pembayaran QRIS Rp 45.000 di Fore Coffee berhasil.',
        title: 'myBCA',
        appPackage: 'com.bca.mybca.omni.android',
      );
      expect(parsed, isNotNull);
      expect(parsed!.amount, equals(45000));
      expect(parsed.merchant, equals('Fore Coffee'));
      expect(parsed.source, equals('BCA'));
    });

    test('parses myBCA notification (merchant first)', () {
      final parsed = parser.parse(
        body: 'Pembayaran di Janji Jiwa sebesar Rp 18.000 sukses',
        title: 'myBCA',
        appPackage: 'com.bca.mybca.omni.android',
      );
      expect(parsed, isNotNull);
      expect(parsed!.amount, equals(18000));
      expect(parsed.merchant, equals('Janji Jiwa'));
      expect(parsed.source, equals('BCA'));
    });

    test('parses BRImo notifications', () {
      final parsed = parser.parse(
        body: 'Transaksi QRIS Rp 54.000 di Alfamart berhasil.',
        title: 'BRImo',
        appPackage: 'id.co.bri.brimo',
      );
      expect(parsed, isNotNull);
      expect(parsed!.amount, equals(54000));
      expect(parsed.merchant, equals('Alfamart'));
      expect(parsed.source, equals('BRI'));
    });

    test('parses Bank Jago notifications', () {
      final parsed = parser.parse(
        body: 'Kamu telah membayar Rp 35.000 ke Starbucks',
        title: 'Bank Jago',
        appPackage: 'com.jago.digitalBanking',
      );
      expect(parsed, isNotNull);
      expect(parsed!.amount, equals(35000));
      expect(parsed.merchant, equals('Starbucks'));
      expect(parsed.source, equals('Bank Jago'));
    });

    test('parses Flip notifications', () {
      final parsed = parser.parse(
        body: 'Transaksi transfer Rp 150.000 ke Budi Santoso berhasil',
        title: 'Flip',
        appPackage: 'id.flip',
      );
      expect(parsed, isNotNull);
      expect(parsed!.amount, equals(150000));
      expect(parsed.merchant, equals('Budi Santoso'));
      expect(parsed.source, equals('Flip'));
    });

    test('parses DANA notifications with leading celebration text', () {
      final parsed = parser.parse(
        body: 'Pembayaran berhasil! Kamu telah bayar Rp 22.000 ke Indomaret',
        title: 'DANA',
        appPackage: 'id.dana',
      );
      expect(parsed, isNotNull);
      expect(parsed!.amount, equals(22000));
      expect(parsed.merchant, equals('Indomaret'));
      expect(parsed.source, equals('DANA'));
    });

    test('parses fallback generic rules for unknown packages with financial text', () {
      final parsed = parser.parse(
        body: 'Transaksi pembayaran Rp 75.000 di SOLARIA sukses!',
        title: 'Notifikasi Bank',
        appPackage: 'com.custom.bankapp',
      );
      expect(parsed, isNotNull);
      expect(parsed!.amount, equals(75000));
      expect(parsed.merchant, equals('SOLARIA'));
    });

    test('recognizes all modern Indonesian packages in WatchedApps', () {
      expect(WatchedApps.isWatchedPackage('com.bca.mybca.omni.android'), isTrue);
      expect(WatchedApps.isWatchedPackage('com.gojek.gopay'), isTrue);
      expect(WatchedApps.isWatchedPackage('com.jago.digitalBanking'), isTrue);
      expect(WatchedApps.isWatchedPackage('id.co.bri.brimo'), isTrue);
      expect(WatchedApps.isWatchedPackage('id.flip'), isTrue);
      expect(WatchedApps.isWatchedPackage('id.co.btn.mobilebanking.android'), isTrue);
    });
  });
}
