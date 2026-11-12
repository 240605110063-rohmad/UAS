/// Satu butir zikir ba'da salat yang diterima dari server.
class ZikirItem {
  const ZikirItem({
    required this.judul,
    required this.arabic,
    required this.latin,
    required this.arti,
    required this.ulang,
  });

  final String judul;
  final String arabic;
  final String latin;
  final String arti;

  /// Jumlah pengulangan, mis. "33x".
  final String ulang;

  factory ZikirItem.fromJson(Map<String, dynamic> json) {
    final judul = (json['judul'] as String?)?.trim() ?? '';
    final arabic = (json['arabic'] as String?)?.trim() ?? '';
    if (judul.isEmpty || arabic.isEmpty) {
      throw const FormatException('Butir zikir tidak lengkap');
    }
    return ZikirItem(
      judul: judul,
      arabic: arabic,
      latin: (json['latin'] as String?)?.trim() ?? '',
      arti: (json['arti'] as String?)?.trim() ?? '',
      ulang: (json['ulang'] as String?)?.trim() ?? '',
    );
  }
}

/// Kumpulan zikir ba'da salat beserta sumbernya.
class ZikirSet {
  const ZikirSet({
    required this.judul,
    required this.sumber,
    required this.items,
  });

  final String judul;
  final String sumber;
  final List<ZikirItem> items;

  factory ZikirSet.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    if (rawItems is! List || rawItems.isEmpty) {
      throw const FormatException('Daftar zikir kosong');
    }
    final items = rawItems
        .whereType<Map<String, dynamic>>()
        .map(ZikirItem.fromJson)
        .toList(growable: false);
    if (items.isEmpty) {
      throw const FormatException('Daftar zikir tidak valid');
    }
    return ZikirSet(
      judul: (json['judul'] as String?)?.trim().isNotEmpty == true
          ? (json['judul'] as String).trim()
          : "Zikir Ba'da Salat",
      sumber: (json['sumber'] as String?)?.trim() ?? '',
      items: items,
    );
  }
}
