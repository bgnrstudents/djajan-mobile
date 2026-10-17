import '../screens/customer/order/order_model.dart';

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
  });

  bool get isPreOrder => orderType.toLowerCase().contains('pre');

  OrderType get parsedOrderType =>
      isPreOrder ? OrderType.preOrder : OrderType.instant;

  CartLine toCartLine({int quantity = 1}) {
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
      imageUrl: imageUrl.isNotEmpty
          ? imageUrl
          : 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400&q=80',
      quantity: quantity,
      price: price.toDouble(),
      type: parsedOrderType,
      umkmId: validUmkmId,
      umkmName: umkm,
      umkmType: umkmType,
      courierFee: courierFee,
      pickupLocation: pickupLocation,
    );
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      umkmId: json['umkm_id']?.toString() ?? '',
      umkm: json['umkm_name'] as String? ?? json['umkm'] as String? ?? '',
      umkmType: json['umkm_type'] as String? ?? 'UMKM Kuliner Desa',
      price: (json['price'] as num?)?.toInt() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      category: json['category'] as String? ?? 'Semua',
      orderType: json['order_type'] as String? ?? 'Pesan Sekarang',
      imageUrl: json['image_url'] as String? ?? '',
      description: json['description'] as String? ?? '',
      variant: json['variant'] as String? ?? 'Pilihan Terbaik',
      unit: json['unit'] as String? ?? 'Porsi',
      courierFee: (json['courier_fee'] as num?)?.toDouble() ?? 5000,
      pickupLocation: json['pickup_location'] as String? ?? 'Desa Kreyongan Atas',
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
      'image_url': imageUrl,
      'description': description,
      'variant': variant,
      'unit': unit,
      'courier_fee': courierFee,
      'pickup_location': pickupLocation,
    };
  }
}
