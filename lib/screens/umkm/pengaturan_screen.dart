import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../models/umkm_seller_models.dart';
import '../../routes/app_routes.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/umkm_data_service.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/osm_map_picker.dart';
import '../customer/order/order_widgets.dart';

/// Satu baris form zona ongkir yang sedang diedit di layar ini.
class _ZonaBaris {
  final TextEditingController sampaiCtrl;
  final TextEditingController tarifCtrl;

  _ZonaBaris({required String sampai, required String tarif})
      : sampaiCtrl = TextEditingController(text: sampai),
        tarifCtrl = TextEditingController(text: tarif);

  void dispose() {
    sampaiCtrl.dispose();
    tarifCtrl.dispose();
  }
}

/// "1.0" -> "1", "3.5" tetap "3.5" — supaya enak dibaca di form.
String _fmtKm(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toString();

/// HALAMAN PENGATURAN USAHA UMKM.
/// Mengelola profil usaha, foto, lokasi dapur GPS, operasional toko,
/// ongkir pengiriman, kebijakan pembayaran, keamanan sandi, dan sesi logout.
class PengaturanScreen extends StatefulWidget {
  final bool isTab;
  const PengaturanScreen({super.key, this.isTab = false});

  @override
  State<PengaturanScreen> createState() => _PengaturanScreenState();
}

class _PengaturanScreenState extends State<PengaturanScreen> {
  late bool _tokoAktif;
  late bool _codAktif;
  late String _skemaPO;
  late bool _pickupAktif;
  late bool _kurirAktif;

  late TextEditingController _radiusCtrl;
  final List<_ZonaBaris> _zonaBaris = [];

  bool _menyimpan = false;
  bool _mengunggahFoto = false;

  final List<String> _skemaOptions = const [
    'DP 30% (Sisa dibayar saat pesanan diantar)',
    'DP 50% (Sisa dibayar saat pesanan diantar)',
    'Lunas di Awal (Full Payment)',
    'Tanpa DP (Bayar Saat Pesanan Sampai)',
  ];

  @override
  void initState() {
    super.initState();
    final p = context.read<UmkmDataService>().profile;
    _tokoAktif = p.tokoAktif;
    _codAktif = p.codAktif;
    _skemaPO = _skemaOptions.contains(p.skemaPO)
        ? p.skemaPO
        : _skemaOptions.first;
    _pickupAktif = p.pickupAktif;
    _kurirAktif = p.kurirWargaAktif;

    _radiusCtrl = TextEditingController(text: _fmtKm(p.radiusGratisKm));
    for (final z in p.zonaOngkir) {
      _zonaBaris.add(
        _ZonaBaris(sampai: _fmtKm(z.jarakMax), tarif: z.biaya.toString()),
      );
    }
  }

  @override
  void dispose() {
    _radiusCtrl.dispose();
    for (final z in _zonaBaris) {
      z.dispose();
    }
    super.dispose();
  }

  // ------------------------------------------------ Ganti Foto Profil
  Future<void> _gantiFoto() async {
    final file = await pilihGambar(context);
    if (file == null || !mounted) return;

    setState(() => _mengunggahFoto = true);
    try {
      final service = context.read<UmkmDataService>();
      final pesan = await service.gantiFotoProfil(file);
      if (!mounted) return;
      pesanSukses(context, pesan);
    } on ApiException catch (e) {
      if (mounted) pesanGagal(context, e.pesan);
    } finally {
      if (mounted) setState(() => _mengunggahFoto = false);
    }
  }

  // ------------------------------------------------ Edit Identitas Usaha
  Future<void> _editIdentitas() async {
    final service = context.read<UmkmDataService>();
    final p = service.profile;
    final namaCtrl = TextEditingController(text: p.namaUsaha);
    final spesialisCtrl = TextEditingController(text: p.spesialis);
    final telpCtrl = TextEditingController(text: p.noTelpUsaha);

    final simpan = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            left: 20,
            right: 20,
            top: 4,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: OC.mint,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.storefront_outlined,
                        color: OC.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ubah Informasi Usaha',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: OC.ink,
                          ),
                        ),
                        Text(
                          'Perbarui identitas warung Anda',
                          style: TextStyle(fontSize: 12, color: OC.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _sheetField(
                controller: namaCtrl,
                label: 'Nama Usaha',
                hint: 'Nama warung/dapur Anda',
                icon: Icons.storefront_outlined,
                capitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 14),
              _sheetField(
                controller: spesialisCtrl,
                label: 'Spesialis / Kategori Makanan',
                hint: 'Contoh: Aneka Jajanan Pasar & Tumpeng',
                icon: Icons.restaurant_menu_outlined,
              ),
              const SizedBox(height: 14),
              _sheetField(
                controller: telpCtrl,
                label: 'Nomor WhatsApp Usaha',
                hint: '08xxxxxxxxxx',
                icon: Icons.phone_outlined,
                inputType: TextInputType.phone,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: OC.line),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Batal',
                          style: TextStyle(color: OC.muted)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(ctx, true),
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Simpan Perubahan',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      style: FilledButton.styleFrom(
                        backgroundColor: OC.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (simpan != true) return;
    if (namaCtrl.text.trim().isEmpty) {
      if (mounted) pesanGagal(context, 'Nama usaha tidak boleh kosong.');
      return;
    }

    try {
      final pesan = await service.simpanIdentitasUsaha(
        namaUsaha: namaCtrl.text.trim(),
        spesialis: spesialisCtrl.text.trim(),
        alamat: p.alamat, // Alamat dikelola terpusat lewat peta GPS
        noTelpUsaha: telpCtrl.text.trim(),
      );
      if (mounted) pesanSukses(context, pesan);
    } on ApiException catch (e) {
      if (mounted) pesanGagal(context, e.pesan);
    }
  }

  // ------------------------------------------------ Pilih Titik Lokasi Peta (OSM)
  Future<void> _pilihLokasiUMKM() async {
    final service = context.read<UmkmDataService>();
    final p = service.profile;
    LatLng? initial;
    if (p.latitude != null && p.longitude != null) {
      initial = LatLng(p.latitude!, p.longitude!);
    }
    final result = await showOsmMapPicker(
      context,
      initialLatLng: initial,
      confirmLabel: 'Gunakan Lokasi Ini',
    );
    if (result == null || !mounted) return;
    try {
      final radiusGratis = double.tryParse(
            _radiusCtrl.text.replaceAll(',', '.'),
          ) ??
          p.radiusGratisKm;

      // 1. Simpan koordinat GPS ke backend
      await service.simpanOngkir(
        latitude: result.latitude,
        longitude: result.longitude,
        radiusGratisKm: radiusGratis,
        jarakMaksimalKm: p.jarakMaksimalKm ?? radiusGratis,
        zonaOngkir: p.zonaOngkir,
      );

      // 2. Jika ada alamat teks dari reverse geocoding, simpan juga sebagai alamat usaha
      if (result.alamatTeks.isNotEmpty) {
        await service.simpanIdentitasUsaha(
          namaUsaha: p.namaUsaha,
          spesialis: p.spesialis,
          alamat: result.alamatTeks,
          noTelpUsaha: p.noTelpUsaha,
        );
      }

      if (mounted) {
        pesanSukses(context, 'Lokasi dapur dan titik GPS berhasil disimpan.');
        setState(() {});
      }
    } on ApiException catch (e) {
      if (mounted) pesanGagal(context, e.pesan);
    }
  }

  // ------------------------------------------------ Ubah Kata Sandi
  Future<void> _ubahPassword() async {
    final lama = TextEditingController();
    final baru = TextEditingController();
    final konfirmasi = TextEditingController();
    final service = context.read<UmkmDataService>();
    final simpan = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ubah Kata Sandi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: lama,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Kata sandi lama'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: baru,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Kata sandi baru (min. 8 karakter)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: konfirmasi,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Konfirmasi kata sandi baru',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (simpan != true) return;
    try {
      final pesan = await service.ubahPassword(
        passwordLama: lama.text,
        passwordBaru: baru.text,
        konfirmasi: konfirmasi.text,
      );
      if (mounted) pesanSukses(context, pesan);
    } on ApiException catch (e) {
      if (mounted) pesanGagal(context, e.pesan);
    }
  }

  // ------------------------------------------------ Beralih ke Akun Pembeli
  Future<void> _switchToCustomer() async {
    try {
      context.read<UmkmDataService>().clearState();
      final session = await context.read<AuthService>().switchToCustomer();
      if (!mounted) return;
      if (session.role != AuthRole.pelanggan) {
        throw ApiException('Mode pelanggan tidak berhasil diaktifkan.');
      }
      Navigator.of(context)
          .pushNamedAndRemoveUntil(AppRoutes.customerHome, (_) => false);
    } on ApiException catch (error) {
      if (mounted) pesanGagal(context, error.pesan);
    }
  }

  // ------------------------------------------------ Konfirmasi Logout
  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Keluar dari Akun UMKM?'),
        content: const Text(
          'Sesi login di perangkat ini akan diakhiri. Anda perlu login kembali untuk mengakses akun.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: OC.danger,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      await context.read<AuthService>().logout();
      if (!mounted) return;
      context.read<UmkmDataService>().logout();
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
    }
  }

  // ------------------------------------------------ Simpan Pengaturan
  Future<void> _simpanPengaturan() async {
    FocusScope.of(context).unfocus();

    final radiusGratis = double.tryParse(_radiusCtrl.text.replaceAll(',', '.'));
    if (radiusGratis == null || radiusGratis < 0) {
      if (mounted) {
        pesanGagal(
          context,
          'Radius gratis ongkir harus berupa angka dan tidak boleh negatif.',
        );
      }
      return;
    }

    final List<ZonaOngkir> zonaBaru = [];
    double batas = radiusGratis;
    for (var i = 0; i < _zonaBaris.length; i++) {
      final sampai = double.tryParse(
        _zonaBaris[i].sampaiCtrl.text.replaceAll(',', '.'),
      );
      final tarif = int.tryParse(_zonaBaris[i].tarifCtrl.text);
      if (sampai == null || tarif == null) {
        if (mounted) {
          pesanGagal(
            context,
            'Isi jarak & tarif zona ke-${i + 1} dengan angka yang benar.',
          );
        }
        return;
      }
      if (sampai <= batas) {
        if (mounted) {
          pesanGagal(
            context,
            'Jarak akhir zona ke-${i + 1} harus lebih besar dari ${_fmtKm(batas)} KM.',
          );
        }
        return;
      }
      if (tarif < 0) {
        if (mounted) {
          pesanGagal(context, 'Tarif zona ke-${i + 1} tidak boleh negatif.');
        }
        return;
      }
      zonaBaru.add(ZonaOngkir(jarakMin: batas, jarakMax: sampai, biaya: tarif));
      batas = sampai;
    }

    final jarakMaksimal = batas;
    final service = context.read<UmkmDataService>();
    if (_kurirAktif &&
        (service.profile.latitude == null ||
            service.profile.longitude == null)) {
      if (mounted) {
        pesanGagal(
          context,
          'Isi titik lokasi dapur di peta terlebih dahulu sebelum mengaktifkan layanan kurir.',
        );
      }
      return;
    }

    setState(() => _menyimpan = true);
    try {
      final pesan = await service.simpanPengaturan(
        tokoAktif: _tokoAktif,
        codAktif: _codAktif,
        skemaPO: _skemaPO,
        pickupAktif: _pickupAktif,
        kurirWargaAktif: _kurirAktif,
        biayaPengantaran: service.profile.biayaPengantaran,
      );

      await service.simpanOngkir(
        latitude: service.profile.latitude,
        longitude: service.profile.longitude,
        radiusGratisKm: radiusGratis,
        jarakMaksimalKm: jarakMaksimal,
        zonaOngkir: zonaBaru,
      );

      if (!mounted) return;
      pesanSukses(context, pesan);
      if (!widget.isTab) {
        Navigator.of(context).pop();
      }
    } on ApiException catch (e) {
      if (mounted) pesanGagal(context, e.pesan);
    } finally {
      if (mounted) setState(() => _menyimpan = false);
    }
  }

  // ================================================= UI COMPONENTS

  /// TextField bergaya DJajan untuk dipakai di bottom sheet form.
  static Widget _sheetField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType inputType = TextInputType.text,
    TextCapitalization capitalization = TextCapitalization.none,
  }) {
    return TextField(
      controller: controller,
      keyboardType: inputType,
      textCapitalization: capitalization,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: OC.muted),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: OC.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: OC.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: OC.primary, width: 1.8),
        ),
      ),
    );
  }

  Widget _judulSeksi(IconData ikon, String judul, String subjudul) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: OC.primarySoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(ikon, color: OC.primary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  judul,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: OC.ink,
                  ),
                ),
                Text(
                  subjudul,
                  style: const TextStyle(color: OC.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleTile({
    required String judul,
    String? badge,
    required String subjudul,
    required bool nilai,
    required ValueChanged<bool> onChanged,
    IconData? ikon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: nilai ? OC.primarySoft : OC.line),
      ),
      child: Row(
        children: [
          if (ikon != null) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: nilai ? OC.mint : OC.box,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                ikon,
                size: 18,
                color: nilai ? OC.primary : OC.muted,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        judul,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: OC.ink,
                        ),
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 6),
                      MiniBadge(badge, bg: OC.peach, fg: OC.amber),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subjudul,
                  style: const TextStyle(color: OC.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch.adaptive(
              value: nilai,
              activeThumbColor: OC.primary,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------- Profil Usaha Card
  Widget _cardProfilUsaha(UmkmProfile profile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OC.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  GambarJaringan(
                    url: profile.fotoProfilUrl,
                    width: 68,
                    height: 68,
                    radius: 34,
                    ikonKosong: Icons.storefront,
                    cacheBuster:
                        DateTime.now().millisecondsSinceEpoch.toString(),
                  ),
                  GestureDetector(
                    onTap: _mengunggahFoto ? null : _gantiFoto,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: OC.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: _mengunggahFoto
                          ? const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.photo_camera,
                              size: 13,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.namaUsaha,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16.5,
                        color: OC.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (profile.terverifikasi)
                      const MiniBadge(
                        'Mitra Terverifikasi',
                        bg: OC.mint,
                        fg: OC.primary,
                        ikon: Icons.verified,
                      )
                    else
                      const MiniBadge(
                        'Menunggu Verifikasi',
                        bg: OC.peach,
                        fg: OC.amber,
                      ),
                    if (profile.spesialis.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        profile.spesialis,
                        style: const TextStyle(
                          color: OC.muted,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                    if (profile.noTelpUsaha.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'WhatsApp: ${profile.noTelpUsaha}',
                        style: const TextStyle(
                          color: OC.muted,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: _editIdentitas,
                icon: const Icon(Icons.edit_outlined, color: OC.primary),
                tooltip: 'Ubah Informasi Usaha',
                style: IconButton.styleFrom(
                  backgroundColor: OC.primarySoft,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------- Status Toko Card
  Widget _cardStatusToko() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _tokoAktif ? OC.primary.withValues(alpha: 0.3) : OC.line,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _tokoAktif ? OC.mint : OC.box,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _tokoAktif ? Icons.storefront : Icons.storefront_outlined,
              color: _tokoAktif ? OC.primary : OC.muted,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _tokoAktif ? 'Toko Buka (Menerima Pesanan)' : 'Toko Tutup / Libur',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: _tokoAktif ? OC.ink : OC.muted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _tokoAktif
                      ? 'Produk Anda tampil di etalase pembeli dan siap dipesan.'
                      : 'Matikan saat toko libur agar pesanan baru tidak masuk.',
                  style: const TextStyle(fontSize: 12, color: OC.muted),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _tokoAktif,
            activeThumbColor: OC.primary,
            onChanged: (v) => setState(() => _tokoAktif = v),
          ),
        ],
      ),
    );
  }

  // ---------------------------------- Unified Lokasi Dapur & Titik GPS
  Widget _cardLokasiDapurTunggal(UmkmProfile profile) {
    final hasLocation = profile.latitude != null && profile.longitude != null;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasLocation ? OC.primary.withValues(alpha: 0.3) : const Color(0xFFFDE8D0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: hasLocation ? OC.mint : const Color(0xFFFDE8D0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  hasLocation ? Icons.location_on : Icons.location_off_outlined,
                  size: 20,
                  color: hasLocation ? OC.primary : const Color(0xFFE67E22),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasLocation
                          ? 'Titik GPS Tersimpan'
                          : 'Titik GPS Belum Disetel',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: hasLocation ? OC.ink : const Color(0xFFE67E22),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      profile.alamat.isNotEmpty
                          ? profile.alamat
                          : 'Belum ada alamat dapur tersimpan.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: profile.alamat.isNotEmpty ? OC.ink : OC.muted,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasLocation
                          ? 'Koordinat: ${profile.latitude!.toStringAsFixed(6)}, ${profile.longitude!.toStringAsFixed(6)}'
                          : 'Layanan kurir desa mewajibkan titik koordinat untuk menghitung ongkir.',
                      style: TextStyle(
                        fontSize: 11,
                        color: hasLocation ? OC.primary : const Color(0xFFE67E22),
                        fontFamily: hasLocation ? 'monospace' : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _pilihLokasiUMKM,
              icon: Icon(
                hasLocation
                    ? Icons.edit_location_alt_outlined
                    : Icons.add_location_outlined,
                color: OC.primary,
                size: 18,
              ),
              label: Text(
                hasLocation
                    ? 'Ubah Titik Lokasi di Peta'
                    : 'Pilih Titik Lokasi Dapur di Peta',
                style: const TextStyle(
                  color: OC.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: OC.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Center(
            child: Text(
              'Memilih lokasi di peta otomatis mengisi nama jalan dan titik GPS dapur.',
              style: TextStyle(fontSize: 11, color: OC.muted),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------- Jarak & Ongkir Card
  Widget _cardOngkirInfo() {
    final radiusGratis =
        double.tryParse(_radiusCtrl.text.replaceAll(',', '.')) ?? 0;
    final jarakMaksimal = _zonaBaris.isEmpty
        ? radiusGratis
        : (double.tryParse(
                _zonaBaris.last.sampaiCtrl.text.replaceAll(',', '.'),
              ) ??
              radiusGratis);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: OC.box,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: OC.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.route_outlined, size: 18, color: OC.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Jarak Maksimal Pengantaran',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: OC.line),
                ),
                child: Text(
                  '${_fmtKm(jarakMaksimal)} KM',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: OC.primary,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Ongkir dihitung otomatis dari titik koordinat GPS dapur Anda ke titik pengiriman pembeli menggunakan rumus jarak Haversine.',
            style: TextStyle(color: OC.muted, fontSize: 11.5, height: 1.3),
          ),
        ],
      ),
    );
  }

  // ---------------------------------- Pembayaran Card
  Widget _cardKebijakanPembayaran() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OC.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: OC.banner,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.verified_user_outlined, size: 18, color: OC.primary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pembayaran online diproses via Midtrans. Aktifkan COD jika siap menerima uang tunai saat pesanan sampai.',
                    style: TextStyle(fontSize: 12, color: OC.muted),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _toggleTile(
            judul: 'COD (Bayar di Tempat)',
            subjudul: 'Titip uang tunai ke kurir saat pesanan sampai',
            nilai: _codAktif,
            ikon: Icons.payments_outlined,
            onChanged: (v) => setState(() => _codAktif = v),
          ),
          const SizedBox(height: 14),
          const Text(
            'Skema Pembayaran Pre-Order (PO)',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
          ),
          const SizedBox(height: 2),
          const Text(
            'Aturan uang muka saat pesanan dalam porsi katering besar',
            style: TextStyle(color: OC.muted, fontSize: 12),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _skemaPO,
            isExpanded: true,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: _skemaOptions
                .map(
                  (s) => DropdownMenuItem(
                    value: s,
                    child: Text(s, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _skemaPO = v!),
          ),
        ],
      ),
    );
  }

  // ---------------------------------- Akun & Sesi Card
  Widget _cardAkunDanSesi() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OC.line),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: OC.box,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.password_outlined, size: 18, color: OC.muted),
            ),
            title: const Text(
              'Ubah Kata Sandi',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
            ),
            subtitle: const Text(
              'Perbarui kata sandi akun UMKM Anda',
              style: TextStyle(color: OC.muted, fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right, color: OC.muted),
            onTap: _ubahPassword,
          ),
          const Divider(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: OC.mintSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.swap_horiz_rounded, size: 20, color: OC.primary),
            ),
            title: const Text(
              'Beralih ke Akun Pembeli',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: OC.primary),
            ),
            subtitle: const Text(
              'Kembali belanja kuliner lokal sebagai pelanggan',
              style: TextStyle(color: OC.muted, fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right, color: OC.primary),
            onTap: _switchToCustomer,
          ),
          const Divider(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: OC.dangerSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.logout_rounded, size: 18, color: OC.danger),
            ),
            title: const Text(
              'Keluar Akun',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: OC.danger),
            ),
            subtitle: const Text(
              'Selesaikan sesi login UMKM di perangkat ini',
              style: TextStyle(color: OC.muted, fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right, color: OC.danger),
            onTap: _confirmLogout,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<UmkmDataService>().profile;

    final bodyContent = ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        widget.isTab ? 10 : 8,
        16,
        widget.isTab ? 110 : 30,
      ),
      children: [
        // 1. Profil Usaha
        _cardProfilUsaha(profile),
        const SizedBox(height: 18),

        // 2. Status Operasional Toko
        _judulSeksi(
          Icons.schedule_outlined,
          'Operasional Toko',
          'Atur kesiapan dapur menerima order baru',
        ),
        _cardStatusToko(),
        const SizedBox(height: 20),

        // 3. Lokasi Dapur & Alamat GPS (Tunggal & Terintegrasi)
        _judulSeksi(
          Icons.location_on_outlined,
          'Lokasi Dapur & Titik GPS',
          'Titik koordinat untuk kalkulasi ongkir kurir otomatis',
        ),
        _cardLokasiDapurTunggal(profile),
        const SizedBox(height: 20),

        // 4. Layanan Pengiriman & Ongkir
        _judulSeksi(
          Icons.local_shipping_outlined,
          'Layanan Pengiriman',
          'Pilihan cara penerimaan makanan oleh pembeli',
        ),
        _toggleTile(
          judul: 'Pickup / Ambil di Dapur',
          subjudul: 'Pelanggan mengambil langsung ke alamat dapur Anda',
          nilai: _pickupAktif,
          ikon: Icons.storefront_outlined,
          onChanged: (v) => setState(() => _pickupAktif = v),
        ),
        const SizedBox(height: 10),
        _toggleTile(
          judul: 'Diantar UMKM / Kurir Warga',
          subjudul: 'Pengantaran kurir langsung ke titik rumah pembeli',
          nilai: _kurirAktif,
          ikon: Icons.delivery_dining_outlined,
          onChanged: (v) => setState(() => _kurirAktif = v),
        ),
        if (_kurirAktif) ...[
          const SizedBox(height: 10),
          _cardOngkirInfo(),
        ],
        const SizedBox(height: 20),

        // 5. Kebijakan Pembayaran
        _judulSeksi(
          Icons.account_balance_wallet_outlined,
          'Kebijakan Pembayaran',
          'Atur metode penerimaan uang pesanan',
        ),
        _cardKebijakanPembayaran(),
        const SizedBox(height: 20),

        // 6. Akun, Keamanan, & Sesi
        _judulSeksi(
          Icons.manage_accounts_outlined,
          'Akun & Keamanan',
          'Kata sandi dan manajemen sesi perangkat',
        ),
        _cardAkunDanSesi(),
        const SizedBox(height: 24),

        // Tombol Simpan jika dalam mode Tab
        if (widget.isTab) ...[
          ElevatedButton.icon(
            onPressed: _menyimpan ? null : _simpanPengaturan,
            icon: _menyimpan
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_circle_outline),
            label: Text(_menyimpan ? 'Menyimpan...' : 'Simpan Pengaturan'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );

    if (widget.isTab) {
      return Scaffold(backgroundColor: OC.bg, body: bodyContent);
    }

    return Scaffold(
      backgroundColor: OC.bg,
      body: SafeArea(
        child: Column(
          children: [
            DjajanPageHeader(
              title: 'Pengaturan Usaha',
              subtitle: 'Profil, operasional, & ongkir warung',
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: OC.muted),
                onPressed: () => Navigator.maybePop(context),
              ),
            ),
            Expanded(child: bodyContent),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: ElevatedButton.icon(
            onPressed: _menyimpan ? null : _simpanPengaturan,
            icon: _menyimpan
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_circle_outline),
            label: Text(_menyimpan ? 'Menyimpan...' : 'Simpan Pengaturan'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
