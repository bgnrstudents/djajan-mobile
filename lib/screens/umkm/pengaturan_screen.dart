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
import '../../widgets/umkm_app_bar.dart';
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Header Sheet
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
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
                                fontWeight: FontWeight.w700,
                                fontSize: 16.5,
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
                      IconButton(
                        icon:
                            const Icon(Icons.close, color: OC.muted, size: 20),
                        onPressed: () => Navigator.pop(ctx, false),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, thickness: 1, color: Colors.grey.shade200),

                // Form Fields dengan padding lega (16px - 24px) dan label di luar
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nama Usaha',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: OC.ink,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _sheetField(
                          controller: namaCtrl,
                          hint: 'Nama warung/dapur Anda',
                          icon: Icons.storefront_outlined,
                          capitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: 20),

                        const Text(
                          'Spesialis / Kategori Makanan',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: OC.ink,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _sheetField(
                          controller: spesialisCtrl,
                          hint: 'Contoh: Aneka Jajanan Pasar & Tumpeng',
                          icon: Icons.restaurant_menu_outlined,
                        ),
                        const SizedBox(height: 20),

                        const Text(
                          'Nomor WhatsApp Usaha',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: OC.ink,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _sheetField(
                          controller: telpCtrl,
                          hint: '08xxxxxxxxxx',
                          icon: Icons.phone_outlined,
                          inputType: TextInputType.phone,
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),

                // Sticky button "Simpan Perubahan" full-width di bagian paling bawah
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade200, width: 1),
                    ),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(ctx, true),
                      icon: const Icon(Icons.check_circle_outline,
                          color: Colors.white, size: 18),
                      label: const Text(
                        'Simpan Perubahan',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: OC.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
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

  /// TextField bergaya modern DJajan untuk dipakai di bottom sheet form.
  static Widget _sheetField({
    required TextEditingController controller,
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
        hintText: hint,
        hintStyle: const TextStyle(color: OC.faint, fontSize: 13.5),
        prefixIcon: Icon(icon, size: 20, color: OC.muted),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: OC.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: OC.muted,
        ),
      ),
    );
  }

  Widget _groupedCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _groupRowDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: Color(0xFFF3F4F6),
      indent: 54,
      endIndent: 16,
    );
  }

  Widget _switchRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    Color iconColor = OC.primary,
    Color iconBg = OC.mint,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: value ? iconBg : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: value ? iconColor : const Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                    color: OC.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: OC.muted,
                    fontSize: 11.5,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: value,
            activeThumbColor: OC.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _actionRow({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    required VoidCallback onTap,
    Color iconColor = OC.ink,
    Color iconBg = const Color(0xFFF3F4F6),
    Color textColor = OC.ink,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                      color: textColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: OC.muted,
                        fontSize: 11.5,
                        height: 1.25,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing ??
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: Color(0xFF9CA3AF),
                ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------- Hero Card (Profil + Live Status)
  Widget _buildHeroCard(UmkmProfile profile) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    GambarJaringan(
                      url: profile.fotoProfilUrl,
                      width: 64,
                      height: 64,
                      radius: 32,
                      ikonKosong: Icons.storefront,
                      cacheBuster:
                          DateTime.now().millisecondsSinceEpoch.toString(),
                    ),
                    GestureDetector(
                      onTap: _mengunggahFoto ? null : _gantiFoto,
                      child: Container(
                        padding: const EdgeInsets.all(5),
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
                          fontWeight: FontWeight.w700,
                          fontSize: 16.5,
                          color: OC.ink,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (profile.noTelpUsaha.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'WA: ${profile.noTelpUsaha}',
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
                  icon: const Icon(Icons.edit_outlined,
                      color: OC.primary, size: 20),
                  tooltip: 'Ubah Profil Usaha',
                  style: IconButton.styleFrom(
                    backgroundColor: OC.mintSoft,
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _tokoAktif ? OC.mint : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _tokoAktif ? Icons.storefront : Icons.storefront_outlined,
                    color: _tokoAktif ? OC.primary : const Color(0xFF9CA3AF),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _tokoAktif
                                ? 'Status Toko: Buka'
                                : 'Status Toko: Tutup',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                              color: _tokoAktif
                                  ? OC.ink
                                  : const Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 6.5,
                            height: 6.5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _tokoAktif
                                  ? const Color(0xFF10B981)
                                  : Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _tokoAktif
                            ? 'Menerima pesanan & tampil di etalase pembeli'
                            : 'Toko libur sementara, pesanan baru dijeda',
                        style: const TextStyle(fontSize: 11.5, color: OC.muted),
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
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<UmkmDataService>().profile;
    final hasLocation = profile.latitude != null && profile.longitude != null;
    final radiusGratis =
        double.tryParse(_radiusCtrl.text.replaceAll(',', '.')) ?? 0;
    final jarakMaksimal = _zonaBaris.isEmpty
        ? radiusGratis
        : (double.tryParse(
                _zonaBaris.last.sampaiCtrl.text.replaceAll(',', '.'),
              ) ??
              radiusGratis);

    final bodyContent = ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        // 1. Hero Card: Profil & Status Toko Terintegrasi
        _buildHeroCard(profile),

        // 2. Group Operasional & Pengiriman
        _sectionHeader('OPERASIONAL & PENGIRIMAN'),
        _groupedCard(
          children: [
            _actionRow(
              icon: Icons.location_on_outlined,
              iconColor: hasLocation ? OC.primary : const Color(0xFFD97706),
              iconBg: hasLocation ? OC.mint : const Color(0xFFFEF3C7),
              title: 'Lokasi Dapur & Pengiriman',
              subtitle: profile.alamat.isNotEmpty
                  ? profile.alamat
                  : 'Atur titik lokasi dapur untuk kalkulasi kurir',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: hasLocation ? OC.mint : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      hasLocation ? 'Tersimpan' : 'Atur Titik',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color:
                            hasLocation ? OC.primary : const Color(0xFFB45309),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded,
                      size: 20, color: Color(0xFF9CA3AF)),
                ],
              ),
              onTap: _pilihLokasiUMKM,
            ),
            _groupRowDivider(),
            _switchRow(
              icon: Icons.storefront_outlined,
              title: 'Ambil di Tempat (Self-Pickup)',
              subtitle: 'Pelanggan mengambil pesanan langsung ke dapur Anda',
              value: _pickupAktif,
              onChanged: (v) => setState(() => _pickupAktif = v),
            ),
            _groupRowDivider(),
            _switchRow(
              icon: Icons.delivery_dining_outlined,
              title: 'Pengantaran Kurir Toko / Warga',
              subtitle: 'Pesanan diantar langsung ke rumah pembeli',
              value: _kurirAktif,
              onChanged: (v) => setState(() => _kurirAktif = v),
            ),
            if (_kurirAktif) ...[
              Container(
                margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.route_outlined,
                            size: 16, color: OC.primary),
                        const SizedBox(width: 6),
                        const Expanded(
                          child: Text(
                            'Jangkauan Pengantaran',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                              color: OC.ink,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Text(
                            'Maks. ${_fmtKm(jarakMaksimal)} KM',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: OC.primary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Ongkir dihitung otomatis berdasarkan jarak tempuh ke titik lokasi pembeli.',
                      style:
                          TextStyle(color: OC.muted, fontSize: 11, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),

        // 3. Group Pembayaran & Pre-Order
        _sectionHeader('PEMBAYARAN & PRE-ORDER'),
        _groupedCard(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(14, 14, 14, 4),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: OC.mintSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined, size: 16, color: OC.primary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pembayaran online diproses otomatis. Aktifkan COD bila Anda menerima uang tunai saat pengantaran.',
                      style:
                          TextStyle(fontSize: 11.5, color: OC.ink, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            _switchRow(
              icon: Icons.payments_outlined,
              title: 'Bayar di Tempat (COD)',
              subtitle:
                  'Pelanggan membayar tunai kepada pengantar saat pesanan tiba',
              value: _codAktif,
              onChanged: (v) => setState(() => _codAktif = v),
            ),
            _groupRowDivider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.event_note_outlined,
                          size: 20,
                          color: OC.ink,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Skema Uang Muka Pre-Order (PO)',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13.5,
                                color: OC.ink,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Ketentuan pembayaran untuk pesanan katering porsi besar',
                              style: TextStyle(color: OC.muted, fontSize: 11.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _skemaPO,
                    isExpanded: true,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFFE5E7EB), width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFFE5E7EB), width: 1),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide(color: OC.primary, width: 1.5),
                      ),
                    ),
                    items: _skemaOptions
                        .map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text(
                              s,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12.5, color: OC.ink),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _skemaPO = v);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),

        // 4. Group Akun & Keamanan
        _sectionHeader('AKUN & KEAMANAN'),
        _groupedCard(
          children: [
            _actionRow(
              icon: Icons.lock_outline_rounded,
              iconColor: const Color(0xFF4B5563),
              iconBg: const Color(0xFFF3F4F6),
              title: 'Ubah Kata Sandi',
              subtitle: 'Perbarui kata sandi akun UMKM Anda',
              onTap: _ubahPassword,
            ),
            _groupRowDivider(),
            _actionRow(
              icon: Icons.shopping_bag_outlined,
              iconColor: OC.primary,
              iconBg: OC.mintSoft,
              title: 'Beralih ke Akun Pelanggan',
              subtitle: 'Beli aneka kuliner lokal sebagai pembeli',
              textColor: OC.primary,
              trailing: const Icon(Icons.chevron_right_rounded,
                  size: 20, color: OC.primary),
              onTap: _switchToCustomer,
            ),
            _groupRowDivider(),
            _actionRow(
              icon: Icons.logout_rounded,
              iconColor: OC.danger,
              iconBg: OC.dangerSoft,
              title: 'Keluar Akun UMKM',
              subtitle: 'Akhiri sesi login mitra di perangkat ini',
              textColor: OC.danger,
              trailing: const Icon(Icons.chevron_right_rounded,
                  size: 20, color: OC.danger),
              onTap: _confirmLogout,
            ),
          ],
        ),
      ],
    );

    if (widget.isTab) {
      return Scaffold(
        backgroundColor: OC.bg,
        body: Column(
          children: [
            Expanded(child: bodyContent),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48,
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
                      : const Icon(Icons.check_circle_outline,
                          color: Colors.white),
                  label: Text(
                    _menyimpan ? 'Menyimpan...' : 'Simpan Pengaturan',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: OC.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: OC.bg,
      body: SafeArea(
        child: Column(
          children: [
            UmkmAppBar(
              title: 'Pengaturan Usaha',
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: OC.muted),
                onPressed: () => Navigator.maybePop(context),
              ),
            ),
            Expanded(child: bodyContent),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SizedBox(
              width: double.infinity,
              height: 50,
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
                    : const Icon(Icons.check_circle_outline,
                        color: Colors.white),
                label: Text(
                  _menyimpan ? 'Menyimpan...' : 'Simpan Pengaturan',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: OC.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
