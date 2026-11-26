import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/app_config.dart';

/// Palet & gaya bersama untuk semua halaman autentikasi
/// (Masuk, Daftar, Lupa Kata Sandi) supaya tampilannya konsisten.
class AuthStyle {
  AuthStyle._();

  static const Color primary =
      AppConfig.primaryColor; // #175D2B Deep Forest Green
  static const Color accent = AppConfig.secondaryColor;

  static const Color bg = Color(0xFFF3F7F3);
  static const Color softMint = Color(0xFFEAF3EC);
  static const Color softMintDeep = Color(0xFFD9EBDD);
  static const Color card = Colors.white;
  static const Color field = Color(0xFFF5F8F6);
  static const Color border = Color(0xFFE2EBE4);
  static const Color hint = Color(0xFF8A9A90);

  static const Color textDark = Color(0xFF16201A);
  static const Color textGrey = Color(0xFF5F6B64);
  static const Color danger = Color(0xFFDC2626);
  static const Color success = Color(0xFF175D2B);

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0B4E32), Color(0xFF175D2B), Color(0xFF267D3C)],
    stops: [0.0, 0.55, 1.0],
  );
}

enum AuthMode { login, register }

/// Kerangka layout bersama untuk Login, Register, dan Lupa Kata Sandi.
/// Mengunci dimensi responsif pada ukuran layar penuh (bukan tinggi sisa
/// saat keyboard muncul) agar tampilan tidak membesar/melompat ketika mengetik.
class AuthScreenShell extends StatelessWidget {
  const AuthScreenShell({
    super.key,
    required this.contentBuilder,
    this.headerTitle = 'Selamat\nDatang!',
    this.headerSubtitle = 'Belanja & kelola usahamu lebih mudah.',
    this.headerTopExtra = 0.0,
    this.bottomBuilder,
  });

