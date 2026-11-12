import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/prayer_times.dart';
import 'app_exception.dart';

/// Service jadwal salat memakai AlAdhan API.
///
/// Dokumentasi: https://aladhan.com/prayer-times-api
/// Perhitungan dilakukan server berdasarkan latitude/longitude sehingga jadwal
/// selalu dinamis (tidak ada jadwal statis di aplikasi).
class PrayerService {
  PrayerService({
    http.Client? client,
    this.timeout = const Duration(seconds: 20),
  }) : _client = client ?? http.Client();

  static const String host = 'api.aladhan.com';

  /// Metode perhitungan 20 = Kemenag Indonesia.
  static const int calculationMethod = 20;

  final http.Client _client;
  final Duration timeout;

  void dispose() => _client.close();

  /// Ambil jadwal salat untuk satu hari pada koordinat tertentu.
  ///
  /// [timezone] diisi identifier zona waktu perangkat (mis. `Asia/Jakarta`)
  /// agar jam yang dikembalikan API sesuai waktu lokal pengguna.
  Future<PrayerTimes> fetchFor({
    required double latitude,
    required double longitude,
    required String locationLabel,
    String? timezone,
    DateTime? date,
  }) async {
    final targetDate = date ?? DateTime.now();
    final path =
        '/v1/timings/${_formatDate(targetDate)}';

    final query = <String, String>{
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'method': calculationMethod.toString(),
      if (timezone != null && timezone.isNotEmpty) 'timezone': timezone,
    };

    final uri = Uri.https(host, path, query);
    final json = await _getJson(uri);

    try {
      final data = json['data'] as Map<String, dynamic>;
      final timings = data['timings'] as Map<String, dynamic>;
      final dateInfo = data['date'] as Map<String, dynamic>?;
      final gregorian = dateInfo?['gregorian'] as Map<String, dynamic>?;
      final hijri = dateInfo?['hijri'] as Map<String, dynamic>?;
      final meta = data['meta'] as Map<String, dynamic>?;

      final day = _parseGregorian(gregorian, targetDate);
      final times = <Prayer, DateTime>{};
      for (final entry in _timingKeys.entries) {
        final raw = timings[entry.value];
        if (raw is! String) continue;
        final parsed = _parseTime(raw, day);
        if (parsed != null) times[entry.key] = parsed;
      }

      if (times.length < 5) {
        throw const InvalidResponseException(
          'Jadwal salat yang diterima tidak lengkap. Coba lagi.',
        );
      }

      return PrayerTimes(
        locationLabel: locationLabel,
        gregorianDate: day,
        timezone:
            (meta?['timezone'] as String?) ?? (timezone ?? 'Waktu lokal'),
        times: times,
        hijri: _parseHijri(hijri),
      );
    } on AppException {
      rethrow;
    } catch (_) {
      throw const InvalidResponseException(
        'Respons jadwal salat tidak dapat dibaca. Coba lagi.',
      );
    }
  }

  static const Map<Prayer, String> _timingKeys = {
    Prayer.fajr: 'Fajr',
    Prayer.sunrise: 'Sunrise',
    Prayer.dhuhr: 'Dhuhr',
    Prayer.asr: 'Asr',
    Prayer.maghrib: 'Maghrib',
    Prayer.isha: 'Isha',
  };

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day-$month-${date.year}';
  }

  DateTime _parseGregorian(
    Map<String, dynamic>? gregorian,
    DateTime fallback,
  ) {
    final raw = gregorian?['date'] as String?;
    if (raw == null) return DateTime(fallback.year, fallback.month, fallback.day);
    final parts = raw.split('-');
    if (parts.length != 3) {
      return DateTime(fallback.year, fallback.month, fallback.day);
    }
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) {
      return DateTime(fallback.year, fallback.month, fallback.day);
    }
    return DateTime(year, month, day);
  }

  /// Format API: "04:38" atau "04:38 (WIB)".
  DateTime? _parseTime(String raw, DateTime day) {
    final cleaned = raw.split(' ').first.trim();
    final parts = cleaned.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return DateTime(day.year, day.month, day.day, hour, minute);
  }

  HijriDate? _parseHijri(Map<String, dynamic>? hijri) {
    if (hijri == null) return null;
    final day = _toInt(hijri['day']);
    final year = _toInt(hijri['year']);
    final month = hijri['month'] as Map<String, dynamic>?;
    final monthName = month?['en'] as String?;
    if (day == null || year == null || monthName == null) return null;
    return HijriDate(day: day, month: monthName, year: year);
  }

  /// AlAdhan mengirim angka sebagai String pada beberapa field.
  int? _toInt(Object? value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    http.Response response;
    try {
      response = await _client.get(uri).timeout(timeout);
    } on TimeoutException {
      throw const NetworkException(
        'Permintaan jadwal salat melebihi batas waktu. Periksa koneksi '
        'internet Anda lalu coba lagi.',
      );
    } on http.ClientException {
      throw const NetworkException(
        'Tidak dapat terhubung ke server jadwal salat. Periksa koneksi '
        'internet Anda lalu coba lagi.',
      );
    } catch (_) {
      throw const NetworkException(
        'Tidak dapat terhubung ke server jadwal salat. Periksa koneksi '
        'internet Anda lalu coba lagi.',
      );
    }

    if (response.statusCode == 429) {
      throw const RateLimitException();
    }
    if (response.statusCode >= 500) {
      throw ServerException(response.statusCode);
    }
    if (response.statusCode != 200) {
      throw ServerException(response.statusCode);
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const InvalidResponseException();
      }
      // AlAdhan membungkus hasil dalam { code, status, data }.
      if (decoded['data'] is! Map<String, dynamic>) {
        throw const InvalidResponseException(
          'Server jadwal salat tidak mengirim data yang valid.',
        );
      }
      return decoded;
    } catch (error) {
      if (error is AppException) rethrow;
      throw const InvalidResponseException(
        'Respons jadwal salat tidak dapat dibaca. Coba lagi.',
      );
    }
  }
}
