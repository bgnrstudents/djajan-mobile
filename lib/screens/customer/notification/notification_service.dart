import 'package:flutter/foundation.dart';

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
  NotificationService._internal() {
    _seed();
  }

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

  void _seed() {
    final now = DateTime.now();
    _items.addAll([
      AppNotification(
        id: 'NTF-seed-1',
        title: 'Pesanan Sedang Ditinjau',
        message:
            'Dapur Bu Minten sedang memeriksa ketersediaan 10 Kotak Nasi Kotak Ayam Geprek untuk pesanan Anda.',
        createdAt: now.subtract(const Duration(minutes: 12)),
        type: AppNotificationType.order,
        orderId: 'ORD-20260915-001',
      ),
      AppNotification(
        id: 'NTF-seed-2',
        title: 'Menunggu Pembayaran',
        message:
            'Selesaikan pembayaran pesanan Anda agar dapat segera diproses oleh UMKM.',
        createdAt: now.subtract(const Duration(minutes: 30)),
        type: AppNotificationType.payment,
        orderId: 'ORD-20260915-001',
      ),
      AppNotification(
        id: 'NTF-seed-3',
        title: 'Gratis Ongkir Kurir Warga',
        message:
            'Promo gotong royong khusus pesanan hari ini di Desa Kreyongan Atas.',
        createdAt: now.subtract(const Duration(days: 1, hours: 2)),
        type: AppNotificationType.promo,
        isRead: true,
      ),
      AppNotification(
        id: 'NTF-seed-4',
        title: 'Selamat Datang di Djajan',
        message:
            'Nikmati aneka jajanan & kuliner rumahan tetangga desa. Dukung UMKM Kreyongan Atas!',
        createdAt: now.subtract(const Duration(days: 2, hours: 5)),
        type: AppNotificationType.info,
        isRead: true,
      ),
    ]);
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
