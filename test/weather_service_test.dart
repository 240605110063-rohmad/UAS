import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uaspraktikum/services/app_exception.dart';
import 'package:uaspraktikum/services/weather_service.dart';

const _apiKey = 'test-api-key';

Map<String, dynamic> _weatherJson({
  String cityName = 'Malang',
  double latitude = -7.98,
  double longitude = 112.63,
}) {
  return {
    'coord': {'lon': longitude, 'lat': latitude},
    'weather': [
      {'description': 'light rain', 'icon': '10d'},
    ],
    'main': {'temp': 29.03, 'humidity': 66},
    'wind': {'speed': 1.36},
    'name': cityName,
    'cod': 200,
  };
}

Map<String, dynamic> _forecastJson() {
  final days = ['2026-11-13', '2026-11-14', '2026-11-15', '2026-11-16'];
  final list = <Map<String, dynamic>>[];
  for (final day in days) {
    // Entri non-12:00 harus diabaikan oleh logika prakiraan lama.
    list.add({
      'dt_txt': '$day 09:00:00',
      'weather': [
        {'description': 'cloudy', 'icon': '03d'},
      ],
      'main': {'temp': 27.0},
    });
    list.add({
      'dt_txt': '$day 12:00:00',
      'weather': [
        {'description': 'light rain', 'icon': '10d'},
      ],
      'main': {'temp': 28.0},
    });
  }
  return {'list': list};
}

String _geoJson() => jsonEncode([
  {
    'name': 'Kota Malang',
    'lat': -7.9771308,
    'lon': 112.6340265,
    'country': 'ID',
    'state': 'East Java',
  },
]);

/// Client tiruan yang melayani endpoint OpenWeatherMap sesuai kebutuhan tes.
MockClient _client({
  bool cityFound = true,
  int weatherStatus = 200,
  bool throwNetworkError = false,
  void Function(Uri uri)? onRequest,
}) {
  return MockClient((request) async {
    onRequest?.call(request.url);
    if (throwNetworkError) {
      throw http.ClientException('offline', request.url);
    }
    final path = request.url.path;
    if (path.contains('/geo/1.0/direct')) {
      return http.Response(
        cityFound ? _geoJson() : '[]',
        200,
        headers: {'content-type': 'application/json'},
      );
    }
    if (path.contains('/geo/1.0/reverse')) {
      return http.Response(
        jsonEncode([
          {
            'name': 'Kota Malang',
            'lat': -7.98,
            'lon': 112.63,
            'country': 'ID',
            'state': 'East Java',
          },
        ]),
        200,
        headers: {'content-type': 'application/json'},
      );
    }
    if (weatherStatus != 200) {
      return http.Response('{}', weatherStatus);
    }
    if (path.contains('/data/2.5/weather')) {
      return http.Response(
        jsonEncode(_weatherJson()),
        200,
        headers: {'content-type': 'application/json'},
      );
    }
    if (path.contains('/data/2.5/forecast')) {
      return http.Response(
        jsonEncode(_forecastJson()),
        200,
        headers: {'content-type': 'application/json'},
      );
    }
    return http.Response('not found', 404);
  });
}

