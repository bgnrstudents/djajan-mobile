import 'package:djajan_mobile/services/catalog_service.dart';
import 'package:provider/provider.dart';
import 'package:djajan_mobile/screens/customer/favorite/favorite_screen.dart';
import 'package:djajan_mobile/services/favorite_service.dart';
import 'package:djajan_mobile/widgets/favorite_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Halaman favorit menampilkan produk & UMKM yang disimpan', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => CatalogService(),
        child: const MaterialApp(home: FavoriteScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Favorit Saya'), findsOneWidget);

    expect(find.text('Belum ada produk favorit'), findsOneWidget);

    // Pindah ke tab UMKM.
    await tester.tap(find.textContaining('UMKM ('));
    await tester.pumpAndSettle();

    expect(find.text('Belum ada UMKM favorit'), findsOneWidget);
  });

  testWidgets('Tombol hati menambah dan menghapus favorit', (tester) async {
    final favorites = FavoriteService();
    const productId = '1';

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
