/// Category type of financial institution.
enum InstitutionType {
  bank,
  eWallet,
}

/// Metadata and identification for an Indonesian bank or e-wallet supported by the notification watcher.
class WatchedApp {
  final String id;
  final String name;
  final InstitutionType type;
  final List<String> packageNames;

  const WatchedApp({
    required this.id,
    required this.name,
    required this.type,
    required this.packageNames,
  });

  /// Whether [packageName] belongs to this app.
  bool matches(String packageName) {
    final lower = packageName.trim().toLowerCase();
    return packageNames.any((p) => p.toLowerCase() == lower);
  }
}

/// Central registry of supported Indonesian banks and e-wallets.
abstract final class WatchedApps {
  static const bca = WatchedApp(
    id: 'bca',
    name: 'BCA (myBCA / BCA Mobile / Blu)',
    type: InstitutionType.bank,
    packageNames: [
      'com.bca',
      'com.bca.mybca',
      'com.bca.mybca.omni.android',
      'id.co.bcadigital.blu',
    ],
  );

  static const mandiri = WatchedApp(
    id: 'mandiri',
    name: 'Bank Mandiri (Livin)',
    type: InstitutionType.bank,
    packageNames: [
      'id.co.bankmandiri.livin',
      'com.bankmandiri.livin',
    ],
  );

  static const bni = WatchedApp(
    id: 'bni',
    name: 'BNI (Mobile / wondr)',
    type: InstitutionType.bank,
    packageNames: [
      'id.co.bni.mobilebanking',
      'id.co.bni.wondr',
    ],
  );

  static const bri = WatchedApp(
    id: 'bri',
    name: 'BRI (BRImo)',
    type: InstitutionType.bank,
    packageNames: [
      'id.co.bri.brimo',
      'id.co.bri.mobilebanking',
    ],
  );

  static const btn = WatchedApp(
    id: 'btn',
    name: 'BTN Mobile',
    type: InstitutionType.bank,
    packageNames: [
      'id.co.btn.mobilebanking',
      'id.co.btn.mobilebanking.android',
    ],
  );

  static const jago = WatchedApp(
    id: 'jago',
    name: 'Bank Jago',
    type: InstitutionType.bank,
    packageNames: [
      'com.jago.digitalBanking',
      'com.jago.digitalbanking',
    ],
  );

  static const seaBank = WatchedApp(
    id: 'seabank',
    name: 'SeaBank',
    type: InstitutionType.bank,
    packageNames: [
      'com.seabank.id',
    ],
  );

  static const bsi = WatchedApp(
    id: 'bsi',
    name: 'BSI Mobile',
    type: InstitutionType.bank,
    packageNames: [
      'com.bsi.mobile',
    ],
  );

  static const cimb = WatchedApp(
    id: 'cimb',
    name: 'CIMB Niaga (OCTO Mobile)',
    type: InstitutionType.bank,
    packageNames: [
      'id.co.cimbniaga.mobile.android',
    ],
  );

  static const jenius = WatchedApp(
    id: 'jenius',
    name: 'Jenius (BTPN)',
    type: InstitutionType.bank,
    packageNames: [
      'com.btpn.dc',
    ],
  );

  static const permata = WatchedApp(
    id: 'permata',
    name: 'PermataBank (PermataME)',
    type: InstitutionType.bank,
    packageNames: [
      'id.co.permatabank.mobile.android',
    ],
  );

  static const flip = WatchedApp(
    id: 'flip',
    name: 'Flip',
    type: InstitutionType.eWallet,
    packageNames: [
      'id.flip',
    ],
  );

  static const yup = WatchedApp(
    id: 'yup',
    name: 'Yup',
    type: InstitutionType.eWallet,
    packageNames: [
      'com.yup.bank.digital.kartu.kredit.debit.pascabayar.pinjaman.investasi',
    ],
  );

  static const shopeePay = WatchedApp(
    id: 'shopeepay',
    name: 'ShopeePay',
    type: InstitutionType.eWallet,
    packageNames: [
      'com.shopee.id',
      'com.shopeepay.id',
    ],
  );

  static const goPay = WatchedApp(
    id: 'gopay',
    name: 'GoPay / Gojek',
    type: InstitutionType.eWallet,
    packageNames: [
      'com.gojek.app',
      'id.co.gopay',
      'com.gojek.gopay',
      'com.gojek.gopaymerchant',
    ],
  );

  static const ovo = WatchedApp(
    id: 'ovo',
    name: 'OVO',
    type: InstitutionType.eWallet,
    packageNames: [
      'ovo.id',
    ],
  );

  static const dana = WatchedApp(
    id: 'dana',
    name: 'DANA',
    type: InstitutionType.eWallet,
    packageNames: [
      'id.dana',
    ],
  );

  static const linkAja = WatchedApp(
    id: 'linkaja',
    name: 'LinkAja',
    type: InstitutionType.eWallet,
    packageNames: [
      'com.telkom.mwallet',
    ],
  );

  /// All supported banking and e-wallet applications.
  static const allApps = [
    bca,
    mandiri,
    bni,
    bri,
    btn,
    jago,
    seaBank,
    bsi,
    cimb,
    jenius,
    permata,
    flip,
    yup,
    shopeePay,
    goPay,
    ovo,
    dana,
    linkAja,
  ];

  /// Set of all lowercase package names watched by the listener service.
  static final Set<String> allPackageNames = {
    for (final app in allApps) ...app.packageNames.map((p) => p.toLowerCase()),
  };

  /// Checks whether [packageName] matches any registered banking or e-wallet application,
  /// or contains recognizable financial keywords.
  static bool isWatchedPackage(String? packageName) {
    if (packageName == null || packageName.isEmpty) return false;
    final lower = packageName.trim().toLowerCase();
    if (allPackageNames.contains(lower)) return true;

    // Intelligent heuristic for banking/payment package variants
    return lower.contains('bca') ||
        lower.contains('mandiri') ||
        lower.contains('bni') ||
        lower.contains('brimo') ||
        lower.contains('bri.') ||
        lower.contains('btn.') ||
        lower.contains('seabank') ||
        lower.contains('shopee') ||
        lower.contains('gopay') ||
        lower.contains('gojek') ||
        lower.contains('ovo') ||
        lower.contains('dana') ||
        lower.contains('jago') ||
        lower.contains('flip') ||
        lower.contains('cimb') ||
        lower.contains('bsi') ||
        lower.contains('jenius') ||
        lower.contains('bank') ||
        lower.contains('fintech') ||
        lower.contains('wallet');
  }

  /// Finds the [WatchedApp] matching [packageName], or `null` if none matches.
  static WatchedApp? findByPackage(String? packageName) {
    if (packageName == null || packageName.isEmpty) return null;
    final lower = packageName.trim().toLowerCase();
    for (final app in allApps) {
      if (app.packageNames.any((p) => p.toLowerCase() == lower)) {
        return app;
      }
    }
    // Fallback heuristic if package contains known identifier
    for (final app in allApps) {
      if (lower.contains(app.id)) {
        return app;
      }
    }
    return null;
  }
}
