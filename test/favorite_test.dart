import 'package:djajan_mobile/data/sample_catalog.dart';
import 'package:djajan_mobile/screens/customer/favorite/favorite_screen.dart';
import 'package:djajan_mobile/screens/customer/favorite/favorite_service.dart';
import 'package:djajan_mobile/widgets/favorite_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Halaman favorit menampilkan produk & UMKM yang disimpan',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: FavoriteScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Favorit Saya'), findsOneWidget);

    // Produk favorit awal (seed).
    expect(find.text('Brownies Lumer Loyang'), findsOneWidget);

    // Pindah ke tab UMKM.
    await tester.tap(find.textContaining('UMKM ('));
    await tester.pumpAndSettle();

    expect(find.text('Dapur Mba Rina'), findsWidgets);
  });

  testWidgets('Tombol hati menambah dan menghapus favorit', (tester) async {
    final favorites = FavoriteService();
    final productId = SampleCatalog.products.first.id;

    favorites.clear();
    expect(favorites.isProductFavorite(productId), isFalse);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(child: FavoriteButton(productId: productId)),
        ),
      ),
    );

    expect(find.byIcon(Icons.favorite_border), findsOneWidget);

    await tester.tap(find.byType(FavoriteButton));
    await tester.pumpAndSettle();

    expect(favorites.isProductFavorite(productId), isTrue);
    expect(find.byIcon(Icons.favorite), findsOneWidget);
  });
}
