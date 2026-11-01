import 'package:djajan_mobile/screens/customer/cart/cart.dart';
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

    // The cart is empty until a customer explicitly adds a product.
    expect(find.text('Keranjang Belanja Kosong'), findsOneWidget);
  });

  testWidgets('CustomerHomeScreen displays home and navigates to Cart via bottom nav', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CustomerHomeScreen(),
      ),
    );

    // Initial screen is Beranda with 'Dukung UMKM Kreyongan Atas'
    expect(find.text('Dukung UMKM Kreyongan Atas'), findsOneWidget);

    // Find the cart action button on bottom nav (index 2)
    final cartIconFinder = find.byIcon(Icons.shopping_cart_outlined);
    expect(cartIconFinder, findsOneWidget);

    // Tap cart icon
    await tester.tap(cartIconFinder);
    await tester.pumpAndSettle();

    // Now cart screen should be displayed
    expect(find.text('Keranjang Belanja Kosong'), findsOneWidget);
  });

  testWidgets('Tapping product card opens ProductDetailScreen and displays full details', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CustomerHomeScreen(),
      ),
    );

    // Find and scroll to the product card 'Nasi Kotak Ayam Geprek'
    final productFinder = find.text('Nasi Kotak Ayam Geprek');
    await tester.scrollUntilVisible(
      productFinder,
      100,
      scrollable: find.byType(Scrollable).first,
    );
    expect(productFinder, findsOneWidget);

    await tester.tap(productFinder);
    await tester.pumpAndSettle();

    // Verify ProductDetailScreen is shown
    expect(find.text('Deskripsi Produk'), findsOneWidget);
    expect(find.text('Informasi UMKM & Dapur'), findsOneWidget);
    expect(find.text('+ Keranjang'), findsOneWidget);
    expect(find.text('Pesan Sekarang'), findsOneWidget);
  });
}
