import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/umkm_seller_models.dart';
import '../../services/api_service.dart';
import '../../services/umkm_data_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import 'detail_pesanan_screen.dart';
import '../../screens/auth/login_screen.dart';
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

  void _keluar() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Keluar dari Akun?'),
        content: const Text('Anda perlu masuk kembali untuk mengelola warung.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                minimumSize: const Size(110, 44)),
            onPressed: () {
              context.read<UmkmDataService>().logout();
              Navigator.pop(ctx);
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicHeader(UmkmProfile profile, UmkmDataService service) {
    switch (_tab) {
      case 0:
        return DjajanPageHeader(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          leftWidget: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: GambarJaringan(
                  url: profile.fotoProfilUrl,
                  width: 44,
                  height: 44,
                  radius: 22,
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
                    Text(profile.namaUsaha, style: OT.pageTitle),
                    const SizedBox(height: 3),
                    MiniBadge(
                      profile.tokoAktif ? 'Toko Aktif' : 'Toko Tutup',
                      bg: profile.tokoAktif ? OC.mint : OC.box,
                      fg: profile.tokoAktif ? OC.mintText : OC.muted,
                      ikon: profile.tokoAktif ? Icons.check_circle : Icons.do_not_disturb_on,
                    ),
                  ],
                ),
              ),
            ],
          ),
          rightAction: IconButton(
            icon: const Icon(Icons.logout_rounded, color: OC.muted),
            tooltip: 'Keluar',
            onPressed: _keluar,
          ),
        );
      case 1:
        return DjajanPageHeader(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          title: 'Katalog Produk',
          subtitle: '${service.produkList.length} produk terdaftar',
        );
      case 2:
        return DjajanPageHeader(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          title: 'Pesanan Masuk',
          subtitle: '${service.pesananList.length} total pesanan pelanggan',
        );
      case 3:
      default:
        return const DjajanPageHeader(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
          title: 'Pengaturan Usaha',
          subtitle: 'Kelola profil, operasional, & ongkir',
        );
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
                  await Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const TambahProdukScreen()));
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
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 110),
        children: [
          // 1. HERO CARD OMZET / TOTAL PENDAPATAN
          KartuPutih(
            radius: 18,
            padding: const EdgeInsets.all(18),
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
                          child: const Icon(Icons.account_balance_wallet_outlined,
                              size: 16, color: OC.primary),
                        ),
                        const SizedBox(width: 8),
                        Text('TOTAL PENDAPATAN',
                            style: OT.label.copyWith(letterSpacing: 0.8)),
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
                const SizedBox(height: 12),
                Text(
                  rupiah(r.omzetDiterima),
                  style: OT.moneyLarge.copyWith(
                    fontSize: 26,
                    color: OC.primary,
                    fontWeight: FontWeight.w900,
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
          const SizedBox(height: 12),

          // 2. TIGA KARTU METRIK CEPAT
          Row(
            children: [
              Expanded(
                child: _KartuStatistik(
                  ikon: Icons.notifications_active_outlined,
                  nilai: '${r.pesananBaru}',
                  label: 'PO Baru',
                  soroti: r.pesananBaru > 0,
                  onTap: () => onPindahTab(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _KartuStatistik(
                  ikon: Icons.task_alt,
                  nilai: '${r.pesananDiterima}',
                  label: 'Selesai',
                  onTap: () => onPindahTab(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _KartuStatistik(
                  ikon: Icons.inventory_2_outlined,
                  nilai: '${r.produkTayang}',
                  label: 'Tayang',
                  onTap: () => onPindahTab(1),
                ),
              ),
            ],
          ),
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
                  border: Border.all(color: OC.peach),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: OC.amber, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Peringatan Stok Habis',
                              style: OT.item.copyWith(color: OC.amber)),
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

          // 4. SHORTCUT / AKSI CEPAT
          Row(
            children: [
              Expanded(
                child: _TombolShortcut(
                  ikon: Icons.add_circle_outline,
                  label: 'Tambah Produk',
                  warnaIkon: OC.primary,
                  onTap: () async {
                    await Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const TambahProdukScreen()));
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

          // 5. PESANAN TERBARU
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Pesanan Terbaru', style: OT.cardTitle),
              if (service.pesananList.isNotEmpty)
                TextButton(
                  onPressed: () => onPindahTab(2),
                  child: Text('Lihat Semua',
                      style: OT.caption.copyWith(
                        color: OC.primary,
                        fontWeight: FontWeight.w700,
                      )),
                ),
            ],
          ),
          const SizedBox(height: 6),

          if (pesananTerbaru.isEmpty)
            const KartuPutih(
              radius: 16,
              padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Center(
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
            ...pesananTerbaru.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () async {
                      await Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) =>
                              DetailPesananScreen(idPesanan: p.idPesanan)));
                      await onRefresh();
                    },
                    child: KartuPutih(
                      radius: 16,
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: OC.box,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.receipt_outlined,
                                size: 20, color: OC.muted),
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
                                    Text(rupiah(p.totalDiterimaMitra),
                                        style: OT.money
                                            .copyWith(color: OC.primary)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                        '${p.namaPembeli} • ${p.totalPorsi} porsi',
                                        style: OT.caption),
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
                )),
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
      final cocokKunci = widget.kataKunci.isEmpty ||
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
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 13),
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
                                horizontal: 14, vertical: 8),
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
                        const Icon(Icons.warning_amber_rounded,
                            color: OC.amber, size: 20),
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
                      judul: widget.kataKunci.isEmpty && _kategoriDipilih == 'Semua'
                          ? 'Belum Ada Produk'
                          : 'Produk Tidak Ditemukan',
                      pesan: widget.kataKunci.isEmpty && _kategoriDipilih == 'Semua'
                          ? 'Tekan tombol "Tambah Produk" untuk mulai berjualan di Djajan.'
                          : 'Coba kata kunci atau filter kategori lain.',
                    ),
                  )
                else
                  Column(
                    children: produkList
                        .map((p) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _KartuProduk(
                                produk: p,
                                service: widget.service,
                                onRefresh: widget.onRefresh,
                              ),
                            ))
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

