import 'package:djajan_mobile/screens/customer/home/customer_home_screen.dart';
import 'package:djajan_mobile/screens/customer/notification/notification_screen.dart';
import 'package:djajan_mobile/screens/customer/notification/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Badge lonceng menampilkan jumlah belum dibaca & membuka halaman',
      (tester) async {
    final service = NotificationService()..clear();
    service.push(title: 'Pesanan Baru', message: 'Pesanan Anda sedang diproses.');

    expect(service.unreadCount, 1);

    await tester.pumpWidget(const MaterialApp(home: CustomerHomeScreen()));
    await tester.pumpAndSettle();

    final badge = find.descendant(
      of: find.widgetWithIcon(IconButton, Icons.notifications_none),
      matching: find.text('1'),
    );
    expect(badge, findsOneWidget);

    await tester.tap(
      find.widgetWithIcon(IconButton, Icons.notifications_none),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(find.text('Notifikasi'), findsOneWidget);
    expect(find.text('Pesanan Baru'), findsOneWidget);
  });

  testWidgets('Notifikasi dapat ditandai dibaca semua', (tester) async {
    final service = NotificationService()..clear();
    service.push(
      title: 'Menunggu Pembayaran',
      message: 'Selesaikan pembayaran pesanan Anda.',
    );
    service.push(title: 'Gratis Ongkir', message: 'Promo hari ini.');

    await tester.pumpWidget(const MaterialApp(home: NotificationScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Menunggu Pembayaran'), findsOneWidget);
    expect(service.unreadCount, 2);

    await tester.tap(find.text('Tandai dibaca'));
    await tester.pumpAndSettle();

    expect(service.unreadCount, 0);
  });

  testWidgets('Halaman notifikasi menampilkan empty state', (tester) async {
    NotificationService().clear();

    await tester.pumpWidget(const MaterialApp(home: NotificationScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Belum ada notifikasi'), findsOneWidget);
  });
}
