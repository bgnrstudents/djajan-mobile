import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../routes/app_routes.dart';
import '../../services/umkm_data_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import 'dashboard_umkm_screen.dart';
import 'registrasi_umkm_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _identifierCtrl = TextEditingController(
    text: '081234567890',
  );

  final _passwordCtrl = TextEditingController(
    text: '12345678',
  );

  bool _obscure = true;
  bool _loading = false;
  String? _errorServer;

  @override
  void dispose() {
    _identifierCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _loading = true;
      _errorServer = null;
    });

    // ====== MODE FRONTEND-ONLY (TANPA BACKEND) ======
    // Simulasi login langsung sukses supaya bisa explorasi UI UMKM.
    // Kalau backend sudah siap, hapus blok ini dan aktifkan blok di bawah.
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    // Inisialisasi data demo agar Dashboard tidak loading terus
    final service = context.read<UmkmDataService>();
    service.mulaiDemo();

    // Pakai pushReplacementNamed biar provider dari main.dart tetap terakses
    Navigator.pushReplacementNamed(context, AppRoutes.umkmDashboard);

    // ====== KODE ASLI (PAKAI BACKEND) - AKTIFKAN NANTI ======
    // final service = context.read<UmkmDataService>();
    //
    // try {
    //   await service.login(
    //     _identifierCtrl.text.trim(),
    //     _passwordCtrl.text,
    //   );
    //
    //   if (!mounted) {
    //     return;
    //   }
    //
    //   Navigator.of(context).pushReplacement(
    //     MaterialPageRoute(
    //       builder: (_) => const DashboardUmkmScreen(),
    //     ),
    //   );
    // } on ApiException catch (e) {
    //   if (!mounted) {
    //     return;
    //   }
    //
    //   setState(() {
    //     _errorServer = e.pesan;
    //   });
    // } catch (e) {
    //   if (!mounted) {
    //     return;
    //   }
    //
    //   setState(() {
    //     _errorServer = 'Terjadi kesalahan: $e';
    //   });
    // } finally {
    //   if (mounted) {
    //     setState(() {
    //       _loading = false;
    //     });
    //   }
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F6FC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 30,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 460,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const LogoDjajanIkon(
                        size: 50,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Djajan',
                        style: GoogleFonts.berkshireSwash(
                          color: AppColors.hijauTua,
                          fontSize: 34,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 34),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(
                      26,
                      30,
                      26,
                      27,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFFE8E7ED),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 30,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Center(
                            child: Text(
                              'Masuk',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          if (_errorServer != null) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(13),
                              decoration: BoxDecoration(
                                color: AppColors.dangerBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: AppColors.danger,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _errorServer!,
                                      style: const TextStyle(
                                        color: AppColors.danger,
                                        fontSize: 13,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                          ],
                          const Text(
                            'Nomor WhatsApp / Email Usaha',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 9),
                          TextFormField(
                            controller: _identifierCtrl,
                            textInputAction: TextInputAction.next,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              hintText: '081234567890',
                              prefixIcon: const Icon(
                                Icons.phone_android_outlined,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFFAFAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(13),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE0E1E6),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(13),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE0E1E6),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(13),
                                borderSide: const BorderSide(
                                  color: AppColors.hijauTua,
                                  width: 1.5,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 16,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Nomor WhatsApp / Email wajib diisi';
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 21),
                          const Text(
                            'Kata Sandi',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 9),
                          TextFormField(
                            controller: _passwordCtrl,
                            obscureText: _obscure,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            decoration: InputDecoration(
                              hintText: 'Masukkan kata sandi',
                              prefixIcon: const Icon(
                                Icons.lock_outline,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: Colors.grey.shade700,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscure = !_obscure;
                                  });
                                },
                              ),
                              filled: true,
                              fillColor: const Color(0xFFFAFAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(13),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE0E1E6),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(13),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE0E1E6),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(13),
                                borderSide: const BorderSide(
                                  color: AppColors.hijauTua,
                                  width: 1.5,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 16,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Kata sandi wajib diisi';
                              }

                              if (value.length < 4) {
                                return 'Kata sandi minimal 4 karakter';
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 8),
                          const Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'Lupa kata sandi?',
                              style: TextStyle(
                                color: AppColors.hijauTua,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 25),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.hijauTua,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                    AppColors.hijauTua.withValues(alpha: 0.6),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(13),
                                ),
                              ),
                              child: _loading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Masuk',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.krem,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: const Color(0xFFF0DFC2),
                      ),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          color: AppColors.chipOrangeText,
                        ),
                        SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            'Akun demo mitra: 081234567890 · '
                            'kata sandi 12345678',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.chipOrangeText,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const RegistrasiUmkmScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_business_outlined),
                      label: const Text(
                        'Daftar UMKM Baru',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.hijauTua,
                        side: const BorderSide(
                          color: AppColors.hijauTua,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  const Text(
                    '© 2026 Djajan',
                    style: TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}