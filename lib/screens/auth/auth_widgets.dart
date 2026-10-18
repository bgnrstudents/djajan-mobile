import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/app_config.dart';

/// Palet & gaya bersama untuk semua halaman autentikasi
/// (Masuk, Daftar, Lupa Kata Sandi) supaya tampilannya konsisten.
class AuthStyle {
  AuthStyle._();

  static const Color primary = AppConfig.primaryColor; // #175D2B
  static const Color accent = AppConfig.secondaryColor; // #FFBE25

  static const Color bg = Color(0xFFF3F5F7);
  static const Color card = Colors.white;
  static const Color field = Color(0xFFF8FAFC);
  static const Color border = Color(0xFFE2E8F0);
  static const Color hint = Color(0xFF94A3B8);

  static const Color textDark = Color(0xFF14231C);
  static const Color textGrey = Color(0xFF64748B);
  static const Color danger = Color(0xFFDC2626);
  static const Color success = Color(0xFF15803D);

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0E4020), Color(0xFF175D2B), Color(0xFF2E8B57)],
    stops: [0.0, 0.55, 1.0],
  );
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
            top: -46,
            right: -34,
            child: _Bubble(size: 150, opacity: 0.10),
          ),
          const Positioned(
            top: 54,
            left: -56,
            child: _Bubble(size: 128, opacity: 0.07),
          ),
          const Positioned(
            bottom: -34,
            right: 46,
            child: _Bubble(size: 96, opacity: 0.06),
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
          decoration: authInputDecoration(icon: icon, hint: hint, suffix: suffix),
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
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

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
            borderRadius: BorderRadius.circular(14),
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
  });

  final String question;
  final String action;
  final VoidCallback onTap;

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
            child: Text(
              action,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: AuthStyle.primary,
              ),
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
                Icon(Icons.verified_rounded, size: 16, color: AuthStyle.primary),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Didukung oleh BUMDes Guyub Rukun Kreyongan Atas',
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
    return _phone.hasMatch(digits) ? null : 'Contoh format yang benar: 081234567890';
  }
}
