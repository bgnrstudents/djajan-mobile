import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/api_service.dart';
import 'auth_widgets.dart';

/// Halaman lupa kata sandi dengan verifikasi kode OTP 6 digit via email.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  int _step = 0; // 0: Input Email, 1: Input OTP & Password Baru, 2: Sukses
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String _sentToEmail = '';

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Email wajib diisi';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) {
      return 'Format email belum benar';
    }
    return null;
  }

  String? _validateOtp(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Kode OTP wajib diisi';
    if (v.length != 6 || int.tryParse(v) == null) {
      return 'Kode OTP harus berupa 6 digit angka';
    }
    return null;
  }

  Future<void> _submitEmail() async {
    FocusScope.of(context).unfocus();
    if (!(_emailFormKey.currentState?.validate() ?? false)) return;

    final email = _emailController.text.trim();
    setState(() => _loading = true);

    try {
      await ApiService.postJson('password/forgot', {'email': email});
      if (!mounted) return;
      setState(() {
        _sentToEmail = email;
        _step = 1;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kode OTP telah dikirim ke $email'),
          backgroundColor: AuthStyle.primary,
        ),
      );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.pesan),
            backgroundColor: AuthStyle.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitReset() async {
    FocusScope.of(context).unfocus();
    if (!(_resetFormKey.currentState?.validate() ?? false)) return;

    final otp = _otpController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    setState(() => _loading = true);

    try {
      await ApiService.postJson('password/reset', {
        'email': _sentToEmail,
        'otp': otp,
        'password': password,
        'password_confirmation': confirm,
      });
      if (!mounted) return;
      setState(() {
        _step = 2;
      });
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.pesan),
            backgroundColor: AuthStyle.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resendOtp() async {
    if (_loading || _sentToEmail.isEmpty) return;
    setState(() => _loading = true);

    try {
      await ApiService.postJson('password/forgot', {'email': _sentToEmail});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kode baru telah dikirim ulang ke $_sentToEmail'),
          backgroundColor: AuthStyle.primary,
        ),
      );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.pesan),
            backgroundColor: AuthStyle.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
              subtitle: 'Atur ulang kata sandi akunmu dengan verifikasi email',
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
                        child: _buildCurrentStep(),
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

  Widget _buildCurrentStep() {
    switch (_step) {
      case 0:
        return _stepEmailForm();
      case 1:
        return _stepResetForm();
      case 2:
      default:
        return _stepSuccessView();
    }
  }

  Widget _stepEmailForm() {
    return Form(
      key: _emailFormKey,
      child: Column(
        key: const ValueKey('step0'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CircleIcon(
            icon: Icons.lock_reset_rounded,
            color: AuthStyle.primary,
          ),
          const SizedBox(height: 16),
          const Text(
            'Lupa Kata Sandi?',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AuthStyle.textDark,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Masukkan alamat email yang terdaftar pada akun DJajan Anda. Kami akan mengirimkan 6 digit kode verifikasi.',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.5,
              color: AuthStyle.textGrey,
            ),
          ),
          const SizedBox(height: 20),

          AuthTextField(
            label: 'Alamat Email',
            hint: 'nama@email.com',
            icon: Icons.email_outlined,
            controller: _emailController,
            enabled: !_loading,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            validator: _validateEmail,
            onFieldSubmitted: (_) => _submitEmail(),
          ),
          const SizedBox(height: 22),

          AuthPrimaryButton(
            label: 'Kirim Kode Verifikasi',
            icon: Icons.send_rounded,
            loading: _loading,
            onPressed: _submitEmail,
          ),
          const SizedBox(height: 14),

          Center(
            child: TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: const Text('Kembali ke Halaman Masuk'),
              style: TextButton.styleFrom(
                foregroundColor: AuthStyle.textGrey,
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepResetForm() {
    return Form(
      key: _resetFormKey,
      child: Column(
        key: const ValueKey('step1'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CircleIcon(
            icon: Icons.mark_email_read_rounded,
            color: AuthStyle.primary,
          ),
          const SizedBox(height: 16),
          const Text(
            'Verifikasi Kode OTP',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AuthStyle.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Kode verifikasi telah dikirim ke $_sentToEmail. Masukkan kode tersebut dan buat kata sandi baru Anda.',
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.5,
              color: AuthStyle.textGrey,
            ),
          ),
          const SizedBox(height: 18),

          AuthTextField(
            label: 'Kode OTP (6 Digit)',
            hint: '123456',
            icon: Icons.pin_rounded,
            controller: _otpController,
            enabled: !_loading,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            validator: _validateOtp,
          ),
          const SizedBox(height: 14),

          AuthTextField(
            label: 'Kata Sandi Baru',
            hint: 'Minimal 8 karakter',
            icon: Icons.lock_outline_rounded,
            controller: _passwordController,
            enabled: !_loading,
            obscure: _obscurePassword,
            textInputAction: TextInputAction.next,
            validator: AuthValidators.kataSandi,
            suffix: IconButton(
              tooltip: _obscurePassword ? 'Tampilkan kata sandi' : 'Sembunyikan kata sandi',
              icon: Icon(
                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                size: 20,
                color: AuthStyle.textGrey,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          const SizedBox(height: 14),

          AuthTextField(
            label: 'Ulangi Kata Sandi Baru',
            hint: 'Ketik ulang kata sandi baru',
            icon: Icons.lock_reset_rounded,
            controller: _confirmPasswordController,
            enabled: !_loading,
            obscure: _obscureConfirm,
            textInputAction: TextInputAction.done,
            validator: (value) => AuthValidators.ulangiKataSandi(
              value,
              _passwordController.text,
            ),
            onFieldSubmitted: (_) => _submitReset(),
            suffix: IconButton(
              tooltip: _obscureConfirm ? 'Tampilkan kata sandi' : 'Sembunyikan kata sandi',
              icon: Icon(
                _obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                size: 20,
                color: AuthStyle.textGrey,
              ),
              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
          const SizedBox(height: 22),

          AuthPrimaryButton(
            label: 'Simpan Kata Sandi Baru',
            icon: Icons.check_circle_rounded,
            loading: _loading,
            onPressed: _submitReset,
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => setState(() => _step = 0),
                style: TextButton.styleFrom(
                  foregroundColor: AuthStyle.textGrey,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Ganti Email', style: TextStyle(fontSize: 12.5)),
              ),
              TextButton(
                onPressed: _resendOtp,
                style: TextButton.styleFrom(
                  foregroundColor: AuthStyle.primary,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Kirim Ulang Kode',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepSuccessView() {
    return Column(
      key: const ValueKey('step2'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _CircleIcon(
          icon: Icons.check_circle_rounded,
          color: AuthStyle.success,
        ),
        const SizedBox(height: 16),
        const Text(
          'Kata Sandi Diperbarui',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AuthStyle.textDark,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Kata sandi akun Anda berhasil diatur ulang. Silakan masuk kembali menggunakan kata sandi baru Anda.',
          style: TextStyle(
            fontSize: 12.5,
            height: 1.5,
            color: AuthStyle.textGrey,
          ),
        ),
        const SizedBox(height: 24),
        AuthPrimaryButton(
          label: 'Masuk Sekarang',
          icon: Icons.login_rounded,
          onPressed: () => Navigator.pop(context),
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
