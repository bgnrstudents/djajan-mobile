import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/umkm_seller_models.dart';
import '../../services/api_service.dart';
import '../../services/umkm_data_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import '../customer/order/order_widgets.dart';

/// HALAMAN 5 — Detail Pesanan.
/// Menampilkan isi tabel `pesanan` + `detail_pesanan`. Tombol Terima/Tolak
/// benar-benar mengubah kolom `status_pesanan` di database, dan saat pesanan
/// diterima stok produk otomatis dikurangi oleh server.
class DetailPesananScreen extends StatefulWidget {
  final String idPesanan;
  const DetailPesananScreen({super.key, required this.idPesanan});

  @override
  State<DetailPesananScreen> createState() => _DetailPesananScreenState();
}

class _DetailPesananScreenState extends State<DetailPesananScreen> {
  Timer? _timer;
  bool _komitmenDicentang = false;
  bool _memproses = false;

  @override
  void initState() {
    super.initState();
    // Hitung mundur berdasarkan kolom `batas_konfirmasi` di database.
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDurasi(Duration d) {
    final j = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return j > 0 ? '$j jam $m:$s menit' : '$m:$s menit';
  }

  Future<void> _terima(Pesanan p) async {
    if (!_komitmenDicentang) {
      pesanGagal(
          context, 'Centang "Komitmen Kesediaan Dapur" terlebih dahulu.');
      return;
    }
    setState(() => _memproses = true);
    try {
      final pesan =
          await context.read<UmkmDataService>().terimaPesanan(p.idPesanan);
      if (!mounted) return;
      pesanSukses(context, pesan);
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (mounted) pesanGagal(context, e.pesan);
    } finally {
      if (mounted) setState(() => _memproses = false);
    }
  }

  Future<void> _tolak(Pesanan p) async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Tolak Pesanan?'),
        content: Text(
            'Pesanan ${p.idPesanan} akan dialihkan ke mitra UMKM terdekat lain. Yakin ingin menolak?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                minimumSize: const Size(110, 44)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Tolak'),
          ),
        ],
      ),
    );
    if (yakin != true) return;
    if (!mounted) return;

    setState(() => _memproses = true);
    final nav = Navigator.of(context);
    try {
      final pesan =
          await context.read<UmkmDataService>().tolakPesanan(p.idPesanan);
      if (!mounted) return;
      pesanSukses(context, pesan);
      nav.pop();
    } on ApiException catch (e) {
      if (mounted) pesanGagal(context, e.pesan);
    } finally {
      if (mounted) setState(() => _memproses = false);
    }
  }

  Future<void> _selesaikan(Pesanan p) async {
    setState(() => _memproses = true);
    try {
      final service = context.read<UmkmDataService>();
      final pesan = await service.selesaikanPesanan(p.idPesanan);
      if (!mounted) return;
      pesanSukses(context, pesan);
    } on ApiException catch (e) {
      if (mounted) pesanGagal(context, e.pesan);
    } finally {
      if (mounted) setState(() => _memproses = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<UmkmDataService>();
    final pesanan = service.cariPesanan(widget.idPesanan);

    if (pesanan == null) {
      return Scaffold(
        backgroundColor: OC.bg,
        body: SafeArea(
          child: Column(
            children: [
              DjajanPageHeader(
                title: 'Detail Pesanan',
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: OC.muted),
                  onPressed: () => Navigator.maybePop(context),
                ),
              ),
              const Expanded(
                child: TampilanKosong(
                  ikon: Icons.receipt_long_outlined,
                  judul: 'Pesanan Tidak Ditemukan',
                  pesan: 'Data pesanan mungkin sudah dihapus dari database.',
                ),
              ),
            ],
          ),
        ),
      );
    }

    final tanggalFmt = DateFormat("d MMM yyyy, HH:mm 'WIB'", 'id_ID');
    final sudahDiputuskan = !pesanan.belumDiputuskan;
    final sisa = pesanan.sisaWaktuKonfirmasi;

    return Scaffold(
      backgroundColor: OC.bg,
      body: SafeArea(
        child: Column(
          children: [
            DjajanPageHeader(
              title: 'Detail Pesanan',
              subtitle: '#${pesanan.idPesanan}',
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: OC.muted),
                onPressed: () => Navigator.maybePop(context),
              ),
            ),
            Expanded(
              child: AbsorbPointer(
                absorbing: _memproses,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
                  children: [
            // --------------- HERO STATUS BANNER ---------------
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: pesanan.status == StatusPesanan.poBaru
                    ? (sisa == Duration.zero ? OC.dangerSoft : OC.peachSoft)
                    : (pesanan.status == StatusPesanan.ditolak
                        ? AppColors.dangerBg
                        : OC.mintSoft),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: pesanan.status == StatusPesanan.poBaru
                      ? (sisa == Duration.zero ? OC.danger : OC.peach)
                      : (pesanan.status == StatusPesanan.ditolak
                          ? AppColors.danger.withValues(alpha: 0.3)
                          : OC.mint),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: pesanan.status == StatusPesanan.poBaru
                          ? (sisa == Duration.zero ? OC.danger : OC.accent)
                          : (pesanan.status == StatusPesanan.ditolak
                              ? AppColors.danger
                              : OC.primary),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      pesanan.status == StatusPesanan.poBaru
                          ? Icons.hourglass_top_rounded
                          : (pesanan.status == StatusPesanan.ditolak
                              ? Icons.cancel_outlined
                              : Icons.check_circle_rounded),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              pesanan.status.label,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: pesanan.status == StatusPesanan.poBaru
                                    ? OC.amber
                                    : (pesanan.status == StatusPesanan.ditolak
                                        ? AppColors.danger
                                        : OC.primary),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              tanggalFmt.format(pesanan.tanggalPesan),
                              style: const TextStyle(
                                  fontSize: 11, color: OC.muted),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        if (pesanan.status == StatusPesanan.poBaru)
                          Text(
                            sisa == Duration.zero
                                ? 'Batas waktu konfirmasi lewat! Putuskan sekarang.'
                                : 'Sisa ${_formatDurasi(sisa)} sebelum dialihkan ke mitra lain.',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: sisa == Duration.zero
                                  ? OC.danger
                                  : OC.amber,
                            ),
                          )
                        else
                          Text(
                            switch (pesanan.status) {
                              StatusPesanan.diterima =>
                                'Pesanan masuk antrean dapur Anda.',
                              StatusPesanan.selesai =>
                                'Pesanan telah selesai & dana diteruskan.',
                              StatusPesanan.ditolak =>
                                'Pesanan telah Anda tolak.',
                              _ => '',
                            },
                            style: const TextStyle(
                                fontSize: 12.5, color: OC.muted),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // --------------- DATA PEMBELI & PENGIRIMAN ---------------
            KartuPutih(
              radius: 16,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: OC.box,
                          shape: BoxShape.circle,
                          border: Border.all(color: OC.line),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _inisial(pesanan.namaPembeli),
                          style: const TextStyle(
                            color: OC.primary,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pesanan.namaPembeli,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: OC.ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(pesanan.noTelp,
                                style: const TextStyle(
                                    fontSize: 12.5, color: OC.muted)),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize: const Size(0, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              title: const Text('Hubungi Pelanggan'),
                              content: Text(
                                  'Nomor WhatsApp ${pesanan.namaPembeli}: ${pesanan.noTelp}.\n\nSilakan konfirmasi pesanan atau koordinasikan pengantaran langsung.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Tutup'),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.chat_bubble_outline, size: 15),
                        label: const Text('Chat WA',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  if (pesanan.waktuDibutuhkan != null) ...[
                    _barisInfo(
                      Icons.event_available_outlined,
                      'WAKTU DIBUTUHKAN',
                      tanggalFmt.format(pesanan.waktuDibutuhkan!),
                      extra: _selisihHari(pesanan.waktuDibutuhkan!),
                    ),
                    const SizedBox(height: 10),
                  ],
                  _barisInfo(Icons.celebration_outlined, 'KEPERLUAN ACARA',
                      pesanan.keperluanAcara),
                  const SizedBox(height: 10),
                  _barisInfo(Icons.local_shipping_outlined, 'METODE PENGIRIMAN',
                      pesanan.metodePengiriman,
                      extra: pesanan.alamatTujuan),
                  const SizedBox(height: 10),
                  _barisInfo(Icons.payments_outlined, 'METODE PEMBAYARAN',
                      pesanan.metodePembayaran,
                      extra: _labelStatusBayar(pesanan.statusPembayaran)),
                ],
              ),
            ),
            const SizedBox(height: 14),

            if (pesanan.catatan.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: OC.peachSoft,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: OC.peach),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.edit_note, color: OC.amber, size: 20),
                        SizedBox(width: 6),
                        Text(
                          'CATATAN KHUSUS DARI PEMBELI',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: OC.amber,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '"${pesanan.catatan}"',
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 13,
                        color: OC.ink,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // --------------- RINCIAN MENU & TAGIHAN ---------------
            KartuPutih(
              radius: 16,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.restaurant_menu_rounded,
                          color: OC.primary, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Rincian Menu Dipesan',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: OC.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  for (final item in pesanan.items) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: OC.line),
                          ),
                          child: GambarJaringan(
                            url: item.gambarUrl,
                            width: 54,
                            height: 54,
                            radius: 10,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.namaProduk,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                  color: OC.ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${item.jumlah} ${item.satuan} × ${formatRupiah(item.hargaSatuan)}',
                                style: const TextStyle(
                                    color: OC.muted, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          formatRupiah(item.subtotal),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                            color: OC.ink,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 22),
                  ],
                  _barisRincian(
                    'Subtotal Item (${pesanan.totalPorsi} Porsi)',
                    formatRupiah(pesanan.subtotal),
                  ),
                  _barisRincian(
                    'Biaya Pengantaran',
                    formatRupiah(pesanan.biayaPengantaran),
                  ),
                  _barisRincian(
                    'Biaya Layanan Koperasi',
                    formatRupiah(pesanan.biayaLayanan),
                    badge: 'Subsidi',
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: OC.mintSoft,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: OC.mint),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TOTAL DITERIMA MITRA',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: OC.mintText,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Dana bersih masuk saldo dompet',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: OC.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          formatRupiah(pesanan.totalDiterimaMitra),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: OC.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            if (!sudahDiputuskan)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _komitmenDicentang ? OC.primary : OC.line,
                    width: _komitmenDicentang ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: _komitmenDicentang,
                      activeColor: OC.primary,
                      onChanged: (v) =>
                          setState(() => _komitmenDicentang = v ?? false),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Komitmen Kesediaan Dapur',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: OC.ink,
                            ),
                          ),
                          Text(
                            'Saya sanggup menyiapkan ${pesanan.totalPorsi} porsi tepat waktu sesuai pesanan.',
                            style: const TextStyle(
                                color: OC.muted, fontSize: 11.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            if (sudahDiputuskan)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: pesanan.status == StatusPesanan.ditolak
                      ? AppColors.dangerBg
                      : OC.mintSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(
                      pesanan.status == StatusPesanan.ditolak
                          ? Icons.cancel
                          : Icons.check_circle,
                      color: pesanan.status == StatusPesanan.ditolak
                          ? AppColors.danger
                          : OC.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        switch (pesanan.status) {
                          StatusPesanan.diterima =>
                            'Pesanan ini sudah Anda terima dan masuk antrean dapur.',
                          StatusPesanan.selesai =>
                            'Pesanan ini telah selesai dikerjakan.',
                          StatusPesanan.ditolak => 'Pesanan ini telah Anda tolak.',
                          StatusPesanan.poBaru => '',
                        },
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

            if (pesanan.status == StatusPesanan.diterima) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: OC.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed:
                    _memproses ? null : () => _selesaikan(pesanan),
                icon: const Icon(Icons.task_alt),
                label: const Text('Tandai Pesanan Selesai'),
              ),
            ],
          ],
        ),
      ),
    ),
  ],
),
),
      bottomNavigationBar: sudahDiputuskan
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          side: const BorderSide(color: AppColors.danger),
                          minimumSize: const Size.fromHeight(52),
                          backgroundColor: AppColors.dangerBg,
                        ),
                        onPressed: _memproses ? null : () => _tolak(pesanan),
                        icon: const Icon(Icons.close),
                        label: const Text('Tolak PO'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _memproses ? null : () => _terima(pesanan),
                        icon: _memproses
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.check_circle_outline),
                        label: Text(
                            _memproses ? 'Memproses...' : 'Terima Pesanan'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ------------------------------------------------------------ helper
  String _inisial(String nama) {
    final bagian =
        nama.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (bagian.isEmpty) return '?';
    return bagian.take(2).map((e) => e[0].toUpperCase()).join();
  }

  String _selisihHari(DateTime waktu) {
    final selisih = waktu.difference(DateTime.now()).inDays;
    if (selisih > 0) return 'Jadwal $selisih hari lagi (bahan aman terencana)';
    if (selisih == 0) return 'Dibutuhkan hari ini — siapkan segera';
    return 'Jadwal sudah lewat ${selisih.abs()} hari';
  }

  String _labelStatusBayar(String kode) => switch (kode) {
        'lunas' => 'Sudah lunas',
        'dp_terbayar' => 'DP sudah masuk',
        _ => 'Belum dibayar',
      };

  Widget _barisInfo(IconData ikon, String label, String nilai,
      {String? extra}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: OC.box,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(ikon, size: 18, color: AppColors.textGrey),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textGrey,
                        fontWeight: FontWeight.w700)),
                Text(nilai,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                if (extra != null && extra.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(extra,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.hijauTua)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _barisRincian(String label, String nilai, {String? badge}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                    child: Text(label,
                        style: const TextStyle(
                            color: OC.muted, fontSize: 13))),
                if (badge != null) ...[
                  const SizedBox(width: 6),
                  MiniBadge(badge,
                      bg: AppColors.chipGreenBg, fg: AppColors.hijauTua),
                ],
              ],
            ),
          ),
          Text(nilai, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
