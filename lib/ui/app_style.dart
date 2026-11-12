import 'package:flutter/material.dart';

/// Identitas visual aplikasi (dipakai semua halaman).
const Color appPrimary = Color(0xFF1E88E5);
const Color appPrimaryDark = Color(0xFF1565C0);

/// Gradasi biru khas aplikasi.
const LinearGradient appGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFF1E88E5), Color(0xFF42A5F5), Color(0xFF90CAF9)],
);

/// Kartu transparan di atas gradasi.
BoxDecoration translucentCardDecoration({
  double opacity = 0.18,
  double radius = 18,
}) {
  return BoxDecoration(
    color: Colors.white.withValues(alpha: opacity),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
  );
}

/// Kartu putih solid untuk konten padat (mis. daftar jadwal).
BoxDecoration solidCardDecoration({double radius = 18}) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.08),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );
}
