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
  String? _noticeMessage;
  AuthNoticeTone _noticeTone = AuthNoticeTone.error;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showNotice(String message, AuthNoticeTone tone) {
    setState(() {
      _noticeMessage = message;
      _noticeTone = tone;
    });
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
    setState(() {
      _loading = true;
      _noticeMessage = null;
    });

    try {
      await ApiService.postJson('password/forgot', {'email': email});
      if (!mounted) return;
      setState(() {
        _sentToEmail = email;
        _step = 1;
        _noticeMessage = 'Kode OTP 6 digit telah dikirim ke $email.';
        _noticeTone = AuthNoticeTone.info;
      });
    } on ApiException catch (e) {
      if (mounted) {
        _showNotice(e.pesan, AuthNoticeTone.error);
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

    setState(() {
      _loading = true;
      _noticeMessage = null;
    });

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
        _noticeMessage = null;
      });
    } on ApiException catch (e) {
      if (mounted) {
        _showNotice(e.pesan, AuthNoticeTone.error);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resendOtp() async {
    if (_loading || _sentToEmail.isEmpty) return;
    setState(() {
      _loading = true;
      _noticeMessage = null;
    });

    try {
      await ApiService.postJson('password/forgot', {'email': _sentToEmail});
      if (!mounted) return;
      _showNotice(
        'Kode verifikasi baru telah dikirim ulang ke $_sentToEmail.',
        AuthNoticeTone.info,
      );
    } on ApiException catch (e) {
      if (mounted) {
        _showNotice(e.pesan, AuthNoticeTone.error);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScreenShell(
      headerTitle: 'Lupa Kata Sandi',
      headerSubtitle: 'Atur ulang sandi akunmu dengan kode OTP email.',
      headerTopExtra: 8.0,
      bottomBuilder: const AuthSecurityBadge(),
      contentBuilder: (context, compact) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StepProgressBar(currentStep: _step),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, -0.06),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: _noticeMessage == null
                  ? const SizedBox.shrink(key: ValueKey('no-fp-notice'))
                  : Padding(
                      key: ValueKey(_noticeMessage),
                      padding: const EdgeInsets.only(bottom: 14),
                      child: AuthNotice(
                        message: _noticeMessage!,
                        tone: _noticeTone,
                      ),
                    ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: _buildCurrentStep(),
            ),
          ],
        );
      },
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
          const _StepHeading(
            icon: Icons.lock_reset_rounded,
            title: 'Pulihkan Akses Akun',
            description:
                'Masukkan email terdaftar pada akun Djajan Anda untuk menerima 6 digit kode verifikasi.',
          ),
          const SizedBox(height: 18),
          AuthTextField(
            label: 'Alamat Email',
            hint: 'nama@email.com',
            icon: Icons.email_outlined,
            controller: _emailController,
            enabled: !_loading,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            validator: _validateEmail,
            onFieldSubmitted: (_) => _submitEmail(),
          ),
          const SizedBox(height: 18),
          AuthPrimaryButton(
            key: const ValueKey('forgot-send-button'),
            label: 'Kirim Kode Verifikasi',
            icon: Icons.send_rounded,
            loading: _loading,
            onPressed: _submitEmail,
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: _loading ? null : () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: const Text('Kembali ke Halaman Masuk'),
              style: TextButton.styleFrom(
                foregroundColor: AuthStyle.primary,
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
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
          _StepHeading(
            icon: Icons.mark_email_read_rounded,
            title: 'Verifikasi Kode OTP',
            description:
                'Masukkan kode 6 digit yang dikirim ke $_sentToEmail beserta kata sandi baru Anda.',
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
            autofillHints: const [AutofillHints.newPassword],
            validator: AuthValidators.kataSandi,
            suffix: IconButton(
              tooltip: _obscurePassword
                  ? 'Tampilkan kata sandi'
                  : 'Sembunyikan kata sandi',
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
                color: AuthStyle.textGrey,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
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
              tooltip: _obscureConfirm
                  ? 'Tampilkan kata sandi'
                  : 'Sembunyikan kata sandi',
              icon: Icon(
                _obscureConfirm
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
                color: AuthStyle.textGrey,
              ),
              onPressed: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
          const SizedBox(height: 18),
          AuthPrimaryButton(
            key: const ValueKey('forgot-reset-button'),
            label: 'Simpan Kata Sandi Baru',
            icon: Icons.check_circle_rounded,
            loading: _loading,
            onPressed: _submitReset,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: _loading
                    ? null
                    : () => setState(() {
                        _step = 0;
                        _noticeMessage = null;
                      }),
                icon: const Icon(Icons.edit_outlined, size: 15),
                label: const Text('Ganti Email'),
                style: TextButton.styleFrom(
                  foregroundColor: AuthStyle.textGrey,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _loading ? null : _resendOtp,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Kirim Ulang Kode'),
                style: TextButton.styleFrom(
                  foregroundColor: AuthStyle.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
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
        const _StepHeading(
          icon: Icons.check_circle_rounded,
          title: 'Kata Sandi Diperbarui',
          description:
              'Kata sandi akun Anda berhasil diatur ulang. Silakan masuk kembali menggunakan kata sandi baru Anda.',
        ),
        const SizedBox(height: 16),
        const AuthInfoBox(
          icon: Icons.verified_user_outlined,
          text:
              'Demi keamanan akun, gunakan kata sandi yang kuat dan jangan bagikan kode OTP kepada siapa pun.',
        ),
        const SizedBox(height: 20),
        AuthPrimaryButton(
          key: const ValueKey('forgot-login-button'),
          label: 'Masuk Sekarang',
          icon: Icons.login_rounded,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}

/// Indikator langkah bergaya pill: Email -> OTP -> Selesai.
class _StepProgressBar extends StatelessWidget {
  const _StepProgressBar({required this.currentStep});

  final int currentStep;

  static const _labels = ['Email', 'OTP & Sandi', 'Selesai'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AuthStyle.field,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AuthStyle.border),
      ),
      child: Row(
        children: [
          for (var i = 0; i < _labels.length; i++) ...[
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                decoration: BoxDecoration(
                  color: i == currentStep
                      ? AuthStyle.primary
                      : i < currentStep
                      ? AuthStyle.softMint
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == currentStep
                            ? Colors.white.withValues(alpha: 0.22)
                            : i < currentStep
                            ? AuthStyle.primary
                            : AuthStyle.border,
                      ),
                      child: i < currentStep
                          ? const Icon(
                              Icons.check_rounded,
                              size: 12,
                              color: Colors.white,
                            )
                          : Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: i == currentStep
                                    ? Colors.white
                                    : AuthStyle.textGrey,
                              ),
                            ),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        _labels[i],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: i == currentStep
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: i == currentStep
                              ? Colors.white
                              : i < currentStep
                              ? AuthStyle.primary
                              : AuthStyle.textGrey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (i < _labels.length - 1) const SizedBox(width: 4),
          ],
        ],
      ),
    );
  }
}

/// Header kompak di dalam kartu dengan ikon soft-mint dan deskripsi langkah.
class _StepHeading extends StatelessWidget {
  const _StepHeading({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            color: AuthStyle.softMint,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AuthStyle.softMintDeep),
          ),
          child: Icon(icon, color: AuthStyle.primary, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AuthStyle.textDark,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.45,
                  color: AuthStyle.textGrey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
