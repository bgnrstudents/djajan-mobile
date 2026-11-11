import 'package:flutter/foundation.dart';

import 'notification_service.dart';
import '../models/order.dart';
import '../models/umkm_seller_models.dart';
import 'api_service.dart';

class OrderService extends ChangeNotifier {
  OrderService._internal();

  static final OrderService _instance = OrderService._internal();
  factory OrderService() => _instance;

  static const int maxProofBytes = 5 * 1024 * 1024;

  final List<Order> _orders = [];

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

  Future<void> loadFromApi() async {
    final data = await ApiService.get('pesanan/saya');
    if (data is! List) {
      throw ApiException('Format riwayat pesanan dari server tidak valid.');
    }
    _orders
      ..clear()
      ..addAll(
        data.whereType<Map>().map(
          (item) => Order.fromJson(Map<String, dynamic>.from(item)),
        ),
      );
    NotificationService().syncOrders(_orders);
    notifyListeners();
  }

  void clear() {
    _orders.clear();
    notifyListeners();
  }

  void seedOrders(List<Order> orders) {
    _orders
      ..clear()
      ..addAll(orders);
    notifyListeners();
  }

  Future<Order?> syncOrder(String orderId) async {
    try {
      final data = await ApiService.get('pesanan/saya/$orderId');
      if (data is Map) {
        final updated = Order.fromJson(Map<String, dynamic>.from(data));
        _replace(updated);
        notifyListeners();
        return updated;
      }
    } catch (_) {
      // Fallback jika network bermasalah
    }
    return findById(orderId);
  }

  Future<String?> refreshPaymentStatus(String orderId) async {
    final order = _require(orderId);
    final groupId = order.checkoutId ?? orderId;
    final data = await ApiService.get('pesanan/saya/group/$groupId');
    final paymentStatus = _effectivePaymentStatus(
      data['payment_status'],
      data['status_pembayaran'],
    );
    final orderStatus = data['status_pesanan']?.toString().toLowerCase();
    
    // Validasi status pesanan menggunakan validation logic baru
    final status = _validateOrderStatus(
      current: order.status,
      paymentDeadline: order.paymentDeadline,
      backendPaymentStatus: paymentStatus,
      backendOrderStatus: orderStatus,
    );
    
    if (status != order.status) {
      _replace(order.copyWith(status: status));
    }
    notifyListeners();
    return paymentStatus;
  }

  Future<String?> refreshPaymentStatusUntilSettled(
    String orderId, {
    int attempts = 4,
  }) async {
    String? paymentStatus;
    for (var attempt = 0; attempt < attempts; attempt++) {
      if (attempt > 0) {
        await Future<void>.delayed(Duration(seconds: attempt == 1 ? 2 : 3));
      }
      paymentStatus = await refreshPaymentStatus(orderId);
      if (paymentStatus == 'paid' ||
          paymentStatus == 'settlement' ||
          paymentStatus == 'capture' ||
          paymentStatus == 'failed') {
        return paymentStatus;
      }
    }
    return paymentStatus;
  }

  static String _effectivePaymentStatus(Object? payment, Object? legacy) {
    final values = [payment, legacy]
        .map((value) => value?.toString().trim().toLowerCase() ?? '')
        .where((value) => value.isNotEmpty)
        .toList();
    if (values.any(
      (value) => value == 'paid' || value == 'settlement' || value == 'capture',
    )) {
      return 'paid';
    }
    if (values.any(
      (value) =>
          value == 'failed' ||
          value == 'deny' ||
          value == 'cancel' ||
          value == 'expire',
    )) {
      return 'failed';
    }
    return values.firstOrNull ?? 'pending';
  }

  static OrderStatus _statusFromPayment({
    required String paymentStatus,
    required String? orderStatus,
    required OrderStatus current,
  }) {
    if (paymentStatus == 'paid' ||
        paymentStatus == 'settlement' ||
        paymentStatus == 'capture') {
      return OrderStatus.reviewing;
    }
    if (paymentStatus == 'failed' ||
        paymentStatus == 'deny' ||
        paymentStatus == 'cancel' ||
        paymentStatus == 'expire') {
      return OrderStatus.cancelled;
    }

    switch (orderStatus) {
      case 'diterima':
      case 'confirmed':
        return OrderStatus.reviewing;
      case 'diproses':
      case 'processing':
        return OrderStatus.processing;
      case 'diantar':
      case 'delivering':
      case 'ready':
        return OrderStatus.delivering;
      case 'selesai':
      case 'completed':
        return OrderStatus.completed;
      case 'ditolak':
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return current;
    }
  }

