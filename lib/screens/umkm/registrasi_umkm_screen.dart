import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import '../customer/order/order_widgets.dart';

/// HALAMAN REGISTRASI UMKM BARU
/// Design sama seperti LoginScreen, dengan validasi profesional
/// untuk mencegah human error seperti di halaman tambah produk.
class RegistrasiUmkmScreen extends StatefulWidget {
  const RegistrasiUmkmScreen({super.key});

  @override
  State<RegistrasiUmkmScreen> createState() => _RegistrasiUmkmScreenState();
}

class _RegistrasiUmkmScreenState extends State<RegistrasiUmkmScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaCtrl = TextEditingController();
  final _noTelpCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _alamatCtrl = TextEditingController();
  final _namaTokoCtrl = TextEditingController();

  @override
  void dispose() {
    _namaCtrl.dispose();
    _noTelpCtrl.dispose();
    _emailCtrl.dispose();
    _alamatCtrl.dispose();
    _namaTokoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: DjajanPageHeader(
          title: 'Registrasi UMKM',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Daftar sebagai UMKM untuk mendapatkan akses penuh ke fitur penjualan di ekosistem Djajan.',
                style: OT.secondary,
              ),
              const SizedBox(height: 24),
              _buildInput(
                controller: _namaCtrl,
                label: 'Nama Lengkap Pemilik',
                icon: Icons.person_outline,
                validator: (v) => v!.isEmpty ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              _buildInput(
                controller: _namaTokoCtrl,
                label: 'Nama Warung / Usaha',
                icon: Icons.storefront,
                validator: (v) => v!.isEmpty ? 'Nama toko wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              _buildInput(
                controller: _noTelpCtrl,
                label: 'Nomor WhatsApp',
                icon: Icons.phone_android,
                keyboard: TextInputType.phone,
                prefix: const Text('+62 ', style: TextStyle(fontWeight: FontWeight.bold)),
                validator: (v) => v!.isEmpty ? 'Nomor WA wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              _buildInput(
                controller: _emailCtrl,
                label: 'Alamat Email',
                icon: Icons.email_outlined,
                keyboard: TextInputType.emailAddress,
                validator: (v) => !v!.contains('@') ? 'Email tidak valid' : null,
              ),
              const SizedBox(height: 16),
              _buildInput(
                controller: _alamatCtrl,
                label: 'Alamat Lengkap Dapur',
                icon: Icons.location_on_outlined,
                maxLines: 3,
                validator: (v) => v!.isEmpty ? 'Alamat wajib diisi' : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    pesanSukses(context, 'Permintaan registrasi terkirim! Tim Djajan akan segera menghubungi Anda.');
                    Navigator.pop(context);
                  }
                },
                child: const Text('Daftar Sekarang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboard,
    Widget? prefix,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.hijauTua),
        prefix: prefix,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDADCE6)),
        ),
      ),
      validator: validator,
    );
  }
}