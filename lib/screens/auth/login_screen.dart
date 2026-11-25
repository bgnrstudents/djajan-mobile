import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../routes/app_routes.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';
import '../../services/umkm_data_service.dart';
import 'auth_widgets.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.initialMode = AuthMode.login});

  final AuthMode initialMode;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  final _phoneOrEmailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _regPasswordController = TextEditingController();
  final _regConfirmPasswordController = TextEditingController();

  late AuthMode _mode;
  bool _obscurePassword = true;
  bool _obscureRegPassword = true;
  bool _obscureRegConfirm = true;
  bool _rememberMe = true;
  bool _loading = false;
  String? _noticeMessage;
  AuthNoticeTone _noticeTone = AuthNoticeTone.error;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
  }

  @override
  void dispose() {
    _phoneOrEmailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _regPasswordController.dispose();
    _regConfirmPasswordController.dispose();
    super.dispose();
  }

  void _switchMode(AuthMode nextMode) {
    if (_loading || _mode == nextMode) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _mode = nextMode;
      _noticeMessage = null;
    });
  }

  Future<void> _submitLogin() async {
    FocusScope.of(context).unfocus();
    if (!(_loginFormKey.currentState?.validate() ?? false)) return;

    setState(() {
      _loading = true;
      _noticeMessage = null;
    });

    try {
      final session = await context.read<AuthService>().login(
        _phoneOrEmailController.text,
        _passwordController.text,
      );
      if (!mounted) return;
      if (session.role == AuthRole.umkm) {
        final umkm = context.read<UmkmDataService>();
        umkm.loadProfileFromLogin(session.data);
        Navigator.pushReplacementNamed(context, AppRoutes.umkmDashboard);
      } else {
        await _continueCustomerLogin();
      }
    } on ApiException catch (error) {
      if (mounted) {
        _showLoginError(error);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitRegister() async {
    FocusScope.of(context).unfocus();
    if (!(_registerFormKey.currentState?.validate() ?? false)) return;

    setState(() {
      _loading = true;
      _noticeMessage = null;
    });

    try {
      await context.read<AuthService>().register(
        nama: _fullNameController.text,
        noTelp: _phoneController.text,
        email: _emailController.text,
        password: _regPasswordController.text,
        passwordConfirmation: _regConfirmPasswordController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pendaftaran berhasil! Selamat datang di DJajan.'),
        ),
      );
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.customerHome,
        (_) => false,
      );
    } on ApiException catch (error) {
      if (mounted) {
        _showAuthNotice(error.pesan, AuthNoticeTone.error);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
    );
  }

  Future<void> _loginWithGoogle() async {
    setState(() {
      _loading = true;
      _noticeMessage = null;
    });
    try {
      final session = await context.read<AuthService>().loginWithGoogle();
      if (!mounted) return;
      if (session.role == AuthRole.umkm) {
        context.read<UmkmDataService>().loadProfileFromLogin(session.data);
        Navigator.pushReplacementNamed(context, AppRoutes.umkmDashboard);
      } else {
        await _continueCustomerLogin();
      }
    } on ApiException catch (error) {
      if (mounted) {
        _showGoogleError(error);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showLoginError(ApiException error) {
    final message = switch (error.code) {
      'account_not_found' =>
        'Akun belum ditemukan. Periksa kembali email atau nomor WhatsApp Anda, atau silakan daftar akun baru.',
      'invalid_password' =>
        'Kata sandi yang Anda masukkan tidak sesuai. Silakan coba kembali.',
      'account_pending' =>
        'Pendaftaran usaha Anda sedang ditinjau. Coba masuk kembali setelah mendapat konfirmasi dari admin.',
      'account_rejected' =>
        'Pendaftaran usaha Anda belum disetujui. Hubungi admin Desa Kreongan Atas untuk informasi lebih lanjut.',
      'network_error' =>
        'Tidak dapat terhubung ke server. Periksa koneksi internet Anda dan coba kembali.',
      'server_error' || 'system_error' =>
        'Terjadi kendala pada sistem. Silakan coba beberapa saat lagi.',
      _ => _fallbackLoginMessage(error),
    };
    final tone = switch (error.code) {
      'account_pending' || 'account_rejected' => AuthNoticeTone.warning,
      'network_error' || 'system_error' => AuthNoticeTone.warning,
      _ => AuthNoticeTone.error,
    };
    _showAuthNotice(message, tone);
  }

  String _fallbackLoginMessage(ApiException error) {
    if (error.statusCode != null && error.statusCode! >= 500) {
      return 'Terjadi kendala pada sistem. Silakan coba beberapa saat lagi.';
    }

    final message = error.pesan.toLowerCase();
    if (message.contains('akun umkm') && message.contains('tidak ditemukan') ||
        message.contains('akun pelanggan terkait')) {
      return 'Akun belum ditemukan. Periksa kembali email atau nomor WhatsApp Anda, atau silakan daftar akun baru.';
    }
    if (error.statusCode == 404) {
      return 'Terjadi kendala pada sistem. Silakan coba beberapa saat lagi.';
    }
    if (error.statusCode == 401 ||
        (message.contains('kata sandi') && message.contains('salah'))) {
      return 'Kata sandi yang Anda masukkan tidak sesuai. Silakan coba kembali.';
    }
    if (error.statusCode == 403) {
      return 'Akun belum dapat digunakan. Hubungi admin Djajan untuk informasi lebih lanjut.';
    }
    if (error.statusCode == 400 || error.statusCode == 422) {
      return 'Periksa kembali email atau nomor WhatsApp dan kata sandi Anda.';
    }
    if (error.statusCode == null) {
      return 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda dan coba kembali.';
    }
    return 'Terjadi kendala pada sistem. Silakan coba beberapa saat lagi.';
  }

  void _showGoogleError(ApiException error) {
    if (error.code == 'account_pending') {
      _showAuthNotice(
        'Pendaftaran usaha Anda sedang ditinjau. Coba masuk kembali setelah mendapat konfirmasi dari admin.',
        AuthNoticeTone.warning,
      );
      return;
    }
    if (error.code == 'account_rejected') {
      _showAuthNotice(
        'Pendaftaran usaha Anda belum disetujui. Hubungi admin Desa Kreongan Atas untuk informasi lebih lanjut.',
        AuthNoticeTone.warning,
      );
      return;
    }
    if (error.code == 'network_error') {
      _showAuthNotice(
        'Tidak dapat terhubung ke server. Periksa koneksi internet Anda dan coba kembali.',
        AuthNoticeTone.warning,
      );
      return;
    }
    if (error.code == 'server_error' ||
        error.code == 'system_error' ||
        (error.statusCode != null && error.statusCode! >= 500)) {
      _showAuthNotice(
        'Terjadi kendala pada sistem. Silakan coba beberapa saat lagi.',
        AuthNoticeTone.warning,
      );
      return;
    }
    if (error.pesan == 'Login Google dibatalkan.') {
      _showAuthNotice(error.pesan, AuthNoticeTone.info);
      return;
    }
    _showAuthNotice(
      'Login Google belum berhasil. Silakan coba kembali atau gunakan email atau nomor WhatsApp.',
      AuthNoticeTone.error,
    );
  }

  void _showAuthNotice(String message, AuthNoticeTone tone) {
    setState(() {
      _noticeMessage = message;
      _noticeTone = tone;
    });
  }

  Future<void> _continueCustomerLogin() async {
    if (!mounted) return;
    final orderLoadFuture = context.read<OrderService>().loadFromApi();
    final messenger = ScaffoldMessenger.of(context);
    if (Navigator.canPop(context)) {
      Navigator.pop(context, true);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.customerHome);
    }

    ApiException? orderLoadError;
    try {
      await orderLoadFuture;
    } on ApiException catch (error) {
      orderLoadError = error;
    } on FormatException {
      orderLoadError = ApiException(
        'Format data riwayat pesanan dari server tidak valid.',
      );
    } on TypeError {
      orderLoadError = ApiException(
        'Struktur data riwayat pesanan dari server tidak sesuai.',
      );
    }

    if (orderLoadError != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Login berhasil, tetapi riwayat pesanan belum dimuat. '
            '${orderLoadError.pesan}',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLogin = _mode == AuthMode.login;

    return AuthScreenShell(
      bottomBuilder: const AuthSecurityBadge(),
      contentBuilder: (context, compact) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthModeSwitcher(
              mode: _mode,
              enabled: !_loading,
              onChanged: _switchMode,
            ),
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
                  ? const SizedBox.shrink(key: ValueKey('no-auth-notice'))
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
              child: isLogin ? _buildLoginForm() : _buildRegisterForm(),
            ),
            const SizedBox(height: 16),
            AuthOrDivider(
              label: isLogin ? 'atau masuk dengan' : 'atau daftar dengan',
            ),
            const SizedBox(height: 12),
            AuthGoogleButton(
              label: isLogin ? 'Masuk dengan Google' : 'Daftar dengan Google',
              enabled: !_loading,
              onPressed: _loginWithGoogle,
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        key: const ValueKey('auth-form-login'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AuthTextField(
            label: 'Nomor WhatsApp atau Email',
            hint: 'Contoh: 081234567890',
            icon: Icons.person_outline_rounded,
            controller: _phoneOrEmailController,
            enabled: !_loading,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: AuthValidators.identitas,
            autofillHints: const [AutofillHints.username],
          ),
          const SizedBox(height: 14),
          AuthTextField(
            label: 'Kata Sandi',
            hint: 'Masukkan kata sandi',
            icon: Icons.lock_outline_rounded,
            controller: _passwordController,
            enabled: !_loading,
            obscure: _obscurePassword,
            textInputAction: TextInputAction.done,
            validator: AuthValidators.kataSandi,
            autofillHints: const [AutofillHints.password],
            onFieldSubmitted: (_) => _submitLogin(),
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
          const SizedBox(height: 8),
          Row(
            children: [
              SizedBox(
                height: 24,
                width: 24,
                child: Checkbox(
                  value: _rememberMe,
                  onChanged: _loading
                      ? null
                      : (value) =>
                          setState(() => _rememberMe = value ?? false),
                  activeColor: AuthStyle.primary,
                  side: const BorderSide(color: AuthStyle.border, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Ingat saya',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: AuthStyle.textDark),
                ),
              ),
              TextButton(
                onPressed: _loading ? null : _openForgotPassword,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Lupa sandi?',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AuthStyle.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          AuthPrimaryButton(
            key: const ValueKey('login-submit-button'),
            label: 'Masuk',
            icon: Icons.arrow_forward_rounded,
            loading: _loading,
            onPressed: _submitLogin,
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm() {
    return Form(
      key: _registerFormKey,
      child: Column(
        key: const ValueKey('auth-form-register'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AuthInfoBox(
            icon: Icons.storefront_outlined,
            text:
                'Punya usaha? Daftarkan toko melalui menu profil setelah masuk.',
          ),
          const SizedBox(height: 14),
          AuthTextField(
            label: 'Nama Lengkap',
            hint: 'Masukkan nama lengkap',
            icon: Icons.person_outline_rounded,
            controller: _fullNameController,
            enabled: !_loading,
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.name,
            validator: AuthValidators.namaLengkap,
            autofillHints: const [AutofillHints.name],
          ),
          const SizedBox(height: 14),
          AuthTextField(
            label: 'Nomor WhatsApp',
            hint: 'Contoh: 081234567890',
            icon: Icons.smartphone_outlined,
            controller: _phoneController,
            enabled: !_loading,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s\-()]')),
            ],
            validator: AuthValidators.nomorWhatsApp,
            autofillHints: const [AutofillHints.telephoneNumber],
          ),
          const SizedBox(height: 14),
          AuthTextField(
            label: 'Email (Opsional)',
            hint: 'nama@email.com',
            icon: Icons.email_outlined,
            controller: _emailController,
            enabled: !_loading,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            inputFormatters: [
              FilteringTextInputFormatter.deny(RegExp(r'\s')),
            ],
            validator: AuthValidators.emailOpsional,
            autofillHints: const [AutofillHints.email],
          ),
          const SizedBox(height: 14),
          AuthTextField(
            label: 'Kata Sandi',
            hint: 'Minimal 8 karakter',
            icon: Icons.lock_outline_rounded,
            controller: _regPasswordController,
            enabled: !_loading,
            obscure: _obscureRegPassword,
            textInputAction: TextInputAction.next,
            validator: AuthValidators.kataSandi,
            autofillHints: const [AutofillHints.newPassword],
            suffix: IconButton(
              tooltip: _obscureRegPassword
                  ? 'Tampilkan kata sandi'
                  : 'Sembunyikan kata sandi',
              icon: Icon(
                _obscureRegPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
                color: AuthStyle.textGrey,
              ),
              onPressed: () =>
                  setState(() => _obscureRegPassword = !_obscureRegPassword),
            ),
          ),
          const SizedBox(height: 14),
          AuthTextField(
            label: 'Ulangi Kata Sandi',
            hint: 'Ketik ulang kata sandi',
            icon: Icons.lock_reset_rounded,
            controller: _regConfirmPasswordController,
            enabled: !_loading,
            obscure: _obscureRegConfirm,
            textInputAction: TextInputAction.done,
            validator: (value) => AuthValidators.ulangiKataSandi(
              value,
              _regPasswordController.text,
            ),
            onFieldSubmitted: (_) => _submitRegister(),
            suffix: IconButton(
              tooltip: _obscureRegConfirm
                  ? 'Tampilkan kata sandi'
                  : 'Sembunyikan kata sandi',
              icon: Icon(
                _obscureRegConfirm
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
                color: AuthStyle.textGrey,
              ),
              onPressed: () =>
                  setState(() => _obscureRegConfirm = !_obscureRegConfirm),
            ),
          ),
          const SizedBox(height: 18),
          AuthPrimaryButton(
            key: const ValueKey('register-submit-button'),
            label: 'Daftar Sekarang',
            icon: Icons.arrow_forward_rounded,
            loading: _loading,
            onPressed: _submitRegister,
          ),
        ],
      ),
    );
  }
}
