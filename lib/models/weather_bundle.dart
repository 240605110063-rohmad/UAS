import 'forecast.dart';
import 'geo_place.dart';
import 'weather.dart';

/// Gabungan data cuaca saat ini dan prakiraan 5 hari untuk satu lokasi.
class WeatherBundle {
  const WeatherBundle({
    required this.weather,
    required this.forecast,
    required this.locationLabel,
    this.place,
  });

  final Weather weather;
  final List<DailyForecast> forecast;

  /// Label lokasi yang ditampilkan ke pengguna.
  final String locationLabel;

  /// Detail tempat hasil geocoding/reverse geocoding (bisa null).
  final GeoPlace? place;
}
