import 'package:flutter/material.dart';

import '../../../models/order.dart';
import '../../../services/api_service.dart';
import '../../../services/order_service.dart';
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

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final OrderService _service = OrderService();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _syncPaymentStatus();
  }

  Future<void> _syncPaymentStatus() async {
    final order = _service.findById(widget.orderId);
    if (order?.paymentMethod != PaymentMethod.midtrans ||
        order?.status != OrderStatus.waitingPayment) {
      return;
    }

    try {
      await _service.refreshPaymentStatusUntilSettled(widget.orderId);
      if (mounted) setState(() {});
    } on ApiException {
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
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(o.hasPreOrder ? 'Batalkan PO?' : 'Batalkan Pesanan?'),
        content: Text(
          'Pesanan ${o.refId} akan dibatalkan dan tidak dapat dikembalikan.',
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
                    Navigator.pop(ctx);
                    copyText(context, text, 'Struk berhasil disalin!');
                  },
                  icon: const Icon(Icons.content_copy_outlined),
                  label: const Text(
                    'Salin Struk',
                    style: TextStyle(fontWeight: FontWeight.w700),
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
                trailing: IconButton(
                  tooltip: 'Bagikan tautan pesanan',
                  icon: const Icon(
                    Icons.share_outlined,
                    color: OC.ink,
                    size: 22,
                  ),
                  onPressed: () => _share(order),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                  children: [
                    _statusCard(order),
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
            ],
          ),
        );
      },
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
                  builder: (_) => MidtransPaymentScreen(orderId: o.id),
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
        chip = 'Pesanan Dibatalkan';
        headline = 'Pesanan ini sudah dibatalkan';
        body = 'Anda dapat menghapus riwayat ini atau membuat pesanan baru.';
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
  /// Untuk COD, langkah "Pembayaran" baru selesai saat pesanan diterima —
  /// jadi tidak ikut dicentang saat pesanan sedang dimasak/diantar.
  ({int done, int? active}) _progress(Order o) {
    final cod = o.paymentMethod == PaymentMethod.cod;
    switch (o.status) {
      case OrderStatus.waitingPayment:
        return (done: 1, active: null);
      case OrderStatus.reviewing:
        return (done: 1, active: 2);
      case OrderStatus.processing:
        return cod ? (done: 2, active: 4) : (done: 3, active: 4);
      case OrderStatus.delivering:
        return cod ? (done: 2, active: 5) : (done: 4, active: 5);
      case OrderStatus.completed:
        return (done: 5, active: null);
      case OrderStatus.cancelled:
        return (done: 0, active: null);
    }
  }

  List<_Step> _steps(Order o) {
    final main = o.mainVendor;
    final first = main.items.first;
    final prog = _progress(o);
    final isGeprek = first.productName.toLowerCase().contains('geprek');

    final s2 =
        'Memastikan kesiapan ${main.totalQty} ${first.unit.toLowerCase()} '
        '${isGeprek ? 'ayam geprek katering' : first.productName}'
        '${main.requiredAt != null ? ' untuk tanggal ${_dayMonth(main.requiredAt!)}' : ''}.';

    String s3;
    if (o.paymentMethod == PaymentMethod.cod) {
      s3 = 'Bayar tunai ke kurir warga saat pesanan tiba.';
    } else if (o.paymentMethod == PaymentMethod.midtrans) {
      s3 = o.status == OrderStatus.waitingPayment
          ? 'Selesaikan pembayaran instan via Midtrans (QRIS, e-wallet, atau VA).'
          : 'Pembayaran instan via Midtrans telah terverifikasi otomatis.';
    } else if (o.hasProof) {
      s3 = prog.done >= 3
          ? 'Bukti transfer terverifikasi oleh bendahara UMKM desa.'
          : 'Bukti transfer sudah diterima, diverifikasi setelah PO disetujui.';
    } else if (o.status == OrderStatus.waitingPayment) {
      s3 = 'Segera transfer & unggah bukti pembayaran Anda.';
    } else {
      s3 =
          'Instruksi bayar (QRIS / Transfer Desa) dibuka setelah PO disetujui.';
    }

    final courier = main.delivery == DeliveryMethod.courier;
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
        s2,
        Icons.fact_check_outlined,
      ),
      _Step(
        o.paymentMethod == PaymentMethod.cod
            ? 'Pembayaran Tunai (COD)'
            : 'Pembayaran Tagihan',
        s3,
        Icons.account_balance_wallet_outlined,
      ),
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
              Icons.two_wheeler,
            )
          : _Step(
              'Siap Diambil Sendiri',
              'Ambil pesanan Anda di ${main.pickupLocation}.',
              Icons.storefront_outlined,
            ),
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
            onPressed: () => openWhatsApp(
              context,
              phone: kUmkmWhatsApp,
              message:
                  'Halo ${main.umkmName}, saya ingin menanyakan pesanan ${o.refId}.',
            ),
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
