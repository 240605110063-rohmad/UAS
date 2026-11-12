/// Hasil geocoding: nama tempat beserta koordinatnya.
class GeoPlace {
  const GeoPlace({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.state,
    this.country,
  });

  final String name;
  final double latitude;
  final double longitude;
  final String? state;
  final String? country;

  factory GeoPlace.fromJson(Map<String, dynamic> json) {
    final latitude = (json['lat'] as num).toDouble();
    final longitude = (json['lon'] as num).toDouble();
    return GeoPlace(
      name: (json['name'] as String?)?.trim() ?? '',
      latitude: latitude,
      longitude: longitude,
      state: (json['state'] as String?)?.trim(),
      country: (json['country'] as String?)?.trim(),
    );
  }

  /// Contoh: "Kota Malang, East Java, ID".
  String get displayName {
    final parts = <String>[
      if (name.isNotEmpty) name,
      if (state != null && state!.isNotEmpty) state!,
      if (country != null && country!.isNotEmpty) country!,
    ];
    return parts.isEmpty ? 'Lokasi tidak dikenal' : parts.join(', ');
  }

  /// Contoh: "-7.977, 112.634".
  String get coordinateLabel =>
      '${latitude.toStringAsFixed(3)}, ${longitude.toStringAsFixed(3)}';
}
