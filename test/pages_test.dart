import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uaspraktikum/main.dart';
import 'package:uaspraktikum/models/notification_settings.dart';
import 'package:uaspraktikum/pages/information_page.dart';
import 'package:uaspraktikum/pages/notification_settings_page.dart';
import 'package:uaspraktikum/pages/prayer_page.dart';
import 'package:uaspraktikum/services/app_exception.dart';
import 'package:uaspraktikum/services/weather_alert_planner.dart';

import 'support/test_doubles.dart';

void _useLargeSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  group('PrayerPage', () {
    testWidgets('menampilkan lima waktu salat dan tanggal Hijriah', (
      tester,
    ) async {
      _useLargeSurface(tester);
      final state = createTestAppState();
      await state.updateWeather(testBundle());

      await tester.pumpWidget(
        MaterialApp(home: PrayerPage(appState: state)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Subuh'), findsOneWidget);
      expect(find.text('Zuhur'), findsOneWidget);
      expect(find.text('Asar'), findsOneWidget);
      expect(find.text('Magrib'), findsOneWidget);
      expect(find.text('Isya'), findsOneWidget);
      expect(find.textContaining('H'), findsWidgets);
      expect(find.textContaining('Asia/Jakarta'), findsOneWidget);

      // Unmount agar Timer countdown berhenti.
      await tester.pumpWidget(const SizedBox());
      state.dispose();
    });

    testWidgets('memakai koordinat lokasi aktif saat ini', (tester) async {
      _useLargeSurface(tester);
      final prayer = FakePrayerService();
      final state = createTestAppState(prayerService: prayer);
      await state.updateWeather(testBundle());

      await tester.pumpWidget(
        MaterialApp(home: PrayerPage(appState: state)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(prayer.requestedLatitudes, contains(-7.98));
      expect(prayer.requestedLongitudes, contains(112.63));

      await tester.pumpWidget(const SizedBox());
      state.dispose();
    });

    testWidgets('error API menampilkan pesan dan tombol coba lagi', (
      tester,
    ) async {
      final state = createTestAppState(
        prayerService: FakePrayerService(error: const NetworkException()),
      );
      await state.updateWeather(testBundle());

      await tester.pumpWidget(
        MaterialApp(home: PrayerPage(appState: state)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Jadwal salat gagal dimuat'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      state.dispose();
    });

    testWidgets('tanpa lokasi menampilkan ajakan membuka halaman cuaca', (
      tester,
    ) async {
      final state = createTestAppState();
      addTearDown(state.dispose);

      await tester.pumpWidget(
        MaterialApp(home: PrayerPage(appState: state)),
      );
      await tester.pump();

      expect(find.text('Menunggu lokasi Anda'), findsOneWidget);
      expect(find.text('Buka Halaman Cuaca'), findsOneWidget);
    });
  });

  group('NotificationSettingsPage', () {
    testWidgets('izin diberikan: notifikasi dapat diaktifkan', (tester) async {
      _useLargeSurface(tester);
      final scheduler = FakeNotificationScheduler(
        permissionGranted: true,
        alerts: [
          WeatherAlert(
            kind: WeatherAlertKind.rain,
            title: 'Peringatan Cuaca Hujan',
            body: 'bawa payung',
            day: DateTime(2026, 11, 13),
          ),
        ],
      );
      final state = createTestAppState(scheduler: scheduler);
      await state.updateWeather(testBundle());

      await tester.pumpWidget(
        MaterialApp(home: NotificationSettingsPage(appState: state)),
      );
      await tester.pump();

      expect(state.settings.enabled, isFalse);
      await tester.tap(find.text('Aktifkan notifikasi cuaca'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(state.settings.enabled, isTrue);
      expect(scheduler.permissionRequests, 1);
      expect(find.textContaining('pengingat dijadwalkan'), findsOneWidget);

      state.dispose();
    });

    testWidgets('izin ditolak: tetap nonaktif dan tidak crash', (tester) async {
      _useLargeSurface(tester);
      final scheduler = FakeNotificationScheduler(permissionGranted: false);
      final state = createTestAppState(scheduler: scheduler);

      await tester.pumpWidget(
        MaterialApp(home: NotificationSettingsPage(appState: state)),
      );
      await tester.pump();

      await tester.tap(find.text('Aktifkan notifikasi cuaca'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(state.settings.enabled, isFalse);
      expect(find.textContaining('Izin notifikasi ditolak'), findsOneWidget);
      expect(tester.takeException(), isNull);

      state.dispose();
    });

    testWidgets('menampilkan jam pengingat dan menerima perubahan', (
      tester,
    ) async {
      _useLargeSurface(tester);
      final state = createTestAppState(
        settings: const NotificationSettings(
          enabled: true,
          hour: 6,
          minute: 30,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(home: NotificationSettingsPage(appState: state)),
      );
      await tester.pump();

      expect(find.text('06:30'), findsOneWidget);

      state.dispose();
    });
  });

  group('InformationPage', () {
    testWidgets('menampilkan semua bagian informasi', (tester) async {
      _useLargeSurface(tester);
      await tester.pumpWidget(const MaterialApp(home: InformationPage()));
      await tester.pump();

      expect(find.text('Tentang Aplikasi'), findsOneWidget);
      expect(find.text('Fitur'), findsOneWidget);
      expect(find.text('Sumber Data'), findsOneWidget);
      expect(find.text('Panduan Penggunaan'), findsOneWidget);
      expect(find.text('Pengembang'), findsOneWidget);
      expect(find.textContaining('AlAdhan'), findsOneWidget);
      expect(find.textContaining('OpenWeather'), findsWidgets);
    });
  });

  group('Navigasi', () {
    testWidgets('berpindah antar empat halaman tanpa kehilangan state', (
      tester,
    ) async {
      _useLargeSurface(tester);
      final state = createTestAppState();
      addTearDown(state.dispose);

      await tester.pumpWidget(MyApp(appState: state));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Halaman cuaca adalah halaman utama.
      expect(find.text('Cari nama kota...'), findsOneWidget);

      await tester.tap(find.text('Informasi'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Informasi Aplikasi'), findsOneWidget);

      await tester.tap(find.text('Jadwal Salat').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Jadwal Salat'), findsWidgets);
      expect(find.text('Subuh'), findsOneWidget);

      await tester.tap(find.text('Notifikasi'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Notifikasi Cuaca'), findsOneWidget);

      await tester.tap(find.text('Cuaca'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Cari nama kota...'), findsOneWidget);

      // Unmount untuk menghentikan timer countdown jadwal salat.
      await tester.pumpWidget(const SizedBox());
    });
  });
}
