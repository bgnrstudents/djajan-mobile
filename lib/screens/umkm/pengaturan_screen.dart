import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/umkm_models.dart';
import '../../services/api_service.dart';
import '../../services/umkm_data_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import '../customer/order/order_widgets.dart';

/// Satu baris form zona ongkir yang sedang diedit di layar ini.
/// "Mulai" tidak disimpan di sini karena selalu dihitung otomatis dari
/// radius gratis / batas akhir zona sebelumnya (supaya tidak mungkin ada
/// celah atau tumpang tindih jarak antar zona).
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

/// HALAMAN 4 — Pengaturan Usaha.
/// Foto profil diunggah ke server, dan seluruh toggle/rekening/ongkir
/// disimpan ke tabel `umkm` di MySQL.
class PengaturanScreen extends StatefulWidget {
  final bool isTab;
  const PengaturanScreen({super.key, this.isTab = false});

  @override
  State<PengaturanScreen> createState() => _PengaturanScreenState();
}

class _PengaturanScreenState extends State<PengaturanScreen> {
  late bool _tokoAktif;
  late bool _transferAktif;
  late bool _codAktif;
  late String _skemaPO;
  late bool _pickupAktif;
  late bool _kurirAktif;

  // --- Lokasi dapur & ongkir berbasis zona jarak ---
  // Koordinat lokasi hardcode ke "Desa Kreongan Atas, Jember" (-8.156515, 113.712613)
  final String _kreonganLat = '-8.156515';
  final String _kreonganLon = '113.712613';

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
    _transferAktif = p.transferBankAktif;
    _codAktif = p.codAktif;
    _skemaPO = _skemaOptions.contains(p.skemaPO) ? p.skemaPO : _skemaOptions.first;
    _pickupAktif = p.pickupAktif;
    _kurirAktif = p.kurirWargaAktif;

