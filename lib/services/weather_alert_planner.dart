import '../models/forecast.dart';
import '../models/notification_settings.dart';

enum WeatherAlertKind { rain, clear }

/// Satu notifikasi cuaca yang akan dijadwalkan.
class WeatherAlert {
  const WeatherAlert({
    required this.kind,
    required this.title,
    required this.body,
    required this.day,
  });

  final WeatherAlertKind kind;
  final String title;
  final String body;

  /// Tanggal prakiraan yang menjadi dasar pengingat.
  final DateTime day;
}

const _rainIcons = {'09', '10', '11'};
const _clearIcons = {'01', '02'};

bool _isRainy(DailyForecast forecast) {
  final icon = forecast.icon;
  if (icon.length >= 2 && _rainIcons.contains(icon.substring(0, 2))) {
    return true;
  }
  final description = forecast.description.toLowerCase();
  return description.contains('rain') ||
      description.contains('drizzle') ||
      description.contains('thunder') ||
      description.contains('hujan');
}

bool _isClear(DailyForecast forecast) {
  final icon = forecast.icon;
  if (icon.length >= 2 && _clearIcons.contains(icon.substring(0, 2))) {
    return true;
  }
  final description = forecast.description.toLowerCase();
  return description.contains('clear') ||
      description.contains('sunny') ||
      description.contains('cerah');
}

/// Menyusun rencana notifikasi dari prakiraan cuaca.
///
/// Aturan anti-duplikat: maksimal satu peringatan hujan dan satu informasi
/// cerah, memakai hari terdekat yang cocok.
List<WeatherAlert> buildWeatherAlerts({
  required List<DailyForecast> forecast,
  required NotificationSettings settings,
  required String locationLabel,
}) {
  if (!settings.enabled || !settings.hasAnyAlert) return const [];

  final alerts = <WeatherAlert>[];

  if (settings.rainAlerts) {
    final rainy = forecast.where(_isRainy).firstOrNull;
    if (rainy != null) {
      alerts.add(
        WeatherAlert(
          kind: WeatherAlertKind.rain,
          title: 'Peringatan Cuaca Hujan',
          body:
              'Diperkirakan akan turun hujan di $locationLabel pada '
              '${rainy.dayName} (${rainy.description}). Jangan lupa membawa '
              'payung.',
          day: rainy.date,
        ),
      );
    }
  }

  if (settings.clearAlerts) {
    final clear = forecast.where(_isClear).firstOrNull;
    if (clear != null) {
      alerts.add(
        WeatherAlert(
          kind: WeatherAlertKind.clear,
          title: 'Informasi Cuaca Cerah',
          body:
              'Cuaca diperkirakan cerah di $locationLabel pada '
              '${clear.dayName} (${clear.description}). Semoga aktivitas Anda '
              'berjalan lancar.',
          day: clear.date,
        ),
      );
    }
  }

  return alerts;
}
