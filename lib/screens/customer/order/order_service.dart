import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import 'order_model.dart';

class OrderService extends ChangeNotifier {
  OrderService._internal() {
    _seed();
  }

  static final OrderService _instance = OrderService._internal();
  factory OrderService() => _instance;

  static const int maxProofBytes = 5 * 1024 * 1024;

  final List<Order> _orders = [];
  int _counter = 1;

  List<Order> get orders {
    final list = List<Order>.from(_orders);
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(list);
  }

  Order? findById(String id) {
    for (final o in _orders) {
      if (o.id == id) return o;
    }
    return null;
  }

  PaymentAccount accountFor(String umkmId) {
    return _accounts[umkmId] ?? _defaultAccount;
  }

  Future<Order> createOrder({
    required List<CartLine> lines,
    required Map<String, VendorCheckout> options,
    required Recipient recipient,
    required PaymentMethod paymentMethod,
  }) async {
    if (lines.isEmpty) {
      throw const OrderException('Keranjang masih kosong.');
    }
    final recipientError = OrderValidator.recipientError(recipient);
    if (recipientError != null) throw OrderException(recipientError);
    recipient = OrderValidator.normalizeRecipient(recipient);

    final Map<String, List<CartLine>> grouped = {};
    for (final l in lines) {
      grouped.putIfAbsent(l.umkmId, () => []).add(l);
    }

    final vendors = <OrderVendor>[];
    for (final entry in grouped.entries) {
      final first = entry.value.first;
      final opt = options[entry.key] ??
          const VendorCheckout(delivery: DeliveryMethod.pickup);
      final isPO = entry.value.any((l) => l.type == OrderType.preOrder);

      if (isPO && opt.requiredAt == null) {
        throw OrderException(
            'Pilih waktu dibutuhkan untuk ${first.umkmName}.');
      }
      if (isPO && opt.requiredAt!.isBefore(DateTime.now())) {
        throw OrderException(
            'Waktu dibutuhkan ${first.umkmName} sudah terlewat.');
      }
      if (isPO) {
        final e = OrderValidator.purpose(opt.purpose);
        if (e != null) throw OrderException('${first.umkmName}: $e');
      }
      final noteErr = OrderValidator.packingNote(opt.note);
      if (noteErr != null) throw OrderException('${first.umkmName}: $noteErr');

      var delivery = opt.delivery;
      if (delivery == DeliveryMethod.courier && first.courierFee == null) {
        delivery = DeliveryMethod.pickup;
      }

      vendors.add(OrderVendor(
        umkmId: first.umkmId,
        umkmName: first.umkmName,
        umkmType: first.umkmType,
        type: isPO ? OrderType.preOrder : OrderType.instant,
        items: entry.value
            .map((l) => OrderItem(
                  productId: l.productId,
                  productName: l.productName,
                  variant: l.variant,
                  unit: l.unit,
                  imageUrl: l.imageUrl,
                  quantity: l.quantity,
                  price: l.price,
                ))
            .toList(),
        delivery: delivery,
        deliveryFee:
            delivery == DeliveryMethod.courier ? (first.courierFee ?? 0) : 0,
        pickupLocation: first.pickupLocation,
        requiredAt: isPO ? opt.requiredAt : null,
        purpose: isPO ? OrderValidator.clean(opt.purpose) : null,
        note: OrderValidator.clean(opt.note).isEmpty
            ? null
            : OrderValidator.clean(opt.note),
      ));
    }

    await Future.delayed(const Duration(milliseconds: 500));

    final now = DateTime.now();
    _counter++;
    final seq = _counter.toString().padLeft(3, '0');
    final date = '${now.year}${_two(now.month)}${_two(now.day)}';
    final isCod = paymentMethod == PaymentMethod.cod;

    final order = Order(
      id: 'ORD-$date-$seq',
      refId: '#DJN-$date-$seq',
      createdAt: now,
      vendors: vendors,
      recipient: recipient,
      paymentMethod: paymentMethod,
      serviceFee: 0,
      discount: 0,
      status: OrderStatus.waitingPayment,
      account: accountFor(vendors.first.umkmId),
      paymentDeadline: isCod ? null : now.add(const Duration(hours: 24)),
    );

    _orders.add(order);
    notifyListeners();
    return order;
  }

  Future<Order> submitPaymentProof(
    String orderId, {
    required Uint8List bytes,
    required String fileName,
  }) async {
    final order = _require(orderId);
    if (order.status != OrderStatus.waitingPayment &&
        order.status != OrderStatus.reviewing) {
      throw const OrderException('Pesanan ini tidak bisa dibayar lagi.');
    }
    if (bytes.isEmpty) {
      throw const OrderException('File bukti transfer kosong.');
    }
    if (bytes.length > maxProofBytes) {
      throw const OrderException('Ukuran file maksimal 5MB.');
    }

    await Future.delayed(const Duration(milliseconds: 900));

    return _replace(order.copyWith(
      proofBytes: bytes,
      proofName: fileName,
      proofUploadedAt: DateTime.now(),
      status: OrderStatus.reviewing,
    ));
  }

  Future<Order> confirmCodOrder(String orderId) async {
    final order = _require(orderId);
    if (order.paymentMethod != PaymentMethod.cod) {
      throw const OrderException('Pesanan ini memakai transfer / QRIS.');
    }
    if (order.status != OrderStatus.waitingPayment) {
      throw const OrderException('Pesanan sudah dikonfirmasi.');
    }
    await Future.delayed(const Duration(milliseconds: 600));
    return _replace(order.copyWith(status: OrderStatus.reviewing));
  }

