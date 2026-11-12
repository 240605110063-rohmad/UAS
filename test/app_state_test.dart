import 'package:flutter_test/flutter_test.dart';
import 'package:uaspraktikum/models/notification_settings.dart';
import 'package:uaspraktikum/services/settings_store.dart';
import 'package:uaspraktikum/services/weather_alert_planner.dart';

import 'support/test_doubles.dart';

WeatherAlert _rainAlert() => WeatherAlert(
  kind: WeatherAlertKind.rain,
  title: 'Peringatan Cuaca Hujan',
  body: 'bawa payung',
  day: DateTime(2026, 11, 13, 12),
);

void main() {
  test('updateWeather menyimpan lokasi dan menjadwalkan notifikasi', () async {
    final scheduler = FakeNotificationScheduler(alerts: [_rainAlert()]);
    final state = createTestAppState(
      scheduler: scheduler,
      settings: const NotificationSettings(enabled: true),
    );

    await state.updateWeather(testBundle());

    expect(state.hasLocation, isTrue);
    expect(state.latitude, closeTo(-7.98, 1e-6));
    expect(state.locationLabel, 'Kota Malang, East Java, ID');
    expect(scheduler.syncCalls, 1);
    expect(scheduler.lastLocationLabel, 'Kota Malang, East Java, ID');
    expect(state.scheduledAlerts.length, 1);
    expect(state.scheduleMessage, contains('1 pengingat'));
  });

  test('notifikasi nonaktif membatalkan jadwal', () async {
    final scheduler = FakeNotificationScheduler(alerts: [_rainAlert()]);
    final state = createTestAppState(
      scheduler: scheduler,
      settings: const NotificationSettings(enabled: false),
    );

    await state.updateWeather(testBundle());

    expect(scheduler.syncCalls, 0);
    expect(scheduler.cancelCalls, 1);
    expect(state.scheduleMessage, contains('dinonaktifkan'));
  });

  test('applySettings menyimpan ke store dan menjadwalkan ulang', () async {
    final store = InMemorySettingsStore();
    final scheduler = FakeNotificationScheduler(alerts: [_rainAlert()]);
    final state = createTestAppState(
      scheduler: scheduler,
      store: store,
      settings: const NotificationSettings(enabled: true),
    );
    await state.updateWeather(testBundle());

    const next = NotificationSettings(
      enabled: true,
      rainAlerts: true,
      clearAlerts: false,
      hour: 5,
      minute: 15,
    );
    await state.applySettings(next);

    expect(state.settings, next);
    expect(await store.load(), next);
    expect(scheduler.syncSettings.last, next);
    expect(state.scheduleMessage, contains('05:15'));
  });

  test('izin notifikasi diteruskan ke scheduler', () async {
    final scheduler = FakeNotificationScheduler();
    final state = createTestAppState(scheduler: scheduler);

    final granted = await state.requestNotificationPermission();

    expect(granted, isTrue);
    expect(scheduler.permissionRequests, 1);
  });

  test('pengaturan awal dimuat dari store', () async {
    const stored = NotificationSettings(
      enabled: true,
      rainAlerts: false,
      clearAlerts: true,
      hour: 6,
      minute: 45,
    );
    final state = createTestAppState(
      store: InMemorySettingsStore(stored),
    );

    await state.loadSettings();

    expect(state.settings, stored);
    expect(state.settingsLoading, isFalse);
  });
}
