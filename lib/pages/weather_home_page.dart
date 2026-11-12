import 'package:flutter/material.dart';

import '../models/forecast.dart';
import '../models/weather.dart';
import '../models/weather_bundle.dart';
import '../services/app_exception.dart';
import '../services/location_service.dart';
import '../services/weather_service.dart';
import '../ui/app_style.dart';

/// Permintaan cuaca terakhir, disimpan agar tombol "Coba Lagi" mengulang
/// permintaan yang sama persis (koordinat GPS atau nama kota).
sealed class _WeatherRequest {
  const _WeatherRequest();

  Future<WeatherBundle> execute(WeatherService service);

  String get loadingLabel;
}

class _CityRequest extends _WeatherRequest {
  const _CityRequest(this.city);

  final String city;

  @override
  Future<WeatherBundle> execute(WeatherService service) =>
      service.searchByCity(city);

  @override
  String get loadingLabel => 'Mencari "$city"...';
}

class _CoordinateRequest extends _WeatherRequest {
  const _CoordinateRequest({
    required this.latitude,
    required this.longitude,
    this.label,
  });

  final double latitude;
  final double longitude;
  final String? label;

  @override
  Future<WeatherBundle> execute(WeatherService service) =>
      service.fetchByCoordinates(
        latitude: latitude,
        longitude: longitude,
        fallbackLabel: label,
      );

  @override
  String get loadingLabel => 'Mengambil cuaca di lokasi Anda...';
}

class WeatherHomePage extends StatefulWidget {
  const WeatherHomePage({
    super.key,
    this.weatherService,
    this.locationService,
    this.onWeatherLoaded,
  });

  /// Dapat diinjeksi untuk pengujian.
  final WeatherService? weatherService;
  final LocationService? locationService;

  /// Dipanggil setiap data cuaca berhasil dimuat (dipakai state global agar
  /// halaman jadwal salat & notifikasi mengikuti lokasi yang sama).
  final ValueChanged<WeatherBundle>? onWeatherLoaded;

