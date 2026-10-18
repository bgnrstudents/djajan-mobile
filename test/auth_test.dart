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

Future<void> _tapButton(WidgetTester tester, String label) async {
  final button = find.widgetWithText(ElevatedButton, label);
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
}

void main() {
  testWidgets('Halaman masuk menampilkan elemen utama', (tester) async {
    _useTallScreen(tester);
    await tester.pumpWidget(_wrap(const LoginScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Selamat Datang'), findsOneWidget);
    expect(find.text('Masuk ke Akun'), findsOneWidget);
    expect(find.text('Nomor WhatsApp atau Email'), findsOneWidget);
    expect(find.text('Kata Sandi'), findsOneWidget);
    expect(find.text('Lupa sandi?'), findsOneWidget);
    expect(find.text('Daftar Sekarang'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Masuk'), findsOneWidget);
  });

  testWidgets('Validasi halaman masuk menampilkan pesan error', (tester) async {
    _useTallScreen(tester);
    await tester.pumpWidget(_wrap(const LoginScreen()));
    await tester.pumpAndSettle();

    await _tapButton(tester, 'Masuk');
    await tester.pumpAndSettle();

    expect(find.text('Nomor WhatsApp atau email wajib diisi'), findsOneWidget);
    expect(find.text('Kata sandi wajib diisi'), findsOneWidget);
  });

  testWidgets('Validasi format nomor WhatsApp pada halaman masuk', (tester) async {
    _useTallScreen(tester);
    await tester.pumpWidget(_wrap(const LoginScreen()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, '0812');
    await tester.pumpAndSettle();

    expect(find.text('Contoh format yang benar: 081234567890'), findsOneWidget);
  });

  testWidgets('Halaman daftar menampilkan seluruh field', (tester) async {
    _useTallScreen(tester);
    await tester.pumpWidget(_wrap(const RegisterScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Buat Akun Baru'), findsOneWidget);
    expect(find.text('Daftar sebagai Pembeli Warga'), findsOneWidget);
    expect(find.text('Nama Lengkap'), findsOneWidget);
    expect(find.text('Nomor WhatsApp'), findsOneWidget);
    expect(find.text('Email (Opsional)'), findsOneWidget);
    expect(find.text('Ulangi Kata Sandi'), findsOneWidget);
    // Pilihan peran sudah dihapus dari halaman daftar.
    expect(find.text('Penjual UMKM'), findsNothing);
  });

  testWidgets('Halaman daftar menolak kata sandi yang tidak sama', (tester) async {
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

  testWidgets('Alur lupa kata sandi sampai kode terkirim', (tester) async {
    _useTallScreen(tester);
    await tester.pumpWidget(_wrap(const LoginScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lupa sandi?'));
    await tester.pumpAndSettle();

    expect(find.text('Reset Kata Sandi'), findsOneWidget);

    await _tapButton(tester, 'Kirim Kode Reset');
    await tester.pumpAndSettle();
    expect(find.text('Nomor WhatsApp atau email wajib diisi'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, '081234567890');
    await tester.pumpAndSettle();

    await _tapButton(tester, 'Kirim Kode Reset');
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Kode Terkirim'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Kembali ke Halaman Masuk'),
        findsOneWidget);
  });
}
