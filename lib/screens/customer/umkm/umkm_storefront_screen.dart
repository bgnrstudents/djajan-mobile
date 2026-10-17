import 'package:flutter/material.dart';

import '../../../config/app_config.dart';
import '../../../data/sample_catalog.dart';
import '../../../models/product.dart';
import '../../../models/umkm.dart';
import '../../../widgets/favorite_button.dart';
import '../../../widgets/product_card.dart';
import '../cart/cart.dart';
import '../cart/cart_service.dart';
import '../order/order_widgets.dart';
import '../product/product_detail_screen.dart';

/// Halaman toko/dapur milik satu UMKM: banner, info warung, dan semua
/// produknya dengan filter Ready / Pre-Order.
class UmkmStorefrontScreen extends StatefulWidget {
  final Umkm umkm;

  const UmkmStorefrontScreen({super.key, required this.umkm});

  @override
  State<UmkmStorefrontScreen> createState() => _UmkmStorefrontScreenState();
}

class _UmkmStorefrontScreenState extends State<UmkmStorefrontScreen> {
  static const Color primaryGreen = AppConfig.primaryColor;
  static const Color textDark = Color(0xFF1E293B);
  static const Color textMuted = Color(0xFF64748B);
  static const Color background = Color(0xFFF8F9FD);

  final CartService _cartService = CartService();
  final TextEditingController _searchController = TextEditingController();

  String _orderTypeFilter = 'Semua';

  Umkm get umkm => widget.umkm;

  List<Product> get _storeProducts => SampleCatalog.productsOf(umkm.id);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

