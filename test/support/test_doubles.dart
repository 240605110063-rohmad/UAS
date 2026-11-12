import 'package:uaspraktikum/models/device_location.dart';
import 'package:uaspraktikum/models/forecast.dart';
import 'package:uaspraktikum/models/geo_place.dart';
import 'package:uaspraktikum/models/notification_settings.dart';
import 'package:uaspraktikum/models/prayer_times.dart';
import 'package:uaspraktikum/models/weather.dart';
import 'package:uaspraktikum/models/weather_bundle.dart';
import 'package:uaspraktikum/services/app_exception.dart';
import 'package:uaspraktikum/services/location_service.dart';
import 'package:uaspraktikum/services/notification_service.dart';
import 'package:uaspraktikum/services/prayer_service.dart';
import 'package:uaspraktikum/services/settings_store.dart';
import 'package:uaspraktikum/services/weather_alert_planner.dart';
import 'package:uaspraktikum/services/weather_service.dart';
import 'package:uaspraktikum/state/app_state.dart';

const testPlace = GeoPlace(
  name: 'Kota Malang',
  latitude: -7.98,
  longitude: 112.63,
  state: 'East Java',
  country: 'ID',
);

WeatherBundle testBundle({
  String cityName = 'Malang',
  String label = 'Kota Malang, East Java, ID',
  List<DailyForecast>? forecast,
}) {
  return WeatherBundle(
    weather: const Weather(
      cityName: 'Malang',
      temperature: 29.4,
      description: 'light rain',
      icon: '10d',
      humidity: 66,
      windSpeed: 1.4,
      latitude: -7.98,
      longitude: 112.63,
    ),
    forecast:
        forecast ??
        [
          DailyForecast(
            date: DateTime(2026, 11, 13, 12),
            description: 'light rain',
            icon: '10d',
            temperature: 28,
          ),
        ],
    place: testPlace,
    locationLabel: label,
  );
}

PrayerTimes testPrayerTimes({DateTime? now}) {
  final base = now ?? DateTime.now();
  final day = DateTime(base.year, base.month, base.day);
  DateTime at(int hour, int minute) =>
      DateTime(day.year, day.month, day.day, hour, minute);

  return PrayerTimes(
    locationLabel: 'Kota Malang, East Java, ID',
    gregorianDate: day,
    timezone: 'Asia/Jakarta',
    times: {
      Prayer.fajr: at(4, 30),
      Prayer.sunrise: at(5, 45),
      Prayer.dhuhr: at(11, 30),
      Prayer.asr: at(14, 45),
      Prayer.maghrib: at(17, 40),
      Prayer.isha: at(18, 55),
    },
    hijri: const HijriDate(day: 23, month: 'Jumada al-awwal', year: 1448),
  );
}

class FakeWeatherService extends WeatherService {
  FakeWeatherService({this.bundle, this.error}) : super(apiKey: 'test');

  final WeatherBundle? bundle;
  final AppException? error;
  int calls = 0;

  @override
  Future<WeatherBundle> searchByCity(String city) async {
    calls++;
    if (error != null) throw error!;
    return bundle ?? testBundle();
  }

  @override
  Future<WeatherBundle> fetchByCoordinates({
    required double latitude,
    required double longitude,
    GeoPlace? place,
    String? fallbackLabel,
  }) async {
    calls++;
    if (error != null) throw error!;
    return bundle ?? testBundle();
  }
}

class FakeLocationService extends LocationService {
  const FakeLocationService({this.error});

  final AppException? error;

  @override
  Future<DeviceLocation> currentPosition() async {
    if (error != null) throw error!;
    return const DeviceLocation(latitude: -7.98, longitude: 112.63);
  }
}

class FakePrayerService extends PrayerService {
  FakePrayerService({this.times, this.error});

  final PrayerTimes? times;
  AppException? error;
  final List<double> requestedLatitudes = [];
  final List<double> requestedLongitudes = [];

  @override
  Future<PrayerTimes> fetchFor({
    required double latitude,
    required double longitude,
    required String locationLabel,
    String? timezone,
    DateTime? date,
  }) async {
    requestedLatitudes.add(latitude);
    requestedLongitudes.add(longitude);
    if (error != null) throw error!;
    return times ?? testPrayerTimes();
  }
}

class FakeNotificationScheduler implements WeatherNotificationScheduler {
  FakeNotificationScheduler({
    this.permissionGranted = true,
    this.alerts = const [],
  });

  bool permissionGranted;
  List<WeatherAlert> alerts;
  int permissionRequests = 0;
  int cancelCalls = 0;
  int syncCalls = 0;
  int testNotificationCalls = 0;
  List<NotificationSettings> syncSettings = [];
  String? lastLocationLabel;

  @override
  Future<bool> ensureInitialized() async => true;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return permissionGranted;
  }

  @override
  Future<List<WeatherAlert>> syncForecast({
    required List<DailyForecast> forecast,
    required NotificationSettings settings,
    required String locationLabel,
  }) async {
    syncCalls++;
    syncSettings.add(settings);
    lastLocationLabel = locationLabel;
    return alerts;
  }

  @override
  Future<void> cancelAll() async {
    cancelCalls++;
  }

  @override
  Future<void> showTestNotification({required String locationLabel}) async {
    testNotificationCalls++;
    lastLocationLabel = locationLabel;
  }
}

AppState createTestAppState({
  FakeWeatherService? weatherService,
  FakePrayerService? prayerService,
  FakeNotificationScheduler? scheduler,
  NotificationSettings settings = const NotificationSettings(),
  SettingsStore? store,
}) {
  return AppState(
    weatherService: weatherService ?? FakeWeatherService(),
    locationService: const FakeLocationService(),
    prayerService: prayerService ?? FakePrayerService(),
    scheduler: scheduler ?? FakeNotificationScheduler(),
    settingsStore: store ?? InMemorySettingsStore(settings),
    initialSettings: settings,
    timezoneResolver: () async => 'Asia/Jakarta',
  );
}
