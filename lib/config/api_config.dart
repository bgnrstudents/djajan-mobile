import 'package:flutter/foundation.dart';

/// ===========================================================================
///  SATU-SATUNYA TEMPAT YANG PERLU DIUBAH SAAT GANTI PERANGKAT / JARINGAN
/// ===========================================================================
///
/// Backend di Djajan-Website.
///
/// Jalankan dari terminal (di folder Djajan-Website):
///
///     cd Djajan-Website
///     php artisan serve --host=0.0.0.0 --port=8000
///
/// (--host=0.0.0.0 WAJIB kalau nanti mau dites dari HP Android asli, bukan
/// cuma dari laptop yang sama)
///
/// LANGKAH 1 — Buka http://localhost:8000/ di browser (ganti 8000 kalau Anda
///             pakai port lain). Harus muncul halaman default Laravel,
///             bukan 404 / connection refused.
///
/// LANGKAH 2 — Pilih alamat sesuai tempat aplikasi dijalankan:
///
///   • Emulator Android  -> otomatis (10.0.2.2), biarkan [alamatManual] kosong
///   • Chrome / Windows  -> otomatis (localhost),  biarkan [alamatManual] kosong
///   • HP Android asli   -> ISI [alamatManual] dengan IP laptop Anda.
///     Cek IP lewat Command Prompt: ketik `ipconfig`, lihat "IPv4 Address".
///     Laptop & HP wajib tersambung ke WiFi yang sama.
///
/// CATATAN PORT: default `php artisan serve` = 8000. Kalau Laravel disajikan
/// lewat Apache/Laragon (virtual host, document root = folder public/ Laravel),
/// biasanya balik ke port 80 — ubah [port] di bawah sesuai itu.
class ApiConfig {
  /// Port tempat Laravel berjalan. Default `php artisan serve` = 8000.
  static const int port = 8000;

  /// IP laptop Anda (cek `ipconfig` -> IPv4 Address).
  /// Isi hanya saat aplikasi dijalankan di HP asli.
  /// Contoh: '192.168.1.128'
  static const String ipLaptop = '192.168.1.6';

  /// Pilih target aplikasi:
  /// - false: laptop/browser atau emulator Android
  /// - true: HP asli yang terhubung ke WiFi yang sama
  static const bool pakaiHpAsli = true;

  /// URL publik untuk pengujian Midtrans dari HP melalui tunnel ngrok.
  /// Kosongkan kembali untuk memakai server lokal berdasarkan [pakaiHpAsli].
  static const String publicBaseUrl =
      'https://cornflake-untrue-fragrance.ngrok-free.dev';

  /// Web OAuth Client ID untuk Google Sign-In.
  ///
  /// Berikan saat menjalankan aplikasi dengan:
  /// --dart-define=GOOGLE_SERVER_CLIENT_ID=web-client-id
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  // ------------------------------------------------------------------
  // Di bawah ini tidak perlu diubah.
  // ------------------------------------------------------------------

  static String _susun(String host) {
    if (port == 80) {
      return 'http://$host/Djajan-Website/public';
    }
    return 'http://$host:$port';
  }

  /// Base URL final yang dipakai seluruh aplikasi (TANPA akhiran /api).
  static String get baseUrl {
    if (publicBaseUrl.isNotEmpty) return publicBaseUrl;
    if (pakaiHpAsli) return _susun(ipLaptop);
    if (kIsWeb) return _susun('localhost');
    return defaultTargetPlatform == TargetPlatform.android
        ? _susun('10.0.2.2')
        : _susun('localhost');
  }

  static String get apiUrl => '$baseUrl/api';

  /// Batas waktu menunggu server sebelum dianggap gagal.
  static const Duration timeout = Duration(seconds: 15);
}
