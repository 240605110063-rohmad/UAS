import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/zikir.dart';
import 'app_exception.dart';

/// Mengambil data zikir ba'da salat dari server (JSON statis di internet).
///
/// Endpoint diatur di [ApiConfig.zikirUrl]. Semua kegagalan koneksi dipetakan
/// ke [NetworkException] / [ServerException] / [InvalidResponseException] agar
/// halaman tetap bisa menampilkan pesan yang jelas dan tombol "Coba Lagi".
class ZikirService {
  ZikirService({
    http.Client? client,
    String? url,
    this.timeout = const Duration(seconds: 15),
  }) : _client = client ?? http.Client(),
       _url = url ?? ApiConfig.zikirUrl;

  final http.Client _client;
  final String _url;
  final Duration timeout;

  void dispose() => _client.close();

  Future<ZikirSet> fetch() async {
    final uri = Uri.parse(_url);

    http.Response response;
    try {
      response = await _client.get(uri).timeout(timeout);
    } on TimeoutException {
      throw const NetworkException(
        'Permintaan data zikir melebihi batas waktu. Periksa koneksi '
        'internet Anda lalu coba lagi.',
      );
    } on http.ClientException {
      throw const NetworkException(
        'Tidak dapat terhubung ke server zikir. Periksa koneksi internet '
        'Anda lalu coba lagi.',
      );
    } catch (_) {
      throw const NetworkException(
        'Tidak dapat terhubung ke server zikir. Periksa koneksi internet '
        'Anda lalu coba lagi.',
      );
    }

    if (response.statusCode == 429) {
      throw const RateLimitException();
    }
    if (response.statusCode != 200) {
      throw ServerException(response.statusCode);
    }

    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) {
        throw const InvalidResponseException(
          'Data zikir dari server tidak dapat dibaca. Coba lagi.',
        );
      }
      return ZikirSet.fromJson(decoded);
    } on AppException {
      rethrow;
    } catch (_) {
      throw const InvalidResponseException(
        'Data zikir dari server tidak dapat dibaca. Coba lagi.',
      );
    }
  }
}
