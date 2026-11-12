/// Lima waktu salat wajib + syuruq (matahari terbit).
enum Prayer { fajr, sunrise, dhuhr, asr, maghrib, isha }

extension PrayerLabel on Prayer {
  String get label {
    switch (this) {
      case Prayer.fajr:
        return 'Subuh';
      case Prayer.sunrise:
        return 'Syuruq';
      case Prayer.dhuhr:
        return 'Zuhur';
      case Prayer.asr:
        return 'Asar';
      case Prayer.maghrib:
        return 'Magrib';
      case Prayer.isha:
        return 'Isya';
    }
  }

  /// Waktu wajib yang ditampilkan pada daftar utama.
  bool get isObligatory => this != Prayer.sunrise;
}

class HijriDate {
  const HijriDate({
    required this.day,
    required this.month,
    required this.year,
  });

  final int day;
  final String month;
  final int year;

  String get formatted => '$day $month $year H';
}

class PrayerTimes {
  const PrayerTimes({
    required this.locationLabel,
    required this.gregorianDate,
    required this.timezone,
    required this.times,
    this.hijri,
  });

  final String locationLabel;
  final DateTime gregorianDate;
  final String timezone;
  final Map<Prayer, DateTime> times;
  final HijriDate? hijri;

  /// Salat berikutnya setelah [now]; null jika seluruh waktu hari ini lewat.
  (Prayer, DateTime)? nextPrayerAfter(DateTime now) {
    for (final prayer in Prayer.values) {
      if (!prayer.isObligatory) continue;
      final time = times[prayer];
      if (time != null && time.isAfter(now)) return (prayer, time);
    }
    return null;
  }

  /// Waktu salat berikutnya; jika hari ini habis, pakai Subuh besok.
  (Prayer, DateTime) upcomingPrayer(DateTime now) {
    final today = nextPrayerAfter(now);
    if (today != null) return today;
    final fajr = times[Prayer.fajr];
    final tomorrow = (fajr ?? now).add(const Duration(days: 1));
    return (Prayer.fajr, tomorrow);
  }
}
