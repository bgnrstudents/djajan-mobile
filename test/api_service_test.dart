import 'dart:convert';

import 'package:djajan_mobile/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  tearDown(() {
    ApiService.clientForTesting = http.Client();
    ApiService.setToken(null);
    ApiService.onUnauthorized = null;
  });

  test('uses the safe API message for a JSON server error', () async {
    ApiService.clientForTesting = MockClient(
      (_) async => http.Response(
        jsonEncode({
          'sukses': false,
          'pesan': 'Pembayaran QRIS belum dapat dibuat. Hubungi admin.',
          'message': 'Sensitive internal exception details',
        }),
        503,
      ),
    );

    await expectLater(
      ApiService.postJson('pesanan/checkout', {}),
      throwsA(
        isA<ApiException>().having(
          (error) => error.pesan,
          'pesan',
          'Pembayaran QRIS belum dapat dibuat. Hubungi admin.',
        ),
      ),
    );
  });

  test(
    'keeps a generic message for server errors without an API message',
    () async {
      ApiService.clientForTesting = MockClient(
        (_) async => http.Response(
          jsonEncode({'message': 'Sensitive internal exception details'}),
          500,
        ),
      );

      await expectLater(
        ApiService.postJson('pesanan/checkout', {}),
        throwsA(
          isA<ApiException>().having(
            (error) => error.pesan,
            'pesan',
            'Terjadi kendala pada sistem. Silakan coba beberapa saat lagi.',
          ),
        ),
      );
    },
  );
}
