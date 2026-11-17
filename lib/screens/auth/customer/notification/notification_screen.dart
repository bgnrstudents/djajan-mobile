import 'package:flutter/material.dart';

import '../../../../config/app_config.dart';
import '../order/order_detail_screen.dart';
import '../../../../services/order_service.dart';
import '../order/order_widgets.dart';
import '../../../../services/notification_service.dart';
import '../../../../widgets/umkm_app_bar.dart';

/// Halaman pusat notifikasi: update pesanan, pembayaran, dan promo.
class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  static const Color primaryGreen = AppConfig.primaryColor;
  static const Color textDark = Color(0xFF183322);
  static const Color textMuted = Color(0xFF5D7263);
  static const Color background = Color(0xFFF5F9F6);

  @override
  Widget build(BuildContext context) {
    final service = NotificationService();

    return Scaffold(
      backgroundColor: background,
      appBar: DjajanAppBar(
        title: 'Notifikasi',
        actions: [
          AnimatedBuilder(
            animation: service,
            builder: (context, _) => TextButton(
              onPressed: service.hasUnread ? service.markAllAsRead : null,
              child: Text(
                'Tandai dibaca',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: service.hasUnread ? primaryGreen : textMuted,
                ),
              ),
            ),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: service,
        builder: (context, _) {
          final items = service.notifications;
          if (items.isEmpty) return const _EmptyNotifications();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _summaryCard(service.unreadCount, items.length),
              const SizedBox(height: 8),
              ..._buildGrouped(context, service, items),
            ],
          );
        },
      ),
    );
  }

  Widget _summaryCard(int unreadCount, int totalCount) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF176236), Color(0xFF0F4D2B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.notifications_active_outlined,
              color: Colors.white,
              size: 23,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  unreadCount == 0
                      ? 'Semua sudah terbaca'
                      : '$unreadCount belum dibaca',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$totalCount aktivitas terbaru di akun Anda',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildGrouped(
    BuildContext context,
    NotificationService service,
    List<AppNotification> items,
  ) {
    final children = <Widget>[];
    String? lastGroup;

    for (final item in items) {
      final group = _groupLabel(item.createdAt);
      if (group != lastGroup) {
        children.add(_sectionHeader(group));
        lastGroup = group;
      }
      children.add(
        _NotificationTile(
          item: item,
          onTap: () => _open(context, service, item),
        ),
      );
    }
    return children;
  }

  void _open(
    BuildContext context,
    NotificationService service,
    AppNotification item,
  ) {
    service.markAsRead(item.id);

    final orderId = item.orderId;
    if (orderId == null) return;

    if (OrderService().findById(orderId) == null) {
      showToast(context, 'Pesanan sudah tidak tersedia.');
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: orderId)),
    );
  }

  static Widget _sectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: textMuted,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  static String _groupLabel(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(time.year, time.month, time.day);
    final diff = today.difference(day).inDays;

    if (diff <= 0) return 'Hari Ini';
    if (diff == 1) return 'Kemarin';
    return '${time.day}/${time.month}/${time.year}';
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification item;
  final VoidCallback onTap;

  const _NotificationTile({required this.item, required this.onTap});

  static const Color textDark = Color(0xFF1E293B);
  static const Color textMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(item.type);

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => NotificationService().remove(item.id),
      background: Container(
        alignment: Alignment.centerRight,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF175D2B),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: Material(
        color: item.isRead ? Colors.white : const Color(0xFFEDF5EF),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: item.isRead
                    ? const Color(0xFFDCE8DE)
                    : const Color(0xFFB7D3BC),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: style.background,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(style.icon, size: 21, color: style.foreground),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: item.isRead
                                    ? FontWeight.w600
                                    : FontWeight.bold,
                                color: textDark,
                              ),
                            ),
                          ),
                          if (!item.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(left: 6),
                              decoration: const BoxDecoration(
                                color: Color(0xFF175D2B),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.message,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: textMuted,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        timeAgo(item.createdAt),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF7C9583),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _TypeStyle _styleFor(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.order:
        return const _TypeStyle(
          icon: Icons.receipt_long_outlined,
          foreground: Color(0xFF175D2B),
          background: Color(0xFFEAF3EC),
        );
      case AppNotificationType.payment:
        return const _TypeStyle(
          icon: Icons.account_balance_wallet_outlined,
          foreground: Color(0xFF175D2B),
          background: Color(0xFFEAF3EC),
        );
      case AppNotificationType.promo:
        return const _TypeStyle(
          icon: Icons.local_offer_outlined,
          foreground: Color(0xFF175D2B),
          background: Color(0xFFEAF3EC),
        );
      case AppNotificationType.info:
        return const _TypeStyle(
          icon: Icons.campaign_outlined,
          foreground: Color(0xFF175D2B),
          background: Color(0xFFEAF3EC),
        );
    }
  }
}

class _TypeStyle {
  final IconData icon;
  final Color foreground;
  final Color background;

  const _TypeStyle({
    required this.icon,
    required this.foreground,
    required this.background,
  });
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: Color(0xFFEAF3EC),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none,
                size: 44,
                color: NotificationScreen.primaryGreen,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Belum ada notifikasi',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: NotificationScreen.textDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pembaruan pesanan dan aktivitas akun Anda akan tampil di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: NotificationScreen.textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE4E9EF)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 17,
                    color: Color(0xFF08753E),
                  ),
                  SizedBox(width: 7),
                  Text(
                    'Cek kembali nanti',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
