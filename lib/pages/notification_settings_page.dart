import 'package:flutter/material.dart';

import '../models/notification_settings.dart';
import '../state/app_state.dart';
import '../ui/app_style.dart';

/// Halaman pengaturan notifikasi cuaca (notifikasi lokal terjadwal).
class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key, required this.appState});

  final AppState appState;

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _busy = false;

  AppState get _state => widget.appState;

  Future<void> _update(NotificationSettings next) async {
    setState(() => _busy = true);
    await _state.applySettings(next);
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _setEnabled(bool value) async {
    if (!value) {
      await _update(_state.settings.copyWith(enabled: false));
      return;
    }

    setState(() => _busy = true);
    final granted = await _state.requestNotificationPermission();
    if (!mounted) return;
    setState(() => _busy = false);

    if (!granted) {
      _showMessage(
        'Izin notifikasi ditolak. Aktifkan izin notifikasi di Pengaturan '
        'aplikasi agar pengingat cuaca dapat muncul.',
      );
      return;
    }
    await _update(_state.settings.copyWith(enabled: true));
  }

  Future<void> _pickReminderTime() async {
    final settings = _state.settings;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: settings.hour, minute: settings.minute),
      helpText: 'Pilih jam pengingat cuaca',
    );
    if (picked == null) return;
    await _update(
      settings.copyWith(hour: picked.hour, minute: picked.minute),
    );
  }

  Future<void> _sendTestNotification() async {
    setState(() => _busy = true);
    final granted = await _state.requestNotificationPermission();
    if (granted) {
      await _state.showTestNotification();
    }
    if (!mounted) return;
    setState(() => _busy = false);
    _showMessage(
      granted
          ? 'Notifikasi uji dikirim. Periksa panel notifikasi perangkat.'
          : 'Izin notifikasi ditolak sehingga notifikasi uji tidak dikirim.',
    );
  }

  Future<void> _reschedule() async {
    setState(() => _busy = true);
    await _state.refreshWeatherNotifications();
    if (!mounted) return;
    setState(() => _busy = false);
    _showMessage(_state.scheduleMessage ?? 'Jadwal notifikasi diperbarui.');
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
        decoration: const BoxDecoration(gradient: appGradient),
        child: SafeArea(
          child: ListenableBuilder(
            listenable: _state,
            builder: (context, _) {
              final settings = _state.settings;
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                children: [
                  const Text(
                    'Notifikasi Cuaca',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Pengingat lokal terjadwal dari prakiraan OpenWeather. '
                    'Bukan push notification real-time dari server.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  _buildMainCard(settings),
                  const SizedBox(height: 14),
                  _buildAlertsCard(settings),
                  const SizedBox(height: 14),
                  _buildStatusCard(settings),
                  const SizedBox(height: 14),
                  _buildActions(settings),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMainCard(NotificationSettings settings) {
    return Material(
      color: Colors.white,
      elevation: 2,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: settings.enabled,
            onChanged: _busy ? null : _setEnabled,
            title: const Text(
              'Aktifkan notifikasi cuaca',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Minta izin notifikasi saat pertama kali diaktifkan.',
            ),
            secondary: const Icon(Icons.notifications_active_outlined),
          ),
          const Divider(height: 1),
          ListTile(
            contentPadding: EdgeInsets.zero,
            enabled: !_busy,
            onTap: settings.enabled ? _pickReminderTime : null,
            leading: const Icon(Icons.schedule),
            title: const Text('Jam pengingat'),
            subtitle: const Text('Waktu notifikasi dikirim setiap hari'),
            trailing: Text(
              settings.reminderLabel,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: appPrimaryDark,
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildAlertsCard(NotificationSettings settings) {
    return Material(
      color: Colors.white,
      elevation: 2,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          const Padding(
            padding: EdgeInsets.only(top: 14, bottom: 4),
            child: Text(
              'Jenis pengingat',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: settings.rainAlerts,
            onChanged: settings.enabled && !_busy
                ? (value) => _update(settings.copyWith(rainAlerts: value))
                : null,
            title: const Text('Peringatan hujan'),
            subtitle: const Text(
              'Ingatkan untuk membawa payung saat prakiraan hujan.',
            ),
            secondary: const Icon(Icons.umbrella),
          ),
          const Divider(height: 1),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: settings.clearAlerts,
            onChanged: settings.enabled && !_busy
                ? (value) => _update(settings.copyWith(clearAlerts: value))
                : null,
            title: const Text('Informasi cuaca cerah'),
            subtitle: const Text(
              'Beri tahu saat prakiraan cuaca cerah.',
            ),
            secondary: const Icon(Icons.wb_sunny_outlined),
          ),
          const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(NotificationSettings settings) {
    final alerts = _state.scheduledAlerts;
    final message = _state.scheduleMessage;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: translucentCardDecoration(opacity: 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                settings.enabled
                    ? 'Notifikasi aktif pada ${settings.reminderLabel}'
                    : 'Notifikasi sedang nonaktif',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (message != null) ...[
            const SizedBox(height: 6),
            Text(
              message,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
          if (alerts.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...alerts.map(
              (alert) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      alert.kind.name == 'rain'
                          ? Icons.water_drop
                          : Icons.wb_sunny,
                      color: Colors.white70,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${alert.title} • ${alert.day.day}/${alert.day.month}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (!_state.hasLocation) ...[
            const SizedBox(height: 8),
            const Text(
              'Lokasi belum tersedia. Buka halaman Cuaca agar pengingat '
              'dapat dijadwalkan sesuai prakiraan.',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActions(NotificationSettings settings) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _busy ? null : _reschedule,
            icon: const Icon(Icons.event_repeat),
            label: const Text('Jadwalkan Ulang dari Prakiraan Terbaru'),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _busy ? null : _sendTestNotification,
            icon: const Icon(Icons.send, color: Colors.white),
            label: const Text(
              'Kirim Notifikasi Uji',
              style: TextStyle(color: Colors.white),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white70),
            ),
          ),
        ),
        if (_busy) ...[
          const SizedBox(height: 12),
          const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
        ],
      ],
    );
  }
}
