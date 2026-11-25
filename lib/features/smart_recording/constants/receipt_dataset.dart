/// Comprehensive dataset and taxonomy of Indonesian retail receipts.
///
/// Contains known consumer brands, corporate legal entities, transaction keyword taxonomies,
/// item units, tax and summary indicators, and non-transaction noise patterns.
abstract final class ReceiptDataset {
  /// Maps Indonesian legal corporate entity names to recognizable consumer brand names.
  static const Map<String, String> legalEntityToBrand = {
    'INDOMARCO PRISMATAMA': 'Indomaret',
    'SUMBER ALFARIA TRIJAYA': 'Alfamart',
    'MIDI UTAMA INDONESIA': 'Alfamidi',
    'LION SUPER INDO': 'Super Indo',
    'HERO SUPERMARKET': 'Hero',
    'FAST FOOD INDONESIA': 'KFC',
    'REKSO NASIONAL FOOD': 'McDonald\'s',
    'SARIMELATI KENCANA': 'Pizza Hut',
    'SARI BURGER INDONESIA': 'Burger King',
    'BUMI BERKAH BOGA': 'Kopi Kenangan',
    'INTI CAKRALOKA': 'Fore Coffee',
    'MAP BOGA ADIPERKASA': 'Starbucks',
    'TRANS RETAIL INDONESIA': 'Transmart',
    'MATAHARI DEPARTMENT STORE': 'Matahari',
    'ACE HARDWARE INDONESIA': 'ACE Hardware',
    'ASPIRASI HIDUP INDONESIA': 'ACE Hardware',
    'DUTA INTIDAYA': 'Watsons',
    'GUARDIAN PHARMACIA': 'Guardian',
    'KIMIA FARMA APOTEK': 'Kimia Farma',
    'PERTAMINA PATRA NIAGA': 'SPBU Pertamina',
    'SHELL INDONESIA': 'Shell',
    'TOUS LES JOURS INDONESIA': 'Tous Les Jours',
    'TALENTA BOGA INDONESIA': 'Janji Jiwa',
    'CHATIME INDONESIA': 'Chatime',
    'PIONIRBETON INDUSTRI': 'Pionir',
    'INDOMARCO ADI PRIMA': 'Indomaret',
    'J.CO DONUTS': 'J.CO Donuts',
    'ROTI O': 'Roti\'O',
    'HOLLAND BAKERY': 'Holland Bakery',
    'BAKMI GM': 'Bakmi GM',
    'SOLARIA JAYA ABADI': 'Solaria',
    'HOKA HOKA BENTO': 'HokBen',
    'YOSHINOYA INDONESIA': 'Yoshinoya',
    'MARUGAME UDON INDONESIA': 'Marugame Udon',
    'SUSHI TEI INDONESIA': 'Sushi Tei',
  };

  /// Hundreds of known Indonesian merchant brand keywords across all consumer sectors.
  static const List<String> knownBrands = [
    // Convenience Stores & Minimarkets
    'indomaret',
    'alfamart',
    'alfamidi',
    'circle k',
    'lawson',
    'familymart',
    'bright store',
    'dandan',

    // Supermarkets & Hypermarkets
    'superindo',
    'super indo',
    'hypermart',
    'carrefour',
    'transmart',
    'hero',
    'ranch market',
    'farmers market',
    'grand lucky',
    'the foodhall',
    'foodhall',
    'lotte mart',
    'papaya fresh gallery',
    'papaya fresh market',
    'naga swalayan',
    'tip top',
    'hari hari swalayan',
    'borma',
    'yogya',
    'griya',
    'luwes',

    // Coffee & Beverages
    'kopi kenangan',
    'janji jiwa',
    'fore coffee',
    'point coffee',
    'tuku',
    'starbucks',
    'tomoro coffee',
    'flash coffee',
    'excelso',
    'maxx coffee',
    'chatime',
    'haus!',
    'haus',
    'teguk',
    'mixue',
    'xi bo ba',
    'kokumi',
    'xing fu tang',
    'dum dum',
    'menantea',
    'gulu gulu',

    // Fast Food & Dining
    'mcdonald',
    'kfc',
    'a&w',
    'burger king',
    'richeese factory',
    'cfc',
    'texas chicken',
    'wingstop',
    'wendy\'s',
    'wendys',
    'carl\'s jr',
    'popeyes',
    'hokben',
    'hoka hoka bento',
    'yoshinoya',
    'marugame udon',
    'marugame',
    'sushi tei',
    'genki sushi',
    'ichiban sushi',
    'pepper lunch',
    'shaburi',
    'kintan buffet',
    'hanamasa',
    'solaria',
    'd\'cost',
    'dcost',
    'platinum',
    'gokana',
    'ta wan',
    'imperial kitchen',
    'bakmi gm',
    'bakso lapangan tembak',
    'bakso afung',
    'es teler 77',
    'ayam geprek bensu',
    'bebek kaleyo',
    'sederhana',
    'restoran sederhana',
    'garuda',
    'pagi sore',
    'sari ratu',
    'natrabu',
    'pizza hut',
    'domino\'s pizza',
    'dominos pizza',
    'phd',

    // Bakeries & Snacks
    'j.co',
    'jco',
    'dunkin',
    'roti\'o',
    'rotio',
    'roti boy',
    'breadtalk',
    'mako',
    'tous les jours',
    'holland bakery',
    'kartika sari',
    'prima rasa',
    'amanda brownies',
    'the harvest',
    'clairmont',

    // Pharmacies, Health & Beauty
    'guardian',
    'watsons',
    'century',
    'kimia farma',
    'k-24',
    'k24',
    'apotek roxy',
    'apotek',
    'sociolla',
    'sephora',
    'the body shop',

    // Lifestyle, Fashion, Bookstores & Department Stores
    'gramedia',
    'gunung agung',
    'matahari',
    'ramayana',
    'sogo',
    'seibu',
    'metro',
    'uniqlo',
    'h&m',
    'zara',
    'pull&bear',
    'stradivarius',
    'bershka',
    'cotton on',
    'miniso',
    'kkv',
    'scoop',

    // Home Improvement & Electronics
    'ace hardware',
    'mr diy',
    'mr. diy',
    'ikea',
    'informa',
    'mitra10',
    'depo bangunan',
    'electronic city',
    'erafone',
    'ibox',
    'digimap',

    // Fuel & Transport
    'pertamina',
    'spbu',
    'shell',
    'bp akr',
    'vivo energy',

    // Entertainment & Leisure
    'cinema xxi',
    'xxi',
    'cgv',
    'cinepolis',
    'timezone',
    'funworld',
  ];

