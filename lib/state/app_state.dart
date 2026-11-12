import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

import '../models/notification_settings.dart';
import '../models/weather_bundle.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../services/prayer_service.dart';
import '../services/settings_store.dart';
import '../services/weather_alert_planner.dart';
import '../services/weather_service.dart';

/// State global aplikasi: lokasi aktif (dipakai semua halaman), data cuaca
/// terakhir, dan pengaturan notifikasi.
class AppState extends ChangeNotifier {
  AppState({
    required this.weatherService,
    required this.locationService,
    required this.prayerService,
    required this.scheduler,
    required this.settingsStore,
    this.initialSettings = const NotificationSettings(),
    Future<String?> Function()? timezoneResolver,
  }) : _timezoneResolver = timezoneResolver ?? _deviceTimezone,
       settings = initialSettings;

  final WeatherService weatherService;
  final LocationService locationService;
  final PrayerService prayerService;
  final WeatherNotificationScheduler scheduler;
  final SettingsStore settingsStore;

  final NotificationSettings initialSettings;
  final Future<String?> Function() _timezoneResolver;

  NotificationSettings settings;

  WeatherBundle? _weather;

  double? _latitude;
  double? _longitude;
  String _locationLabel = 'Lokasi belum ditentukan';
  bool _settingsLoading = false;
  List<WeatherAlert> _scheduledAlerts = const [];
  String? _scheduleMessage;

  WeatherBundle? get weather => _weather;
  double? get latitude => _latitude;
  double? get longitude => _longitude;
  String get locationLabel => _locationLabel;
  bool get hasLocation => _latitude != null && _longitude != null;
  bool get settingsLoading => _settingsLoading;
  List<WeatherAlert> get scheduledAlerts => _scheduledAlerts;
  String? get scheduleMessage => _scheduleMessage;

  /// Muat pengaturan tersimpan (dipanggil sekali saat aplikasi dibuka).
  Future<void> loadSettings() async {
    _settingsLoading = true;
    notifyListeners();
    try {
      settings = await settingsStore.load();
    } finally {
      _settingsLoading = false;
      notifyListeners();
    }
  }

  /// Dipanggil halaman cuaca setiap kali data cuaca berhasil dimuat.
  Future<void> updateWeather(WeatherBundle bundle) async {
    _weather = bundle;
    _latitude =
        bundle.place?.latitude ?? bundle.weather.latitude ?? _latitude;
    _longitude =
        bundle.place?.longitude ?? bundle.weather.longitude ?? _longitude;
    _locationLabel = bundle.locationLabel;
    notifyListeners();
    await refreshWeatherNotifications();
  }

  /// Simpan pengaturan lalu jadwalkan ulang notifikasi (lokasi bisa berubah).
  Future<void> applySettings(NotificationSettings next) async {
    settings = next;
    notifyListeners();
    await settingsStore.save(next);
    await refreshWeatherNotifications();
  }

  Future<bool> requestNotificationPermission() =>
      scheduler.requestPermission();

  Future<void> showTestNotification() =>
      scheduler.showTestNotification(locationLabel: _locationLabel);

  /// Susun ulang notifikasi dari data cuaca yang sedang ditampilkan.
  Future<void> refreshWeatherNotifications() async {
    final bundle = _weather;
    if (bundle == null) return;

    if (!settings.enabled || !settings.hasAnyAlert) {
      await scheduler.cancelAll();
      _scheduledAlerts = const [];
      _scheduleMessage = settings.enabled
          ? 'Aktifkan minimal satu jenis pengingat.'
          : 'Notifikasi cuaca dinonaktifkan.';
      notifyListeners();
      return;
    }

    final alerts = await scheduler.syncForecast(
      forecast: bundle.forecast,
      settings: settings,
      locationLabel: _locationLabel,
    );
    _scheduledAlerts = alerts;
    _scheduleMessage = alerts.isEmpty
        ? 'Belum ada prakiraan hujan/cerah untuk dijadwalkan.'
        : '${alerts.length} pengingat dijadwalkan pukul ${settings.reminderLabel}.';
    notifyListeners();
  }

  /// Zona waktu perangkat untuk permintaan jadwal salat.
  Future<String?> resolveTimezone() => _timezoneResolver();

  static Future<String?> _deviceTimezone() async {
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      return info.identifier;
    } catch (_) {
      return null;
    }
  }

  /// Refresh notifikasi setelah pengguna kembali ke aplikasi/lokasi berubah.
  void refreshInBackground() {
    unawaited(refreshWeatherNotifications());
  }
}