    _radiusCtrl = TextEditingController(text: _fmtKm(p.radiusGratisKm));
    for (final z in p.zonaOngkir) {
      _zonaBaris.add(
          _ZonaBaris(sampai: _fmtKm(z.jarakMax), tarif: z.biaya.toString()));
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

  // ------------------------------------------------ ganti foto profil
  Future<void> _gantiFoto() async {
    final file = await pilihGambar(context);
    if (file == null) return;
    if (!mounted) return;

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

  // ------------------------------------------------ ubah identitas usaha
  Future<void> _editIdentitas() async {
    final service = context.read<UmkmDataService>();
    final p = service.profile;
    final namaCtrl = TextEditingController(text: p.namaUsaha);
    final spesialisCtrl = TextEditingController(text: p.spesialis);
    final alamatCtrl = TextEditingController(text: p.alamat);
    final telpCtrl = TextEditingController(text: p.noTelpUsaha);

    final simpan = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Ubah Identitas Usaha'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: namaCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nama Usaha'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: spesialisCtrl,
                decoration: const InputDecoration(labelText: 'Spesialis / Slogan'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: alamatCtrl,
                decoration: const InputDecoration(labelText: 'Alamat Dapur'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: telpCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Nomor WhatsApp Usaha'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(110, 44)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
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
        alamat: alamatCtrl.text.trim(),
        noTelpUsaha: telpCtrl.text.trim(),
      );
      if (mounted) pesanSukses(context, pesan);
    } on ApiException catch (e) {
      if (mounted) pesanGagal(context, e.pesan);
    }
  }

  // ---------------------------------------------------- ubah rekening
  Future<void> _editRekening() async {
    final service = context.read<UmkmDataService>();
    final p = service.profile;
    final bankKodeCtrl = TextEditingController(text: p.bankKode);
    final bankNamaCtrl = TextEditingController(text: p.bankNama);
    final noRekCtrl = TextEditingController(text: p.noRekening);
    final atasNamaCtrl = TextEditingController(text: p.atasNama);

    final simpan = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Ubah Rekening Bank'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: bankKodeCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(labelText: 'Kode Bank (mis. BRI)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bankNamaCtrl,
                decoration: const InputDecoration(labelText: 'Nama Bank Lengkap'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noRekCtrl,
                decoration: const InputDecoration(labelText: 'Nomor Rekening'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: atasNamaCtrl,
                decoration: const InputDecoration(labelText: 'Atas Nama'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(110, 44)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (simpan != true) return;

    try {
      final pesan = await service.simpanRekening(
        bankKode: bankKodeCtrl.text.trim().toUpperCase(),
        bankNama: bankNamaCtrl.text.trim(),
        noRekening: noRekCtrl.text.trim(),
        atasNama: atasNamaCtrl.text.trim(),
      );
      if (mounted) pesanSukses(context, pesan);
    } on ApiException catch (e) {
      if (mounted) pesanGagal(context, e.pesan);
    }
  }

  // ---------------------------------------------------- simpan pengaturan
  Future<void> _simpanPengaturan() async {
    FocusScope.of(context).unfocus();

    // Lokasi pengantaran tetap berada di Desa Kreongan Atas, Jember.
    final radiusGratis = double.tryParse(_radiusCtrl.text.replaceAll(',', '.'));
    if (radiusGratis == null || radiusGratis < 0) {
      if (mounted) pesanGagal(context, 'Radius gratis ongkir harus berupa angka dan tidak boleh negatif.');
      return;
    }

    final List<ZonaOngkir> zonaBaru = [];
    double batas = radiusGratis;
    for (var i = 0; i < _zonaBaris.length; i++) {
      final sampai =
          double.tryParse(_zonaBaris[i].sampaiCtrl.text.replaceAll(',', '.'));
      final tarif = int.tryParse(_zonaBaris[i].tarifCtrl.text);
      if (sampai == null || tarif == null) {
        if (mounted) pesanGagal(context, 'Isi jarak & tarif zona ke-${i + 1} dengan angka yang benar.');
        return;
      }
      if (sampai <= batas) {
        if (mounted) pesanGagal(context, 'Jarak akhir zona ke-${i + 1} harus lebih besar dari ${_fmtKm(batas)} KM (batas zona sebelumnya).');
        return;
      }
      if (tarif < 0) {
        if (mounted) pesanGagal(context, 'Tarif zona ke-${i + 1} tidak boleh negatif.');
        return;
      }
      zonaBaru.add(ZonaOngkir(jarakMin: batas, jarakMax: sampai, biaya: tarif));
      batas = sampai;
    }
    // Jarak maksimal pengantaran otomatis = akhir zona terakhir (atau sama
    // dengan radius gratis kalau UMKM tidak membuat zona berbayar sama sekali).
    final jarakMaksimal = batas;

    setState(() => _menyimpan = true);
    try {
      final service = context.read<UmkmDataService>();

      final pesan = await service.simpanPengaturan(
        tokoAktif: _tokoAktif,
        transferBankAktif: _transferAktif,
        codAktif: _codAktif,
        skemaPO: _skemaPO,
        pickupAktif: _pickupAktif,
        kurirWargaAktif: _kurirAktif,
        // Tarif flat lama tidak lagi diedit lewat layar ini (digantikan zona
        // ongkir), nilainya tetap dikirim apa adanya supaya kolom lama di
        // database tidak berubah tanpa sengaja.
        biayaPengantaran: service.profile.biayaPengantaran,
      );

      await service.simpanOngkir(
        latitude: double.parse(_kreonganLat),
        longitude: double.parse(_kreonganLon),
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

  Widget _judulSeksi(IconData ikon, String judul, String subjudul) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: OC.box, borderRadius: BorderRadius.circular(10)),
          child: Icon(ikon, color: OC.primary, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(judul,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16.5)),
              Text(subjudul,
                  style: const TextStyle(
                      color: OC.muted, fontSize: 12.5)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _toggleTile({
    required String judul,
    String? badge,
    required String subjudul,
    required bool nilai,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OC.line),
      ),
      child: Row(
        children: [
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
                            color: OC.ink),
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 6),
                      MiniBadge(badge, bg: OC.peach, fg: OC.amber),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
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

  // ------------------------------------------------ kartu ongkir berzona
  Widget _kartuOngkirZona() {
    // Jarak maksimal pengantaran SELALA mengikuti akhir zona terakhir (atau
    // radius gratis kalau belum ada zona sama sekali) — lihat poin 12 & 33:
    // supaya tidak mungkin ada rentang jarak yang "kelewati" tanpa tarif.
    final radiusGratis =
        double.tryParse(_radiusCtrl.text.replaceAll(',', '.')) ?? 0;
    final jarakMaksimal = _zonaBaris.isEmpty
        ? radiusGratis
        : (double.tryParse(
                _zonaBaris.last.sampaiCtrl.text.replaceAll(',', '.')) ??
            radiusGratis);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: const Row(
              children: [
                Icon(Icons.location_on_outlined,
                    size: 18, color: OC.primary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Lokasi pengantara: Desa Kreongan Atas, Jember. Ongkir dihitung otomatis dari alamat pembeli.',
                    style: TextStyle(fontSize: 11.5, color: OC.muted),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 26),

          // ---------- Jarak maksimal (otomatis) ----------
          Row(
            children: [
              const Expanded(
                child: Text('Jarak Maksimal Pengantaran',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10)),
                child: Text('${_fmtKm(jarakMaksimal)} KM',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, color: OC.primary)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Otomatis mengikuti batas akhir zona ongkir terakhir. Pelanggan di luar jarak '
            'ini akan melihat "di luar jangkauan pengantaran".',
            style: TextStyle(color: OC.muted, fontSize: 11.5),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------ helper
  // Widget _barisForm dihapus karena tidak digunakan

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<UmkmDataService>().profile;

    final bodyContent = ListView(
      padding: EdgeInsets.fromLTRB(16, widget.isTab ? 8 : 4, 16, widget.isTab ? 110 : 30),
      children: [
        // ==================== PROFIL USAHA + FOTO ====================
        KartuPutih(
            child: Column(
              children: [
                Row(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        GambarJaringan(
                          url: profile.fotoProfilUrl,
                          width: 72,
                          height: 72,
                          radius: 36,
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
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.photo_camera,
                                    size: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(profile.namaUsaha,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 17)),
                          const SizedBox(height: 4),
                          if (profile.terverifikasi)
                            const MiniBadge('Mitra Terverifikasi',
                                bg: OC.mint,
                                fg: OC.primary,
                                ikon: Icons.verified)
                          else
                            const MiniBadge('Menunggu Verifikasi',
                                bg: OC.peach,
                                fg: OC.amber),
                          const SizedBox(height: 4),
                          Text(profile.spesialis,
                              style: const TextStyle(
                                  color: OC.muted, fontSize: 12.5)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _editIdentitas,
                      icon: const Icon(Icons.edit_outlined,
                          color: OC.primary),
                      tooltip: 'Ubah identitas usaha',
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Status Toko',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                          Text(
                              'Matikan bila dapur sedang libur / tidak menerima pesanan',
                              style: TextStyle(
                                  color: OC.muted, fontSize: 12)),
                        ],
                      ),
                    ),
                    Switch(
                      value: _tokoAktif,
                      activeThumbColor: OC.primary,
                      onChanged: (v) => setState(() => _tokoAktif = v),
                    ),
                  ],
                ),
                if (profile.alamat.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.place_outlined,
                          size: 16, color: OC.muted),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(profile.alamat,
                            style: const TextStyle(
                                fontSize: 12.5, color: OC.muted)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // =================== KEBIJAKAN PEMBAYARAN ===================
          _judulSeksi(
              Icons.account_balance_wallet_outlined,
              'Kebijakan Pembayaran',
              'Atur metode terima uang dari pelanggan warga'),
          const SizedBox(height: 10),
          _toggleTile(
            judul: 'Transfer Bank Manual',
            badge: 'Utama',
            subjudul:
                'Pelanggan mengunggah bukti transfer ke rekening mitra',
            nilai: _transferAktif,
            onChanged: (v) => setState(() => _transferAktif = v),
          ),
          if (_transferAktif) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: OC.box,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6)),
                        child: Text(profile.bankKode,
                            style: const TextStyle(
                                color: OC.primary,
                                fontWeight: FontWeight.w800)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Bank ${profile.bankKode}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            Text(profile.bankNama,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: OC.muted, fontSize: 12)),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _editRekening,
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        tooltip: 'Ubah rekening',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('NOMOR REKENING',
                            style: TextStyle(
                                fontSize: 10.5,
                                color: OC.muted,
                                fontWeight: FontWeight.w700)),
                        Text(
                          profile.noRekening.isEmpty
                              ? 'Belum diisi'
                              : profile.noRekening,
                          style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text.rich(TextSpan(children: [
                    const TextSpan(
                        text: 'Atas Nama (A.N): ',
                        style: TextStyle(
                            color: OC.muted, fontSize: 12.5)),
                    TextSpan(
                        text: profile.atasNama.isEmpty ? '-' : profile.atasNama,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 12.5)),
                  ])),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          _toggleTile(
            judul: 'COD (Bayar di Tempat)',
            subjudul:
                'Titip uang tunai ke kurir warga desa saat pesanan sampai',
            nilai: _codAktif,
            onChanged: (v) => setState(() => _codAktif = v),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.garis),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Skema Pembayaran Pre-Order (PO)',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const Text(
                    'Aturan uang muka saat warga pesan katering atau tumpeng porsi besar',
                    style: TextStyle(color: OC.muted, fontSize: 12.5)),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _skemaPO,
                  isExpanded: true,
                  items: _skemaOptions
                      .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s, overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (v) => setState(() => _skemaPO = v!),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: OC.box,
                      borderRadius: BorderRadius.circular(10)),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 16, color: OC.muted),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Pesanan otomatis masuk jadwal dapur setelah DP terverifikasi',
                          style: TextStyle(
                              fontSize: 12, color: OC.muted),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // ================== LAYANAN & ONGKIR ==================
          _judulSeksi(
              Icons.local_shipping_outlined,
              'Layanan & Ongkir Pengiriman',
              'Kelola cara pengambilan & jangkauan kurir lokal'),
          const SizedBox(height: 10),
          _toggleTile(
            judul: 'Pickup / Ambil Sendiri di Dapur',
            subjudul:
                'Pelanggan mengambil langsung ke alamat dapur Anda',
            nilai: _pickupAktif,
            onChanged: (v) => setState(() => _pickupAktif = v),
          ),
          const SizedBox(height: 10),
          _toggleTile(
            judul: 'Diantar UMKM / Kurir Warga',
            subjudul:
                'Pengantaran mandiri atau bantuan pemuda karang taruna sekitar',
            nilai: _kurirAktif,
            onChanged: (v) => setState(() => _kurirAktif = v),
          ),
          if (_kurirAktif) ...[
            const SizedBox(height: 10),
            _kartuOngkirZona(),
          ],
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, color: OC.primary),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Semua perubahan disimpan ke database dan langsung sinkron ke halaman etalase pembeli.',
                    style: TextStyle(fontSize: 12.5, color: OC.muted),
                  ),
                ),
              ],
            ),
          ),
          if (widget.isTab) ...[
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _menyimpan ? null : _simpanPengaturan,
              icon: _menyimpan
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: Text(_menyimpan ? 'Menyimpan...' : 'Simpan Pengaturan'),
            ),
          ],
        ],
      );

    if (widget.isTab) {
      return Scaffold(
        backgroundColor: OC.bg,
        body: bodyContent,
      );
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
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.check_circle_outline),
            label: Text(_menyimpan ? 'Menyimpan...' : 'Simpan Pengaturan'),
          ),
        ),
      ),
    );
  }
}