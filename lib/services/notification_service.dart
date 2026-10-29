import 'package:flutter/foundation.dart';

import '../models/order.dart';

/// Jenis notifikasi yang tampil di aplikasi.
enum AppNotificationType { order, payment, promo, info }

class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final AppNotificationType type;
  final String? orderId;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    this.type = AppNotificationType.info,
    this.orderId,
    this.isRead = false,
  });

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      title: title,
      message: message,
      createdAt: createdAt,
      type: type,
      orderId: orderId,
      isRead: isRead ?? this.isRead,
    );
  }
}

/// Menyimpan daftar notifikasi pengguna (update pesanan, pembayaran, promo).
///
/// In-memory untuk prototipe; nanti diganti push notification / API.
class NotificationService extends ChangeNotifier {
  NotificationService._internal();

  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final List<AppNotification> _items = [];
  int _counter = 0;

  /// Notifikasi terbaru di atas.
  List<AppNotification> get notifications {
    final list = List<AppNotification>.from(_items);
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(list);
  }

  int get unreadCount => _items.where((n) => !n.isRead).length;
  bool get hasUnread => unreadCount > 0;
  bool get isEmpty => _items.isEmpty;

  void markAsRead(String id) {
    final i = _items.indexWhere((n) => n.id == id);
    if (i < 0 || _items[i].isRead) return;
    _items[i] = _items[i].copyWith(isRead: true);
    notifyListeners();
  }

  void markAllAsRead() {
    if (!hasUnread) return;
    for (var i = 0; i < _items.length; i++) {
      _items[i] = _items[i].copyWith(isRead: true);
    }
    notifyListeners();
  }

  void remove(String id) {
    _items.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  void syncOrders(List<Order> orders) {
    final orderIds = orders.map((order) => order.id).toSet();
    _items.removeWhere(
      (item) => item.orderId != null && !orderIds.contains(item.orderId),
    );
    for (final order in orders) {
      if (_items.any((item) => item.orderId == order.id)) continue;
      push(
        title: order.status == OrderStatus.waitingPayment
            ? 'Menunggu Pembayaran'
            : 'Pesanan Diperbarui',
        message: order.status == OrderStatus.waitingPayment
            ? 'Pesanan ${order.refId} menunggu pembayaran.'
            : 'Status pesanan ${order.refId} adalah ${order.status.label}.',
        type: order.status == OrderStatus.waitingPayment
            ? AppNotificationType.payment
            : AppNotificationType.order,
        orderId: order.id,
      );
    }
  }

  /// Menambah notifikasi baru (dipakai saat status pesanan berubah).
  AppNotification push({
    required String title,
    required String message,
    AppNotificationType type = AppNotificationType.order,
    String? orderId,
  }) {
    _counter++;
    final item = AppNotification(
      id: 'NTF-${DateTime.now().millisecondsSinceEpoch}-$_counter',
      title: title,
      message: message,
      createdAt: DateTime.now(),
      type: type,
      orderId: orderId,
    );
    _items.add(item);
    notifyListeners();
    return item;
  }
}

/// Format waktu relatif sederhana untuk daftar notifikasi.
String timeAgo(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'Baru saja';
  if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
  if (diff.inHours < 24) return '${diff.inHours} jam lalu';
  if (diff.inDays == 1) return 'Kemarin';
  if (diff.inDays < 7) return '${diff.inDays} hari lalu';
  return '${time.day}/${time.month}/${time.year}';
}