  /// Helper untuk validasi pembayaran menggunakan StatusPesanan
  static bool _isValidPaymentStatusTransition(
    OrderStatus current,
    OrderStatus next,
  ) {
    final currentPesanan = current.toStatusPesanan;
    final nextPesanan = next.toStatusPesanan;
    return StatusPesananX.isValidTransition(currentPesanan, nextPesanan);
  }

  /// Helper untuk validasi payment expiry
  static OrderStatus _validatePaymentExpiry(
    OrderStatus current,
    DateTime? paymentDeadline,
  ) {
    if (paymentDeadline == null) return current;
    final now = DateTime.now();
    if (now.isAfter(paymentDeadline) && 
        (current == OrderStatus.waitingPayment || current == OrderStatus.reviewing)) {
      return OrderStatus.cancelled;
    }
    return current;
  }

  /// Validasi lengkap status pesanan dengan validation rules
  static OrderStatus _validateOrderStatus({
    required OrderStatus current,
    DateTime? paymentDeadline,
    String? backendPaymentStatus,
    String? backendOrderStatus,
  }) {
    var validated = current;
    
    // 1. Validasi payment expiry
    validated = _validatePaymentExpiry(validated, paymentDeadline);
    
    // 2. Validasi status transition (jika status berubah dari backend)
    if (backendPaymentStatus != null || backendOrderStatus != null) {
      final fromBackend = _statusFromPayment(
        paymentStatus: backendPaymentStatus ?? 'pending',
        orderStatus: backendOrderStatus,
        current: validated,
      );
      if (fromBackend != validated && 
          _isValidPaymentStatusTransition(validated, fromBackend)) {
        validated = fromBackend;
      }
    }
    
    return validated;
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
      final opt =
          options[entry.key] ??
          const VendorCheckout(delivery: DeliveryMethod.pickup);
      final isPO = entry.value.any((l) => l.type == OrderType.preOrder);

      if (isPO && opt.requiredAt == null) {
        throw OrderException('Pilih waktu dibutuhkan untuk ${first.umkmName}.');
      }
      if (isPO && opt.requiredAt!.isBefore(DateTime.now())) {
        throw OrderException(
          'Waktu dibutuhkan ${first.umkmName} sudah terlewat.',
        );
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

      vendors.add(
        OrderVendor(
          umkmId: first.umkmId,
          umkmName: first.umkmName,
          umkmType: first.umkmType,
          type: isPO ? OrderType.preOrder : OrderType.instant,
          items: entry.value
              .map(
                (l) => OrderItem(
                  productId: l.productId,
                  productName: l.productName,
                  variant: l.variant,
                  unit: l.unit,
                  imageUrl: l.imageUrl,
                  quantity: l.quantity,
                  price: l.price,
                ),
              )
              .toList(),
          delivery: delivery,
          deliveryFee: delivery == DeliveryMethod.courier
              ? (first.courierFee ?? 0)
              : 0,
          pickupLocation: first.pickupLocation,
          requiredAt: isPO ? opt.requiredAt : null,
          purpose: isPO ? OrderValidator.clean(opt.purpose) : null,
          note: OrderValidator.clean(opt.note).isEmpty
              ? null
              : OrderValidator.clean(opt.note),
        ),
      );
    }

    final isCod = paymentMethod == PaymentMethod.cod;
    final groupedLines = <String, List<CartLine>>{};
    for (final line in lines) {
      groupedLines.putIfAbsent(line.umkmId, () => []).add(line);
    }
    final backendData = await ApiService.postJson('pesanan/checkout', {
      'metode_pembayaran': isCod ? 'cod' : 'midtrans',
      if (recipient.addressId != null) 'id_alamat': recipient.addressId,
      if (recipient.latitude != null) 'latitude': recipient.latitude,
      if (recipient.longitude != null) 'longitude': recipient.longitude,
      'alamat_tujuan': recipient.address,
      'groups': groupedLines.entries.map((entry) {
        final vendor = vendors.firstWhere((item) => item.umkmId == entry.key);
        final option = options[entry.key]!;
        return {
          'id_umkm': int.tryParse(entry.key) ?? 0,
          'metode_pengiriman': vendor.delivery == DeliveryMethod.courier
              ? 'kurir'
              : 'pickup',
          'catatan': option.note ?? recipient.addressNote ?? '',
          'waktu_dibutuhkan': option.requiredAt?.toIso8601String(),
          'keperluan_acara': option.purpose ?? '',
          'items': entry.value
              .map((item) => {
                    'id_produk': int.tryParse(item.productId) ?? 0,
                    'jumlah': item.quantity,
                  })
              .toList(),
        };
      }).toList(),
    });

    final now = DateTime.now();
    final backendOrderId =
        (backendData['id_checkout'] ?? backendData['id_pesanan'] ?? '')
            .toString();
    if (backendOrderId.isEmpty) {
      throw const OrderException('Server tidak mengembalikan nomor pesanan.');
    }

    // Validasi status pesanan yang dibuat
    final initialStatus = _validateOrderStatus(
      current: OrderStatus.waitingPayment,
      paymentDeadline: isCod ? null : now.add(const Duration(hours: 2)),
      backendPaymentStatus: backendData['payment_status']?.toString(),
      backendOrderStatus: null,
    );

    final order = Order(
      id: backendOrderId,
      checkoutId: backendOrderId,
      refId: backendOrderId,
      createdAt: now,
      vendors: vendors,
      recipient: recipient,
      paymentMethod: paymentMethod,
      serviceFee: 0,
      discount: 0,
      status: initialStatus,
      account: accountFor(vendors.first.umkmId),
      paymentDeadline: isCod ? null : now.add(const Duration(hours: 2)),
      snapToken: backendData['snap_token']?.toString(),
      paymentUrl: backendData['payment_url']?.toString(),
    );
    
    // Log jika payment expired saat creation
    if (!isCod && now.isAfter(order.paymentDeadline!)) {
      print('Warning: Order ${order.id} created with expired payment deadline');
    }

    _orders.add(order);
    notifyListeners();

    _notify(
      title: isCod ? 'Pesanan COD Dibuat' : 'Menunggu Pembayaran',
      message: isCod
          ? 'Pesanan di ${_vendorName(order)} berhasil dibuat. UMKM akan mengonfirmasi pesanan Anda.'
          : 'Pesanan di ${_vendorName(order)} berhasil dibuat. Selesaikan pembayaran sebelum batas waktu.',
      type: isCod ? AppNotificationType.order : AppNotificationType.payment,
      orderId: order.id,
    );
    return order;
  }

