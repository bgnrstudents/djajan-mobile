import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../routes/app_routes.dart';
import 'auth_widgets.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';
import '../../services/umkm_data_service.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../services/order_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneOrEmailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _loading = false;
  String? _noticeMessage;
  AuthNoticeTone _noticeTone = AuthNoticeTone.error;

  @override
  void dispose() {
    _phoneOrEmailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

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

  void _openRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
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
    return Scaffold(
      backgroundColor: AuthStyle.bg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = MediaQuery.sizeOf(context).height < 700;
          final heroHeight = compact ? 306.0 : 350.0;
          final cardTop = heroHeight - (compact ? 54 : 68);
          final horizontalPadding = constraints.maxWidth >= 600 ? 28.0 : 18.0;

          return SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.paddingOf(context).bottom + 16,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Stack(
                  children: [
                    SizedBox(
                      height: heroHeight,
                      width: double.infinity,
                      child: _LoginHero(height: heroHeight),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        cardTop,
                        horizontalPadding,
                        20,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AuthCard(
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Masuk ke Akun',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: AuthStyle.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Gunakan nomor WhatsApp atau email yang terdaftar.',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: AuthStyle.textGrey,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 220),
                                    switchInCurve: Curves.easeOutCubic,
                                    switchOutCurve: Curves.easeInCubic,
                                    transitionBuilder: (child, animation) =>
                                        FadeTransition(
                                          opacity: animation,
                                          child: SlideTransition(
                                            position: Tween<Offset>(
                                              begin: const Offset(0, -0.08),
                                              end: Offset.zero,
                                            ).animate(animation),
                                            child: child,
                                          ),
                                        ),
                                    child: _noticeMessage == null
                                        ? const SizedBox.shrink(
                                            key: ValueKey('no-login-notice'),
                                          )
                                        : AuthNotice(
                                            key: ValueKey(_noticeMessage),
                                            message: _noticeMessage!,
                                            tone: _noticeTone,
                                          ),
                                  ),
                                  const SizedBox(height: 14),

                                  AuthTextField(
                                    label: 'Nomor WhatsApp atau Email',
                                    hint: 'Contoh: 081234567890',
                                    icon: Icons.person_outline_rounded,
                                    controller: _phoneOrEmailController,
                                    enabled: !_loading,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    validator: AuthValidators.identitas,
                                    autofillHints: const [
                                      AutofillHints.username,
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  AuthTextField(
                                    label: 'Kata Sandi',
                                    hint: 'Masukkan kata sandi',
                                    icon: Icons.lock_outline_rounded,
                                    controller: _passwordController,
                                    enabled: !_loading,
                                    obscure: _obscurePassword,
                                    textInputAction: TextInputAction.done,
                                    validator: AuthValidators.kataSandi,
                                    autofillHints: const [
                                      AutofillHints.password,
                                    ],
                                    onFieldSubmitted: (_) => _submit(),
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
                                      onPressed: () => setState(
                                        () => _obscurePassword =
                                            !_obscurePassword,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),

                                  Row(
                                    children: [
                                      SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: Checkbox(
                                          value: _rememberMe,
                                          onChanged: _loading
                                              ? null
                                              : (value) => setState(
                                                  () => _rememberMe =
                                                      value ?? false,
                                                ),
                                          activeColor: AuthStyle.primary,
                                          side: const BorderSide(
                                            color: AuthStyle.border,
                                            width: 1.5,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      ),
                                      const Expanded(
                                        child: Text(
                                          'Ingat saya',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AuthStyle.textDark,
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: _loading
                                            ? null
                                            : _openForgotPassword,
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                          ),
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
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
                                    label: 'Masuk',
                                    icon: Icons.login_rounded,
                                    loading: _loading,
                                    onPressed: _submit,
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: OutlinedButton.icon(
                                      onPressed: _loading
                                          ? null
                                          : _loginWithGoogle,
                                      icon: const Icon(
                                        Icons.g_mobiledata_rounded,
                                        size: 23,
                                      ),
                                      label: const Text('Masuk dengan Google'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AuthStyle.primary,
                                        side: const BorderSide(
                                          color: AuthStyle.border,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        textStyle: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          AuthLinkRow(
                            question: 'Belum punya akun?',
                            action: 'Daftar Sekarang',
                            onTap: _loading ? () {} : _openRegister,
                          ),
                          const SizedBox(height: 26),
                          const AuthFooter(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LoginHero extends StatelessWidget {
  const _LoginHero({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/javanese_village_background.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xCC0B4E32),
                    Color(0xB8175D2B),
                    Color(0xE60B4E32),
                  ],
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
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
                      height: 62,
                      width: 62,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.16),
                            blurRadius: 18,
                            offset: const Offset(0, 7),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/logo_djajan_mark.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Usaha lokal,\ntumbuh bersama.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        height: 1.08,
                        letterSpacing: -0.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Dukung langkah kecil dan temukan produk dari sekitar kita.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.86),
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
