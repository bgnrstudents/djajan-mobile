import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/umkm_models.dart';
import '../../services/api_service.dart';
import '../../services/umkm_data_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
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

  // -------------------------------------------------- batas validasi form
  // Dikumpulkan di satu tempat supaya mudah disesuaikan tanpa menelusuri
  // seluruh file. Tujuannya mencegah human error saat mengisi form, mis.
  // harga kepencet angka nol kelebihan (Rp999.999.999) atau nama produk
  // yang isinya cuma angka/simbol.
  static const int _hargaMinimal = 100; // Rp100 — di bawah ini kemungkinan salah ketik
  static const int _hargaMaksimal = 1000000; // Rp1.000.000 / porsi
  static const int _namaMinPanjang = 3;
  static const int _namaMaksPanjang = 80;
  static const int _deskripsiMaksPanjang = 500;
  static const int _stokMaksimal = 9999;
  static const int _minOrderMaksimal = 9999;

  // Huruf (termasuk huruf beraksen), spasi, dan tanda baca umum pada nama
  // makanan: & - ' ( ) , .  — TIDAK boleh angka maupun simbol @#$%^*_+=<>\n
  static final RegExp _polaKarakterNamaValid =
      RegExp(r'^[A-Za-zÀ-ÖØ-öø-ÿ .,&()\-]+$');
  static final RegExp _polaAdaAngka = RegExp(r'[0-9]');
  // Minimal ada satu huruf, supaya nama tidak bisa diisi angka/simbol saja
  // (mis. "999999999" atau "!!!!!").
  static final RegExp _polaAdaHuruf = RegExp(r'[A-Za-zÀ-ÖØ-öø-ÿ]');

  late String _kategori;
  final List<String> _kategoriOptions = const [
    'Makanan & Catering',
    'Jajan Pasar',
    'Minuman',
    'Kue & Roti',
    'Sembako',
  ];

  late ModePenjualan _mode;
  late String _waktuMasak;
  final List<String> _waktuMasakOptions = const [
    'H-1 Hari',
    'H-2 Hari',
    'H-3 Hari',
    'H-7 Hari'
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
          child: Icon(Icons.broken_image_outlined,
              color: OC.muted, size: 40),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_photo_alternate_outlined,
                size: 44, color: OC.primary),
            SizedBox(height: 8),
            Text('Ketuk untuk memilih foto',
                style: TextStyle(
                    color: OC.primary, fontWeight: FontWeight.w600)),
            SizedBox(height: 2),
            Text('dari galeri atau kamera',
                style: TextStyle(color: OC.muted, fontSize: 12)),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: _fotoBaruBytes != null
          ? () => tampilkanZoomGambarLokal(context, _fotoBaruBytes!)
          : _pilihFoto,
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: Container(
          decoration: BoxDecoration(
            color: OC.box,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.garis),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              isi,
              if (_fotoBaru != null)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: OC.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Foto baru',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700)),
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
      final harga = int.parse(_hargaCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''));
      final String pesan;

      if (_isEdit) {
        pesan = await service.updateProduk(
          idProduk: widget.produkToEdit!.idProduk,
          namaProduk: _namaCtrl.text.trim(),
          kategori: _kategori,
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
          namaProduk: _namaCtrl.text.trim(),
          kategori: _kategori,
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
    _hargaCtrl =
        TextEditingController(text: p != null ? p.harga.toString() : '');
    _deskripsiCtrl = TextEditingController(text: p?.deskripsi ?? '');
    _minOrderCtrl =
        TextEditingController(text: (p?.minOrderPO ?? 20).toString());
    _stokCtrl = TextEditingController(text: (p?.stok ?? 15).toString());
    _kategori = p?.kategori ?? 'Makanan & Catering';
    if (!_kategoriOptions.contains(_kategori)) _kategori = _kategoriOptions.first;
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
      pesanGagal(context, 'Ukuran gambar melebihi 5 MB. Silakan pilih gambar lain.');
      return;
    }

    setState(() {
      _fotoBaru = file;
      _fotoBaruBytes = bytes;
    });
  }

  bool get _isEdit => widget.isEditMode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      body: SafeArea(
        child: Column(
          children: [
            DjajanPageHeader(
              title: _isEdit ? 'Edit Produk' : 'Tambah Produk Baru',
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: OC.muted),
                onPressed: () => Navigator.maybePop(context),
              ),
            ),
            Expanded(
              child: AbsorbPointer(
                absorbing: _menyimpan,
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                    children: [
              // =================== FOTO PRODUK (UPLOAD ASLI) ===================
              KartuPutih(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Foto Produk',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16)),
                    const SizedBox(height: 12),
                    _kotakFoto(),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pilihFoto,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: OC.primary,
                              side: const BorderSide(color: OC.primary),
                              minimumSize: const Size.fromHeight(44),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.photo_camera_outlined,
                                size: 18),
                            label: Text(_adaFoto ? 'Ganti Foto' : 'Pilih Foto'),
                          ),
                        ),
                        if (_fotoBaru != null) ...[
                          const SizedBox(width: 10),
                          OutlinedButton.icon(
                            onPressed: () => setState(() {
                              _fotoBaru = null;
                              _fotoBaruBytes = null;
                            }),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.danger,
                              side: const BorderSide(color: AppColors.danger),
                              minimumSize: const Size(0, 44),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.close, size: 18),
                            label: const Text('Batal'),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _fotoBaru != null
                          ? '${_fotoBaru!.name} • ${_ukuranFoto()} — akan diunggah saat disimpan'
                          : 'Format JPG, PNG, atau WEBP, maksimal 5 MB',
                      style: TextStyle(
                        color: _fotoBaru != null
                            ? OC.primary
                            : OC.muted,
                        fontSize: 12,
                        fontWeight: _fotoBaru != null
                            ? FontWeight.w600
                            : FontWeight.w400),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ===================== INFORMASI PRODUK ====================
              _kartuSessi(
                ikon: Icons.restaurant_menu,
                judul: 'Informasi Produk',
                children: [
                  _label('Nama Produk', wajib: true),
                  TextFormField(
                    controller: _namaCtrl,
                    textCapitalization: TextCapitalization.words,
                    maxLength: _namaMaksPanjang,
                    inputFormatters: [
                      // Memblokir simbol aneh (@#$%^*_+=<>[]{}|\\~`!?;:) saat
                      // diketik, bukan cuma ditolak belakangan saat submit.
                      FilteringTextInputFormatter.allow(_polaKarakterNamaValid),
                      LengthLimitingTextInputFormatter(_namaMaksPanjang),
                    ],
                    decoration: InputDecoration(
                      hintText: 'Contoh: Nasi Kotak Ayam Geprek Spesial',
                      counterText: '',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFDADCE6)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFDADCE6)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: OC.primary, width: 1.6),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.danger),
                      ),
                    ),
                    onChanged: (_) {
                      if (_errNamaServer != null) {
                        setState(() => _errNamaServer = null);
                      }
                    },
                    validator: (v) {
                      if (_errNamaServer != null) return _errNamaServer;
                      final teks = (v ?? '').trim();
                      if (teks.isEmpty) return 'Nama produk wajib diisi';
                      if (teks.length < _namaMinPanjang) {
                        return 'Nama produk minimal $_namaMinPanjang karakter';
                      }
                      if (!_polaAdaHuruf.hasMatch(teks)) {
                        return 'Nama produk harus mengandung huruf, tidak boleh hanya angka/simbol';
                      }
                      if (_polaAdaAngka.hasMatch(teks)) {
                        return 'Nama produk tidak boleh mengandung angka';
                      }
                      if (!_polaKarakterNamaValid.hasMatch(teks)) {
                        return "Hanya boleh huruf, spasi, dan tanda & - ' ( ) , .";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _label('Kategori Produk', wajib: true),
                  DropdownButtonFormField<String>(
                    initialValue: _kategori,
                    isExpanded: true,
                    items: _kategoriOptions
                        .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                        .toList(),
                    onChanged: (v) => setState(() => _kategori = v!),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFDADCE6)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFDADCE6)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: OC.primary, width: 1.6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _label('Harga Satuan', wajib: true),
                  TextFormField(
                    controller: _hargaCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      // Maksimal 7 digit supaya angka tidak bisa "kebablasan".
                      LengthLimitingTextInputFormatter(7),
                      _PemformatRibuan(),
                    ],
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFDADCE6)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFDADCE6)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: OC.primary, width: 1.6),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.danger),
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
                        return 'Harga maksimal ${formatRupiah(_hargaMaksimal)}';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _label('Deskripsi Menu'),
                  TextFormField(
                    controller: _deskripsiCtrl,
                    maxLines: 3,
                    maxLength: _deskripsiMaksPanjang,
                    textCapitalization: TextCapitalization.sentences,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(_deskripsiMaksPanjang),
                    ],
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      hintText: 'Ceritakan bahan & keunggulan produk...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFDADCE6)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFDADCE6)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: OC.primary, width: 1.6),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ==================== MODE PENJUALAN ====================
              _kartuSessi(
                ikon: Icons.tune,
                judul: 'Mode Penjualan Warung',
                children: [
                  const Text(
                      'Sesuaikan kesiapan dapur & kapasitas produksi Anda',
                      style:
                          TextStyle(color: OC.muted, fontSize: 13)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
      Expanded(
          child: _tombolMode('Ready', Icons.bolt, ModePenjualan.ready)),
      const SizedBox(width: 8),
      Expanded(
          child: _tombolMode('Pre-Order', Icons.event_note,
              ModePenjualan.preOrder)),
      const SizedBox(width: 8),
      Expanded(
          child: _tombolMode('Keduanya', Icons.done_all,
              ModePenjualan.keduanya)),
    ],
                  ),
                  const SizedBox(height: 14),
                  if (_mode != ModePenjualan.preOrder) ...[
                    Container(
                      padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
                      decoration: BoxDecoration(
                        color: OC.box,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text('Stok Ready Hari Ini',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                          IconButton(
                            onPressed: () => _ubahStok(-1),
                            icon: const Icon(Icons.remove_circle_outline),
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
                                    _stokMaksimal.toString().length),
                              ],
                              style: const TextStyle(fontWeight: FontWeight.w800),
                              decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(vertical: 10)),
                              onChanged: (v) {
                                final n = int.tryParse(v);
                                if (n != null && n > _stokMaksimal) {
                                  _stokCtrl.text = _stokMaksimal.toString();
                                  _stokCtrl.selection = TextSelection.collapsed(
                                      offset: _stokCtrl.text.length);
                                }
                              },
                            ),
                          ),
                          IconButton(
                            onPressed: () => _ubahStok(1),
                            icon: const Icon(Icons.add_circle_outline),
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
                              Expanded(
                                child: Text('Ketentuan Pre-Order (PO Acara)',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w700)),
                              ),
                              MiniBadge('Catering',
                                  bg: OC.peach,
                                  fg: OC.amber),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Min. Order',
                                          style: TextStyle(fontSize: 12)),
                                      const SizedBox(height: 4),
                                      TextFormField(
                                        controller: _minOrderCtrl,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly,
                                          LengthLimitingTextInputFormatter(
                                              _minOrderMaksimal
                                                  .toString()
                                                  .length),
                                        ],
                                        decoration: const InputDecoration(
                                            suffixText: 'Porsi'),
                                        validator: (v) {
                                          if (_mode == ModePenjualan.ready) {
                                            return null;
                                          }
                                          final n = int.tryParse(v ?? '');
                                          if (n == null || n < 1) {
                                            return 'Minimal order harus 1 porsi atau lebih';
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
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Waktu Masak',
                                          style: TextStyle(fontSize: 12)),
                                      const SizedBox(height: 4),
                                      DropdownButtonFormField<String>(
                                        initialValue: _waktuMasak,
                                        isExpanded: true,
                                        items: _waktuMasakOptions
                                            .map((w) => DropdownMenuItem(
                                                value: w, child: Text(w)))
                                            .toList(),
                                        onChanged: (v) => setState(() => _waktuMasak = v!),
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

              KartuPutih(
                radius: 16,
                child: Row(
                  children: [
                    const Icon(Icons.storefront, color: OC.primary),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tampilkan di Warung',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                          Text('Produk langsung terlihat oleh pembeli sekitar',
                              style: TextStyle(
                                  color: OC.muted, fontSize: 12)),
                        ],
                      ),
                    ),
                    Switch(
                      value: _tampilkanDiWarung,
                      activeThumbColor: OC.primary,
                      onChanged: (v) => setState(() => _tampilkanDiWarung = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: OC.mint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.eco, color: OC.primary, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Bahan pangan bersumber langsung dari kelompok tani mitra binaan Djajan UMKM.',
                        style: TextStyle(fontSize: 12.5),
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
  ],
),
),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              if (!_isEdit) ...[
                Container(
                  decoration: BoxDecoration(
                    color: OC.box,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: IconButton(
                    onPressed:
                        _menyimpan ? null : () => _simpan(tayangan: false),
                    icon: const Icon(Icons.bookmark_border,
                        color: OC.primary),
                    tooltip: 'Simpan sebagai draft (belum tayang)',
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _menyimpan ? null : () => _simpan(tayangan: true),
                  icon: _menyimpan
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(_menyimpan
                      ? 'Menyimpan ke database...'
                      : (_isEdit ? 'Simpan Perubahan' : 'Simpan & Tayangkan')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------ helper
  Widget _tombolMode(String label, IconData ikon, ModePenjualan mode) {
    final terpilih = _mode == mode;
    return GestureDetector(
      onTap: () => setState(() => _mode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: terpilih ? OC.primary : OC.box,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(ikon,
                color: terpilih ? Colors.white : OC.muted, size: 20),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    color: terpilih ? Colors.white : OC.muted,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5)),
          ],
        ),
      ),
    );
  }

  Widget _kartuSessi({
    required IconData ikon,
    required String judul,
    required List<Widget> children,
  }) {
    return KartuPutih(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(ikon, color: OC.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(judul,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 16.5)),
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
              fontSize: 14),
          children: [
            TextSpan(text: teks),
            if (wajib)
              const TextSpan(
                  text: ' *', style: TextStyle(color: AppColors.danger)),
          ],
        ),
      ),
    );
  }
}

/// Menambahkan titik pemisah ribuan otomatis saat mengetik harga
/// (mis. "18500" -> "18.500"), supaya UMKM langsung sadar kalau tidak
/// sengaja mengetik angka kelebihan nol sebelum menekan simpan.
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