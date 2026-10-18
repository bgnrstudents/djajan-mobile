import 'package:flutter/material.dart';

import 'auth_widgets.dart';

/// Halaman lupa kata sandi.
///
/// Catatan: pengiriman kode verifikasi masih disimulasikan karena belum ada
/// endpoint pemulihan kata sandi di backend. Bagian UI & alur sudah siap,
/// tinggal disambungkan ke API saat backend tersedia.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();

  bool _loading = false;
  bool _sent = false;
  String _sentTo = '';

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    setState(() {
      _loading = false;
      _sent = true;
      _sentTo = _identifierController.text.trim();
    });
  }

  void _reset() {
    setState(() {
      _sent = false;
      _sentTo = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthStyle.bg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const AuthHero(
              title: 'Lupa Kata Sandi',
              subtitle: 'Tenang, kami bantu kamu masuk kembali ke akunmu',
            ),
            Transform.translate(
              offset: const Offset(0, -34),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                child: Column(
                  children: [
                    AuthCard(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: _sent ? _successView() : _formView(),
                      ),
                    ),
                    const SizedBox(height: 26),
                    const AuthFooter(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _formView() {
    return Form(
      key: _formKey,
      child: Column(
        key: const ValueKey('form'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CircleIcon(
            icon: Icons.lock_reset_rounded,
            color: AuthStyle.primary,
          ),
          const SizedBox(height: 16),
          const Text(
            'Reset Kata Sandi',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AuthStyle.textDark,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Masukkan nomor WhatsApp atau email yang terdaftar. Kami akan '
            'mengirim kode verifikasi untuk mengatur ulang kata sandi kamu.',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.5,
              color: AuthStyle.textGrey,
            ),
          ),
          const SizedBox(height: 20),

          AuthTextField(
            label: 'Nomor WhatsApp atau Email',
            hint: 'Contoh: 081234567890',
            icon: Icons.person_outline_rounded,
            controller: _identifierController,
            enabled: !_loading,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            validator: AuthValidators.identitas,
            onFieldSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 22),

          AuthPrimaryButton(
            label: 'Kirim Kode Reset',
            icon: Icons.send_rounded,
            loading: _loading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }

  Widget _successView() {
    return Column(
      key: const ValueKey('sent'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _CircleIcon(
          icon: Icons.mark_email_read_rounded,
          color: AuthStyle.success,
        ),
        const SizedBox(height: 16),
        const Text(
          'Kode Terkirim',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AuthStyle.textDark,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Kode verifikasi sudah dikirim ke $_sentTo. Masukkan kode tersebut '
          'untuk mengatur ulang kata sandi. Kode berlaku selama 5 menit.',
          style: const TextStyle(
            fontSize: 12.5,
            height: 1.5,
            color: AuthStyle.textGrey,
          ),
        ),
        const SizedBox(height: 22),
        AuthPrimaryButton(
          label: 'Kembali ke Halaman Masuk',
          icon: Icons.arrow_back_rounded,
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(height: 6),
        Center(
          child: TextButton(
            onPressed: _reset,
            style: TextButton.styleFrom(
              foregroundColor: AuthStyle.primary,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Salah nomor/email? Kirim ulang',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}

class _CircleIcon extends StatelessWidget {
  const _CircleIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      width: 56,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }
}
