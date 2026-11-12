import 'package:flutter/material.dart';

import '../config/app_info.dart';
import '../ui/app_style.dart';

/// Halaman informasi aplikasi: tentang, fitur, sumber data, panduan, developer.
class InformationPage extends StatelessWidget {
  const InformationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: appGradient),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            children: const [
              Text(
                'Informasi Aplikasi',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '${AppInfo.appName} • versi ${AppInfo.version}+'
                '${AppInfo.buildNumber}',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              SizedBox(height: 16),
              _InfoCard(
                icon: Icons.apps,
                title: 'Tentang Aplikasi',
                children: [
                  _InfoText(
                    'Aplikasi ini dibuat sebagai proyek UAS Praktikum untuk '
                    'membantu pengguna memantau prakiraan cuaca harian '
                    'berdasarkan lokasi aktual.',
                  ),
                  _InfoText(
                    'Fungsi utama: prakiraan cuaca 5 hari, pencarian kota '
                    'manual, geolocation GPS, jadwal salat dinamis, serta '
                    'pengingat cuaca lokal.',
                  ),
                  _InfoText(
                    'Manfaat: pengguna dapat merencanakan aktivitas luar '
                    'ruangan, membawa payung, dan mengetahui waktu salat '
                    'sesuai koordinat.',
                  ),
                ],
              ),
              SizedBox(height: 14),
              _InfoCard(
                icon: Icons.dashboard_customize,
                title: 'Fitur',
                children: [
                  _FeatureRow(
                    icon: Icons.wb_cloudy,
                    title: 'Prakiraan cuaca',
                    subtitle: 'Suhu, kelembapan, angin, dan prakiraan 5 hari.',
                  ),
                  _FeatureRow(
                    icon: Icons.search,
                    title: 'Pencarian lokasi',
                    subtitle: 'Cari kota lewat geocoding OpenWeather.',
                  ),
                  _FeatureRow(
                    icon: Icons.my_location,
                    title: 'Geolocation GPS',
                    subtitle: 'Cuaca otomatis sesuai posisi perangkat.',
                  ),
                  _FeatureRow(
                    icon: Icons.mosque,
                    title: 'Jadwal salat',
                    subtitle: 'Subuh, Zuhur, Asar, Magrib, Isya + Hijriah.',
                  ),
                  _FeatureRow(
                    icon: Icons.menu_book,
                    title: 'Zikir ba\'da salat',
                    subtitle: 'Zikir lengkap berisi arab, latin, arti, & ulangan.',
                  ),
                  _FeatureRow(
                    icon: Icons.notifications_active,
                    title: 'Notifikasi cuaca',
                    subtitle: 'Pengingat lokal hujan dan cuaca cerah.',
                  ),
                ],
              ),
              SizedBox(height: 14),
              _InfoCard(
                icon: Icons.cloud_queue,
                title: 'Sumber Data',
                children: [
                  _InfoText(
                    'Cuaca & prakiraan: OpenWeather API '
                    '(api.openweathermap.org/data/2.5).',
                  ),
                  _InfoText(
                    'Geocoding nama kota & reverse geocoding: OpenWeather '
                    'Geocoding API (api.openweathermap.org/geo/1.0).',
                  ),
                  _InfoText(
                    'Jadwal salat & tanggal Hijriah: AlAdhan Prayer Times API '
                    '(api.aladhan.com, metode Kemenag).',
                  ),
                  _InfoText(
                    'Zikir ba\'da salat: JSON statis di server (api.pastes.dev).',
                  ),
                ],
              ),
              SizedBox(height: 14),
              _InfoCard(
                icon: Icons.menu_book,
                title: 'Panduan Penggunaan',
                children: [
                  _InfoStep(
                    number: 1,
                    text: 'Aktifkan GPS pada perangkat, lalu izinkan akses '
                        'lokasi saat aplikasi memintanya.',
                  ),
                  _InfoStep(
                    number: 2,
                    text: 'Tekan ikon GPS untuk memakai posisi saat ini, atau '
                        'ketik nama kota lalu tekan tombol cari.',
                  ),
                  _InfoStep(
                    number: 3,
                    text: 'Buka tab Jadwal Salat untuk melihat waktu salat dan '
                        'hitung mundur salat berikutnya.',
                  ),
                  _InfoStep(
                    number: 4,
                    text: 'Buka tab Notifikasi, aktifkan notifikasi, pilih jam '
                        'pengingat, lalu simpan.',
                  ),
                ],
              ),
              SizedBox(height: 14),
              _InfoCard(
                icon: Icons.favorite,
                title: 'Tips Kesehatan Berdasarkan Cuaca',
                children: [
                  _InfoText(
                    'Hujan: bawa payung & tas hujan; hindari kolam genangan; '
                    'cuci tangan setelah aktivitas luar.',
                  ),
                  _InfoText(
                    'Cerah panas: minum air putih rutin; pakai topi/sunscreen; '
                    'hindari aktivitas berat siang hari (11-15).',
                  ),
                  _InfoText(
                    'Berawan lembap: jaga ventilasi ruangan; gunakan pelembap '
                    'jika kulit kering; waspada jamur & kutu debu.',
                  ),
                  _InfoText(
                    'Angin kencang: amankan barang terbang; hindari area '
                    'pohon tua/konstruksi; tutup jendela saat badai.',
                  ),
                ],
              ),
              SizedBox(height: 14),
              _InfoCard(
                icon: Icons.person,
                title: 'Pengembang',
                children: [
                  _InfoText('Nama aplikasi: ${AppInfo.appName}'),
                  _InfoText(
                    'Versi: ${AppInfo.version}+${AppInfo.buildNumber}',
                  ),
                  _InfoText(
                    'Pengembang: ${AppInfo.developerName} '
                    '(${AppInfo.developerId})',
                  ),
                  _InfoText('Repositori: ${AppInfo.repository}'),
                ],
              ),
              SizedBox(height: 18),
              Text(
                'Data cuaca dan jadwal salat bergantung pada layanan pihak '
                'ketiga sehingga membutuhkan koneksi internet.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: solidCardDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: appPrimary, size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _InfoText extends StatelessWidget {
  const _InfoText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.black87),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: appPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 17, color: appPrimary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoStep extends StatelessWidget {
  const _InfoStep({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: appPrimary,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
