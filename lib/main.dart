import 'package:flutter/material.dart';

import 'pages/home_shell.dart';
import 'services/location_service.dart';
import 'services/notification_service.dart';
import 'services/prayer_service.dart';
import 'services/settings_store.dart';
import 'services/weather_service.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final scheduler = LocalNotificationScheduler();
  await scheduler.ensureInitialized();

  final appState = AppState(
    weatherService: WeatherService(),
    locationService: const LocationService(),
    prayerService: PrayerService(),
    scheduler: scheduler,
    settingsStore: SharedPreferencesSettingsStore(),
  );
  await appState.loadSettings();

  runApp(MyApp(appState: appState));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, this.appState});

  /// Dapat diinjeksi pada pengujian; jika null dibuat otomatis.
  final AppState? appState;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final bool _ownsState = widget.appState == null;
  late final AppState _appState = widget.appState ?? _createState();

  AppState _createState() {
    final state = AppState(
      weatherService: WeatherService(),
      locationService: const LocationService(),
      prayerService: PrayerService(),
      scheduler: LocalNotificationScheduler(),
      settingsStore: SharedPreferencesSettingsStore(),
    );
    state.loadSettings();
    return state;
  }

  @override
  void dispose() {
    if (_ownsState) {
      _appState.weatherService.dispose();
      _appState.prayerService.dispose();
      _appState.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pelacak Cuaca',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
        useMaterial3: true,
      ),
      home: HomeShell(appState: _appState),
    );
  }
}
