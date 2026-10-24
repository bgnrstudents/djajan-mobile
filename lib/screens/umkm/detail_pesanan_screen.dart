import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/umkm_models.dart';
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
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: DjajanPageHeader(
            title: 'Detail Pesanan',
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.maybePop(context),
            ),
          ),
        ),
        body: const TampilanKosong(
          ikon: Icons.receipt_long_outlined,
          judul: 'Pesanan Tidak Ditemukan',
          pesan: 'Data pesanan mungkin sudah dihapus dari database.',
        ),
      );
    }

    final tanggalFmt = DateFormat("d MMM yyyy, HH:mm 'WIB'", 'id_ID');
    final sudahDiputuskan = !pesanan.belumDiputuskan;
    final sisa = pesanan.sisaWaktuKonfirmasi;

    return Scaffold(
      backgroundColor: OC.bg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: DjajanPageHeader(
          title: 'Detail Pesanan',
          subtitle: '#${pesanan.idPesanan}',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
      ),
      body: AbsorbPointer(
        absorbing: _memproses,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pesanan #${pesanan.idPesanan}', style: OT.pageTitle),
                      Text(
                          'Diajukan ${tanggalFmt.format(pesanan.tanggalPesan)}',
                          style: OT.caption),
                    ],
                  ),
                ),
                _badgeStatus(pesanan.status),
              ],
            ),
            const SizedBox(height: 14),

            // --------------- countdown konfirmasi ---------------
            if (!sudahDiputuskan)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: sisa == Duration.zero
                      ? OC.dangerSoft
                      : OC.box,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                          color: Color(0xFF6B4A16), shape: BoxShape.circle),
                      child: const Icon(Icons.hourglass_bottom,
                          color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Konfirmasi Ketersediaan Dapur',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          if (sisa == Duration.zero)
                            const Text(
                              'Batas waktu konfirmasi sudah lewat. Segera putuskan agar pelanggan tidak menunggu.',
                              style: TextStyle(
                                  fontSize: 13, color: AppColors.danger),
                            )
                          else
                            RichText(
                              text: TextSpan(
                                style: OT.body,
                                children: [
                                  const TextSpan(text: 'Tersisa '),
                                  TextSpan(
                                    text: _formatDurasi(sisa),
                                    style: OT.caption
                                        .copyWith(color: OC.danger, fontWeight: FontWeight.w800),
                                  ),
                                  const TextSpan(
                                      text:
                                          ' sebelum pesanan otomatis dialihkan ke mitra UMKM terdekat lain.'),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // --------------- data pembeli ---------------
            KartuPutih(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: OC.mintSoft,
                        child: Text(
                          _inisial(pesanan.namaPembeli),
                          style: const TextStyle(
                              color: OC.primary,
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(pesanan.namaPembeli,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 15)),
                            Text(pesanan.noTelp, style: OT.caption),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: OC.primary,
                          minimumSize: const Size(0, 38),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              title: const Text('Hubungi Pelanggan'),
                              content: Text(
                                  'Silakan hubungi ${pesanan.namaPembeli} melalui WhatsApp di nomor ${pesanan.noTelp}.'),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Tutup')),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.chat_bubble_outline, size: 16),
                        label: const Text('Hubungi'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (pesanan.waktuDibutuhkan != null)
                    _barisInfo(
                      Icons.event_available,
                      'WAKTU DIBUTUHKAN',
                      tanggalFmt.format(pesanan.waktuDibutuhkan!),
                      extra: _selisihHari(pesanan.waktuDibutuhkan!),
                    ),
                  const SizedBox(height: 10),
                  _barisInfo(Icons.celebration_outlined, 'KEPERLUAN ACARA',
                      pesanan.keperluanAcara),
                  const SizedBox(height: 10),
                  _barisInfo(Icons.local_shipping_outlined, 'METODE PENGIRIMAN',
                      pesanan.metodePengiriman,
                      extra: pesanan.alamatTujuan),
                  const SizedBox(height: 10),
                  _barisInfo(Icons.payments_outlined, 'PEMBAYARAN',
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
                  color: OC.box,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.edit_note,
                            color: OC.amber, size: 18),
                        SizedBox(width: 6),
                        Text('CATATAN KHUSUS PEMESAN',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: OC.amber)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('"${pesanan.catatan}"',
                        style: const TextStyle(fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // --------------- rincian menu & tagihan ---------------
            KartuPutih(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.receipt_long_outlined,
                          color: OC.primary),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text('Rincian Menu & Tagihan',
                            style: TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 16)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  for (final item in pesanan.items) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GambarJaringan(
                            url: item.gambarUrl,
                            width: 56,
                            height: 56,
                            radius: 10),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.namaProduk,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                              Text(
                                  '${item.jumlah} ${item.satuan} × ${formatRupiah(item.hargaSatuan)}',
                                  style: const TextStyle(
                                      color: AppColors.textGrey,
                                      fontSize: 12.5)),
                            ],
                          ),
                        ),
                        Text(formatRupiah(item.subtotal),
                            style:
                                const TextStyle(fontWeight: FontWeight.w800)),
                      ],
                    ),
                    const Divider(height: 24),
                  ],
                  _barisRincian(
                      'Subtotal Pesanan (${pesanan.totalPorsi} Porsi)',
                      formatRupiah(pesanan.subtotal)),
                  _barisRincian('Biaya Pengantaran Kurir Warga',
                      formatRupiah(pesanan.biayaPengantaran)),
                  _barisRincian('Biaya Layanan Koperasi',
                      formatRupiah(pesanan.biayaLayanan),
                      badge: 'Subsidi Desa'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: OC.box,
                        borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text('TOTAL DITERIMA MITRA',
                              style: TextStyle(
                                  fontSize: 10.5,
                                  color: AppColors.textGrey,
                                  fontWeight: FontWeight.w700)),
                        ),
                        Text(formatRupiah(pesanan.totalDiterimaMitra),
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: AppColors.hijauTua)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (!sudahDiputuskan)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _komitmenDicentang
                        ? AppColors.hijauMuda
                        : AppColors.garis,
                    width: _komitmenDicentang ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: _komitmenDicentang,
                      activeColor: AppColors.hijauTua,
                      onChanged: (v) =>
                          setState(() => _komitmenDicentang = v ?? false),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Komitmen Kesediaan Dapur',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                          Text(
                            'Saya menyatakan sanggup menyiapkan ${pesanan.totalPorsi} porsi lengkap sesuai instruksi'
                            '${pesanan.waktuDibutuhkan != null ? ' tepat waktu pada ${DateFormat("d MMMM yyyy", 'id_ID').format(pesanan.waktuDibutuhkan!)}' : ''}.',
                            style: const TextStyle(
                                color: AppColors.textGrey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: pesanan.status == StatusPesanan.ditolak
                      ? AppColors.dangerBg
                      : AppColors.chipGreenBg,
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
                          : AppColors.hijauTua,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        switch (pesanan.status) {
                          StatusPesanan.diterima =>
                            'Pesanan ini sudah Anda terima dan masuk jadwal dapur.',
                          StatusPesanan.selesai =>
                            'Pesanan ini telah selesai dikerjakan.',
                          StatusPesanan.ditolak => 'Pesanan ini telah ditolak.',
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
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.hijauTua,
                  side: const BorderSide(color: AppColors.hijauTua),
                  minimumSize: const Size.fromHeight(50),
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

  Widget _badgeStatus(StatusPesanan status) {
    final (bg, fg, ikon) = switch (status) {
      StatusPesanan.poBaru => (
          OC.peach,
          OC.amber,
          Icons.schedule
        ),
      StatusPesanan.diterima => (
          OC.mint,
          OC.mintText,
          Icons.check_circle
        ),
      StatusPesanan.selesai => (
          OC.mintSoft,
          OC.primary,
          Icons.task_alt
        ),
      StatusPesanan.ditolak => (
          OC.dangerSoft,
          OC.danger,
          Icons.cancel
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ikon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(status.label,
              style: TextStyle(
                  color: fg, fontSize: 11.5, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
