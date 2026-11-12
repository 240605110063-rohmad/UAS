import 'package:flutter/material.dart';

import '../models/zikir.dart';
import '../services/app_exception.dart';
import '../services/zikir_service.dart';
import '../ui/app_style.dart';

/// Bagian zikir ba'da salat yang datanya diambil dari server.
///
/// Menampilkan status loading, pesan error yang jelas (offline/server down),
/// dan tombol "Coba Lagi" tanpa mengganggu jadwal salat yang sudah tampil.
class ZikirSection extends StatefulWidget {
  const ZikirSection({super.key, this.service});

  /// Dapat diinjeksi pada pengujian.
  final ZikirService? service;

  @override
  State<ZikirSection> createState() => _ZikirSectionState();
}

class _ZikirSectionState extends State<ZikirSection> {
  late final ZikirService _service = widget.service ?? ZikirService();

  ZikirSet? _data;
  AppException? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _service.fetch();
      if (!mounted) return;
      setState(() => _data = data);
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _error = const InvalidResponseException(
          'Data zikir dari server tidak dapat dibaca. Coba lagi.',
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.menu_book, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                "Zikir Ba'da Salat",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Muat ulang zikir',
              onPressed: _loading ? null : _load,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.refresh, color: Colors.white, size: 20),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Data diambil dari server. Diperlukan koneksi internet.',
          style: TextStyle(color: Colors.white70, fontSize: 11),
        ),
        const SizedBox(height: 10),
        ..._buildContent(),
      ],
    );
  }

  List<Widget> _buildContent() {
    final data = _data;
    if (data != null) {
      return [
        ...data.items.map(_buildZikirCard),
        if (data.sumber.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Sumber: ${data.sumber}',
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ),
      ];
    }

    final error = _error;
    if (error != null) {
      return [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: translucentCardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.cloud_off, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Gagal memuat zikir dari server',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                error.message,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _load,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Coba Lagi'),
                ),
              ),
            ],
          ),
        ),
      ];
    }

    return [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: translucentCardDecoration(),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      ),
    ];
  }

  Widget _buildZikirCard(ZikirItem item) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: solidCardDecoration(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.judul,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (item.ulang.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: appPrimary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.ulang,
                    style: const TextStyle(
                      fontSize: 11,
                      color: appPrimaryDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.arabic,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: const TextStyle(
              fontSize: 22,
              height: 1.9,
              color: Colors.black87,
            ),
          ),
          if (item.latin.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              item.latin,
              style: const TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: Colors.black87,
              ),
            ),
          ],
          if (item.arti.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              item.arti,
              style: const TextStyle(
                fontSize: 12,
                height: 1.4,
                color: Colors.black54,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
