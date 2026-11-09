import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../models/order.dart';
import '../../../services/catalog_service.dart';
import '../../../services/map_navigation_service.dart';
import '../../../services/order_service.dart';
import '../../../services/receipt_pdf_service.dart';
import '../../../widgets/order_delivery_map_card.dart';
import 'order_payment_screen.dart';
import 'midtrans_payment_screen.dart';
import 'order_widgets.dart';

/// Tahap 3 alur pesanan: Status Pesanan.
///
/// Susunan halaman:
///   1. satu blok status  -> banner (tag, chip, headline, aksi) menyatu dengan
///      tahapan pesanan, supaya informasi status tidak diulang dua kali;
///   2. satu kartu per UMKM -> produk + pengantaran digabung, tidak lagi
///      dipisah menjadi dua daftar yang saling menyilang;
///   3. bukti bayar (jika ada);
///   4. rincian pembayaran;
///   5. aksi (hubungi UMKM, struk, batalkan/hapus).
class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen>
    with WidgetsBindingObserver {
  final OrderService _service = OrderService();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _syncPaymentStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncPaymentStatus();
    }
  }

  Future<void> _syncPaymentStatus({bool showMessage = false}) async {
    try {
      await _service.syncOrder(widget.orderId);
      final order = _service.findById(widget.orderId);
      if (order?.paymentMethod == PaymentMethod.midtrans &&
          order?.status == OrderStatus.waitingPayment) {
        await _service.refreshPaymentStatusUntilSettled(widget.orderId);
      }
      if (mounted) {
        setState(() {});
        if (showMessage) {
          showToast(context, 'Status pesanan berhasil diperbarui.');
        }
      }
    } catch (_) {
      // The existing order view remains available if status sync is temporarily unavailable.
    }
  }

  // -------------------------------------------------------------- actions

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } on OrderException catch (e) {
      if (mounted) showToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel(Order o) async {
    final reasonController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(o.hasPreOrder ? 'Batalkan PO?' : 'Batalkan Pesanan?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pesanan ${o.refId} akan dibatalkan dan tidak dapat dikembalikan.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: 'Alasan pembatalan (opsional)',
                hintStyle: const TextStyle(fontSize: 13, color: OC.muted),
                filled: true,
                fillColor: const Color(0xFFF9F9F9),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: OC.line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: OC.line),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Tidak'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: OC.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final reason = reasonController.text.trim();
    await _run(() async {
      await _service.cancelOrder(o.id, reason: reason.isNotEmpty ? reason : null);
      if (mounted) showToast(context, 'Pesanan berhasil dibatalkan.');
    });
  }

  Future<void> _confirmReceived(Order o) async {
    final main = o.mainVendor;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 24),
            SizedBox(width: 8),
            Text('Pesanan Diterima?'),
          ],
        ),
        content: Text(
          'Apakah Anda sudah menerima seluruh pesanan dari ${main.umkmName} dengan baik dan sesuai?\n\nTindakan ini akan menyelesaikan transaksi.',
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Belum', style: TextStyle(color: OC.muted)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Sudah Diterima'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    await _run(() async {
      await _service.completeOrder(o.id);
      if (!mounted) return;
      showToast(context, 'Pesanan selesai! Terima kasih telah berbelanja.');
      _showRatingDialog(o);
    });
  }

  void _showRatingDialog(Order o) {
    int rating = 5;
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Beri Ulasan ${_shortName(o.mainVendor.umkmName)}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Bagaimana kualitas makanan & layanan yang Anda terima?',
                style: TextStyle(fontSize: 13, color: OC.muted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final star = index + 1;
                  return IconButton(
                    icon: Icon(
                      star <= rating ? Icons.star : Icons.star_border,
                      color: const Color(0xFFF59E0B),
                      size: 32,
                    ),
                    onPressed: () => setModalState(() => rating = star),
                  );
                }),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: noteCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Tulis ulasan singkat (opsional)',
                  hintStyle: const TextStyle(fontSize: 12.5, color: OC.muted),
                  filled: true,
                  fillColor: const Color(0xFFF9F9F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: OC.line),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Nanti Saja'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: OC.primary),
              onPressed: () {
                Navigator.pop(ctx);
                showToast(context, 'Terima kasih atas penilaian Anda!');
              },
              child: const Text('Kirim Ulasan'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(Order o) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus riwayat pesanan?'),
        content: Text('${o.refId} akan dihapus dari daftar pesanan Anda.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: OC.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _run(() async {
      await _service.deleteOrder(o.id);
      if (mounted) Navigator.pop(context);
    });
  }

  Future<void> _editRecipient(Order o) async {
    final r = await showRecipientSheet(context, o.recipient);
    if (r == null) return;
    await _run(() async {
      await _service.updateRecipient(o.id, r);
      if (mounted) showToast(context, 'Alamat penerima diperbarui.');
    });
  }

  void _share(Order o) {
    final link = 'https://djajan.id/pesanan/${o.refId.replaceAll('#', '')}';
    copyText(context, link, 'Tautan berhasil disalin!');
  }

  String _receiptText(Order o) {
    final b = StringBuffer()
      ..writeln('        STRUK DIGITAL DJAJAN        ')
      ..writeln('      --------------------------    ')
      ..writeln('Ref ID   : ${o.refId}')
      ..writeln('Tanggal  : ${fmtDateComma(o.createdAt)}')
      ..writeln('Status   : ${o.status.label.toUpperCase()}')
      ..writeln('====================================');

    for (final v in o.vendors) {
      b.writeln(v.umkmName.toUpperCase());
      for (final i in v.items) {
        final name = i.productName.length > 20
            ? '${i.productName.substring(0, 17)}...'
            : i.productName.padRight(20);
        b.writeln('$name ${i.quantity}x ${rupiah(i.price)}');
        b.writeln('                     = ${rupiah(i.subtotal)}');
      }
      if (v.deliveryFee > 0) {
        b.writeln('Ongkir (${v.umkmName}) : ${rupiah(v.deliveryFee)}');
      }
      b.writeln('------------------------------------');
    }

    b
      ..writeln('RINGKASAN PEMBAYARAN')
      ..writeln('Subtotal : ${rupiah(o.subtotal).padLeft(19)}')
      ..writeln('Ongkir   : ${rupiah(o.shippingTotal).padLeft(19)}')
      ..writeln('Layanan  : ${rupiah(o.serviceFee).padLeft(19)}');

    if (o.discount > 0) {
      b.writeln('Diskon   : -${rupiah(o.discount).padLeft(18)}');
    }

    b
      ..writeln('====================================')
      ..writeln('TOTAL    : ${rupiah(o.total).padLeft(19)}')
      ..writeln('====================================')
      ..writeln('')
      ..writeln('PENERIMA')
      ..writeln('Nama     : ${o.recipient.name}')
      ..writeln('Telepon  : ${o.recipient.phone}')
      ..writeln('Alamat   : ${o.recipient.address}');

    if (o.recipient.addressNote != null) {
      b.writeln('Patokan  : ${o.recipient.addressNote}');
    }

    b
      ..writeln('')
      ..writeln('      TERIMA KASIH TELAH BERBELANJA ')
      ..writeln('         DJAJAN - DARI DESA         ');

    return b.toString();
  }

  void _showReceipt(Order o) {
    final text = _receiptText(o);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, color: OC.primary, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Struk Digital',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: OC.ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Center(
                child: Image.asset(
                  'assets/images/logoNoBg.png',
                  height: 50,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: OC.box,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: SelectableText(
                      text,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12.5,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: OC.ink,
                        side: const BorderSide(color: OC.line),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        copyText(context, text, 'Struk berhasil disalin!');
                      },
                      icon: const Icon(Icons.content_copy_outlined, size: 18),
                      label: const Text(
                        'Salin Teks',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: OC.primary,
                        side: const BorderSide(color: OC.primary),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final data = ReceiptData.fromCustomerOrder(o);
                        await ReceiptPdfService.shareReceiptPdf(data);
                      },
                      icon: const Icon(Icons.share_outlined, size: 18),
                      label: const Text(
                        'Bagi PDF',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: OC.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final data = ReceiptData.fromCustomerOrder(o);
                    await ReceiptPdfService.printOrDownloadReceipt(context, data);
                  },
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 20),
                  label: const Text(
                    'Cetak / Simpan PDF',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProof(Order o) {
    if (o.proofBytes == null) return;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: InteractiveViewer(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(o.proofBytes!, fit: BoxFit.contain),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Tutup'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _service,
      builder: (context, _) {
        final order = _service.findById(widget.orderId);
        if (order == null) {
          return const Scaffold(
            body: Center(child: Text('Pesanan tidak ditemukan')),
          );
        }
        return Scaffold(
          backgroundColor: OC.bg,
          body: Column(
            children: [
              OrderHeader(
                title: 'Status Pesanan',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Perbarui status pesanan',
                      icon: const Icon(
                        Icons.refresh_rounded,
                        color: OC.ink,
                        size: 22,
                      ),
                      onPressed: () => _syncPaymentStatus(showMessage: true),
                    ),
                    IconButton(
                      tooltip: 'Bagikan tautan pesanan',
                      icon: const Icon(
                        Icons.share_outlined,
                        color: OC.ink,
                        size: 22,
                      ),
                      onPressed: () => _share(order),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: OC.primary,
                  onRefresh: () => _syncPaymentStatus(showMessage: true),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                    children: [
                      _statusCard(order),
                      if (order.vendors.any((v) => v.delivery == DeliveryMethod.courier)) ...[
                        const SizedBox(height: 10),
                        _deliveryMapCard(order),
                      ],
                      for (final v in order.vendors) ...[
                        const SizedBox(height: 10),
                        _vendorCard(order, v),
                      ],
                      if (order.hasProof) ...[
                        const SizedBox(height: 10),
                        _proofCard(order),
                      ],
                      const SizedBox(height: 10),
                      _paymentCard(order),
                      const SizedBox(height: 14),
                      _actions(order),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _deliveryMapCard(Order o) {
    final v = o.mainVendor;
    final origin = (v.latitude != null && v.longitude != null)
        ? LatLng(v.latitude!, v.longitude!)
        : MapNavigationService.defaultKreyonganCenter;
    final destination = (o.recipient.latitude != null && o.recipient.longitude != null)
        ? LatLng(o.recipient.latitude!, o.recipient.longitude!)
        : MapNavigationService.defaultCustomerLocation;

    return OrderDeliveryMapCard(
      origin: origin,
      destination: destination,
      originLabel: v.umkmName,
      destinationLabel: o.recipient.name,
      recipientAddress: o.recipient.address,
      recipientNote: o.recipient.addressNote,
      distanceKm: v.distanceKm,
      isDelivering: o.status == OrderStatus.delivering,
      isUmkmView: false,
      contactPhone: v.phone,
      orderId: o.refId,
    );
  }

  // -------------------------------------------------------- blok status

  /// Banner status + tahapan pesanan dalam SATU kartu.
  Widget _statusCard(Order o) {
    final main = o.mainVendor;
    final short = _shortName(main.umkmName);
    final prog = _progress(o);
    final cancelled = o.status == OrderStatus.cancelled;
    final stage = (prog.active ?? prog.done).clamp(1, 5).toInt();

    late String tag;
    late String chip;
    late String headline;
    late String body;
    Color toneBg = OC.peach;
    Color toneFg = OC.amber;
    IconData icon = Icons.hourglass_top_rounded;
    Widget? action;

    switch (o.status) {
      case OrderStatus.waitingPayment:
        tag = o.hasPreOrder ? 'PO Aktif' : 'Pesanan Aktif';
        final cod = o.paymentMethod == PaymentMethod.cod;
        chip = cod ? 'Menunggu Konfirmasi' : 'Menunggu Pembayaran';
        headline = o.paymentDeadline != null
            ? 'Bayar sebelum ${fmtDateComma(o.paymentDeadline!)}'
            : 'Konfirmasi pesanan Anda';
        body = cod
            ? 'Konfirmasi pesanan agar $short dapat segera memprosesnya.'
            : o.paymentMethod == PaymentMethod.midtrans
            ? 'Selesaikan pembayaran melalui Midtrans agar $short dapat segera memproses pesanan Anda.'
            : 'Unggah bukti transfer agar $short dapat segera memproses pesanan Anda.';
        icon = Icons.account_balance_wallet_outlined;
        action = FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: OC.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () async {
            if (o.paymentMethod == PaymentMethod.midtrans) {
              await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => MidtransPaymentScreen(
                    orderId: o.id,
                    paymentUrl: o.paymentUrl,
                  ),
                ),
              );
              if (mounted) await _syncPaymentStatus();
            } else {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OrderPaymentScreen(orderId: o.id),
                ),
              );
            }
          },
          icon: const Icon(Icons.upload_file_rounded, size: 18),
          label: Text(
            cod ? 'Konfirmasi Pesanan' : 'Bayar Sekarang',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        );
        break;
      case OrderStatus.reviewing:
        tag = o.hasPreOrder ? 'PO Aktif' : 'Pesanan Aktif';
        chip = 'Menunggu Persetujuan UMKM';
        headline = 'Estimasi konfirmasi dalam 30 menit';
        body = o.hasPreOrder
            ? '$short sedang meninjau ketersediaan bahan dapur segar & kapasitas porsi Pre-Order Anda.'
            : '$short sedang memeriksa ketersediaan pesanan Anda.';
        break;
      case OrderStatus.processing:
        tag = 'Pesanan Diproses';
        chip = 'Sedang Dimasak';
        headline = 'Pesanan Anda sedang disiapkan';
        body = '$short sedang memproses & mengemas pesanan Anda dengan rapi.';
        icon = Icons.soup_kitchen_outlined;
        break;
      case OrderStatus.delivering:
        tag = 'Dalam Perjalanan';
        chip = 'Sedang Diantar';
        headline = 'Pesanan menuju lokasi Anda';
        body = 'Kurir warga sedang mengantar pesanan ke alamat penerima.';
        icon = Icons.two_wheeler;
        break;
      case OrderStatus.completed:
        tag = 'Selesai';
        chip = 'Pesanan Selesai';
        headline = 'Terima kasih sudah jajan di desa!';
        body = 'Pesanan Anda sudah diterima. Semoga suka dengan hidangannya.';
        toneBg = OC.mint;
        toneFg = OC.mintText;
        icon = Icons.check_circle_outline;
        break;
      case OrderStatus.cancelled:
        tag = 'Dibatalkan';
        chip = o.refundStatus == 'perlu_refund'
            ? 'Menunggu Refund'
            : 'Pesanan Dibatalkan';
        headline = 'Pesanan ini sudah dibatalkan';
        if (o.refundStatus == 'perlu_refund') {
          body =
              'Pesanan telah dibatalkan. Dana Anda sedang menunggu pengembalian/refund manual dari pihak UMKM/Admin.';
        } else if (o.cancelReason != null && o.cancelReason!.isNotEmpty) {
          body = 'Alasan: ${o.cancelReason}';
        } else {
          body = 'Anda dapat menghapus riwayat ini atau membuat pesanan baru.';
        }
        toneBg = OC.dangerSoft;
        toneFg = OC.danger;
        icon = Icons.cancel_outlined;
        break;
    }

    final steps = _steps(o);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OC.line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // ---- kepala: banner status
          Container(
            width: double.infinity,
            color: toneBg,
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 19, color: toneFg),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tag,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: toneFg,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            o.refId,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: toneFg.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: toneFg,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              chip,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: toneFg,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  headline,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: OC.ink,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: OC.muted,
                    height: 1.35,
                  ),
                ),
                if (action != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(width: double.infinity, height: 44, child: action),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 14, color: toneFg),
                    const SizedBox(width: 5),
                    Text(
                      'Dibuat ${fmtDateComma(o.createdAt)}',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: toneFg,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // ---- badan: tahapan pesanan
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text('Tahapan Pesanan', style: OT.label),
                    ),
                    Pill(
                      text: cancelled ? 'Dibatalkan' : 'Tahap $stage dari 5',
                      bg: cancelled ? OC.dangerSoft : OC.mint,
                      fg: cancelled ? OC.danger : OC.mintText,
                      fontSize: 10.5,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                for (var i = 0; i < steps.length; i++)
                  _stepRow(
                    steps[i],
                    isLast: i == steps.length - 1,
                    state: cancelled
                        ? _StepState.pending
                        : (i + 1 <= prog.done
                              ? _StepState.done
                              : (prog.active == i + 1
                                    ? _StepState.active
                                    : _StepState.pending)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------- tahapan

  String _shortName(String n) {
    for (final p in ['Dapur ', 'Toko ', 'Warung ']) {
      if (n.startsWith(p)) return n.substring(p.length);
    }
    return n;
  }

  String _dayMonth(DateTime d) => '${d.day} ${fmtDate(d).split(' ')[1]}';

  /// (jumlah langkah selesai, langkah yang sedang aktif).
  ///
  /// Disesuaikan secara dinamis menurut metode pembayaran:
  /// - Midtrans: Pembayaran di awal (Tahap 2) sebelum ditinjau UMKM.
  /// - COD: Pembayaran tunai di akhir (Tahap 5) saat pesanan tiba.
  /// - Transfer Desa / QRIS: Alur konfirmasi PO -> Bayar Tagihan -> Masak.
  ({int done, int? active}) _progress(Order o) {
    if (o.status == OrderStatus.cancelled) {
      return (done: 0, active: null);
    }
    if (o.status == OrderStatus.completed) {
      return (done: 5, active: null);
    }

    if (o.paymentMethod == PaymentMethod.midtrans) {
      switch (o.status) {
        case OrderStatus.waitingPayment:
          // Tahap 1 (Pesanan Dibuat) selesai, Tahap 2 (Pembayaran Midtrans) aktif
          return (done: 1, active: 2);
        case OrderStatus.reviewing:
          // Tahap 1 & 2 selesai, Tahap 3 (Ditinjau & Dikonfirmasi UMKM) aktif
          return (done: 2, active: 3);
        case OrderStatus.processing:
          // Tahap 1, 2, 3 selesai, Tahap 4 (Diproses Dapur) aktif
          return (done: 3, active: 4);
        case OrderStatus.delivering:
          // Tahap 1, 2, 3, 4 selesai, Tahap 5 (Pengantaran/Ambil) aktif
          return (done: 4, active: 5);
        default:
          return (done: 1, active: 2);
      }
    } else if (o.paymentMethod == PaymentMethod.cod) {
      switch (o.status) {
        case OrderStatus.waitingPayment:
        case OrderStatus.reviewing:
          // Tahap 1 (Pesanan Terkirim) selesai, Tahap 2 (Ditinjau & Dikonfirmasi UMKM) aktif
          return (done: 1, active: 2);
        case OrderStatus.processing:
          // Tahap 1 & 2 selesai, Tahap 3 (Diproses Dapur) aktif
          return (done: 2, active: 3);
        case OrderStatus.delivering:
          // Tahap 1, 2, 3 selesai, Tahap 4 (Pengantaran/Siap Diambil) aktif
          return (done: 3, active: 4);
        default:
          return (done: 1, active: 2);
      }
    } else {
      // Skema Transfer Desa / QRIS Manual (PO Katering Tradisional)
      switch (o.status) {
        case OrderStatus.waitingPayment:
          return o.hasProof ? (done: 2, active: 3) : (done: 1, active: 2);
        case OrderStatus.reviewing:
          return (done: 1, active: 2);
        case OrderStatus.processing:
          return (done: 3, active: 4);
        case OrderStatus.delivering:
          return (done: 4, active: 5);
        default:
          return (done: 1, active: 2);
      }
    }
  }

  List<_Step> _steps(Order o) {
    final main = o.mainVendor;
    final first = main.items.first;
    final isGeprek = first.productName.toLowerCase().contains('geprek');
    final courier = main.delivery == DeliveryMethod.courier;

    final reviewDesc =
        'Memastikan kesiapan ${main.totalQty} ${first.unit.toLowerCase()} '
        '${isGeprek ? 'ayam geprek katering' : first.productName}'
        '${main.requiredAt != null ? ' untuk tanggal ${_dayMonth(main.requiredAt!)}' : ''}.';

    final kitchenDesc = isGeprek
        ? 'Penyembelihan ayam segar, goreng renyah, dan racikan sambal bawang.'
        : 'Bahan segar dipersiapkan, dimasak, dan dikemas rapi oleh dapur mitra.';

    final deliveryStep = courier
        ? _Step(
            'Pengantaran Kurir Warga',
            main.purpose != null
                ? 'Diantar langsung dalam kondisi hangat ke lokasi kegiatan ${main.purpose!.toLowerCase()}.'
                : 'Diantar langsung dalam kondisi hangat ke alamat penerima.',
            Icons.two_wheeler,
          )
        : _Step(
            'Siap Diambil Sendiri',
            'Ambil pesanan Anda di ${main.pickupLocation}.',
            Icons.storefront_outlined,
          );

    // 1. ALUR KHUSUS MIDTRANS (Bayar instan di awal sebelum diproses)
    if (o.paymentMethod == PaymentMethod.midtrans) {
      final isPaid = o.status != OrderStatus.waitingPayment;
      return <_Step>[
        _Step(
          o.hasPreOrder ? 'Pengajuan PO Dibuat' : 'Pesanan Dibuat',
          'Rincian pesanan berhasil dibuat di sistem.',
          Icons.check_rounded,
          trailing: fmtTime(o.createdAt),
        ),
        _Step(
          'Pembayaran Midtrans',
          isPaid
              ? 'Pembayaran instan via Midtrans telah terverifikasi otomatis.'
              : 'Selesaikan pembayaran instan via Midtrans (QRIS, e-wallet, atau VA).',
          Icons.account_balance_wallet_outlined,
        ),
        _Step(
          'Ditinjau & Dikonfirmasi ${_shortName(main.umkmName)}',
          reviewDesc,
          Icons.fact_check_outlined,
        ),
        _Step(
          'Diproses & Dimasak Dapur',
          kitchenDesc,
          Icons.soup_kitchen_outlined,
        ),
        deliveryStep,
      ];
    }

    // 2. ALUR KHUSUS COD (Bayar tunai di akhir saat pesanan tiba)
    if (o.paymentMethod == PaymentMethod.cod) {
      return <_Step>[
        _Step(
          o.hasPreOrder ? 'Pengajuan PO Terkirim' : 'Pesanan Terkirim',
          'Rincian pesanan sukses diajukan ke UMKM.',
          Icons.check_rounded,
          trailing: fmtTime(o.createdAt),
        ),
        _Step(
          'Ditinjau & Dikonfirmasi ${_shortName(main.umkmName)}',
          reviewDesc,
          Icons.fact_check_outlined,
        ),
        _Step(
          'Diproses & Dimasak Dapur',
          kitchenDesc,
          Icons.soup_kitchen_outlined,
        ),
        deliveryStep,
        _Step(
          courier ? 'Pembayaran Tunai (COD)' : 'Bayar Tunai di Tempat',
          courier
              ? 'Bayar tunai ke kurir warga saat pesanan tiba di tujuan.'
              : 'Bayar tunai langsung di tempat saat mengambil pesanan.',
          Icons.payments_outlined,
        ),
      ];
    }

    // 3. ALUR MANUAL TRANSFER / QRIS DESA (PO Katering Tradisional)
    final prog = _progress(o);
    String manualPayDesc;
    if (o.hasProof) {
      manualPayDesc = prog.done >= 3
          ? 'Bukti transfer terverifikasi oleh bendahara UMKM desa.'
          : 'Bukti transfer sudah diterima, diverifikasi setelah PO disetujui.';
    } else if (o.status == OrderStatus.waitingPayment) {
      manualPayDesc = 'Segera transfer & unggah bukti pembayaran Anda.';
    } else {
      manualPayDesc =
          'Instruksi bayar (QRIS / Transfer Desa) dibuka setelah PO disetujui.';
    }

    return <_Step>[
      _Step(
        o.hasPreOrder ? 'Pengajuan PO Terkirim' : 'Pesanan Terkirim',
        o.hasPreOrder
            ? 'Rincian menu & jadwal katering sukses diajukan ke dapur mitra.'
            : 'Rincian pesanan sukses diajukan ke UMKM.',
        Icons.check_rounded,
        trailing: fmtTime(o.createdAt),
      ),
      _Step(
        'Sedang Ditinjau ${_shortName(main.umkmName)}',
        reviewDesc,
        Icons.fact_check_outlined,
      ),
      _Step(
        'Pembayaran Tagihan',
        manualPayDesc,
        Icons.account_balance_wallet_outlined,
      ),
      _Step(
        'Diproses & Dimasak Dapur',
        kitchenDesc,
        Icons.soup_kitchen_outlined,
      ),
      deliveryStep,
    ];
  }

  Widget _stepRow(_Step s, {required bool isLast, required _StepState state}) {
    const double dot = 30;
    final Color titleColor;
    final Color bodyColor;
    Widget circle;

    switch (state) {
      case _StepState.done:
        titleColor = OC.ink;
        bodyColor = OC.muted;
        circle = Container(
          width: dot,
          height: dot,
          decoration: const BoxDecoration(
            color: OC.primary,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 17),
        );
        break;
      case _StepState.active:
        titleColor = OC.amber;
        bodyColor = OC.ink;
        circle = SizedBox(
          width: dot,
          height: dot,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: dot,
                height: dot,
                decoration: const BoxDecoration(
                  color: OC.peach,
                  shape: BoxShape.circle,
                ),
                child: Icon(s.icon, color: OC.amber, size: 16),
              ),
              Positioned(
                top: -1,
                right: -1,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: OC.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
        );
        break;
      case _StepState.pending:
        titleColor = OC.faint;
        bodyColor = OC.faint;
        circle = Container(
          width: dot,
          height: dot,
          decoration: const BoxDecoration(
            color: OC.box,
            shape: BoxShape.circle,
          ),
          child: Icon(s.icon, color: OC.faint, size: 15),
        );
        break;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: dot,
            child: Column(
              children: [
                circle,
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        color: state == _StepState.done
                            ? OC.primary.withValues(alpha: 0.35)
                            : OC.line,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 8 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          s.title,
                          style: TextStyle(
                            fontSize: state == _StepState.active ? 14 : 13,
                            fontWeight: FontWeight.w700,
                            color: titleColor,
                          ),
                        ),
                      ),
                      if (state == _StepState.active)
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Text(
                            'Aktif',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: OC.amber,
                            ),
                          ),
                        )
                      else if (s.trailing != null && state == _StepState.done)
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Text(
                            s.trailing!,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: OC.muted,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    s.body,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: bodyColor,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------- kartu per UMKM (produk + kirim)

  Widget _vendorCard(Order o, OrderVendor v) {
    return OrderCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBadge(
                icon: Icons.storefront_outlined,
                bg: OC.primarySoft,
                fg: OC.primary,
                size: 38,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      v.umkmName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: OT.cardTitle,
                    ),
                    Text(
                      v.umkmType,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: OT.caption,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Pill(
                text: v.isPreOrder ? 'PRE-ORDER' : 'PESAN SEKARANG',
                bg: v.isPreOrder ? OC.peach : OC.mint,
                fg: v.isPreOrder ? OC.amber : OC.mintText,
                icon: v.isPreOrder
                    ? Icons.hourglass_top_rounded
                    : Icons.bolt_rounded,
                fontSize: 10,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: OC.line),
          const SizedBox(height: 12),
          for (final i in v.items) _itemRow(i),
          if (v.isPreOrder) _poInfoBox(v),
          if (!v.isPreOrder && v.note != null) _noteBox(v.note!),
          const SizedBox(height: 10),
          _deliveryBlock(o, v),
          const SizedBox(height: 12),
          const Divider(height: 1, color: OC.line),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Subtotal (${v.totalQty} porsi)',
                  style: OT.secondary,
                ),
              ),
              const SizedBox(width: 8),
              Text(rupiah(v.subtotal), style: OT.money),
            ],
          ),
        ],
      ),
    );
  }

  Widget _itemRow(OrderItem i) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NetImage(url: i.imageUrl, width: 52, height: 52, radius: 10),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  i.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: OT.item,
                ),
                const SizedBox(height: 2),
                Text(
                  i.variant,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: OC.muted,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${i.quantity}x @ ${rupiah(i.price)}/${i.unit.toLowerCase()}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: OT.secondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(rupiah(i.subtotal), style: OT.money),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _poInfoBox(OrderVendor v) {
    Widget field(IconData icon, String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: OC.amber),
              const SizedBox(width: 5),
              Text(label, style: OT.label.copyWith(color: OC.amber)),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: OC.ink,
              height: 1.3,
            ),
          ),
        ],
      ),
    );

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 2),
      decoration: BoxDecoration(
        color: OC.peachSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: OC.peach),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (v.requiredAt != null)
            field(
              Icons.calendar_month_outlined,
              'WAKTU DIBUTUHKAN',
              fmtDateTime(v.requiredAt!),
            ),
          if (v.purpose != null)
            field(Icons.groups_outlined, 'KEPERLUAN', v.purpose!),
          if (v.note != null)
            field(Icons.edit_note_outlined, 'CATATAN KHUSUS', v.note!),
        ],
      ),
    );
  }

  Widget _noteBox(String note) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: OC.box,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.edit_note_rounded, size: 15, color: OC.muted),
              const SizedBox(width: 6),
              Text('CATATAN KHUSUS', style: OT.label),
            ],
          ),
          const SizedBox(height: 4),
          Text(note, style: OT.body),
        ],
      ),
    );
  }

  /// Metode pengantaran milik satu UMKM (kurir warga atau ambil sendiri).
  Widget _deliveryBlock(Order o, OrderVendor v) {
    final courier = v.delivery == DeliveryMethod.courier;
    final r = o.recipient;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: OC.box,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                courier
                    ? Icons.two_wheeler_outlined
                    : Icons.storefront_outlined,
                size: 17,
                color: OC.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  courier
                      ? 'Diantar Kurir Warga / UMKM'
                      : 'Ambil Sendiri (Pickup)',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: OC.ink,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                courier
                    ? (v.deliveryFee == 0 ? 'Gratis' : rupiah(v.deliveryFee))
                    : 'Gratis',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: OC.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (courier) ...[
            Row(
              children: [
                const Icon(Icons.person_outline, size: 15, color: OC.muted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${r.name} · ${r.phone}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: OC.ink,
                    ),
                  ),
                ),
                if (o.status.canEdit)
                  InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () => _editRecipient(o),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Text(
                        'Ubah',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: OC.primary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 15,
                  color: OC.muted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    r.addressNote == null
                        ? r.address
                        : '${r.address} (${r.addressNote})',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: OC.muted,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 15,
                  color: OC.muted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Ambil pesanan di ${v.pickupLocation}.',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: OC.muted,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- proof

  Widget _proofCard(Order o) {
    return OrderCard(
      child: Row(
        children: [
          InkWell(
            onTap: () => _showProof(o),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.memory(
                o.proofBytes!,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Bukti Transfer', style: OT.cardTitle),
                Text(
                  'Diunggah ${o.proofUploadedAt != null ? fmtDateComma(o.proofUploadedAt!) : ''}',
                  style: OT.secondary,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _showProof(o),
            style: TextButton.styleFrom(
              foregroundColor: OC.primary,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(40, 34),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Lihat',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
          if (o.status == OrderStatus.reviewing &&
              o.paymentMethod == PaymentMethod.qris)
            IconButton(
              tooltip: 'Ganti bukti',
              icon: const Icon(Icons.edit_outlined, size: 20, color: OC.muted),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OrderPaymentScreen(orderId: o.id),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------- payment

  Widget _paymentCard(Order o) {
    String note;
    if (o.paymentMethod == PaymentMethod.cod) {
      note = 'Dibayar tunai saat pesanan tiba';
    } else if (o.paymentMethod == PaymentMethod.midtrans) {
      note = o.status == OrderStatus.waitingPayment
          ? 'Menunggu pembayaran Anda'
          : 'Pembayaran instan terverifikasi';
    } else if (o.status == OrderStatus.waitingPayment) {
      note = 'Menunggu pembayaran Anda';
    } else if (o.hasProof) {
      note = 'Bukti transfer diterima';
    } else {
      note = 'Dibayar saat disetujui penjual';
    }

    return OrderCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TitleRow(
            icon: Icons.receipt_long_outlined,
            title: 'Rincian Pembayaran',
          ),
          const SizedBox(height: 6),
          MoneyRow(
            label: 'Subtotal menu (${o.totalQty} porsi)',
            value: rupiah(o.subtotal),
          ),
          MoneyRow(
            label: 'Ongkir kurir',
            value: o.shippingTotal == 0 ? 'Gratis' : rupiah(o.shippingTotal),
          ),
          MoneyRow(
            label: 'Biaya layanan',
            value: o.serviceFee == 0 ? 'Gratis' : rupiah(o.serviceFee),
          ),
          if (o.discount > 0)
            MoneyRow(
              label: 'Diskon',
              value: '-${rupiah(o.discount)}',
              color: OC.primary,
            ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Divider(height: 1, color: OC.line),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      o.hasPreOrder
                          ? 'Total Pembayaran PO'
                          : 'Total Pembayaran',
                      style: OT.cardTitle,
                    ),
                    Text(note, style: OT.caption),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(rupiah(o.total), style: OT.moneyLarge),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------- actions

  Widget _actions(Order o) {
    final main = o.mainVendor;
    return Column(
      children: [
        if (o.canComplete) ...[
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 1,
              ),
              onPressed: _busy ? null : () => _confirmReceived(o),
              icon: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline, size: 22),
              label: const Text(
                'Pesanan Sudah Diterima',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: OC.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () {
              final phone = main.phone.isNotEmpty
                  ? main.phone
                  : (CatalogService().umkmById(main.umkmId)?.phone.isNotEmpty == true
                      ? CatalogService().umkmById(main.umkmId)!.phone
                      : kUmkmWhatsApp);
              openWhatsApp(
                context,
                phone: phone,
                message: generateOrderWhatsAppMessage(o, umkmName: main.umkmName),
              );
            },
            icon: const Icon(Icons.chat_outlined, size: 20),
            label: Text(
              'Hubungi ${_shortName(main.umkmName)} via WhatsApp',
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _softButton(
                icon: Icons.picture_as_pdf_outlined,
                label: 'Struk PDF',
                color: OC.ink,
                onTap: () => _showReceipt(o),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: o.status.canCancel
                  ? _softButton(
                      icon: Icons.cancel_outlined,
                      label: o.hasPreOrder ? 'Batalkan PO' : 'Batalkan',
                      color: OC.danger,
                      onTap: _busy ? null : () => _cancel(o),
                    )
                  : (!o.status.isActive
                        ? _softButton(
                            icon: Icons.delete_outline,
                            label: 'Hapus Riwayat',
                            color: OC.danger,
                            onTap: _busy ? null : () => _delete(o),
                          )
                        : _softButton(
                            icon: Icons.lock_outline,
                            label: 'Tidak dapat batal',
                            color: OC.faint,
                            onTap: null,
                          )),
            ),
          ],
        ),
      ],
    );
  }

  Widget _softButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return SizedBox(
      height: 46,
      child: Material(
        color: OC.box,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _StepState { done, active, pending }

class _Step {
  final String title;
  final String body;
  final IconData icon;
  final String? trailing;

  const _Step(this.title, this.body, this.icon, {this.trailing});
}