void main() {
  group('WeatherService.searchByCity', () {
    test('mencari Malang lewat geocoding lalu memakai koordinat', () async {
      final urls = <Uri>[];
      final service = WeatherService(
        client: _client(onRequest: urls.add),
        apiKey: _apiKey,
      );

      final bundle = await service.searchByCity(' Malang ');

      expect(bundle.weather.cityName, 'Malang');
      expect(bundle.weather.temperature, 29.03);
      expect(bundle.locationLabel, contains('Kota Malang'));
      expect(bundle.place?.latitude, closeTo(-7.9771308, 1e-6));

      // Permintaan cuaca memakai koordinat, bukan parameter q.
      final weatherUrl = urls.firstWhere(
        (uri) => uri.path.contains('/data/2.5/weather'),
      );
      expect(weatherUrl.queryParameters['lat'], isNotNull);
      expect(weatherUrl.queryParameters['lon'], isNotNull);
      expect(weatherUrl.queryParameters.containsKey('q'), isFalse);
      expect(weatherUrl.host, 'api.openweathermap.org');
    });

    test('prakiraan memakai satu entri per hari maksimal 5 hari', () async {
      final service = WeatherService(
        client: _client(),
        apiKey: _apiKey,
      );

      final bundle = await service.searchByCity('Malang');

      expect(bundle.forecast.length, 4);
      expect(bundle.forecast.first.temperature, 28.0);
      expect(bundle.forecast.first.description, 'light rain');
    });

    test('kota tidak dikenal melempar LocationNotFoundException', () async {
      final service = WeatherService(
        client: _client(cityFound: false),
        apiKey: _apiKey,
      );

      await expectLater(
        service.searchByCity('KotaTidakAda123'),
        throwsA(
          isA<LocationNotFoundException>().having(
            (e) => e.message,
            'message',
            contains('tidak ditemukan'),
          ),
        ),
      );
    });

    test('kegagalan jaringan bukan "kota tidak ditemukan"', () async {
      final service = WeatherService(
        client: _client(throwNetworkError: true),
        apiKey: _apiKey,
      );

      await expectLater(
        service.searchByCity('Malang'),
        throwsA(isA<NetworkException>()),
      );
    });

    test('error server dipetakan ke ServerException', () async {
      final service = WeatherService(
        client: _client(weatherStatus: 503),
        apiKey: _apiKey,
      );

      await expectLater(
        service.searchByCity('Malang'),
        throwsA(
          isA<ServerException>().having((e) => e.statusCode, 'status', 503),
        ),
      );
    });

    test('API key salah dipetakan ke ApiKeyInvalidException', () async {
      final service = WeatherService(
        client: _client(weatherStatus: 401),
        apiKey: _apiKey,
      );

      await expectLater(
        service.searchByCity('Malang'),
        throwsA(isA<ApiKeyInvalidException>()),
      );
    });

    test('API key kosong tidak memanggil jaringan', () async {
      var called = false;
      final service = WeatherService(
        client: _client(onRequest: (_) => called = true),
        apiKey: '',
      );

      await expectLater(
        service.searchByCity('Malang'),
        throwsA(isA<ApiKeyMissingException>()),
      );
      expect(called, isFalse);
    });
  });

  group('WeatherService.fetchByCoordinates', () {
    test('memakai lat/lon dan reverse geocoding untuk label', () async {
      final urls = <Uri>[];
      final service = WeatherService(
        client: _client(onRequest: urls.add),
        apiKey: _apiKey,
      );

      final bundle = await service.fetchByCoordinates(
        latitude: -7.98,
        longitude: 112.63,
      );

      expect(bundle.locationLabel, contains('Kota Malang'));
      expect(
        urls.any(
          (uri) =>
              uri.path.contains('/geo/1.0/reverse') &&
              uri.queryParameters['lat'] == '-7.98',
        ),
        isTrue,
      );
      final weatherUrl = urls.firstWhere(
        (uri) => uri.path.contains('/data/2.5/weather'),
      );
      expect(weatherUrl.queryParameters['lat'], '-7.98');
      expect(weatherUrl.queryParameters['lon'], '112.63');
      expect(weatherUrl.queryParameters['appid'], _apiKey);
    });

    test('label fallback dipakai bila reverse geocoding gagal', () async {
      final service = WeatherService(
        client: MockClient((request) async {
          final path = request.url.path;
          if (path.contains('/geo/1.0/reverse')) {
            return http.Response('[]', 200);
          }
          if (path.contains('/data/2.5/weather')) {
            return http.Response(jsonEncode(_weatherJson()), 200);
          }
          return http.Response(jsonEncode(_forecastJson()), 200);
        }),
        apiKey: _apiKey,
      );

      final bundle = await service.fetchByCoordinates(
        latitude: -7.98,
        longitude: 112.63,
        fallbackLabel: 'Lokasi saya',
      );

      expect(bundle.locationLabel, 'Lokasi saya');
      expect(bundle.place, isNull);
    });
  });
}
