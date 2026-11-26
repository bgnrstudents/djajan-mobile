import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/product.dart';
import '../models/order.dart';
import '../models/umkm.dart';

/// Grup keranjang per kombinasi (UMKM + Mode Pesanan: Ready Stock vs Pre-Order).
class CartGroup {
  final String umkmId;
  final String umkmName;
  final String umkmType;
  final OrderType orderType;
  final List<CartLine> items;

  const CartGroup({
    required this.umkmId,
    required this.umkmName,
    required this.umkmType,
    required this.orderType,
    required this.items,
  });

  String get key => '${umkmId}_${orderType.name}';
  bool get isPreOrder => orderType == OrderType.preOrder;
  double get subtotal => items.fold(0.0, (sum, item) => sum + item.subtotal);
  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);
  CartLine get firstLine => items.first;
  double? get courierFee => firstLine.courierFee;
  String get pickupLocation => firstLine.pickupLocation;
  bool get codAvailable =>
      items.every((item) => item.codAvailable) && !isPreOrder;
  bool get pickupAvailable => items.every((item) => item.pickupAvailable);
}

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

  int quantityForProduct(Product product, {OrderType? type}) {
    final cartLine = product.toCartLine(type: type);
    if (type != null) {
      final index = _items.indexWhere(
        (item) =>
            (item.productId == cartLine.productId ||
                (item.productName == product.name && item.umkmName == product.umkm)) &&
            item.type == type,
      );
      return index < 0 ? 0 : _items[index].quantity;
    }
    return _items
        .where(
          (item) =>
              item.productId == cartLine.productId ||
              (item.productName == product.name && item.umkmName == product.umkm),
        )
        .fold(0, (sum, item) => sum + item.quantity);
  }

  Future<void> loadForCustomer(String customerId) async {
    final normalizedId = customerId.trim();
    if (normalizedId.isEmpty || normalizedId == _customerId) return;

    await _saveOperation;
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

  /// Mengelompokkan item keranjang berdasarkan kombinasi (UMKM + Mode Pesanan).
  List<CartGroup> get groupedByStoreAndMode {
    final Map<String, List<CartLine>> grouped = {};
    for (final item in _items) {
      final key = '${item.umkmId}_${item.type.name}';
      grouped.putIfAbsent(key, () => []).add(item);
    }
    return grouped.values.map((lines) {
      final first = lines.first;
      return CartGroup(
        umkmId: first.umkmId,
        umkmName: first.umkmName,
        umkmType: first.umkmType,
        orderType: first.type,
        items: List.unmodifiable(lines),
      );
    }).toList();
  }

  /// Menambahkan produk dari halaman Beranda atau Detail Produk
  int addProduct(Product product, {int quantity = 1, OrderType? type}) {
    if (quantity <= 0) return 0;
    final targetType = type ?? product.parsedOrderType;
    final cartLine = product.toCartLine(quantity: quantity, type: targetType);

    final index = _items.indexWhere(
      (l) =>
          (l.productId == cartLine.productId ||
              (l.productName == product.name && l.umkmName == product.umkm)) &&
          l.type == targetType,
    );

    if (index >= 0) {
      final existing = _items[index];
      final accepted = _acceptedQuantity(
        existing,
        quantity,
        alreadyInCart: existing.quantity,
      );
      if (accepted <= 0) return 0;
      _items[index] = existing.copyWith(
        quantity: existing.quantity + accepted,
        stock: cartLine.stock,
        clearStock: cartLine.stock == null,
      );
      _changed();
      return accepted;
    } else {
      final accepted = _acceptedQuantity(cartLine, quantity);
      if (accepted <= 0) return 0;
      _items.add(cartLine.copyWith(quantity: accepted));
      _changed();
      return accepted;
    }
  }

  /// Menambahkan CartLine secara langsung
  int addCartLine(CartLine line) {
    if (line.quantity <= 0) return 0;
    final index = _items.indexWhere(
      (l) => l.productId == line.productId && l.type == line.type,
    );
    if (index >= 0) {
      final existing = _items[index];
      final accepted = _acceptedQuantity(
        existing,
        line.quantity,
        alreadyInCart: existing.quantity,
      );
      if (accepted <= 0) return 0;
      _items[index] = existing.copyWith(
        quantity: existing.quantity + accepted,
        stock: line.stock,
        clearStock: line.stock == null,
      );
      _changed();
      return accepted;
    } else {
      final accepted = _acceptedQuantity(line, line.quantity);
      if (accepted <= 0) return 0;
      _items.add(line.copyWith(quantity: accepted));
      _changed();
      return accepted;
    }
  }

  /// Mengubah jumlah item produk (jika <= 0, produk akan dihapus)
  int updateQuantity(String productId, int newQuantity, {OrderType? type}) {
    final index = _items.indexWhere(
      (l) => l.productId == productId && (type == null || l.type == type),
    );
    if (index < 0) return 0;
    if (newQuantity <= 0) {
      _items.removeAt(index);
      _changed();
      return 0;
    }
    final item = _items[index];
    final stockLimit = _stockLimit(item);
    if (stockLimit != null && stockLimit <= 0) {
      _items.removeAt(index);
      _changed();
      return 0;
    }
    final effectiveQuantity = stockLimit == null
        ? newQuantity
        : newQuantity.clamp(1, stockLimit).toInt();
    _items[index] = item.copyWith(quantity: effectiveQuantity);
    _changed();
    return effectiveQuantity;
  }

  /// Menghapus produk tertentu dari keranjang
  void removeProduct(String productId, {OrderType? type}) {
    _items.removeWhere(
      (l) => l.productId == productId && (type == null || l.type == type),
    );
    _changed();
  }

  /// Menghapus seluruh item untuk grup (UMKM + Mode Pesanan) tertentu setelah checkout
  void clearGroup(String umkmId, OrderType type) {
    _items.removeWhere((l) => l.umkmId == umkmId && l.type == type);
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
    final removeIndexes = <int>[];
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

      if (matchingProduct != null) {
        if (_items[i].type != OrderType.preOrder &&
            !matchingProduct.isPreOrder &&
            matchingProduct.stock != null &&
            matchingProduct.stock! <= 0) {
          removeIndexes.add(i);
          hasChanged = true;
          continue;
        }
        final newType = matchingProduct.isBothMode
            ? line.type // pertahankan pilihan mode pelanggan jika UMKM mengizinkan keduanya
            : matchingProduct.parsedOrderType;

        final updatedLine = _items[i].copyWith(
          productName: matchingProduct.name,
          unit: matchingProduct.unit,
          imageUrl: matchingProduct.imageUrl,
          price: matchingProduct.price.toDouble(),
          type: newType,
          umkmName: matchingProduct.umkm,
          umkmType: matchingProduct.umkmType,
          courierFee: matchingProduct.courierFee,
          clearCourierFee: matchingProduct.courierFee == null,
          pickupLocation: matchingProduct.pickupLocation,
          codAvailable: matchingProduct.codAvailable,
          pickupAvailable: matchingProduct.pickupAvailable,
          minOrderPo: matchingProduct.minOrderPo,
          modePenjualan: matchingProduct.modePenjualan,
          stock: matchingProduct.stock,
          clearStock: matchingProduct.stock == null,
        );
        final stockLimit = _stockLimit(updatedLine);
        final withAvailableQuantity = stockLimit != null &&
                updatedLine.quantity > stockLimit
            ? updatedLine.copyWith(quantity: stockLimit)
            : updatedLine;
        if (withAvailableQuantity.productName != _items[i].productName ||
            withAvailableQuantity.unit != _items[i].unit ||
            withAvailableQuantity.imageUrl != _items[i].imageUrl ||
            withAvailableQuantity.price != _items[i].price ||
            withAvailableQuantity.type != _items[i].type ||
            withAvailableQuantity.umkmName != _items[i].umkmName ||
            withAvailableQuantity.umkmType != _items[i].umkmType ||
            withAvailableQuantity.courierFee != _items[i].courierFee ||
            withAvailableQuantity.pickupLocation != _items[i].pickupLocation ||
            withAvailableQuantity.codAvailable != _items[i].codAvailable ||
            withAvailableQuantity.pickupAvailable != _items[i].pickupAvailable ||
            withAvailableQuantity.minOrderPo != _items[i].minOrderPo ||
            withAvailableQuantity.modePenjualan != _items[i].modePenjualan ||
            withAvailableQuantity.stock != _items[i].stock ||
            withAvailableQuantity.quantity != _items[i].quantity) {
          _items[i] = withAvailableQuantity;
          hasChanged = true;
        }
      }
    }

    for (final index in removeIndexes.reversed) {
      _items.removeAt(index);
    }
    if (hasChanged) {
      _changed();
    }
  }

  int? _stockLimit(CartLine item) {
    final mode = item.modePenjualan
        .toLowerCase()
        .replaceAll(RegExp(r'[-_ ]'), '');
    return item.type == OrderType.preOrder || mode == 'preorder'
        ? null
        : item.stock;
  }

  int _acceptedQuantity(
    CartLine item,
    int requested, {
    int alreadyInCart = 0,
  }) {
    final stockLimit = _stockLimit(item);
    if (stockLimit == null) return requested;
    return (stockLimit - alreadyInCart).clamp(0, requested).toInt();
  }

  void _changed() {
    notifyListeners();
    final customerId = _customerId;
    if (customerId == null) return;
    final encodedItems = jsonEncode(_items.map(_encodeItem).toList());
    _saveOperation = _saveOperation.then((_) async {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        _storageKey(customerId),
        encodedItems,
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
    'min_order_po': item.minOrderPo,
    'mode_penjualan': item.modePenjualan,
    'stock': item.stock,
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
      minOrderPo: (item['min_order_po'] as num?)?.toInt() ?? 0,
      modePenjualan: item['mode_penjualan']?.toString() ?? 'ready',
      stock: (item['stock'] as num?)?.toInt(),
    );
  }
}
