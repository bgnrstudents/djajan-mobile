import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'order_model.dart';
import 'order_service.dart';
import 'order_detail_screen.dart';
import 'order_widgets.dart';

/// Tahap 2 alur pesanan: Proses Checkout (transfer + unggah bukti pembayaran).
class OrderPaymentScreen extends StatefulWidget {
  final String orderId;

  const OrderPaymentScreen({super.key, required this.orderId});

  @override
  State<OrderPaymentScreen> createState() => _OrderPaymentScreenState();
}

class _OrderPaymentScreenState extends State<OrderPaymentScreen> {
  final OrderService _service = OrderService();
  final ImagePicker _picker = ImagePicker();

  Uint8List? _proofBytes;
  String? _proofName;
  bool _guideOpen = true;
  bool _submitting = false;

  Order? get _order => _service.findById(widget.orderId);

  @override
  void initState() {
    super.initState();
    // Jika membuka ulang untuk mengganti bukti, tampilkan bukti lama.
    final o = _order;
    if (o != null && o.hasProof) {
      _proofBytes = o.proofBytes;
      _proofName = o.proofName;
    }
  }

  // --------------------------------------------------------------- upload

  Future<void> _chooseSource() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pilih Bukti Transfer',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700, color: OC.ink)),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const IconBadge(
                    icon: Icons.photo_library_outlined,
                    bg: OC.mint,
                    fg: OC.mintText,
                    size: 42),
                title: const Text('Galeri / File',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Pilih screenshot atau foto struk'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const IconBadge(
                    icon: Icons.photo_camera_outlined,
                    bg: OC.mint,
                    fg: OC.mintText,
                    size: 42),
                title: const Text('Kamera',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Foto struk ATM langsung'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );
    if (source != null) await _pick(source);
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (file == null) return; // dibatalkan pengguna

      final name = file.name.toLowerCase();
      final okExt = name.endsWith('.jpg') ||
          name.endsWith('.jpeg') ||
          name.endsWith('.png') ||
          (file.mimeType ?? '').startsWith('image/');
      if (!okExt) {
        if (mounted) showToast(context, 'Format harus JPG atau PNG.', error: true);
        return;
      }

      final bytes = await file.readAsBytes();
      if (bytes.length > OrderService.maxProofBytes) {
        if (mounted) showToast(context, 'Ukuran file maksimal 5MB.', error: true);
        return;
      }

      if (!mounted) return;
      setState(() {
        _proofBytes = bytes;
        _proofName = file.name;
      });
    } catch (e) {
      if (mounted) {
        showToast(
            context, 'Tidak dapat membuka foto. Periksa izin galeri/kamera.',
            error: true);
      }
    }
  }

  Future<void> _confirm() async {
    final isCod = _order?.paymentMethod == PaymentMethod.cod;
    final bytes = _proofBytes;
    if (!isCod && bytes == null) {
      showToast(context, 'Unggah bukti transfer terlebih dahulu.', error: true);
      return;
    }
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final o = isCod
          ? await _service.confirmCodOrder(widget.orderId)
          : await _service.submitPaymentProof(
              widget.orderId,
              bytes: bytes!,
              fileName: _proofName ?? 'bukti_transfer.jpg',
            );
      if (!mounted) return;
      // Lanjut ke Status Pesanan; tombol kembali menuju daftar pesanan.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: o.id)),
        (route) => route.isFirst,
      );
    } on OrderException catch (e) {
      if (mounted) showToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ------------------------------------------------------------------ UI

  @override
  Widget build(BuildContext context) {
    final order = _order;
    if (order == null) {
      return const Scaffold(body: Center(child: Text('Pesanan tidak ditemukan')));
    }

    final isCod = order.paymentMethod == PaymentMethod.cod;
    return Scaffold(
      backgroundColor: OC.bg,
      body: Column(
        children: [
          OrderHeader(
            title: 'Proses Checkout',
            trailing: const CircleAvatar(
              radius: 20,
              backgroundColor: OC.primary,
              child: Icon(Icons.person_outline, color: Colors.white),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              children: [
                _statusRow(order),
                const SizedBox(height: 14),
                _totalCard(order),
                const SizedBox(height: 22),
                _sectionTitle('Metode Pembayaran',
                    chip: isCod ? 'Bayar di Tempat (COD)' : 'Transfer Bank Manual'),
                const SizedBox(height: 10),
                if (isCod) _codCard(order) else _bankCard(order),
                if (!isCod) ...[
                  const SizedBox(height: 22),
                  _sectionTitle('Unggah Bukti Transfer', chipText: 'Wajib'),
                  const SizedBox(height: 10),
                  _uploadCard(),
                ],
                const SizedBox(height: 18),
                _guideCard(),
              ],
            ),
          ),
          _bottomBar(order),
        ],
      ),
    );
  }

  Widget _statusRow(Order o) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(color: Color(0xFF1B8A2E), shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
            o.paymentMethod == PaymentMethod.cod
                ? 'Menunggu Konfirmasi'
                : 'Menunggu Pembayaran',
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0B6A1F))),
        const Spacer(),
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => openWhatsApp(
            context,
            phone: kUmkmWhatsApp,
            message: 'Halo, saya butuh bantuan untuk pesanan ${o.refId}.',
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
                color: OC.box, borderRadius: BorderRadius.circular(20)),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.chat_outlined, size: 16, color: OC.primary),
                SizedBox(width: 6),
                Text('Bantuan UMKM',
                    style: TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w700, color: OC.ink)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _copyChip(String label, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
            color: OC.box, borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.content_copy_outlined, size: 17, color: OC.primary),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: OC.primary)),
          ],
        ),
      ),
    );
  }

  Widget _totalCard(Order o) {
    final deadline = o.paymentDeadline;
    return OrderCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TOTAL TAGIHAN',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: OC.muted)),
                    const SizedBox(height: 8),
                    Text(rupiah(o.total),
                        style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: OC.primary,
                            height: 1.1)),
                  ],
                ),
              ),
              _copyChip(
                  'Salin',
                  () => copyText(context, o.total.round().toString(),
                      'Nominal berhasil disalin!')),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: OC.box, borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('No. Pesanan:',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600, color: OC.muted)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(o.refId,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: OC.ink)),
                    ),
                    InkWell(
                      onTap: () => copyText(
                          context, o.refId, 'Nomor pesanan berhasil disalin!'),
                      child: const Icon(Icons.content_copy_outlined,
                          size: 20, color: OC.primary),
                    ),
                  ],
                ),
                if (deadline != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 18, color: OC.amber),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text('Bayar sebelum: ${fmtDateComma(deadline)}',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: OC.amber)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.storefront_outlined, size: 20, color: OC.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: const TextStyle(fontSize: 13, color: OC.ink),
                    children: [
                      TextSpan(
                          text: '${o.vendors.length} Pesanan UMKM: ',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      TextSpan(
                          text: o.vendorNames,
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, {String? chip, String? chipText}) {
    final c = chip ?? chipText;
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(title,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w700, color: OC.ink)),
        ),
        const Spacer(),
        if (chip != null)
          Pill(text: c!, bg: OC.box, fg: OC.primary, fontSize: 12)
        else if (c != null)
          Text(c,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: OC.muted)),
      ],
    );
  }

  Widget _bankCard(Order o) {
    final a = o.account;
    return OrderCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: const Color(0xFFDDE3FA),
                    borderRadius: BorderRadius.circular(14)),
                child: Text(a.bank,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A4BA0))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bank ${a.bank}',
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w700, color: OC.ink)),
                    Text(a.bankFullName,
                        style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: OC.muted)),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                    color: const Color(0xFFA6F2B4),
                    borderRadius: BorderRadius.circular(8)),
                child: const Text('Terverifikasi',
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: OC.mintText)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: OC.box, borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Nomor Rekening Tujuan',
                          style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: OC.muted)),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(a.number,
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                                color: OC.ink)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => copyText(
                      context,
                      a.number.replaceAll('-', ''),
                      'Nomor rekening berhasil disalin!'),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                        color: OC.primary, borderRadius: BorderRadius.circular(10)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.content_copy_outlined, size: 16, color: Colors.white),
                        SizedBox(width: 6),
                        Text('Salin',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: [
                const Text('Nama Penerima',
                    style: TextStyle(fontSize: 14, color: OC.muted)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(a.holder,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700, color: OC.ink)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: OC.box, borderRadius: BorderRadius.circular(14)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 20, color: OC.amber),
                const SizedBox(width: 8),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: const TextStyle(
                          fontSize: 13.5, color: OC.muted, height: 1.35),
                      children: [
                        const TextSpan(text: 'Pastikan mentransfer sesuai nominal tepat '),
                        TextSpan(
                            text: rupiah(o.total),
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, color: OC.ink)),
                        const TextSpan(
                            text:
                                ' agar bendahara UMKM desa dapat memverifikasi pesanan Anda secara otomatis dan instan.'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _codCard(Order o) {
    return OrderCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              IconBadge(
                  icon: Icons.handshake_outlined,
                  bg: OC.mint,
                  fg: OC.mintText,
                  size: 52),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bayar Tunai Saat Pesanan Tiba',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: OC.ink)),
                    Text('Tidak perlu transfer atau unggah bukti',
                        style: TextStyle(fontSize: 12.5, color: OC.muted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: OC.box, borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Siapkan uang pas sebesar',
                    style: TextStyle(fontSize: 12.5, color: OC.muted)),
                Text(rupiah(o.total),
                    style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: OC.ink)),
                const SizedBox(height: 8),
                for (final v in o.vendors)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                            v.delivery == DeliveryMethod.courier
                                ? Icons.two_wheeler
                                : Icons.storefront_outlined,
                            size: 18,
                            color: OC.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            v.delivery == DeliveryMethod.courier
                                ? '${v.umkmName}: bayar ke kurir warga saat pesanan tiba'
                                : '${v.umkmName}: bayar langsung di ${v.pickupLocation} saat mengambil',
                            style: const TextStyle(
                                fontSize: 13.5, color: OC.ink, height: 1.3),
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
    );
  }

  Widget _uploadCard() {
    final bytes = _proofBytes;
    return OrderCard(
      padding: const EdgeInsets.all(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: OC.box, borderRadius: BorderRadius.circular(16)),
        child: bytes == null ? _uploadEmpty() : _uploadPreview(bytes),
      ),
    );
  }

  Widget _uploadEmpty() {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: _chooseSource,
      child: Column(
        children: [
          const SizedBox(height: 4),
          Container(
            width: 74,
            height: 74,
            decoration: const BoxDecoration(color: OC.mint, shape: BoxShape.circle),
            child: const Icon(Icons.add_a_photo_outlined, size: 34, color: OC.primary),
          ),
          const SizedBox(height: 14),
          const Text('Ketuk untuk Mengunggah Foto',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 19, fontWeight: FontWeight.w700, color: OC.ink)),
          const SizedBox(height: 8),
          const Text(
              'Pilih foto struk ATM, bukti m-Banking, atau screenshot transfer. Mendukung format JPG/PNG (Maks. 5MB).',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: OC.muted, height: 1.35)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
                color: const Color(0xFFDDE1F5),
                borderRadius: BorderRadius.circular(12)),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_upload_outlined, size: 22, color: OC.primary),
                SizedBox(width: 8),
                Text('Pilih Foto / File',
                    style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: OC.primary)),
              ],
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _uploadPreview(Uint8List bytes) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: Image.memory(bytes, fit: BoxFit.contain, width: double.infinity),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.check_circle, color: OC.primary, size: 20),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '${_proofName ?? 'bukti_transfer'} • ${(bytes.length / 1024).round()} KB',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: OC.ink),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _chooseSource,
                icon: const Icon(Icons.swap_horiz_rounded),
                label: const Text('Ganti Foto'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: OC.primary,
                  side: const BorderSide(color: OC.primary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => setState(() {
                  _proofBytes = null;
                  _proofName = null;
                }),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Hapus'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: OC.danger,
                  side: const BorderSide(color: OC.danger),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _guideCard() {
    final o = _order!;
    Widget step(int n, String title, String body) => Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                    color: Color(0xFFDDE3FA), shape: BoxShape.circle),
                child: Text('$n',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, color: Color(0xFF1A4BA0))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700, color: OC.ink)),
                    Text(body,
                        style: const TextStyle(
                            fontSize: 13.5, color: OC.muted, height: 1.35)),
                  ],
                ),
              ),
            ],
          ),
        );

    return OrderCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _guideOpen = !_guideOpen),
            child: Row(
              children: [
                const Icon(Icons.help_outline, color: OC.primary),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Panduan Pembayaran',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w700, color: OC.ink)),
                ),
                Icon(_guideOpen
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded),
              ],
            ),
          ),
          if (_guideOpen) ...[
            if (o.paymentMethod == PaymentMethod.cod) ...[
              step(1, 'Siapkan Uang Pas',
                  'Siapkan nominal sesuai total tagihan agar transaksi lancar.'),
              step(2, 'Terima Pesanan',
                  'Kurir warga mengantar pesanan, atau ambil sendiri di UMKM.'),
              step(3, 'Bayar & Konfirmasi',
                  'Serahkan pembayaran saat pesanan diterima, lalu tekan "Konfirmasi Pesanan" di bawah.'),
            ] else ...[
              step(1, 'Transfer ke Rekening ${o.account.bank}',
                  'Gunakan m-Banking, ATM, atau SMS banking menuju rekening tertera di atas.'),
              step(2, 'Simpan Bukti Struk',
                  'Ambil tangkapan layar m-banking yang memuat detail waktu dan nomor referensi.'),
              step(3, 'Unggah & Konfirmasi',
                  'Masukkan file pada kolom di atas, lalu tekan tombol "Konfirmasi Pembayaran" di bawah.'),
            ],
          ],
        ],
      ),
    );
  }

  Widget _bottomBar(Order o) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).padding.bottom + 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Color(0x14000000), blurRadius: 14, offset: Offset(0, -3)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('TOTAL BAYAR',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                            color: OC.muted)),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(rupiah(o.total),
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: OC.primary)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 56,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: OC.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _submitting ? null : _confirm,
                  icon: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_circle_outline),
                  label: Text(
                      o.paymentMethod == PaymentMethod.cod
                          ? 'Konfirmasi Pesanan'
                          : 'Konfirmasi Pembayaran',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified_user_outlined, size: 16, color: OC.primary),
              SizedBox(width: 6),
              Flexible(
                child: Text('Pembayaran aman & langsung disalurkan ke UMKM Desa',
                    style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: OC.ink)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
