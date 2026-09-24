import 'package:flutter/material.dart';

import 'order_model.dart';
import 'order_service.dart';
import 'order_checkout_screen.dart';
import 'order_detail_screen.dart';
import 'order_payment_screen.dart';
import 'order_widgets.dart';

/// Tab "Pesanan" pada navigasi bawah: daftar pesanan + filter.
class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

enum _Filter { all, active, done, cancelled }

class _OrderListScreenState extends State<OrderListScreen> {
  final OrderService _service = OrderService();
  _Filter _filter = _Filter.all;

  List<Order> _filtered() {
    return _service.orders.where((o) {
      switch (_filter) {
        case _Filter.all:
          return true;
        case _Filter.active:
          return o.status.isActive;
        case _Filter.done:
          return o.status == OrderStatus.completed;
        case _Filter.cancelled:
          return o.status == OrderStatus.cancelled;
      }
    }).toList();
  }

  void _openDetail(Order o) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: o.id)),
    );
  }

  void _startCheckout() {
    // Nanti diganti dengan isi keranjang asli dari halaman Keranjang.
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => const OrderCheckoutScreen(cartLines: SampleData.cart)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: OC.bg,
      child: AnimatedBuilder(
        animation: _service,
        builder: (context, _) {
          final list = _filtered();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              const Text('Pesanan Saya',
                  style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w800, color: OC.ink)),
              const Text('Pantau pesanan jajan & katering dari UMKM desa',
                  style: TextStyle(fontSize: 13.5, color: OC.muted)),
              const SizedBox(height: 14),
              _checkoutPromo(),
              const SizedBox(height: 14),
              _filters(),
              const SizedBox(height: 14),
              if (list.isEmpty) _empty() else ...list.map(_orderCard),
            ],
          );
        },
      ),
    );
  }

  Widget _checkoutPromo() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: OC.primary, borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          const IconBadge(
              icon: Icons.shopping_bag_outlined,
              bg: Color(0x33FFFFFF),
              fg: Colors.white),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Coba alur pesanan',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800)),
                Text('Checkout contoh dari 2 UMKM (Bu Minten & Pak Budi)',
                    style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 12.5)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: OC.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _startCheckout,
            child: const Text('Checkout',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _filters() {
    const labels = {
      _Filter.all: 'Semua',
      _Filter.active: 'Aktif',
      _Filter.done: 'Selesai',
      _Filter.cancelled: 'Dibatalkan',
    };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final f in _Filter.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(labels[f]!),
                selected: _filter == f,
                showCheckmark: false,
                selectedColor: OC.primary,
                backgroundColor: Colors.white,
                side: const BorderSide(color: OC.line),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                labelStyle: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _filter == f ? Colors.white : OC.ink),
                onSelected: (_) => setState(() => _filter = f),
              ),
            ),
        ],
      ),
    );
  }

  Widget _empty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 12),
          const Text('Belum ada pesanan',
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w700, color: OC.muted)),
          const SizedBox(height: 4),
          const Text('Pesanan yang sesuai filter akan muncul di sini',
              style: TextStyle(fontSize: 13, color: OC.faint)),
        ],
      ),
    );
  }

  ({Color bg, Color fg}) _statusColors(OrderStatus s) {
    switch (s) {
      case OrderStatus.waitingPayment:
      case OrderStatus.reviewing:
        return (bg: OC.peach, fg: OC.amber);
      case OrderStatus.processing:
      case OrderStatus.delivering:
        return (bg: OC.banner, fg: const Color(0xFF1A4BA0));
      case OrderStatus.completed:
        return (bg: OC.mint, fg: OC.mintText);
      case OrderStatus.cancelled:
        return (bg: OC.dangerSoft, fg: OC.danger);
    }
  }

  Widget _orderCard(Order o) {
    final c = _statusColors(o.status);
    final firstItem = o.vendors.first.items.first;
    final more = o.vendors.fold(0, (s, v) => s + v.items.length) - 1;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _openDetail(o),
        child: OrderCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(o.refId,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: OC.ink)),
                  ),
                  Pill(
                      text: o.status.label,
                      bg: c.bg,
                      fg: c.fg,
                      fontSize: 11),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  NetImage(url: firstItem.imageUrl, width: 64, height: 64, radius: 12),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(o.vendorNames,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: OC.muted)),
                        Text(firstItem.productName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: OC.ink)),
                        Text(
                            more > 0
                                ? '${firstItem.quantity}x ${firstItem.unit.toLowerCase()} • +$more menu lainnya'
                                : '${firstItem.quantity}x ${firstItem.unit.toLowerCase()}',
                            style: const TextStyle(fontSize: 12.5, color: OC.muted)),
                      ],
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: OC.line),
              ),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Pembayaran',
                            style: TextStyle(fontSize: 12, color: OC.muted)),
                        Text(rupiah(o.total),
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: OC.primary)),
                        Text(fmtDateComma(o.createdAt),
                            style: const TextStyle(fontSize: 11.5, color: OC.faint)),
                      ],
                    ),
                  ),
                  if (o.status == OrderStatus.waitingPayment)
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: OC.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => OrderPaymentScreen(orderId: o.id)),
                      ),
                      child: Text(
                          o.paymentMethod == PaymentMethod.cod
                              ? 'Konfirmasi'
                              : 'Bayar',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    )
                  else
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: OC.primary,
                        side: const BorderSide(color: OC.primary),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _openDetail(o),
                      child: const Text('Lihat Detail',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
