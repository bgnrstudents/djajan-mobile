import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/umkm_seller_models.dart';
import '../../services/api_service.dart';
import '../../services/umkm_data_service.dart';
import '../../services/category_service.dart';
import '../../models/category.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/umkm_app_bar.dart';
import '../customer/order/order_widgets.dart';

/// HALAMAN 3 — Tambah / Edit Produk.
/// Data disimpan ke tabel `produk`, sedangkan foto diunggah ke folder
/// `backend/uploads/produk` dan nama filenya dicatat pada kolom `gambar_produk`.
class TambahProdukScreen extends StatefulWidget {
  /// Jika diisi, layar berpindah ke mode EDIT (form terisi otomatis).
  final Produk? produkToEdit;

  const TambahProdukScreen({super.key, this.produkToEdit});

  bool get isEditMode => produkToEdit != null;

  @override
  State<TambahProdukScreen> createState() => _TambahProdukScreenState();
}

class _TambahProdukScreenState extends State<TambahProdukScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _namaCtrl;
  late final TextEditingController _hargaCtrl;
  late final TextEditingController _deskripsiCtrl;
  late final TextEditingController _minOrderCtrl;
  late final TextEditingController _stokCtrl;

  // Batas harga mengikuti signed integer yang digunakan kolom harga di DB.
  static const int _hargaMinimal = 100;
  static const int _hargaMaksimal = 2147483647;
  static const int _namaMinPanjang = 3;
  static const int _namaMaksPanjang = 80;
  static const int _deskripsiMaksPanjang = 500;
  static const int _stokMaksimal = 9999;
  static const int _minOrderMaksimal = 9999;

  // Nama produk mendukung ukuran, tipe, dan penanda lain yang memakai angka.
  static final RegExp _polaKarakterNamaValid = RegExp(
    r"^[A-Za-zÀ-ÖØ-öø-ÿ0-9 .,&()/'%+-]+$",
  );
  static final RegExp _karakterNamaProduk = RegExp(
    r"[A-Za-zÀ-ÖØ-öø-ÿ0-9 .,&()/'%+-]",
  );
  // Nama tetap harus memiliki huruf agar tidak hanya berupa angka/simbol.
  static final RegExp _polaAdaHuruf = RegExp(r'[A-Za-zÀ-ÖØ-öø-ÿ]');

  int? _idKategori;

  late ModePenjualan _mode;
  late String _waktuMasak;
  final List<String> _waktuMasakOptions = const [
    'H-1 Hari',
    'H-2 Hari',
    'H-3 Hari',
    'H-7 Hari',
  ];

  late bool _tampilkanDiWarung;
  bool _menyimpan = false;

  /// Pesan "produk sudah ada" dari server, ditampilkan di bawah kolom nama.
  String? _errNamaServer;

  /// Foto baru yang dipilih pengguna (belum diunggah).
  XFile? _fotoBaru;
  Uint8List? _fotoBaruBytes;

  bool get _adaFoto =>
      _fotoBaruBytes != null ||
      (widget.produkToEdit?.gambarUrl?.isNotEmpty ?? false);

  String _ukuranFoto() {
    final b = _fotoBaruBytes?.lengthInBytes ?? 0;
    return b >= 1024 * 1024
        ? '${(b / (1024 * 1024)).toStringAsFixed(1)} MB'
        : '${(b / 1024).round()} KB';
  }

  /// Kotak pratinjau foto: menampilkan foto BARU yang baru dipilih (langsung
  /// dari memori, sebelum diunggah), atau foto lama dari server saat edit,
  /// atau tampilan kosong yang mengajak memilih foto.
  Widget _kotakFoto() {
    final urlLama = widget.produkToEdit?.gambarUrl;

    Widget isi;
    if (_fotoBaruBytes != null) {
      isi = Image.memory(
        _fotoBaruBytes!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, _, _) => const Center(
          child: Icon(Icons.broken_image_outlined, color: OC.muted, size: 40),
        ),
      );
    } else if (urlLama != null && urlLama.isNotEmpty) {
      isi = LayoutBuilder(
        builder: (context, c) => GambarJaringan(
          url: urlLama,
          width: c.maxWidth,
          height: c.maxHeight,
          radius: 0,
          ikonKosong: Icons.add_photo_alternate_outlined,
        ),
      );
    } else {
      isi = const Center(
        child: Icon(
          Icons.add_photo_alternate_outlined,
          size: 32,
          color: OC.primary,
        ),
      );
    }

    return GestureDetector(
      onTap: _fotoBaruBytes != null
          ? () => tampilkanZoomGambarLokal(context, _fotoBaruBytes!)
          : _pilihFoto,
      child: SizedBox(
        width: 96,
        height: 96,
        child: Container(
          decoration: BoxDecoration(
            color: OC.box,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: OC.line, width: 1),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              isi,
              if (!_adaFoto)
                Positioned(
                  right: 6,
                  bottom: 6,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: OC.primary,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      Icons.add_a_photo_outlined,
                      color: Colors.white,
                      size: 15,
                    ),
                  ),
                ),
              if (_fotoBaru != null)
                Positioned(
                  right: 5,
                  top: 5,
                  child: Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: () => setState(() {
                        _fotoBaru = null;
                        _fotoBaruBytes = null;
                      }),
                      customBorder: const CircleBorder(),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.close_rounded,
                          size: 15,
                          color: OC.muted,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  int get _stok => int.tryParse(_stokCtrl.text) ?? 0;

  void _ubahStok(int delta) {
    final baru = (_stok + delta).clamp(0, 99999);
    setState(() => _stokCtrl.text = baru.toString());
  }

  Future<void> _simpan({required bool tayangan}) async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _menyimpan = true;
      _errNamaServer = null;
    });
    final service = context.read<UmkmDataService>();

    try {
      final harga = int.parse(
        _hargaCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''),
      );
      final String pesan;

      if (_isEdit) {
        pesan = await service.updateProduk(
          idProduk: widget.produkToEdit!.idProduk,
          idKategori: _idKategori!,
          namaProduk: _namaCtrl.text.trim(),
          harga: harga,
          deskripsi: _deskripsiCtrl.text.trim(),
          modePenjualan: _mode,
          stok: _mode == ModePenjualan.preOrder ? 0 : _stok,
          minOrderPO: int.tryParse(_minOrderCtrl.text) ?? 0,
          waktuMasakPO: _waktuMasak,
          tampilkanDiWarung: _tampilkanDiWarung,
          gambarBaru: _fotoBaru,
        );
      } else {
        pesan = await service.tambahProduk(
          idKategori: _idKategori!,
          namaProduk: _namaCtrl.text.trim(),
          harga: harga,
          deskripsi: _deskripsiCtrl.text.trim(),
          modePenjualan: _mode,
          stok: _mode == ModePenjualan.preOrder ? 0 : _stok,
          minOrderPO: int.tryParse(_minOrderCtrl.text) ?? 0,
          waktuMasakPO: _waktuMasak,
          tampilkanDiWarung: tayangan && _tampilkanDiWarung,
          gambar: _fotoBaru,
        );
      }

      if (!mounted) return;
      pesanSukses(context, pesan);
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.field == 'nama_produk') {
        // Produk kembar: tandai kolom nama + tampilkan pesan.
        setState(() => _errNamaServer = e.pesan);
        _formKey.currentState?.validate();
      }
      pesanGagal(context, e.pesan);
    } catch (e) {
      if (mounted) pesanGagal(context, 'Gagal menyimpan: $e');
    } finally {
      if (mounted) setState(() => _menyimpan = false);
    }
  }

  @override
  void initState() {
    super.initState();
    final p = widget.produkToEdit;
    _namaCtrl = TextEditingController(text: p?.namaProduk ?? '');
    // Format harga dengan titik ribuan saat mode edit agar field terbaca jelas
    _hargaCtrl = TextEditingController(
      text: p != null
          ? p.harga.toString().replaceAllMapped(
              RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
              (m) => '${m[1]}.',
            )
          : '',
    );
    _deskripsiCtrl = TextEditingController(text: p?.deskripsi ?? '');
    _minOrderCtrl = TextEditingController(
      text: (p?.minOrderPO ?? 20).toString(),
    );
    _stokCtrl = TextEditingController(text: (p?.stok ?? 15).toString());
    _idKategori = p?.idKategori;
    final categoryService = context.read<CategoryService>();
    if (categoryService.categories.isEmpty && !categoryService.loading) {
      Future.microtask(() => categoryService.load());
    }
    _mode = p?.modePenjualan ?? ModePenjualan.keduanya;
    _waktuMasak = p?.waktuMasakPO ?? 'H-2 Hari';
    if (!_waktuMasakOptions.contains(_waktuMasak)) _waktuMasak = 'H-2 Hari';
    _tampilkanDiWarung = p?.tampilkanDiWarung ?? true;
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _hargaCtrl.dispose();
    _deskripsiCtrl.dispose();
    _minOrderCtrl.dispose();
    _stokCtrl.dispose();
    super.dispose();
  }

  Future<void> _pilihFoto() async {
    final file = await pilihGambar(context);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;

    if (bytes.lengthInBytes > 5 * 1024 * 1024) {
      pesanGagal(
        context,
        'Ukuran gambar melebihi 5 MB. Silakan pilih gambar lain.',
      );
      return;
    }

    setState(() {
      _fotoBaru = file;
      _fotoBaruBytes = bytes;
    });
  }

  bool get _isEdit => widget.isEditMode;

  InputDecoration _modernInputDecoration({
    String? hintText,
    String? counterText = '',
    String? suffixText,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: OC.faint, fontSize: 13.5),
      counterText: counterText,
      suffixText: suffixText,
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: OC.bg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: OC.primary, width: 1.5),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: OC.danger, width: 1),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: OC.danger, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F3),
      body: Stack(
        children: [
          const HeaderBotanicalBackdrop(height: 250),
          SafeArea(
            child: Column(
              children: [
                UmkmAppBar(
                  title: _isEdit ? 'Edit Produk' : 'Tambah Produk Baru',
                  leading: DjajanBackButton(
                    onPressed: () => Navigator.maybePop(context),
                  ),
                ),
                Expanded(
                  child: AbsorbPointer(
                    absorbing: _menyimpan,
                    child: Form(
                      key: _formKey,
                      child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                    children: [
                      // =================== FOTO PRODUK (UPLOAD ASLI) ===================
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: OC.line),
                        ),
                        child: Row(
                          children: [
                            _kotakFoto(),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Expanded(
                                        child: Text(
                                          'Foto produk',
                                          style: TextStyle(
                                            color: OC.ink,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      const MiniBadge(
                                        'Opsional',
                                        bg: OC.box,
                                        fg: OC.muted,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    _fotoBaru != null
                                        ? '${_fotoBaru!.name} · ${_ukuranFoto()}'
                                        : 'Foto produk membantu pelanggan mengenalinya.',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: OC.muted,
                                      fontSize: 11.5,
                                      height: 1.35,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  OutlinedButton.icon(
                                    onPressed: _pilihFoto,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: OC.primary,
                                      side: const BorderSide(color: OC.line),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 9,
                                      ),
                                      minimumSize: const Size(0, 38),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(11),
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.photo_camera_outlined,
                                      size: 16,
                                    ),
                                    label: Text(
                                      _adaFoto ? 'Ganti foto' : 'Pilih foto',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ===================== INFORMASI PRODUK ====================
                      _kartuSeksi(
                        ikon: Icons.inventory_2_outlined,
                        judul: 'Informasi Produk',
                        children: [
                          _label('Nama Produk', wajib: true),
                          TextFormField(
                            controller: _namaCtrl,
                            textCapitalization: TextCapitalization.words,
                            maxLength: _namaMaksPanjang,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                _karakterNamaProduk,
                              ),
                              LengthLimitingTextInputFormatter(
                                _namaMaksPanjang,
                              ),
                            ],
                            decoration: _modernInputDecoration(
                              hintText:
                                  'Contoh: Air Mineral 1L atau Nasi Kotak',
                            ),
                            onChanged: (_) {
                              if (_errNamaServer != null) {
                                setState(() => _errNamaServer = null);
                              }
                            },
                            validator: (v) {
                              if (_errNamaServer != null) return _errNamaServer;
                              final teks = (v ?? '').trim();
                              if (teks.isEmpty) {
                                return 'Nama produk wajib diisi';
                              }
                              if (teks.length < _namaMinPanjang) {
                                return 'Nama produk minimal $_namaMinPanjang karakter';
                              }
                              if (!_polaAdaHuruf.hasMatch(teks)) {
                                return 'Nama produk harus mengandung huruf, tidak boleh hanya angka/simbol';
                              }
                              if (!_polaKarakterNamaValid.hasMatch(teks)) {
                                return 'Gunakan huruf, angka, spasi, dan tanda baca yang umum';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          _label('Kategori Produk', wajib: true),
                          Consumer<CategoryService>(
                            builder: (context, categoryService, _) {
                              final categories = categoryService.categories;
                              final selected =
                                  categories.any((c) => c.id == _idKategori)
                                  ? _idKategori
                                  : null;
                              return DropdownButtonFormField<int>(
                                initialValue: selected,
                                isExpanded: true,
                                items: categories
                                    .map(
                                      (Category category) => DropdownMenuItem(
                                        value: category.id,
                                        child: Text(category.name),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) {
                                  if (v == null) return;
                                  setState(() {
                                    _idKategori = v;
                                  });
                                },
                                validator: (v) => v == null
                                    ? categoryService.loading
                                          ? 'Kategori sedang dimuat'
                                          : categoryService.errorMessage ??
                                                'Kategori wajib dipilih'
                                    : null,
                                decoration: _modernInputDecoration(),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          _label('Harga Produk', wajib: true),
                          TextFormField(
                            controller: _hargaCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(
                                _hargaMaksimal.toString().length,
                              ),
                              _PemformatRibuan(),
                            ],
                            decoration: _modernInputDecoration(
                              hintText: 'Contoh: 15.000',
                              prefixIcon: const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 14,
                                ),
                                child: Text(
                                  'Rp',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: OC.primary,
                                  ),
                                ),
                              ),
                            ),
                            validator: (v) {
                              final bersih = (v ?? '').replaceAll('.', '');
                              if (bersih.isEmpty) return 'Harga wajib diisi';
                              final n = int.tryParse(bersih);
                              if (n == null) return 'Harga harus berupa angka';
                              if (n < _hargaMinimal) {
                                return 'Harga minimal ${formatRupiah(_hargaMinimal)}';
                              }
                              if (n > _hargaMaksimal) {
                                return 'Harga melebihi batas maksimum sistem';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _label('Deskripsi Produk'),
                          TextFormField(
                            controller: _deskripsiCtrl,
                            maxLines: 3,
                            maxLength: _deskripsiMaksPanjang,
                            textCapitalization: TextCapitalization.sentences,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(
                                _deskripsiMaksPanjang,
                              ),
                            ],
                            decoration: _modernInputDecoration(
                              hintText: 'Jelaskan ukuran, isi, bahan, manfaat, atau keunggulan produk...',
                              counterText: null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ==================== MODE PENJUALAN ====================
                      _kartuSeksi(
                        ikon: Icons.storefront_outlined,
                        judul: 'Penjualan & ketersediaan',
                        children: [
                          const Text(
                            'Pilih cara produk tersedia untuk dipesan',
                            style: TextStyle(color: OC.muted, fontSize: 13),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _tombolMode(
                                  'Ready',
                                  Icons.bolt,
                                  ModePenjualan.ready,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _tombolMode(
                                  'Pre-Order',
                                  Icons.event_note,
                                  ModePenjualan.preOrder,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _tombolMode(
                                  'Keduanya',
                                  Icons.done_all,
                                  ModePenjualan.keduanya,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Info banner sesuai mode yang dipilih
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Container(
                              key: ValueKey(_mode),
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: _mode == ModePenjualan.ready
                                    ? const Color(0xFFE8F5E9)
                                    : _mode == ModePenjualan.preOrder
                                    ? const Color(0xFFFFF7ED)
                                    : OC.mint,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _mode == ModePenjualan.ready
                                        ? Icons.bolt_rounded
                                        : _mode == ModePenjualan.preOrder
                                        ? Icons.event_note_rounded
                                        : Icons.done_all_rounded,
                                    size: 16,
                                    color: _mode == ModePenjualan.ready
                                        ? const Color(0xFF15803D)
                                        : _mode == ModePenjualan.preOrder
                                        ? const Color(0xFFEA580C)
                                        : OC.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _mode == ModePenjualan.ready
                                          ? 'Ready Stock: produk tersedia sekarang dan bisa langsung dibeli sampai stok habis.'
                                          : _mode == ModePenjualan.preOrder
                                          ? 'Pre-Order: pelanggan memesan lebih dulu. Anda menyiapkan produk sesuai jumlah pesanan.'
                                          : 'Keduanya: produk tersedia untuk pembelian langsung dan bisa dipesan lebih awal.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _mode == ModePenjualan.ready
                                            ? const Color(0xFF15803D)
                                            : _mode == ModePenjualan.preOrder
                                            ? const Color(0xFFEA580C)
                                            : OC.primary,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          if (_mode != ModePenjualan.preOrder) ...[
                            Container(
                              padding: const EdgeInsets.fromLTRB(
                                14,
                                10,
                                10,
                                10,
                              ),
                              decoration: BoxDecoration(
                                color: OC.box,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Stok siap dijual',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          _mode == ModePenjualan.keduanya
                                              ? 'Produk tersedia untuk pembelian langsung'
                                              : 'Jumlah produk yang tersedia',
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            color: OC.muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => _ubahStok(-1),
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                      color: OC.primary,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 62,
                                    child: TextFormField(
                                      controller: _stokCtrl,
                                      textAlign: TextAlign.center,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(
                                          _stokMaksimal.toString().length,
                                        ),
                                      ],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      ),
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                      ),
                                      onChanged: (v) {
                                        final n = int.tryParse(v);
                                        if (n != null && n > _stokMaksimal) {
                                          _stokCtrl.text = _stokMaksimal
                                              .toString();
                                          _stokCtrl.selection =
                                              TextSelection.collapsed(
                                                offset: _stokCtrl.text.length,
                                              );
                                        }
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => _ubahStok(1),
                                    icon: const Icon(
                                      Icons.add_circle_outline,
                                      color: OC.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                          if (_mode != ModePenjualan.ready)
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: OC.box,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Expanded(
                                        child: Text(
                                          'Ketentuan Pre-Order',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Min. Pesanan',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                            const SizedBox(height: 4),
                                            TextFormField(
                                              controller: _minOrderCtrl,
                                              keyboardType:
                                                  TextInputType.number,
                                              inputFormatters: [
                                                FilteringTextInputFormatter
                                                    .digitsOnly,
                                                LengthLimitingTextInputFormatter(
                                                  _minOrderMaksimal
                                                      .toString()
                                                      .length,
                                                ),
                                              ],
                                              decoration:
                                                  _modernInputDecoration(
                                                    suffixText: 'Unit',
                                                  ),
                                              validator: (v) {
                                                if (_mode ==
                                                    ModePenjualan.ready) {
                                                  return null;
                                                }
                                                final n = int.tryParse(v ?? '');
                                                if (n == null || n < 1) {
                                                  return 'Minimal pesanan harus 1 unit atau lebih';
                                                }
                                                return null;
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Waktu Persiapan',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                            const SizedBox(height: 4),
                                            DropdownButtonFormField<String>(
                                              initialValue: _waktuMasak,
                                              isExpanded: true,
                                              items: _waktuMasakOptions
                                                  .map(
                                                    (w) => DropdownMenuItem(
                                                      value: w,
                                                      child: Text(w),
                                                    ),
                                                  )
                                                  .toList(),
                                              decoration:
                                                  _modernInputDecoration(),
                                              onChanged: (v) => setState(
                                                () => _waktuMasak = v!,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Container(
                        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                        decoration: BoxDecoration(
                          color: _tampilkanDiWarung
                              ? OC.primarySoft
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _tampilkanDiWarung
                                ? OC.primarySoft
                                : OC.line,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.storefront_outlined,
                                color: OC.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _tampilkanDiWarung
                                        ? 'Tayangkan produk'
                                        : 'Simpan sebagai draft',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: OC.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _tampilkanDiWarung
                                        ? 'Produk dapat dilihat pelanggan'
                                        : 'Produk belum terlihat pelanggan',
                                    style: const TextStyle(
                                      color: OC.muted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch.adaptive(
                              value: _tampilkanDiWarung,
                              activeThumbColor: OC.primary,
                              onChanged: (v) =>
                                  setState(() => _tampilkanDiWarung = v),
                            ),
                          ],
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
    ],
  ),
  bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _menyimpan
                        ? null
                        : () => _simpan(tayangan: true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: OC.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: _menyimpan
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.check_circle_outline,
                            color: Colors.white,
                          ),
                    label: Text(
                      _menyimpan
                          ? 'Menyimpan...'
                          : (_isEdit
                                ? 'Simpan Perubahan'
                                : _tampilkanDiWarung
                                ? 'Simpan & Tayangkan'
                                : 'Simpan sebagai Draft'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (!_isEdit && _tampilkanDiWarung) ...[
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: _menyimpan
                        ? null
                        : () => _simpan(tayangan: false),
                    child: const Text(
                      'Simpan tanpa menayangkan',
                      style: TextStyle(
                        color: OC.muted,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------ helper
  Widget _tombolMode(String label, IconData ikon, ModePenjualan mode) {
    final terpilih = _mode == mode;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _mode = mode),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
          decoration: BoxDecoration(
            color: terpilih ? OC.primarySoft : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: terpilih ? OC.primary : OC.line,
              width: terpilih ? 1.4 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(ikon, color: terpilih ? OC.primary : OC.muted, size: 19),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: terpilih ? OC.primary : OC.muted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kartuSeksi({
    required IconData ikon,
    required String judul,
    required List<Widget> children,
  }) {
    return Container(
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
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: OC.primarySoft,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(ikon, color: OC.primary, size: 19),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  judul,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: OC.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _label(String teks, {bool wajib = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          children: [
            TextSpan(text: teks),
            if (wajib)
              const TextSpan(
                text: ' *',
                style: TextStyle(color: AppColors.danger),
              ),
          ],
        ),
      ),
    );
  }
}

/// Menambahkan titik pemisah ribuan otomatis agar harga mudah dibaca.
class _PemformatRibuan extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitOnly.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final angka = int.parse(digitOnly);
    final teksBaru = _formatRibuan(angka);

    return TextEditingValue(
      text: teksBaru,
      selection: TextSelection.collapsed(offset: teksBaru.length),
    );
  }

  String _formatRibuan(int n) {
    final s = n.toString();
    final buffer = StringBuffer();
    int hitung = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      buffer.write(s[i]);
      hitung++;
      if (hitung % 3 == 0 && i != 0) buffer.write('.');
    }
    return buffer.toString().split('').reversed.join();
  }
}
