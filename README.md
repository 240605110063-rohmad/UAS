# uaspraktikum — Pelacak Cuaca (UAS Praktikum)

Pengembangan lanjutan aplikasi prakiraan cuaca dari UTS. Aplikasi sekarang
memakai **geolocation**, **jadwal salat dinamis**, **notifikasi cuaca lokal**,
**halaman informasi**, dan **data zikir dari server**.

## Fitur

1. **Prakiraan cuaca berbasis lokasi**
   - Deteksi GPS otomatis saat aplikasi dibuka (`geolocator`).
   - Prakiraan 5 hari dari OpenWeather (koordinat, bukan nama kota).
   - Pencarian kota manual lewat geocoding sebagai alternatif bila izin
     lokasi ditolak.
   - Penanganan error terpisah: GPS mati, izin ditolak, izin permanen,
     timeout GPS, offline, API key salah, kuota habis, server error.
2. **Jadwal salat dinamis** (tab Jadwal Salat)
   - Subuh, Zuhur, Asar, Magrib, Isya (+ Syuruq) dari AlAdhan API.
   - Mengikuti koordinat lokasi aktif; metode perhitungan Kemenag (20).
   - Hitung mundur salat berikutnya + tanggal Hijriah.
3. **Zikir ba'da salat dari server**
   - JSON diambil lewat HTTP GET, lengkap arab/latin/arti/ulangan.
   - Ada indikator loading, pesan kegagalan koneksi, dan tombol "Coba Lagi".
4. **Notifikasi cuaca lokal**
   - `flutter_local_notifications`: peringatan hujan & info cuaca cerah
     dijadwalkan dari prakiraan terbaru.
   - Jam pengingat dapat diatur; ada tombol kirim notifikasi uji.
   - Bukan push notification server; penjadwalan lokal di perangkat.
5. **Halaman informasi**
   - Tentang aplikasi, daftar fitur, sumber data, panduan pemakaian,
     tips kesehatan per kondisi cuaca, info pengembang.

## Menjalankan

### Konfigurasi API Key (Wajib)

API key OpenWeatherMap **tidak** ditanam di source code. Anda wajib menyiapkannya
agar aplikasi dapat mengambil data cuaca.

1. **Siapkan `env.json`**
   Salin `env.example.json` ke `env.json` lalu isi API key Anda:
   ```json
   {
     "OPENWEATHER_API_KEY": "MASUKKAN_API_KEY_ANDA"
   }
   ```
   `env.json` sudah masuk `.gitignore` sehingga aman tidak ter-commit.

2. **Menjalankan via Terminal**
   ```bash
   flutter run --dart-define-from-file=env.json
   ```

3. **Menjalankan via Android Studio**
   Kami telah menyediakan konfigurasi Run **`uaspraktikum (env.json)`**.
   Cukup pilih konfigurasi tersebut di toolbar atas, lalu tekan **Run** / **Debug**.
   Jika belum ada, tambahkan konfigurasi Flutter baru dengan argumen:
   `--dart-define-from-file=env.json` di kolom *Additional run args*.

### Build APK debug
```bash
flutter build apk --debug --dart-define-from-file=env.json
```
Hasil: `build/app/outputs/flutter-apk/app-debug.apk`


## Teknologi

| Kebutuhan | Paket / layanan |
|---|---|
| Cuaca, geocoding, reverse geocoding | OpenWeatherMap API (api.openweathermap.org) |
| Jadwal salat + Hijriah | AlAdhan API (api.aladhan.com, method=20) |
| Zikir ba'da salat | JSON statis di `https://api.pastes.dev/r8hMzByuMe` |
| Lokasi perangkat | `geolocator` |
| Notifikasi lokal | `flutter_local_notifications`, `timezone`, `flutter_timezone` |
| Penyimpanan pengaturan | `shared_preferences` |
| HTTP | `http` |
| Format tanggal/angka | `intl` |

## Struktur kode

```
lib/
├── main.dart                     # bootstrap + injeksi AppState
├── config/
│   ├── api_config.dart           # host/path API + URL zikir
│   └── app_info.dart             # identitas aplikasi & pengembang
├── models/
│   ├── weather.dart              # cuaca saat ini (+ koordinat)
│   ├── forecast.dart             # prakiraan harian
│   ├── weather_bundle.dart       # cuaca + prakiraan + label lokasi
│   ├── geo_place.dart            # hasil geocoding
│   ├── device_location.dart      # koordinat GPS
│   ├── prayer_times.dart         # waktu salat & Hijriah
│   ├── notification_settings.dart
│   └── zikir.dart                # model data zikir dari server
├── services/
│   ├── weather_service.dart      # OpenWeather (koordinat + geocoding)
│   ├── prayer_service.dart       # AlAdhan
│   ├── zikir_service.dart        # fetch JSON zikir
│   ├── location_service.dart     # geolocator + pemetaan error
│   ├── notification_service.dart # penjadwalan notifikasi lokal
│   ├── weather_alert_planner.dart# aturan hujan/cerah -> notifikasi
│   ├── settings_store.dart       # SharedPreferences
│   └── app_exception.dart        # exception domain
├── state/app_state.dart          # lokasi aktif, cuaca, pengaturan
├── pages/
│   ├── home_shell.dart           # navigasi 4 tab
│   ├── weather_home_page.dart    # GPS + pencarian kota + prakiraan
│   ├── prayer_page.dart          # jadwal salat + zikir
│   ├── notification_settings_page.dart
│   └── information_page.dart
├── widgets/zikir_section.dart    # UI zikir + state loading/error
└── ui/app_style.dart             # warna, gradasi, kartu
```

## Pengujian

```bash
flutter analyze
flutter test
```

Cakupan: 48 pengujian (service cuaca, service jadwal salat, service zikir,
perencana notifikasi, AppState, widget halaman, navigasi, error handling).
Laporan pengembangan lengkap ada di [LAPORAN.md](LAPORAN.md).