  final Widget Function(BuildContext context, bool compact) contentBuilder;
  final String headerTitle;
  final String headerSubtitle;
  final double headerTopExtra;
  final Widget? bottomBuilder;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);
    final padding = MediaQuery.paddingOf(context);
    final topPadding = padding.top;
    final bottomInset = padding.bottom;
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Scaffold(
      backgroundColor: AuthStyle.bg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Gunakan screenHeight (bukan constraints.maxHeight yang menyusut
          // saat keyboard terbuka) agar card dan header tidak tiba-tiba berubah
          // skala/lebar ("nge-zoom") ketika user mulai mengetik.
          final compact = constraints.maxWidth < 360 || screenHeight < 680;
          final horizontalPadding = constraints.maxWidth >= 600
              ? 28.0
              : compact
              ? 14.0
              : 18.0;
          final cardTop =
              topPadding +
              headerTopExtra +
              (canPop
                  ? (compact ? 196.0 : 212.0)
                  : (compact ? 160.0 : 178.0));
          final heroHeight = cardTop + 38.0;

          return Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: screenHeight,
                child: IgnorePointer(
                  child: CustomPaint(painter: AuthBottomWavePainter()),
                ),
              ),
              SingleChildScrollView(
                padding: EdgeInsets.only(bottom: bottomInset + 20),
                child: Stack(
                  children: [
                    AuthBrandHeader(
                      height: heroHeight,
                      compact: compact,
                      showBackButton: canPop,
                      title: headerTitle,
                      subtitle: headerSubtitle,
                    ),
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            cardTop,
                            horizontalPadding,
                            0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AuthCard(
                                padding: EdgeInsets.fromLTRB(
                                  compact ? 15 : 18,
                                  18,
                                  compact ? 15 : 18,
                                  20,
                                ),
                                child: contentBuilder(context, compact),
                              ),
                              if (bottomBuilder != null) ...[
                                const SizedBox(height: 16),
                                bottomBuilder!,
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Header gradien hijau tua mewah dengan ilustrasi toko & skuter pengantar di kanan.
class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({
    super.key,
    required this.height,
    this.compact = false,
    this.showBackButton = false,
    this.title = 'Selamat\nDatang!',
    this.subtitle = 'Belanja & kelola usahamu lebih mudah.',
  });

  final double height;
  final bool compact;
  final bool showBackButton;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final artWidth = compact ? 116.0 : 148.0;
    final artHeight = compact ? 104.0 : 132.0;

    return Container(
      height: height,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0B4326),
            Color(0xFF135A31),
            Color(0xFF1B703F),
          ],
          stops: [0.0, 0.52, 1.0],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(34)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _HeaderGridGlowPainter()),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 16 : 20,
              topPadding + (showBackButton ? 8 : (compact ? 14 : 18)),
              compact ? 12 : 16,
              36,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showBackButton) ...[
                  Material(
                    color: Colors.white.withValues(alpha: 0.16),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.pop(context),
                      child: const SizedBox(
                        height: 36,
                        width: 36,
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                height: compact ? 32 : 36,
                                width: compact ? 32 : 36,
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(11),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.16,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Image.asset(
                                  'assets/images/logo_djajan_mark.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(width: 9),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Djajan',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: compact ? 17 : 19,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: -0.3,
                                        height: 1.05,
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    const Text(
                                      'Dari Desa, Untuk Semua',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        color: Color(0xFFD4EED8),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: compact ? 10 : 12),
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: compact ? 21 : 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.5,
                              height: 1.08,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: compact ? 11.5 : 12,
                              color: const Color(0xFFD4EED8),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: artWidth,
                      height: artHeight,
                      child: CustomPaint(
                        painter: _HeaderWarungScooterPainter(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderGridGlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Lingkaran cahaya lembut di kanan atas
    canvas.drawCircle(
      Offset(size.width * 0.88, size.height * 0.16),
      size.width * 0.25,
      Paint()..color = Colors.white.withValues(alpha: 0.06),
    );
    canvas.drawCircle(
      Offset(size.width * 0.94, size.height * 0.68),
      size.width * 0.16,
      Paint()..color = Colors.white.withValues(alpha: 0.05),
    );
    canvas.drawCircle(
      Offset(size.width * 0.06, size.height * 0.82),
      size.width * 0.14,
      Paint()..color = Colors.white.withValues(alpha: 0.04),
    );

    // Aksen grid tipis di bagian kanan belakang toko
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 0.8;
    const step = 13.0;
    final startX = size.width * 0.50;
    final endX = size.width * 0.94;
    final startY = size.height * 0.14;
    final endY = size.height * 0.70;

    for (var x = startX; x <= endX; x += step) {
      canvas.drawLine(Offset(x, startY), Offset(x, endY), gridPaint);
    }
    for (var y = startY; y <= endY; y += step) {
      canvas.drawLine(Offset(startX, y), Offset(endX, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Ilustrasi toko UMKM bernuansa krem-mint + skuter pengantar di header hijau tua.
class _HeaderWarungScooterPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final wallLight = const Color(0xFFEDF5EE);
    final wallShade = const Color(0xFFD5E6D8);
    final darkGreen = const Color(0xFF175D2B);
    final midGreen = const Color(0xFF4F9660);
    final mintAccent = const Color(0xFF83BC8E);
    final warmWindow = const Color(0xFFFEF3C7);
    final stroke = Paint()
      ..color = const Color(0xFF1D4D2E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    // Pohon lembut di belakang kanan
    canvas.drawOval(
      Rect.fromLTWH(w * 0.80, h * 0.22, w * 0.17, h * 0.42),
      Paint()..color = const Color(0xFF3E834E).withValues(alpha: 0.65),
    );
    canvas.drawLine(
      Offset(w * 0.885, h * 0.55),
      Offset(w * 0.885, h * 0.84),
      Paint()
        ..color = const Color(0xFF174A28)
        ..strokeWidth = 2.2,
    );

    // Bayangan lantai di bawah toko & skuter
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.04, h * 0.84, w * 0.92, h * 0.05),
        const Radius.circular(6),
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.18),
    );

    // Bagian samping kanan bangunan (dengan unit AC kecil)
    final sideBlock = RRect.fromRectAndCorners(
      Rect.fromLTWH(w * 0.64, h * 0.30, w * 0.24, h * 0.55),
      topRight: const Radius.circular(5),
    );
    canvas.drawRRect(sideBlock, Paint()..color = wallShade);
    canvas.drawRRect(sideBlock, stroke);

    final acRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.68, h * 0.37, w * 0.14, h * 0.10),
      const Radius.circular(2.5),
    );
    canvas.drawRRect(acRect, Paint()..color = wallLight);
    canvas.drawRRect(acRect, stroke);
    canvas.drawCircle(
      Offset(w * 0.72, h * 0.42),
      w * 0.025,
      Paint()..color = mintAccent,
    );

    // Bangunan utama toko
    final mainBlock = RRect.fromRectAndCorners(
      Rect.fromLTWH(w * 0.10, h * 0.24, w * 0.55, h * 0.61),
      topLeft: const Radius.circular(5),
      topRight: const Radius.circular(5),
    );
    canvas.drawRRect(mainBlock, Paint()..color = wallLight);
    canvas.drawRRect(mainBlock, stroke);

    // Lis atap atas
    final roofTrim = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.08, h * 0.22, w * 0.60, h * 0.06),
      const Radius.circular(3),
    );
    canvas.drawRRect(roofTrim, Paint()..color = wallShade);
    canvas.drawRRect(roofTrim, stroke);

    // Jendela etalase kiri (hangat bercahaya)
    final windowRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.15, h * 0.46, w * 0.27, h * 0.22),
      const Radius.circular(3),
    );
    canvas.drawRRect(windowRect, Paint()..color = warmWindow);
    canvas.drawRRect(windowRect, stroke);

    // Rak pot / jajanan kecil di ambang jendela
    for (var i = 0; i < 3; i++) {
      final bx = w * (0.18 + i * 0.08);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(bx, h * 0.62, w * 0.05, h * 0.05),
          const Radius.circular(1.5),
        ),
        Paint()..color = const Color(0xFFD97706),
      );
      canvas.drawCircle(
        Offset(bx + w * 0.025, h * 0.60),
        w * 0.028,
        Paint()..color = midGreen,
      );
    }

    // Pintu toko di tengah-kanan
    final doorRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(w * 0.46, h * 0.45, w * 0.14, h * 0.40),
      topLeft: const Radius.circular(3),
      topRight: const Radius.circular(3),
    );
    canvas.drawRRect(doorRect, Paint()..color = wallShade);
    canvas.drawRRect(doorRect, stroke);
    final doorGlass = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.485, h * 0.49, w * 0.09, h * 0.14),
      const Radius.circular(2),
    );
    canvas.drawRRect(doorGlass, Paint()..color = warmWindow);
    canvas.drawRRect(doorGlass, stroke);

    // Kanopi bergaris hijau tua & putih di atas etalase
    const stripes = 6;
    final aTopL = Offset(w * 0.10, h * 0.30);
    final aTopR = Offset(w * 0.64, h * 0.30);
    final aBotL = Offset(w * 0.05, h * 0.41);
    final aBotR = Offset(w * 0.63, h * 0.41);
    for (var i = 0; i < stripes; i++) {
      final t0 = i / stripes;
      final t1 = (i + 1) / stripes;
      final p0 = Offset.lerp(aTopL, aTopR, t0)!;
      final p1 = Offset.lerp(aTopL, aTopR, t1)!;
      final p2 = Offset.lerp(aBotL, aBotR, t1)!;
      final p3 = Offset.lerp(aBotL, aBotR, t0)!;
      final path = Path()
        ..moveTo(p0.dx, p0.dy)
        ..lineTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..quadraticBezierTo(
          (p2.dx + p3.dx) / 2,
          p2.dy + h * 0.03,
          p3.dx,
          p3.dy,
        )
        ..close();
      canvas.drawPath(
        path,
        Paint()..color = i.isEven ? darkGreen : Colors.white,
      );
      canvas.drawPath(path, stroke);
    }

    // Tanaman pot di kiri depan
    canvas.drawCircle(
      Offset(w * 0.09, h * 0.70),
      w * 0.055,
      Paint()..color = midGreen,
    );
    canvas.drawCircle(
      Offset(w * 0.06, h * 0.73),
      w * 0.04,
      Paint()..color = mintAccent,
    );
    final leftPot = Path()
      ..moveTo(w * 0.05, h * 0.75)
      ..lineTo(w * 0.13, h * 0.75)
      ..lineTo(w * 0.115, h * 0.85)
      ..lineTo(w * 0.065, h * 0.85)
      ..close();
    canvas.drawPath(leftPot, Paint()..color = const Color(0xFFD97706));
    canvas.drawPath(leftPot, stroke);

    // Tanaman kecil di sebelah pintu
    canvas.drawCircle(
      Offset(w * 0.65, h * 0.77),
      w * 0.038,
      Paint()..color = mintAccent,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.625, h * 0.79, w * 0.05, h * 0.06),
        const Radius.circular(2),
      ),
      Paint()..color = wallLight,
    );

    // Skuter pengantar kecil di kanan depan
    final wheelPaint = Paint()..color = const Color(0xFF1F2937);
    final rimPaint = Paint()..color = Colors.white;
    // Roda belakang & depan
    for (final wx in [w * 0.74, w * 0.90]) {
      canvas.drawCircle(Offset(wx, h * 0.81), w * 0.046, wheelPaint);
      canvas.drawCircle(Offset(wx, h * 0.81), w * 0.022, rimPaint);
    }
    // Bodi skuter mint
    final scooterBody = Path()
      ..moveTo(w * 0.70, h * 0.78)
      ..quadraticBezierTo(w * 0.73, h * 0.71, w * 0.80, h * 0.73)
      ..lineTo(w * 0.86, h * 0.75)
      ..lineTo(w * 0.85, h * 0.64)
      ..lineTo(w * 0.88, h * 0.64)
      ..lineTo(w * 0.92, h * 0.79)
      ..lineTo(w * 0.71, h * 0.80)
      ..close();
    canvas.drawPath(scooterBody, Paint()..color = mintAccent);
    canvas.drawPath(scooterBody, stroke);

    // Jok & stang + lampu depan
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.73, h * 0.70, w * 0.085, h * 0.032),
        const Radius.circular(3),
      ),
      Paint()..color = darkGreen,
    );
    canvas.drawCircle(
      Offset(w * 0.895, h * 0.66),
      w * 0.022,
      Paint()..color = warmWindow,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Dekorasi gelombang mint halus di bagian bawah halaman auth.
class AuthBottomWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final leftPaint = Paint()
      ..color = const Color(0xFFE3F0E6).withValues(alpha: 0.75);
    final leftWave = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height - 64)
      ..quadraticBezierTo(
        size.width * 0.24,
        size.height - 14,
        size.width * 0.48,
        size.height,
      )
      ..close();
    canvas.drawPath(leftWave, leftPaint);

    final rightPaint = Paint()
      ..color = const Color(0xFFD8EADC).withValues(alpha: 0.7);
    final rightWave = Path()
      ..moveTo(size.width, size.height)
      ..lineTo(size.width, size.height - 76)
      ..quadraticBezierTo(
        size.width * 0.74,
        size.height - 18,
        size.width * 0.50,
        size.height,
      )
      ..close();
    canvas.drawPath(rightWave, rightPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Tab switcher berbentuk pill: Masuk | Daftar.
class AuthModeSwitcher extends StatelessWidget {
  const AuthModeSwitcher({
    super.key,
    required this.mode,
    required this.onChanged,
    this.enabled = true,
  });

  final AuthMode mode;
  final ValueChanged<AuthMode> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AuthStyle.field,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AuthStyle.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeTabButton(
              key: const ValueKey('auth-tab-login'),
              label: 'Masuk',
              icon: Icons.login_rounded,
              selected: mode == AuthMode.login,
              enabled: enabled,
              onTap: () => onChanged(AuthMode.login),
            ),
          ),
          Expanded(
            child: _ModeTabButton(
              key: const ValueKey('auth-tab-register'),
              label: 'Daftar',
              icon: Icons.person_add_outlined,
              selected: mode == AuthMode.register,
              enabled: enabled,
              onTap: () => onChanged(AuthMode.register),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeTabButton extends StatelessWidget {
  const _ModeTabButton({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(26),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AuthStyle.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? Colors.white : AuthStyle.textGrey,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: selected ? Colors.white : AuthStyle.textGrey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Garis pemisah "atau masuk dengan".
class AuthOrDivider extends StatelessWidget {
  const AuthOrDivider({super.key, this.label = 'atau masuk dengan'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AuthStyle.border, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: AuthStyle.textGrey),
          ),
        ),
        const Expanded(child: Divider(color: AuthStyle.border, thickness: 1)),
      ],
    );
  }
}

/// Tombol Google Sign-In bergaya pill dengan ikon G berwarna.
class AuthGoogleButton extends StatelessWidget {
  const AuthGoogleButton({
    super.key,
    required this.onPressed,
    this.label = 'Masuk dengan Google',
    this.enabled = true,
  });

  final VoidCallback onPressed;
  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: enabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AuthStyle.textDark,
          side: const BorderSide(color: AuthStyle.border, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CustomPaint(painter: _GoogleLogoPainter()),
              ),
              const SizedBox(width: 10),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.19;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );

    Paint arcPaint(Color color) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    // Merah (atas)
    canvas.drawArc(
      rect,
      -math.pi * 0.80,
      math.pi * 0.56,
      false,
      arcPaint(const Color(0xFFEA4335)),
    );
    // Kuning (kiri)
    canvas.drawArc(
      rect,
      math.pi * 0.72,
      math.pi * 0.48,
      false,
      arcPaint(const Color(0xFFFBBC05)),
    );
    // Hijau (bawah)
    canvas.drawArc(
      rect,
      math.pi * 0.18,
      math.pi * 0.55,
      false,
      arcPaint(const Color(0xFF34A853)),
    );
    // Biru (kanan bawah)
    canvas.drawArc(
      rect,
      -math.pi * 0.04,
      math.pi * 0.25,
      false,
      arcPaint(const Color(0xFF4285F4)),
    );

    // Palang horizontal biru pada huruf G
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.52,
        size.height * 0.42,
        size.width * 0.46,
        stroke,
      ),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Badge keamanan "Akun Anda aman dan terlindungi | Djajan".
class AuthSecurityBadge extends StatelessWidget {
  const AuthSecurityBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AuthStyle.softMint,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.verified_user_outlined,
            size: 18,
            color: AuthStyle.primary,
          ),
          const SizedBox(width: 8),
          const Flexible(
            child: Text(
              'Akun Anda aman dan terlindungi',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: AuthStyle.textDark,
              ),
            ),
          ),
          Container(
            height: 16,
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            color: AuthStyle.primary.withValues(alpha: 0.22),
          ),
          Image.asset(
            'assets/images/logo_djajan_mark.png',
            height: 18,
            width: 18,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 5),
          const Text(
            'Djajan',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: AuthStyle.primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu putih pembungkus form.
class AuthCard extends StatelessWidget {
  const AuthCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        color: AuthStyle.card,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE5EEE7)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F4B28).withValues(alpha: 0.09),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

