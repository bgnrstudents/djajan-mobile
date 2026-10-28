import 'package:flutter/foundation.dart';

import '../models/product.dart';
import '../models/umkm.dart';
import 'api_service.dart';

class CatalogService extends ChangeNotifier {
  List<Product> products = const [];
  List<Umkm> umkms = const [];
  List<String> categories = const ['Semua'];
  bool isLoading = false;
  String? errorMessage;

  Future<void> load({String query = '', String category = ''}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.get(
        'katalog',
        query: {
          if (query.trim().isNotEmpty) 'cari': query.trim(),
          if (category.isNotEmpty && category != 'Semua') 'kategori': category,
        },
      ) as Map<String, dynamic>;

      final rawProducts = response['produk'];
      final rawUmkms = response['umkm'];
      final rawCategories = response['kategori'];

      products = rawProducts is List
          ? rawProducts
                .whereType<Map>()
                .map(
                  (item) => Product.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList()
          : const [];
      umkms = rawUmkms is List
          ? rawUmkms
                .whereType<Map>()
                .map((item) => Umkm.fromJson(Map<String, dynamic>.from(item)))
                .toList()
          : const [];
      categories = [
        'Semua',
        if (rawCategories is List)
          ...rawCategories.map((item) => item.toString()),
      ];
    } on ApiException catch (error) {
      errorMessage = error.pesan;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  List<Product> productsOf(String umkmId) =>
      products.where((product) => product.umkmId == umkmId).toList();

  Umkm? umkmById(String id) {
    for (final umkm in umkms) {
      if (umkm.id == id) return umkm;
    }
    return null;
  }
}
