/// Model UMKM (warung / dapur warga) yang dipakai di storefront & katalog.
///
/// Sudah disiapkan `fromJson`/`toJson` agar siap ditukar ke data Laravel API.
class Umkm {
  final String id;
  final String name;
  final String type;
  final String description;
  final String imageUrl;
  final String pickupLocation;
  final double? courierFee;
  final double rating;
  final int soldCount;
  final bool isVerified;
  final String phone;

  const Umkm({
    required this.id,
    required this.name,
    required this.type,
    this.description = '',
    this.imageUrl = '',
    required this.pickupLocation,
    this.courierFee,
    this.rating = 0.0,
    this.soldCount = 0,
    this.isVerified = true,
    this.phone = '',
  });

  /// UMKM yang hanya melayani ambil sendiri (tanpa kurir warga).
  bool get isPickupOnly => courierFee == null;

  /// Bisa diantar kurir warga.
  bool get hasCourier => courierFee != null;

  /// Inisial nama untuk avatar storefront, maksimal 2 huruf.
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.take(2).map((p) => p.isEmpty ? '' : p[0]).join().toUpperCase();
  }

  Umkm copyWith({
    String? id,
    String? name,
    String? type,
    String? description,
    String? imageUrl,
    String? pickupLocation,
    double? courierFee,
    double? rating,
    int? soldCount,
    bool? isVerified,
    String? phone,
  }) {
    return Umkm(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      courierFee: courierFee ?? this.courierFee,
      rating: rating ?? this.rating,
      soldCount: soldCount ?? this.soldCount,
      isVerified: isVerified ?? this.isVerified,
      phone: phone ?? this.phone,
    );
  }

  factory Umkm.fromJson(Map<String, dynamic> json) {
    return Umkm(
      id: (json['id'] ?? json['id_umkm'])?.toString() ?? '',
      name: (json['name'] ?? json['nama_usaha']) as String? ?? '',
      type:
          (json['type'] ?? json['spesialis']) as String? ?? 'UMKM Kuliner Desa',
      description:
          (json['description'] ?? json['deskripsi_usaha']) as String? ?? '',
      imageUrl: (json['image_url'] ?? json['foto_profil_url']) as String? ?? '',
      pickupLocation:
          (json['pickup_location'] ?? json['alamat']) as String? ??
          'Desa Kreyongan Atas',
      courierFee: (json['courier_fee'] as num?)?.toDouble(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      soldCount: (json['sold_count'] as num?)?.toInt() ?? 0,
      isVerified: json['is_verified'] as bool? ?? true,
      phone: (json['phone'] ?? json['no_telp_usaha']) as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'description': description,
      'image_url': imageUrl,
      'pickup_location': pickupLocation,
      'courier_fee': courierFee,
      'rating': rating,
      'sold_count': soldCount,
      'is_verified': isVerified,
      'phone': phone,
    };
  }
}