enum AuthNoticeTone { error, warning, info }

class AuthNotice extends StatelessWidget {
  const AuthNotice({
    super.key,
    required this.message,
    this.tone = AuthNoticeTone.error,
  });

  final String message;
  final AuthNoticeTone tone;

  @override
  Widget build(BuildContext context) {
    final (background, border, foreground, icon) = switch (tone) {
      AuthNoticeTone.error => (
        const Color(0xFFFFF1F1),
        const Color(0xFFFECACA),
        const Color(0xFFB91C1C),
        Icons.error_outline_rounded,
      ),
      AuthNoticeTone.warning => (
        const Color(0xFFFFF8E8),
        const Color(0xFFFDE68A),
        const Color(0xFF9A6700),
        Icons.info_outline_rounded,
      ),
      AuthNoticeTone.info => (
        const Color(0xFFEEF6F0),
        const Color(0xFFD8E9DB),
        AuthStyle.primary,
        Icons.check_circle_outline_rounded,
      ),
    };

    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: background,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 19, color: foreground),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.4,
                  color: foreground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Satu baris field dengan label di atasnya.
class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.icon,
    this.hint,
    this.obscure = false,
    this.suffix,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.validator,
    this.enabled = true,
    this.autofillHints,
    this.onFieldSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final IconData icon;
  final String? hint;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final bool enabled;
  final Iterable<String>? autofillHints;
  final void Function(String)? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AuthStyle.textDark,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          enabled: enabled,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          inputFormatters: inputFormatters,
          validator: validator,
          autofillHints: autofillHints,
          onFieldSubmitted: onFieldSubmitted,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          style: const TextStyle(fontSize: 15, color: AuthStyle.textDark),
          decoration: authInputDecoration(
            icon: icon,
            hint: hint,
            suffix: suffix,
          ),
        ),
      ],
    );
  }
}

