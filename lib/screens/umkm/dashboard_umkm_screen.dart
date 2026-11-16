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

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F3),
      body: Stack(
        children: [
          // 1. Decorative Botanical Leaf Gradient Header (ala referensi mockup)
          const HeaderBotanicalBackdrop(height: 250),

          // 2. Main Content (Scrollable dengan Header di dalam masing-masing tab)
          SafeArea(
            child: service.memuat &&
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
                        onPindahCustomer: _switchToCustomer,
                      ),
                      _TabProduk(
                        service: service,
                        kataKunci: _kataKunci,
                        onCari: (v) => setState(() => _kataKunci = v),
                        onRefresh: _refresh,
                        onTambah: _tambahProduk,
                      ),
                      _TabPesanan(service: service, onRefresh: _refresh),
                      const PengaturanScreen(isTab: true),
                    ],
                  ),
          ),
        ],
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
  final VoidCallback onPindahCustomer;

  const _TabBeranda({
    required this.service,
    required this.onPindahTab,
    required this.onRefresh,
    required this.periodeBulanan,
    required this.onPilihPeriodeBulanan,
    required this.onPindahCustomer,
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
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 110),
        children: [
          // 0. HEADER BERANDA ALA MOCKUP (Seamless Edge-to-Edge)
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 4, 0, 16),
            child: Row(
              children: [
                SizedBox(
                  width: 44,
                  height: 44,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFD8EBD8),
                            width: 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: service.profile.fotoProfilUrl != null &&
                                  service.profile.fotoProfilUrl!.isNotEmpty
                              ? GambarJaringan(
                                  url: service.profile.fotoProfilUrl,
                                  width: 44,
                                  height: 44,
                                  radius: 13,
                                  ikonKosong: Icons.storefront_rounded,
                                )
                              : const Center(
                                  child: Icon(
                                    Icons.storefront_rounded,
                                    size: 24,
                                    color: Color(0xFF047857),
                                  ),
                                ),
                        ),
                      ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.check_rounded,
                              size: 10,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(width: 1.2, height: 26, color: const Color(0xFFD6E2D6)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              service.profile.namaUsaha,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w800,
                                color: OC.ink,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: OC.ink,
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: service.profile.tokoAktif
                                  ? const Color(0xFF10B981)
                                  : Colors.grey.shade400,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              service.profile.tokoAktif
                                  ? 'Buka · Siap Terima Pesanan'
                                  : 'Tutup · Toko Libur',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: service.profile.tokoAktif
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
                const SizedBox(width: 10),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onPindahCustomer,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFD3E7D3)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F2E1B).withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.shopping_bag_outlined,
                            size: 14,
                            color: Color(0xFF047857),
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Mode Belanja',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF047857),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

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
            const SizedBox(height: 14),
            const Text('Produk Terlaris', style: OT.cardTitle),
            const SizedBox(height: 10),
            ...r.produkTerlaris.take(3).map((produk) {
              String? gambarUrl;
              for (final item in semuaProduk) {
                if (item.namaProduk == produk.namaProduk) {
                  gambarUrl = item.gambarUrl;
                  break;
                }
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2EBE2), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F2E1B).withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    GambarJaringan(
                      url: gambarUrl,
                      width: 48,
                      height: 48,
                      radius: 12,
                      ikonKosong: Icons.restaurant_rounded,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  produk.namaProduk,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: OC.ink,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.star_rounded,
                                size: 16,
                                color: Color(0xFFF59E0B),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${produk.jumlahTerjual} terjual',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: OC.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.local_fire_department_rounded,
                            size: 13,
                            color: Color(0xFFD97706),
                          ),
                          SizedBox(width: 3),
                          Text(
                            'Terlaris',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFD97706),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
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
  final Future<void> Function() onTambah;

  const _TabProduk({
    required this.service,
    required this.kataKunci,
    required this.onCari,
    required this.onRefresh,
    required this.onTambah,
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
              borderRadius: BorderRadius.circular(14),
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

    final jumlahTayang = semua
        .where((produk) => produk.tampilkanDiWarung)
        .length;
    final jumlahDraft = semua.length - jumlahTayang;
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

    final statistik = [
      (
        label: 'Total Produk',
        nilai: semua.length,
        ikon: Icons.inventory_2_outlined,
        warna: OC.primary,
        aktif:
            _statusDipilih == 'Semua' &&
            kategoriAktif == 'Semua' &&
            widget.kataKunci.isEmpty,
        status: 'Semua',
      ),
      (
        label: 'Tayang',
        nilai: jumlahTayang,
        ikon: Icons.visibility_outlined,
        warna: const Color(0xFF16A34A),
        aktif: _statusDipilih == 'Tayang',
        status: 'Tayang',
      ),
      (
        label: 'Draft',
        nilai: jumlahDraft,
        ikon: Icons.edit_note_rounded,
        warna: OC.muted,
        aktif: _statusDipilih == 'Draft',
        status: 'Draft',
      ),
    ];

    void pilihStatistik(String status) {
      setState(() {
        _kategoriDipilih = 'Semua';
        _statusDipilih = status;
        if (_searchCtrl.text.isNotEmpty) {
          _searchCtrl.clear();
          widget.onCari('');
        }
      });
    }

    Widget buatStatistik(int index) {
      final item = statistik[index];
      return Expanded(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => pilihStatistik(item.status),
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                color: item.aktif ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                boxShadow: item.aktif
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2EBE2)),
                      ),
                      child: Icon(
                        item.ikon,
                        color: item.warna,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${item.nilai}',
                            style: const TextStyle(
                              color: OC.ink,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: OC.muted,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Pre-Order tidak punya stok, jadi tidak ikut dihitung sebagai "stok habis".
    return RefreshIndicator(
      color: OC.primary,
      onRefresh: widget.onRefresh,
      child: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 170),
            children: [
              // 0. HEADER SCROLLABLE KATALOG PRODUK ALA MOCKUP (Seamless Edge-to-Edge)
              const UmkmHeaderRow(
                padding: EdgeInsets.fromLTRB(0, 4, 0, 16),
                iconBadge: UmkmSquircleIcon(
                  icon: Icons.inventory_2_rounded,
                ),
                title: 'Katalog Produk',
                subtitle: 'Kelola produk dan stok jualanmu',
              ),

              // 1. STATISTIK SUMMARY CARD (3 Kolom ala referensi)
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDF4ED),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFDFEADF)),
                ),
                child: Row(
                  children: [
                    buatStatistik(0),
                    Container(width: 1, height: 36, color: const Color(0xFFD6E2D6)),
                    buatStatistik(1),
                    Container(width: 1, height: 36, color: const Color(0xFFD6E2D6)),
                    buatStatistik(2),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 2. SEARCH BAR + FILTER BUTTON
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: OC.line),
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: widget.onCari,
                        textInputAction: TextInputAction.search,
                        textAlignVertical: TextAlignVertical.center,
                        decoration: InputDecoration(
                          hintText: 'Cari nama produk...',
                          hintStyle: const TextStyle(
                            color: OC.faint,
                            fontSize: 13,
                          ),
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
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    size: 19,
                                  ),
                                  color: OC.muted,
                                ),
                          isDense: true,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: () => _bukaFilter(listKategori),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: jumlahFilterAktif > 0
                              ? OC.primary
                              : OC.line,
                          width: jumlahFilterAktif > 0 ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            size: 18,
                            color: jumlahFilterAktif > 0
                                ? OC.primary
                                : OC.ink,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            jumlahFilterAktif == 0
                                ? 'Filter'
                                : 'Filter ($jumlahFilterAktif)',
                            style: TextStyle(
                              color: jumlahFilterAktif > 0
                                  ? OC.primary
                                  : OC.ink,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 3. CATEGORY PILLS BAR (Semua, Kategori dinamis, Draft)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    ...listKategori.map((kategori) {
                      final terpilih =
                          _statusDipilih != 'Draft' &&
                          kategoriAktif == kategori;
                      final iconData = _ikonKategoriProduk(kategori);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _statusDipilih = 'Semua';
                              _kategoriDipilih = kategori;
                            });
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: terpilih ? OC.primary : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: terpilih
                                    ? OC.primary
                                    : const Color(0xFFE2EBE2),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  iconData,
                                  size: 16,
                                  color: terpilih ? Colors.white : OC.ink,
                                ),
                                const SizedBox(width: 7),
                                Text(
                                  kategori,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: terpilih
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    color: terpilih ? Colors.white : OC.ink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    // Pill Tambahan: Draft
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _statusDipilih =
                                _statusDipilih == 'Draft' ? 'Semua' : 'Draft';
                          });
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: _statusDipilih == 'Draft'
                                ? OC.primary
                                : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _statusDipilih == 'Draft'
                                  ? OC.primary
                                  : const Color(0xFFE2EBE2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.edit_note_rounded,
                                size: 18,
                                color: _statusDipilih == 'Draft'
                                    ? Colors.white
                                    : OC.ink,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Draft ($jumlahDraft)',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: _statusDipilih == 'Draft'
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  color: _statusDipilih == 'Draft'
                                      ? Colors.white
                                      : OC.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              if (categoryService.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
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
                const SizedBox(height: 10),
              ],

              if (jumlahStokHabis > 0 && _statusDipilih == 'Semua') ...[
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
                const SizedBox(height: 12),
              ],

              // 4. LIST PRODUK
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
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _KartuProduk(
                      produk: produk,
                      service: widget.service,
                      onRefresh: widget.onRefresh,
                    ),
                  ),
                ),
            ],
          ),

          // 5. BANNER CTA "TAMBAH PRODUK BARU" (Sticky di Bawah)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(22),
              elevation: 4,
              shadowColor: OC.primary.withValues(alpha: 0.3),
              child: InkWell(
                onTap: widget.onTambah,
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF135B38), Color(0xFF1C7A4D)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.shopping_bag_outlined,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Tambah Produk Baru',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Mulai jualan dengan produk baru',
                              style: TextStyle(
                                color: Color(0xFFD4EED8),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: OC.primary,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
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
    final statusColor = p.tampilkanDiWarung ? OC.primary : OC.muted;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEBEFEB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: _sibuk ? 0.55 : 1,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FOTO PRODUK SQUARE DENGAN BADGE STATUS READY / PO
            GestureDetector(
              onTap: () => tampilkanZoomGambarJaringan(context, p.gambarUrl),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: GambarJaringan(
                      url: p.gambarUrl,
                      width: 104,
                      height: 104,
                      radius: 16,
                      ikonKosong: _ikonKategoriProduk(p.kategori),
                      cacheBuster:
                          DateTime.now().millisecondsSinceEpoch.toString(),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6.5,
                            height: 6.5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: p.modePenjualan == ModePenjualan.ready
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFFF59E0B),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            p.modePenjualan == ModePenjualan.ready
                                ? 'Ready'
                                : 'Pre-Order',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: p.modePenjualan == ModePenjualan.ready
                                  ? const Color(0xFF15803D)
                                  : const Color(0xFFB45309),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // DETAIL KONTEN TENGAH & AKSI
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // NAMA PRODUK & TOMBOL MEATBALL 3-TITIK
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          p.namaProduk,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: OC.ink,
                            height: 1.25,
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.more_vert_rounded,
                            size: 20,
                            color: OC.muted,
                          ),
                          tooltip: 'Menu aksi produk',
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
                  const SizedBox(height: 2),

                  // HARGA PRODUK
                  Text(
                    rupiah(p.harga),
                    style: const TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w900,
                      color: OC.primary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // BADGE CHIPS KATEGORI & STOK / MODE
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3.5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFDCFCE7)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _ikonKategoriProduk(p.kategori),
                              size: 12,
                              color: const Color(0xFF16A34A),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              p.kategori.isEmpty ? 'Umum' : p.kategori,
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF15803D),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (p.modePenjualan == ModePenjualan.preOrder)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFFEF3C7)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                size: 12,
                                color: Color(0xFFD97706),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Pre-Order',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),

                  // INFO STOK & SWITCH TOGGLE TAYANG (Pojok Kanan Bawah)
                  Row(
                    children: [
                      if (p.modePenjualan != ModePenjualan.preOrder)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.inventory_2_outlined,
                              size: 14,
                              color: OC.muted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              p.stok == 0 ? 'Stok 0' : 'Stok ${p.stok}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: p.stok == 0
                                    ? OC.danger
                                    : OC.muted,
                              ),
                            ),
                          ],
                        )
                      else
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.shopping_bag_outlined,
                              size: 14,
                              color: OC.muted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Min. ${p.minOrderPO}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: OC.muted,
                              ),
                            ),
                          ],
                        ),
                      const Spacer(),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            p.tampilkanDiWarung
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 14,
                            color: statusColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            p.tampilkanDiWarung ? 'Tayang' : 'Draft',
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 4),
                          SizedBox(
                            width: 38,
                            height: 26,
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child: Switch.adaptive(
                                value: p.tampilkanDiWarung,
                                activeThumbColor: OC.primary,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                onChanged: _sibuk
                                    ? null
                                    : (v) => _jalankan(
                                        () => widget.service
                                            .ubahStatusTayang(p, v),
                                      ),
                              ),
                            ),
                          ),
                        ],
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
  String _kataKunci = '';
  String _filterJenis = 'semua'; // 'semua', 'ready', 'po'
  late final TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _bukaFilter(Map<String, int> jumlahPerStatus) async {
    var statusSementara = _statusDipilih;
    var jenisSementara = _filterJenis;

    final pilihanStatus = [
      ('semua', 'Semua status', widget.service.pesananList.length),
      ...StatusPesanan.values.map(
        (status) =>
            (status.kodeDb, status.label, jumlahPerStatus[status.kodeDb] ?? 0),
      ),
    ];

    final hasil = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          Widget pilihanRadio({
            required String label,
            required bool terpilih,
            required VoidCallback onTap,
            int? jumlah,
          }) {
            return InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
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
                    if (jumlah != null)
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
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.85,
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
                        const Expanded(
                          child: Text(
                            'Filter Pesanan',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: OC.ink,
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
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 10, bottom: 4),
                          child: Text('JENIS PESANAN', style: OT.label),
                        ),
                        pilihanRadio(
                          label: 'Semua Jenis',
                          terpilih: jenisSementara == 'semua',
                          onTap: () =>
                              setSheetState(() => jenisSementara = 'semua'),
                        ),
                        pilihanRadio(
                          label: '⚡ Pesanan Langsung (Ready)',
                          terpilih: jenisSementara == 'ready',
                          onTap: () =>
                              setSheetState(() => jenisSementara = 'ready'),
                        ),
                        pilihanRadio(
                          label: '🕐 Pre-Order (PO)',
                          terpilih: jenisSementara == 'po',
                          onTap: () =>
                              setSheetState(() => jenisSementara = 'po'),
                        ),
                        const SizedBox(height: 14),
                        const Padding(
                          padding: EdgeInsets.only(left: 10, bottom: 4),
                          child: Text('STATUS PESANAN', style: OT.label),
                        ),
                        ...pilihanStatus.map(
                          (opt) => pilihanRadio(
                            label: opt.$2,
                            terpilih: statusSementara == opt.$1,
                            jumlah: opt.$3,
                            onTap: () =>
                                setSheetState(() => statusSementara = opt.$1),
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
                            onPressed: () {
                              setSheetState(() {
                                statusSementara = 'semua';
                                jenisSementara = 'semua';
                              });
                            },
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
                              'jenis': jenisSementara,
                            }),
                            style: FilledButton.styleFrom(
                              backgroundColor: OC.primary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13),
                              ),
                            ),
                            child: const Text('Terapkan Filter'),
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
      _statusDipilih = hasil['status'] ?? 'semua';
      _filterJenis = hasil['jenis'] ?? 'semua';
    });
  }

  @override
  Widget build(BuildContext context) {
    final semua = widget.service.pesananList;
    final tanggalFmt = DateFormat('d MMM yyyy, HH:mm', 'id_ID');

    final jumlahPerStatus = {
      for (final status in StatusPesanan.values)
        status.kodeDb: semua.where((p) => p.status == status).length,
    };

    final jumlahPerluTindakan =
        semua.where((p) => p.status == StatusPesanan.poBaru).length;

    // Filter berdasarkan kata kunci, status tab/filter, dan jenis
    final pesananTersaring = semua.where((p) {
      final cocokKunci = _kataKunci.isEmpty ||
          p.idPesanan.toString().contains(_kataKunci) ||
          p.namaPembeli.toLowerCase().contains(_kataKunci.toLowerCase()) ||
          p.items.any((it) =>
              it.namaProduk.toLowerCase().contains(_kataKunci.toLowerCase()));

      final cocokStatus =
          _statusDipilih == 'semua' || p.status.kodeDb == _statusDipilih;

      final cocokJenis = switch (_filterJenis) {
        'ready' => !p.isPreOrder,
        'po' => p.isPreOrder,
        _ => true,
      };

      return cocokKunci && cocokStatus && cocokJenis;
    }).toList();

    // Grouping pesanan berdasarkan Tanggal (Hari)
    final Map<String, List<Pesanan>> pesananPerTanggal = {};
    for (final p in pesananTersaring) {
      final kunciTanggal = DateFormat('d MMMM yyyy', 'id_ID').format(p.tanggalPesan);
      pesananPerTanggal.putIfAbsent(kunciTanggal, () => []).add(p);
    }
    final listTanggal = pesananPerTanggal.keys.toList();

    // Daftar status untuk horizontal pills
    final statusTabs = [
      (kode: 'semua', label: 'Semua', count: semua.length),
      (
        kode: StatusPesanan.poBaru.kodeDb,
        label: 'Konfirmasi',
        count: jumlahPerStatus[StatusPesanan.poBaru.kodeDb] ?? 0,
      ),
      (
        kode: StatusPesanan.diterima.kodeDb,
        label: 'Diterima',
        count: jumlahPerStatus[StatusPesanan.diterima.kodeDb] ?? 0,
      ),
      (
        kode: StatusPesanan.diproses.kodeDb,
        label: 'Diproses',
        count: jumlahPerStatus[StatusPesanan.diproses.kodeDb] ?? 0,
      ),
      (
        kode: StatusPesanan.diantar.kodeDb,
        label: 'Diantar',
        count: jumlahPerStatus[StatusPesanan.diantar.kodeDb] ?? 0,
      ),
      (
        kode: StatusPesanan.selesai.kodeDb,
        label: 'Selesai',
        count: jumlahPerStatus[StatusPesanan.selesai.kodeDb] ?? 0,
      ),
      (
        kode: StatusPesanan.ditolak.kodeDb,
        label: 'Ditolak',
        count: jumlahPerStatus[StatusPesanan.ditolak.kodeDb] ?? 0,
      ),
    ];

    final jumlahFilterAktif =
        (_statusDipilih != 'semua' ? 1 : 0) + (_filterJenis != 'semua' ? 1 : 0);

    return RefreshIndicator(
      color: OC.primary,
      onRefresh: widget.onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 110),
        children: [
          // 0. HEADER SCROLLABLE PESANAN ALA MOCKUP (Seamless Edge-to-Edge)
          const UmkmHeaderRow(
            padding: EdgeInsets.fromLTRB(0, 4, 0, 16),
            iconBadge: UmkmSquircleIcon(
              icon: Icons.shopping_bag_rounded,
            ),
            title: 'Pesanan',
            subtitle: 'Kelola pesanan dan transaksi',
          ),

          // 1. STATISTIK PESANAN SUMMARY (Total Pesanan | Perlu Tindakan)
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: const Color(0xFFEDF4ED),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFDFEADF)),
            ),
            child: Row(
              children: [
                // Total Pesanan
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _statusDipilih = 'semua';
                          _filterJenis = 'semua';
                          _searchCtrl.clear();
                          _kataKunci = '';
                        });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        decoration: BoxDecoration(
                          color: _statusDipilih == 'semua'
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: _statusDipilih == 'semua'
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFE2EBE2),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.shopping_bag_outlined,
                                  color: OC.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${semua.length}',
                                      style: const TextStyle(
                                        color: OC.ink,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        height: 1.1,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'Total Pesanan',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: OC.muted,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Container(width: 1, height: 36, color: const Color(0xFFD6E2D6)),

                // Perlu Tindakan
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _statusDipilih = StatusPesanan.poBaru.kodeDb;
                        });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        decoration: BoxDecoration(
                          color: _statusDipilih == StatusPesanan.poBaru.kodeDb
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow:
                              _statusDipilih == StatusPesanan.poBaru.kodeDb
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFE2EBE2),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.schedule_rounded,
                                  color: Color(0xFFD97706),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '$jumlahPerluTindakan',
                                      style: const TextStyle(
                                        color: OC.ink,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        height: 1.1,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'Perlu Tindakan',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: OC.muted,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 2. STATUS PILLS HORIZONTAL WITH COUNTER
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: statusTabs.map((tab) {
                final terpilih = _statusDipilih == tab.kode;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => setState(() => _statusDipilih = tab.kode),
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: terpilih ? OC.primary : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: terpilih
                              ? OC.primary
                              : const Color(0xFFE2EBE2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            tab.label,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: terpilih
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: terpilih ? Colors.white : OC.ink,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: terpilih
                                  ? Colors.white.withValues(alpha: 0.22)
                                  : const Color(0xFFF0F5F0),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${tab.count}',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: terpilih ? Colors.white : OC.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),

          // 3. SEARCH BAR + FILTER BUTTON
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: OC.line),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (val) => setState(() => _kataKunci = val),
                    textInputAction: TextInputAction.search,
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      hintText: 'Cari pesanan...',
                      hintStyle: const TextStyle(
                        color: OC.faint,
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: OC.muted,
                        size: 21,
                      ),
                      suffixIcon: _kataKunci.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Hapus pencarian',
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _kataKunci = '');
                              },
                              icon: const Icon(
                                Icons.close_rounded,
                                size: 19,
                              ),
                              color: OC.muted,
                            ),
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: () => _bukaFilter(jumlahPerStatus),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: jumlahFilterAktif > 0 ? OC.primary : OC.line,
                      width: jumlahFilterAktif > 0 ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        size: 18,
                        color: jumlahFilterAktif > 0 ? OC.primary : OC.ink,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        jumlahFilterAktif == 0
                            ? 'Filter'
                            : 'Filter ($jumlahFilterAktif)',
                        style: TextStyle(
                          color: jumlahFilterAktif > 0 ? OC.primary : OC.ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 4. DAFTAR PESANAN BERDASARKAN GROUP TANGGAL
          if (pesananTersaring.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: TampilanKosong(
                ikon: Icons.receipt_long_outlined,
                judul: 'Tidak Ada Pesanan',
                pesan: _kataKunci.isNotEmpty
                    ? 'Tidak ditemukan pesanan dengan kata kunci "$_kataKunci".'
                    : 'Belum ada pesanan di kategori atau filter ini.',
              ),
            )
          else
            ...listTanggal.map((tanggal) {
              final pesananHariIni = pesananPerTanggal[tanggal]!;
              final isTerbaru = tanggal == listTanggal.first;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Group Header Tanggal
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_month_outlined,
                          size: 16,
                          color: OC.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          tanggal,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: OC.ink,
                          ),
                        ),
                        const Spacer(),
                        if (isTerbaru)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  size: 11,
                                  color: Color(0xFF2E7D32),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Terbaru',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Cards Pesanan Hari Ini
                  ...pesananHariIni.map((p) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _KartuPesananBaru(
                          pesanan: p,
                          onRefresh: widget.onRefresh,
                          tanggalFmt: tanggalFmt,
                        ),
                      )),
                ],
              );
            }),
        ],
      ),
    );
  }
}

