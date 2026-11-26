import 'order.dart';

class Product {
  final String id;
  final String name;
  final String umkmId;
  final String umkm;
  final String umkmType;
  final int price;
  final double rating;
  final String category;
  final String orderType; // 'Pre-Order' atau 'Pesan Sekarang'
  final String imageUrl;
  final String description;
  final String variant;
  final String unit;
  final double? courierFee;
  final String pickupLocation;
  final bool codAvailable;
  final bool pickupAvailable;
  final int? stock;
  final String modePenjualan; // 'ready', 'pre_order', 'keduanya'
  final int minOrderPo;

  const Product({
    this.id = '',
    required this.name,
    this.umkmId = '',
    required this.umkm,
    this.umkmType = 'UMKM Kuliner Desa',
    required this.price,
    required this.rating,
    required this.category,
    required this.orderType,
    this.imageUrl = '',
    this.description = '',
    this.variant = 'Pilihan Terbaik',
    this.unit = 'Porsi',
    this.courierFee = 5000,
    this.pickupLocation = 'Desa Kreyongan Atas',
    this.codAvailable = true,
    this.pickupAvailable = true,
    this.stock,
    this.modePenjualan = 'ready',
    this.minOrderPo = 0,
  });

  bool get isPreOrder =>
      modePenjualan == 'pre_order' ||
      (modePenjualan != 'keduanya' && orderType.toLowerCase().contains('pre'));
  bool get isBothMode => modePenjualan == 'keduanya';
  bool get isReadyOnly => modePenjualan == 'ready';
  bool get isOutOfStock => !isPreOrder && stock != null && stock! <= 0;

  OrderType get parsedOrderType =>
      isPreOrder ? OrderType.preOrder : OrderType.instant;

  CartLine toCartLine({int quantity = 1, OrderType? type}) {
    final validId = id.isNotEmpty
        ? id
        : 'prod_${name.toLowerCase().replaceAll(RegExp(r'\s+'), '_')}';
    final validUmkmId = umkmId.isNotEmpty
        ? umkmId
        : 'umkm_${umkm.toLowerCase().replaceAll(RegExp(r'\s+'), '_')}';

    return CartLine(
      productId: validId,
      productName: name,
      variant: variant,
      unit: unit,
      imageUrl: imageUrl.isNotEmpty ? imageUrl : 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400&q=80',
      quantity: quantity,
      price: price.toDouble(),
      type: type ?? parsedOrderType,
      umkmId: validUmkmId,
      umkmName: umkm,
      umkmType: umkmType,
      courierFee: courierFee,
      pickupLocation: pickupLocation,
      codAvailable: codAvailable,
      pickupAvailable: pickupAvailable,
      minOrderPo: minOrderPo,
      modePenjualan: modePenjualan,
      stock: stock,
    );
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    final rawPrice = json['price'] ?? json['harga'];
    return Product(
      id: (json['id'] ?? json['id_produk'])?.toString() ?? '',
      name: (json['name'] ?? json['nama_produk']) as String? ?? '',
      umkmId: (json['umkm_id'] ?? json['id_umkm'])?.toString() ?? '',
      umkm: json['umkm_name'] as String? ?? json['umkm'] as String? ?? '',
      umkmType: json['umkm_type'] as String? ?? 'UMKM Kuliner Desa',
      price: rawPrice is num ? rawPrice.toInt() : 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      category: (json['category'] ?? json['kategori']) as String? ?? 'Semua',
      orderType:
          (json['order_type'] ?? json['mode_penjualan']) as String? ??
          'Pesan Sekarang',
      imageUrl: (json['image_url'] ?? json['gambar_url']) as String? ?? '',
      description: (json['description'] ?? json['deskripsi']) as String? ?? '',
      variant: json['variant'] as String? ?? 'Pilihan Terbaik',
      unit: json['unit'] as String? ?? 'Porsi',
      courierFee: (json['courier_fee'] as num?)?.toDouble(),
      pickupLocation:
          json['pickup_location'] as String? ?? 'Desa Kreyongan Atas',
      codAvailable: json['cod_available'] as bool? ?? true,
      pickupAvailable: json['pickup_available'] as bool? ?? true,
      stock: (json['stok'] ?? json['stock']) is num
          ? (json['stok'] ?? json['stock']).toInt()
          : null,
      modePenjualan: (json['mode_penjualan'] as String?) ??
          ((json['order_type'] as String?)?.toLowerCase().contains('pre') == true
              ? 'pre_order'
              : 'ready'),
      minOrderPo: (json['min_order_po'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'umkm_id': umkmId,
      'umkm_name': umkm,
      'umkm_type': umkmType,
      'price': price,
      'rating': rating,
      'category': category,
      'order_type': orderType,
      'mode_penjualan': modePenjualan,
      'min_order_po': minOrderPo,
      'image_url': imageUrl,
      'description': description,
      'variant': variant,
      'unit': unit,
      'courier_fee': courierFee,
      'pickup_location': pickupLocation,
      'cod_available': codAvailable,
      'pickup_available': pickupAvailable,
      'stok': stock,
    };
  }
}
