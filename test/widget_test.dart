import 'package:djajan_mobile/screens/customer/cart/cart.dart';
import 'package:djajan_mobile/screens/customer/home/customer_home_screen.dart';
import 'package:djajan_mobile/services/auth_service.dart';
import 'package:djajan_mobile/widgets/app_bottom_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('Bottom navigation indicator springs across all destinations', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: _BottomNavigationHarness()),
    );

    final indicator = find.byKey(const ValueKey('bottom-nav-indicator'));
    final initialLeft = tester.getRect(indicator).left;
    final selectedDestinations = <int>[];

    for (final index in [1, 2, 3, 0]) {
      await tester.tap(find.byKey(ValueKey('bottom-nav-item-$index')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.getRect(indicator).left, isNot(initialLeft));
      await tester.pumpAndSettle();
      expect(find.text('Menu $index'), findsOneWidget);
      selectedDestinations.add(index);
    }

    expect(selectedDestinations, [1, 2, 3, 0]);
    expect(tester.getRect(indicator).left, closeTo(initialLeft, 0.1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('CartScreen displays all initial design sections', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: CartScreen()));

    // The cart is empty until a customer explicitly adds a product.
    expect(find.text('Keranjang Belanja Kosong'), findsOneWidget);
  });

  testWidgets(
    'CustomerHomeScreen displays home and navigates to Cart via bottom nav',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AuthService(),
          child: const MaterialApp(home: CustomerHomeScreen()),
        ),
      );

      expect(find.text('UMKM di Desa'), findsOneWidget);
      expect(find.byType(AppBottomNavigation), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('bottom-nav-item-2')));
      await tester.pumpAndSettle();
      expect(find.text('Keranjang Belanja Kosong'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('bottom-nav-item-1')));
      await tester.pumpAndSettle();
      expect(find.text('Pesanan Saya'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('bottom-nav-item-3')));
      await tester.pumpAndSettle();
      expect(find.text('Profil Saya'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('bottom-nav-item-0')));
      await tester.pumpAndSettle();
      expect(find.text('UMKM di Desa'), findsOneWidget);
    },
  );

  testWidgets(
    'Tapping product card opens ProductDetailScreen and displays full details',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AuthService(),
          child: const MaterialApp(home: CustomerHomeScreen()),
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
    },
  );
}

class _BottomNavigationHarness extends StatefulWidget {
  const _BottomNavigationHarness();

  @override
  State<_BottomNavigationHarness> createState() =>
      _BottomNavigationHarnessState();
}

class _BottomNavigationHarnessState extends State<_BottomNavigationHarness> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Menu $_currentIndex')),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
      ),
    );
  }
}
