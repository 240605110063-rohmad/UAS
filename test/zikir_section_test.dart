import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uaspraktikum/services/zikir_service.dart';
import 'package:uaspraktikum/widgets/zikir_section.dart';

const _body = '''
{
  "judul": "Zikir Ba'da Salat",
  "sumber": "HR. Muslim no. 597",
  "items": [
    {"judul": "Tasbih", "arabic": "سُبْحَانَ اللَّهِ", "latin": "Subhanallah", "arti": "Maha Suci Allah", "ulang": "33x"}
  ]
}
''';

void main() {
  testWidgets('menampilkan zikir dari server', (tester) async {
    final service = ZikirService(
      client: MockClient(
        (_) async => http.Response.bytes(
          utf8.encode(_body),
          200,
          headers: {'content-type': 'text/plain; charset=utf-8'},
        ),
      ),
      url: 'https://example.test/zikir.json',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: ZikirSection(service: service)),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text("Zikir Ba'da Salat"), findsOneWidget);
    expect(find.text('Tasbih'), findsOneWidget);
    expect(find.text('Subhanallah'), findsOneWidget);
    expect(find.text('33x'), findsOneWidget);
    expect(find.textContaining('HR. Muslim'), findsOneWidget);
  });

  testWidgets('server gagal menampilkan pesan dan tombol coba lagi', (
    tester,
  ) async {
    final service = ZikirService(
      client: MockClient((_) async => http.Response('error', 503)),
      url: 'https://example.test/zikir.json',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: ZikirSection(service: service)),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Gagal memuat zikir dari server'), findsOneWidget);
    expect(find.text('Coba Lagi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
