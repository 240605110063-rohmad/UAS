/// Pengaturan notifikasi cuaca yang dipilih pengguna.
class NotificationSettings {
  const NotificationSettings({
    this.enabled = false,
    this.rainAlerts = true,
    this.clearAlerts = true,
    this.hour = 7,
    this.minute = 0,
  });

  final bool enabled;
  final bool rainAlerts;
  final bool clearAlerts;

  /// Jam pengingat harian (0-23).
  final int hour;

  /// Menit pengingat harian (0-59).
  final int minute;

  bool get hasAnyAlert => rainAlerts || clearAlerts;

  String get reminderLabel =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  NotificationSettings copyWith({
    bool? enabled,
    bool? rainAlerts,
    bool? clearAlerts,
    int? hour,
    int? minute,
  }) {
    return NotificationSettings(
      enabled: enabled ?? this.enabled,
      rainAlerts: rainAlerts ?? this.rainAlerts,
      clearAlerts: clearAlerts ?? this.clearAlerts,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
    );
  }

  Map<String, Object> toMap() => {
    'enabled': enabled,
    'rainAlerts': rainAlerts,
    'clearAlerts': clearAlerts,
    'hour': hour,
    'minute': minute,
  };

  factory NotificationSettings.fromMap(Map<String, Object?> map) {
    return NotificationSettings(
      enabled: map['enabled'] as bool? ?? false,
      rainAlerts: map['rainAlerts'] as bool? ?? true,
      clearAlerts: map['clearAlerts'] as bool? ?? true,
      hour: (map['hour'] as num?)?.toInt() ?? 7,
      minute: (map['minute'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is NotificationSettings &&
        other.enabled == enabled &&
        other.rainAlerts == rainAlerts &&
        other.clearAlerts == clearAlerts &&
        other.hour == hour &&
        other.minute == minute;
  }

  @override
  int get hashCode =>
      Object.hash(enabled, rainAlerts, clearAlerts, hour, minute);
}
