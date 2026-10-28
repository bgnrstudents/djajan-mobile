import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../config/api_config.dart';

/// Error yang sudah diterjemahkan ke bahasa yang dimengerti pengguna.
class ApiException implements Exception {
  final String pesan;
  final String? field;

  ApiException(this.pesan, {this.field});
  @override
  String toString() => pesan;
}

/// Lapisan komunikasi dengan backend PHP + MySQL.
/// Semua endpoint mengembalikan JSON dengan bentuk seragam:
///   { "sukses": true/false, "pesan": "...", "data": ... }
class ApiService {
  static final http.Client _client = http.Client();

  /// Token Sanctum, disimpan di memori (sama seperti sebelumnya id_umkm
  /// cuma disimpan di memori) â€” hilang saat aplikasi ditutup total, pengguna
  /// perlu login ulang. Diisi UmkmDataService.login(), dikosongkan saat logout.
  static String? _token;
  static void setToken(String? token) => _token = token;
  static bool get hasToken => _token != null && _token!.isNotEmpty;

  static Map<String, String> get _headerAuth => {
    'Accept': 'application/json',
    'ngrok-skip-browser-warning': 'true',
    if (hasToken) 'Authorization': 'Bearer ' + _token!,
  };

  // ---------------------------------------------------------------- GET
  static Future<dynamic> get(String endpoint, {Map<String, String>? query}) {
    final uri = Uri.parse('${ApiConfig.apiUrl}/$endpoint')
        .replace(queryParameters: query);
    return _jalankan(
      () => _client.get(uri, headers: _headerAuth).timeout(ApiConfig.timeout),
    );
  }

  // --------------------------------------------------------------- POST
  static Future<dynamic> postJson(String endpoint, Map<String, dynamic> data) {
    final uri = Uri.parse('${ApiConfig.apiUrl}/$endpoint');
    return _jalankan(
      () => _client
          .post(
            uri,
            headers: {..._headerAuth, 'Content-Type': 'application/json'},
            body: jsonEncode(data),
          )
          .timeout(ApiConfig.timeout),
    );
  }

  /// POST biasa (form-urlencoded). Nilai non-String otomatis diubah ke String.
  static Future<dynamic> post(String endpoint, Map<String, dynamic> data) {
    final uri = Uri.parse('${ApiConfig.apiUrl}/$endpoint');
    return _jalankan(
      () => _client
          .post(uri, headers: _headerAuth, body: _keString(data))
          .timeout(ApiConfig.timeout),
    );
  }

  /// POST multipart â€” dipakai saat mengirim data sekaligus file gambar.
  /// [gambar] boleh null (berarti hanya data yang dikirim).
  static Future<dynamic> postDenganGambar(
    String endpoint,
    Map<String, dynamic> data, {
    XFile? gambar,
    String namaField = 'gambar_produk',
  }) async {
    if (gambar == null) return post(endpoint, data);

    // Pakai bytes supaya berjalan di Android, iOS, maupun Flutter Web.
    final bytes = await gambar.readAsBytes();
    if (bytes.lengthInBytes > 5 * 1024 * 1024) {
      throw ApiException(
        'Ukuran gambar melebihi 5 MB. Silakan pilih gambar lain.',
      );
    }

    return _jalankan(() async {
      final request =
          http.MultipartRequest(
              'POST',
              Uri.parse('${ApiConfig.apiUrl}/$endpoint'),
            )
            ..headers.addAll(_headerAuth)
            ..fields.addAll(_keString(data))
            ..files.add(
              http.MultipartFile.fromBytes(
                namaField,
                bytes,
                filename: _namaFileAman(gambar.name),
              ),
            );

      final streamed = await request.send().timeout(ApiConfig.timeout);
      return http.Response.fromStream(streamed);
    });
  }

  // ------------------------------------------------------------- privat
  /// Menjalankan permintaan HTTP sambil menerjemahkan seluruh kemungkinan error
  /// menjadi pesan berbahasa Indonesia yang mudah dipahami pengguna.
  static Future<dynamic> _jalankan(
    Future<http.Response> Function() aksi,
  ) async {
    try {
      return _proses(await aksi());
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException(
        'Koneksi lambat (Timeout).\n\n'
        'Jika pakai HP fisik, pastikan:\n'
        '1. IP Laptop (${ApiConfig.baseUrl}) benar.\n'
        '2. HP & Laptop di WiFi yang SAMA.\n'
        '3. Windows Firewall tidak memblokir port ${ApiConfig.port}.',
      );
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('socketexception') ||
          msg.contains('connection refused')) {
        throw ApiException(
          'Gagal terhubung ke server.\n\n'
          'Pastikan:\n'
          '1. Laravel sudah jalan dengan perintah:\n'
          '   php artisan serve --host=0.0.0.0 --port=${ApiConfig.port}\n'
          '2. IP address yang dimasukkan benar.',
        );
      }
      throw ApiException('Terjadi kesalahan koneksi: $e');
    }
  }

  static Map<String, String> _keString(Map<String, dynamic> data) {
    final hasil = <String, String>{};
    data.forEach((k, v) {
      if (v == null) return;
      hasil[k] = v is bool ? (v ? '1' : '0') : v.toString();
    });
    return hasil;
  }

  static String _namaFileAman(String nama) {
    final bersih = nama.split(RegExp(r'[\\/]')).last;
    return bersih.isEmpty ? 'gambar.jpg' : bersih;
  }

  static dynamic _proses(http.Response res) {
    Map<String, dynamic> json;
    try {
      json = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      // Balasan bukan JSON. Terjemahkan per kode HTTP supaya jelas
      // bagian mana yang harus diperbaiki.
      throw ApiException(_pesanNonJson(res.statusCode));
    }

    if (json['sukses'] == true) return json['data'];

    final data = json['data'];
    throw ApiException(
      (json['pesan'] ?? 'Terjadi kesalahan pada server.').toString(),
      field: data is Map ? data['field']?.toString() : null,
    );
  }

  /// Pesan bantuan saat server membalas HTML (bukan JSON).
  static String _pesanNonJson(int kode) {
    switch (kode) {
      case 404:
        return 'Endpoint API tidak ditemukan di server Laravel (404).\n\n'
            'Alamat yang dipanggil:\n${ApiConfig.apiUrl}\n\n'
            'Periksa: route-nya sudah ada di routes/api.php, dan bootstrap/app.php '
            'sudah mendaftarkan routes/api.php (api: __DIR__."/../routes/api.php").';
      case 401:
        return 'Sesi login sudah tidak valid (401). Silakan login ulang.';
      case 403:
        return 'Akses ditolak server (403). Periksa middleware/izin pada route ini.';
      case 500:
        return 'Server Laravel mengalami error (500). '
            'Buka terminal tempat `php artisan serve` berjalan untuk melihat pesan '
            'error aslinya, lalu pastikan MySQL menyala dan .env sudah diarahkan ke djajan_db.';
      default:
        return 'Server membalas data yang tidak dikenali (kode $kode). '
            'Buka ${ApiConfig.baseUrl}/api/ di browser untuk memeriksa status backend.';
    }
  }
}
