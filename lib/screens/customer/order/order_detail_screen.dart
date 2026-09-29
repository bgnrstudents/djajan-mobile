import 'package:flutter/material.dart';

import 'order_model.dart';
import 'order_service.dart';
import 'order_payment_screen.dart';
import 'order_widgets.dart';

/// Tahap 3 alur pesanan: Status Pesanan (timeline, rincian, aksi).
class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final OrderService _service = OrderService();
  bool _busy = false;

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
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(o.hasPreOrder ? 'Batalkan PO?' : 'Batalkan Pesanan?'),
        content: Text(
            'Pesanan ${o.refId} akan dibatalkan dan tidak dapat dikembalikan.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Tidak')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: OC.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _run(() async {
      await _service.cancelOrder(o.id);
      if (mounted) showToast(context, 'Pesanan berhasil dibatalkan.');
    });
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
              child: const Text('Batal')),
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
                      Text('Struk Digital',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w700, color: OC.ink)),
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
                        color: OC.box, borderRadius: BorderRadius.circular(14)),
                    child: SelectableText(text,
                        style: const TextStyle(
                            fontFamily: 'monospace', fontSize: 12.5, height: 1.5)),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: OC.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    copyText(context, text, 'Struk berhasil disalin!');
                  },
                  icon: const Icon(Icons.content_copy_outlined),
                  label: const Text('Salin Struk',
                      style: TextStyle(fontWeight: FontWeight.w700)),
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
                  onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
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
              body: Center(child: Text('Pesanan tidak ditemukan')));
        }
        return Scaffold(
          backgroundColor: OC.bg,
          body: Column(
            children: [
              const OrderHeader(title: 'Status Pesanan'),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                  children: [
                    _titleRow(order),
                    const SizedBox(height: 14),
                    _banner(order),
                    const SizedBox(height: 16),
                    _timelineCard(order),
                    for (final v in order.vendors) ...[
                      const SizedBox(height: 16),
                      _vendorCard(v),
                    ],
                    for (final v in order.vendors) ...[
                      const SizedBox(height: 16),
                      _deliveryCard(order, v),
                    ],
                    if (order.hasProof) ...[
                      const SizedBox(height: 16),
                      _proofCard(order),
                    ],
                    const SizedBox(height: 16),
                    _paymentCard(order),
                    const SizedBox(height: 18),
                    _actions(order),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(color: OC.box, shape: BoxShape.circle),
        child: Icon(icon, size: 21, color: OC.ink),
      ),
    );
  }

  Widget _titleRow(Order o) {
    return Row(
      children: [
        const IconBadge(icon: Icons.receipt_long_outlined, bg: OC.box, fg: OC.ink),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Detail Pesanan',
                  style: TextStyle(
                      fontSize: 21, fontWeight: FontWeight.w700, color: OC.ink)),
              Text('Ref ID: ${o.refId}',
                  style: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w600, color: OC.muted)),
            ],
          ),
        ),
        _circleButton(Icons.share_outlined, () => _share(o)),
        const SizedBox(width: 8),
        _circleButton(Icons.file_download_outlined, () => _showReceipt(o)),
      ],
    );
  }

  // --------------------------------------------------------------- banner

  Widget _banner(Order o) {
    final main = o.mainVendor;
    final short = _shortName(main.umkmName);
    late String tag, chip, headline, body;
    Color bg = OC.peach;
    Color fg = OC.amber;
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
            : 'Unggah bukti transfer agar $short dapat segera memproses pesanan Anda.';
        icon = Icons.account_balance_wallet_outlined;
        action = FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: OC.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => OrderPaymentScreen(orderId: o.id)),
          ),
          icon: const Icon(Icons.upload_file_rounded, size: 18),
          label: Text(cod ? 'Konfirmasi Pesanan' : 'Bayar Sekarang',
              style: const TextStyle(fontWeight: FontWeight.w700)),
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
        bg = OC.mint;
        fg = OC.mintText;
        icon = Icons.check_circle_outline;
        break;
      case OrderStatus.cancelled:
        tag = 'Dibatalkan';
        chip = 'Pesanan Dibatalkan';
        headline = 'Pesanan ini sudah dibatalkan';
        body = 'Anda dapat menghapus riwayat ini atau membuat pesanan baru.';
        bg = OC.dangerSoft;
        fg = OC.danger;
        icon = Icons.cancel_outlined;
        break;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        color: bg,
        child: Stack(
          children: [
            Positioned(
              top: -30,
              left: -30,
              child: Container(
                width: 110,
                height: 110,
                decoration: const BoxDecoration(
                    color: Color(0x22FFFFFF), shape: BoxShape.circle),
              ),
            ),
            Padding(
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
                            Text(tag,
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: fg)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                        color: fg, shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(chip,
                                        style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w800,
                                            color: fg)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 62,
                        height: 62,
                        decoration: const BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle),
                        child: Icon(icon, size: 30, color: fg),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(headline,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800, color: OC.ink)),
                  const SizedBox(height: 4),
                  Text(body,
                      style: const TextStyle(
                          fontSize: 14, color: OC.muted, height: 1.35)),
                  if (action != null) ...[
                    const SizedBox(height: 12),
                    action,
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 16, color: fg),
                      const SizedBox(width: 6),
                      Text('Dibuat: ${fmtDateComma(o.createdAt)}',
                          style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: fg)),
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

  // ------------------------------------------------------------- timeline

  String _shortName(String n) {
    for (final p in ['Dapur ', 'Toko ', 'Warung ']) {
      if (n.startsWith(p)) return n.substring(p.length);
    }
    return n;
  }

  String _dayMonth(DateTime d) => '${d.day} ${fmtDate(d).split(' ')[1]}';

  /// Menghasilkan (jumlah langkah selesai, langkah aktif atau null).
  ({int done, int? active}) _progress(OrderStatus s) {
    switch (s) {
      case OrderStatus.waitingPayment:
        return (done: 1, active: null);
      case OrderStatus.reviewing:
        return (done: 1, active: 2);
      case OrderStatus.processing:
        return (done: 3, active: 4);
      case OrderStatus.delivering:
        return (done: 4, active: 5);
      case OrderStatus.completed:
        return (done: 5, active: null);
      case OrderStatus.cancelled:
        return (done: 0, active: null);
    }
  }

  Widget _timelineCard(Order o) {
    final main = o.mainVendor;
    final first = main.items.first;
    final prog = _progress(o.status);
    final cancelled = o.status == OrderStatus.cancelled;
    final isGeprek = first.productName.toLowerCase().contains('geprek');

    final s2 = 'Memastikan kesiapan ${main.totalQty} ${first.unit.toLowerCase()} '
        '${isGeprek ? 'ayam geprek katering' : first.productName}'
        '${main.requiredAt != null ? ' untuk tanggal ${_dayMonth(main.requiredAt!)}' : ''}.';

    String s3;
    if (o.paymentMethod == PaymentMethod.cod) {
      s3 = 'Bayar tunai ke kurir warga saat pesanan tiba.';
    } else if (o.hasProof) {
      s3 = prog.done >= 3
          ? 'Bukti transfer terverifikasi oleh bendahara UMKM desa.'
          : 'Bukti transfer sudah diterima, diverifikasi setelah PO disetujui.';
    } else if (o.status == OrderStatus.waitingPayment) {
      s3 = 'Segera transfer & unggah bukti pembayaran Anda.';
    } else {
      s3 = 'Instruksi bayar (QRIS / Transfer Desa) dibuka setelah PO disetujui.';
    }

    final courier = main.delivery == DeliveryMethod.courier;
    final steps = <_Step>[
      _Step(
        'Ajukan PO Terkirim',
        o.hasPreOrder
            ? 'Rincian menu & jadwal katering sukses diajukan ke dapur mitra.'
            : 'Rincian pesanan sukses diajukan ke UMKM.',
        Icons.check_rounded,
        trailing: fmtTime(o.createdAt),
      ),
      _Step('Sedang Ditinjau ${_shortName(main.umkmName)}', s2,
          Icons.fact_check_outlined),
      _Step('Pembayaran Tagihan', s3, Icons.account_balance_wallet_outlined),
      _Step(
        'Diproses & Dimasak Dapur',
        isGeprek
            ? 'Penyembelihan ayam segar, goreng renyah, dan racikan sambal bawang.'
            : 'Bahan segar dipersiapkan, dimasak, dan dikemas rapi oleh dapur mitra.',
        Icons.soup_kitchen_outlined,
      ),
      courier
          ? _Step(
              'Pengantaran Kurir Warga',
              main.purpose != null
                  ? 'Diantar langsung dalam kondisi hangat ke lokasi kegiatan ${main.purpose!.toLowerCase()}.'
                  : 'Diantar langsung dalam kondisi hangat ke alamat penerima.',
              Icons.two_wheeler)
          : _Step('Siap Diambil Sendiri',
              'Ambil pesanan Anda di ${main.pickupLocation}.', Icons.storefront_outlined),
    ];

    final int stage = (prog.active ?? prog.done).clamp(1, 5).toInt();

    return OrderCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_shipping_outlined, color: OC.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Status Pesanan',
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700, color: OC.ink)),
              ),
              Pill(
                text: cancelled ? 'Dibatalkan' : 'Tahap $stage dari 5',
                bg: cancelled ? OC.dangerSoft : const Color(0xFFA6F2B4),
                fg: cancelled ? OC.danger : OC.mintText,
                fontSize: 12,
              ),
            ],
          ),
          const SizedBox(height: 14),
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
    );
  }

  Widget _stepRow(_Step s, {required bool isLast, required _StepState state}) {
    final Color titleColor;
    final Color bodyColor;
    Widget circle;
    switch (state) {
      case _StepState.done:
        titleColor = OC.ink;
        bodyColor = OC.muted;
        circle = Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(color: OC.primary, shape: BoxShape.circle),
          child: const Icon(Icons.check_rounded, color: Colors.white),
        );
        break;
      case _StepState.active:
        titleColor = OC.amber;
        bodyColor = OC.ink;
        circle = SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration:
                    const BoxDecoration(color: OC.peach, shape: BoxShape.circle),
                child: Icon(s.icon, color: OC.amber, size: 22),
              ),
              Positioned(
                top: -1,
                right: -2,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF34C759),
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
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
              color: Color(0xFFE9EAF6), shape: BoxShape.circle),
          child: Icon(s.icon == Icons.check_rounded ? Icons.check_rounded : s.icon,
              color: OC.faint, size: 21),
        );
        break;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                circle,
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 3,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        color: state == _StepState.done
                            ? OC.primary.withValues(alpha: 0.35)
                            : const Color(0xFFDDE0F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 10 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(s.title,
                            style: TextStyle(
                                fontSize: state == _StepState.active ? 19 : 16,
                                fontWeight: FontWeight.w700,
                                color: titleColor)),
                      ),
                      if (state == _StepState.active)
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text('Aktif',
                              style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: OC.amber)),
                        )
                      else if (s.trailing != null && state == _StepState.done)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(s.trailing!,
                              style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: OC.muted)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(s.body,
                      style: TextStyle(fontSize: 14, color: bodyColor, height: 1.35)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------- vendor

  Widget _vendorCard(OrderVendor v) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x0F1A2340), blurRadius: 14, offset: Offset(0, 3)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color: const Color(0xFFF3F4FD),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const IconBadge(
                    icon: Icons.storefront_outlined,
                    bg: OC.primary,
                    fg: Colors.white,
                    size: 52),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(v.umkmName,
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: OC.ink)),
                      const Row(
                        children: [
                          Icon(Icons.verified_outlined, size: 15, color: OC.primary),
                          SizedBox(width: 4),
                          Flexible(
                            child: Text('Mitra Kuliner Kreyongan',
                                style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: OC.primary)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Pill(
                    text: v.umkmType,
                    bg: const Color(0xFFA6F2B4),
                    fg: OC.mintText,
                    fontSize: 11,
                    shrink: true,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                for (final i in v.items) ...[
                  _itemRow(v, i),
                  const SizedBox(height: 12),
                ],
                if (v.isPreOrder) _poInfoBox(v),
                if (!v.isPreOrder && v.note != null) _noteBox(v.note!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemRow(OrderVendor v, OrderItem i) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            NetImage(url: i.imageUrl, width: 88, height: 88, radius: 12),
            Positioned(
              right: 6,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8)),
                child: Text('${i.quantity}x',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(i.productName,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700, color: OC.ink)),
                  if (v.isPreOrder)
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: const Color(0xFFA6F2B4),
                          borderRadius: BorderRadius.circular(6)),
                      child: const Text('Pre-Order',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: OC.mintText)),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(i.variant,
                  style: const TextStyle(fontSize: 13.5, color: OC.muted, height: 1.3)),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(rupiah(i.subtotal),
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: OC.primary)),
                  const Spacer(),
                  Text('@ ${rupiah(i.price)}/${i.unit.toLowerCase()}',
                      style: const TextStyle(fontSize: 12.5, color: OC.muted)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _poInfoBox(OrderVendor v) {
    Widget row(IconData icon, String label, String value) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 19, color: OC.primary),
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(fontSize: 14, color: OC.muted)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(value,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700, color: OC.ink)),
              ),
            ],
          ),
        );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: OC.box, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (v.requiredAt != null)
            row(Icons.calendar_month_outlined, 'Waktu Diperlukan:',
                fmtDateTime(v.requiredAt!)),
          if (v.purpose != null)
            row(Icons.groups_outlined, 'Keperluan:', v.purpose!),
          if (v.note != null) ...[
            const Row(
              children: [
                Icon(Icons.edit_note_rounded, size: 20, color: OC.primary),
                SizedBox(width: 8),
                Text('Catatan Khusus:',
                    style: TextStyle(fontSize: 14, color: OC.muted)),
              ],
            ),
            const SizedBox(height: 6),
            _quote(v.note!),
          ],
        ],
      ),
    );
  }

  Widget _noteBox(String note) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: OC.box, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.edit_note_rounded, size: 20, color: OC.primary),
              SizedBox(width: 8),
              Text('Catatan Khusus:',
                  style: TextStyle(fontSize: 14, color: OC.muted)),
            ],
          ),
          const SizedBox(height: 6),
          _quote(note),
        ],
      ),
    );
  }

  Widget _quote(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(8)),
      child: Text('“$text”',
          style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w700, color: OC.ink, height: 1.3)),
    );
  }

  // ------------------------------------------------------------- delivery

  Widget _deliveryCard(Order o, OrderVendor v) {
    final courier = v.delivery == DeliveryMethod.courier;
    final r = o.recipient;
    return OrderCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(
                  icon: courier ? Icons.two_wheeler : Icons.storefront_outlined,
                  bg: OC.mint,
                  fg: OC.mintText),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Metode Pengiriman',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: OC.ink,
                            height: 1.15)),
                    if (o.vendors.length > 1)
                      Text(v.umkmName,
                          style: const TextStyle(fontSize: 12.5, color: OC.muted)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  courier
                      ? '${rupiah(v.deliveryFee)} (Kurir Warga)'
                      : 'Ambil Sendiri (Gratis)',
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: OC.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: OC.box, borderRadius: BorderRadius.circular(14)),
            child: courier
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text('Penerima: ${r.name}',
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: OC.ink)),
                          ),
                          const Icon(Icons.phone_outlined,
                              size: 16, color: OC.primary),
                          const SizedBox(width: 4),
                          Text(r.phone,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: OC.primary)),
                          if (o.status.canEdit)
                            InkWell(
                              onTap: () => _editRecipient(o),
                              child: const Padding(
                                padding: EdgeInsets.only(left: 10),
                                child: Icon(Icons.edit_outlined,
                                    size: 18, color: OC.muted),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 18, color: OC.muted),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              r.addressNote == null
                                  ? r.address
                                  : '${r.address} (${r.addressNote}).',
                              style: const TextStyle(
                                  fontSize: 14, color: OC.ink, height: 1.35),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 18, color: OC.muted),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text('Ambil pesanan di ${v.pickupLocation}.',
                            style: const TextStyle(
                                fontSize: 14, color: OC.ink, height: 1.35)),
                      ),
                    ],
                  ),
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
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(o.proofBytes!,
                  width: 64, height: 64, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Bukti Transfer',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700, color: OC.ink)),
                Text(
                  'Diunggah ${o.proofUploadedAt != null ? fmtDateComma(o.proofUploadedAt!) : ''}',
                  style: const TextStyle(fontSize: 12.5, color: OC.muted),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _showProof(o),
            child: const Text('Lihat',
                style: TextStyle(fontWeight: FontWeight.w700, color: OC.primary)),
          ),
          if (o.status == OrderStatus.reviewing &&
              o.paymentMethod == PaymentMethod.qris)
            IconButton(
              tooltip: 'Ganti bukti',
              icon: const Icon(Icons.edit_outlined, color: OC.muted),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => OrderPaymentScreen(orderId: o.id)),
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
    } else if (o.status == OrderStatus.waitingPayment) {
      note = 'Menunggu pembayaran Anda';
    } else if (o.hasProof) {
      note = 'Bukti transfer diterima';
    } else {
      note = 'Dibayar saat disetujui penjual';
    }

    return OrderCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Rincian Pembayaran',
              style: TextStyle(
                  fontSize: 21, fontWeight: FontWeight.w700, color: OC.ink)),
          const SizedBox(height: 8),
          MoneyRow(
              label: 'Subtotal Menu (${o.totalQty} Porsi)',
              value: rupiah(o.subtotal)),
          MoneyRow(label: 'Ongkir Kurir Antar Desa', value: rupiah(o.shippingTotal)),
          MoneyRow(
              label: 'Biaya Layanan Koperasi',
              value: o.serviceFee == 0 ? 'Gratis' : rupiah(o.serviceFee)),
          if (o.discount > 0)
            MoneyRow(
                label: 'Diskon Promo Gotong Royong',
                value: '-${rupiah(o.discount)}',
                color: OC.primary),
          const SizedBox(height: 8),
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
                      Text(
                          o.hasPreOrder
                              ? 'Total Pembayaran PO'
                              : 'Total Pembayaran',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: OC.ink)),
                      Text(note,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600, color: OC.muted)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(rupiah(o.total),
                    style: const TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        color: OC.primary)),
              ],
            ),
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
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: OC.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () => openWhatsApp(
              context,
              phone: kUmkmWhatsApp,
              message:
                  'Halo ${main.umkmName}, saya ingin menanyakan pesanan ${o.refId}.',
            ),
            icon: const Icon(Icons.chat_outlined),
            label: Text('Hubungi ${_shortName(main.umkmName)} via WhatsApp',
                style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _softButton(
                icon: Icons.receipt_long_outlined,
                label: 'Struk Digital',
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
        if (o.status.isActive && o.status != OrderStatus.waitingPayment) ...[
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: _busy
                ? null
                : () => _run(() async {
                      final u = await _service.advanceStatus(o.id);
                      if (mounted) {
                        showToast(context, 'Simulasi: ${u.status.label}');
                      }
                    }),
            icon: const Icon(Icons.fast_forward_rounded, size: 18),
            label: const Text('Simulasi: lanjutkan ke tahap berikutnya (demo)'),
            style: TextButton.styleFrom(foregroundColor: OC.muted),
          ),
        ],
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
      height: 52,
      child: Material(
        color: OC.box,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Flexible(
                child: Text(label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 14.5, fontWeight: FontWeight.w700, color: color)),
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
