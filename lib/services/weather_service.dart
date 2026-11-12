import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/forecast.dart';
import '../models/geo_place.dart';
import '../models/weather.dart';
import '../models/weather_bundle.dart';
import 'app_exception.dart';

/// Service tunggal untuk semua komunikasi dengan OpenWeatherMap.
///
/// Semua permintaan cuaca memakai koordinat latitude/longitude:
/// - pencarian manual: nama kota -> geocoding -> koordinat -> cuaca
/// - geolocation: koordinat GPS -> cuaca
class WeatherService {
  WeatherService({
    http.Client? client,
    String? apiKey,
    this.timeout = const Duration(seconds: 20),
  }) : _client = client ?? http.Client(),
       _apiKey = (apiKey ?? ApiConfig.openWeatherApiKey).trim();

  final http.Client _client;
  final String _apiKey;
  final Duration timeout;

  void dispose() => _client.close();

  /// Ambil cuaca berdasarkan koordinat.
  ///
  /// [place] dipakai jika sudah diketahui (hasil geocoding). Jika null, nama
  /// lokasi dicari lewat reverse geocoding; bila gagal, memakai nama kota dari
  /// respons cuaca atau [fallbackLabel].
  Future<WeatherBundle> fetchByCoordinates({
    required double latitude,
    required double longitude,
    GeoPlace? place,
    String? fallbackLabel,
  }) async {
    _requireApiKey();

    final responses = await Future.wait([
      _getJson(
        _uri(ApiConfig.currentWeatherPath, {
          'lat': latitude.toString(),
          'lon': longitude.toString(),
          'units': 'metric',
        }),
      ),
      _getJson(
        _uri(ApiConfig.forecastPath, {
          'lat': latitude.toString(),
          'lon': longitude.toString(),
          'units': 'metric',
        }),
      ),
    ]);

    final Weather weather;
    final List<DailyForecast> forecast;
    try {
      weather = Weather.fromJson(responses[0] as Map<String, dynamic>);
      forecast = _mapForecast(responses[1] as Map<String, dynamic>);
    } on AppException {
      rethrow;
    } catch (_) {
      throw const InvalidResponseException();
    }

    final GeoPlace? resolvedPlace =
        place ?? await _reverseGeocodeSafe(latitude, longitude);

    return WeatherBundle(
      weather: weather,
      forecast: forecast,
      place: resolvedPlace,
      locationLabel:
          resolvedPlace?.displayName ??
          fallbackLabel ??
          weather.cityName,
    );
  }

  /// Cari cuaca dari nama kota (pencarian manual).
  ///
  /// Nama kota di-geocode dulu menjadi koordinat agar hasil konsisten dengan
  /// data berbasis koordinat dan tahan terhadap perbedaan penulisan
  /// (huruf besar/kecil, spasi berlebih, "Kota Malang" vs "Malang").
  Future<WeatherBundle> searchByCity(String city) async {
    final query = city.trim();
    if (query.isEmpty) {
      throw LocationNotFoundException(city);
    }

    final places = await searchPlaces(query);
    if (places.isEmpty) {
      throw LocationNotFoundException(query);
    }

    final place = places.first;
    return fetchByCoordinates(
      latitude: place.latitude,
      longitude: place.longitude,
      place: place,
      fallbackLabel: query,
    );
  }

  /// Daftar kandidat tempat dari nama (limit 5, hasil teratas paling relevan).
  Future<List<GeoPlace>> searchPlaces(String query) async {
    _requireApiKey();

    var places = await _requestPlaces(query);
    if (places.isEmpty && query.contains(',')) {
      // "Malang, Jawa Timur" -> coba "Malang" bila format lengkap gagal.
      places = await _requestPlaces(query.split(',').first.trim());
    }
    return places;
  }

  Future<List<GeoPlace>> _requestPlaces(String query) async {
    final trimmed = query.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (trimmed.isEmpty) return const [];

    final json = await _getJson(
      _uri(ApiConfig.geocodingDirectPath, {'q': trimmed, 'limit': '5'}),
    );
    if (json is! List) {
      throw const InvalidResponseException();
    }
    return json
        .whereType<Map<String, dynamic>>()
        .map(GeoPlace.fromJson)
        .toList(growable: false);
  }

  Future<GeoPlace?> _reverseGeocodeSafe(
    double latitude,
    double longitude,
  ) async {
    try {
      final json = await _getJson(
        _uri(ApiConfig.geocodingReversePath, {
          'lat': latitude.toString(),
          'lon': longitude.toString(),
          'limit': '1',
        }),
      );
      if (json is! List || json.isEmpty) return null;
      final first = json.first;
      if (first is! Map<String, dynamic>) return null;
      return GeoPlace.fromJson(first);
    } on AppException {
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Logika prakiraan dipertahankan dari versi UTS: ambil sampel pukul 12:00
  /// per hari, satu entri per tanggal, maksimal 5 hari.
  List<DailyForecast> _mapForecast(Map<String, dynamic> json) {
    final list = json['list'];
    if (list is! List) {
      throw const InvalidResponseException();
    }

    final forecastMap = <String, DailyForecast>{};
    for (final item in list) {
      if (item is! Map<String, dynamic>) continue;
      final dt = DateTime.parse(item['dt_txt'] as String);
      if (dt.hour == 12) {
        final dateKey = '${dt.year}-${dt.month}-${dt.day}';
        forecastMap[dateKey] ??= DailyForecast.fromJson(item);
      }
    }

    if (forecastMap.isEmpty) {
      // Fallback: data 3-jam tidak punya entri 12:00 (mis. tanggal batas).
      for (final item in list) {
        if (item is! Map<String, dynamic>) continue;
        final dt = DateTime.parse(item['dt_txt'] as String);
        final dateKey = '${dt.year}-${dt.month}-${dt.day}';
        forecastMap[dateKey] ??= DailyForecast.fromJson(item);
      }
    }

    return forecastMap.values.take(5).toList(growable: false);
  }

  Uri _uri(String path, Map<String, String> query) {
    return Uri.https(ApiConfig.host, path, {...query, 'appid': _requireApiKey()});
  }

  String _requireApiKey() {
    if (_apiKey.isEmpty) {
      throw const ApiKeyMissingException();
    }
    return _apiKey;
  }

  Future<dynamic> _getJson(Uri uri) async {
    http.Response response;
    try {
      response = await _client.get(uri).timeout(timeout);
    } on TimeoutException {
      throw const NetworkException(
        'Permintaan ke server cuaca melebihi batas waktu. Periksa koneksi '
        'internet Anda lalu coba lagi.',
      );
    } on http.ClientException {
      throw const NetworkException();
    } catch (_) {
      throw const NetworkException();
    }

    switch (response.statusCode) {
      case 200:
        break;
      case 401:
        throw const ApiKeyInvalidException();
      case 404:
        throw LocationNotFoundException('koordinat tersebut');
      case 429:
        throw const RateLimitException();
      default:
        if (response.statusCode >= 500) {
          throw ServerException(response.statusCode);
        }
        throw ServerException(response.statusCode);
    }

    try {
      return jsonDecode(response.body);
    } catch (_) {
      throw const InvalidResponseException();
    }
  }
}
