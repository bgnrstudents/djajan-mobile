import 'dart:convert';

import 'package:djajan_mobile/services/api_service.dart';
import 'package:djajan_mobile/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ApiService.setToken(null);
  });

  tearDown(() {
    ApiService.setToken(null);
    ApiService.onUnauthorized = null;
    ApiService.clientForTesting = http.Client();
  });

  test('account not found on customer endpoint falls back to Umkm login', () async {
    final requests = <String>[];
    ApiService.clientForTesting = MockClient((request) async {
      requests.add(request.url.path);
      if (request.url.path.endsWith('/pelanggan/login')) {
        return _response(
          statusCode: 404,
          message:
              'Akun belum ditemukan. Periksa kembali email atau nomor WhatsApp Anda, atau silakan daftar akun baru.',
          code: 'account_not_found',
        );
      }

      return http.Response(
        jsonEncode({
          'sukses': true,
          'pesan': 'Selamat datang.',
          'data': {'role': 'umkm', 'token': 'umkm-token'},
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final auth = AuthService();
    addTearDown(auth.dispose);
    final session = await auth.login('pemilik@example.com', 'password123');

    expect(session.role, AuthRole.umkm);
    expect(requests, hasLength(2));
    expect(requests.last, endsWith('/login'));
  });

  test('wrong customer password does not fall back to Umkm login', () async {
    final requests = <String>[];
    ApiService.clientForTesting = MockClient((request) async {
      requests.add(request.url.path);
      return _response(
        statusCode: 401,
        message: 'Kata sandi yang Anda masukkan tidak sesuai. Silakan coba kembali.',
        code: 'invalid_password',
      );
    });

    final auth = AuthService();
    addTearDown(auth.dispose);

    await expectLater(
      auth.login('pelanggan@example.com', 'password-salah'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.code,
          'code',
          'invalid_password',
        ),
      ),
    );
    expect(requests, hasLength(1));
  });

  test('temporary server errors preserve the saved session for retry', () async {
    SharedPreferences.setMockInitialValues({
      'djajan_auth_token': 'saved-token',
      'djajan_auth_role': 'pelanggan',
    });
    ApiService.clientForTesting = MockClient((_) async {
      return http.Response(
        jsonEncode({
          'sukses': false,
          'pesan': 'Terjadi kendala pada sistem. Silakan coba beberapa saat lagi.',
          'data': null,
        }),
        503,
        headers: {'content-type': 'application/json'},
      );
    });

    final auth = AuthService();
    addTearDown(auth.dispose);

    await expectLater(
      auth.restoreSession(),
      throwsA(
        isA<ApiException>().having(
          (error) => error.code,
          'code',
          'server_error',
        ),
      ),
    );

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('djajan_auth_token'), 'saved-token');
    expect(ApiService.hasToken, isTrue);
  });
}

http.Response _response({
  required int statusCode,
  required String message,
  required String code,
}) {
  return http.Response(
    jsonEncode({
      'sukses': false,
      'pesan': message,
      'data': {'code': code},
    }),
    statusCode,
    headers: {'content-type': 'application/json'},
  );
}
