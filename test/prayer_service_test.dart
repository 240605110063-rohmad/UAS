import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uaspraktikum/models/prayer_times.dart';
import 'package:uaspraktikum/services/app_exception.dart';
import 'package:uaspraktikum/services/prayer_service.dart';

String _aladhanBody({String? overrideTime}) {
  return jsonEncode({
    'code': 200,
    'status': 'OK',
    'data': {
      'timings': {
        'Fajr': overrideTime ?? '04:30',
        'Sunrise': '05:45',
        'Dhuhr': '11:30',
        'Asr': '14:45',
        'Maghrib': '17:40',
        'Isha': '18:55 (WIB)',
      },
      'date': {
        'gregorian': {'date': '13-11-2026'},
        'hijri': {
          'day': '23',
          'year': '1448',
          'month': {'en': 'Jumada al-awwal', 'number': 5},
        },
      },
      'meta': {'timezone': 'Asia/Jakarta'},
    },
  });
}

PrayerService _service({
  int statusCode = 200,
  String? body,
  bool networkError = false,
  void Function(Uri)? onRequest,
}) {
  return PrayerService(
    client: MockClient((request) async {
      onRequest?.call(request.url);
      if (networkError) {
        throw http.ClientException('offline', request.url);
      }
      return http.Response(
        body ?? _aladhanBody(),
        statusCode,
        headers: {'content-type': 'application/json'},
      );
    }),
  );
}

void main() {
  test('mengambil 5 waktu salat, hijriah, dan zona waktu', () async {
    final service = _service();

    final times = await service.fetchFor(
      latitude: -7.98,
      longitude: 112.63,
      locationLabel: 'Kota Malang',
      timezone: 'Asia/Jakarta',
      date: DateTime(2026, 11, 13),
    );

    expect(times.times[Prayer.fajr]!.hour, 4);
    expect(times.times[Prayer.fajr]!.minute, 30);
    expect(times.times[Prayer.dhuhr]!.hour, 11);
    // "18:55 (WIB)" harus terbaca tanpa suffix zona waktu.
    expect(times.times[Prayer.isha]!.hour, 18);
    expect(times.times[Prayer.isha]!.minute, 55);
    expect(times.times.length, 6);
    expect(times.hijri?.formatted, '23 Jumada al-awwal 1448 H');
    expect(times.timezone, 'Asia/Jakarta');
    expect(times.gregorianDate, DateTime(2026, 11, 13));
  });

  test('meminta endpoint koordinat dengan parameter waktu lokal', () async {
    Uri? captured;
    final service = _service(onRequest: (uri) => captured = uri);

    await service.fetchFor(
      latitude: -7.98,
      longitude: 112.63,
      locationLabel: 'Kota Malang',
      timezone: 'Asia/Jakarta',
      date: DateTime(2026, 11, 13),
    );

    expect(captured!.host, 'api.aladhan.com');
    expect(captured!.path, '/v1/timings/13-11-2026');
    expect(captured!.queryParameters['latitude'], '-7.98');
    expect(captured!.queryParameters['longitude'], '112.63');
    expect(captured!.queryParameters['timezone'], 'Asia/Jakarta');
    expect(captured!.queryParameters['method'], '20');
  });

  test('menghitung salat berikutnya dari daftar waktu', () {
    final times = PrayerTimes(
      locationLabel: 'Malang',
      gregorianDate: DateTime(2026, 11, 13),
      timezone: 'Asia/Jakarta',
      times: {
        Prayer.fajr: DateTime(2026, 11, 13, 4, 30),
        Prayer.dhuhr: DateTime(2026, 11, 13, 11, 30),
        Prayer.asr: DateTime(2026, 11, 13, 14, 45),
        Prayer.maghrib: DateTime(2026, 11, 13, 17, 40),
        Prayer.isha: DateTime(2026, 11, 13, 18, 55),
      },
    );

    final next = times.nextPrayerAfter(DateTime(2026, 11, 13, 12));
    expect(next!.$1, Prayer.asr);

    // Lewat Isya -> Subuh besok.
    final afterIsha = times.upcomingPrayer(DateTime(2026, 11, 13, 20));
    expect(afterIsha.$1, Prayer.fajr);
    expect(afterIsha.$2.day, 14);
  });

  test('error jaringan dipetakan ke NetworkException', () async {
    final service = _service(networkError: true);

    await expectLater(
      service.fetchFor(
        latitude: -7.98,
        longitude: 112.63,
        locationLabel: 'Malang',
      ),
      throwsA(isA<NetworkException>()),
    );
  });

  test('server error dipetakan ke ServerException', () async {
    final service = _service(statusCode: 503);

    await expectLater(
      service.fetchFor(
        latitude: -7.98,
        longitude: 112.63,
        locationLabel: 'Malang',
      ),
      throwsA(isA<ServerException>()),
    );
  });

  test('JSON tidak lengkap tidak membuat crash', () async {
    final service = _service(body: jsonEncode({'code': 500, 'data': null}));

    await expectLater(
      service.fetchFor(
        latitude: -7.98,
        longitude: 112.63,
        locationLabel: 'Malang',
      ),
      throwsA(isA<InvalidResponseException>()),
    );
  });

  test('respons tanpa 5 waktu wajib dianggap tidak valid', () async {
    final body = jsonEncode({
      'code': 200,
      'data': {
        'timings': {'Fajr': '04:30', 'Dhuhr': '11:30'},
        'date': {
          'gregorian': {'date': '13-11-2026'},
        },
        'meta': {'timezone': 'Asia/Jakarta'},
      },
    });
    final service = _service(body: body);

    await expectLater(
      service.fetchFor(
        latitude: -7.98,
        longitude: 112.63,
        locationLabel: 'Malang',
      ),
      throwsA(isA<InvalidResponseException>()),
    );
  });
}