class _KartuPesananBaru extends StatelessWidget {
  final Pesanan pesanan;
  final Future<void> Function() onRefresh;
  final DateFormat tanggalFmt;

  const _KartuPesananBaru({
    required this.pesanan,
    required this.onRefresh,
    required this.tanggalFmt,
  });

  (Color, Color) _warnaStatus(StatusPesanan s) => switch (s) {
        StatusPesanan.poBaru => (const Color(0xFFFFFBEB), const Color(0xFFD97706)),
        StatusPesanan.diterima => (const Color(0xFFF0FDF4), const Color(0xFF16A34A)),
        StatusPesanan.diproses => (const Color(0xFFEFF6FF), const Color(0xFF2563EB)),
        StatusPesanan.diantar => (const Color(0xFFFAF5FF), const Color(0xFF9333EA)),
        StatusPesanan.selesai => (const Color(0xFFF0FDF4), const Color(0xFF16A34A)),
        StatusPesanan.ditolak => (const Color(0xFFFEF2F2), const Color(0xFFDC2626)),
      };

  @override
  Widget build(BuildContext context) {
    final p = pesanan;
    final (bgStatus, fgStatus) = _warnaStatus(p.status);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DetailPesananScreen(idPesanan: p.idPesanan),
          ),
        );
        await onRefresh();
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEBEFEB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. HEADER CARD: ID PESANAN, BADGE JENIS, BADGE STATUS, TITIK 3
            Row(
              children: [
                Expanded(
                  child: Text(
                    '#${p.idPesanan}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: OC.ink,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Badge Jenis (Pre-Order / Ready)
                if (p.isPreOrder)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3.5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFFEDD5)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 11,
                          color: Color(0xFFEA580C),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Pre-Order',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFEA580C),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3.5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFDCFCE7)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.bolt_rounded,
                          size: 12,
                          color: Color(0xFF16A34A),
                        ),
                        SizedBox(width: 3),
                        Text(
                          'Ready',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF15803D),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(width: 6),

                // Badge Status
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3.5,
                  ),
                  decoration: BoxDecoration(
                    color: bgStatus,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    p.status.label,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: fgStatus,
                    ),
                  ),
                ),
                const SizedBox(width: 4),

                const Icon(
                  Icons.more_vert_rounded,
                  size: 18,
                  color: OC.muted,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 2. BODY CARD: FOTO MENU SQUARE & INFO LENGKAP
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: p.items.isNotEmpty &&
                          p.items.first.gambarUrl != null &&
                          p.items.first.gambarUrl!.isNotEmpty
                      ? GambarJaringan(
                          url: p.items.first.gambarUrl!,
                          width: 80,
                          height: 80,
                          radius: 14,
                          cacheBuster:
                              DateTime.now().millisecondsSinceEpoch.toString(),
                        )
                      : Container(
                          width: 80,
                          height: 80,
                          color: const Color(0xFFF3F4F6),
                          child: const Icon(
                            Icons.restaurant_menu_rounded,
                            color: OC.muted,
                            size: 28,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.namaPembeli,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: OC.ink,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        p.items.isNotEmpty
                            ? '${p.items.first.namaProduk}${p.items.length > 1 ? ' (+${p.items.length - 1} lainnya)' : ''}'
                            : 'Pesanan UMKM',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: OC.muted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.group_outlined,
                            size: 13,
                            color: OC.muted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${p.totalPorsi} porsi',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: OC.muted,
                            ),
                          ),
                        ],
                      ),
                      if (p.isPreOrder && p.waktuDibutuhkan != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.schedule_rounded,
                              size: 13,
                              color: Color(0xFFEA580C),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Acara: ${tanggalFmt.format(p.waktuDibutuhkan!)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFEA580C),
                                ),
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
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF1F3F1)),
            const SizedBox(height: 10),

            // 3. FOOTER CARD: PENDAPATAN BERSIH & LIHAT DETAIL
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pendapatan Bersih',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: OC.muted,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      rupiah(p.totalDiterimaMitra),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: OC.primary,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Lihat Detail',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: OC.primary,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: OC.primary,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
