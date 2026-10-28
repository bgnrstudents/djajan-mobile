import 'package:flutter/foundation.dart';

import '../../../models/product.dart';
import '../models/order.dart';

class CartService extends ChangeNotifier {
  CartService._internal();

  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;

  final List<CartLine> _items = [];

  List<CartLine> get items => List.unmodifiable(_items);

  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;

  int get totalQuantity => _items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => _items.fold(0.0, (sum, item) => sum + item.subtotal);

  /// Mengelompokkan item keranjang berdasarkan ID UMKM
  Map<String, List<CartLine>> get itemsByUmkm {
    final Map<String, List<CartLine>> grouped = {};
    for (final item in _items) {
      grouped.putIfAbsent(item.umkmId, () => []).add(item);
    }
    return grouped;
  }

  /// Menambahkan produk dari halaman Beranda atau Detail Produk
  void addProduct(Product product, {int quantity = 1}) {
    final targetId = product.id.isNotEmpty
        ? product.id
        : 'prod_${product.name.toLowerCase().replaceAll(RegExp(r'\s+'), '_')}';

    final index = _items.indexWhere(
      (l) =>
          l.productId == targetId ||
          (l.productName == product.name && l.umkmName == product.umkm),
    );

    if (index >= 0) {
      final existing = _items[index];
      _items[index] = existing.copyWith(quantity: existing.quantity + quantity);
    } else {
      _items.add(product.toCartLine(quantity: quantity));
    }
    notifyListeners();
  }

  /// Menambahkan CartLine secara langsung
  void addCartLine(CartLine line) {
    final index = _items.indexWhere((l) => l.productId == line.productId);
    if (index >= 0) {
      final existing = _items[index];
      _items[index] = existing.copyWith(
        quantity: existing.quantity + line.quantity,
      );
    } else {
      _items.add(line);
    }
    notifyListeners();
  }

  /// Mengubah jumlah item produk (jika <= 0, produk akan dihapus)
  void updateQuantity(String productId, int newQuantity) {
    final index = _items.indexWhere((l) => l.productId == productId);
    if (index >= 0) {
      if (newQuantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index] = _items[index].copyWith(quantity: newQuantity);
      }
      notifyListeners();
    }
  }

  /// Menghapus produk tertentu dari keranjang
  void removeProduct(String productId) {
    _items.removeWhere((l) => l.productId == productId);
    notifyListeners();
  }

  /// Mengosongkan seluruh keranjang (misal setelah berhasil checkout)
  void clear() {
    _items.clear();
    notifyListeners();
  }
}
