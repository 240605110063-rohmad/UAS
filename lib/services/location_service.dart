import 'dart:async';

import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import '../models/device_location.dart';
import 'app_exception.dart';

/// Pembungkus `geolocator` yang memetakan setiap kegagalan platform menjadi
/// [LocationFailure] dengan pesan yang mudah dimengerti pengguna.
class LocationService {
  const LocationService();

  /// Ambil posisi perangkat saat ini.
  ///
  /// Melempar [LocationFailure] untuk: GPS mati, izin ditolak, izin ditolak
  /// permanen, perangkat tidak memberi koordinat, atau plugin tidak tersedia.
  Future<DeviceLocation> currentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw const LocationFailure(
          LocationFailureReason.serviceDisabled,
          'Layanan lokasi (GPS) perangkat sedang mati. Aktifkan lokasi lalu '
          'coba lagi, atau cari kota secara manual.',
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw const LocationFailure(
          LocationFailureReason.permissionDenied,
          'Izin lokasi ditolak. Cuaca otomatis tidak dapat dipakai, tetapi '
          'pencarian kota manual tetap tersedia.',
        );
      }

      if (permission == LocationPermission.deniedForever) {
        throw const LocationFailure(
          LocationFailureReason.permissionDeniedForever,
          'Izin lokasi ditolak permanen. Buka Pengaturan aplikasi untuk '
          'mengizinkan akses lokasi.',
        );
      }

      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 20),
          ),
        ).timeout(const Duration(seconds: 25));
        return _toDeviceLocation(position);
      } on TimeoutException {
        final lastKnown = await _lastKnownPosition();
        if (lastKnown != null) return lastKnown;
        throw const LocationFailure(
          LocationFailureReason.timeout,
          'Perangkat belum memperoleh koordinat GPS. Coba di area terbuka atau '
          'gunakan pencarian kota manual.',
        );
      } on LocationFailure {
        rethrow;
      } catch (_) {
        final lastKnown = await _lastKnownPosition();
        if (lastKnown != null) return lastKnown;
        throw const LocationFailure(
          LocationFailureReason.unavailable,
          'Koordinat perangkat tidak dapat dibaca. Gunakan pencarian kota '
          'manual.',
        );
      }
    } on LocationFailure {
      rethrow;
    } on MissingPluginException {
      throw const LocationFailure(
        LocationFailureReason.unavailable,
        'Fitur lokasi tidak tersedia pada perangkat ini. Gunakan pencarian '
        'kota manual.',
      );
    } on PlatformException catch (error) {
      if (error.code == 'LOCATION_SERVICES_DISABLED') {
        throw const LocationFailure(
          LocationFailureReason.serviceDisabled,
          'Layanan lokasi (GPS) perangkat sedang mati. Aktifkan lokasi lalu '
          'coba lagi.',
        );
      }
      throw const LocationFailure(
        LocationFailureReason.unavailable,
        'Lokasi tidak dapat dibaca saat ini. Gunakan pencarian kota manual.',
      );
    } catch (_) {
      throw const LocationFailure(
        LocationFailureReason.unavailable,
        'Lokasi tidak dapat dibaca saat ini. Gunakan pencarian kota manual.',
      );
    }
  }

  Future<DeviceLocation?> _lastKnownPosition() async {
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last == null) return null;
      return _toDeviceLocation(last);
    } catch (_) {
      return null;
    }
  }

  DeviceLocation _toDeviceLocation(Position position) {
    return DeviceLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
    );
  }

  Future<void> openLocationSettings() async {
    try {
      await Geolocator.openLocationSettings();
    } catch (_) {
      // Diabaikan: perangkat mungkin tidak mendukung pengaturan ini.
    }
  }

  Future<void> openAppSettings() async {
    try {
      await Geolocator.openAppSettings();
    } catch (_) {
      // Diabaikan.
    }
  }
}