class _KartuStatistik extends StatelessWidget {
  final IconData ikon;
  final String nilai;
  final String label;
  final bool soroti;
  final VoidCallback? onTap;

  const _KartuStatistik({
    required this.ikon,
    required this.nilai,
    required this.label,
    this.soroti = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: KartuPutih(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        radius: 16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: soroti ? OC.peachSoft : OC.primarySoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(ikon,
                  color: soroti ? OC.amber : OC.primary, size: 18),
            ),
            const SizedBox(height: 10),
            Text(nilai,
                style: OT.cardTitle.copyWith(
                  color: soroti ? OC.amber : OC.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                )),
            const SizedBox(height: 2),
            Text(label,
                style: OT.caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
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
      child: KartuPutih(
        radius: 14,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Icon(ikon, color: warnaIkon, size: 22),
            const SizedBox(height: 6),
            Text(label,
                textAlign: TextAlign.center,
                style: OT.caption.copyWith(fontWeight: FontWeight.w600)),
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

  void _konfirmasiHapus() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Produk?'),
        content: Text(
            '"${widget.produk.namaProduk}" akan dihapus permanen dari database beserta fotonya.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                minimumSize: const Size(110, 44)),
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

    return KartuPutih(
      padding: const EdgeInsets.all(14),
      radius: 16,
      child: Opacity(
        opacity: _sibuk ? 0.55 : 1,
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    GestureDetector(
                      onTap: () =>
                          tampilkanZoomGambarJaringan(context, p.gambarUrl),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: OC.line),
                        ),
                        child: GambarJaringan(
                          url: p.gambarUrl,
                          width: 80,
                          height: 80,
                          radius: 14,
                          cacheBuster:
                              DateTime.now().millisecondsSinceEpoch.toString(),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: p.modePenjualan == ModePenjualan.ready
                              ? OC.mint
                              : OC.peach,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          p.modePenjualan == ModePenjualan.ready ? 'Ready' : 'PO',
                          style: TextStyle(
                            fontSize: 9.5,
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
                const SizedBox(width: 12),
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
                              style: OT.item,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: _sibuk
                                ? null
                                : () async {
                                    await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            TambahProdukScreen(produkToEdit: p),
                                      ),
                                    );
                                    if (mounted) widget.onRefresh();
                                  },
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(Icons.edit_outlined,
                                  size: 19, color: OC.muted),
                            ),
                          ),
                          const SizedBox(width: 4),
                          InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: _sibuk ? null : _konfirmasiHapus,
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(Icons.delete_outline,
                                  size: 19, color: AppColors.danger),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        rupiah(p.harga),
                        style: OT.money.copyWith(
                          color: OC.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: OC.box,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              p.kategori,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: OC.muted,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                          const Spacer(),
                          MiniBadge(
                            p.tampilkanDiWarung ? 'Tayang' : 'Draft',
                            bg: p.tampilkanDiWarung ? OC.mintSoft : OC.box,
                            fg: p.tampilkanDiWarung ? OC.primary : OC.faint,
                            ikon: p.tampilkanDiWarung
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            // ------ Baris Kontrol Bawah: Mini Stepper Stok & Switch Tayang ------
            Row(
              children: [
                if (p.modePenjualan != ModePenjualan.preOrder) ...[
                  Container(
                    decoration: BoxDecoration(
                      color: OC.box,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: _sibuk || p.stok == 0
                              ? null
                              : () => _jalankan(
                                  () => widget.service.ubahStok(p, p.stok - 1)),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.remove_rounded,
                              size: 18,
                              color: p.stok == 0 ? OC.faint : OC.muted,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            '${p.stok} stok',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: p.stok == 0 ? AppColors.danger : OC.ink,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: _sibuk
                              ? null
                              : () => _jalankan(
                                  () => widget.service.ubahStok(p, p.stok + 1)),
                          borderRadius: BorderRadius.circular(8),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(Icons.add_rounded,
                                size: 18, color: OC.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else
                  const Flexible(
                    child: Row(
                      children: [
                        Icon(Icons.event_seat_outlined,
                            size: 15, color: OC.muted),
                        SizedBox(width: 5),
                        Text('Porsi sesuai PO acara',
                            style: TextStyle(fontSize: 12, color: OC.muted)),
                      ],
                    ),
                  ),
                const Spacer(),
                const Text('Tayangkan',
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: OC.muted)),
                const SizedBox(width: 6),
                Transform.scale(
                  scale: 0.82,
                  child: Switch.adaptive(
                    value: p.tampilkanDiWarung,
                    activeThumbColor: OC.primary,
                    onChanged: _sibuk
                        ? null
                        : (v) => _jalankan(
                            () => widget.service.ubahStatusTayang(p, v)),
                  ),
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

class _TabPesananState extends State<_TabPesanan> {
  int _filterIndex = 0; // 0: Semua, 1: Perlu Konfirmasi, 2: Diterima, 3: Selesai

  @override
  Widget build(BuildContext context) {
    final semua = widget.service.pesananList;
    final tanggalFmt = DateFormat('d MMM yyyy, HH:mm', 'id_ID');

    final pesananTersaring = switch (_filterIndex) {
      1 => semua.where((p) => p.status == StatusPesanan.poBaru).toList(),
      2 => semua.where((p) => p.status == StatusPesanan.diterima).toList(),
      3 => semua.where((p) => p.status == StatusPesanan.selesai).toList(),
      _ => semua,
    };

    final jumlahPoBaru =
        semua.where((p) => p.status == StatusPesanan.poBaru).length;

    return RefreshIndicator(
      color: OC.primary,
      onRefresh: widget.onRefresh,
      child: Column(
        children: [
          // Filter Tabs Horizontal
          Container(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
            color: OC.bg,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterButton('Semua', 0, semua.length),
                  const SizedBox(width: 8),
                  _filterButton('Perlu Konfirmasi', 1, jumlahPoBaru,
                      dangerBadge: jumlahPoBaru > 0),
                  const SizedBox(width: 8),
                  _filterButton(
                      'Diterima',
                      2,
                      semua
                          .where((p) => p.status == StatusPesanan.diterima)
                          .length),
                  const SizedBox(width: 8),
                  _filterButton(
                      'Selesai',
                      3,
                      semua
                          .where((p) => p.status == StatusPesanan.selesai)
                          .length),
                ],
              ),
            ),
          ),
          Expanded(
            child: pesananTersaring.isEmpty
                ? ListView(
                    padding: const EdgeInsets.only(top: 60),
                    children: const [
                      TampilanKosong(
                        ikon: Icons.receipt_long_outlined,
                        judul: 'Tidak Ada Pesanan',
                        pesan:
                            'Pesanan pelanggan untuk kategori filter ini belum ada.',
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
                    itemCount: pesananTersaring.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final p = pesananTersaring[i];
                      final (bg, fg) = _warnaStatus(p.status);

                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  DetailPesananScreen(idPesanan: p.idPesanan),
                            ),
                          );
                          await widget.onRefresh();
                        },
                        child: KartuPutih(
                          padding: const EdgeInsets.all(14),
                          radius: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header Kartu: ID Pesanan & Status Pill
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: OC.box,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '#${p.idPesanan}',
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w800,
                                        color: OC.ink,
                                      ),
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
                                  // Thumbnail item pertama (jika ada)
                                  if (p.items.isNotEmpty &&
                                      p.items.first.gambarUrl != null &&
                                      p.items.first.gambarUrl!.isNotEmpty)
                                    Container(
                                      margin: const EdgeInsets.only(right: 12),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: OC.line),
                                      ),
                                      child: GambarJaringan(
                                        url: p.items.first.gambarUrl!,
                                        width: 52,
                                        height: 52,
                                        radius: 10,
                                        cacheBuster: DateTime.now()
                                            .millisecondsSinceEpoch
                                            .toString(),
                                      ),
                                    )
                                  else
                                    Container(
                                      width: 52,
                                      height: 52,
                                      margin: const EdgeInsets.only(right: 12),
                                      decoration: BoxDecoration(
                                        color: OC.box,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: OC.line),
                                      ),
                                      child: const Icon(Icons.fastfood_outlined,
                                          color: OC.muted, size: 24),
                                    ),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                              ? '${p.items.first.namaProduk}${p.items.length > 1 ? ' (+${p.items.length - 1} menu lainnya)' : ''}'
                                              : 'Pesanan UMKM (${p.totalPorsi} porsi)',
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            color: OC.muted,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${p.totalPorsi} porsi total',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: OC.muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 20),

                              // Footer Kartu: Total pendapatan & Jadwal/Countdown
                              Row(
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('Pendapatan Bersih',
                                          style: TextStyle(
                                              fontSize: 11, color: OC.muted)),
                                      Text(
                                        formatRupiah(p.totalDiterimaMitra),
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w900,
                                          color: OC.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  if (p.status == StatusPesanan.poBaru)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: OC.peachSoft,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(Icons.timer_outlined,
                                              size: 14, color: OC.amber),
                                          SizedBox(width: 4),
                                          Text(
                                            'Konfirmasi Segera',
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w800,
                                              color: OC.amber,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  else
                                    Row(
                                      children: [
                                        Text(
                                          tanggalFmt.format(p.tanggalPesan),
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            color: OC.muted,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.chevron_right,
                                            size: 18, color: OC.muted),
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

  Widget _filterButton(String label, int index, int count,
      {bool dangerBadge = false}) {
    final terpilih = _filterIndex == index;
    return InkWell(
      onTap: () => setState(() => _filterIndex = index),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: terpilih ? OC.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: terpilih ? OC.primary : OC.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: terpilih ? FontWeight.w800 : FontWeight.w600,
                color: terpilih ? Colors.white : OC.muted,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: terpilih
                    ? Colors.white.withValues(alpha: 0.25)
                    : dangerBadge
                        ? AppColors.dangerBg
                        : OC.box,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: terpilih
                      ? Colors.white
                      : dangerBadge
                          ? AppColors.danger
                          : OC.muted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  (Color, Color) _warnaStatus(StatusPesanan s) => switch (s) {
        StatusPesanan.poBaru => (OC.peach, OC.amber),
        StatusPesanan.diterima => (OC.mint, OC.primary),
        StatusPesanan.selesai => (OC.mint, OC.primary),
        StatusPesanan.ditolak => (AppColors.dangerBg, AppColors.danger),
      };
}