  Future<Order> updateRecipient(String orderId, Recipient recipient) async {
    final order = _require(orderId);
    if (!order.status.canEdit) {
      throw const OrderException('Alamat tidak bisa diubah pada tahap ini.');
    }
    final error = OrderValidator.recipientError(recipient);
    if (error != null) throw OrderException(error);
    return _replace(
        order.copyWith(recipient: OrderValidator.normalizeRecipient(recipient)));
  }

  Future<Order> advanceStatus(String orderId) async {
    final order = _require(orderId);
    switch (order.status) {
      case OrderStatus.waitingPayment:
        throw const OrderException(
            'Unggah bukti transfer terlebih dahulu.');
      case OrderStatus.reviewing:
        return _replace(order.copyWith(status: OrderStatus.processing));
      case OrderStatus.processing:
        return _replace(order.copyWith(status: OrderStatus.delivering));
      case OrderStatus.delivering:
        return _replace(order.copyWith(status: OrderStatus.completed));
      case OrderStatus.completed:
      case OrderStatus.cancelled:
        throw const OrderException('Pesanan sudah berakhir.');
    }
  }

  Future<Order> cancelOrder(String orderId) async {
    final order = _require(orderId);
    if (!order.status.canCancel) {
      throw const OrderException(
          'Pesanan yang sudah diproses tidak dapat dibatalkan.');
    }
    return _replace(order.copyWith(status: OrderStatus.cancelled));
  }

  Future<void> deleteOrder(String orderId) async {
    final order = _require(orderId);
    if (order.status.isActive) {
      throw const OrderException(
          'Batalkan pesanan terlebih dahulu sebelum menghapus.');
    }
    _orders.removeWhere((o) => o.id == order.id);
    notifyListeners();
  }

  Order _require(String id) {
    final o = findById(id);
    if (o == null) throw const OrderException('Pesanan tidak ditemukan.');
    return o;
  }

  Order _replace(Order updated) {
    final i = _orders.indexWhere((o) => o.id == updated.id);
    _orders[i] = updated;
    notifyListeners();
    return updated;
  }

  static String _two(int v) => v.toString().padLeft(2, '0');

  static const PaymentAccount _defaultAccount = PaymentAccount(
    bank: 'BRI',
    bankFullName: 'PT Bank Rakyat Indonesia',
    number: '3241-01-098273-53-1',
    holder: 'Bu Minten (Dapur Bu Minten)',
  );

  static const Map<String, PaymentAccount> _accounts = {
    'umkm-bu-minten': _defaultAccount,
  };

  void _seed() {
    _orders.add(Order(
      id: 'ORD-20260915-001',
      refId: '#DJN-20260915-001',
      createdAt: DateTime(2026, 9, 15, 9, 15),
      vendors: [
        OrderVendor(
          umkmId: 'umkm-bu-minten',
          umkmName: 'Dapur Bu Minten',
          umkmType: 'Spesialis Katering',
          type: OrderType.preOrder,
          items: const [
            OrderItem(
              productId: 'p-nasi-geprek',
              productName: 'Nasi Kotak Ayam Geprek',
              variant: 'Nasi kuning wangi, tempe bacem, lalapan segar',
              unit: 'box',
              imageUrl: SampleData.imgNasiGeprek,
              quantity: 10,
              price: 15000,
            ),
          ],
          delivery: DeliveryMethod.courier,
          deliveryFee: 5000,
          pickupLocation: 'Dapur Bu Minten RT 01',
          requiredAt: DateTime(2026, 9, 20, 11, 0),
          purpose: 'Rapat Desa Kreyongan Atas',
          note: 'Sambal dipisah pakai cup kecil, kemangi dipacking rapi kering.',
        ),
      ],
      recipient: const Recipient(
        name: 'Muhammad Rizki',
        phone: '0812-3456-7890',
        address:
            'RT 03 / RW 02, Balai Pertemuan RW, Desa Kreyongan Atas',
        addressNote: 'Rumah pagar hijau samping pos ronda kamling',
      ),
      paymentMethod: PaymentMethod.qris,
      serviceFee: 1000,
      discount: 5000,
      status: OrderStatus.reviewing,
      account: _defaultAccount,
    ));
  }
}

class SampleData {
  static const String imgNasiGeprek =
      'https://images.unsplash.com/photo-1626645738196-c2a7c87a8f58?w=400&q=80';
  static const String imgEsTeh =
      'https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=400&q=80';

  static const List<CartLine> cart = [
    CartLine(
      productId: 'p-nasi-geprek',
      productName: 'Nasi Kotak Ayam Geprek',
      variant: 'Porsi Spesial Kenduri',
      unit: 'Kotak',
      imageUrl: imgNasiGeprek,
      quantity: 10,
      price: 15000,
      type: OrderType.preOrder,
      umkmId: 'umkm-bu-minten',
      umkmName: 'Dapur Bu Minten',
      umkmType: 'Spesialis Katering & Kotakan',
      courierFee: 5000,
      pickupLocation: 'Ke dapur Bu Minten RT 01',
    ),
    CartLine(
      productId: 'p-es-teh',
      productName: 'Es Teh Solo Original',
      variant: 'Gula Asli, Cup Jumbo',
      unit: 'Gelas',
      imageUrl: imgEsTeh,
      quantity: 5,
      price: 5000,
      type: OrderType.instant,
      umkmId: 'umkm-pak-budi',
      umkmName: 'Toko Pak Budi',
      umkmType: 'Warung Kelontong & Es Tradisional',
      courierFee: null,
      pickupLocation: 'Toko Pak Budi',
    ),
  ];
}