  Future<Order> submitPaymentProof(
    String orderId, {
    required Uint8List bytes,
    required String fileName,
  }) async {
    final order = _require(orderId);
    
    // Validasi status pesanan dengan payment expiry
    final validatedStatus = _validateOrderStatus(
      current: order.status,
      paymentDeadline: order.paymentDeadline,
      backendPaymentStatus: null,
      backendOrderStatus: null,
    );
    
    if (validatedStatus != order.status) {
      // Pembayaran expired
      return _replace(order.copyWith(status: OrderStatus.cancelled));
    }
    
    if (validatedStatus != OrderStatus.waitingPayment &&
        validatedStatus != OrderStatus.reviewing) {
      throw const OrderException('Pesanan ini tidak bisa dibayar lagi.');
    }
    
    if (bytes.isEmpty) {
      throw const OrderException('File bukti transfer kosong.');
    }
    if (bytes.length > maxProofBytes) {
      throw const OrderException('Ukuran file maksimal 5MB.');
    }

    await Future.delayed(const Duration(milliseconds: 900));

    final updated = _replace(
      order.copyWith(
        proofBytes: bytes,
        proofName: fileName,
        proofUploadedAt: DateTime.now(),
        status: OrderStatus.reviewing,
      ),
    );

    _notify(
      title: 'Bukti Pembayaran Terkirim',
      message:
          'Bukti pembayaran untuk ${_vendorName(updated)} sedang diperiksa UMKM.',
      type: AppNotificationType.payment,
      orderId: updated.id,
    );
    return updated;
  }

