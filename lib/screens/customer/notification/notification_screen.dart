import 'package:flutter/material.dart';

import '../../../config/app_config.dart';
import '../order/order_detail_screen.dart';
import '../../../services/order_service.dart';
import '../order/order_widgets.dart';
import '../../../services/notification_service.dart';

/// Halaman pusat notifikasi: update pesanan, pembayaran, dan promo.
class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  static const Color primaryGreen = AppConfig.primaryColor;
  static const Color textDark = Color(0xFF1E293B);
  static const Color textMuted = Color(0xFF64748B);
  static const Color background = Color(0xFFF8F9FD);

  @override
  Widget build(BuildContext context) {
    final service = NotificationService();

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifikasi',
          style: TextStyle(
            color: textDark,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
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
            children: _buildGrouped(context, service, items),
          );
        },
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
          color: const Color(0xFFEF6461),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: Material(
        color: item.isRead ? Colors.white : const Color(0xFFF1F8F3),
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
                    ? const Color(0xFFE4E9EF)
                    : const Color(0xFFBDDCC7),
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
                                color: Color(0xFF16A34A),
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
                          color: Color(0xFF94A3B8),
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
          foreground: Color(0xFF08753E),
          background: Color(0xFFDDF6E9),
        );
      case AppNotificationType.payment:
        return const _TypeStyle(
          icon: Icons.account_balance_wallet_outlined,
          foreground: Color(0xFFC56500),
          background: Color(0xFFFFF0D8),
        );
      case AppNotificationType.promo:
        return const _TypeStyle(
          icon: Icons.local_offer_outlined,
          foreground: Color(0xFF7C3AED),
          background: Color(0xFFF0E9FE),
        );
      case AppNotificationType.info:
        return const _TypeStyle(
          icon: Icons.campaign_outlined,
          foreground: Color(0xFF2563EB),
          background: Color(0xFFE4EDFF),
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
              'Update status pesanan dan promo UMKM akan tampil di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: NotificationScreen.textMuted,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
