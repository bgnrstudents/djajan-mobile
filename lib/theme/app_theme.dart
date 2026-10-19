import 'package:flutter/material.dart';

/// Warna diambil dari brand guideline Djajan (logo & palet warna).
class AppColors {
  static const Color hijauTua = Color(0xFF0B4D2E); // Lokal, alami, kepercayaan
  static const Color hijauMuda = Color(0xFF6FBE6A); // Kesegaran, harapan
  static const Color kuning = Color(0xFFF5B400); // Ekonomi, semangat
  static const Color krem = Color(0xFFF3E9DA); // Sederhana, hangat
  static const Color bgLavender = Color(0xFFF3F2FB);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF14231C);
  static const Color textGrey = Color(0xFF6B7280);
  static const Color danger = Color(0xFFDC3B3B);
  static const Color dangerBg = Color(0xFFFDEBEB);
  static const Color chipOrange = Color(0xFFFCE7C9);
  static const Color chipOrangeText = Color(0xFF9A6A00);
  static const Color chipGreenBg = Color(0xFFDDF3E1);
  static const Color garis = Color(0xFFE7E6F2);
}

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bgLavender,
      fontFamily: 'Roboto',
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.hijauTua,
        primary: AppColors.hijauTua,
        secondary: AppColors.hijauMuda,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bgLavender,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.textDark,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textDark,
          fontSize: 19,
          fontWeight: FontWeight.w700,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.hijauTua,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDADCE6)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDADCE6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.hijauTua, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
      ),
    );
  }
}

/// Format angka menjadi "Rp 18.500".
String formatRupiah(num value) {
  final s = value.toInt().abs().toString();
  final buffer = StringBuffer();
  int count = 0;
  for (int i = s.length - 1; i >= 0; i--) {
    buffer.write(s[i]);
    count++;
    if (count % 3 == 0 && i != 0) buffer.write('.');
  }
  final hasil = buffer.toString().split('').reversed.join();
  return value < 0 ? '-Rp $hasil' : 'Rp $hasil';
}