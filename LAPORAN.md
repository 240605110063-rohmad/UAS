# Laporan Pengembangan Aplikasi — UTS ke UAS

**Nama:** Rohmad
**NIM:** 240605110063
**Proyek:** `uaspraktikum` (pengembangan dari `utspraktikum`)
**Tanggal:** 12 November 2026

---

## 1. Gambaran Aplikasi Versi UTS

Aplikasi UTS adalah pelacak cuaca Flutter satu halaman:

- Input nama kota, tombol cari, tampilan suhu/kelembapan/angin.
- Daftar prakiraan 5 hari (sampel data 3-jam pukul 12.00).
- Model `Weather` dan `DailyForecast`, service HTTP ke OpenWeather.
- Tampilan gradasi biru, indikator loading, dan pesan error sederhana.
- Belum ada geolocation, jadwal salat, notifikasi, halaman informasi, maupun
  integrasi server selain API cuaca.

**Kekurangan yang ditemukan pada UTS**

| Masalah | Dampak | Penyelesaian di UAS |
|---|---|---|
| `baseUrl` memakai `https://openweathermap.org/` (host web, bukan API) dan path diawali `/` ganda | Semua permintaan cuaca gagal → pesan "Gagal memuat data cuaca" | Host & path dipindah ke `ApiConfig` (`api.openweathermap.org`, `/data/2.5/...`) dan URL dibangun dengan `Uri.https` |
| File `lib/pages/weather_home_page.dart` duplikat class `WeatherHomePage` | Dead code, rawan konflik | Tidak disalin; hanya satu versi halaman cuaca |
| Semua error tampil sebagai satu pesan generik | Pengguna tidak tahu penyebab (offline? izin? kuota?) | Exception domain: `NetworkException`, `ServerException`, `ApiKeyInvalidException`, `LocationFailure`, dll. |
| Pencarian berbasis nama kota di API cuaca | Hasil tidak konsisten dengan data koordinat | Pencarian kota → geocoding → koordinat → cuaca |

---

## 2. Fitur Baru yang Ditambahkan

### 2.1 Geolocation cuaca
- `LocationService` membungkus `geolocator`: cek GPS aktif, minta izin,
  ambil posisi (akurasi medium, batas waktu 20 detik), fallback ke
  `getLastKnownPosition`.
- Cuaca diminta memakai `lat`/`lon`; label lokasi dari reverse geocoding.
- Deteksi otomatis saat aplikasi dibuka + tombol "Gunakan lokasi saya".
- Jika izin ditolak: aplikasi tetap berjalan, pencarian kota manual tetap
  tersedia, plus tombol "Buka Pengaturan"/"Aktifkan GPS" sesuai penyebab.

### 2.2 Jadwal salat dinamis
- Halaman tab **Jadwal Salat** (halaman kedua, memenuhi syarat minimal 2 page).
- Data AlAdhan API `GET /v1/timings/{dd-mm-yyyy}?latitude&longitude&method=20`
  (metode Kemenag) + zona waktu perangkat dari `flutter_timezone`.
- Menampilkan Subuh, Syuruq, Zuhur, Asar, Magrib, Isya, tanggal Masehi,
  Hijriah, kartu salat berikutnya, dan hitung mundur per detik.
- Otomatis memuat ulang bila koordinat lokasi aktif berubah.

### 2.3 Notifikasi cuaca
- `flutter_local_notifications` + `timezone` untuk **notifikasi lokal
  terjadwal** (bukan push server).
- `weather_alert_planner.dart` memetakan prakiraan → maksimal satu
  peringatan hujan (ikon `09/10/11`, kata rain/drizzle/thunder/hujan) dan
  satu info cerah (ikon `01/02`, clear/sunny/cerah), memakai hari terdekat.
- Halaman **Notifikasi**: switch aktif/nonaktif (meminta izin Android 13+),
  pilih jam pengingat, pilih jenis pengingat, jadwalkan ulang, kirim
  notifikasi uji, dan ringkasan pengingat yang terjadwal.
- Pengaturan disimpan di SharedPreferences; jadwal otomatis disinkronkan
  setiap kali data cuaca baru dimuat atau lokasi berubah.
- ID notifikasi tetap (4101/4102) sehingga jadwal lama dibatalkan dulu →
  tidak ada duplikat.

### 2.4 Halaman informasi + zikir
- Tab **Informasi**: tentang aplikasi, daftar fitur, sumber data, panduan
  penggunaan, tips kesehatan per kondisi cuaca, identitas pengembang.