/// Gaya seragam untuk semua input di halaman auth.
InputDecoration authInputDecoration({
  required IconData icon,
  String? hint,
  Widget? suffix,
}) {
  OutlineInputBorder outline(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 14, color: AuthStyle.hint),
    prefixIcon: Padding(
      padding: const EdgeInsets.only(left: 14, right: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: AuthStyle.textGrey),
          const SizedBox(width: 10),
          Container(
            width: 1,
            height: 20,
            color: AuthStyle.border,
          ),
        ],
      ),
    ),
    prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
    suffixIcon: suffix,
    filled: true,
    fillColor: AuthStyle.field,
    isDense: true,
    errorMaxLines: 2,
    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
    border: outline(AuthStyle.border),
    enabledBorder: outline(AuthStyle.border),
    disabledBorder: outline(AuthStyle.border),
    focusedBorder: outline(AuthStyle.primary, 1.6),
    errorBorder: outline(AuthStyle.danger),
    focusedErrorBorder: outline(AuthStyle.danger, 1.6),
    errorStyle: const TextStyle(fontSize: 12, color: AuthStyle.danger),
  );
}

/// Tombol utama hijau dengan indikator loading.
class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.icon,
    this.borderRadius = 28,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AuthStyle.primary,
          disabledBackgroundColor: AuthStyle.primary.withValues(alpha: 0.65),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: loading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              )
            // FittedBox menjaga label tetap utuh walau ukuran font sistem besar.
            : FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (icon != null) ...[
                      const SizedBox(width: 8),
                      Icon(icon, size: 19),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}

