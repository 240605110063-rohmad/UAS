import 'dart:async';

import 'package:flutter/material.dart';

import '../models/prayer_times.dart';
import '../services/app_exception.dart';
import '../state/app_state.dart';
import '../ui/app_style.dart';
import '../widgets/zikir_section.dart';

const _monthNames = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

/// Halaman jadwal salat dinamis berdasarkan koordinat lokasi aktif.
class PrayerPage extends StatefulWidget {
  const PrayerPage({
    super.key,
    required this.appState,
    this.onOpenWeatherTab,
  });

  final AppState appState;
  final VoidCallback? onOpenWeatherTab;

  @override
  State<PrayerPage> createState() => _PrayerPageState();
}

class _PrayerPageState extends State<PrayerPage> {
  PrayerTimes? _times;
  AppException? _error;
  bool _loading = false;
  double? _loadedLatitude;
  double? _loadedLongitude;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    widget.appState.addListener(_onAppStateChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadIfNeeded());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    widget.appState.removeListener(_onAppStateChanged);
    super.dispose();
  }

  void _onAppStateChanged() {
    if (!mounted) return;
    final latitude = widget.appState.latitude;
    final longitude = widget.appState.longitude;
    final changed =
        latitude != _loadedLatitude || longitude != _loadedLongitude;
    if (changed && !_loading) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadIfNeeded());
    }
  }

  Future<void> _loadIfNeeded({bool force = false}) async {
    final latitude = widget.appState.latitude;
    final longitude = widget.appState.longitude;
    if (latitude == null || longitude == null) return;
    if (!force && _times != null && latitude == _loadedLatitude &&
        longitude == _loadedLongitude) {
      return;
    }
    await _load(latitude, longitude, force: force);
  }

  Future<void> _load(
    double latitude,
    double longitude, {
    bool force = false,
  }) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final timezone = await widget.appState.resolveTimezone();
      final times = await widget.appState.prayerService.fetchFor(
        latitude: latitude,
        longitude: longitude,
        locationLabel: widget.appState.locationLabel,
        timezone: timezone,
      );
      if (!mounted) return;
      setState(() {
        _times = times;
        _loadedLatitude = latitude;
        _loadedLongitude = longitude;
        _error = null;
      });
      _startTicker();
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _error = const InvalidResponseException(
          'Jadwal salat tidak dapat dimuat. Coba lagi.',
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: appGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Jadwal Salat',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Muat ulang jadwal',
            onPressed: _loading
                ? null
                : () => _loadIfNeeded(force: true),
            icon: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (!widget.appState.hasLocation && _times == null) {
      return _buildWaitingLocation();
    }

    final times = _times;
    if (times == null) {
      if (_error != null) {
        return _buildError(_error!, showRetry: true);
      }
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadIfNeeded(force: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          if (_error != null) _buildStaleBanner(_error!),
          _buildLocationCard(times),
          const SizedBox(height: 16),
          _buildNextPrayerCard(times),
          const SizedBox(height: 16),
          ..._buildPrayerRows(times),
          const SizedBox(height: 12),
          const Text(
            'Jadwal dihitung AlAdhan API berdasarkan koordinat lokasi aktif. '
            'Notifikasi cuaca memakai notifikasi lokal, bukan push server.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 11),
          ),
          const SizedBox(height: 18),
          const ZikirSection(),
        ],
      ),
    );
  }

  Widget _buildWaitingLocation() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_searching, size: 72, color: Colors.white),
            const SizedBox(height: 18),
            const Text(
              'Menunggu lokasi Anda',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Jadwal salat mengikuti lokasi yang aktif di halaman Cuaca. '
              'Buka halaman Cuaca lalu gunakan GPS atau cari kota.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: widget.onOpenWeatherTab,
              icon: const Icon(Icons.wb_sunny),
              label: const Text('Buka Halaman Cuaca'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(AppException error, {required bool showRetry}) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 64, color: Colors.white),
            const SizedBox(height: 16),
            const Text(
              'Jadwal salat gagal dimuat',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 20),
            if (showRetry)
              ElevatedButton.icon(
                onPressed: () => _loadIfNeeded(force: true),
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaleBanner(AppException error) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Gagal memperbarui: ${error.message}',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: () => _loadIfNeeded(force: true),
            child: const Text(
              'Ulangi',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(PrayerTimes times) {
    final date = times.gregorianDate;
    final gregorian =
        '${date.day} ${_monthNames[date.month - 1]} ${date.year}';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: translucentCardDecoration(),
      child: Row(
        children: [
          const Icon(Icons.place, color: Colors.white, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  times.locationLabel,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$gregorian • ${times.timezone}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                if (times.hijri != null)
                  Text(
                    times.hijri!.formatted,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextPrayerCard(PrayerTimes times) {
    final now = DateTime.now();
    final upcoming = times.upcomingPrayer(now);
    final remaining = upcoming.$2.difference(now);
    final isTomorrow = upcoming.$2.day != times.gregorianDate.day;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: appPrimary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_active, color: appPrimary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isTomorrow
                      ? 'Salat berikutnya besok'
                      : 'Salat berikutnya',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
                Text(
                  '${upcoming.$1.label} • ${_formatClock(upcoming.$2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: appPrimaryDark,
                  ),
                ),
                Text(
                  _formatRemaining(remaining),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPrayerRows(PrayerTimes times) {
    final now = DateTime.now();
    final next = times.upcomingPrayer(now).$1;

    return Prayer.values.map((prayer) {
      final time = times.times[prayer];
      if (time == null) return const SizedBox.shrink();
      final isNext = prayer == next && prayer.isObligatory;
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isNext ? Colors.white : Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isNext ? appPrimary : Colors.white.withValues(alpha: 0.25),
            width: isNext ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              prayer == Prayer.sunrise
                  ? Icons.wb_twilight
                  : Icons.access_time_filled,
              color: isNext ? appPrimary : Colors.white,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                prayer.label,
                style: TextStyle(
                  color: isNext ? Colors.black87 : Colors.white,
                  fontWeight: isNext ? FontWeight.bold : FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ),
            if (isNext)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: appPrimary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Berikutnya',
                  style: TextStyle(fontSize: 10, color: appPrimaryDark),
                ),
              ),
            Text(
              _formatClock(time),
              style: TextStyle(
                color: isNext ? appPrimaryDark : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }).toList(growable: false);
  }

  String _formatClock(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatRemaining(Duration duration) {
    if (duration.isNegative) return 'Sudah lewat';
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    if (hours > 0) return '$hours jam $minutes menit lagi';
    if (minutes > 0) return '$minutes menit $seconds detik lagi';
    return '$seconds detik lagi';
  }
}