  Future<Order> confirmCodOrder(String orderId) async {
    final order = _require(orderId);
    if (order.paymentMethod != PaymentMethod.cod) {
      throw const OrderException('Pesanan ini memakai transfer / QRIS.');
    }
    
    // Validasi status pesanan dengan payment expiry
    final validatedStatus = _validateOrderStatus(
      current: order.status,
      paymentDeadline: order.paymentDeadline,
      backendPaymentStatus: null,
      backendOrderStatus: null,
    );
    
    if (validatedStatus != order.status) {
      // Pembayaran expired
      return _replace(order.copyWith(status: OrderStatus.cancelled));
    }
    
    if (validatedStatus != OrderStatus.waitingPayment) {
      throw const OrderException('Pesanan sudah dikonfirmasi.');
    }
    
    // Validasi status transition menggunakan StatusPesanan
    final currentPesanan = order.status.toStatusPesanan;
    final nextPesanan = OrderStatus.reviewing.toStatusPesanan;
    
    if (!StatusPesananX.isValidTransition(currentPesanan, nextPesanan)) {
      throw const OrderException('Transisi status pesanan tidak valid.');
    }
    
    await Future.delayed(const Duration(milliseconds: 600));
    final updated = _replace(order.copyWith(status: OrderStatus.reviewing));
    _notify(
      title: 'Pesanan COD Dikonfirmasi',
      message: 'Pesanan COD di ${_vendorName(updated)} siap diproses.',
      orderId: updated.id,
    );
    return updated;
  }

  Future<Order> markAsPaidViaMidtrans(String orderId) async {
    final order = _require(orderId);
    if (order.status != OrderStatus.waitingPayment) {
      throw const OrderException(
        'Pesanan ini sudah dibayar atau dalam proses.',
      );
    }
    
    // Validasi payment expiry sebelum menandai sebagai paid
    final validatedStatus = _validateOrderStatus(
      current: order.status,
      paymentDeadline: order.paymentDeadline,
      backendPaymentStatus: 'paid',
      backendOrderStatus: null,
    );
    
    if (validatedStatus != order.status) {
      // Pembayaran expired - secara otomatis batalkan pesanan
      _notify(
        title: 'Pembayaran Expired',
        message: 'Pembayaran pesanan ${order.refId} telah expired dan dibatalkan.',
        type: AppNotificationType.payment,
        orderId: order.id,
      );
      return _replace(order.copyWith(status: OrderStatus.cancelled));
    }
    
    await Future.delayed(const Duration(milliseconds: 600));
    
    // Validasi status transition menggunakan StatusPesanan
    final currentPesanan = order.status.toStatusPesanan;
    final nextPesanan = OrderStatus.reviewing.toStatusPesanan;
    
    if (!StatusPesananX.isValidTransition(currentPesanan, nextPesanan)) {
      throw const OrderException('Transisi status pembayaran tidak valid.');
    }
    
    final updated = _replace(order.copyWith(status: OrderStatus.reviewing));
    _notify(
      title: 'Pembayaran Berhasil',
      message:
          'Pembayaran pesanan ${updated.refId} berhasil. UMKM akan segera memproses.',
      type: AppNotificationType.payment,
      orderId: updated.id,
    );
    return updated;
  }

  Future<Order> updateRecipient(String orderId, Recipient recipient) async {
    final order = _require(orderId);
    if (!order.status.canEdit) {
      throw const OrderException('Alamat tidak bisa diubah pada tahap ini.');
    }
    final error = OrderValidator.recipientError(recipient);
    if (error != null) throw OrderException(error);
    return _replace(
      order.copyWith(recipient: OrderValidator.normalizeRecipient(recipient)),
    );
  }

  Future<Order> advanceStatus(String orderId) async {
    final order = _require(orderId);
    final OrderStatus next;
    
    switch (order.status) {
      case OrderStatus.waitingPayment:
        throw const OrderException('Unggah bukti transfer terlebih dahulu.');
      case OrderStatus.reviewing:
        next = OrderStatus.processing;
        break;
      case OrderStatus.processing:
        next = OrderStatus.delivering;
        break;
      case OrderStatus.delivering:
        next = OrderStatus.completed;
        break;
      case OrderStatus.completed:
      case OrderStatus.cancelled:
        throw const OrderException('Pesanan sudah berakhir.');
    }

    // Validasi status menggunakan StatusPesanan
    final currentStatusPesanan = order.status.toStatusPesanan;
    final nextStatusPesanan = next.toStatusPesanan;
    
    if (!StatusPesananX.isValidTransition(currentStatusPesanan, nextStatusPesanan)) {
      throw const OrderException('Status pesanan tidak valid.');
    }

    // Validasi untuk stock protection - cek status berdasarkan business logic
    final currentOrderStatus = order.status;
    if (currentOrderStatus == OrderStatus.processing || 
        currentOrderStatus == OrderStatus.delivering) {
      // Status ini memerlukan validasi stok
      // TODO: Integrasi dengan service validasi stok
    }

    final updated = _replace(order.copyWith(status: next));
    _notify(
      title: _statusTitle(next),
      message: _statusMessage(updated),
      orderId: updated.id,
    );
    return updated;
  }

