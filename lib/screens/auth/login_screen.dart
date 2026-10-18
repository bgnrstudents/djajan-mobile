import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import 'auth_widgets.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

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

  @override
  void dispose() {
    _phoneOrEmailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);

    // Catatan: belum ada endpoint login pelanggan di backend,
    // jadi proses masuk masih disimulasikan di sisi aplikasi.
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    setState(() => _loading = false);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Berhasil masuk! Selamat datang di Djajan.'),
          backgroundColor: AuthStyle.primary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );

    Navigator.pushReplacementNamed(context, AppRoutes.customerHome);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthStyle.bg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const AuthHero(
              title: 'Selamat Datang',
              subtitle:
                  'Masuk untuk belanja kebutuhan harian dari UMKM warga Kreyongan Atas',
            ),
            Transform.translate(
              offset: const Offset(0, -34),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                child: Column(
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
                              autofillHints: const [AutofillHints.password],
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
                                  () => _obscurePassword = !_obscurePassword,
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
                                              () => _rememberMe = value ?? false,
                                            ),
                                    activeColor: AuthStyle.primary,
                                    side: const BorderSide(
                                      color: AuthStyle.border,
                                      width: 1.5,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                                const SizedBox(width: 8),
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
                                  onPressed: _loading ? null : _openForgotPassword,
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
            ),
          ],
        ),
      ),
    );
  }
}
