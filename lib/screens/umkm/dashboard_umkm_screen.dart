import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/umkm_seller_models.dart';
import '../../services/api_service.dart';
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
                        Text(
                          profile.tokoAktif
                              ? 'Buka • Siap Terima Pesanan'
                              : 'Tutup • Toko Libur',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: profile.tokoAktif
                                ? const Color(0xFF047857)
                                : OC.muted,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 6.5),
                decoration: BoxDecoration(
                  color: OC.mintSoft,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: OC.primary.withValues(alpha: 0.15),
                  ),
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
        return UmkmAppBar(
          title: 'Katalog Produk',
          rightAction: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: OC.mintSoft,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: OC.primary.withValues(alpha: 0.15)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                  size: 13,
                  color: OC.primary,
                ),
                const SizedBox(width: 5),
                Text(
                  '${service.produkList.length} Menu',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: OC.primary,
                  ),
                ),
              ],
            ),
          ),
        );
      case 2:
        final jumlahPoBaru = service.pesananList
            .where((p) => p.status == StatusPesanan.poBaru)
            .length;
        return UmkmAppBar(
          title: 'Pesanan Masuk',
          showBottomBorder: false,
          rightAction: jumlahPoBaru > 0
              ? Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '$jumlahPoBaru Perlu Konfirmasi',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFB91C1C),
                        ),
                      ),
                    ],
                  ),
                )
              : null,
        );
      case 3:
      default:
        return const UmkmAppBar(title: 'Pengaturan Usaha');
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
      backgroundColor: OC.bg,
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
      floatingActionButton: _tab == 1
          ? FloatingActionButton.extended(
              backgroundColor: OC.primary,
              foregroundColor: Colors.white,
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TambahProdukScreen()),
                );
                if (mounted) _refresh();
              },
              icon: const Icon(Icons.add),
              label: const Text('Tambah Produk'),
            )
          : null,
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

  const _TabBeranda({
    required this.service,
    required this.onPindahTab,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final r = service.ringkasan;
    final pesananTerbaru = service.pesananList.take(3).toList();
    final semuaProduk = service.produkList;
    final stokHabis = semuaProduk
        .where((p) => p.modePenjualan != ModePenjualan.preOrder && p.stok == 0)
        .length;

    return RefreshIndicator(
      color: OC.primary,
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 110),
        children: [
          // 1. HERO CARD OMZET / TOTAL PENDAPATAN (FLAT DESIGN)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200, width: 1),
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
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: OC.mintSoft,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 16,
                            color: OC.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'TOTAL PENDAPATAN',
                          style: OT.label.copyWith(letterSpacing: 0.8),
                        ),
                      ],
                    ),
                    MiniBadge(
                      '${r.pesananDiterima} Selesai',
                      bg: OC.mintSoft,
                      fg: OC.primary,
                      ikon: Icons.verified_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  rupiah(r.omzetDiterima),
                  style: OT.moneyLarge.copyWith(
                    fontSize: 24,
                    color: OC.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Akumulasi omzet bersih dari pesanan yang telah selesai.',
                  style: OT.caption,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 2. RINGKASAN USAHA (GRID VIEW PADAT & RAPI)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ringkasan Usaha',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: OC.ink,
                  ),
                ),
                Text(
                  'Periode Ini',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.85,
            children: [
              _KartuMetrikGrid(
                ikon: Icons.notifications_active_outlined,
                nilai: '${r.pesananBaru}',
                label: 'Perlu Konfirmasi',
                soroti: r.pesananBaru > 0,
                onTap: () => onPindahTab(2),
              ),
              _KartuMetrikGrid(
                ikon: Icons.task_alt,
                nilai: '${r.pesananDiterima}',
                label: 'Pesanan Selesai',
                onTap: () => onPindahTab(2),
              ),
              _KartuMetrikGrid(
                ikon: Icons.inventory_2_outlined,
                nilai: '${r.produkTayang}',
                label: 'Produk Tayang',
                onTap: () => onPindahTab(1),
              ),
              _KartuMetrikGrid(
                ikon: Icons.trending_up_rounded,
                nilai: '${r.totalPesananPeriode}',
                label: 'Pesanan Periode',
                sublabel: rupiah(r.omzetPeriode),
              ),
            ],
          ),

          if (r.produkTerlaris.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Produk Terlaris',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: OC.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...r.produkTerlaris.take(3).map(
                        (produk) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              const Icon(Icons.star_rounded,
                                  size: 16, color: OC.accent),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  produk.namaProduk,
                                  style: const TextStyle(
                                      fontSize: 12.5, color: OC.ink),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${produk.jumlahTerjual} terjual',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),

          // 3. PERINGATAN STOK HABIS (JIKA ADA)
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

          // 4. SHORTCUT / AKSI CEPAT (FLAT DESIGN)
          Row(
            children: [
              Expanded(
                child: _TombolShortcut(
                  ikon: Icons.add_circle_outline,
                  label: 'Tambah Produk',
                  warnaIkon: OC.primary,
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const TambahProdukScreen(),
                      ),
                    );
                    onRefresh();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TombolShortcut(
                  ikon: Icons.format_list_bulleted,
                  label: 'Katalog Produk',
                  warnaIkon: OC.primary,
                  onTap: () => onPindahTab(1),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TombolShortcut(
                  ikon: Icons.receipt_long_outlined,
                  label: 'Semua PO',
                  warnaIkon: OC.primary,
                  onTap: () => onPindahTab(2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 5. PESANAN TERBARU (FLAT DESIGN)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Pesanan Terbaru', style: OT.cardTitle),
              if (service.pesananList.isNotEmpty)
                TextButton(
                  onPressed: () => onPindahTab(2),
                  child: Text(
                    'Lihat Semua',
                    style: OT.caption.copyWith(
                      color: OC.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),

          if (pesananTerbaru.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200, width: 1),
              ),
              child: const Center(
                child: Column(
                  children: [
                    Icon(Icons.inbox_outlined, size: 36, color: OC.faint),
                    SizedBox(height: 8),
                    Text('Belum ada pesanan masuk', style: OT.secondary),
                  ],
                ),
              ),
            )
          else
            ...pesananTerbaru.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
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
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200, width: 1),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: OC.box,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.receipt_outlined,
                            size: 20,
                            color: OC.muted,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text('#${p.idPesanan}', style: OT.item),
                                  const Spacer(),
                                  Text(
                                    rupiah(p.totalDiterimaMitra),
                                    style: OT.money.copyWith(color: OC.primary),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    '${p.namaPembeli} • ${p.totalPorsi} porsi',
                                    style: OT.caption,
                                  ),
                                  const Spacer(),
                                  MiniBadge(
                                    p.status.label,
                                    bg: p.status == StatusPesanan.poBaru
                                        ? OC.peach
                                        : OC.mintSoft,
                                    fg: p.status == StatusPesanan.poBaru
                                        ? OC.amber
                                        : OC.primary,
                                  ),
                                ],
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
        ],
      ),
    );
  }
}

