import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'auth_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);

    // Catatan: belum ada endpoint registrasi pelanggan di backend,
    // jadi pendaftaran masih disimulasikan di sisi aplikasi.
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    setState(() => _loading = false);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text(
            'Pendaftaran berhasil! Silakan masuk dengan akun kamu.',
          ),
          backgroundColor: AuthStyle.primary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthStyle.bg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const AuthHero(
              title: 'Buat Akun Baru',
              subtitle:
                  'Daftar sekali, lalu belanja dan pantau pesananmu dari UMKM warga',
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
                              'Daftar sebagai Pembeli Warga',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AuthStyle.textDark,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const AuthInfoBox(
                              icon: Icons.storefront_outlined,
                              text:
                                  'Punya usaha? Buat akun pembeli dulu, lalu daftarkan usahamu lewat menu "Toko Saya" di halaman profil.',
                            ),
                            const SizedBox(height: 20),

                            AuthTextField(
                              label: 'Nama Lengkap',
                              hint: 'Masukkan nama sesuai KTP',
                              icon: Icons.person_outline_rounded,
                              controller: _fullNameController,
                              enabled: !_loading,
                              textInputAction: TextInputAction.next,
                              keyboardType: TextInputType.name,
                              validator: AuthValidators.namaLengkap,
                              autofillHints: const [AutofillHints.name],
                            ),
                            const SizedBox(height: 16),

                            AuthTextField(
                              label: 'Nomor WhatsApp',
                              hint: 'Contoh: 081234567890',
                              icon: Icons.smartphone_outlined,
                              controller: _phoneController,
                              enabled: !_loading,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9+\s\-()]'),
                                ),
                              ],
                              validator: AuthValidators.nomorWhatsApp,
                              autofillHints: const [
                                AutofillHints.telephoneNumber,
                              ],
                            ),
                            const SizedBox(height: 16),

                            AuthTextField(
                              label: 'Email (Opsional)',
                              hint: 'nama@email.com',
                              icon: Icons.email_outlined,
                              controller: _emailController,
                              enabled: !_loading,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              inputFormatters: [
                                FilteringTextInputFormatter.deny(
                                  RegExp(r'\s'),
                                ),
                              ],
                              validator: AuthValidators.emailOpsional,
                              autofillHints: const [AutofillHints.email],
                            ),
                            const SizedBox(height: 16),

                            AuthTextField(
                              label: 'Kata Sandi',
                              hint: 'Minimal 8 karakter',
                              icon: Icons.lock_outline_rounded,
                              controller: _passwordController,
                              enabled: !_loading,
                              obscure: _obscurePassword,
                              textInputAction: TextInputAction.next,
                              validator: AuthValidators.kataSandi,
                              autofillHints: const [
                                AutofillHints.newPassword,
                              ],
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
                            const SizedBox(height: 16),

                            AuthTextField(
                              label: 'Ulangi Kata Sandi',
                              hint: 'Ketik ulang kata sandi',
                              icon: Icons.lock_reset_rounded,
                              controller: _confirmPasswordController,
                              enabled: !_loading,
                              obscure: _obscureConfirm,
                              textInputAction: TextInputAction.done,
                              validator: (value) =>
                                  AuthValidators.ulangiKataSandi(
                                value,
                                _passwordController.text,
                              ),
                              onFieldSubmitted: (_) => _submit(),
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
                                onPressed: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm,
                                ),
                              ),
                            ),
                            const SizedBox(height: 22),

                            AuthPrimaryButton(
                              label: 'Daftar Sekarang',
                              icon: Icons.person_add_alt_1_rounded,
                              loading: _loading,
                              onPressed: _submit,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    AuthLinkRow(
                      question: 'Sudah punya akun?',
                      action: 'Masuk di sini',
                      onTap: _loading ? () {} : () => Navigator.pop(context),
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
