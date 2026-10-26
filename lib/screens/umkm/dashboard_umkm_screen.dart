import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/umkm_models.dart';
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
class _TabProduk extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final semua = service.produkList;
    final produkList = kataKunci.isEmpty
        ? semua
        : semua
            .where((p) =>
                p.namaProduk.toLowerCase().contains(kataKunci.toLowerCase()) ||
                p.kategori.toLowerCase().contains(kataKunci.toLowerCase()))
            .toList();

    // Pre-Order tidak punya stok, jadi tidak ikut dihitung sebagai "stok habis".
    final stokHabis = semua
        .where((p) => p.modePenjualan != ModePenjualan.preOrder && p.stok == 0)
        .length;

    return RefreshIndicator(
      color: OC.primary,
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 110),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                TextField(
                  onChanged: onCari,
                  decoration: InputDecoration(
                    hintText: 'Cari produk atau kategori...',
                    prefixIcon:
                        const Icon(Icons.search, color: OC.muted),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                if (stokHabis > 0) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: OC.peachSoft,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: OC.peach),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: OC.amber, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '$stokHabis produk stoknya habis. Segera isi ulang '
                            'agar tetap tampil menarik di etalase.',
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
                      judul: kataKunci.isEmpty
                          ? 'Belum Ada Produk'
                          : 'Produk Tidak Ditemukan',
                      pesan: kataKunci.isEmpty
                          ? 'Tekan tombol "Tambah Produk" untuk mulai berjualan di Djajan.'
                          : 'Coba kata kunci lain, atau tambahkan produk baru.',
                    ),
                  )
                else
                  Column(
                    children: produkList
                        .map((p) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _KartuProduk(
                                  produk: p, service: service, onRefresh: onRefresh),
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
      padding: const EdgeInsets.all(12),
      radius: 16,
      child: Opacity(
        opacity: _sibuk ? 0.55 : 1,
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () =>
                      tampilkanZoomGambarJaringan(context, p.gambarUrl),
                  child: GambarJaringan(
                    url: p.gambarUrl,
                    width: 68,
                    height: 68,
                    radius: 12,
                    cacheBuster:
                        DateTime.now().millisecondsSinceEpoch.toString(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.namaProduk,
                          style: OT.item,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(rupiah(p.harga),
                          style: OT.money.copyWith(color: OC.primary)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          MiniBadge(p.modePenjualan.label,
                              bg: OC.mintSoft,
                              fg: OC.primary),
                          MiniBadge(p.kategori,
                              bg: OC.box,
                              fg: OC.muted),
                          if (p.tampilkanDiWarung)
                            const MiniBadge('Tayang',
                                bg: OC.mint,
                                fg: OC.mintText,
                                ikon: Icons.visibility)
                          else
                            const MiniBadge('Draft',
                                bg: OC.box,
                                fg: OC.muted,
                                ikon: Icons.visibility_off),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.edit_outlined,
                          color: OC.primary),
                      tooltip: 'Edit produk',
                      onPressed: _sibuk
                          ? null
                          : () async {
                              await Navigator.of(context)
                                  .push(MaterialPageRoute(
                                builder: (_) =>
                                    TambahProdukScreen(produkToEdit: p),
                              ));
                              if (mounted) widget.onRefresh();
                            },
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.delete_outline,
                          color: AppColors.danger),
                      tooltip: 'Hapus produk',
                      onPressed: _sibuk ? null : _konfirmasiHapus,
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 20),
            // ------ pengaturan cepat: stok & status tayang ------
            // Produk Pre-Order tidak punya stok (pelanggan yang menentukan
            // jumlah pesanannya), jadi bagian stok disembunyikan.
            Row(
              children: [
                if (p.modePenjualan != ModePenjualan.preOrder) ...[
                  const Text('Stok',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(width: 6),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                    onPressed: _sibuk || p.stok == 0
                        ? null
                        : () => _jalankan(
                            () => widget.service.ubahStok(p, p.stok - 1)),
                  ),
                  Container(
                    constraints: const BoxConstraints(minWidth: 34),
                    alignment: Alignment.center,
                    child: Text('${p.stok}',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: p.stok == 0
                              ? AppColors.danger
                              : AppColors.textDark,
                        )),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    onPressed: _sibuk
                        ? null
                        : () => _jalankan(
                            () => widget.service.ubahStok(p, p.stok + 1)),
                  ),
                ] else
                  const Flexible(
                    child: Text('Jumlah pesanan ditentukan pelanggan',
                        style: TextStyle(
                            fontSize: 12.5, color: OC.muted)),
                  ),
                const Spacer(),
                const Text('Tayang',
                    style:
                        TextStyle(fontSize: 12.5, color: OC.muted)),
                Switch(
                  value: p.tampilkanDiWarung,
                  activeThumbColor: OC.primary,
                  onChanged: _sibuk
                      ? null
                      : (v) => _jalankan(
                          () => widget.service.ubahStatusTayang(p, v)),
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
class _TabPesanan extends StatelessWidget {
  final UmkmDataService service;
  final Future<void> Function() onRefresh;

  const _TabPesanan({required this.service, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final pesananList = service.pesananList;
    final tanggalFmt = DateFormat('d MMM yyyy, HH:mm', 'id_ID');

    return RefreshIndicator(
      color: OC.primary,
      onRefresh: onRefresh,
      child: pesananList.isEmpty
          ? ListView(
              padding: const EdgeInsets.only(top: 80),
              children: const [
                TampilanKosong(
                  ikon: Icons.receipt_long_outlined,
                  judul: 'Belum Ada Pesanan Masuk',
                  pesan:
                      'Pesanan dari pelanggan akan muncul di sini secara otomatis.',
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: pesananList.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final p = pesananList[i];
                final (bg, fg) = _warnaStatus(p.status);

                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () async {
                    await Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) =>
                            DetailPesananScreen(idPesanan: p.idPesanan)));
                    await onRefresh();
                  },
                  child: KartuPutih(
                    padding: const EdgeInsets.all(14),
                    radius: 16,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('#${p.idPesanan}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14.5)),
                                  const SizedBox(height: 2),
                                  Text(
                                      '${p.namaPembeli} • ${p.totalPorsi} porsi',
                                      style: const TextStyle(
                                          color: OC.muted,
                                          fontSize: 12.5)),
                                  const SizedBox(height: 4),
                                  Text(formatRupiah(p.totalDiterimaMitra),
                                      style: const TextStyle(
                                          color: OC.primary,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                MiniBadge(p.status.label, bg: bg, fg: fg),
                                const SizedBox(height: 8),
                                const Icon(Icons.chevron_right,
                                    color: OC.muted),
                              ],
                            ),
                          ],
                        ),
                        const Divider(height: 18),
                        Row(
                          children: [
                            const Icon(Icons.schedule,
                                size: 14, color: OC.muted),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Masuk ${tanggalFmt.format(p.tanggalPesan)} WIB',
                                style: const TextStyle(
                                    fontSize: 11.5, color: OC.muted),
                              ),
                            ),
                            if (p.status == StatusPesanan.poBaru)
                              const MiniBadge('Perlu Dikonfirmasi',
                                  bg: AppColors.dangerBg,
                                  fg: AppColors.danger,
                                  ikon: Icons.priority_high),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  (Color, Color) _warnaStatus(StatusPesanan s) => switch (s) {
        StatusPesanan.poBaru => (
            OC.peach,
            OC.amber
          ),
        StatusPesanan.diterima => (OC.mint, OC.primary),
        StatusPesanan.selesai => (OC.mint, OC.primary),
        StatusPesanan.ditolak => (AppColors.dangerBg, AppColors.danger),
      };
}