  Future<Order> cancelOrder(String orderId, {String? reason}) async {
    final order = _require(orderId);
    if (!order.status.canCancel) {
      throw const OrderException(
        'Pesanan yang sudah diproses tidak dapat dibatalkan.',
      );
    }

    try {
      final res = await ApiService.post('pesanan/batal', {
        'id_pesanan': orderId,
        if (reason != null && reason.trim().isNotEmpty) 'alasan': reason.trim(),
      });
      if (res is Map) {
        final updated = Order.fromJson(Map<String, dynamic>.from(res));
        _replace(updated);
        _notify(
          title: 'Pesanan Dibatalkan',
          message: 'Pesanan ${updated.refId} telah dibatalkan.',
          type: AppNotificationType.order,
          orderId: updated.id,
        );
        return updated;
      }
    } on ApiException catch (e) {
      if (e.pesan.contains('Endpoint API tidak ditemukan') ||
          e.pesan.contains('Tidak dapat terhubung') ||
          e.pesan.contains('Terjadi kesalahan pada server') ||
          e.pesan.contains('Terjadi kesalahan koneksi') ||
          e.pesan.contains('Koneksi internet terputus')) {
        // Fallback jika offline atau server pengujian tidak aktif
      } else {
        throw OrderException(e.pesan);
      }
    } catch (_) {
      // Offline fallback: lanjutkan pembatalan lokal
    }

    final updated = _replace(
      order.copyWith(
        status: OrderStatus.cancelled,
        cancelReason: reason ?? 'Dibatalkan oleh pelanggan',
        cancelledBy: 'pelanggan',
        cancelledAt: DateTime.now(),
      ),
    );
    _notify(
      title: 'Pesanan Dibatalkan',
      message: 'Pesanan ${updated.refId} telah dibatalkan.',
      orderId: updated.id,
    );
    return updated;
  }

  Future<Order> completeOrder(String orderId) async {
    final order = _require(orderId);
    if (!order.status.canComplete) {
      throw const OrderException(
        'Pesanan belum dapat diselesaikan pada status ini.',
      );
    }

    try {
      final res = await ApiService.post('pesanan/selesai', {
        'id_pesanan': orderId,
      });
      if (res is Map) {
        final updated = Order.fromJson(Map<String, dynamic>.from(res));
        _replace(updated);
        _notify(
          title: 'Pesanan Selesai',
          message: 'Pesanan ${updated.refId} telah Anda konfirmasi selesai. Terima kasih!',
          type: AppNotificationType.order,
          orderId: updated.id,
        );
        return updated;
      }
    } on ApiException catch (e) {
      if (e.pesan.contains('Endpoint API tidak ditemukan') ||
          e.pesan.contains('Tidak dapat terhubung') ||
          e.pesan.contains('Terjadi kesalahan pada server') ||
          e.pesan.contains('Terjadi kesalahan koneksi') ||
          e.pesan.contains('Koneksi internet terputus')) {
        // Fallback jika offline
      } else {
        throw OrderException(e.pesan);
      }
    } catch (_) {
      // Offline fallback
    }

    final updated = _replace(
      order.copyWith(
        status: OrderStatus.completed,
        completedAt: DateTime.now(),
      ),
    );
    _notify(
      title: 'Pesanan Selesai',
      message: 'Pesanan ${updated.refId} telah Anda konfirmasi selesai.',
      type: AppNotificationType.order,
      orderId: updated.id,
    );
    return updated;
  }