- **Zikir ba'da salat** dari server ditampilkan di bawah jadwal salat:
  arab (RTL), latin, arti, jumlah ulangan, dan sumber hadis.

### 2.5 Integrasi data server (zikir)
- Endpoint JSON statis: `https://api.pastes.dev/r8hMzByuMe`
  (dapat diganti di `ApiConfig.zikirUrl`).
- `ZikirService` melakukan HTTP GET dengan timeout 15 detik dan memetakan:
  gangguan koneksi → `NetworkException`, status ≠ 200 → `ServerException`,
  format salah → `InvalidResponseException`.
- UI menampilkan loading, pesan gagal yang jelas, dan tombol **Coba Lagi**
  tanpa mengganggu jadwal salat yang sudah tampil.

---

## 3. Perubahan Tampilan dan Fungsi

| Aspek | UTS | UAS |
|---|---|---|
| Navigasi | 1 halaman | 4 tab: Cuaca, Jadwal Salat, Notifikasi, Informasi (IndexedStack, state tidak hilang) |
| Lokasi | Input nama kota saja | GPS otomatis + tombol lokasi + pencarian manual + chip koordinat |
| Data cuaca | Nama kota | Koordinat (konsisten GPS & geocoding), label lokasi 3 tingkat |
| Error | 1 pesan generik | Ikon, judul, penjelasan, dan aksi berbeda per penyebab |
| Jadwal salat | — | 6 waktu + Hijriah + hitung mundur + penanda "Berikutnya" |
| Notifikasi | — | Halaman pengaturan lengkap + penjadwalan otomatis |
| Konten | Cuaca | + informasi, tips kesehatan, zikir dari server |
| Struktur kode | 5 file, semua di `main.dart`/`pages` | Berlapis: config/model/service/state/page/widget |

---

## 4. Teknologi, API, dan Layanan

| Kebutuhan | Teknologi |
|---|---|
| Framework | Flutter 3.47.4 / Dart 3.13.3, Material 3 |
| Cuaca & prakiraan | OpenWeather `data/2.5/weather`, `data/2.5/forecast` |
| Geocoding | OpenWeather `geo/1.0/direct`, `geo/1.0/reverse` |
| Jadwal salat | AlAdhan API (method 20 = Kemenag) |
| Zikir | JSON statis di `api.pastes.dev` |
| Lokasi | `geolocator ^14.1.2` |
| Notifikasi | `flutter_local_notifications ^23.0.1`, `timezone ^0.11.2`, `flutter_timezone ^5.1.1` |
| Penyimpanan | `shared_preferences ^2.5.6` |
| HTTP | `http ^1.2.2` |
| Format | `intl ^0.20.3` |
| Android | minSdk Flutter default (24), compileSdk 37, core library desugaring aktif |

**Penyimpanan API key:** `ApiConfig` membaca `OPENWEATHER_API_KEY` dari
`--dart-define` / `--dart-define-from-file=env.json`; file `env.json`
di-gitignore sehingga kunci tidak masuk repositori.

**Izin Android** (`AndroidManifest.xml`): `INTERNET`,
`ACCESS_COARSE_LOCATION`, `ACCESS_FINE_LOCATION`, `POST_NOTIFICATIONS`,
`VIBRATE`, `RECEIVE_BOOT_COMPLETED`, plus receiver penjadwalan notifikasi.

---

## 5. Dokumentasi Tangkapan Layar

Simpan screenshot ke `docs/screenshots/` lalu ganti tanda `⬜` menjadi
`![...](docs/screenshots/...)`.

| No | Bagian | Sebelum (UTS) | Sesudah (UAS) |
|---|---|---|---|
| 1 | Halaman utama | ⬜ `docs/screenshots/uts-01-cuaca.png` | ⬜ `docs/screenshots/uas-01-cuaca-gps.png` |
| 2 | Prakiraan 5 hari | ⬜ `docs/screenshots/uts-02-forecast.png` | ⬜ `docs/screenshots/uas-02-forecast.png` |
| 3 | Jadwal salat | — | ⬜ `docs/screenshots/uas-03-salat.png` |
| 4 | Zikir dari server | — | ⬜ `docs/screenshots/uas-04-zikir.png` |
| 5 | Pengaturan notifikasi | — | ⬜ `docs/screenshots/uas-05-notifikasi.png` |
| 6 | Notifikasi muncul di panel | — | ⬜ `docs/screenshots/uas-06-notif-panel.png` |
| 7 | Halaman informasi + tips | — | ⬜ `docs/screenshots/uas-07-informasi.png` |
| 8 | Error izin lokasi/GPS | ⬜ `docs/screenshots/uts-03-error.png` | ⬜ `docs/screenshots/uas-08-error-lokasi.png` |
| 9 | Error server zikir (mode pesawat) | — | ⬜ `docs/screenshots/uas-09-error-zikir.png` |

