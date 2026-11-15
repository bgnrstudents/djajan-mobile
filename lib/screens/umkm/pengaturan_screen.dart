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
  late bool _tokoAktifTersimpan;
  late bool _codAktifTersimpan;
  late String _skemaPOTersimpan;
  late bool _pickupAktifTersimpan;
  late bool _kurirAktifTersimpan;

  late TextEditingController _radiusCtrl;
  final List<_ZonaBaris> _zonaBaris = [];

  bool _menyimpan = false;
  bool _mengunggahFoto = false;

  bool get _adaPerubahan =>
      _tokoAktif != _tokoAktifTersimpan ||
      _codAktif != _codAktifTersimpan ||
      _skemaPO != _skemaPOTersimpan ||
      _pickupAktif != _pickupAktifTersimpan ||
      _kurirAktif != _kurirAktifTersimpan;

  String _labelSkemaPO(String skema) {
    if (skema.startsWith('DP 30%')) return 'DP 30%';
    if (skema.startsWith('DP 50%')) return 'DP 50%';
    if (skema.startsWith('Lunas di Awal')) return 'Lunas di awal';
    return 'Tanpa DP';
  }

  String _deskripsiSkemaPO(String skema) {
    if (skema.startsWith('DP 30%')) {
      return 'Bayar 30% di awal, sisanya saat pesanan diantar';
    }
    if (skema.startsWith('DP 50%')) {
      return 'Bayar 50% di awal, sisanya saat pesanan diantar';
    }
    if (skema.startsWith('Lunas di Awal')) {
      return 'Seluruh pembayaran dilakukan sebelum pesanan';
    }
    return 'Pembayaran dilakukan saat pesanan sampai';
  }

  Future<void> _pilihSkemaPO() async {
    final pilihan = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 17, 16, 13),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Skema pembayaran PO',
                        style: TextStyle(
                          color: OC.ink,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      color: OC.muted,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: OC.line),
              ..._skemaOptions.map(
                (skema) => ListTile(
                  onTap: () => Navigator.pop(context, skema),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 3,
                  ),
                  title: Text(
                    _labelSkemaPO(skema),
                    style: TextStyle(
                      color: skema == _skemaPO ? OC.primary : OC.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    _deskripsiSkemaPO(skema),
                    style: const TextStyle(
                      color: OC.muted,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                  trailing: Icon(
                    skema == _skemaPO
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: skema == _skemaPO ? OC.primary : OC.faint,
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );

    if (pilihan != null && mounted) {
      setState(() => _skemaPO = pilihan);
    }
  }

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
    _tokoAktifTersimpan = _tokoAktif;
    _codAktifTersimpan = _codAktif;
    _skemaPOTersimpan = _skemaPO;
    _pickupAktifTersimpan = _pickupAktif;
    _kurirAktifTersimpan = _kurirAktif;

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
    String? hasil;
    var namaUsaha = '';
    var spesialisasi = '';
    var noTelpUsaha = '';
    try {
      hasil = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) {
          var namaDisentuh = false;
          var teleponDisentuh = false;

          String? errorNama() => namaDisentuh && namaCtrl.text.trim().isEmpty
              ? 'Nama usaha wajib diisi.'
              : null;

          String? errorTelepon() {
            final nomor = telpCtrl.text.trim();
            if (!teleponDisentuh || nomor.isEmpty) return null;
            final digit = nomor.replaceAll(RegExp(r'[\s()+-]'), '');
            return RegExp(r'^\d{10,15}$').hasMatch(digit)
                ? null
                : 'Masukkan nomor WhatsApp dengan 10–15 digit.';
          }

          bool nomorTeleponValid() {
            final nomor = telpCtrl.text.trim();
            if (nomor.isEmpty) return true;
            final digit = nomor.replaceAll(RegExp(r'[\s()+-]'), '');
            return RegExp(r'^\d{10,15}$').hasMatch(digit);
          }

          return StatefulBuilder(
            builder: (context, setSheetState) {
              final namaValid = namaCtrl.text.trim().isNotEmpty;
              final teleponValid = nomorTeleponValid();
              final berubah =
                  namaCtrl.text.trim() != p.namaUsaha ||
                  spesialisCtrl.text.trim() != p.spesialis ||
                  telpCtrl.text.trim() != p.noTelpUsaha;

              return AnimatedPadding(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: EdgeInsets.only(
                  bottom: MediaQuery.viewInsetsOf(ctx).bottom,
                ),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    height: MediaQuery.sizeOf(ctx).height * 0.88,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: OC.bg,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(28),
                        ),
                      ),
                      child: Column(
                        children: [
                          Center(
                            child: Container(
                              margin: const EdgeInsets.only(top: 11, bottom: 7),
                              width: 38,
                              height: 4,
                              decoration: BoxDecoration(
                                color: const Color(0xFFD4DAD5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 8, 14, 15),
                            child: Row(
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFE7F2E9), Colors.white],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(color: OC.line),
                                  ),
                                  child: const Icon(
                                    Icons.storefront_rounded,
                                    color: OC.primary,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Informasi usaha',
                                        style: TextStyle(
                                          color: OC.ink,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      SizedBox(height: 3),
                                      Text(
                                        'Atur identitas yang dilihat pelanggan',
                                        style: TextStyle(
                                          color: OC.muted,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: OC.muted,
                                  ),
                                  icon: const Icon(Icons.close_rounded),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1, color: OC.line),
                          Expanded(
                            child: SingleChildScrollView(
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                22,
                                20,
                                24,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'DETAIL PROFIL',
                                    style: TextStyle(
                                      color: OC.muted,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.9,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _sheetField(
                                    controller: namaCtrl,
                                    label: 'Nama usaha',
                                    hint: 'Contoh: Dapur Ibu Sari',
                                    helper: 'Gunakan nama yang mudah dikenali.',
                                    icon: Icons.storefront_outlined,
                                    capitalization: TextCapitalization.words,
                                    errorText: errorNama(),
                                    onChanged: (_) {
                                      namaDisentuh = true;
                                      setSheetState(() {});
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  _sheetField(
                                    controller: spesialisCtrl,
                                    label: 'Spesialisasi',
                                    hint: 'Contoh: Jajanan pasar & kue',
                                    helper: 'Ceritakan jenis produk andalan usaha Anda.',
                                    icon: Icons.restaurant_menu_outlined,
                                    capitalization:
                                        TextCapitalization.sentences,
                                    onChanged: (_) => setSheetState(() {}),
                                  ),
                                  const SizedBox(height: 20),
                                  _sheetField(
                                    controller: telpCtrl,
                                    label: 'WhatsApp usaha',
                                    hint: '08xxxxxxxxxx',
                                    helper: 'Gunakan nomor aktif, 10–15 digit. Boleh dikosongkan.',
                                    icon: Icons.phone_iphone_outlined,
                                    inputType: TextInputType.phone,
                                    errorText: errorTelepon(),
                                    onChanged: (_) {
                                      teleponDisentuh = true;
                                      setSheetState(() {});
                                    },
                                  ),
                                  const SizedBox(height: 18),
                                  Container(
                                    padding: const EdgeInsets.all(13),
                                    decoration: BoxDecoration(
                                      color: OC.mintSoft,
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(
                                        color: OC.mint.withValues(alpha: 0.8),
                                      ),
                                    ),
                                    child: const Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.info_outline_rounded,
                                          size: 18,
                                          color: OC.primary,
                                        ),
                                        SizedBox(width: 9),
                                        Expanded(
                                          child: Text(
                                            'Alamat dan titik lokasi usaha dikelola melalui pengaturan lokasi dapur.',
                                            style: TextStyle(
                                              color: OC.ink,
                                              fontSize: 11.5,
                                              height: 1.4,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              border: Border(top: BorderSide(color: OC.line)),
                            ),
                            child: SafeArea(
                              top: false,
                              child: SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: FilledButton.icon(
                                  onPressed:
                                      berubah && namaValid && teleponValid
                                      ? () => Navigator.pop(ctx, 'save')
                                      : null,
                                  icon: const Icon(Icons.check_rounded),
                                  label: const Text(
                                    'Simpan perubahan',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: OC.primary,
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor: OC.primary
                                        .withValues(alpha: 0.35),
                                    disabledForegroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
      namaUsaha = namaCtrl.text.trim();
      spesialisasi = spesialisCtrl.text.trim();
      noTelpUsaha = telpCtrl.text.trim();
    } finally {
      namaCtrl.dispose();
      spesialisCtrl.dispose();
      telpCtrl.dispose();
    }

    if (hasil != 'save') return;

    try {
      final pesan = await service.simpanIdentitasUsaha(
        namaUsaha: namaUsaha,
        spesialis: spesialisasi,
        alamat: p.alamat,
        noTelpUsaha: noTelpUsaha,
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
      final radiusGratis =
          double.tryParse(_radiusCtrl.text.replaceAll(',', '.')) ??
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
      _tokoAktifTersimpan = _tokoAktif;
      _codAktifTersimpan = _codAktif;
      _skemaPOTersimpan = _skemaPO;
      _pickupAktifTersimpan = _pickupAktif;
      _kurirAktifTersimpan = _kurirAktif;
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
    required String label,
    required String hint,
    required String helper,
    required IconData icon,
    TextInputType inputType = TextInputType.text,
    TextCapitalization capitalization = TextCapitalization.none,
    String? errorText,
    ValueChanged<String>? onChanged,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(color: OC.line),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: OC.ink,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: inputType,
          textCapitalization: capitalization,
          onChanged: onChanged,
          style: const TextStyle(
            color: OC.ink,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: OC.faint, fontSize: 13),
            prefixIcon: Icon(icon, size: 19, color: OC.muted),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 48,
              minHeight: 48,
            ),
            errorText: errorText,
            errorStyle: const TextStyle(fontSize: 11.5),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 15,
            ),
            border: border,
            enabledBorder: border,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: OC.primary, width: 1.4),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: OC.danger),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: OC.danger, width: 1.4),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          helper,
          style: TextStyle(
            color: errorText == null ? OC.muted : OC.danger,
            fontSize: 11.5,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 24, 2, 9),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: OC.ink,
        ),
      ),
    );
  }

  Widget _groupedCard({required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  Widget _groupRowDivider() {
    return const Divider(height: 1, thickness: 1, color: OC.line, indent: 50);
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
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: value ? iconBg : Colors.white,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 19, color: value ? iconColor : OC.faint),
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
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: OC.muted,
                    fontSize: 11.5,
                    height: 1.3,
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
    Color iconBg = OC.box,
    Color textColor = OC.ink,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(11),
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
                      height: 1.25,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: OC.muted,
                        fontSize: 11.5,
                        height: 1.3,
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
                  color: OC.faint,
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
        gradient: const LinearGradient(
          colors: [Color(0xFF103D20), Color(0xFF175D2B), Color(0xFF26743B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: OC.primary.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(19, 16, 19, 0),
            child: Row(
              children: [
                Container(
                  width: 18,
                  height: 2,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFBE25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 7),
                const Text(
                  'PROFIL MITRA',
                  style: TextStyle(
                    color: Color(0xFFD8EBDD),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.15,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 14, 16),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: GambarJaringan(
                        url: profile.fotoProfilUrl,
                        width: 68,
                        height: 68,
                        radius: 34,
                        ikonKosong: Icons.storefront,
                        cacheBuster: DateTime.now().millisecondsSinceEpoch
                            .toString(),
                      ),
                    ),
                    Material(
                      color: const Color(0xFFFFBE25),
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: _mengunggahFoto ? null : _gantiFoto,
                        customBorder: const CircleBorder(),
                        child: SizedBox(
                          width: 27,
                          height: 27,
                          child: Center(
                            child: _mengunggahFoto
                                ? const SizedBox(
                                    width: 13,
                                    height: 13,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: OC.primary,
                                    ),
                                  )
                                : const Icon(
                                    Icons.camera_alt_rounded,
                                    size: 14,
                                    color: OC.primary,
                                  ),
                          ),
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      if (profile.spesialis.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          profile.spesialis,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFD8EBDD),
                            fontSize: 12,
                          ),
                        ),
                      ],
                      if (profile.noTelpUsaha.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          'WA ${profile.noTelpUsaha}',
                          style: const TextStyle(
                            color: Color(0xFFD8EBDD),
                            fontSize: 11,
                          ),
                        ),
                      ],
                      const SizedBox(height: 9),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              profile.terverifikasi
                                  ? Icons.verified_rounded
                                  : Icons.hourglass_top_rounded,
                              size: 13,
                              color: profile.terverifikasi
                                  ? const Color(0xFFFFD166)
                                  : const Color(0xFFFFDDA0),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              profile.terverifikasi
                                  ? 'Mitra terverifikasi'
                                  : 'Menunggu verifikasi',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _editIdentitas,
                  tooltip: 'Ubah profil usaha',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.14),
                    foregroundColor: Colors.white,
                    fixedSize: const Size(40, 40),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 19),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _tokoAktif
                          ? const Color(0xFF76E0A1)
                          : const Color(0xFFB7C0B9),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _tokoAktif ? 'Toko sedang buka' : 'Toko sedang tutup',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _tokoAktif
                              ? 'Pesanan baru dapat diterima'
                              : 'Pesanan baru dijeda sementara',
                          style: const TextStyle(
                            color: Color(0xFFD8EBDD),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _tokoAktif,
                    activeThumbColor: Colors.white,
                    activeTrackColor: const Color(0xFF65A979),
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: Colors.white24,
                    onChanged: (value) => setState(() => _tokoAktif = value),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveBar({required bool compact}) {
    final horizontalPadding = compact ? 16.0 : 16.0;
    return Container(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        10,
        horizontalPadding,
        compact ? 12 : 10,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: OC.line)),
      ),
      child: SafeArea(
        top: false,
        child: _adaPerubahan || _menyimpan
            ? SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
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
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    _menyimpan ? 'Menyimpan...' : 'Simpan perubahan',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: OC.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              )
            : const Padding(
                padding: EdgeInsets.symmetric(vertical: 9),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 17,
                      color: OC.primary,
                    ),
                    SizedBox(width: 7),
                    Text(
                      'Pengaturan sudah tersimpan',
                      style: TextStyle(
                        color: OC.muted,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        // 1. Hero Card: Profil & Status Toko Terintegrasi
        _buildHeroCard(profile),

        // 2. Group Operasional & Pengiriman
        _sectionHeader('Operasional & pengiriman'),
        _groupedCard(
          children: [
            _actionRow(
              icon: Icons.location_on_outlined,
              iconColor: hasLocation ? OC.primary : const Color(0xFFD97706),
              iconBg: hasLocation ? OC.mintSoft : const Color(0xFFFEF3C7),
              title: 'Lokasi dapur',
              subtitle: profile.alamat.isNotEmpty
                  ? profile.alamat
                  : 'Atur titik lokasi dapur untuk kalkulasi kurir',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: hasLocation ? OC.mint : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      hasLocation ? 'Tersimpan' : 'Atur Titik',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: hasLocation
                            ? OC.primary
                            : const Color(0xFFB45309),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: Color(0xFF9CA3AF),
                  ),
                ],
              ),
              onTap: _pilihLokasiUMKM,
            ),
            _groupRowDivider(),
            _switchRow(
              icon: Icons.storefront_outlined,
              title: 'Ambil di tempat',
              subtitle: 'Pembeli mengambil pesanan langsung ke dapur',
              value: _pickupAktif,
              onChanged: (v) => setState(() => _pickupAktif = v),
            ),
            _groupRowDivider(),
            _switchRow(
              icon: Icons.delivery_dining_outlined,
              title: 'Pengantaran',
              subtitle: 'Antar pesanan ke alamat pembeli',
              value: _kurirAktif,
              onChanged: (v) => setState(() => _kurirAktif = v),
            ),
            if (_kurirAktif) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(50, 0, 2, 12),
                child: Row(
                  children: [
                    const Icon(
                      Icons.route_outlined,
                      size: 16,
                      color: OC.primary,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        'Jangkauan hingga ${_fmtKm(jarakMaksimal)} km',
                        style: const TextStyle(
                          color: OC.muted,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),

        // 3. Group Pembayaran & Pre-Order
        _sectionHeader('Pembayaran & pre-order'),
        _groupedCard(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(17, 15, 17, 0),
              child: Row(
                children: [
                  const Icon(
                    Icons.shield_outlined,
                    size: 16,
                    color: OC.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pembayaran online diproses otomatis.',
                      style: OT.secondary.copyWith(fontSize: 11.5),
                    ),
                  ),
                ],
              ),
            ),
            _switchRow(
              icon: Icons.payments_outlined,
              title: 'Bayar di Tempat (COD)',
              subtitle: 'Terima pembayaran tunai saat pesanan tiba',
              value: _codAktif,
              onChanged: (v) => setState(() => _codAktif = v),
            ),
            _groupRowDivider(),
            _groupRowDivider(),
            _actionRow(
              icon: Icons.event_note_outlined,
              iconColor: OC.amber,
              iconBg: OC.peachSoft,
              title: 'Uang muka pre-order',
              subtitle: _labelSkemaPO(_skemaPO),
              trailing: const Icon(
                Icons.expand_more_rounded,
                size: 22,
                color: OC.muted,
              ),
              onTap: _pilihSkemaPO,
            ),
          ],
        ),

        // 4. Group Akun & Keamanan
        _sectionHeader('Akun & keamanan'),
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
              trailing: const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: OC.primary,
              ),
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
              trailing: const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: OC.danger,
              ),
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
            _buildSaveBar(compact: true),
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
              subtitle: _tokoAktif
                  ? 'Toko buka  ·  Profil & operasional'
                  : 'Toko tutup  ·  Profil & operasional',
              leading: DjajanBackButton(
                onPressed: () => Navigator.maybePop(context),
              ),
            ),
            Expanded(child: bodyContent),
          ],
        ),
      ),
      bottomNavigationBar: _buildSaveBar(compact: false),
    );
  }
}
