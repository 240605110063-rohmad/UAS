import 'package:flutter_test/flutter_test.dart';
import 'package:uaspraktikum/models/forecast.dart';
import 'package:uaspraktikum/models/notification_settings.dart';
import 'package:uaspraktikum/services/weather_alert_planner.dart';

DailyForecast _forecast({
  required DateTime date,
  required String icon,
  required String description,
}) {
  return DailyForecast(
    date: date,
    icon: icon,
    description: description,
    temperature: 28,
  );
}

void main() {
  final base = DateTime(2026, 11, 13, 12);

  test('menjadwalkan peringatan hujan dari ikon prakiraan', () {
    final alerts = buildWeatherAlerts(
      forecast: [
        _forecast(date: base, icon: '10d', description: 'light rain'),
      ],
      settings: const NotificationSettings(enabled: true),
      locationLabel: 'Malang',
    );

    final rain = alerts.singleWhere(
      (alert) => alert.kind == WeatherAlertKind.rain,
    );
    expect(rain.title, 'Peringatan Cuaca Hujan');
    expect(rain.body, contains('payung'));
    expect(rain.body, contains('Malang'));
  });

  test('menjadwalkan informasi cerah dari deskripsi', () {
    final alerts = buildWeatherAlerts(
      forecast: [
        _forecast(date: base, icon: '01d', description: 'clear sky'),
      ],
      settings: const NotificationSettings(enabled: true),
      locationLabel: 'Malang',
    );

    final clear = alerts.singleWhere(
      (alert) => alert.kind == WeatherAlertKind.clear,
    );
    expect(clear.title, 'Informasi Cuaca Cerah');
  });

  test('tidak ada duplikat: maksimal satu hujan dan satu cerah', () {
    final alerts = buildWeatherAlerts(
      forecast: [
        _forecast(date: base, icon: '10d', description: 'rain'),
        _forecast(
          date: base.add(const Duration(days: 1)),
          icon: '09d',
          description: 'drizzle',
        ),
        _forecast(
          date: base.add(const Duration(days: 2)),
          icon: '01d',
          description: 'clear sky',
        ),
        _forecast(
          date: base.add(const Duration(days: 3)),
          icon: '02d',
          description: 'few clouds',
        ),
      ],
      settings: const NotificationSettings(enabled: true),
      locationLabel: 'Malang',
    );

    expect(alerts.length, 2);
    expect(alerts.where((a) => a.kind == WeatherAlertKind.rain).length, 1);
    expect(alerts.where((a) => a.kind == WeatherAlertKind.clear).length, 1);
  });

  test('menghormati toggle pengguna', () {
    final onlyRain = buildWeatherAlerts(
      forecast: [
        _forecast(date: base, icon: '10d', description: 'rain'),
        _forecast(
          date: base.add(const Duration(days: 1)),
          icon: '01d',
          description: 'clear sky',
        ),
      ],
      settings: const NotificationSettings(
        enabled: true,
        rainAlerts: true,
        clearAlerts: false,
      ),
      locationLabel: 'Malang',
    );

    expect(onlyRain.length, 1);
    expect(onlyRain.single.kind, WeatherAlertKind.rain);
  });

  test('notifikasi nonaktif tidak menghasilkan jadwal', () {
    final alerts = buildWeatherAlerts(
      forecast: [
        _forecast(date: base, icon: '10d', description: 'rain'),
        _forecast(
          date: base.add(const Duration(days: 1)),
          icon: '01d',
          description: 'clear sky',
        ),
      ],
      settings: const NotificationSettings(enabled: false),
      locationLabel: 'Malang',
    );

    expect(alerts, isEmpty);
  });

  test('prakiraan tanpa kondisi cocok tidak menghasilkan jadwal', () {
    final alerts = buildWeatherAlerts(
      forecast: [
        _forecast(date: base, icon: '04d', description: 'broken clouds'),
      ],
      settings: const NotificationSettings(enabled: true),
      locationLabel: 'Malang',
    );

    expect(alerts, isEmpty);
  });
}
