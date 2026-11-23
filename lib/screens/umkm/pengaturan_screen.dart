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
import '../../theme/app_theme.dart';
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

  late String _skemaOngkir; // 'flat', 'standar', 'gratis', 'zona'
  late String _skemaOngkirTersimpan;
  late TextEditingController _biayaFlatCtrl;
  late TextEditingController _jarakMaksimalCtrl;

  late TextEditingController _radiusCtrl;
  final List<_ZonaBaris> _zonaBaris = [];

  bool _menyimpan = false;
  bool _mengunggahFoto = false;

  bool _expandOperasional = true;
  bool _expandPembayaran = true;
  bool _expandAkun = true;

  bool get _adaPerubahan =>
      _tokoAktif != _tokoAktifTersimpan ||
      _codAktif != _codAktifTersimpan ||
      _skemaPO != _skemaPOTersimpan ||
      _pickupAktif != _pickupAktifTersimpan ||
      _kurirAktif != _kurirAktifTersimpan ||
      _skemaOngkir != _skemaOngkirTersimpan;

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

  String get _labelSkemaOngkir {
    switch (_skemaOngkir) {
      case 'flat':
        final tarif = int.tryParse(_biayaFlatCtrl.text) ?? 5000;
        final maxKm =
            _jarakMaksimalCtrl.text.isEmpty ? '10' : _jarakMaksimalCtrl.text;
        return 'Flat Rp ${tarif.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} (Maks $maxKm km)';
      case 'gratis':
        final maxKm =
            _jarakMaksimalCtrl.text.isEmpty ? '10' : _jarakMaksimalCtrl.text;
        return 'Gratis Ongkir (Maks $maxKm km)';
      case 'zona':
        return 'Zona Kustom (${_zonaBaris.length} zona)';
      case 'standar':
      default:
        return 'Standar Desa (Rp 3.000/km)';
    }
  }

  String get _deskripsiSkemaOngkir {
    switch (_skemaOngkir) {
      case 'flat':
        return 'Satu tarif tetap ke seluruh pembeli dalam radius pengantaran';
      case 'gratis':
        return 'Bebas biaya ongkir untuk semua pembeli di sekitar tokomu';
      case 'zona':
        return 'Tarif bertingkat disesuaikan jarak kilometer';
      case 'standar':
      default:
        return '1 km pertama Rp 3.000, tiap km berikutnya +Rp 1.500';
    }
  }

  Widget _tileSkemaOption({
    required bool selected,
    required VoidCallback onTap,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: selected ? OC.primary : const Color(0xFFF0F5F0),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 20,
          color: selected ? Colors.white : OC.primary,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: selected ? OC.primary : OC.ink,
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: OC.muted, fontSize: 11.5, height: 1.3),
      ),
      trailing: Icon(
        selected
            ? Icons.radio_button_checked_rounded
            : Icons.radio_button_unchecked_rounded,
        color: selected ? OC.primary : OC.faint,
      ),
    );
  }

  Future<void> _pilihSkemaOngkir() async {
    String skemaSementara = _skemaOngkir;
    final biayaCtrl = TextEditingController(text: _biayaFlatCtrl.text);
    final jarakCtrl = TextEditingController(text: _jarakMaksimalCtrl.text);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Skema Tarif Pengantaran',
                                  style: TextStyle(
                                    color: OC.ink,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Tentukan skema ongkir kurir untuk tokomu',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: OC.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close_rounded),
                            color: OC.muted,
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: OC.line),
                    const SizedBox(height: 8),

                    // Opsi 1: Tarif Flat Toko Sendiri
                    _tileSkemaOption(
                      selected: skemaSementara == 'flat',
                      onTap: () => setModalState(() => skemaSementara = 'flat'),
                      icon: Icons.two_wheeler_rounded,
                      title: 'Tarif Flat Toko Sendiri (Rekomendasi)',
                      subtitle:
                          'Satu tarif tetap ke seluruh pembeli dalam radius pengantaran.',
                    ),
                    if (skemaSementara == 'flat')
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextField(
                                controller: biayaCtrl,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Biaya Ongkir (Rp)',
                                  prefixText: 'Rp ',
                                  hintText: '5000',
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: jarakCtrl,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Maks Jarak',
                                  suffixText: 'km',
                                  hintText: '5',
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Opsi 2: Standar Desa Kreyongan
                    _tileSkemaOption(
                      selected: skemaSementara == 'standar',
                      onTap: () =>
                          setModalState(() => skemaSementara = 'standar'),
                      icon: Icons.location_city_rounded,
                      title: 'Ikuti Standar Desa Kreyongan',
                      subtitle:
                          '1 km pertama Rp 3.000, berikutnya +Rp 1.500/km (Radius maks 10 km).',
                    ),

                    // Opsi 3: Gratis Ongkir Toko
                    _tileSkemaOption(
                      selected: skemaSementara == 'gratis',
                      onTap: () =>
                          setModalState(() => skemaSementara = 'gratis'),
                      icon: Icons.card_giftcard_rounded,
                      title: 'Gratis Ongkir Toko (Promosi)',
                      subtitle: 'Bebas biaya ongkir (Rp 0) untuk semua pembeli.',
                    ),

                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _skemaOngkir = skemaSementara;
                              _biayaFlatCtrl.text = biayaCtrl.text;
                              _jarakMaksimalCtrl.text = jarakCtrl.text;
                            });
                            Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: OC.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Terapkan Skema',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
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

    if (p.zonaOngkir.isNotEmpty) {
      _skemaOngkir = 'zona';
    } else if (p.radiusGratisKm > 0 &&
        (p.biayaPengantaran == 0 ||
            p.radiusGratisKm >= (p.jarakMaksimalKm ?? 10.0))) {
      _skemaOngkir = 'gratis';
    } else if (p.biayaPengantaran > 0) {
      _skemaOngkir = 'flat';
    } else {
      _skemaOngkir = 'standar';
    }
    _skemaOngkirTersimpan = _skemaOngkir;

    _biayaFlatCtrl = TextEditingController(
      text: p.biayaPengantaran > 0 ? p.biayaPengantaran.toString() : '5000',
    );
    _jarakMaksimalCtrl = TextEditingController(
      text: _fmtKm(p.jarakMaksimalKm ?? 10.0),
    );

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
    _biayaFlatCtrl.dispose();
    _jarakMaksimalCtrl.dispose();
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

              final viewInsetsBottom = MediaQuery.viewInsetsOf(ctx).bottom;
              final screenHeight = MediaQuery.sizeOf(ctx).height;
              final maxAllowedHeight = screenHeight - viewInsetsBottom;
              final targetHeight = (screenHeight * 0.88).clamp(
                120.0,
                maxAllowedHeight > 120.0 ? maxAllowedHeight : 120.0,
              );

              return AnimatedPadding(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: EdgeInsets.only(
                  bottom: viewInsetsBottom,
                ),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    height: targetHeight,
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
                                  Center(
                                    child: Column(
                                      children: [
                                        Stack(
                                          alignment: Alignment.bottomRight,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(3),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withValues(alpha: 0.08),
                                                    blurRadius: 10,
                                                    offset: const Offset(0, 3),
                                                  ),
                                                ],
                                              ),
                                              child: GambarJaringan(
                                                url: service.profile.fotoProfilUrl,
                                                width: 76,
                                                height: 76,
                                                radius: 38,
                                                ikonKosong: Icons.storefront_rounded,
                                                cacheBuster: DateTime.now().millisecondsSinceEpoch.toString(),
                                              ),
                                            ),
                                            Positioned(
                                              right: 0,
                                              bottom: 0,
                                              child: Material(
                                                color: AppColors.hijauTua,
                                                shape: const CircleBorder(),
                                                child: InkWell(
                                                  onTap: () async {
                                                    await _gantiFoto();
                                                    setSheetState(() {});
                                                  },
                                                  customBorder: const CircleBorder(),
                                                  child: Container(
                                                    padding: const EdgeInsets.all(6),
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      border: Border.all(color: Colors.white, width: 2),
                                                    ),
                                                    child: const Icon(
                                                      Icons.camera_alt_rounded,
                                                      size: 14,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        TextButton.icon(
                                          onPressed: () async {
                                            await _gantiFoto();
                                            setSheetState(() {});
                                          },
                                          icon: const Icon(Icons.photo_camera_outlined, size: 16, color: OC.primary),
                                          label: const Text(
                                            'Ubah Foto Profil Usaha',
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w700,
                                              color: OC.primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 14),
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

    int biayaPengantaran = 0;
    double radiusGratis = 0;
    double jarakMaksimal = 10.0;
    final List<ZonaOngkir> zonaBaru = [];

    if (_skemaOngkir == 'flat') {
      final flat = int.tryParse(_biayaFlatCtrl.text);
      if (flat == null || flat < 0) {
        if (mounted) pesanGagal(context, 'Biaya ongkir flat tidak valid.');
        return;
      }
      final maks =
          double.tryParse(_jarakMaksimalCtrl.text.replaceAll(',', '.'));
      if (maks == null || maks <= 0) {
        if (mounted) {
          pesanGagal(context, 'Maksimal jarak pengantaran tidak valid.');
        }
        return;
      }
      biayaPengantaran = flat;
      jarakMaksimal = maks;
      radiusGratis = 0;
    } else if (_skemaOngkir == 'gratis') {
      final maks =
          double.tryParse(_jarakMaksimalCtrl.text.replaceAll(',', '.'));
      if (maks == null || maks <= 0) {
        if (mounted) pesanGagal(context, 'Maksimal jarak gratis tidak valid.');
        return;
      }
      biayaPengantaran = 0;
      radiusGratis = maks;
      jarakMaksimal = maks;
    } else if (_skemaOngkir == 'standar') {
      biayaPengantaran = 0;
      radiusGratis = 0;
      jarakMaksimal = 10.0;
    } else if (_skemaOngkir == 'zona') {
      final rg = double.tryParse(_radiusCtrl.text.replaceAll(',', '.'));
      if (rg == null || rg < 0) {
        if (mounted) {
          pesanGagal(
            context,
            'Radius gratis ongkir harus berupa angka dan tidak boleh negatif.',
          );
        }
        return;
      }
      radiusGratis = rg;
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
        zonaBaru.add(
          ZonaOngkir(jarakMin: batas, jarakMax: sampai, biaya: tarif),
        );
        batas = sampai;
      }
      jarakMaksimal = batas;
    }

    setState(() => _menyimpan = true);
    try {
      final pesan = await service.simpanPengaturan(
        tokoAktif: _tokoAktif,
        codAktif: _codAktif,
        skemaPO: _skemaPO,
        pickupAktif: _pickupAktif,
        kurirWargaAktif: _kurirAktif,
        biayaPengantaran: biayaPengantaran,
      );

      await service.simpanOngkir(
        latitude: service.profile.latitude,
        longitude: service.profile.longitude,
        radiusGratisKm: radiusGratis,
        jarakMaksimalKm: jarakMaksimal,
        zonaOngkir: zonaBaru,
        biayaPengantaran: biayaPengantaran,
      );

      if (!mounted) return;
      _tokoAktifTersimpan = _tokoAktif;
      _codAktifTersimpan = _codAktif;
      _skemaPOTersimpan = _skemaPO;
      _pickupAktifTersimpan = _pickupAktif;
      _kurirAktifTersimpan = _kurirAktif;
      _skemaOngkirTersimpan = _skemaOngkir;
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

  Widget _sectionCardHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isExpanded,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: OC.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: OC.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: OC.muted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isExpanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: OC.muted,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _groupedCardBox({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 18),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEBEFEB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _switchRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    Color iconColor = OC.primary,
    Color iconBg = const Color(0xFFE8F5E9),
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
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
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: OC.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: OC.muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: value,
            activeThumbColor: Colors.white,
            activeTrackColor: OC.primary,
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
    Color iconColor = OC.primary,
    Color iconBg = const Color(0xFFE8F5E9),
    Color textColor = OC.ink,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
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
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                      color: textColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: OC.muted,
                        fontSize: 11,
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
                  color: OC.muted,
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
          colors: [Color(0xFF0F4B28), Color(0xFF135A31), Color(0xFF1B703F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F4B28).withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Baris Atas: Foto Profil + Info Usaha + Tombol Edit Profil
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar Toko + Tombol Kamera Ganti Foto
                    GestureDetector(
                      onTap: _mengunggahFoto ? null : _gantiFoto,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: GambarJaringan(
                              url: profile.fotoProfilUrl,
                              width: 62,
                              height: 62,
                              radius: 31,
                              ikonKosong: Icons.storefront_rounded,
                              cacheBuster:
                                  DateTime.now().millisecondsSinceEpoch.toString(),
                            ),
                          ),
                          Positioned(
                            right: -2,
                            bottom: -2,
                            child: Material(
                              color: AppColors.hijauTua,
                              shape: const CircleBorder(),
                              elevation: 2,
                              child: InkWell(
                                onTap: _mengunggahFoto ? null : _gantiFoto,
                                customBorder: const CircleBorder(),
                                child: Tooltip(
                                  message: 'Ganti Foto Profil Usaha',
                                  child: Container(
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: Center(
                                      child: _mengunggahFoto
                                          ? const SizedBox(
                                              width: 12,
                                              height: 12,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 1.8,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.camera_alt_rounded,
                                              size: 13,
                                              color: Colors.white,
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Info Nama Usaha, Spesialisasi & No Kontak
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.namaUsaha.isEmpty
                                ? 'Nama Usaha'
                                : profile.namaUsaha,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  profile.terverifikasi
                                      ? Icons.verified_rounded
                                      : Icons.shield_outlined,
                                  size: 11,
                                  color: const Color(0xFF86EFAC),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  profile.terverifikasi
                                      ? 'Mitra Terverifikasi'
                                      : 'Mitra',
                                  style: const TextStyle(
                                    color: Color(0xFFDCFCE7),
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.restaurant_menu_rounded,
                                size: 12,
                                color: Color(0xFFD4EED8),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  profile.spesialis.isNotEmpty
                                      ? profile.spesialis
                                      : 'Kuliner & Makanan',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFFD4EED8),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (profile.noTelpUsaha.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Icon(
                                  Icons.phone_outlined,
                                  size: 12,
                                  color: Color(0xFFD4EED8),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  profile.noTelpUsaha,
                                  style: const TextStyle(
                                    color: Color(0xFFD4EED8),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Tombol Outlined "Edit Profil"
                    InkWell(
                      onTap: _editIdentitas,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              size: 13,
                              color: Colors.white,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Edit Profil',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Baris Bawah: Status Buka / Tutup Toko dengan Switch
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: Colors.white,
                      size: 17,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 7.5,
                    height: 7.5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _tokoAktif
                          ? const Color(0xFF22C55E)
                          : const Color(0xFF9CA3AF),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _tokoAktif ? 'Toko Sedang Buka' : 'Toko Sedang Tutup',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 1.5),
                        Text(
                          _tokoAktif
                              ? 'Pesanan dapat masuk sekarang'
                              : 'Pesanan dijeda sementara',
                          style: const TextStyle(
                            color: Color(0xFFD4EED8),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _tokoAktif,
                    activeThumbColor: Colors.white,
                    activeTrackColor: const Color(0xFF22C55E),
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
    final bodyContent = ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 32),
      children: [
        // 0. HEADER SCROLLABLE PENGATURAN USAHA ALA MOCKUP (Seamless Edge-to-Edge)
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 4, 0, 16),
          child: Row(
            children: [
              if (!widget.isTab) ...[
                DjajanBackButton(
                  onPressed: () => Navigator.maybePop(context),
                ),
                const SizedBox(width: 8),
              ],
              const Expanded(
                child: UmkmHeaderRow(
                  padding: EdgeInsets.zero,
                  iconBadge: UmkmSquircleIcon(
                    icon: Icons.settings_rounded,
                  ),
                  title: 'Pengaturan Usaha',
                  subtitle: 'Atur profil, operasional dan pembayaran',
                ),
              ),
            ],
          ),
        ),

        // 1. Hero Card: Profil & Status Toko Terintegrasi
        _buildHeroCard(profile),
        const SizedBox(height: 16),

        // 2. Section Operasional & Pengiriman
        _sectionCardHeader(
          icon: Icons.local_shipping_outlined,
          title: 'Operasional & Pengiriman',
          subtitle: 'Atur lokasi, metode pengambilan, dan pengantaran',
          isExpanded: _expandOperasional,
          onTap: () => setState(() => _expandOperasional = !_expandOperasional),
        ),
        if (_expandOperasional)
          _groupedCardBox(
            children: [
              // Card Preview Lokasi Dapur
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7FAF7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2EBE2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: OC.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Lokasi Dapur',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: OC.ink,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2.5,
                                ),
                                decoration: BoxDecoration(
                                  color: hasLocation
                                      ? const Color(0xFFE8F5E9)
                                      : const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      hasLocation
                                          ? Icons.check_rounded
                                          : Icons.info_outline_rounded,
                                      size: 11,
                                      color: hasLocation
                                          ? const Color(0xFF15803D)
                                          : const Color(0xFFB45309),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      hasLocation ? 'Tersimpan' : 'Belum Ada',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: hasLocation
                                            ? const Color(0xFF15803D)
                                            : const Color(0xFFB45309),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            profile.alamat.isNotEmpty
                                ? profile.alamat
                                : 'Belum mengatur titik koordinat dan alamat dapur.',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: OC.muted,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: _pilihLokasiUMKM,
                            borderRadius: BorderRadius.circular(8),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Ubah Lokasi',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: OC.primary,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 14,
                                    color: OC.primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _switchRow(
                icon: Icons.shopping_bag_outlined,
                title: 'Ambil di Tempat',
                subtitle: 'Pelanggan mengambil pesanan di dapur',
                value: _pickupAktif,
                onChanged: (v) => setState(() => _pickupAktif = v),
              ),
              const Divider(height: 1, color: Color(0xFFF1F3F1)),
              _switchRow(
                icon: Icons.two_wheeler_rounded,
                title: 'Pengantaran',
                subtitle: 'Antar pesanan ke alamat pembeli',
                value: _kurirAktif,
                onChanged: (v) => setState(() => _kurirAktif = v),
              ),
              if (_kurirAktif) ...[
                const Divider(height: 1, color: Color(0xFFF1F3F1)),
                _actionRow(
                  icon: Icons.alt_route_rounded,
                  title: 'Tarif & Jangkauan Pengantaran',
                  subtitle: _deskripsiSkemaOngkir,
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4.5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 140),
                          child: Text(
                            _labelSkemaOngkir,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: OC.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 15,
                          color: OC.primary,
                        ),
                      ],
                    ),
                  ),
                  onTap: _pilihSkemaOngkir,
                ),
              ],
            ],
          ),

        // 3. Section Pembayaran & Pre-Order
        _sectionCardHeader(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Pembayaran & Pre-order',
          subtitle: 'Atur metode pembayaran dan uang muka',
          isExpanded: _expandPembayaran,
          onTap: () => setState(() => _expandPembayaran = !_expandPembayaran),
        ),
        if (_expandPembayaran)
          _groupedCardBox(
            children: [
              _switchRow(
                icon: Icons.payments_outlined,
                title: 'Bayar di Tempat (COD)',
                subtitle: 'Pelanggan membayar tunai saat pesanan tiba',
                value: _codAktif,
                onChanged: (v) => setState(() => _codAktif = v),
              ),
              const Divider(height: 1, color: Color(0xFFF1F3F1)),
              _actionRow(
                icon: Icons.percent_rounded,
                title: 'Uang Muka Pre-order',
                subtitle: 'Atur persentase uang muka pesanan',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F5F0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _labelSkemaPO(_skemaPO),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: OC.ink,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: OC.muted,
                      ),
                    ],
                  ),
                ),
                onTap: _pilihSkemaPO,
              ),
              const SizedBox(height: 8),
              // Tips edukasi lampu kuning
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFEF3C7)),
                ),
                child: const Row(
                  children: [
                    Text('💡', style: TextStyle(fontSize: 14)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Uang muka membantu mengurangi pembatalan pesanan.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF92400E),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

        // 4. Section Akun & Keamanan
        _sectionCardHeader(
          icon: Icons.security_rounded,
          title: 'Akun & Keamanan',
          subtitle: 'Kelola keamanan akun dan akses',
          isExpanded: _expandAkun,
          onTap: () => setState(() => _expandAkun = !_expandAkun),
        ),
        if (_expandAkun)
          _groupedCardBox(
            children: [
              _actionRow(
                icon: Icons.lock_outline_rounded,
                title: 'Ubah Kata Sandi',
                subtitle: 'Perbarui kata sandi akun',
                onTap: _ubahPassword,
              ),
              const Divider(height: 1, color: Color(0xFFF1F3F1)),
              _actionRow(
                icon: Icons.person_outline_rounded,
                title: 'Beralih ke Akun Pelanggan',
                subtitle: 'Belanja sebagai pembeli',
                onTap: _switchToCustomer,
              ),
              const Divider(height: 1, color: Color(0xFFF1F3F1)),
              _actionRow(
                icon: Icons.logout_rounded,
                iconColor: const Color(0xFFDC2626),
                iconBg: const Color(0xFFFEF2F2),
                title: 'Keluar Akun UMKM',
                subtitle: 'Akhiri sesi login perangkat ini',
                textColor: const Color(0xFFDC2626),
                onTap: _confirmLogout,
              ),
            ],
          ),

        // 5. Footer Informasi Versi Aplikasi & Status
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: OC.muted,
              ),
              const SizedBox(width: 5),
              const Text(
                'Versi Aplikasi 1.0.0',
                style: TextStyle(
                  fontSize: 11,
                  color: OC.muted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _adaPerubahan
                        ? Icons.pending_outlined
                        : Icons.check_circle_rounded,
                    size: 13,
                    color: _adaPerubahan
                        ? const Color(0xFFD97706)
                        : const Color(0xFF16A34A),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _adaPerubahan
                        ? 'Ada perubahan belum disimpan'
                        : 'Semua perubahan tersimpan',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _adaPerubahan
                          ? const Color(0xFFD97706)
                          : const Color(0xFF16A34A),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );

    if (widget.isTab) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            Expanded(child: bodyContent),
            _buildSaveBar(compact: true),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F3),
      body: Stack(
        children: [
          const HeaderBotanicalBackdrop(height: 250),
          SafeArea(
            child: Column(
              children: [
                Expanded(child: bodyContent),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildSaveBar(compact: false),
    );
  }
}
