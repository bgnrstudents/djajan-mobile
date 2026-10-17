import '../models/product.dart';
import '../models/umkm.dart';

/// Sumber data contoh (dummy) katalog Djajan.
///
/// Semua halaman (beranda, katalog, storefront) membaca dari sini agar
/// konsisten. Saat backend Laravel siap, cukup ganti isi kelas ini dengan
/// pemanggilan API tanpa mengubah UI.
class SampleCatalog {
  const SampleCatalog._();

  // ------------------------------------------------------------------ UMKM
  static const List<Umkm> umkms = [
    Umkm(
      id: 'umkm-bu-minten',
      name: 'Dapur Bu Minten',
      type: 'Spesialis Katering & Kotakan',
      description:
          'Dapur katering rumahan yang melayani nasi kotak, tumpeng, dan paket hajatan warga desa. Dimasak fresh sesuai jadwal pesanan.',
      imageUrl:
          'https://images.unsplash.com/photo-1556910103-1c02745aae4d?w=600&q=80',
      pickupLocation: 'Dapur Bu Minten RT 01',
      courierFee: 5000,
      rating: 4.8,
      soldCount: 320,
      phone: '0812-3456-7890',
    ),
    Umkm(
      id: 'umkm-pak-budi',
      name: 'Toko Pak Budi',
      type: 'Warung Kelontong & Es Tradisional',
      description:
          'Warung serba ada dengan aneka minuman segar, es tradisional, dan paket snack box untuk rapat atau pengajian.',
      imageUrl:
          'https://images.unsplash.com/photo-1604719312566-8912e9227c6a?w=600&q=80',
      pickupLocation: 'Toko Pak Budi',
      courierFee: null,
      rating: 4.9,
      soldCount: 540,
      phone: '0813-2233-4455',
    ),
    Umkm(
      id: 'umkm-mba-rina',
      name: 'Dapur Mba Rina',
      type: 'Kue Basah & Pastry',
      description:
          'Aneka kue basah, brownies lumer, dan pastry rumahan. Cocok untuk hantaran, arisan, dan suguhan tamu.',
      imageUrl:
          'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=600&q=80',
      pickupLocation: 'Dapur Mba Rina Gang 2',
      courierFee: 4000,
      rating: 4.7,
      soldCount: 210,
      phone: '0857-1122-3344',
    ),
    Umkm(
      id: 'umkm-bu-siti',
      name: 'Warung Bu Siti',
      type: 'Gorengan & Masakan Desa',
      description:
          'Gorengan hangat dan masakan desa sehari-hari. Siap disantap langsung atau dipesan untuk syukuran keluarga.',
      imageUrl:
          'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=600&q=80',
      pickupLocation: 'Warung Bu Siti Depan Pos',
      courierFee: 3000,
      rating: 4.8,
      soldCount: 430,
      phone: '0895-6677-8899',
    ),
  ];