  List<Product> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    return _storeProducts.where((p) {
      final typeMatch =
          _orderTypeFilter == 'Semua' || p.orderType == _orderTypeFilter;
      final searchMatch = q.isEmpty ||
          p.name.toLowerCase().contains(q) ||
          p.variant.toLowerCase().contains(q);
      return typeMatch && searchMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final products = _storeProducts;
    final bool hasPreOrder = products.any((p) => p.isPreOrder);
    final bool hasInstant = products.any((p) => !p.isPreOrder);

    return Scaffold(
      backgroundColor: background,
      body: CustomScrollView(
        slivers: [
          _buildHeader(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsRow(products.length),
                  const SizedBox(height: 14),
                  _buildServiceCard(),
                  const SizedBox(height: 18),

                  // Pencarian dalam toko
                  _buildStoreSearch(),
                  const SizedBox(height: 14),

                  // Filter tipe pesanan
                  if (hasPreOrder && hasInstant) ...[
                    _buildOrderTypeFilter(),
                    const SizedBox(height: 16),
                  ],

                  Row(
                    children: [
                      const Text(
                        'Produk Warung',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF3EC),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_filtered.length}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: primaryGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildProductGrid(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------- Header
  Widget _buildHeader() {
    return SliverAppBar(
      expandedHeight: 230,
      pinned: true,
      backgroundColor: primaryGreen,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          shape: BoxShape.circle,
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: FavoriteButton(umkmId: umkm.id),
        ),
        const SizedBox(width: 6),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            shape: BoxShape.circle,
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
          ),
          child: IconButton(
            tooltip: 'Hubungi penjual',
            icon: const Icon(
              Icons.chat_bubble_outline,
              color: textDark,
              size: 19,
            ),
            onPressed: () => openWhatsApp(
              context,
              phone: umkm.phone.isNotEmpty ? umkm.phone : kUmkmWhatsApp,
              message:
                  'Halo ${umkm.name}, saya mau tanya-tanya produk di Djajan.',
            ),
          ),
        ),
        const SizedBox(width: 6),
        AnimatedBuilder(
          animation: _cartService,
          builder: (context, _) {
            final count = _cartService.totalQuantity;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                shape: BoxShape.circle,
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
              ),
              child: Stack(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.shopping_cart_outlined,
                      color: textDark,
                      size: 20,
                    ),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CartScreen()),
                    ),
                  ),
                  if (count > 0)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFBA1A1A),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          '$count',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            umkm.imageUrl.isNotEmpty
                ? Image.network(
                    umkm.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _headerFallback(),
                  )
                : _headerFallback(),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.15),
                      Colors.black.withValues(alpha: 0.75),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF175D2B), Color(0xFF22915D)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        umkm.initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                umkm.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (umkm.isVerified) ...[
                              const SizedBox(width: 5),
                              const Icon(
                                Icons.verified,
                                color: Color(0xFF4ADE80),
                                size: 17,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          umkm.type,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerFallback() {
    return Container(
      color: const Color(0xFF175D2B),
      child: const Icon(Icons.storefront, size: 90, color: Colors.white24),
    );
  }

  // ---------------------------------------------------------------- Stats
  Widget _buildStatsRow(int productCount) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4E9EF)),
      ),
      child: Row(
        children: [
          _statItem('${umkm.rating}', 'Rating', Icons.star,
              const Color(0xFFF29B00)),
          _divider(),
          _statItem('$productCount', 'Produk', Icons.inventory_2_outlined,
              primaryGreen),
          _divider(),
          _statItem('${umkm.soldCount}', 'Terjual', Icons.shopping_bag_outlined,
              const Color(0xFF2563EB)),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: textMuted),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 36,
        color: const Color(0xFFE9EEF2),
      );

  // -------------------------------------------------------------- Layanan
  Widget _buildServiceCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4E9EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 18, color: primaryGreen),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  umkm.pickupLocation,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (umkm.hasCourier)
                _serviceChip(
                  Icons.delivery_dining_outlined,
                  'Diantar Kurir Warga (+Rp${_rupiah(umkm.courierFee!.round())})',
                  const Color(0xFF2563EB),
                ),
              _serviceChip(
                Icons.storefront_outlined,
                'Ambil Sendiri (Gratis)',
                primaryGreen,
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryGreen,
                side: const BorderSide(color: primaryGreen, width: 1.2),
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => openWhatsApp(
                context,
                phone: umkm.phone.isNotEmpty ? umkm.phone : kUmkmWhatsApp,
                message:
                    'Halo ${umkm.name}, saya mau pesan produk di Djajan.',
              ),
              icon: const Icon(Icons.chat_bubble_outline, size: 17),
              label: const Text(
                'Hubungi Penjual',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _serviceChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------- Pencarian
  Widget _buildStoreSearch() {
    return TextField(
      controller: _searchController,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: 'Cari produk di ${umkm.name}...',
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
        prefixIcon: const Icon(Icons.search, size: 21),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
              ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE4E9EF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE4E9EF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryGreen, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 13),
      ),
    );
  }

  // ------------------------------------------------------------- Filter PO
  Widget _buildOrderTypeFilter() {
    const types = ['Semua', 'Pesan Sekarang', 'Pre-Order'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE9EEF2),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: types.map((type) {
          final isSelected = _orderTypeFilter == type;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _orderTypeFilter = type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    type,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: const Color(0xFF59636E),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // --------------------------------------------------------------- Produk
  Widget _buildProductGrid() {
    final items = _filtered;

    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            const Icon(Icons.search_off_rounded, size: 46, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              'Produk tidak ditemukan',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Coba kata kunci lain atau ubah filter.',
              style: TextStyle(fontSize: 12.5, color: textMuted),
            ),
            if (_searchController.text.isNotEmpty ||
                _orderTypeFilter != 'Semua') ...[
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => setState(() {
                  _searchController.clear();
                  _orderTypeFilter = 'Semua';
                }),
                child: const Text('Reset Filter'),
              ),
            ],
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 235,
      ),
      itemBuilder: (context, index) {
        final product = items[index];
        return ProductCard(
          product: product,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(product: product),
            ),
          ),
          onAddToCart: () => _addToCart(product),
        );
      },
    );
  }

  String _rupiah(int value) => value.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      );
}
