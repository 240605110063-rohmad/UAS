import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/forecast.dart';
import '../models/notification_settings.dart';
import 'weather_alert_planner.dart';

/// Kontrak penjadwalan notifikasi cuaca (notifikasi LOKAL, bukan push server).
abstract class WeatherNotificationScheduler {
  /// Siapkan plugin + zona waktu. Mengembalikan false jika platform tidak
  /// mendukung notifikasi (mis. unit test / perangkat tanpa fitur ini).
  Future<bool> ensureInitialized();

  /// Minta izin notifikasi (Android 13+ memakai dialog sistem).
  Future<bool> requestPermission();

  /// Jadwalkan ulang notifikasi dari prakiraan terbaru.
  ///
  /// Notifikasi lama dengan ID tetap dibatalkan lebih dulu sehingga tidak ada
  /// duplikat untuk kondisi cuaca yang sama.
  Future<List<WeatherAlert>> syncForecast({
    required List<DailyForecast> forecast,
    required NotificationSettings settings,
    required String locationLabel,
  });

  Future<void> cancelAll();

  Future<void> showTestNotification({required String locationLabel});
}

/// Implementasi tanpa efek (dipakai saat plugin tidak tersedia / pengujian).
class NoopNotificationScheduler implements WeatherNotificationScheduler {
  @override
  Future<bool> ensureInitialized() async => false;

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<List<WeatherAlert>> syncForecast({
    required List<DailyForecast> forecast,
    required NotificationSettings settings,
    required String locationLabel,
  }) async => const [];

  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> showTestNotification({required String locationLabel}) async {}
}

/// Penjadwal notifikasi lokal memakai `flutter_local_notifications`.
class LocalNotificationScheduler implements WeatherNotificationScheduler {
  LocalNotificationScheduler({
    FlutterLocalNotificationsPlugin? plugin,
    DateTime Function()? clock,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _clock = clock ?? DateTime.now;

  static const int rainNotificationId = 4101;
  static const int clearNotificationId = 4102;
  static const String channelId = 'weather_alerts';
  static const String channelName = 'Peringatan Cuaca';
  static const String channelDescription =
      'Pengingat lokal berdasarkan prakiraan cuaca (bukan push notification).';

  final FlutterLocalNotificationsPlugin _plugin;
  final DateTime Function() _clock;

  bool _initialized = false;
  bool _available = true;

  @override
  Future<bool> ensureInitialized() async {
    if (_initialized) return _available;
    _initialized = true;
    try {
      tz.initializeTimeZones();
      await _configureLocalTimezone();

      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const initializationSettings = InitializationSettings(
        android: androidSettings,
      );
      await _plugin.initialize(settings: initializationSettings);
      return _available = true;
    } catch (_) {
      // Plugin tidak tersedia (mis. unit test): jangan pernah melempar error.
      return _available = false;
    }
  }

  Future<void> _configureLocalTimezone() async {
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // Tetap pakai lokasi default dari database timezone.
    }
  }

  @override
  Future<bool> requestPermission() async {
    if (!await ensureInitialized()) return false;
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android == null) return false;
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<WeatherAlert>> syncForecast({
    required List<DailyForecast> forecast,
    required NotificationSettings settings,
    required String locationLabel,
  }) async {
    if (!await ensureInitialized()) return const [];

    final alerts = buildWeatherAlerts(
      forecast: forecast,
      settings: settings,
      locationLabel: locationLabel,
    );

    try {
      await _cancelWeatherAlerts();
      for (final alert in alerts) {
        final id = alert.kind == WeatherAlertKind.rain
            ? rainNotificationId
            : clearNotificationId;
        await _schedule(id: id, alert: alert, settings: settings);
      }
    } catch (_) {
      // Penjadwalan gagal (mis. izin dicabut): aplikasi tetap berjalan.
    }
    return alerts;
  }

  Future<void> _schedule({
    required int id,
    required WeatherAlert alert,
    required NotificationSettings settings,
  }) async {
    var scheduled = DateTime(
      alert.day.year,
      alert.day.month,
      alert.day.day,
      settings.hour,
      settings.minute,
    );
    final now = _clock();
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );
    const details = NotificationDetails(android: androidDetails);

    await _plugin.zonedSchedule(
      id: id,
      title: alert.title,
      body: alert.body,
      scheduledDate: tz.TZDateTime.from(scheduled, tz.local),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: alert.kind.name,
    );
  }

  Future<void> _cancelWeatherAlerts() async {
    await _plugin.cancel(id: rainNotificationId);
    await _plugin.cancel(id: clearNotificationId);
  }

  @override
  Future<void> cancelAll() async {
    if (!await ensureInitialized()) return;
    try {
      await _cancelWeatherAlerts();
    } catch (_) {
      // Diabaikan.
    }
  }

  @override
  Future<void> showTestNotification({required String locationLabel}) async {
    if (!await ensureInitialized()) return;
    try {
      const androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      await _plugin.show(
        id: 4100,
        title: 'Notifikasi Cuaca Aktif',
        body:
            'Pengingat cuaca untuk $locationLabel akan muncul sesuai '
            'prakiraan.',
        notificationDetails: const NotificationDetails(android: androidDetails),
      );
    } catch (_) {
      // Diabaikan.
    }
  }
}
