import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/product.dart';
import '../models/order.dart';
import '../models/umkm.dart';

class CartService extends ChangeNotifier {
  CartService._internal();

  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;

  final List<CartLine> _items = [];
  String? _customerId;
  Future<void> _saveOperation = Future<void>.value();

  List<CartLine> get items => List.unmodifiable(_items);

  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;

  int get totalQuantity => _items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => _items.fold(0.0, (sum, item) => sum + item.subtotal);

  Future<void> loadForCustomer(String customerId) async {
    final normalizedId = customerId.trim();
    if (normalizedId.isEmpty || normalizedId == _customerId) return;

    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_storageKey(normalizedId));
    _customerId = normalizedId;
    _items
      ..clear()
      ..addAll(_decodeItems(raw));
    notifyListeners();
  }

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
    _changed();
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
    _changed();
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
      _changed();
    }
  }

  /// Menghapus produk tertentu dari keranjang
  void removeProduct(String productId) {
    _items.removeWhere((l) => l.productId == productId);
    _changed();
  }

  void removeProducts(Iterable<String> productIds) {
    final ids = productIds.toSet();
    if (ids.isEmpty) return;
    _items.removeWhere((l) => ids.contains(l.productId));
    _changed();
  }

  /// Mengosongkan seluruh keranjang (misal setelah berhasil checkout)
  void clear() {
    _items.clear();
    _changed();
  }

  /// Memperbarui status ketersediaan COD dan pengantaran berdasarkan katalog terkini
  void syncWithCatalog(List<Product> products, {List<Umkm>? umkms}) {
    if (_items.isEmpty) return;
    bool hasChanged = false;
    for (int i = 0; i < _items.length; i++) {
      final line = _items[i];
      final matchingProduct = products.cast<Product?>().firstWhere(
        (p) =>
            p != null &&
            (p.id == line.productId ||
                (p.name == line.productName && p.umkm == line.umkmName)),
        orElse: () => null,
      );

      final matchingUmkm = umkms?.cast<Umkm?>().firstWhere(
        (u) => u != null && (u.id == line.umkmId || u.name == line.umkmName),
        orElse: () => null,
      );

      bool? updatedCod;
      if (matchingProduct != null) {
        updatedCod = matchingProduct.codAvailable;
      } else if (matchingUmkm != null) {
        updatedCod = matchingUmkm.codAvailable;
      }

      if (updatedCod != null && updatedCod != line.codAvailable) {
        _items[i] = line.copyWith(codAvailable: updatedCod);
        hasChanged = true;
      }
    }

    if (hasChanged) {
      _changed();
    }
  }

  void _changed() {
    notifyListeners();
    final customerId = _customerId;
    if (customerId == null) return;
    _saveOperation = _saveOperation.then((_) async {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        _storageKey(customerId),
        jsonEncode(_items.map(_encodeItem).toList()),
      );
    });
  }

  String _storageKey(String customerId) => 'djajan_cart_$customerId';

  List<CartLine> _decodeItems(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((item) => _decodeItem(Map<String, dynamic>.from(item)))
          .whereType<CartLine>()
          .toList();
    } on FormatException {
      return const [];
    }
  }

  Map<String, dynamic> _encodeItem(CartLine item) => {
    'product_id': item.productId,
    'product_name': item.productName,
    'variant': item.variant,
    'unit': item.unit,
    'image_url': item.imageUrl,
    'quantity': item.quantity,
    'price': item.price,
    'type': item.type.name,
    'umkm_id': item.umkmId,
    'umkm_name': item.umkmName,
    'umkm_type': item.umkmType,
    'courier_fee': item.courierFee,
    'pickup_location': item.pickupLocation,
    'cod_available': item.codAvailable,
    'pickup_available': item.pickupAvailable,
  };

  CartLine? _decodeItem(Map<String, dynamic> item) {
    final typeName = item['type']?.toString();
    final type = OrderType.values.where((value) => value.name == typeName);
    final productId = item['product_id']?.toString() ?? '';
    final productName = item['product_name']?.toString() ?? '';
    if (productId.isEmpty || productName.isEmpty || type.isEmpty) return null;

    return CartLine(
      productId: productId,
      productName: productName,
      variant: item['variant']?.toString() ?? 'Pilihan Terbaik',
      unit: item['unit']?.toString() ?? 'Porsi',
      imageUrl: item['image_url']?.toString() ?? '',
      quantity: (item['quantity'] as num?)?.toInt() ?? 1,
      price: (item['price'] as num?)?.toDouble() ?? 0,
      type: type.first,
      umkmId: item['umkm_id']?.toString() ?? '',
      umkmName: item['umkm_name']?.toString() ?? '',
      umkmType: item['umkm_type']?.toString() ?? 'UMKM Kuliner Desa',
      courierFee: (item['courier_fee'] as num?)?.toDouble(),
      pickupLocation:
          item['pickup_location']?.toString() ?? 'Desa Kreyongan Atas',
      codAvailable: item['cod_available'] as bool? ?? true,
      pickupAvailable: item['pickup_available'] as bool? ?? true,
    );
  }
}
