import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/app_config.dart';

/// Palet & gaya bersama untuk semua halaman autentikasi
/// (Masuk, Daftar, Lupa Kata Sandi) supaya tampilannya konsisten.
class AuthStyle {
  AuthStyle._();

  static const Color primary = AppConfig.primaryColor; // #175D2B Deep Forest Green
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

/// Header mint lembut yang ringkas untuk dipadukan dengan kartu form mengambang.
class AuthLightHeader extends StatelessWidget {
  const AuthLightHeader({
    super.key,
    required this.mode,
    this.compact = false,
    this.showBackButton = false,
  });

  final AuthMode mode;
  final bool compact;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final illustrationWidth = compact ? 108.0 : 132.0;
    final illustrationHeight = compact ? 102.0 : 124.0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: CustomPaint(painter: _AuthTopWashPainter()),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            topPadding + (showBackButton ? 8 : 16),
            16,
            compact ? 42 : 48,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showBackButton) ...[
                Material(
                  color: AuthStyle.primary.withValues(alpha: 0.10),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => Navigator.pop(context),
                    child: const SizedBox(
                      height: 38,
                      width: 38,
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: AuthStyle.primary,
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
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/images/logo_djajan_mark.png',
                              height: compact ? 30 : 34,
                              width: compact ? 30 : 34,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Djajan',
                              style: TextStyle(
                                fontSize: compact ? 18 : 19.5,
                                fontWeight: FontWeight.w800,
                                color: AuthStyle.primary,
                                letterSpacing: -0.4,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: compact ? 10 : 12),
                        Text(
                          'Masuk atau\nDaftar',
                          style: TextStyle(
                            fontSize: compact ? 22 : 25,
                            fontWeight: FontWeight.w800,
                            color: AuthStyle.textDark,
                            height: 1.12,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Jajan & kelola usaha lokal lebih mudah.',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.35,
                            color: AuthStyle.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: illustrationWidth,
                    height: illustrationHeight,
                    child: CustomPaint(
                      painter: StorefrontIllustrationPainter(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AuthTopWashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final basePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFEAF4EC),
          Color(0xFFD8EBDC),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final bgRRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(0, 0, size.width, size.height),
      bottomLeft: const Radius.circular(32),
      bottomRight: const Radius.circular(32),
    );
    canvas.save();
    canvas.clipRRect(bgRRect);
    canvas.drawRRect(bgRRect, basePaint);

    final blob1 = Paint()..color = const Color(0xFFC4E1CA).withValues(alpha: 0.45);
    canvas.drawCircle(
      Offset(size.width * 0.88, size.height * 0.14),
      size.width * 0.27,
      blob1,
    );

    final blob2 = Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.35);
    canvas.drawCircle(
      Offset(size.width * 0.96, size.height * 0.58),
      size.width * 0.20,
      blob2,
    );
    canvas.restore();
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

/// Ilustrasi vektor toko UMKM bergaya clean editorial (tanpa aset eksternal).
class StorefrontIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final darkGreen = AuthStyle.primary;
    final midGreen = const Color(0xFF3E834E);
    final softGreen = const Color(0xFF7BB888);
    final glassTint = const Color(0xFFD9ECDE);
    final wallWhite = const Color(0xFFF9FBF9);
    final wallShade = const Color(0xFFEAEFEA);
    final strokePaint = Paint()
      ..color = const Color(0xFF23482E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    // Awan lembut di belakang atap
    final cloudPaint = Paint()..color = Colors.white.withValues(alpha: 0.75);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.44, h * 0.05, w * 0.46, h * 0.11),
        const Radius.circular(14),
      ),
      cloudPaint,
    );
    canvas.drawCircle(Offset(w * 0.62, h * 0.07), w * 0.08, cloudPaint);

    // Bayangan tanah
    final groundPaint = Paint()..color = const Color(0xFFCDE1D1);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.06, h * 0.87, w * 0.90, h * 0.06),
        const Radius.circular(10),
      ),
      groundPaint,
    );

    // Dinding sisi kiri (perspektif 3/4)
    final sideWall = Path()
      ..moveTo(w * 0.14, h * 0.34)
      ..lineTo(w * 0.34, h * 0.39)
      ..lineTo(w * 0.34, h * 0.88)
      ..lineTo(w * 0.14, h * 0.83)
      ..close();
    canvas.drawPath(sideWall, Paint()..color = wallShade);
    canvas.drawPath(sideWall, strokePaint);

    // Dinding depan toko
    final frontWall = RRect.fromRectAndCorners(
      Rect.fromLTWH(w * 0.34, h * 0.37, w * 0.56, h * 0.51),
      topRight: const Radius.circular(6),
    );
    canvas.drawRRect(frontWall, Paint()..color = wallWhite);
    canvas.drawRRect(frontWall, strokePaint);

    // Pintu kaca ganda + etalase kaca
    final frameRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.40, h * 0.48, w * 0.44, h * 0.40),
      const Radius.circular(4),
    );
    canvas.drawRRect(frameRect, Paint()..color = glassTint);
    canvas.drawRRect(frameRect, strokePaint);

    // Kusen pembagi pintu
    canvas.drawLine(
      Offset(w * 0.545, h * 0.48),
      Offset(w * 0.545, h * 0.88),
      strokePaint,
    );
    canvas.drawLine(
      Offset(w * 0.695, h * 0.48),
      Offset(w * 0.695, h * 0.88),
      strokePaint,
    );

    // Kilau kaca diagonal
    final glarePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.65)
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(w * 0.43, h * 0.54),
      Offset(w * 0.50, h * 0.64),
      glarePaint,
    );
    canvas.drawLine(
      Offset(w * 0.58, h * 0.53),
      Offset(w * 0.65, h * 0.63),
      glarePaint,
    );

    // Gagang pintu
    canvas.drawLine(
      Offset(w * 0.525, h * 0.66),
      Offset(w * 0.525, h * 0.72),
      strokePaint,
    );
    canvas.drawLine(
      Offset(w * 0.565, h * 0.66),
      Offset(w * 0.565, h * 0.72),
      strokePaint,
    );

    // Kanopi atap bergaris hijau-putih
    const stripeCount = 6;
    final awningTopLeft = Offset(w * 0.10, h * 0.25);
    final awningTopRight = Offset(w * 0.92, h * 0.22);
    final awningBotLeft = Offset(w * 0.05, h * 0.41);
    final awningBotRight = Offset(w * 0.94, h * 0.39);

    for (var i = 0; i < stripeCount; i++) {
      final t0 = i / stripeCount;
      final t1 = (i + 1) / stripeCount;
      final p0 = Offset.lerp(awningTopLeft, awningTopRight, t0)!;
      final p1 = Offset.lerp(awningTopLeft, awningTopRight, t1)!;
      final p2 = Offset.lerp(awningBotLeft, awningBotRight, t1)!;
      final p3 = Offset.lerp(awningBotLeft, awningBotRight, t0)!;

      final stripePath = Path()
        ..moveTo(p0.dx, p0.dy)
        ..lineTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..quadraticBezierTo(
          (p2.dx + p3.dx) / 2,
          (p2.dy + p3.dy) / 2 + h * 0.04,
          p3.dx,
          p3.dy,
        )
        ..close();

      canvas.drawPath(
        stripePath,
        Paint()..color = i.isEven ? darkGreen : wallWhite,
      );
      canvas.drawPath(stripePath, strokePaint);
    }

    // Papan nama gantung di kanan pintu
    final bracket = Path()
      ..moveTo(w * 0.74, h * 0.50)
      ..lineTo(w * 0.87, h * 0.50);
    canvas.drawPath(bracket, strokePaint);

    final signRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.74, h * 0.54, w * 0.17, h * 0.16),
      const Radius.circular(4),
    );
    canvas.drawRRect(signRect, Paint()..color = Colors.white);
    canvas.drawRRect(signRect, strokePaint);

    // Ikon daun kecil di papan nama
    final signCenter = Offset(w * 0.825, h * 0.62);
    canvas.drawCircle(signCenter, w * 0.055, Paint()..color = AuthStyle.softMint);
    final leafPath = Path()
      ..moveTo(signCenter.dx - 4, signCenter.dy + 3)
      ..quadraticBezierTo(
        signCenter.dx - 4,
        signCenter.dy - 5,
        signCenter.dx + 4,
        signCenter.dy - 4,
      )
      ..quadraticBezierTo(
        signCenter.dx + 4,
        signCenter.dy + 4,
        signCenter.dx - 4,
        signCenter.dy + 3,
      );
    canvas.drawPath(leafPath, Paint()..color = darkGreen);

    // Pot tanaman kiri
    _drawPottedPlant(
      canvas,
      Offset(w * 0.19, h * 0.88),
      potWidth: w * 0.11,
      potHeight: h * 0.09,
      leafRadius: w * 0.075,
      potColor: const Color(0xFFB5C7B8),
      leafColor: midGreen,
      strokePaint: strokePaint,
    );
    _drawPottedPlant(
      canvas,
      Offset(w * 0.30, h * 0.89),
      potWidth: w * 0.09,
      potHeight: h * 0.07,
      leafRadius: w * 0.055,
      potColor: Colors.white,
      leafColor: softGreen,
      strokePaint: strokePaint,
    );

    // Semak hijau kanan
    canvas.drawCircle(
      Offset(w * 0.90, h * 0.85),
      w * 0.065,
      Paint()..color = midGreen,
    );
    canvas.drawCircle(
      Offset(w * 0.85, h * 0.87),
      w * 0.045,
      Paint()..color = softGreen,
    );
  }

  void _drawPottedPlant(
    Canvas canvas,
    Offset baseCenter, {
    required double potWidth,
    required double potHeight,
    required double leafRadius,
    required Color potColor,
    required Color leafColor,
    required Paint strokePaint,
  }) {
    final leafCenter = Offset(baseCenter.dx, baseCenter.dy - potHeight - leafRadius * 0.65);
    canvas.drawCircle(leafCenter, leafRadius, Paint()..color = leafColor);
    canvas.drawCircle(
      Offset(leafCenter.dx - leafRadius * 0.45, leafCenter.dy + 3),
      leafRadius * 0.62,
      Paint()..color = leafColor,
    );
    canvas.drawCircle(
      Offset(leafCenter.dx + leafRadius * 0.45, leafCenter.dy + 4),
      leafRadius * 0.58,
      Paint()..color = leafColor,
    );

    final pot = Path()
      ..moveTo(baseCenter.dx - potWidth * 0.55, baseCenter.dy - potHeight)
      ..lineTo(baseCenter.dx + potWidth * 0.55, baseCenter.dy - potHeight)
      ..lineTo(baseCenter.dx + potWidth * 0.38, baseCenter.dy)
      ..lineTo(baseCenter.dx - potWidth * 0.38, baseCenter.dy)
      ..close();
    canvas.drawPath(pot, Paint()..color = potColor);
    canvas.drawPath(pot, strokePaint);
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
            style: const TextStyle(
              fontSize: 12,
              color: AuthStyle.textGrey,
            ),
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
    canvas.drawArc(rect, -math.pi * 0.80, math.pi * 0.56, false, arcPaint(const Color(0xFFEA4335)));
    // Kuning (kiri)
    canvas.drawArc(rect, math.pi * 0.72, math.pi * 0.48, false, arcPaint(const Color(0xFFFBBC05)));
    // Hijau (bawah)
    canvas.drawArc(rect, math.pi * 0.18, math.pi * 0.55, false, arcPaint(const Color(0xFF34A853)));
    // Biru (kanan bawah)
    canvas.drawArc(rect, -math.pi * 0.04, math.pi * 0.25, false, arcPaint(const Color(0xFF4285F4)));

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

/// Header bergradien dengan logo, judul, dan subjudul.
class AuthHero extends StatelessWidget {
  const AuthHero({
    super.key,
    required this.title,
    required this.subtitle,
    this.height = 282,
  });

  final String title;
  final String subtitle;
  final double height;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);

    return Container(
      height: height,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AuthStyle.heroGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Stack(
        children: [
          // Dekorasi lingkaran lembut supaya header tidak terlihat datar.
          const Positioned(
            top: -42,
            right: -30,
            child: _Bubble(size: 132, opacity: 0.07),
          ),
          const Positioned(
            top: 58,
            left: -50,
            child: _Bubble(size: 112, opacity: 0.05),
          ),
          const Positioned(
            bottom: -30,
            right: 42,
            child: _Bubble(size: 82, opacity: 0.04),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 22),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      height: 40,
                      width: 40,
                      child: canPop
                          ? Material(
                              color: Colors.white.withValues(alpha: 0.16),
                              shape: const CircleBorder(),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () => Navigator.pop(context),
                                child: const Icon(
                                  Icons.arrow_back_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    height: 76,
                    width: 76,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/logoNoBg.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: Colors.white.withValues(alpha: 0.84),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
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
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.07),
            blurRadius: 26,
            offset: const Offset(0, 12),
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
    prefixIcon: Icon(icon, size: 20, color: AuthStyle.textGrey),
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

/// Badge "Didukung oleh BUMDes" + catatan hak cipta.
class AuthFooter extends StatelessWidget {
  const AuthFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 330),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AuthStyle.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_rounded,
                  size: 16,
                  color: AuthStyle.primary,
                ),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Didukung oleh pelaku usaha lokal',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AuthStyle.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Pemberdayaan Ekonomi Warga © 2025 Djajan',
          style: TextStyle(fontSize: 12, color: AuthStyle.hint),
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
