import 'package:flutter/material.dart';

import '../../../models/order.dart';
import '../../../services/api_service.dart';
import '../../../services/order_service.dart';
import 'order_detail_screen.dart';
import 'order_payment_screen.dart';
import 'midtrans_payment_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: OC.bg,
      child: AnimatedBuilder(
        animation: _service,
        builder: (context, _) {
          final list = _filtered();
          return ListView(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
            children: [
              const DjajanPageHeader(
                title: 'Pesanan Saya',
                subtitle: 'Pantau pesanan jajan & katering dari UMKM desa',
                padding: EdgeInsets.zero,
              ),
              const SizedBox(height: 12),
              _filters(),
              const SizedBox(height: 12),
              if (list.isEmpty) _empty() else ...list.map(_orderCard),
            ],
          );
        },
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
                    fontSize: 13,
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
      padding: const EdgeInsets.symmetric(vertical: 56),
      child: Column(
        children: [
          const Icon(Icons.receipt_long_outlined, size: 60, color: OC.faint),
          const SizedBox(height: 12),
          const Text('Belum ada pesanan',
              style: TextStyle(
                  fontSize: 16.5, fontWeight: FontWeight.w700, color: OC.muted)),
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
        return (bg: OC.banner, fg: OC.mintText);
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
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
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
                            fontSize: 13.5,
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
                  NetImage(url: firstItem.imageUrl, width: 56, height: 56, radius: 10),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(o.vendorNames,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: OC.muted)),
                        Text(firstItem.productName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: OC.ink)),
                        Text(
                            more > 0
                                ? '${firstItem.quantity}x ${firstItem.unit.toLowerCase()} • +$more menu lainnya'
                                : '${firstItem.quantity}x ${firstItem.unit.toLowerCase()}',
                            style: const TextStyle(fontSize: 12, color: OC.muted)),
                      ],
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
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
                        Text(rupiah(o.total), style: OT.moneyLarge),
                        Text(fmtDateComma(o.createdAt),
                            style: const TextStyle(fontSize: 11.5, color: OC.faint)),
                      ],
                    ),
                  ),
                  if (o.status == OrderStatus.waitingPayment)
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: OC.primary,
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11)),
                      ),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                o.paymentMethod == PaymentMethod.midtrans
                                ? MidtransPaymentScreen(orderId: o.id)
                                : OrderPaymentScreen(orderId: o.id),
                          ),
                        );
                        if (o.paymentMethod == PaymentMethod.midtrans) {
                          try {
                            await _service.refreshPaymentStatus(o.id);
                          } on ApiException {
                            // The list remains usable if the status endpoint is temporarily unavailable.
                          }
                        }
                      },
                      child: Text(
                          o.paymentMethod == PaymentMethod.cod
                              ? 'Konfirmasi'
                              : 'Bayar',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700)),
                    )
                  else
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: OC.primary,
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        side: const BorderSide(color: OC.primary),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11)),
                      ),
                      onPressed: () => _openDetail(o),
                      child: const Text('Lihat Detail',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700)),
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
