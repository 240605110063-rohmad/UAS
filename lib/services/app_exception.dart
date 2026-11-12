/// Exception domain aplikasi.
///
/// Setiap kegagalan dipetakan ke tipe yang berbeda agar UI dapat menampilkan
/// pesan sesuai penyebabnya (bukan selalu "kota tidak ditemukan").
sealed class AppException implements Exception {
  const AppException(this.message);

  /// Pesan siap tampil untuk pengguna.
  final String message;

  @override
  String toString() => message;
}

/// API key belum dikonfigurasi saat build/run.
class ApiKeyMissingException extends AppException {
  const ApiKeyMissingException()
    : super(
        'API key OpenWeatherMap belum dikonfigurasi. Jalankan aplikasi dengan '
        '--dart-define-from-file=env.json (atau '
        '--dart-define=OPENWEATHER_API_KEY=<kunci-anda>).',
      );
}

/// API key ditolak server (HTTP 401).
class ApiKeyInvalidException extends AppException {
  const ApiKeyInvalidException()
    : super(
        'API key OpenWeatherMap ditolak (HTTP 401). Periksa kembali kunci API '
        'yang digunakan.',
      );
}

/// Nama kota/lokasi tidak ditemukan oleh layanan geocoding.
class LocationNotFoundException extends AppException {
  LocationNotFoundException(this.query)
    : super(
        'Lokasi "$query" tidak ditemukan. Periksa ejaan nama kota, atau '
        'gunakan tombol lokasi saya.',
      );

  final String query;
}

/// Gagal menghubungi server (offline, DNS, timeout, koneksi diputus).
class NetworkException extends AppException {
  const NetworkException([
    super.message =
        'Tidak dapat terhubung ke server cuaca. Periksa koneksi internet '
        'Anda lalu coba lagi.',
  ]);
}

/// Server merespons dengan status error.
class ServerException extends AppException {
  ServerException(this.statusCode)
    : super(
        'Server cuaca sedang bermasalah (HTTP $statusCode). '
        'Coba lagi beberapa saat lagi.',
      );

  final int statusCode;
}

/// Batas kuota permintaan API tercapai.
class RateLimitException extends AppException {
  const RateLimitException()
    : super(
        'Batas permintaan API tercapai (HTTP 429). Tunggu beberapa saat lalu '
        'coba lagi.',
      );
}

/// Respons server tidak sesuai format yang diharapkan.
class InvalidResponseException extends AppException {
  const InvalidResponseException([
    super.message = 'Respons server cuaca tidak dapat dibaca. Coba lagi.',
  ]);
}

enum LocationFailureReason {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  unavailable,
  timeout,
}

/// Kegagalan layanan lokasi perangkat (GPS/izin).
class LocationFailure extends AppException {
  const LocationFailure(this.reason, super.message);

  final LocationFailureReason reason;
}
