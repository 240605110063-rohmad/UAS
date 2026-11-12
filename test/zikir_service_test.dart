import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uaspraktikum/services/app_exception.dart';
import 'package:uaspraktikum/services/zikir_service.dart';

const _body = '''
{
  "judul": "Zikir Ba'da Salat",
  "sumber": "HR. Muslim no. 597",
  "items": [
    {"judul": "Istighfar", "arabic": "أَسْتَغْفِرُ اللَّهَ", "latin": "Astaghfirullah", "arti": "Ampunilah aku", "ulang": "3x"},
    {"judul": "Tasbih", "arabic": "سُبْحَانَ اللَّهِ", "latin": "Subhanallah", "arti": "Maha Suci Allah", "ulang": "33x"}
  ]
}
''';

ZikirService _serviceWith(MockClient client) =>
    ZikirService(client: client, url: 'https://example.test/zikir.json');

void main() {
  test('mem-parse data zikir dari server', () async {
    final service = _serviceWith(
      MockClient(
        (_) async => http.Response.bytes(
          utf8.encode(_body),
          200,
          headers: {'content-type': 'text/plain; charset=utf-8'},
        ),
      ),
    );
    addTearDown(service.dispose);

    final data = await service.fetch();

    expect(data.judul, "Zikir Ba'da Salat");
    expect(data.sumber, contains('Muslim'));
    expect(data.items.length, 2);
    expect(data.items.first.judul, 'Istighfar');
    expect(data.items.first.arabic, contains('أَسْتَغْفِرُ'));
    expect(data.items.first.ulang, '3x');
  });

  test('kegagalan koneksi dipetakan ke NetworkException', () async {
    final service = _serviceWith(
      MockClient((_) async => throw http.ClientException('offline')),
    );
    addTearDown(service.dispose);

    await expectLater(service.fetch(), throwsA(isA<NetworkException>()));
  });

  test('respons error server dipetakan ke ServerException', () async {
    final service = _serviceWith(
      MockClient((_) async => http.Response('error', 503)),
    );
    addTearDown(service.dispose);

    await expectLater(service.fetch(), throwsA(isA<ServerException>()));
  });

  test('JSON rusak dipetakan ke InvalidResponseException', () async {
    final service = _serviceWith(
      MockClient((_) async => http.Response('{"items": []}', 200)),
    );
    addTearDown(service.dispose);

    await expectLater(
      service.fetch(),
      throwsA(isA<InvalidResponseException>()),
    );
  });
}
