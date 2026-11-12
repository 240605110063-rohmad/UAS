/// Konfigurasi endpoint OpenWeatherMap.
///
/// API key TIDAK disimpan di source code. Nilai dibaca dari compile-time
/// environment variable yang diberikan lewat `--dart-define`:
///
/// ```
/// flutter run --dart-define=OPENWEATHER_API_KEY=<kunci-anda>
/// ```
///
/// atau dari file yang tidak di-commit:
///
/// ```
/// flutter run --dart-define-from-file=env.json
/// ```
class ApiConfig {
  const ApiConfig._();

  static const String openWeatherApiKey = String.fromEnvironment(
    'OPENWEATHER_API_KEY',
  );

  static const String host = 'api.openweathermap.org';

  static const String currentWeatherPath = '/data/2.5/weather';
  static const String forecastPath = '/data/2.5/forecast';
  static const String geocodingDirectPath = '/geo/1.0/direct';
  static const String geocodingReversePath = '/geo/1.0/reverse';

  static bool get hasApiKey => openWeatherApiKey.trim().isNotEmpty;

  /// Endpoint JSON zikir ba'da salat (data statis di server).
  ///
  /// Bisa diganti dengan URL server kampus/repositori sendiri tanpa mengubah
  /// kode lain, selama format JSON-nya sama.
  static const String zikirUrl = 'https://api.pastes.dev/r8hMzByuMe';
}