/// Baris "Belum punya akun? Daftar Sekarang".
class AuthLinkRow extends StatelessWidget {
  const AuthLinkRow({
    super.key,
    required this.question,
    required this.action,
    required this.onTap,
    this.trailingIcon,
  });

  final String question;
  final String action;
  final VoidCallback onTap;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    // Wrap supaya teks tetap rapi walau layar sempit atau font sistem besar.
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          question,
          style: const TextStyle(fontSize: 13.5, color: AuthStyle.textGrey),
        ),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  action,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: AuthStyle.primary,
                  ),
                ),
                if (trailingIcon != null) ...[
                  const SizedBox(width: 2),
                  Icon(trailingIcon, size: 17, color: AuthStyle.primary),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Kotak informasi kecil (mis. dipakai di halaman daftar).
class AuthInfoBox extends StatelessWidget {
  const AuthInfoBox({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: AuthStyle.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AuthStyle.primary),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                height: 1.4,
                color: AuthStyle.textGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kumpulan validator dengan pesan berbahasa Indonesia.
class AuthValidators {
  AuthValidators._();

  static final RegExp _email = RegExp(r'^[\w.+\-]+@[\w\-]+\.[\w.\-]+$');
  static final RegExp _phone = RegExp(r'^(\+?62|0)8[1-9][0-9]{6,11}$');
  static final RegExp _separator = RegExp(r'[\s\-()]');

  static String? namaLengkap(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Nama lengkap wajib diisi';
    if (v.length < 3) return 'Nama minimal 3 karakter';
    if (RegExp(r'^[0-9\s]+$').hasMatch(v)) return 'Nama tidak boleh angka saja';
    return null;
  }

  static String? nomorWhatsApp(String? value) {
    final v = (value ?? '').replaceAll(_separator, '');
    if (v.isEmpty) return 'Nomor WhatsApp wajib diisi';
    if (!_phone.hasMatch(v)) return 'Contoh format yang benar: 081234567890';
    return null;
  }

  static String? emailOpsional(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return null;
    if (!_email.hasMatch(v)) return 'Format email belum benar';
    return null;
  }

  static String? emailWajib(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Email wajib diisi';
    if (!_email.hasMatch(v)) return 'Format email belum benar';
    return null;
  }

  static String? kataSandi(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Kata sandi wajib diisi';
    if (v.length < 8) return 'Kata sandi minimal 8 karakter';
    return null;
  }

  static String? ulangiKataSandi(String? value, String sandi) {
    if ((value ?? '').isEmpty) return 'Ulangi kata sandi kamu';
    if (value != sandi) return 'Kata sandi tidak sama';
    return null;
  }

  /// Untuk kolom yang boleh diisi nomor WhatsApp atau email.
  static String? identitas(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Nomor WhatsApp atau email wajib diisi';
    if (v.contains('@')) {
      return _email.hasMatch(v) ? null : 'Format email belum benar';
    }
    final digits = v.replaceAll(_separator, '');
    return _phone.hasMatch(digits)
        ? null
        : 'Contoh format yang benar: 081234567890';
  }
}
