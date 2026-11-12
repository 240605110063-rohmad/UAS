/// Koordinat perangkat hasil pembacaan GPS.
class DeviceLocation {
  const DeviceLocation({
    required this.latitude,
    required this.longitude,
    this.accuracy,
  });

  final double latitude;
  final double longitude;

  /// Akurasi dalam meter (null jika tidak tersedia).
  final double? accuracy;
}
