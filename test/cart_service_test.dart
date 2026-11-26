import 'package:djajan_mobile/models/product.dart';
import 'package:djajan_mobile/services/cart_service.dart';
import 'package:djajan_mobile/widgets/floating_cart_button.dart';
import 'package:djajan_mobile/widgets/product_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final cart = CartService();

  setUp(() {
    cart.clear();
  });

  test('cart quantity and subtotal stay in sync as products are changed', () {
    final first = _product(id: '101', price: 12000);
    final second = _product(id: '102', name: 'Kue Desa', price: 8000);

    cart.addProduct(first);
    cart.addProduct(first);
    cart.addProduct(second);

    expect(cart.quantityForProduct(first), 2);
    expect(cart.totalQuantity, 3);
    expect(cart.subtotal, 32000);

    cart.updateQuantity(first.id, 1);
    expect(cart.subtotal, 20000);

    cart.updateQuantity(first.id, 0);
    expect(cart.quantityForProduct(first), 0);
    expect(cart.totalQuantity, 1);
    expect(cart.subtotal, 8000);
  });

  test('catalog refresh updates saved cart prices', () {
    final product = _product(id: '101', price: 12000);
    cart.addProduct(product);
    cart.syncWithCatalog([_product(id: '101', price: 15000)]);

    expect(cart.subtotal, 15000);
  });

  test('ready-stock quantities cannot exceed available stock', () {
    final product = _product(id: 'stock-30', price: 12000, stock: 30);

    expect(cart.addProduct(product, quantity: 99999), 30);
    expect(cart.quantityForProduct(product), 30);
    expect(cart.addProduct(product), 0);

    expect(cart.updateQuantity(product.id, 99999), 30);
    expect(cart.quantityForProduct(product), 30);
  });

  test('pre-order quantities are not limited by ready stock', () {
    final product = _product(
      id: 'preorder',
      price: 12000,
      stock: 0,
      modePenjualan: 'pre_order',
      orderType: 'Pre-Order',
    );

    expect(cart.addProduct(product, quantity: 31), 31);
    expect(cart.quantityForProduct(product), 31);
  });

  test('cart persists per customer when the session is restored', () async {
    SharedPreferences.setMockInitialValues({});
    await cart.loadForCustomer('cart-test-customer-a');
    cart.addProduct(_product(id: '101', price: 12000));

    await cart.loadForCustomer('cart-test-customer-b');
    expect(cart.isEmpty, isTrue);

    await cart.loadForCustomer('cart-test-customer-a');
    expect(cart.quantityForProduct(_product(id: '101', price: 12000)), 1);
    expect(cart.subtotal, 12000);
  });

  testWidgets('duplicate product cards share the same quantity controller', (
    WidgetTester tester,
  ) async {
    final product = _product(id: '101', price: 12000);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 2,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: 260,
            ),
            itemBuilder: (_, _) => ProductCard(
              product: product,
              onAddToCart: () => cart.addProduct(product),
            ),
          ),
        ),
      ),
    );

    final addButton = find.byKey(const ValueKey('product-card-add-101'));
    await tester.tap(addButton.first);
    await tester.pumpAndSettle();

    final quantity = find.byKey(const ValueKey('product-card-quantity-101'));
    expect(quantity, findsNWidgets(2));
    expect(find.text('1'), findsNWidgets(2));

    await tester.tap(
      find.byKey(const ValueKey('product-card-decrease-101')).first,
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('product-card-add-101')),
      findsNWidgets(2),
    );
  });

  testWidgets('floating cart appears with current total and opens cart', (
    WidgetTester tester,
  ) async {
    var opened = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomRight,
            child: FloatingCartButton(onPressed: () => opened = true),
          ),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('floating-cart-button')), findsNothing);

    cart.addProduct(_product(id: '101', price: 12000), quantity: 2);
    await tester.pumpAndSettle();

    expect(find.text('2 item di keranjang'), findsOneWidget);
    expect(find.text('Subtotal Rp24.000'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('floating-cart-button')));
    expect(opened, isTrue);

    cart.updateQuantity('101', 0);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('floating-cart-button')), findsNothing);
  });
}

Product _product({
  required String id,
  String name = 'Jajanan Djajan',
  required int price,
  int? stock,
  String modePenjualan = 'ready',
  String orderType = 'Pesan Sekarang',
}) {
  return Product(
    id: id,
    name: name,
    umkmId: '10',
    umkm: 'Dapur Desa',
    price: price,
    rating: 4.8,
    category: 'Jajanan',
    orderType: orderType,
    imageUrl: '',
    stock: stock,
    modePenjualan: modePenjualan,
  );
}