  /// Common units used in line items to express quantity or measurement.
  static const List<String> quantityUnits = [
    'x',
    '@',
    'pcs',
    'pc',
    'bh',
    'buah',
    'pax',
    'cup',
    'btl',
    'btg',
    'kg',
    'gr',
    'g',
    'pack',
    'dus',
    'bks',
    'ktk',
    'ptg',
    'lbr',
    'lembar',
    'porsi',
    'kaleng',
    'klg',
    'sachet',
    'sch',
  ];

  /// Keywords indicating the grand total or final bill payable.
  static const List<String> grandTotalKeywords = [
    'GRAND TOTAL',
    'TOTAL BELANJA',
    'TOTAL HARGA',
    'TOTAL BAYAR',
    'TOTAL AKHIR',
    'TOTAL TAGIHAN',
    'JUMLAH AKHIR',
    'JUMLAH BAYAR',
    'TOTAL TRANSAKSI',
    'HARGA JUAL',
    'NETTO',
    'TOTAL',
  ];

  /// Keywords indicating intermediate subtotals.
  static const List<String> subtotalKeywords = [
    'SUBTOTAL',
    'SUB TOTAL',
    'JUMLAH',
    'TAGIHAN',
  ];

  /// Keywords indicating discounts, vouchers, promotions, or cashback.
  static const List<String> discountKeywords = [
    'DISKON',
    'DISCOUNT',
    'POTONGAN',
    'HEMAT',
    'PROMO',
    'VOUCHER',
    'CASHBACK',
    'REBATE',
  ];

  /// Keywords indicating tax, service charge, and rounding adjustments.
  static const List<String> taxAndFeeKeywords = [
    'PPN',
    'PB1',
    'PAJAK',
    'TAX',
    'SERVICE CHARGE',
    'SERVICE',
    'BIAYA LAYANAN',
    'PEMBULATAN',
    'ROUNDING',
    'ONGKIR',
    'DELIVERY FEE',
  ];

  /// Keywords indicating cash tendered or change returned (not the total expense).
  static const List<String> paymentTenderKeywords = [
    'TUNAI',
    'CASH',
    'KEMBALI',
    'KEMBALIAN',
    'CHANGE',
    'BAYAR TUNAI',
    'UANG MUKA',
    'DITERIMA',
  ];

  /// Keywords indicating payment methods and card transaction details.
  static const List<String> paymentMethodKeywords = [
    'DEBIT BCA',
    'DEBIT MANDIRI',
    'DEBIT BRI',
    'DEBIT BNI',
    'KARTU DEBIT',
    'KARTU KREDIT',
    'CREDIT CARD',
    'QRIS',
    'GOPAY',
    'OVO',
    'DANA',
    'SHOPEEPAY',
    'LINKAJA',
    'KREDIVO',
    'AKULAKU',
    'CARD NO',
    'PAN:',
    'AUTH CODE',
    'APPR CODE',
    'MID:',
    'TID:',
    'BATCH NO',
    'TRACE NO',
    'REF NO',
  ];

  /// Keywords indicating non-transaction administrative or store noise.
  static const List<String> noiseKeywords = [
    'NPWP',
    'NPPKP',
    'TAX ID',
    'SIUP',
    'TDP',
    'NIB',
    'KASIR',
    'CASHIER',
    'OPERATOR',
    'POS#',
    'POS #',
    'POS ',
    'TERMINAL',
    'SHIFT',
    'REGISTER',
    'NO. STRUK',
    'NO STRUK',
    'TRX#',
    'INVOICE',
    'BILL NO',
    'ORDER NO',
    'TABLE',
    'MEJA',
    'ANTRIAN',
    'QUEUE',
    'TERIMA KASIH',
    'THANK YOU',
    'SELAMAT DATANG',
    'SELAMAT MENIKMATI',
    'BARANG YANG SUDAH DIBELI',
    'TIDAK DAPAT DITUKAR',
    'KRITIK & SARAN',
    'KRITIK DAN SARAN',
    'WIFI',
    'PASSWORD',
    'DOWNLOAD APLIKASI',
    'PLAY STORE',
    'APP STORE',
    'MEMBER ID',
    'POIN',
  ];

  /// Resolves a merchant name from a string that might be a known brand or a legal entity.
  static String? resolveMerchant(String text) {
    final clean = text.trim();
    if (clean.isEmpty) return null;

    final upper = clean.toUpperCase();

    // Check legal entities first
    for (final entry in legalEntityToBrand.entries) {
      if (upper.contains(entry.key)) {
        return entry.value;
      }
    }

    // Check known brands
    final lower = clean.toLowerCase();
    for (final brand in knownBrands) {
      if (lower.contains(brand)) {
        return _formatBrandName(brand);
      }
    }

    return null;
  }

  static String _formatBrandName(String brand) {
    return brand
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }
}