// ======================================================== TAB PRODUK ===
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

  @override
  Widget build(BuildContext context) {
    final semua = widget.service.produkList;

    // Ambil daftar kategori unik dari data produk
    final kategoriSet = <String>{'Semua'};
    for (final p in semua) {
      if (p.kategori.isNotEmpty) kategoriSet.add(p.kategori);
    }
    final listKategori = kategoriSet.toList();

    // Filter berdasarkan kata kunci & kategori
    final produkList = semua.where((p) {
      final cocokKunci =
          widget.kataKunci.isEmpty ||
          p.namaProduk.toLowerCase().contains(widget.kataKunci.toLowerCase()) ||
          p.kategori.toLowerCase().contains(widget.kataKunci.toLowerCase());
      final cocokKategori =
          _kategoriDipilih == 'Semua' || p.kategori == _kategoriDipilih;
      return cocokKunci && cocokKategori;
    }).toList();

    // Pre-Order tidak punya stok, jadi tidak ikut dihitung sebagai "stok habis".
    final stokHabis = semua
        .where((p) => p.modePenjualan != ModePenjualan.preOrder && p.stok == 0)
        .length;

    return RefreshIndicator(
      color: OC.primary,
      onRefresh: widget.onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 110),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Modern Search Bar ala Customer
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: OC.line),
                  ),
                  child: TextField(
                    onChanged: widget.onCari,
                    decoration: const InputDecoration(
                      hintText: 'Cari nama produk...',
                      hintStyle: TextStyle(color: OC.faint, fontSize: 13.5),
                      prefixIcon: Icon(Icons.search, color: OC.muted, size: 22),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Horizontal Category Pills
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: listKategori.map((kat) {
                      final terpilih = _kategoriDipilih == kat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () => setState(() => _kategoriDipilih = kat),
                          borderRadius: BorderRadius.circular(20),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: terpilih ? OC.primary : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: terpilih ? OC.primary : OC.line,
                              ),
                            ),
                            child: Text(
                              kat,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: terpilih
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: terpilih ? Colors.white : OC.muted,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 14),

                if (stokHabis > 0) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: OC.peachSoft,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: OC.peach),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: OC.amber,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '$stokHabis produk stoknya habis. Segera isi ulang agar siap dipesan.',
                            style: OT.caption.copyWith(color: OC.amber),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                if (produkList.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: TampilanKosong(
                      ikon: Icons.inventory_2_outlined,
                      judul:
                          widget.kataKunci.isEmpty &&
                              _kategoriDipilih == 'Semua'
                          ? 'Belum Ada Produk'
                          : 'Produk Tidak Ditemukan',
                      pesan:
                          widget.kataKunci.isEmpty &&
                              _kategoriDipilih == 'Semua'
                          ? 'Tekan tombol "Tambah Produk" untuk mulai berjualan di Djajan.'
                          : 'Coba kata kunci atau filter kategori lain.',
                    ),
                  )
                else
                  Column(
                    children: produkList
                        .map(
                          (p) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _KartuProduk(
                              produk: p,
                              service: widget.service,
                              onRefresh: widget.onRefresh,
                            ),
                          ),
                        )
                        .toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KartuMetrikGrid extends StatelessWidget {
  final IconData ikon;
  final String nilai;
  final String label;
  final String? sublabel;
  final bool soroti;
  final VoidCallback? onTap;

  const _KartuMetrikGrid({
    required this.ikon,
    required this.nilai,
    required this.label,
    this.sublabel,
    this.soroti = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: soroti ? const Color(0xFFFFCC80) : Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: soroti ? OC.peachSoft : OC.primarySoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    ikon,
                    color: soroti ? OC.amber : OC.primary,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    nilai,
                    style: TextStyle(
                      color: soroti ? OC.amber : OC.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (sublabel != null) ...[
              const SizedBox(height: 2),
              Text(
                sublabel!,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: OC.primary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TombolShortcut extends StatelessWidget {
  final IconData ikon;
  final String label;
  final Color warnaIkon;
  final VoidCallback onTap;

  const _TombolShortcut({
    required this.ikon,
    required this.label,
    required this.warnaIkon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200, width: 1),
        ),
        child: Column(
          children: [
            Icon(ikon, color: warnaIkon, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: OT.caption.copyWith(fontWeight: FontWeight.w600),
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: OC.box,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      '$stokSementara',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
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
                await _jalankan(() =>
                    widget.service.ubahStok(widget.produk, stokSementara));
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
        content: Text(
          '"${widget.produk.namaProduk}" akan dihapus permanen dari database beserta fotonya.',
        ),
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

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Opacity(
        opacity: _sibuk ? 0.55 : 1,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. KIRI: Foto produk berasio kotak (square)
            GestureDetector(
              onTap: () => tampilkanZoomGambarJaringan(context, p.gambarUrl),
              child: Stack(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: GambarJaringan(
                      url: p.gambarUrl,
                      width: 76,
                      height: 76,
                      radius: 10,
                      cacheBuster:
                          DateTime.now().millisecondsSinceEpoch.toString(),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: p.modePenjualan == ModePenjualan.ready
                            ? OC.mint
                            : OC.peach,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        p.modePenjualan == ModePenjualan.ready ? 'Ready' : 'PO',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: p.modePenjualan == ModePenjualan.ready
                              ? OC.mintText
                              : OC.amber,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // 2. TENGAH: Detail teks (nama, harga, kategori & stok)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    p.namaProduk,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: OC.ink,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    rupiah(p.harga),
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: OC.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: OC.box,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            p.kategori,
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: OC.muted,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (p.modePenjualan != ModePenjualan.preOrder)
                        Text(
                          '${p.stok} stok',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: p.stok == 0 ? AppColors.danger : OC.muted,
                          ),
                        )
                      else
                        const Text(
                          'PO',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: OC.muted,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // 3. KANAN: Menu meatball (3 titik) dan Switch Tayangkan
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded,
                      size: 20, color: OC.muted),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (val) async {
                    if (val == 'edit') {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TambahProdukScreen(produkToEdit: p),
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
                          Icon(Icons.edit_outlined, size: 18, color: OC.ink),
                          SizedBox(width: 8),
                          Text('Edit Produk', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                    if (p.modePenjualan != ModePenjualan.preOrder)
                      const PopupMenuItem(
                        value: 'stok',
                        child: Row(
                          children: [
                            Icon(Icons.inventory_2_outlined,
                                size: 18, color: OC.ink),
                            SizedBox(width: 8),
                            Text('Ubah Stok', style: TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'hapus',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline,
                              size: 18, color: AppColors.danger),
                          SizedBox(width: 8),
                          Text('Hapus Produk',
                              style: TextStyle(
                                  fontSize: 13, color: AppColors.danger)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      p.tampilkanDiWarung ? 'Tayang' : 'Draft',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: p.tampilkanDiWarung ? OC.primary : OC.muted,
                      ),
                    ),
                    const SizedBox(width: 2),
                    SizedBox(
                      height: 28,
                      width: 38,
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: Switch.adaptive(
                          value: p.tampilkanDiWarung,
                          activeThumbColor: OC.primary,
                          onChanged: _sibuk
                              ? null
                              : (v) => _jalankan(
                                  () => widget.service.ubahStatusTayang(p, v),
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

class _TabPesananState extends State<_TabPesanan>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // 3 tab: Semua | Perlu Aksi | Selesai
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Filter berdasarkan tab yang aktif
  List<Pesanan> _filterByTab(List<Pesanan> semua) {
    return switch (_tabController.index) {
      1 => semua.where((p) => p.status == StatusPesanan.poBaru).toList(),
      2 => semua
          .where(
            (p) =>
                p.status == StatusPesanan.selesai ||
                p.status == StatusPesanan.ditolak,
          )
          .toList(),
      _ => semua,
    };
  }
  @override
  Widget build(BuildContext context) {
    final semua = widget.service.pesananList;
    final tanggalFmt = DateFormat('d MMM yyyy, HH:mm', 'id_ID');

    final jumlahPerluAksi =
        semua.where((p) => p.status == StatusPesanan.poBaru).length;
    final jumlahSelesai = semua
        .where(
          (p) =>
              p.status == StatusPesanan.selesai ||
              p.status == StatusPesanan.ditolak,
        )
        .length;

    final pesananTersaring = _filterByTab(semua);

    return RefreshIndicator(
      color: OC.primary,
      onRefresh: widget.onRefresh,
      child: Column(
        children: [
          // ── TabBar Filter: Semua | Perlu Aksi | Selesai ──────────────
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xFFEFEFEF), width: 1),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: OC.primary,
              indicatorWeight: 2.5,
              labelColor: OC.primary,
              unselectedLabelColor: OC.muted,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              tabs: [
                const Tab(text: 'Semua'),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Perlu Aksi'),
                      if (jumlahPerluAksi > 0) ...[
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$jumlahPerluAksi',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Selesai'),
                      if (jumlahSelesai > 0) ...[
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: OC.mint,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$jumlahSelesai',
                            style: const TextStyle(
                              color: OC.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
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
