import 'package:flutter/foundation.dart';

import '../models/product.dart';
import '../models/umkm.dart';
import 'api_service.dart';

/// Menyimpan daftar produk & UMKM favorit pengguna.
///
class FavoriteService extends ChangeNotifier {
  FavoriteService._internal();

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
  Set<String> get productIds => Set.unmodifiable(_productIds);
  Set<String> get umkmIds => Set.unmodifiable(_umkmIds);

  bool get isEmpty => _productIds.isEmpty && _umkmIds.isEmpty;
  bool get isNotEmpty => !isEmpty;

  List<Product> favoriteProductsFrom(Iterable<Product> products) =>
      products.where((p) => _productIds.contains(p.id)).toList();

  List<Umkm> favoriteUmkmsFrom(Iterable<Umkm> umkms) =>
      umkms.where((u) => _umkmIds.contains(u.id)).toList();

  void setFromApi(Map<String, dynamic> data) {
    _productIds
      ..clear()
      ..addAll(((data['produk'] as List?) ?? []).map((id) => id.toString()));
    _umkmIds
      ..clear()
      ..addAll(((data['umkm'] as List?) ?? []).map((id) => id.toString()));
    notifyListeners();
  }

  Future<void> syncProduct(String id, bool favorite) async {
    await ApiService.post('pelanggan/favorit_toggle', {
      'tipe': 'produk',
      'id_item': int.tryParse(id) ?? 0,
      'favorit': favorite,
    });
  }

  Future<void> syncUmkm(String id, bool favorite) async {
    await ApiService.post('pelanggan/favorit_toggle', {
      'tipe': 'umkm',
      'id_item': int.tryParse(id) ?? 0,
      'favorit': favorite,
    });
  }

  // ------------------------------------------------------------- Reset
  void clear() {
    _productIds.clear();
    _umkmIds.clear();
    notifyListeners();
  }
}
