import 'package:djajan_mobile/screens/auth/auth_widgets.dart';
import 'package:djajan_mobile/screens/auth/forgot_password_screen.dart';
import 'package:djajan_mobile/screens/auth/login_screen.dart';
import 'package:djajan_mobile/screens/auth/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(home: child);

/// Pakai ukuran layar ponsel yang lapang supaya isi form tidak terpotong.
void _useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _tapButton(WidgetTester tester, Key key) async {
  final button = find.byKey(key);
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
}

void main() {
  testWidgets('Halaman masuk menampilkan elemen utama desain baru', (
    tester,
  ) async {
    _useTallScreen(tester);
    await tester.pumpWidget(_wrap(const LoginScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Selamat\nDatang!'), findsOneWidget);
    expect(find.text('Belanja & kelola usahamu lebih mudah.'), findsOneWidget);
    expect(find.byType(AuthCard), findsOneWidget);
    expect(find.byKey(const ValueKey('auth-tab-login')), findsOneWidget);
    expect(find.byKey(const ValueKey('auth-tab-register')), findsOneWidget);
    expect(find.text('Nomor WhatsApp atau Email'), findsOneWidget);
    expect(find.text('Kata Sandi'), findsOneWidget);
    expect(find.text('Ingat saya'), findsOneWidget);
    expect(find.text('Lupa sandi?'), findsOneWidget);
    expect(find.text('Masuk dengan Google'), findsOneWidget);
    expect(find.text('Akun Anda aman dan terlindungi'), findsOneWidget);
    expect(find.text('Belum punya akun?'), findsNothing);
    expect(find.byKey(const ValueKey('login-submit-button')), findsOneWidget);
  });

  testWidgets('Validasi halaman masuk menampilkan pesan error', (tester) async {
    _useTallScreen(tester);
    await tester.pumpWidget(_wrap(const LoginScreen()));
    await tester.pumpAndSettle();

    await _tapButton(tester, const ValueKey('login-submit-button'));
    await tester.pumpAndSettle();

    expect(find.text('Nomor WhatsApp atau email wajib diisi'), findsOneWidget);
    expect(find.text('Kata sandi wajib diisi'), findsOneWidget);
  });

  testWidgets('Validasi format nomor WhatsApp pada halaman masuk', (
    tester,
  ) async {
    _useTallScreen(tester);
    await tester.pumpWidget(_wrap(const LoginScreen()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, '0812');
    await tester.pumpAndSettle();

    expect(find.text('Contoh format yang benar: 081234567890'), findsOneWidget);
  });

  testWidgets('Berpindah tab dari Masuk ke Daftar di halaman yang sama', (
    tester,
  ) async {
    _useTallScreen(tester);
    await tester.pumpWidget(_wrap(const LoginScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('auth-tab-register')));
    await tester.pumpAndSettle();

    expect(find.text('Nama Lengkap'), findsOneWidget);
    expect(find.text('Nomor WhatsApp'), findsOneWidget);
    expect(find.text('Email (Opsional)'), findsOneWidget);
    expect(find.text('Ulangi Kata Sandi'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('register-submit-button')),
      findsOneWidget,
    );
  });

  testWidgets('Halaman daftar menampilkan seluruh field', (tester) async {
    _useTallScreen(tester);
    await tester.pumpWidget(_wrap(const RegisterScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Selamat\nDatang!'), findsOneWidget);
    expect(find.text('Belanja & kelola usahamu lebih mudah.'), findsOneWidget);
    expect(find.byType(AuthCard), findsOneWidget);
    expect(find.text('Nama Lengkap'), findsOneWidget);
    expect(find.text('Nomor WhatsApp'), findsOneWidget);
    expect(find.text('Email (Opsional)'), findsOneWidget);
    expect(find.text('Ulangi Kata Sandi'), findsOneWidget);
    expect(find.text('Daftar dengan Google'), findsOneWidget);
    expect(find.text('Sudah punya akun?'), findsNothing);
    expect(find.text('Penjual UMKM'), findsNothing);
  });

  testWidgets('Halaman daftar tetap dapat digunakan di layar sempit', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap(const RegisterScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Selamat\nDatang!'), findsOneWidget);
    expect(find.text('Belanja & kelola usahamu lebih mudah.'), findsOneWidget);
    expect(find.byType(AuthCard), findsOneWidget);
    final subtitleRect = tester.getRect(
      find.text('Belanja & kelola usahamu lebih mudah.'),
    );
    final cardRect = tester.getRect(find.byType(AuthCard));
    expect(subtitleRect.bottom, lessThan(cardRect.top));
    expect(find.text('Nama Lengkap'), findsOneWidget);

    final submitButton = find.byKey(const ValueKey('register-submit-button'));
    await tester.ensureVisible(submitButton);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Form daftar tetap dapat digulir saat keyboard terbuka', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);

    await tester.pumpWidget(_wrap(const RegisterScreen()));
    await tester.pumpAndSettle();

    final firstField = find.byType(TextFormField).first;
    await tester.ensureVisible(firstField);
    await tester.tap(firstField);
    await tester.pumpAndSettle();

    final submitButton = find.byKey(const ValueKey('register-submit-button'));
    await tester.ensureVisible(submitButton);
    await tester.pumpAndSettle();

    expect(tester.getRect(submitButton).bottom, lessThanOrEqualTo(440));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Halaman daftar menolak kata sandi yang tidak sama', (
    tester,
  ) async {
    _useTallScreen(tester);
    await tester.pumpWidget(_wrap(const RegisterScreen()));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Budi Santoso');
    await tester.enterText(fields.at(1), '081234567890');
    await tester.enterText(fields.at(3), 'rahasia123');
    await tester.enterText(fields.at(4), 'rahasia456');
    await tester.pumpAndSettle();

    expect(find.text('Kata sandi tidak sama'), findsOneWidget);
  });

  testWidgets('Navigasi ke lupa kata sandi dan validasi email', (tester) async {
    _useTallScreen(tester);
    await tester.pumpWidget(_wrap(const LoginScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lupa sandi?'));
    await tester.pumpAndSettle();

    expect(find.text('Lupa Kata Sandi'), findsOneWidget);
    expect(find.text('Pulihkan Akses Akun'), findsOneWidget);
    expect(find.text('Akun Anda aman dan terlindungi'), findsOneWidget);

    final sendButton = find.byKey(const ValueKey('forgot-send-button'));
    await tester.ensureVisible(sendButton);
    await tester.tap(sendButton);
    await tester.pumpAndSettle();

    expect(find.text('Email wajib diisi'), findsOneWidget);
  });

  testWidgets('Halaman lupa kata sandi rapi pada layar sempit', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap(const ForgotPasswordScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Lupa Kata Sandi'), findsOneWidget);
    expect(find.byType(AuthCard), findsOneWidget);
    final subtitleRect = tester.getRect(
      find.text('Atur ulang sandi akunmu dengan kode OTP email.'),
    );
    final cardRect = tester.getRect(find.byType(AuthCard));
    expect(subtitleRect.bottom, lessThan(cardRect.top));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Dimensi card dan header tidak berubah saat keyboard terbuka', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);

    await tester.pumpWidget(_wrap(const LoginScreen()));
    await tester.pumpAndSettle();

    final cardBefore = tester.getRect(find.byType(AuthCard));
    final headerBefore = tester.getRect(find.byType(AuthBrandHeader));

    // Simulasi keyboard HP terbuka (tinggi sisa turun di bawah threshold 680px).
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();

    final cardAfter = tester.getRect(find.byType(AuthCard));
    final headerAfter = tester.getRect(find.byType(AuthBrandHeader));

    expect(cardAfter.width, cardBefore.width);
    expect(headerAfter.height, headerBefore.height);
    expect(tester.takeException(), isNull);
  });
}