  // -------------------------------------------------------------- Produk
  static const List<Product> products = [
    Product(
      id: 'p-nasi-geprek',
      name: 'Nasi Kotak Ayam Geprek',
      umkmId: 'umkm-bu-minten',
      umkm: 'Dapur Bu Minten',
      umkmType: 'Spesialis Katering & Kotakan',
      price: 15000,
      rating: 4.8,
      category: 'Makanan',
      orderType: 'Pre-Order',
      variant: 'Porsi Spesial Kenduri',
      unit: 'Kotak',
      imageUrl:
          'https://images.unsplash.com/photo-1626645738196-c2a7c87a8f58?w=400&q=80',
      courierFee: 5000,
      pickupLocation: 'Ke dapur Bu Minten RT 01',
    ),
    Product(
      id: 'p-ayam-lengkuas',
      name: 'Ayam Lengkuas Goreng Satuan',
      umkmId: 'umkm-bu-minten',
      umkm: 'Dapur Bu Minten',
      umkmType: 'Spesialis Katering & Kotakan',
      price: 12000,
      rating: 4.7,
      category: 'Makanan',
      orderType: 'Pesan Sekarang',
      variant: 'Ayam Goreng Gurih',
      unit: 'Porsi',
      imageUrl:
          'https://images.unsplash.com/photo-1598103442097-8b74394b95c6?w=400&q=80',
      courierFee: 5000,
      pickupLocation: 'Ke dapur Bu Minten RT 01',
    ),
    Product(
      id: 'p-es-teh',
      name: 'Es Teh Solo Original',
      umkmId: 'umkm-pak-budi',
      umkm: 'Toko Pak Budi',
      umkmType: 'Warung Kelontong & Es Tradisional',
      price: 5000,
      rating: 4.9,
      category: 'Minuman',
      orderType: 'Pesan Sekarang',
      variant: 'Gula Asli, Cup Jumbo',
      unit: 'Gelas',
      imageUrl:
          'https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=400&q=80',
      courierFee: null,
      pickupLocation: 'Toko Pak Budi',
    ),
    Product(
      id: 'p-snack-box',
      name: 'Paket Snack Box Rapat',
      umkmId: 'umkm-pak-budi',
      umkm: 'Toko Pak Budi',
      umkmType: 'Warung Kelontong & Es Tradisional',
      price: 18000,
      rating: 4.8,
      category: 'Jajanan',
      orderType: 'Pre-Order',
      variant: '3 Kue + Air Mineral',
      unit: 'Kotak',
      imageUrl:
          'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=400&q=80',
      courierFee: null,
      pickupLocation: 'Toko Pak Budi',
    ),
    Product(
      id: 'p-brownies-loyang',
      name: 'Brownies Lumer Loyang',
      umkmId: 'umkm-mba-rina',
      umkm: 'Dapur Mba Rina',
      umkmType: 'Kue Basah & Pastry',
      price: 25000,
      rating: 4.7,
      category: 'Jajanan',
      orderType: 'Pre-Order',
      variant: 'Ukuran 20x10 cm',
      unit: 'Loyang',
      imageUrl:
          'https://images.unsplash.com/photo-1606313564200-e75d5e30476c?w=400&q=80',
      courierFee: 4000,
      pickupLocation: 'Dapur Mba Rina Gang 2',
    ),
    Product(
      id: 'p-mini-brownies',
      name: 'Mini Cup Brownies Lumer',
      umkmId: 'umkm-mba-rina',
      umkm: 'Dapur Mba Rina',
      umkmType: 'Kue Basah & Pastry',
      price: 8000,
      rating: 4.6,
      category: 'Jajanan',
      orderType: 'Pesan Sekarang',
      variant: 'Cup Siap Santap',
      unit: 'Cup',
      imageUrl:
          'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=400&q=80',
      courierFee: 4000,
      pickupLocation: 'Dapur Mba Rina Gang 2',
    ),
    Product(
      id: 'p-gorengan-combo',
      name: 'Gorengan Hangat Combo',
      umkmId: 'umkm-bu-siti',
      umkm: 'Warung Bu Siti',
      umkmType: 'Gorengan & Masakan Desa',
      price: 10000,
      rating: 4.8,
      category: 'Jajanan',
      orderType: 'Pesan Sekarang',
      variant: 'Isi 6 Pcs Campur',
      unit: 'Porsi',
      imageUrl:
          'https://images.unsplash.com/photo-1541592106381-b31e9677c0e5?w=400&q=80',
      courierFee: 3000,
      pickupLocation: 'Warung Bu Siti Depan Pos',
    ),
    Product(
      id: 'p-tumpeng-mini',
      name: 'Tumpeng Mini Syukuran',
      umkmId: 'umkm-bu-siti',
      umkm: 'Warung Bu Siti',
      umkmType: 'Gorengan & Masakan Desa',
      price: 35000,
      rating: 4.9,
      category: 'Makanan',
      orderType: 'Pre-Order',
      variant: 'Lengkap Lauk 5 Macam',
      unit: 'Porsi',
      imageUrl:
          'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=400&q=80',
      courierFee: 3000,
      pickupLocation: 'Warung Bu Siti Depan Pos',
    ),
  ];

  // ------------------------------------------------------------- Helpers
  static List<Product> productsOf(String umkmId) =>
      products.where((p) => p.umkmId == umkmId).toList();

  static Umkm? umkmById(String umkmId) {
    for (final u in umkms) {
      if (u.id == umkmId) return u;
    }
    return null;
  }

  /// Daftar kategori unik dari katalog, diawali 'Semua'.
  static List<String> get categories {
    final set = <String>{};
    for (final p in products) {
      set.add(p.category);
    }
    final list = set.toList()..sort();
    return ['Semua', ...list];
  }

  /// Pencarian sederhana: cocokkan nama produk, nama UMKM, atau kategori.
  static List<Product> search(
    String query, {
    String category = 'Semua',
    String orderType = 'Semua',
    String? umkmId,
  }) {
    final q = query.trim().toLowerCase();
    return products.where((p) {
      final categoryMatch = category == 'Semua' || p.category == category;
      final orderTypeMatch = orderType == 'Semua' || p.orderType == orderType;
      final umkmMatch = umkmId == null || p.umkmId == umkmId;
      final searchMatch = q.isEmpty ||
          p.name.toLowerCase().contains(q) ||
          p.umkm.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q);
      return categoryMatch && orderTypeMatch && umkmMatch && searchMatch;
    }).toList();
  }
}
