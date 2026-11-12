import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uaspraktikum/main.dart';
import 'package:uaspraktikum/models/device_location.dart';
import 'package:uaspraktikum/models/forecast.dart';
import 'package:uaspraktikum/models/geo_place.dart';
import 'package:uaspraktikum/models/weather.dart';
import 'package:uaspraktikum/models/weather_bundle.dart';
import 'package:uaspraktikum/pages/weather_home_page.dart';
import 'package:uaspraktikum/services/app_exception.dart';
import 'package:uaspraktikum/services/location_service.dart';
import 'package:uaspraktikum/services/weather_service.dart';

WeatherBundle _bundle({String cityName = 'Kota Malang'}) {
  return WeatherBundle(
    weather: Weather(
      cityName: cityName,
      temperature: 29.4,
      description: 'light rain',
      icon: '10d',
      humidity: 66,
      windSpeed: 1.4,
      latitude: -7.98,
      longitude: 112.63,
    ),
    forecast: [
      DailyForecast(
        date: DateTime(2026, 11, 13, 12),
        description: 'light rain',
        icon: '10d',
        temperature: 28,
      ),
    ],
    place: const GeoPlace(
      name: 'Kota Malang',
      latitude: -7.98,
      longitude: 112.63,
      state: 'East Java',
      country: 'ID',
    ),
    locationLabel: 'Kota Malang, East Java, ID',
  );
}

class _FakeWeatherService extends WeatherService {
  _FakeWeatherService({
    this.failuresBeforeSuccess = 0,
    this.onRequest,
  }) : super(apiKey: 'fake');

  final int failuresBeforeSuccess;
  final void Function(String? city)? onRequest;
  int calls = 0;

  @override
  Future<WeatherBundle> searchByCity(String city) async {
    calls++;
    onRequest?.call(city);
    if (calls <= failuresBeforeSuccess) {
      throw const NetworkException();
    }
    return _bundle();
  }

  @override
  Future<WeatherBundle> fetchByCoordinates({
    required double latitude,
    required double longitude,
    GeoPlace? place,
    String? fallbackLabel,
  }) async {
    calls++;
    onRequest?.call(null);
    if (calls <= failuresBeforeSuccess) {
      throw const NetworkException();
    }
    return _bundle();
  }
}

class _FailingLocationService extends LocationService {
  const _FailingLocationService();

  @override
  Future<DeviceLocation> currentPosition() async {
    throw const LocationFailure(
      LocationFailureReason.permissionDeniedForever,
      'Izin lokasi ditolak permanen. Buka Pengaturan aplikasi.',
    );
  }
}

class _FakeLocationService extends LocationService {
  const _FakeLocationService();

  @override
  Future<DeviceLocation> currentPosition() async {
    return const DeviceLocation(latitude: -7.98, longitude: 112.63);
  }
}

Widget _app({
  required WeatherService weatherService,
  LocationService locationService = const _FailingLocationService(),
}) {
  return MaterialApp(
    home: WeatherHomePage(
      weatherService: weatherService,
      locationService: locationService,
    ),
  );
}

void main() {
  testWidgets('menampilkan kolom pencarian dan tombol lokasi saya', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(weatherService: _FakeWeatherService()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cari nama kota...'), findsOneWidget);
    expect(find.byIcon(Icons.my_location), findsOneWidget);
    expect(find.textContaining('Izin lokasi dipakai'), findsOneWidget);
  });

  testWidgets('pencarian manual Malang menampilkan data cuaca', (tester) async {
    String? requestedCity;
    final service = _FakeWeatherService(
      onRequest: (city) => requestedCity = city,
    );

    await tester.pumpWidget(_app(weatherService: service));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Malang');
    await tester.tap(find.byIcon(Icons.arrow_forward_rounded));
    await tester.pumpAndSettle();

    expect(requestedCity, 'Malang');
    expect(find.text('Kota Malang'), findsOneWidget);
    expect(find.textContaining('Koordinat:'), findsOneWidget);
    expect(find.text('Perkiraan 5 Hari Kedepan'), findsOneWidget);
  });

  testWidgets('GPS dipakai saat tombol lokasi saya ditekan', (tester) async {
    final service = _FakeWeatherService();

    await tester.pumpWidget(
      _app(
        weatherService: service,
        locationService: const _FakeLocationService(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Kota Malang'), findsOneWidget);
    expect(service.calls, greaterThan(0));
  });

  testWidgets('izin ditolak permanen tidak membuat aplikasi crash', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        weatherService: _FakeWeatherService(),
        locationService: const _FailingLocationService(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Izin lokasi ditolak permanen'), findsOneWidget);
    expect(find.text('Buka Pengaturan'), findsOneWidget);
    expect(find.text('Cari Kota Manual'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('error jaringan tampil jelas dan Coba Lagi mengulang permintaan', (
    tester,
  ) async {
    final service = _FakeWeatherService(failuresBeforeSuccess: 1);

    await tester.pumpWidget(_app(weatherService: service));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Malang');
    await tester.tap(find.byIcon(Icons.arrow_forward_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Tidak ada koneksi'), findsOneWidget);
    expect(find.textContaining('tidak ditemukan'), findsNothing);
    expect(service.calls, 1);

    await tester.tap(find.text('Coba Lagi'));
    await tester.pumpAndSettle();

    expect(service.calls, 2);
    expect(find.text('Kota Malang'), findsOneWidget);
  });

  testWidgets('root MyApp dapat dirender tanpa crash', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();
    expect(find.byType(TextField), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
