import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../config/api_config.dart';

/// Error yang sudah diterjemahkan ke bahasa yang dimengerti pengguna.
class ApiException implements Exception {
  final String pesan;
  final String? field;
  final String? code;
  final int? statusCode;

  ApiException(this.pesan, {this.field, this.code, this.statusCode});
  @override
  String toString() => pesan;
}

/// Lapisan komunikasi dengan backend PHP + MySQL.
/// Semua endpoint mengembalikan JSON dengan bentuk seragam:
///   { "sukses": true/false, "pesan": "...", "data": ... }
class ApiService {
  static http.Client _client = http.Client();

  @visibleForTesting
  static set clientForTesting(http.Client client) => _client = client;

  /// Token Sanctum, disimpan di memori (sama seperti sebelumnya id_umkm
  /// cuma disimpan di memori) â€” hilang saat aplikasi ditutup total, pengguna
  /// perlu login ulang. Diisi UmkmDataService.login(), dikosongkan saat logout.
  static String? _token;
  static void Function()? onUnauthorized;
  static void setToken(String? token) => _token = token;
  static bool get hasToken => _token != null && _token!.isNotEmpty;

  static Map<String, String> get _headerAuth => {
    'Accept': 'application/json',
    'ngrok-skip-browser-warning': 'true',
    if (hasToken) 'Authorization': 'Bearer ${_token!}',
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
        'Tidak dapat terhubung ke server. Periksa koneksi internet Anda dan coba kembali.',
        code: 'network_error',
      );
    } on http.ClientException catch (error) {
      debugPrint('Permintaan API gagal terhubung: $error');
      throw ApiException(
        'Tidak dapat terhubung ke server. Periksa koneksi internet Anda dan coba kembali.',
        code: 'network_error',
      );
    } catch (error) {
      debugPrint('Permintaan API mengalami kendala: $error');
      throw ApiException(
        'Terjadi kendala pada sistem. Silakan coba beberapa saat lagi.',
        code: 'system_error',
      );
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
    if (res.statusCode == 401) {
      onUnauthorized?.call();
    }

    Map<String, dynamic> json;
    try {
      json = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException(
        res.statusCode >= 500
            ? 'Terjadi kendala pada sistem. Silakan coba beberapa saat lagi.'
            : _pesanNonJson(res.statusCode),
        statusCode: res.statusCode,
        code: res.statusCode >= 500 ? 'server_error' : null,
      );
    }

    if (json['sukses'] == true) return json['data'];

    final data = json['data'];
    if (res.statusCode >= 500) {
      final serverMessage = json['pesan']?.toString().trim();
      throw ApiException(
        serverMessage != null && serverMessage.isNotEmpty
            ? serverMessage
            : 'Terjadi kendala pada sistem. Silakan coba beberapa saat lagi.',
        field: data is Map ? data['field']?.toString() : null,
        code: data is Map ? data['code']?.toString() : 'server_error',
        statusCode: res.statusCode,
      );
    }

    final fallbackMessage = json['message']?.toString().isNotEmpty == true
        ? json['message'].toString()
        : 'Permintaan gagal (HTTP ${res.statusCode}).';
    throw ApiException(
      (json['pesan'] ?? fallbackMessage).toString(),
      field: data is Map ? data['field']?.toString() : null,
      code: data is Map ? data['code']?.toString() : null,
      statusCode: res.statusCode,
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
        return 'Sesi login Anda telah berakhir. Silakan masuk kembali.';
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