Cara mengambil: jalankan
`flutter run --dart-define-from-file=env.json` pada emulator/HP, lalu
screenshot per tab.

---

## 6. Hasil Pengujian

Perintah: `flutter analyze` dan `flutter test`.

- `flutter analyze`: **No issues found**.
- `flutter test`: **48 pengujian lulus** (46 sebelumnya + 2 pengujian
  widget zikir).

| Berkas uji | Cakupan |
|---|---|
| `test/weather_service_test.dart` | Geocoding → koordinat, label reverse geocoding, 5 hari unik, 404/401/500, offline, API key kosong |
| `test/prayer_service_test.dart` | Parsing jadwal AlAdhan, format jam, Hijriah, respons tidak lengkap, error jaringan |
| `test/weather_alert_planner_test.dart` | Deteksi hujan/cerah, prioritas hari terdekat, pengaturan nonaktif |
| `test/app_state_test.dart` | Sinkronisasi lokasi + notifikasi, simpan pengaturan, muat pengaturan |
| `test/pages_test.dart` | Jadwal salat (5 waktu, Hijriah, koordinat), error + retry, halaman notifikasi, informasi, navigasi 4 tab |
| `test/widget_test.dart` | Pencarian kota, tombol GPS, izin ditolak permanen, error jaringan + retry |
| `test/zikir_service_test.dart` | Parsing JSON zikir, offline, HTTP 503, JSON rusak |
| `test/zikir_section_test.dart` | Render zikir dari server, state gagal + tombol Coba Lagi |

Pengujian manual (emulator Android):

1. GPS aktif + izin diberikan → cuaca muncul sesuai posisi.
2. Izin ditolak → muncul penjelasan + pencarian kota tetap bisa dipakai.
3. Tab Jadwal Salat → waktu sesuai koordinat, hitung mundur berjalan.
4. Zikir tampil; mode pesawat lalu refresh → pesan gagal + "Coba Lagi".
5. Notifikasi diaktifkan → izin diminta; "Kirim Notifikasi Uji" memunculkan
   notifikasi; jadwalkan ulang menampilkan jumlah pengingat.
6. Rotasi/pindah tab → state tidak hilang (IndexedStack).

---

## 7. Kendala dan Penyelesaian

| Kendala | Penyelesaian |
|---|---|
| `Weather` versi UTS tidak menyimpan koordinat, padahal `AppState` membutuhkannya | Tambah field `latitude`/`longitude` opsional dari blok `coord`; UI & state memakai nilai itu |
| Plugin notifikasi butuh core library desugaring & compileSdk 37 | Aktifkan `isCoreLibraryDesugaringEnabled` + `desugar_jdk_libs:2.1.4`, set `compileSdk = 37` |
| Notifikasi terjadwal butuh zona waktu perangkat, bukan UTC | `flutter_timezone` + `timezone`, `TZDateTime.from(..., tz.local)` |
| Zikir harus dari server, tanpa API key | JSON statis di `api.pastes.dev`, URL terpusat di `ApiConfig` agar mudah diganti |
| Data zikir berisi teks Arab non-ASCII | Decode `response.bodyBytes` dengan `utf8.decode`; render `TextDirection.rtl` |
| API cuaca UTS selalu gagal (host & slash salah) | Bangun URL via `Uri.https(host, path, query)` |
| Error jaringan pada FutureBuilder bisa dianggap unhandled | Error ditangkap lewat `onError` saat memulai request, FutureBuilder tetap menampilkan pesan |
| Timer hitung mundur bocor saat halaman ditutup | `Timer` dibatalkan di `dispose()` |

---

## 8. Kesimpulan

Aplikasi UTS berhasil dikembangkan menjadi aplikasi prakiraan cuaca berbasis
geolocation dengan jadwal salat dinamis, notifikasi cuaca lokal, halaman
informasi, dan integrasi data zikir dari server. Seluruh fitur utama berjalan,
kesalahan API pada versi UTS diperbaiki, seluruh pengujian otomatis lulus, dan
aplikasi siap dibangun menjadi APK dengan API key yang dikelola aman.
