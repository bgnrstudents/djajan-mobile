import 'package:flutter/material.dart';

/// Shared Djajan palette: white and green, with green tints for surfaces.
class AppColors {
  static const Color hijauTua = Color(0xFF175D2B);
  static const Color hijauMuda = Color(0xFF5B9E68);
  static const Color hijauLembut = Color(0xFFEAF3EC);
  static const Color latar = Color(0xFFF3F7F3);
  static const Color putih = Color(0xFFFFFFFF);
  static const Color garis = Color(0xFFE2EBE2);
  static const Color textDark = Color(0xFF16201A);
  static const Color textGrey = Color(0xFF5F6B64);

  // Semantic aliases for consistency with brand and alert semantics
  static const Color kuning = Color(0xFFF59E0B);
  static const Color krem = latar;
  static const Color bgLavender = latar;
  static const Color cardWhite = putih;
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerBg = Color(0xFFFEF2F2);
  static const Color chipOrange = Color(0xFFFEF3C7);
  static const Color chipOrangeText = Color(0xFFD97706);
  static const Color chipGreenBg = hijauLembut;
}

class AppTheme {
  static ThemeData get theme {
    const fontFamily = 'Plus Jakarta Sans';
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.hijauTua,
      primary: AppColors.hijauTua,
      secondary: AppColors.hijauMuda,
      surface: AppColors.putih,
      error: AppColors.danger,
    );
    final baseTextTheme = Typography.material2021().black.apply(
      fontFamily: fontFamily,
      bodyColor: AppColors.textDark,
      displayColor: AppColors.textDark,
    );
    final textTheme = baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge?.copyWith(
        fontWeight: FontWeight.w700,
        height: 1.15,
      ),
      displayMedium: baseTextTheme.displayMedium?.copyWith(
        fontWeight: FontWeight.w700,
        height: 1.15,
      ),
      displaySmall: baseTextTheme.displaySmall?.copyWith(
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        height: 1.25,
      ),
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        height: 1.25,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      titleSmall: baseTextTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        fontWeight: FontWeight.w400,
        height: 1.45,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w400,
        height: 1.4,
      ),
      bodySmall: baseTextTheme.bodySmall?.copyWith(
        fontWeight: FontWeight.w400,
        height: 1.35,
      ),
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        height: 1.2,
      ),
      labelMedium: baseTextTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w500,
        height: 1.2,
      ),
      labelSmall: baseTextTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w500,
        height: 1.2,
      ),
    );
    final outline = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.garis),
    );

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.latar,
      // Gunakan transisi ringan tanpa SnapshotWidget agar route pop tidak
      // memicu layar hitam pada GPU Android OpenGLES tertentu (MediaTek/PowerVR).
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      fontFamily: fontFamily,
      fontFamilyFallback: const ['Roboto', 'Arial', 'sans-serif'],
      colorScheme: scheme,
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.latar,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.textDark,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          color: AppColors.textDark,
          fontSize: 19,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.putih,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.garis),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.hijauTua,
          foregroundColor: AppColors.putih,
          minimumSize: const Size.fromHeight(52),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.hijauTua,
          foregroundColor: AppColors.putih,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.hijauTua,
          side: const BorderSide(color: AppColors.garis),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.hijauTua,
        contentTextStyle: const TextStyle(
          fontFamily: fontFamily,
          color: AppColors.putih,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.putih,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: outline,
        enabledBorder: outline,
        focusedBorder: outline.copyWith(
          borderSide: const BorderSide(color: AppColors.hijauTua, width: 1.5),
        ),
        errorBorder: outline.copyWith(
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.putih,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
      ),
      dividerColor: AppColors.garis,
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.hijauTua,
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
