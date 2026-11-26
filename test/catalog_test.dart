import 'package:djajan_mobile/data/sample_catalog.dart';
import 'package:djajan_mobile/models/product.dart';
import 'package:djajan_mobile/screens/customer/catalog/catalog_list_screen.dart';
import 'package:djajan_mobile/screens/customer/home/customer_home_screen.dart';
import 'package:djajan_mobile/screens/customer/umkm/umkm_storefront_screen.dart';
import 'package:djajan_mobile/services/auth_service.dart';
import 'package:djajan_mobile/services/cart_service.dart';
import 'package:djajan_mobile/services/catalog_service.dart';
import 'package:djajan_mobile/widgets/product_card.dart';
import 'package:djajan_mobile/widgets/umkm_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  test(
    'Urutan harga menyaring produk tanpa mengubah urutan terbaru dari API',
    () {
      final products = [
        _product('mahal', 12000),
        _product('murah', 3000),
        _product('sedang', 8000),
      ];

      expect(
        sortProducts(
          products,
          ProductSortOrder.priceAscending,
        ).map((product) => product.id),
        ['murah', 'sedang', 'mahal'],
      );
      expect(
        sortProducts(
          products,
          ProductSortOrder.priceDescending,
        ).map((product) => product.id),
        ['mahal', 'sedang', 'murah'],
      );
      expect(
        sortProducts(
          products,
          ProductSortOrder.newest,
        ).map((product) => product.id),
        ['mahal', 'murah', 'sedang'],
      );
    },
  );

  testWidgets('Beranda menampilkan seksi UMKM di Desa', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthService(),
        child: const MaterialApp(home: CustomerHomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('UMKM di Desa'), findsOneWidget);
    final sectionTitle = tester.widget<Text>(find.text('UMKM di Desa'));
    expect(sectionTitle.style?.fontWeight, FontWeight.w800);
    expect(sectionTitle.style?.letterSpacing, -0.35);
    expect(find.byIcon(Icons.storefront_rounded), findsOneWidget);
    expect(find.text('Dapur Bu Minten'), findsWidgets);
    expect(find.text('Pilih alamat'), findsOneWidget);
    expect(find.textContaining('Kreyongan'), findsNothing);
  });

  testWidgets('Kartu beranda tidak overflow pada mobile dan desktop', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final size in [const Size(320, 1000), const Size(1200, 1200)]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AuthService(),
          child: const MaterialApp(home: CustomerHomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Jajanan Paling Menggoda'), findsOneWidget);
      final featuredCards = find.byWidgetPredicate(
        (widget) => widget is ProductCard && widget.featured,
      );
      expect(featuredCards, findsNWidgets(SampleCatalog.products.length));
      final firstCard = tester.getRect(featuredCards.at(0));
      final secondCard = tester.getRect(featuredCards.at(1));
      final thirdCard = tester.getRect(featuredCards.at(2));
      final productImageAspectRatio = tester.widget<AspectRatio>(
        find.descendant(
          of: featuredCards.at(0),
          matching: find.byType(AspectRatio),
        ),
      );
      expect(productImageAspectRatio.aspectRatio, closeTo(4 / 3, 0.001));
      expect(secondCard.top, closeTo(firstCard.top, 0.1));
      expect(secondCard.left - firstCard.right, closeTo(14, 0.1));
      if (size.width < 620) {
        expect(thirdCard.top, greaterThan(firstCard.top));
        expect(firstCard.width, lessThan(140));
        expect(firstCard.height, lessThan(300));
        final featuredUmkmCard = tester.getRect(
          find
              .byWidgetPredicate(
                (widget) => widget is UmkmCard && widget.featured,
              )
              .first,
        );
        expect(featuredUmkmCard.width, 230);
        expect(featuredUmkmCard.height, 250);
        final nextUmkmCard = tester.getRect(
          find
              .byWidgetPredicate(
                (widget) => widget is UmkmCard && widget.featured,
              )
              .at(1),
        );
        expect(nextUmkmCard.left, lessThan(size.width - 18));
      } else {
        expect(thirdCard.top, closeTo(firstCard.top, 0.1));
      }
      expect(
        find.byWidgetPredicate(
          (widget) => widget is UmkmCard && widget.featured,
        ),
        findsWidgets,
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('Tombol tambah pada card unggulan tetap memperbarui keranjang', (
    tester,
  ) async {
    final cart = CartService()..clear();
    addTearDown(cart.clear);
    final product = SampleCatalog.products.first;
    final cartProductId = product.toCartLine().productId;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 280,
              child: ProductCard(
                product: product,
                featured: true,
                onAddToCart: () => cart.addProduct(product),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ValueKey('product-card-add-$cartProductId')));
    await tester.pumpAndSettle();

    expect(cart.quantityForProduct(product), 1);
    expect(
      find.byKey(ValueKey('product-card-quantity-$cartProductId')),
      findsOneWidget,
    );
  });

  testWidgets('Dropdown katalog menerapkan urutan harga yang dipilih', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: CatalogListScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Urutkan hasil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Harga terendah'));
    await tester.pumpAndSettle();

    expect(find.text('Harga terendah'), findsOneWidget);
  });

  testWidgets('Storefront menampilkan hanya produk milik UMKM terkait', (
    tester,
  ) async {
    final umkm = SampleCatalog.umkms.firstWhere(
      (u) => u.id == 'umkm-bu-minten',
    );

    await tester.pumpWidget(
      MaterialApp(home: UmkmStorefrontScreen(umkm: umkm)),
    );
    await tester.pumpAndSettle();

    // Produk milik Dapur Bu Minten tampil.
    expect(find.text('Nasi Kotak Ayam Geprek'), findsOneWidget);
    expect(find.text('Ayam Lengkuas Goreng Satuan'), findsOneWidget);

    // Produk UMKM lain tidak ikut tampil.
    expect(find.text('Es Teh Solo Original'), findsNothing);
  });

  testWidgets('Katalog memfilter produk berdasarkan kata kunci', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: CatalogListScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Nasi Kotak Ayam Geprek'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'es teh');
    await tester.pumpAndSettle();

    expect(find.text('Es Teh Solo Original'), findsOneWidget);
    expect(find.text('Nasi Kotak Ayam Geprek'), findsNothing);
  });

  testWidgets('Katalog menampilkan hasil UMKM saat mencari nama warung', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: CatalogListScreen()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'mba rina');
    await tester.pumpAndSettle();

    expect(find.text('UMKM Ditemukan'), findsOneWidget);
    expect(find.text('Dapur Mba Rina'), findsWidgets);
  });
}

Product _product(String id, int price) => Product(
  id: id,
  name: id,
  umkm: 'Usaha $id',
  price: price,
  rating: 0,
  category: 'Makanan',
  orderType: 'Pesan Sekarang',
);
