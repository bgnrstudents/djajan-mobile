import 'package:flutter/foundation.dart';

import '../../../data/sample_catalog.dart';
import '../../../models/product.dart';
import '../../../models/umkm.dart';

/// Menyimpan daftar produk & UMKM favorit pengguna.
///
/// Masih in-memory untuk prototipe; nanti tinggal sinkron ke API Laravel.
class FavoriteService extends ChangeNotifier {
  FavoriteService._internal() {
    _seed();
  }

  static final FavoriteService _instance = FavoriteService._internal();
  factory FavoriteService() => _instance;

  final Set<String> _productIds = {};
  final Set<String> _umkmIds = {};

  // ----------------------------------------------------------- Produk
  bool isProductFavorite(String productId) => _productIds.contains(productId);

  /// Mengembalikan `true` bila produk kini menjadi favorit.
  bool toggleProduct(String productId) {
    final wasFavorite = _productIds.contains(productId);
    if (wasFavorite) {
      _productIds.remove(productId);
    } else {
      _productIds.add(productId);
    }
    notifyListeners();
    return !wasFavorite;
  }

  // ------------------------------------------------------------- UMKM
  bool isUmkmFavorite(String umkmId) => _umkmIds.contains(umkmId);

  /// Mengembalikan `true` bila UMKM kini menjadi favorit.
  bool toggleUmkm(String umkmId) {
    final wasFavorite = _umkmIds.contains(umkmId);
    if (wasFavorite) {
      _umkmIds.remove(umkmId);
    } else {
      _umkmIds.add(umkmId);
    }
    notifyListeners();
    return !wasFavorite;
  }

  // ------------------------------------------------------------- Query
  int get productCount => _productIds.length;
  int get umkmCount => _umkmIds.length;
  int get totalCount => productCount + umkmCount;

  bool get isEmpty => _productIds.isEmpty && _umkmIds.isEmpty;
  bool get isNotEmpty => !isEmpty;

  List<Product> get favoriteProducts =>
      SampleCatalog.products.where((p) => _productIds.contains(p.id)).toList();

  List<Umkm> get favoriteUmkms =>
      SampleCatalog.umkms.where((u) => _umkmIds.contains(u.id)).toList();

  // ------------------------------------------------------------- Reset
  void clear() {
    _productIds.clear();
    _umkmIds.clear();
    notifyListeners();
  }

  /// Beberapa favorit awal agar halaman terasa hidup saat demo.
  void _seed() {
    _productIds.addAll({'p-brownies-loyang', 'p-es-teh'});
    _umkmIds.add('umkm-mba-rina');
  }
}
