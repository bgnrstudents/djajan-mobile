import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/api_service.dart';
import '../../services/umkm_data_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';

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
      appBar: AppBar(title: const Text('Registrasi UMKM')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Daftar sebagai UMKM untuk mendapatkan akses penuh ke fitur penjualan.'),
              const SizedBox(height: 24),
              TextFormField(
                controller: _namaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama lengkap wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noTelpCtrl,
                decoration: const InputDecoration(
                  labelText: 'No. Telepon',
                  border: OutlineInputBorder(),
                  prefixText: '+62',
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'No. telepon wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email wajib diisi';
                  }
                  if (!value.contains('@')) {
                    return 'Masukkan email yang valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _alamatCtrl,
                decoration: const InputDecoration(
                  labelText: 'Alamat Toko',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Alamat wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _namaTokoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nama Toko',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama toko wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // TODO: Simpan registrasi ke backend
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Registrasi berhasil!')),
                    );
                  }
                },
                child: const Text('Daftar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}