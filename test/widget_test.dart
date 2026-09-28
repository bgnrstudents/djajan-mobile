import 'package:djajan_mobile/screens/customer/profile/cart.dart';
import 'package:djajan_mobile/screens/customer/home/customer_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CartScreen displays all initial design sections', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CartScreen(),
      ),
    );

    // Initial visible elements in cart
    expect(find.text('Pesanan dari 2 UMKM Berbeda'), findsOneWidget);
    expect(find.text('Kontak & Alamat Penerima'), findsOneWidget);
    expect(find.text('Muhammad Rizki'), findsOneWidget);
    expect(find.text('WhatsApp Aktif'), findsOneWidget);
    expect(find.text('Dapur Bu Minten'), findsOneWidget);
    expect(find.text('Nasi Kotak Ayam Geprek'), findsOneWidget);
  });

  testWidgets('CustomerHomeScreen has working cart icon button in AppBar', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CustomerHomeScreen(),
      ),
    );

    // Initial screen is Beranda with 'Mau jajan apa hari ini?'
    expect(find.text('Mau jajan apa hari ini?'), findsOneWidget);

    // Find the cart action button on AppBar
    final cartIconFinder = find.byIcon(Icons.shopping_cart_outlined).first;
    expect(cartIconFinder, findsOneWidget);

    // Tap cart icon
    await tester.tap(cartIconFinder);
    await tester.pumpAndSettle();

    // Now cart screen should be displayed
    expect(find.text('Pesanan dari 2 UMKM Berbeda'), findsOneWidget);
    expect(find.text('Dapur Bu Minten'), findsOneWidget);
  });
}
