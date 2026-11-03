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
  bool matches(String packageName) => packageNames.contains(packageName.trim().toLowerCase());
}

/// Central registry of supported Indonesian banks and e-wallets.
abstract final class WatchedApps {
  static const bca = WatchedApp(
    id: 'bca',
    name: 'BCA (myBCA / BCA Mobile)',
    type: InstitutionType.bank,
    packageNames: ['com.bca', 'com.bca.mybca'],
  );

  static const mandiri = WatchedApp(
    id: 'mandiri',
    name: 'Bank Mandiri (Livin)',
    type: InstitutionType.bank,
    packageNames: ['id.co.bankmandiri.livin'],
  );

  static const bni = WatchedApp(
    id: 'bni',
    name: 'BNI (Mobile / wondr)',
    type: InstitutionType.bank,
    packageNames: ['id.co.bni.mobilebanking', 'id.co.bni.wondr'],
  );

  static const btn = WatchedApp(
    id: 'btn',
    name: 'BTN Mobile',
    type: InstitutionType.bank,
    packageNames: ['id.co.btn.mobilebanking'],
  );

  static const seaBank = WatchedApp(
    id: 'seabank',
    name: 'SeaBank',
    type: InstitutionType.bank,
    packageNames: ['com.seabank.id'],
  );

  static const shopeePay = WatchedApp(
    id: 'shopeepay',
    name: 'ShopeePay',
    type: InstitutionType.eWallet,
    packageNames: ['com.shopee.id', 'com.shopeepay.id'],
  );

  static const goPay = WatchedApp(
    id: 'gopay',
    name: 'GoPay / Gojek',
    type: InstitutionType.eWallet,
    packageNames: ['com.gojek.app', 'id.co.gopay'],
  );

  static const ovo = WatchedApp(
    id: 'ovo',
    name: 'OVO',
    type: InstitutionType.eWallet,
    packageNames: ['ovo.id'],
  );

  static const dana = WatchedApp(
    id: 'dana',
    name: 'DANA',
    type: InstitutionType.eWallet,
    packageNames: ['id.dana'],
  );

  /// All supported banking and e-wallet applications.
  static const allApps = [
    bca,
    mandiri,
    bni,
    btn,
    seaBank,
    shopeePay,
    goPay,
    ovo,
    dana,
  ];

  /// Set of all lowercase package names watched by the listener service.
  static final Set<String> allPackageNames = {
    for (final app in allApps) ...app.packageNames.map((p) => p.toLowerCase()),
  };

  /// Checks whether [packageName] matches any registered banking or e-wallet application.
  static bool isWatchedPackage(String? packageName) {
    if (packageName == null || packageName.isEmpty) return false;
    return allPackageNames.contains(packageName.trim().toLowerCase());
  }

  /// Finds the [WatchedApp] matching [packageName], or `null` if none matches.
  static WatchedApp? findByPackage(String? packageName) {
    if (packageName == null || packageName.isEmpty) return null;
    final lower = packageName.trim().toLowerCase();
    for (final app in allApps) {
      if (app.packageNames.contains(lower)) {
        return app;
      }
    }
    return null;
  }
}
