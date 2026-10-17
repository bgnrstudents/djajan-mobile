import 'package:djajan_mobile/data/sample_catalog.dart';
import 'package:djajan_mobile/screens/customer/catalog/catalog_list_screen.dart';
import 'package:djajan_mobile/screens/customer/home/customer_home_screen.dart';
import 'package:djajan_mobile/screens/customer/umkm/umkm_storefront_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Beranda menampilkan seksi UMKM di Desa', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: CustomerHomeScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('UMKM di Desa'), findsOneWidget);
    expect(find.text('Dapur Bu Minten'), findsWidgets);
  });

  testWidgets('Storefront menampilkan hanya produk milik UMKM terkait',
      (tester) async {
    final umkm =
        SampleCatalog.umkms.firstWhere((u) => u.id == 'umkm-bu-minten');

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

  testWidgets('Katalog memfilter produk berdasarkan kata kunci',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: CatalogListScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nasi Kotak Ayam Geprek'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'es teh');
    await tester.pumpAndSettle();

    expect(find.text('Es Teh Solo Original'), findsOneWidget);
    expect(find.text('Nasi Kotak Ayam Geprek'), findsNothing);
  });

  testWidgets('Katalog menampilkan hasil UMKM saat mencari nama warung',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: CatalogListScreen()),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'mba rina');
    await tester.pumpAndSettle();

    expect(find.text('UMKM Ditemukan'), findsOneWidget);
    expect(find.text('Dapur Mba Rina'), findsWidgets);
  });
}