  @override
  State<WeatherHomePage> createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage> {
  final TextEditingController _cityController = TextEditingController(
    text: 'Jakarta',
  );
  final FocusNode _searchFocus = FocusNode();

  late final WeatherService _weatherService =
      widget.weatherService ?? WeatherService();
  late final LocationService _locationService =
      widget.locationService ?? const LocationService();

  Future<WeatherBundle>? _future;
  _WeatherRequest? _lastRequest;
  AppException? _locationFailure;
  bool _detectingLocation = false;

  @override
  void initState() {
    super.initState();
    // Langsung deteksi lokasi saat aplikasi dibuka (izin diminta oleh sistem).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _useCurrentLocation();
    });
  }

  @override
  void dispose() {
    _cityController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _run(_WeatherRequest request) {
    final future = request.execute(_weatherService);
    setState(() {
      _lastRequest = request;
      _locationFailure = null;
      _future = future;
    });
    // Error yang selesai sebelum FutureBuilder mendengarkan tetap dianggap
    // tertangani; FutureBuilder tetap menerima error yang sama.
    future.then<void>(
      (bundle) => widget.onWeatherLoaded?.call(bundle),
      onError: (Object _) {},
    );
  }

  void _searchByCity() {
    final query = _cityController.text.trim();
    if (query.isEmpty) {
      _showMessage('Masukkan nama kota terlebih dahulu.');
      _searchFocus.requestFocus();
      return;
    }
    _searchFocus.unfocus();
    _run(_CityRequest(query));
  }

  Future<void> _useCurrentLocation() async {
    if (_detectingLocation) return;
    _searchFocus.unfocus();
    setState(() {
      _detectingLocation = true;
      _locationFailure = null;
    });

    try {
      final position = await _locationService.currentPosition();
      if (!mounted) return;
      setState(() => _detectingLocation = false);
      _run(
        _CoordinateRequest(
          latitude: position.latitude,
          longitude: position.longitude,
          label: 'Lokasi saya',
        ),
      );
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() {
        _detectingLocation = false;
        _locationFailure = error;
        _future = null;
        _lastRequest = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _detectingLocation = false;
        _locationFailure = const LocationFailure(
          LocationFailureReason.unavailable,
          'Lokasi tidak dapat dibaca saat ini. Gunakan pencarian kota manual.',
        );
        _future = null;
        _lastRequest = null;
      });
    }
  }

  void _retryLastRequest() {
    final lastRequest = _lastRequest;
    if (lastRequest != null) {
      _run(lastRequest);
      return;
    }
    _useCurrentLocation();
  }

  void _focusManualSearch() {
    _searchFocus.requestFocus();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: appGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildSearchArea(),
              Expanded(
                child: FutureBuilder<WeatherBundle>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (_detectingLocation) {
                      return _buildLoading('Mendeteksi lokasi perangkat...');
                    }
                    if (_future == null) {
                      return _buildIdle();
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildLoading(
                        _lastRequest?.loadingLabel ?? 'Memuat data cuaca...',
                      );
                    }
                    if (snapshot.hasError) {
                      final error = snapshot.error;
                      return _buildError(
                        error is AppException
                            ? error
                            : const InvalidResponseException(),
                      );
                    }
                    return _buildWeatherContent(snapshot.data!);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchArea() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _cityController,
                    focusNode: _searchFocus,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _searchByCity(),
                    decoration: InputDecoration(
                      hintText: 'Cari nama kota...',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: appPrimary,
                      ),
                      suffixIcon: IconButton(
                        tooltip: 'Cari kota',
                        icon: const Icon(
                          Icons.arrow_forward_rounded,
                          color: appPrimary,
                        ),
                        onPressed: _searchByCity,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _buildLocationButton(),
            ],
          ),
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: Text(
                'Izin lokasi dipakai untuk menampilkan cuaca di posisi Anda saat ini.',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationButton() {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 4,
      child: IconButton(
        tooltip: 'Gunakan lokasi saya',
        onPressed: _detectingLocation ? null : _useCurrentLocation,
        icon: _detectingLocation
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: appPrimary,
                ),
              )
            : const Icon(Icons.my_location, color: appPrimary),
      ),
    );
  }

  Widget _buildLoading(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.white),
          const SizedBox(height: 20),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildIdle() {
    final locationFailure = _locationFailure;
    if (locationFailure != null) {
      return _buildError(locationFailure);
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.travel_explore, size: 80, color: Colors.white70),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              'Ketik nama kota pada kolom pencarian atau tekan ikon lokasi '
              'untuk memakai posisi Anda saat ini.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _focusManualSearch,
            icon: const Icon(Icons.search),
            label: const Text('Cari Kota'),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherContent(WeatherBundle bundle) {
    final weather = bundle.weather;
    final coordinatesLabel =
        bundle.place?.coordinateLabel ??
        (weather.latitude != null && weather.longitude != null
            ? '${weather.latitude!.toStringAsFixed(3)}, '
                  '${weather.longitude!.toStringAsFixed(3)}'
            : null);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Column(
        children: [
          _buildLocationChip(bundle.locationLabel, coordinatesLabel),
          const SizedBox(height: 12),
          _buildCurrentWeather(weather),
          const SizedBox(height: 30),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Perkiraan 5 Hari Kedepan',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...bundle.forecast.map(_buildForecastRow),
          if (bundle.forecast.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Prakiraan harian belum tersedia untuk lokasi ini.',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildLocationChip(String label, String? coordinatesLabel) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.place, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (coordinatesLabel != null)
                  Text(
                    'Koordinat: $coordinatesLabel',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Perbarui data',
            visualDensity: VisualDensity.compact,
            onPressed: _retryLastRequest,
            icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentWeather(Weather weather) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_on, color: Colors.white, size: 28),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                weather.cityName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        Image.network(
          'https://openweathermap.org/img/wn/${weather.icon}@4x.png',
          width: 120,
          height: 120,
          errorBuilder: (context, error, stackTrace) => const SizedBox(
            height: 120,
            child: Icon(
              Icons.cloud,
              size: 80,
              color: Colors.white70,
            ),
          ),
        ),
        Text(
          '${weather.temperature.round()}°C',
          style: const TextStyle(
            fontSize: 64,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        Text(
          weather.description.toUpperCase(),
          style: const TextStyle(
            fontSize: 18,
            color: Colors.white70,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildWeatherDetailItem(
                icon: Icons.water_drop_outlined,
                value: '${weather.humidity}%',
                label: 'Kelembapan',
              ),
              Container(
                height: 48,
                width: 1,
                color: Colors.white.withValues(alpha: 0.35),
              ),
              _buildWeatherDetailItem(
                icon: Icons.air_rounded,
                value: '${weather.windSpeed} m/s',
                label: 'Angin',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildForecastRow(DailyForecast forecast) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              forecast.dayName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Image.network(
            'https://openweathermap.org/img/wn/${forecast.icon}.png',
            width: 40,
            errorBuilder: (context, error, stackTrace) => const SizedBox(
              width: 40,
              height: 40,
              child: Icon(Icons.cloud, color: Colors.white70),
            ),
          ),
          Expanded(
            child: Text(
              forecast.description,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ),
          Text(
            '${forecast.temperature.round()}°C',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherDetailItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 30),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildError(AppException error) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_errorIcon(error), size: 72, color: Colors.white),
            const SizedBox(height: 18),
            Text(
              _errorTitle(error),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 22),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: _errorActions(error),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _errorActions(AppException error) {
    final actions = <Widget>[];
    final failure = error is LocationFailure ? error : null;

    if (failure?.reason == LocationFailureReason.serviceDisabled) {
      actions.add(
        ElevatedButton.icon(
          onPressed: _locationService.openLocationSettings,
          icon: const Icon(Icons.location_on),
          label: const Text('Aktifkan GPS'),
        ),
      );
    }

    if (failure?.reason == LocationFailureReason.permissionDeniedForever) {
      actions.add(
        ElevatedButton.icon(
          onPressed: _locationService.openAppSettings,
          icon: const Icon(Icons.settings),
          label: const Text('Buka Pengaturan'),
        ),
      );
    }

    actions.add(
      ElevatedButton.icon(
        onPressed: _retryLastRequest,
        icon: const Icon(Icons.refresh),
        label: const Text('Coba Lagi'),
      ),
    );
    actions.add(
      TextButton.icon(
        onPressed: _focusManualSearch,
        icon: const Icon(Icons.search, color: Colors.white),
        label: const Text(
          'Cari Kota Manual',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
    return actions;
  }

  IconData _errorIcon(AppException error) {
    if (error is NetworkException) return Icons.wifi_off;
    if (error is LocationNotFoundException) return Icons.location_off;
    if (error is ServerException || error is RateLimitException) {
      return Icons.cloud_off;
    }
    if (error is ApiKeyMissingException || error is ApiKeyInvalidException) {
      return Icons.key_off;
    }
    if (error is LocationFailure) {
      switch (error.reason) {
        case LocationFailureReason.serviceDisabled:
          return Icons.location_disabled;
        case LocationFailureReason.permissionDenied:
        case LocationFailureReason.permissionDeniedForever:
          return Icons.lock;
        case LocationFailureReason.timeout:
          return Icons.gps_off;
        case LocationFailureReason.unavailable:
          return Icons.location_searching;
      }
    }
    return Icons.error_outline;
  }

  String _errorTitle(AppException error) {
    if (error is ApiKeyMissingException) return 'API key belum diatur';
    if (error is ApiKeyInvalidException) return 'API key ditolak';
    if (error is LocationNotFoundException) return 'Lokasi tidak ditemukan';
    if (error is NetworkException) return 'Tidak ada koneksi';
    if (error is RateLimitException) return 'Kuota API habis';
    if (error is ServerException) return 'Server cuaca bermasalah';
    if (error is LocationFailure) {
      switch (error.reason) {
        case LocationFailureReason.serviceDisabled:
          return 'GPS tidak aktif';
        case LocationFailureReason.permissionDenied:
          return 'Izin lokasi ditolak';
        case LocationFailureReason.permissionDeniedForever:
          return 'Izin lokasi ditolak permanen';
        case LocationFailureReason.timeout:
          return 'Koordinat belum didapat';
        case LocationFailureReason.unavailable:
          return 'Lokasi tidak tersedia';
      }
    }
    return 'Terjadi kesalahan';
  }
}
