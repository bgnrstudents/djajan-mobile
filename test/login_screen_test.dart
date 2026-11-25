import 'package:djajan_mobile/screens/auth/auth_widgets.dart';
import 'package:djajan_mobile/screens/auth/login_screen.dart';
import 'package:djajan_mobile/services/api_service.dart';
import 'package:djajan_mobile/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('wrong password is shown in a clear inline notice', (
    tester,
  ) async {
    await _submitLoginFailure(
      tester,
      ApiException(
        'Kata sandi yang Anda masukkan tidak sesuai. Silakan coba kembali.',
        code: 'invalid_password',
        statusCode: 401,
      ),
    );

    expect(
      find.text(
        'Kata sandi yang Anda masukkan tidak sesuai. Silakan coba kembali.',
      ),
      findsOneWidget,
    );
    expect(find.byType(AuthNotice), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('unknown-account notice avoids internal account terminology', (
    tester,
  ) async {
    await _submitLoginFailure(
      tester,
      ApiException(
        'Akun UMKM dengan data tersebut tidak ditemukan.',
        code: 'account_not_found',
        statusCode: 404,
      ),
    );

    expect(
      find.text(
        'Akun belum ditemukan. Periksa kembali email atau nomor WhatsApp Anda, atau silakan daftar akun baru.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('UMKM'), findsNothing);
  });

  testWidgets('pending account is displayed as an informative warning', (
    tester,
  ) async {
    await _submitLoginFailure(
      tester,
      ApiException(
        'Pendaftaran usaha Anda sedang ditinjau.',
        code: 'account_pending',
        statusCode: 403,
      ),
    );

    expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
    expect(find.textContaining('sedang ditinjau'), findsOneWidget);
  });

  testWidgets('network failure displays a helpful connection message', (
    tester,
  ) async {
    await _submitLoginFailure(
      tester,
      ApiException('Tidak dapat terhubung ke server.', code: 'network_error'),
    );

    expect(
      find.text(
        'Tidak dapat terhubung ke server. Periksa koneksi internet Anda dan coba kembali.',
      ),
      findsOneWidget,
    );
  });
}

Future<void> _submitLoginFailure(
  WidgetTester tester,
  ApiException error,
) async {
  final auth = _LoginFailureService(error);
  addTearDown(auth.dispose);

  await tester.pumpWidget(
    ChangeNotifierProvider<AuthService>.value(
      value: auth,
      child: const MaterialApp(home: LoginScreen()),
    ),
  );
  await tester.enterText(
    find.byType(TextFormField).at(0),
    'pelanggan@example.com',
  );
  await tester.enterText(find.byType(TextFormField).at(1), 'password123');
  await tester.ensureVisible(find.text('Masuk'));
  await tester.tap(find.text('Masuk'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

class _LoginFailureService extends AuthService {
  _LoginFailureService(this.error);

  final ApiException error;

  @override
  Future<AuthSession> login(String identifier, String password) async {
    throw error;
  }
}
