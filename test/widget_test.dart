import 'package:djajan_mobile/data/sample_catalog.dart';
import 'package:djajan_mobile/models/order.dart';
import 'package:djajan_mobile/models/product.dart';
import 'package:djajan_mobile/models/umkm.dart';
import 'package:djajan_mobile/screens/customer/cart/cart.dart';
import 'package:djajan_mobile/screens/customer/home/customer_home_screen.dart';
import 'package:djajan_mobile/screens/customer/order/order_checkout_screen.dart';
import 'package:djajan_mobile/screens/customer/order/qris_payment_screen.dart';
import 'package:djajan_mobile/screens/customer/umkm/umkm_storefront_screen.dart';
import 'package:djajan_mobile/services/auth_service.dart';
import 'package:djajan_mobile/services/cart_service.dart';
import 'package:djajan_mobile/services/catalog_service.dart';
import 'package:djajan_mobile/widgets/app_bottom_navigation.dart';
import 'package:djajan_mobile/widgets/product_card.dart';
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
    final indicatorCenterY = tester.getCenter(indicator).dy;
    final firstItemCenterY = tester.getCenter(find.text('Beranda')).dy;
    final firstIconCenterY = tester.getCenter(find.byIcon(Icons.home_rounded)).dy;
    expect(((firstItemCenterY + firstIconCenterY) / 2 - indicatorCenterY).abs(), lessThan(4.0));
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
    'Tapping product card on Home opens UmkmStorefrontScreen and then ProductDetailScreen',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AuthService(),
          child: const MaterialApp(home: CustomerHomeScreen()),
        ),
      );

      final productFinder = find.text('Nasi Kotak Ayam Geprek');
      await tester.scrollUntilVisible(
        productFinder,
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(productFinder, findsOneWidget);

      await tester.tap(productFinder);
      await tester.pumpAndSettle();

      // Storefront UMKM terbuka lebih dulu
      expect(find.text('Jelajahi menu'), findsOneWidget);

      // Tap produk di dalam toko -> buka ProductDetailScreen
      final innerProductFinder = find.text('Nasi Kotak Ayam Geprek');
      await tester.ensureVisible(innerProductFinder);
      await tester.pumpAndSettle();
      await tester.tap(innerProductFinder);
      await tester.pumpAndSettle();

      expect(find.text('Deskripsi Produk'), findsOneWidget);
      expect(find.text('Informasi UMKM & Dapur'), findsOneWidget);
      expect(find.text('+ Keranjang'), findsOneWidget);
      expect(find.text('Pesan Sekarang'), findsOneWidget);
    },
  );

  testWidgets('CartScreen separates store and order mode groups with individual checkout', (
    WidgetTester tester,
  ) async {
    final cart = CartService()..clear();
    addTearDown(cart.clear);

    cart.addCartLine(
      const CartLine(
        productId: '1',
        productName: 'Nasi Goreng Desa',
        variant: 'Pedas',
        unit: 'porsi',
        imageUrl: '',
        quantity: 1,
        price: 15000,
        type: OrderType.instant,
        umkmId: 'u1',
        umkmName: 'Warung Bu Minten',
        umkmType: 'Makanan',
        pickupLocation: 'Desa Kreyongan',
      ),
    );
    cart.addCartLine(
      const CartLine(
        productId: '2',
        productName: 'Tumpeng Mini',
        variant: 'Original',
        unit: 'paket',
        imageUrl: '',
        quantity: 10,
        price: 25000,
        type: OrderType.preOrder,
        umkmId: 'u1',
        umkmName: 'Warung Bu Minten',
        umkmType: 'Katering',
        pickupLocation: 'Desa Kreyongan',
        minOrderPo: 10,
      ),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthService(),
        child: const MaterialApp(home: CartScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2 Keranjang Toko & Layanan'), findsOneWidget);
    expect(find.text('Checkout Pesanan Ini'), findsOneWidget);
    expect(find.text('Checkout PO Ini'), findsOneWidget);
  });

  testWidgets('QrisPaymentScreen displays actions and close confirmation dialog', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: QrisPaymentScreen(
          orderId: 'CHK-QRIS-UI-1',
          qrCodeUrl: 'https://api.sandbox.midtrans.com/v2/qris/tx-123/qr-code',
          qrString: '000201010212',
          totalAmount: 26500,
          expiryTime: DateTime.now().add(const Duration(minutes: 15)),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Pembayaran QRIS'), findsOneWidget);
    expect(find.text('Download QRIS'), findsOneWidget);
    expect(find.text('Salin QRIS'), findsOneWidget);
    expect(find.text('Cek Status Pembayaran'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('qris-close-button')));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Keluar dari Pembayaran?'), findsOneWidget);
    await tester.tap(find.text('Lanjutkan Bayar'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Keluar dari Pembayaran?'), findsNothing);
  });

  testWidgets(
    'SnackBar Lihat action navigates safely after UmkmStorefrontScreen is popped',
    (WidgetTester tester) async {
      CartService().clear();
      final umkm = SampleCatalog.umkms.first;

      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AuthService(),
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => UmkmStorefrontScreen(umkm: umkm),
                      ),
                    ),
                    child: const Text('Buka Toko'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Buka Toko'));
      await tester.pumpAndSettle();

      final addButton = find.byIcon(Icons.add).first;
      await tester.ensureVisible(addButton);
      await tester.pumpAndSettle();
      await tester.tap(addButton);
      await tester.pump(const Duration(milliseconds: 200));

      // Keluar dari UmkmStorefrontScreen saat SnackBar "Lihat" masih tampil
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Buka Toko'), findsOneWidget);

      // Tekan "Lihat" pada SnackBar harus tetap aman membuka CartScreen
      await tester.tap(find.text('Lihat'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Keranjang Belanja'), findsOneWidget);
    },
  );

  testWidgets(
    'ProductCard shows available stock for Ready Stock and hides it for Pre-Order',
    (WidgetTester tester) async {
      final readyProduct = Product.fromJson({
        'id_produk': 10,
        'id_umkm': 1,
        'nama_produk': 'Risoles Mayo',
        'nama_usaha': 'Dapur Berkah',
        'harga': 5000,
        'stok': 7,
        'mode_penjualan': 'ready',
      });
      final poProduct = Product.fromJson({
        'id_produk': 11,
        'id_umkm': 1,
        'nama_produk': 'Tumpeng Acara',
        'nama_usaha': 'Dapur Berkah',
        'harga': 150000,
        'stok': 20,
        'mode_penjualan': 'pre_order',
        'min_order_po': 2,
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                SizedBox(
                  width: 170,
                  height: 268,
                  child: ProductCard(product: readyProduct),
                ),
                SizedBox(
                  width: 170,
                  height: 268,
                  child: ProductCard(product: poProduct),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Stok: 7'), findsOneWidget);
      expect(find.text('Min. 2 porsi'), findsOneWidget);
      expect(find.text('Stok: 20'), findsNothing);
    },
  );

  testWidgets(
    'OrderCheckoutScreen shows DP 30% breakdown when UMKM uses DP 30% scheme',
    (WidgetTester tester) async {
      final catalog = CatalogService()
        ..umkms = [
          Umkm.fromJson({
            'id_umkm': '99',
            'nama_usaha': 'Katering DP 30',
            'skema_po': 'DP 30%',
            'layanan_ambil_sendiri': true,
            'layanan_kurir': false,
          }),
        ];

      final poLine = CartLine(
        productId: 'po_1',
        productName: 'Nasi Box Spesial',
        variant: 'Komplit',
        unit: 'kotak',
        imageUrl: '',
        quantity: 10,
        price: 20000,
        type: OrderType.preOrder,
        umkmId: '99',
        umkmName: 'Katering DP 30',
        umkmType: 'Katering',
        pickupLocation: 'Kreongan',
        pickupAvailable: true,
        codAvailable: false,
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<CatalogService>.value(
          value: catalog,
          child: MaterialApp(
            home: OrderCheckoutScreen(cartLines: [poLine]),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('BAYAR SEKARANG (DP 30%)'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('SKEMA PO: DP 30%'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('SKEMA PO: DP 30%'), findsOneWidget);
      expect(find.text('Bayar Sekarang (DP 30%)'), findsOneWidget);
      expect(find.text('Sisa Pelunasan Nanti'), findsOneWidget);
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
