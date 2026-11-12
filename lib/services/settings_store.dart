import 'package:shared_preferences/shared_preferences.dart';

import '../models/notification_settings.dart';

/// Penyimpanan pengaturan notifikasi.
abstract class SettingsStore {
  Future<NotificationSettings> load();

  Future<void> save(NotificationSettings settings);
}

/// Implementasi produksi memakai SharedPreferences.
class SharedPreferencesSettingsStore implements SettingsStore {
  static const _kEnabled = 'notifications.enabled';
  static const _kRain = 'notifications.rain';
  static const _kClear = 'notifications.clear';
  static const _kHour = 'notifications.hour';
  static const _kMinute = 'notifications.minute';

  @override
  Future<NotificationSettings> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return NotificationSettings(
        enabled: prefs.getBool(_kEnabled) ?? false,
        rainAlerts: prefs.getBool(_kRain) ?? true,
        clearAlerts: prefs.getBool(_kClear) ?? true,
        hour: prefs.getInt(_kHour) ?? 7,
        minute: prefs.getInt(_kMinute) ?? 0,
      );
    } catch (_) {
      // Penyimpanan tidak tersedia: pakai default agar aplikasi tetap jalan.
      return const NotificationSettings();
    }
  }

  @override
  Future<void> save(NotificationSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kEnabled, settings.enabled);
      await prefs.setBool(_kRain, settings.rainAlerts);
      await prefs.setBool(_kClear, settings.clearAlerts);
      await prefs.setInt(_kHour, settings.hour);
      await prefs.setInt(_kMinute, settings.minute);
    } catch (_) {
      // Diabaikan: pengaturan tetap berlaku di sesi berjalan.
    }
  }
}

/// Implementasi untuk pengujian (tanpa plugin platform).
class InMemorySettingsStore implements SettingsStore {
  InMemorySettingsStore([this._settings = const NotificationSettings()]);

  NotificationSettings _settings;

  @override
  Future<NotificationSettings> load() async => _settings;

  @override
  Future<void> save(NotificationSettings settings) async {
    _settings = settings;
  }
}
