import 'package:budget_tracker/features/notification_watcher/constants/watched_apps.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WatchedApps Constants & Registry Tests', () {
    test('contains all 18 Indonesian banking and e-wallet applications', () {
      expect(WatchedApps.allApps.length, 18);

      final appIds = WatchedApps.allApps.map((a) => a.id).toSet();
      expect(appIds, containsAll([
        'bca',
        'mandiri',
        'bni',
        'bri',
        'btn',
        'jago',
        'seabank',
        'bsi',
        'cimb',
        'jenius',
        'permata',
        'flip',
        'yup',
        'shopeepay',
        'gopay',
        'ovo',
        'dana',
        'linkaja',
      ]));
    });

    test('isWatchedPackage correctly identifies supported banking apps', () {
      expect(WatchedApps.isWatchedPackage('com.bca'), isTrue);
      expect(WatchedApps.isWatchedPackage('com.bca.mybca'), isTrue);
      expect(WatchedApps.isWatchedPackage('id.co.bankmandiri.livin'), isTrue);
      expect(WatchedApps.isWatchedPackage('id.co.bni.mobilebanking'), isTrue);
      expect(WatchedApps.isWatchedPackage('id.co.bni.wondr'), isTrue);
      expect(WatchedApps.isWatchedPackage('id.co.bri.brimo'), isTrue);
      expect(WatchedApps.isWatchedPackage('id.co.btn.mobilebanking'), isTrue);
      expect(WatchedApps.isWatchedPackage('com.jago.digitalBanking'), isTrue);
      expect(WatchedApps.isWatchedPackage('com.seabank.id'), isTrue);
    });

    test('isWatchedPackage correctly identifies supported e-wallets', () {
      expect(WatchedApps.isWatchedPackage('com.shopee.id'), isTrue);
      expect(WatchedApps.isWatchedPackage('com.shopeepay.id'), isTrue);
      expect(WatchedApps.isWatchedPackage('com.gojek.app'), isTrue);
      expect(WatchedApps.isWatchedPackage('id.co.gopay'), isTrue);
      expect(WatchedApps.isWatchedPackage('com.gojek.gopay'), isTrue);
      expect(WatchedApps.isWatchedPackage('ovo.id'), isTrue);
      expect(WatchedApps.isWatchedPackage('id.dana'), isTrue);
      expect(WatchedApps.isWatchedPackage('id.flip'), isTrue);
    });

    test('isWatchedPackage returns false for non-financial or null packages', () {
      expect(WatchedApps.isWatchedPackage('com.whatsapp'), isFalse);
      expect(WatchedApps.isWatchedPackage('com.instagram.android'), isFalse);
      expect(WatchedApps.isWatchedPackage(''), isFalse);
      expect(WatchedApps.isWatchedPackage(null), isFalse);
    });

    test('findByPackage returns matching WatchedApp or null', () {
      final bca = WatchedApps.findByPackage('com.bca.mybca');
      expect(bca, isNotNull);
      expect(bca!.name, contains('BCA'));
      expect(bca.type, InstitutionType.bank);

      final gopay = WatchedApps.findByPackage('com.gojek.app');
      expect(gopay, isNotNull);
      expect(gopay!.name, contains('GoPay'));
      expect(gopay.type, InstitutionType.eWallet);

      final bri = WatchedApps.findByPackage('id.co.bri.brimo');
      expect(bri, isNotNull);
      expect(bri!.name, contains('BRI'));

      expect(WatchedApps.findByPackage('com.unrelated.app'), isNull);
      expect(WatchedApps.findByPackage(null), isNull);
    });
  });
}
