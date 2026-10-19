import 'package:flutter/material.dart';

import '../../../config/app_config.dart';
import '../../../data/sample_catalog.dart';
import '../../../models/product.dart';
import '../../../models/umkm.dart';
import '../../../widgets/favorite_button.dart';
import '../../../widgets/product_card.dart';
import '../order/order_widgets.dart';
import '../cart/cart.dart';
import '../cart/cart_service.dart';
import '../product/product_detail_screen.dart';
import '../umkm/umkm_storefront_screen.dart';
import 'favorite_service.dart';

/// Halaman daftar favorit pengguna: produk dan UMKM yang disimpan.
class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  static const Color primaryGreen = AppConfig.primaryColor;
  static const Color textDark = Color(0xFF1E293B);
  static const Color textMuted = Color(0xFF64748B);
  static const Color background = Color(0xFFF8F9FD);

  final FavoriteService _favorites = FavoriteService();
  final CartService _cartService = CartService();

  void _addToCart(Product product) {
    _cartService.addProduct(product);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} ditambahkan ke keranjang'),
        backgroundColor: primaryGreen,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Lihat',
          textColor: const Color(0xFFFFBE25),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CartScreen()),
          ),
        ),
      ),
    );
  }

  void _openStorefront(Umkm umkm) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => UmkmStorefrontScreen(umkm: umkm)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: background,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DjajanPageHeader(
              title: 'Favorit Saya',
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: textDark),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(height: 8),
            AnimatedBuilder(
              animation: _favorites,
              builder: (context, _) => Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9EEF2),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TabBar(
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: primaryGreen,
                  unselectedLabelColor: const Color(0xFF59636E),
                  labelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  unselectedLabelStyle: const TextStyle(fontSize: 13),
                  tabs: [
                    Tab(text: 'Produk (${_favorites.productCount})'),
                    Tab(text: 'UMKM (${_favorites.umkmCount})'),
                  ],
                ),
              ),
            ),
            Expanded(
              child: AnimatedBuilder(
                animation: _favorites,
                builder: (context, _) => TabBarView(
                  children: [
                    _buildProductsTab(),
                    _buildUmkmTab(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------- Produk
  Widget _buildProductsTab() {
    final products = _favorites.favoriteProducts;

    if (products.isEmpty) {
      return _emptyState(
        icon: Icons.favorite_border,
        title: 'Belum ada produk favorit',
        message:
            'Tekan ikon hati pada produk untuk menyimpannya di sini.',
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: products.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemBuilder: (context, index) {
        final product = products[index];
        final umkm = SampleCatalog.umkmById(product.umkmId);
        return ProductCard(
          product: product,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(product: product),
            ),
          ),
          onUmkmTap: umkm == null ? null : () => _openStorefront(umkm),
          onAddToCart: () => _addToCart(product),
        );
      },
    );
  }

  // ----------------------------------------------------------------- UMKM
  Widget _buildUmkmTab() {
    final umkms = _favorites.favoriteUmkms;

    if (umkms.isEmpty) {
      return _emptyState(
        icon: Icons.storefront_outlined,
        title: 'Belum ada UMKM favorit',
        message:
            'Tekan ikon hati di halaman warung untuk menyimpannya di sini.',
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: umkms.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (context, index) => _umkmCard(umkms[index]),
    );
  }

  Widget _umkmCard(Umkm umkm) {
    final productCount = SampleCatalog.productsOf(umkm.id).length;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: () => _openStorefront(umkm),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE4E9EF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Avatar + Favorite
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF175D2B), Color(0xFF22915D)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        umkm.initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  FavoriteButton(
                    umkmId: umkm.id,
                    backgroundColor: Colors.transparent,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Name + Verified Badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      umkm.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                        height: 1.2,
                      ),
                    ),
                  ),
                  if (umkm.isVerified) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.verified,
                        size: 14, color: Color(0xFF16A34A)),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                umkm.type,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11.5, color: textMuted),
              ),
              const Spacer(),
              // Rating + Product Count
              Row(
                children: [
                  const Icon(Icons.star, size: 13, color: Color(0xFFF29B00)),
                  const SizedBox(width: 3),
                  Text(
                    '${umkm.rating}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$productCount produk',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: Color(0xFFEAF3EC),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 44, color: primaryGreen),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: textMuted,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
