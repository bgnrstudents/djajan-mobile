import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/umkm_seller_models.dart';
import '../../services/api_service.dart';
import '../../services/category_service.dart';
import '../../services/umkm_data_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/umkm_app_bar.dart';
import 'detail_pesanan_screen.dart';
import '../../screens/customer/order/order_widgets.dart';
import '../../widgets/umkm_bottom_navigation.dart';
import 'tambah_produk_screen.dart';
import 'pengaturan_screen.dart';

/// HALAMAN 2 — Dashboard UMKM.
/// Seluruh isi halaman ini dibaca langsung dari database MySQL
/// (produk, pesanan, dan ringkasan statistik).
class DashboardUmkmScreen extends StatefulWidget {
  const DashboardUmkmScreen({super.key});

  @override
  State<DashboardUmkmScreen> createState() => _DashboardUmkmScreenState();
}

class _DashboardUmkmScreenState extends State<DashboardUmkmScreen> {
  int _tab = 0;
  String _kataKunci = '';
  bool _pendapatanBulanan = true;

  @override
  void initState() {
    super.initState();
    // Muat data dari server segera setelah dashboard tampil.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UmkmDataService>().muatSemua();
    });
  }

  Future<void> _refresh() =>
      context.read<UmkmDataService>().muatSemua(tampilkanLoading: false);

  Future<void> _tambahProduk() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const TambahProdukScreen()));
    if (mounted) await _refresh();
  }

  Widget _buildDynamicHeader(UmkmProfile profile, UmkmDataService service) {
    switch (_tab) {
      case 0:
        return UmkmAppBar(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          leftWidget: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade200, width: 1.5),
                ),
                child: GambarJaringan(
                  url: profile.fotoProfilUrl,
                  width: 42,
                  height: 42,
                  radius: 21,
                  ikonKosong: Icons.storefront,
                  cacheBuster: DateTime.now().millisecondsSinceEpoch.toString(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      profile.namaUsaha,
                      style: const TextStyle(
                        fontSize: 17.5,
                        fontWeight: FontWeight.w700,
                        color: OC.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: profile.tokoAktif
                                ? const Color(0xFF10B981)
                                : Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            profile.tokoAktif
                                ? 'Buka • Siap Terima Pesanan'
                                : 'Tutup • Toko Libur',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: profile.tokoAktif
                                  ? const Color(0xFF047857)
                                  : OC.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          rightAction: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _switchToCustomer,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6.5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: OC.primary.withValues(alpha: 0.22)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.shopping_bag_outlined,
                      size: 14,
                      color: OC.primary,
                    ),
                    SizedBox(width: 4.5),
                    Text(
                      'Mode Belanja',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: OC.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      case 1:
        final totalProduk = service.produkList.length;
        final jumlahTayang = service.produkList
            .where((produk) => produk.tampilkanDiWarung)
            .length;
        final jumlahDraft = totalProduk - jumlahTayang;
        return UmkmAppBar(
          title: 'Katalog Produk',
          subtitle:
              '$totalProduk produk  ·  $jumlahTayang tayang  ·  $jumlahDraft draft',
          rightAction: FilledButton.icon(
            onPressed: _tambahProduk,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Tambah'),
            style: FilledButton.styleFrom(
              backgroundColor: OC.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
          ),
        );
      case 2:
        final jumlahPoBaru = service.pesananList
            .where((p) => p.status == StatusPesanan.poBaru)
            .length;
        return UmkmAppBar(
          title: 'Pesanan',
          subtitle: '${service.pesananList.length} pesanan masuk',
          showBottomBorder: false,
          rightAction: jumlahPoBaru > 0
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: OC.peachSoft,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFF1D8A8)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFD97706),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$jumlahPoBaru baru',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF8A5A00),
                        ),
                      ),
                    ],
                  ),
                )
              : null,
        );
      case 3:
      default:
        return UmkmAppBar(
          title: 'Pengaturan Usaha',
          subtitle: 'Profil dan operasional usaha',
          rightAction: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: profile.tokoAktif ? OC.mintSoft : OC.box,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: profile.tokoAktif
                        ? const Color(0xFF10B981)
                        : OC.faint,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  profile.tokoAktif ? 'Buka' : 'Tutup',
                  style: TextStyle(
                    color: profile.tokoAktif ? OC.primary : OC.muted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
    }
  }

  Future<void> _switchToCustomer() async {
    try {
      context.read<UmkmDataService>().clearState();
      final session = await context.read<AuthService>().switchToCustomer();
      if (!mounted) return;
      if (session.role != AuthRole.pelanggan) {
        throw ApiException('Mode pelanggan tidak berhasil diaktifkan.');
      }
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/customer/home', (_) => false);
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.pesan)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<UmkmDataService>();

    if (!service.sudahLogin) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final profile = service.profile;

    return Scaffold(
      backgroundColor: _tab == 1 ? const Color(0xFFF5F6F4) : OC.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildDynamicHeader(profile, service),
            Expanded(
              child:
                  service.memuat &&
                      service.produkList.isEmpty &&
                      service.pesananList.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : service.pesanError != null && service.produkList.isEmpty
                  ? TampilanError(
                      pesan: service.pesanError!,
                      onCobaLagi: () => service.muatSemua(),
                    )
                  : IndexedStack(
                      index: _tab,
                      children: [
                        _TabBeranda(
                          service: service,
                          onPindahTab: (i) => setState(() => _tab = i),
                          onRefresh: _refresh,
                          periodeBulanan: _pendapatanBulanan,
                          onPilihPeriodeBulanan: (value) =>
                              setState(() => _pendapatanBulanan = value),
                        ),
                        _TabProduk(
                          service: service,
                          kataKunci: _kataKunci,
                          onCari: (v) => setState(() => _kataKunci = v),
                          onRefresh: _refresh,
                        ),
                        _TabPesanan(service: service, onRefresh: _refresh),
                        const PengaturanScreen(isTab: true),
                      ],
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: UmkmBottomNavigation(
        currentIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        pesananBaru: service.jumlahPoBaru,
      ),
    );
  }
}

// ======================================================== TAB BERANDA ===
class _TabBeranda extends StatelessWidget {
  final UmkmDataService service;
  final ValueChanged<int> onPindahTab;
  final Future<void> Function() onRefresh;
  final bool periodeBulanan;
  final ValueChanged<bool> onPilihPeriodeBulanan;

  const _TabBeranda({
    required this.service,
    required this.onPindahTab,
    required this.onRefresh,
    required this.periodeBulanan,
    required this.onPilihPeriodeBulanan,
  });

  @override
  Widget build(BuildContext context) {
    final r = service.ringkasan;
    final pesananTerbaru = service.pesananList.take(3).toList();
    final semuaProduk = service.produkList;
    final totalPendapatan = periodeBulanan ? r.omzetPeriode : r.omzetDiterima;
    final jumlahPesananPendapatan = periodeBulanan
        ? r.totalPesananPeriode
        : r.pesananDiterima;
    final stokHabis = semuaProduk
        .where((p) => p.modePenjualan != ModePenjualan.preOrder && p.stok == 0)
        .length;

    return RefreshIndicator(
      color: OC.primary,
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 110),
        children: [
          // 1. TOTAL PENDAPATAN
          Container(
            clipBehavior: Clip.antiAlias,
            padding: const EdgeInsets.fromLTRB(19, 17, 19, 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF103D20),
                  Color(0xFF175D2B),
                  Color(0xFF287842),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF103D20).withValues(alpha: 0.2),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFC857),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'TOTAL PENDAPATAN',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    PopupMenuButton<bool>(
                      tooltip: 'Filter pendapatan',
                      initialValue: periodeBulanan,
                      onSelected: onPilihPeriodeBulanan,
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: true, child: Text('Bulan Ini')),
                        PopupMenuItem(value: false, child: Text('Semua Waktu')),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              periodeBulanan ? 'Bulan Ini' : 'Semua Waktu',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Colors.white,
                              size: 15,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 17),
                Text(
                  rupiah(totalPendapatan),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.16),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.receipt_long_outlined,
                            size: 14,
                            color: Color(0xFFD8EBDD),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '$jumlahPesananPendapatan pesanan',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        periodeBulanan
                            ? 'Omzet bersih periode ini'
                            : 'Akumulasi omzet bersih',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFD8EBDD),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 2. RINGKASAN USAHA
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text('Ringkasan Usaha', style: OT.cardTitle),
          ),
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _KartuRingkasanBeranda(
                      ikon: Icons.notifications_none_rounded,
                      nilai: '${r.pesananBaru}',
                      label: 'Perlu Konfirmasi',
                      warnaAksen: OC.amber,
                      onTap: () => onPindahTab(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _KartuRingkasanBeranda(
                      ikon: Icons.inventory_2_outlined,
                      nilai: '${r.pesananDiterima}',
                      label: 'Pesanan Diterima',
                      warnaAksen: OC.primary,
                      onTap: () => onPindahTab(2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _KartuRingkasanBeranda(
                      ikon: Icons.storefront_outlined,
                      nilai: '${r.produkTayang}',
                      label: 'Produk Tayang',
                      warnaAksen: OC.primary,
                      onTap: () => onPindahTab(1),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _KartuRingkasanBeranda(
                      ikon: Icons.remove_shopping_cart_outlined,
                      nilai: '${r.stokHabis}',
                      label: 'Stok Habis',
                      warnaAksen: OC.danger,
                      onTap: () => onPindahTab(1),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 3. PESANAN TERBARU
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Pesanan Terbaru', style: OT.cardTitle),
              TextButton(
                onPressed: () => onPindahTab(2),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF1B4332),
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Row(
                  children: [
                    Text(
                      'Lihat Semua',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 3),
                    Icon(Icons.arrow_forward_rounded, size: 14),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (pesananTerbaru.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Center(
                child: Column(
                  children: [
                    Icon(Icons.inbox_outlined, size: 32, color: OC.faint),
                    SizedBox(height: 7),
                    Text('Belum ada pesanan masuk', style: OT.secondary),
                  ],
                ),
              ),
            )
          else
            ...pesananTerbaru.map((p) {
              final itemUtama = p.items.isEmpty ? null : p.items.first;
              final ringkasanItem = itemUtama == null
                  ? '${p.totalPorsi} porsi'
                  : '${itemUtama.namaProduk} (${itemUtama.jumlah} porsi)';
              final isSelesai = p.status == StatusPesanan.selesai;
              final isBaru = p.status == StatusPesanan.poBaru;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            DetailPesananScreen(idPesanan: p.idPesanan),
                      ),
                    );
                    await onRefresh();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF1F5F2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.receipt_long_outlined,
                            size: 18,
                            color: Color(0xFF1B4332),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${p.namaPembeli} • $ringkasanItem',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: OC.ink,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${p.idPesanan} • ${DateFormat('dd MMM', 'id_ID').format(p.tanggalPesan)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: OC.faint,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              rupiah(p.totalDiterimaMitra),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: OC.ink,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: isBaru
                                    ? OC.peach
                                    : const Color(0xFFE7F3E9),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                p.status.label,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: isBaru
                                      ? OC.amber
                                      : isSelesai
                                      ? const Color(0xFF1B4332)
                                      : OC.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

          if (r.produkTerlaris.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Produk Terlaris', style: OT.cardTitle),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: r.produkTerlaris.take(3).map((produk) {
                  String? gambarUrl;
                  for (final item in semuaProduk) {
                    if (item.namaProduk == produk.namaProduk) {
                      gambarUrl = item.gambarUrl;
                      break;
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    child: Row(
                      children: [
                        GambarJaringan(
                          url: gambarUrl,
                          width: 42,
                          height: 42,
                          radius: 9,
                          ikonKosong: Icons.restaurant_rounded,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  produk.namaProduk,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: OC.ink,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.star_rounded,
                                size: 15,
                                color: OC.accent,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${produk.jumlahTerjual} terjual',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: OC.muted,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          const SizedBox(height: 18),

          // 4. PERINGATAN STOK HABIS
          if (stokHabis > 0) ...[
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => onPindahTab(1),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: OC.peachSoft,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: OC.amber,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Peringatan Stok Habis',
                            style: OT.item.copyWith(color: OC.amber),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$stokHabis produk butuh restock agar tetap tayang di etalase.',
                            style: OT.caption.copyWith(color: OC.amber),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: OC.amber),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

// TAB PRODUK
class _TabProduk extends StatefulWidget {
  final UmkmDataService service;
  final String kataKunci;
  final ValueChanged<String> onCari;
  final Future<void> Function() onRefresh;

  const _TabProduk({
    required this.service,
    required this.kataKunci,
    required this.onCari,
    required this.onRefresh,
  });

  @override
  State<_TabProduk> createState() => _TabProdukState();
}

class _TabProdukState extends State<_TabProduk> {
  String _kategoriDipilih = 'Semua';
  String _statusDipilih = 'Semua';
  late final TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController(text: widget.kataKunci);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final categoryService = context.read<CategoryService>();
      if (!categoryService.loading && categoryService.categories.isEmpty) {
        categoryService.load();
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _bukaFilter(List<String> kategori) async {
    var statusSementara = _statusDipilih;
    var kategoriSementara = _kategoriDipilih;

    final hasil = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          Widget pilihan({
            required String label,
            required int jumlah,
            required bool terpilih,
            required VoidCallback onTap,
          }) {
            return InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 11,
                ),
                child: Row(
                  children: [
                    Icon(
                      terpilih
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      size: 20,
                      color: terpilih ? OC.primary : OC.faint,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: terpilih ? OC.primary : OC.ink,
                          fontSize: 13,
                          fontWeight: terpilih
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      '$jumlah',
                      style: const TextStyle(
                        color: OC.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final status = [
            ('Semua status', 'Semua', widget.service.produkList.length),
            (
              'Tayang',
              'Tayang',
              widget.service.produkList
                  .where((produk) => produk.tampilkanDiWarung)
                  .length,
            ),
            (
              'Draft',
              'Draft',
              widget.service.produkList
                  .where((produk) => !produk.tampilkanDiWarung)
                  .length,
            ),
            (
              'Stok habis',
              'Stok habis',
              widget.service.produkList
                  .where(
                    (produk) =>
                        produk.modePenjualan != ModePenjualan.preOrder &&
                        produk.stok == 0,
                  )
                  .length,
            ),
          ];

          return SafeArea(
            top: false,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.82,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Filter produk',
                            style: OT.cardTitle.copyWith(fontSize: 18),
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
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      children: [
                        const Text('STATUS', style: OT.label),
                        const SizedBox(height: 6),
                        ...status.map(
                          (option) => pilihan(
                            label: option.$1,
                            jumlah: option.$3,
                            terpilih: statusSementara == option.$2,
                            onTap: () => setSheetState(
                              () => statusSementara = option.$2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text('KATEGORI', style: OT.label),
                        const SizedBox(height: 6),
                        ...kategori.map((nama) {
                          final jumlah = nama == 'Semua'
                              ? widget.service.produkList.length
                              : widget.service.produkList
                                    .where((produk) => produk.kategori == nama)
                                    .length;
                          return pilihan(
                            label: nama == 'Semua' ? 'Semua kategori' : nama,
                            jumlah: jumlah,
                            terpilih: kategoriSementara == nama,
                            onTap: () =>
                                setSheetState(() => kategoriSementara = nama),
                          );
                        }),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setSheetState(() {
                              statusSementara = 'Semua';
                              kategoriSementara = 'Semua';
                            }),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: OC.primary,
                              side: const BorderSide(color: OC.line),
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13),
                              ),
                            ),
                            child: const Text('Reset'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            onPressed: () => Navigator.pop(context, {
                              'status': statusSementara,
                              'kategori': kategoriSementara,
                            }),
                            style: FilledButton.styleFrom(
                              backgroundColor: OC.primary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13),
                              ),
                            ),
                            child: const Text('Terapkan filter'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (!mounted || hasil == null) return;
    setState(() {
      _statusDipilih = hasil['status'] ?? 'Semua';
      _kategoriDipilih = hasil['kategori'] ?? 'Semua';
    });
  }

  @override
  Widget build(BuildContext context) {
    final semua = widget.service.produkList;
    final categoryService = context.watch<CategoryService>();
    final kategoriDb = categoryService.categories
        .map((category) => category.name.trim())
        .where((name) => name.isNotEmpty);
    final kategoriLama = semua
        .map((produk) => produk.kategori.trim())
        .where((name) => name.isNotEmpty);
    final kategoriTersedia = <String>{...kategoriDb, ...kategoriLama};
    final kategoriTerurut = kategoriTersedia.toList()..sort();
    final listKategori = ['Semua', ...kategoriTerurut];
    final kategoriAktif = listKategori.contains(_kategoriDipilih)
        ? _kategoriDipilih
        : 'Semua';

    final jumlahStokHabis = semua
        .where((p) => p.modePenjualan != ModePenjualan.preOrder && p.stok == 0)
        .length;
    final jumlahFilterAktif =
        (kategoriAktif == 'Semua' ? 0 : 1) +
        (_statusDipilih == 'Semua' ? 0 : 1);

    // Filter berdasarkan kata kunci & kategori
    final produkList = semua.where((p) {
      final cocokKunci =
          widget.kataKunci.isEmpty ||
          p.namaProduk.toLowerCase().contains(widget.kataKunci.toLowerCase()) ||
          p.kategori.toLowerCase().contains(widget.kataKunci.toLowerCase());
      final cocokKategori =
          kategoriAktif == 'Semua' || p.kategori == kategoriAktif;
      final cocokStatus = switch (_statusDipilih) {
        'Tayang' => p.tampilkanDiWarung,
        'Draft' => !p.tampilkanDiWarung,
        'Stok habis' =>
          p.modePenjualan != ModePenjualan.preOrder && p.stok == 0,
        _ => true,
      };
      return cocokKunci && cocokKategori && cocokStatus;
    }).toList();

    // Pre-Order tidak punya stok, jadi tidak ikut dihitung sebagai "stok habis".
    return RefreshIndicator(
      color: OC.primary,
      onRefresh: widget.onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: OC.line),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: widget.onCari,
                    textInputAction: TextInputAction.search,
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      hintText: 'Cari produk...',
                      hintStyle: const TextStyle(color: OC.faint, fontSize: 13),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: OC.muted,
                        size: 21,
                      ),
                      suffixIcon: widget.kataKunci.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Hapus pencarian',
                              onPressed: () {
                                _searchCtrl.clear();
                                widget.onCari('');
                              },
                              icon: const Icon(Icons.close_rounded, size: 19),
                              color: OC.muted,
                            ),
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 100,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => _bukaFilter(listKategori),
                  icon: const Icon(Icons.tune_rounded, size: 18),
                  label: Text(
                    jumlahFilterAktif == 0
                        ? 'Filter'
                        : 'Filter $jumlahFilterAktif',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: jumlahFilterAktif > 0
                        ? OC.primary
                        : OC.ink,
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: jumlahFilterAktif > 0
                          ? OC.primary.withValues(alpha: 0.35)
                          : OC.line,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Daftar produk',
                  style: OT.cardTitle.copyWith(fontSize: 16),
                ),
              ),
              Text(
                '${produkList.length} hasil',
                style: OT.secondary.copyWith(fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (categoryService.errorMessage != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: OC.peachSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 17,
                    color: OC.amber,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Kategori belum dapat dimuat.',
                      style: TextStyle(color: OC.amber, fontSize: 11),
                    ),
                  ),
                  TextButton(
                    onPressed: categoryService.loading
                        ? null
                        : categoryService.load,
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: OC.primary,
                    ),
                    child: const Text('Coba lagi'),
                  ),
                ],
              ),
            ),
          ],
          if (jumlahStokHabis > 0 && _statusDipilih == 'Semua') ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: OC.peachSoft,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFF2E5CC)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: OC.amber,
                    size: 19,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      '$jumlahStokHabis produk stoknya habis',
                      style: const TextStyle(
                        color: OC.amber,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        setState(() => _statusDipilih = 'Stok habis'),
                    style: TextButton.styleFrom(
                      foregroundColor: OC.amber,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('Lihat'),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (produkList.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: TampilanKosong(
                ikon: Icons.inventory_2_outlined,
                judul:
                    widget.kataKunci.isEmpty &&
                        kategoriAktif == 'Semua' &&
                        _statusDipilih == 'Semua'
                    ? 'Belum Ada Produk'
                    : 'Produk Tidak Ditemukan',
                pesan:
                    widget.kataKunci.isEmpty &&
                        kategoriAktif == 'Semua' &&
                        _statusDipilih == 'Semua'
                    ? 'Tambahkan produk untuk mulai berjualan di Djajan.'
                    : 'Ubah pencarian atau filter untuk melihat produk lainnya.',
              ),
            )
          else
            ...produkList.map(
              (produk) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _KartuProduk(
                  produk: produk,
                  service: widget.service,
                  onRefresh: widget.onRefresh,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

IconData _ikonKategoriProduk(String kategori) {
  final nilai = kategori.toLowerCase();
  if (kategori == 'Semua') return Icons.grid_view_rounded;
  if (nilai.contains('makanan')) return Icons.restaurant_menu_rounded;
  if (nilai.contains('minuman')) return Icons.local_cafe_outlined;
  if (nilai.contains('camilan') || nilai.contains('snack')) {
    return Icons.cookie_outlined;
  }
  if (nilai.contains('kue') || nilai.contains('roti')) {
    return Icons.cake_outlined;
  }
  if (nilai.contains('sembako') ||
      nilai.contains('bahan pokok') ||
      nilai.contains('kelontong')) {
    return Icons.shopping_basket_outlined;
  }
  return Icons.category_outlined;
}

class _KartuRingkasanBeranda extends StatelessWidget {
  final IconData ikon;
  final String nilai;
  final String label;
  final Color warnaAksen;
  final VoidCallback onTap;

  const _KartuRingkasanBeranda({
    required this.ikon,
    required this.nilai,
    required this.label,
    required this.warnaAksen,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(17),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: OC.line),
          boxShadow: [
            BoxShadow(
              color: OC.ink.withValues(alpha: 0.025),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: warnaAksen.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(ikon, color: warnaAksen, size: 18),
                ),
                const Spacer(),
                Text(
                  nilai,
                  style: TextStyle(
                    color: warnaAksen,
                    fontWeight: FontWeight.w800,
                    fontSize: 26,
                    height: 1,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                height: 1.2,
                fontWeight: FontWeight.w600,
                color: OC.muted,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _KartuProduk extends StatefulWidget {
  final Produk produk;
  final UmkmDataService service;
  final Future<void> Function() onRefresh;

  const _KartuProduk({
    required this.produk,
    required this.service,
    required this.onRefresh,
  });

  @override
  State<_KartuProduk> createState() => _KartuProdukState();
}

class _KartuProdukState extends State<_KartuProduk> {
  bool _sibuk = false;

  Future<void> _jalankan(Future<void> Function() aksi) async {
    setState(() => _sibuk = true);
    try {
      await aksi();
    } on ApiException catch (e) {
      if (mounted) pesanGagal(context, e.pesan);
    } finally {
      if (mounted) setState(() => _sibuk = false);
    }
  }

  void _dialogUbahStok() {
    int stokSementara = widget.produk.stok;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Atur Stok Produk',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.produk.namaProduk,
                style: const TextStyle(fontSize: 13, color: OC.muted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filledTonal(
                    onPressed: stokSementara > 0
                        ? () => setDialogState(() => stokSementara--)
                        : null,
                    icon: const Icon(Icons.remove_rounded),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: OC.box,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      '$stokSementara',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: () => setDialogState(() => stokSementara++),
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: OC.primary),
              onPressed: () async {
                Navigator.pop(ctx);
                await _jalankan(
                  () => widget.service.ubahStok(widget.produk, stokSementara),
                );
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _konfirmasiHapus() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Produk?'),
        content: Text('"${widget.produk.namaProduk}" akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              minimumSize: const Size(110, 44),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await _jalankan(() async {
                final pesan = await widget.service.hapusProduk(widget.produk);
                if (mounted) pesanSukses(context, pesan);
              });
            },
            child: const Text('Ya, Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.produk;
    final modeLabel = switch (p.modePenjualan) {
      ModePenjualan.ready => 'READY',
      ModePenjualan.preOrder => 'PRE-ORDER',
      ModePenjualan.keduanya => 'READY + PO',
    };
    final statusColor = p.tampilkanDiWarung ? OC.primary : OC.muted;
    final warnaStok = p.stok == 0
        ? OC.danger
        : p.stok <= 10
        ? OC.amber
        : OC.primary;
    final latarStok = p.stok == 0
        ? OC.dangerSoft
        : p.stok <= 10
        ? const Color(0xFFFFF4D6)
        : OC.primarySoft;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: OC.line),
        boxShadow: [
          BoxShadow(
            color: OC.primary.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: _sibuk ? 0.55 : 1,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => tampilkanZoomGambarJaringan(context, p.gambarUrl),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GambarJaringan(
                  url: p.gambarUrl,
                  width: 82,
                  height: 96,
                  radius: 12,
                  ikonKosong: _ikonKategoriProduk(p.kategori),
                  cacheBuster: DateTime.now().millisecondsSinceEpoch.toString(),
                ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          p.namaProduk,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: OC.ink,
                            height: 1.25,
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      SizedBox(
                        width: 30,
                        height: 30,
                        child: PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.more_horiz_rounded,
                            size: 20,
                            color: OC.muted,
                          ),
                          tooltip: 'Aksi produk',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          onSelected: (val) async {
                            if (val == 'edit') {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      TambahProdukScreen(produkToEdit: p),
                                ),
                              );
                              if (mounted) widget.onRefresh();
                            } else if (val == 'stok') {
                              _dialogUbahStok();
                            } else if (val == 'hapus') {
                              _konfirmasiHapus();
                            }
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                    color: OC.ink,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Edit Produk',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            if (p.modePenjualan != ModePenjualan.preOrder)
                              const PopupMenuItem(
                                value: 'stok',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.inventory_2_outlined,
                                      size: 18,
                                      color: OC.ink,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Ubah Stok',
                                      style: TextStyle(fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            const PopupMenuItem(
                              value: 'hapus',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                    color: AppColors.danger,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Hapus Produk',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.danger,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${p.kategori.isEmpty ? 'Tanpa kategori' : p.kategori} · $modeLabel',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: OC.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (p.modePenjualan != ModePenjualan.preOrder) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: latarStok,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            p.stok == 0 ? 'Habis' : 'Stok ${p.stok}',
                            maxLines: 1,
                            style: TextStyle(
                              color: warnaStok,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Text(
                        rupiah(p.harga),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: OC.primary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        p.tampilkanDiWarung
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 15,
                        color: statusColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        p.tampilkanDiWarung ? 'Tayang' : 'Draft',
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 3),
                      SizedBox(
                        height: 28,
                        child: Switch.adaptive(
                          value: p.tampilkanDiWarung,
                          activeThumbColor: OC.primary,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          onChanged: _sibuk
                              ? null
                              : (v) => _jalankan(
                                  () => widget.service.ubahStatusTayang(p, v),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================= TAB PESANAN ===
class _TabPesanan extends StatefulWidget {
  final UmkmDataService service;
  final Future<void> Function() onRefresh;

  const _TabPesanan({required this.service, required this.onRefresh});

  @override
  State<_TabPesanan> createState() => _TabPesananState();
}

class _TabPesananState extends State<_TabPesanan> {
  String _statusDipilih = 'semua';

  String _labelStatus(String kode) {
    if (kode == 'semua') return 'Semua status';
    return StatusPesanan.values
        .firstWhere((status) => status.kodeDb == kode)
        .label;
  }

  Future<void> _bukaFilter(Map<String, int> jumlahPerStatus) async {
    var statusSementara = _statusDipilih;
    final pilihanStatus = [
      ('semua', 'Semua status', widget.service.pesananList.length),
      ...StatusPesanan.values.map(
        (status) =>
            (status.kodeDb, status.label, jumlahPerStatus[status.kodeDb] ?? 0),
      ),
    ];

    final hasil = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          Widget pilihan({
            required String kode,
            required String label,
            required int jumlah,
          }) {
            final terpilih = statusSementara == kode;
            return InkWell(
              onTap: () => setSheetState(() => statusSementara = kode),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 11,
                ),
                child: Row(
                  children: [
                    Icon(
                      terpilih
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      size: 20,
                      color: terpilih ? OC.primary : OC.faint,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: terpilih ? OC.primary : OC.ink,
                          fontSize: 13,
                          fontWeight: terpilih
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      '$jumlah',
                      style: const TextStyle(
                        color: OC.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return SafeArea(
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
                    padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Filter pesanan',
                            style: OT.cardTitle.copyWith(fontSize: 18),
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
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 10, bottom: 4),
                          child: Text('STATUS PESANAN', style: OT.label),
                        ),
                        ...pilihanStatus.map(
                          (option) => pilihan(
                            kode: option.$1,
                            label: option.$2,
                            jumlah: option.$3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                setSheetState(() => statusSementara = 'semua'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: OC.primary,
                              side: const BorderSide(color: OC.line),
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13),
                              ),
                            ),
                            child: const Text('Reset'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            onPressed: () =>
                                Navigator.pop(context, statusSementara),
                            style: FilledButton.styleFrom(
                              backgroundColor: OC.primary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13),
                              ),
                            ),
                            child: const Text('Terapkan filter'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (!mounted || hasil == null) return;
    setState(() => _statusDipilih = hasil);
  }

  @override
  Widget build(BuildContext context) {
    final semua = widget.service.pesananList;
    final tanggalFmt = DateFormat('d MMM yyyy, HH:mm', 'id_ID');

    final jumlahPerStatus = {
      for (final status in StatusPesanan.values)
        status.kodeDb: semua.where((p) => p.status == status).length,
    };
    final pesananTersaring = _statusDipilih == 'semua'
        ? semua
        : semua
              .where((pesanan) => pesanan.status.kodeDb == _statusDipilih)
              .toList();

    return RefreshIndicator(
      color: OC.primary,
      onRefresh: widget.onRefresh,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: OutlinedButton(
              onPressed: () => _bukaFilter(jumlahPerStatus),
              style: OutlinedButton.styleFrom(
                foregroundColor: OC.ink,
                backgroundColor: Colors.white,
                side: const BorderSide(color: OC.line),
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 11,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.tune_rounded, size: 18, color: OC.primary),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      '${_labelStatus(_statusDipilih)}  ·  ${pesananTersaring.length} pesanan',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: OC.muted,
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: pesananTersaring.isEmpty
                ? ListView(
                    padding: const EdgeInsets.only(top: 60),
                    children: [
                      TampilanKosong(
                        ikon: Icons.receipt_long_outlined,
                        judul: 'Tidak Ada Pesanan',
                        pesan: 'Belum ada pesanan di kategori ini.',
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
                    itemCount: pesananTersaring.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final p = pesananTersaring[i];
                      final (bg, fg) = _warnaStatus(p.status);

                      return InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  DetailPesananScreen(idPesanan: p.idPesanan),
                            ),
                          );
                          await widget.onRefresh();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header Kartu: ID Pesanan & Badge Status Visual Jenis Pesanan
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: OC.box,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '#${p.idPesanan}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: OC.ink,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Badge visual jenis pesanan (Ready / PO) disematkan langsung di card
                                  if (p.isPreOrder)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF3E0),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: const Color(0xFFFFB74D),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.cake_outlined,
                                            size: 11,
                                            color: Color(0xFFE65100),
                                          ),
                                          SizedBox(width: 3),
                                          Text(
                                            'Pre-Order',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFFE65100),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  else
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8F5E9),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: const Color(0xFFA5D6A7),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.bolt_rounded,
                                            size: 11,
                                            color: Color(0xFF2E7D32),
                                          ),
                                          SizedBox(width: 3),
                                          Text(
                                            'Ready',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF2E7D32),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  const Spacer(),
                                  MiniBadge(p.status.label, bg: bg, fg: fg),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Body Kartu: Nama pembeli & item preview
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (p.items.isNotEmpty &&
                                      p.items.first.gambarUrl != null &&
                                      p.items.first.gambarUrl!.isNotEmpty)
                                    Container(
                                      margin: const EdgeInsets.only(right: 12),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: Colors.grey.shade200,
                                        ),
                                      ),
                                      child: GambarJaringan(
                                        url: p.items.first.gambarUrl!,
                                        width: 50,
                                        height: 50,
                                        radius: 10,
                                        cacheBuster: DateTime.now()
                                            .millisecondsSinceEpoch
                                            .toString(),
                                      ),
                                    )
                                  else
                                    Container(
                                      width: 50,
                                      height: 50,
                                      margin: const EdgeInsets.only(right: 12),
                                      decoration: BoxDecoration(
                                        color: OC.box,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: Colors.grey.shade200,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.fastfood_outlined,
                                        color: OC.muted,
                                        size: 22,
                                      ),
                                    ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p.namaPembeli,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: OC.ink,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          p.items.isNotEmpty
                                              ? '${p.items.first.namaProduk}${p.items.length > 1 ? ' (+${p.items.length - 1} menu lainnya)' : ''}'
                                              : 'Pesanan UMKM (${p.totalPorsi} porsi)',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: OC.muted,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          '${p.totalPorsi} porsi total',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        if (p.isPreOrder &&
                                            p.waktuDibutuhkan != null) ...[
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.event_available_outlined,
                                                size: 13,
                                                color: Color(0xFFE65100),
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  'Acara: ${tanggalFmt.format(p.waktuDibutuhkan!)}',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                    color: Color(0xFFE65100),
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 18),

                              // Footer Kartu: Total pendapatan & status countdown/tanggal
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Pendapatan Bersih',
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            color: OC.muted,
                                          ),
                                        ),
                                        Text(
                                          formatRupiah(p.totalDiterimaMitra),
                                          style: const TextStyle(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w800,
                                            color: OC.primary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (p.status == StatusPesanan.poBaru)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: OC.peachSoft,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.timer_outlined,
                                            size: 13,
                                            color: OC.amber,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            p.isPreOrder
                                                ? 'Konfirmasi 24 Jam'
                                                : 'Konfirmasi 30 Mnt',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: OC.amber,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  else
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          tanggalFmt.format(p.tanggalPesan),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: OC.muted,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.chevron_right,
                                          size: 16,
                                          color: OC.muted,
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  (Color, Color) _warnaStatus(StatusPesanan s) => switch (s) {
    StatusPesanan.poBaru => (OC.peach, OC.amber),
    StatusPesanan.diterima => (OC.mint, OC.primary),
    StatusPesanan.diproses => (OC.banner, OC.mintText),
    StatusPesanan.diantar => (OC.banner, OC.mintText),
    StatusPesanan.selesai => (OC.mint, OC.primary),
    StatusPesanan.ditolak => (AppColors.dangerBg, AppColors.danger),
  };
}