  Future<void> submitOrderReview({
    required String orderId,
    required int rating,
    String? comment,
  }) async {
    final order = _require(orderId);
    if (order.status != OrderStatus.completed) {
      throw const OrderException(
        'Hanya pesanan yang sudah selesai yang dapat diberi ulasan.',
      );
    }

    try {
      await ApiService.postJson('pesanan/ulasan', {
        'id_pesanan': orderId,
        'rating': rating,
        if (comment != null && comment.trim().isNotEmpty)
          'komentar': comment.trim(),
      });
    } on ApiException catch (e) {
      if (e.pesan.contains('Endpoint API tidak ditemukan') ||
          e.pesan.contains('Tidak dapat terhubung') ||
          e.pesan.contains('Terjadi kesalahan koneksi')) {
        // Fallback offline
      } else {
        throw OrderException(e.pesan);
      }
    } catch (_) {
      // Fallback offline
    }

    final updated = order.copyWith(
      rating: rating,
      reviewNote: comment,
    );
    _replace(updated);
  }

  Future<void> deleteOrder(String orderId) async {
    final order = _require(orderId);
    if (order.status.isActive) {
      throw const OrderException(
        'Batalkan pesanan terlebih dahulu sebelum menghapus.',
      );
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

  // -------------------------------------------------------- Notifikasi
  void _notify({
    required String title,
    required String message,
    required String orderId,
    AppNotificationType type = AppNotificationType.order,
  }) {
    NotificationService().push(
      title: title,
      message: message,
      type: type,
      orderId: orderId,
    );
  }

  static String _vendorName(Order order) =>
      order.vendors.isEmpty ? 'UMKM' : order.vendors.first.umkmName;

  static String _statusTitle(OrderStatus status) {
    switch (status) {
      case OrderStatus.processing:
        return 'Pesanan Sedang Diproses';
      case OrderStatus.delivering:
        return 'Pesanan Sedang Dikirim';
      case OrderStatus.completed:
        return 'Pesanan Selesai';
      case OrderStatus.waitingPayment:
      case OrderStatus.reviewing:
      case OrderStatus.cancelled:
        return 'Update Pesanan';
    }
  }

  static String _statusMessage(Order order) {
    switch (order.status) {
      case OrderStatus.processing:
        return '${_vendorName(order)} sedang menyiapkan pesanan ${order.refId}.';
      case OrderStatus.delivering:
        return 'Kurir warga sedang mengantar pesanan ${order.refId}.';
      case OrderStatus.completed:
        return 'Pesanan ${order.refId} sudah selesai. Jangan lupa beri ulasan!';
      case OrderStatus.waitingPayment:
      case OrderStatus.reviewing:
      case OrderStatus.cancelled:
        return 'Status pesanan ${order.refId} diperbarui.';
    }
  }

  Future<OngkirCalculation> calculateDeliveryFee({
    required int umkmId,
    required DeliveryMethod delivery,
    int? addressId,
    double? latitude,
    double? longitude,
  }) async {
    final methodStr = delivery == DeliveryMethod.courier ? 'kurir' : 'pickup';
    try {
      final res = await ApiService.postJson('ongkir_hitung', {
        'id_umkm': umkmId,
        'metode_pengiriman': methodStr,
        if (addressId != null) 'id_alamat': addressId,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      });

      if (res is Map<String, dynamic>) {
        return OngkirCalculation.fromJson(res);
      }
      return OngkirCalculation(
        umkmId: umkmId,
        umkmName: '',
        deliveryMethod: methodStr,
        deliveryFee: 0,
        isFree: true,
        message: 'Kalkulasi default',
        isOutOfRange: false,
      );
    } on ApiException catch (e) {
      final isOutOfRange = e.pesan.toLowerCase().contains('di luar jangkauan') ||
          e.pesan.toLowerCase().contains('jangkauan');
      return OngkirCalculation(
        umkmId: umkmId,
        umkmName: '',
        deliveryMethod: methodStr,
        deliveryFee: 0,
        isFree: false,
        message: e.pesan,
        isOutOfRange: isOutOfRange,
      );
    }
  }

  static const PaymentAccount _defaultAccount = PaymentAccount(
    bank: 'BRI',
    bankFullName: 'PT Bank Rakyat Indonesia',
    number: '3241-01-098273-53-1',
    holder: 'Bu Minten (Dapur Bu Minten)',
  );

  static const Map<String, PaymentAccount> _accounts = {
    'umkm-bu-minten': _defaultAccount,
  };
}
