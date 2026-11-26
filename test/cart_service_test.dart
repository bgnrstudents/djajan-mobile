import 'package:djajan_mobile/models/order.dart';
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

  test('groupedByStoreAndMode splits Ready Stock and Pre-Order per UMKM and clearGroup clears only target group', () {
    cart.addCartLine(
      const CartLine(
        productId: '1',
        productName: 'Es Teh',
        variant: 'Manis',
        unit: 'gelas',
        imageUrl: '',
        quantity: 2,
        price: 5000,
        type: OrderType.instant,
        umkmId: 'u1',
        umkmName: 'Dapur Bu Minten',
        umkmType: 'Minuman',
        pickupLocation: 'Kreyongan',
      ),
    );
    cart.addCartLine(
      const CartLine(
        productId: '2',
        productName: 'Nasi Kotak',
        variant: 'Komplit',
        unit: 'kotak',
        imageUrl: '',
        quantity: 10,
        price: 20000,
        type: OrderType.preOrder,
        umkmId: 'u1',
        umkmName: 'Dapur Bu Minten',
        umkmType: 'Katering',
        pickupLocation: 'Kreyongan',
      ),
    );
    cart.addCartLine(
      const CartLine(
        productId: '3',
        productName: 'Kue Basah',
        variant: 'Campur',
        unit: 'pcs',
        imageUrl: '',
        quantity: 3,
        price: 3000,
        type: OrderType.instant,
        umkmId: 'u2',
        umkmName: 'Warung Mba Rina',
        umkmType: 'Jajanan',
        pickupLocation: 'Kreyongan',
      ),
    );

    final groups = cart.groupedByStoreAndMode;
    expect(groups.length, 3);
    expect(groups[0].key, 'u1_instant');
    expect(groups[1].key, 'u1_preOrder');
    expect(groups[2].key, 'u2_instant');

    cart.clearGroup('u1', OrderType.instant);
    final remaining = cart.groupedByStoreAndMode;
    expect(remaining.length, 2);
    expect(remaining.any((g) => g.key == 'u1_instant'), isFalse);
    expect(remaining.any((g) => g.key == 'u1_preOrder'), isTrue);
    expect(remaining.any((g) => g.key == 'u2_instant'), isTrue);
  });
}

Product _product({
  required String id,
  String name = 'Jajanan Djajan',
  required int price,
}) {
  return Product(
    id: id,
    name: name,
    umkmId: '10',
    umkm: 'Dapur Desa',
    price: price,
    rating: 4.8,
    category: 'Jajanan',
    orderType: 'Pesan Sekarang',
    imageUrl: '',
  );
}
