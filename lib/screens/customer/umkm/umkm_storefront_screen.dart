import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/app_config.dart';
import '../../../data/sample_catalog.dart';
import '../../../models/product.dart';
import '../../../models/umkm.dart';
import '../../../services/api_service.dart';
import '../../../services/catalog_service.dart';
import '../../../widgets/favorite_button.dart';
import '../../../widgets/app_network_image.dart';
import '../../../widgets/product_card.dart';
import '../cart/cart.dart';
import '../../../services/cart_service.dart';
import '../../../theme/app_theme.dart';
import '../order/order_widgets.dart';
import '../product/product_detail_screen.dart';

/// Halaman toko/dapur milik satu UMKM: banner, info warung, dan semua
/// produknya dengan filter Ready / Pre-Order.
class UmkmStorefrontScreen extends StatefulWidget {
  final Umkm umkm;
  final String? highlightedProductId;

  const UmkmStorefrontScreen({
    super.key,
    required this.umkm,
    this.highlightedProductId,
  });

  @override
  State<UmkmStorefrontScreen> createState() => _UmkmStorefrontScreenState();
}

class _UmkmStorefrontScreenState extends State<UmkmStorefrontScreen> {
  static const Color primaryGreen = AppConfig.primaryColor;
  static const Color textDark = AppColors.textDark;
  static const Color textMuted = AppColors.textGrey;
  static const Color background = AppColors.latar;

  final CartService _cartService = CartService();
  final TextEditingController _searchController = TextEditingController();

  String _orderTypeFilter = 'Semua';
  bool _loadingReviews = false;
  double _avgRating = 0.0;
  int _totalReviews = 0;
  List<Map<String, dynamic>> _reviews = [];

  Umkm get umkm => widget.umkm;

  CatalogService? get _catalog => Provider.of<CatalogService?>(context, listen: false);

  @override
  void initState() {
    super.initState();
    _avgRating = widget.umkm.rating;
    _totalReviews = widget.umkm.reviewCount;
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() => _loadingReviews = true);
    try {
      final res = await ApiService.get('umkm/ulasan', query: {'id_umkm': umkm.id});
      // ApiService._proses mengembalikan json['data'] langsung.
      // Antisipasi jika data ada di res langsung atau dibungkus dalam key 'data'.
      final Map? data = (res is Map && res['data'] is Map)
          ? (res['data'] as Map)
          : (res is Map ? res : null);

      if (data != null && mounted) {
        setState(() {
          _avgRating = (data['rata_rata'] as num?)?.toDouble() ?? _avgRating;
          _totalReviews = (data['total_ulasan'] as num?)?.toInt() ?? _totalReviews;
          final list = data['daftar_ulasan'];
          if (list is List) {
            _reviews = list.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
          }
        });
      }
    } catch (_) {
      // Offline fallback
    } finally {
      if (mounted) setState(() => _loadingReviews = false);
    }
  }

  List<Product> get _storeProducts {
    final catalog = _catalog;
    if (catalog == null) {
      return SampleCatalog.productsOf(umkm.id);
    }
    return catalog.products.where((product) => product.umkmId == umkm.id).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _addToCart(Product product) {
    _cartService.addProduct(product);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text('${product.name} ditambahkan ke keranjang'),
        backgroundColor: primaryGreen,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Lihat',
          textColor: Colors.white,
          onPressed: () {
            if (!navigator.mounted) return;
            navigator.push(
              MaterialPageRoute(builder: (_) => const CartScreen()),
            );
          },
        ),
      ),
    );
  }

  List<Product> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    final list = _storeProducts.where((p) {
      final typeMatch =
          _orderTypeFilter == 'Semua' || p.orderType == _orderTypeFilter;
      final searchMatch = q.isEmpty ||
          p.name.toLowerCase().contains(q) ||
          p.variant.toLowerCase().contains(q);
      return typeMatch && searchMatch;
    }).toList();
    final highlightedId = widget.highlightedProductId;
    if (highlightedId != null && highlightedId.isNotEmpty) {
      final idx = list.indexWhere((p) => p.id == highlightedId);
      if (idx > 0) {
        final chosen = list.removeAt(idx);
        list.insert(0, chosen);
      }
    }
    return list;
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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsRow(products.length),
                  if (umkm.description.trim().isNotEmpty) ...[
                    const SizedBox(height: 26),
                    _buildStoreProfile(),
                  ],
                  const SizedBox(height: 24),
                  _buildServiceCard(),
                  const SizedBox(height: 26),

                  _buildStoreSearch(),
                  const SizedBox(height: 18),

                  if (hasPreOrder && hasInstant) ...[
                    _buildOrderTypeFilter(),
                    const SizedBox(height: 20),
                  ],

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Jelajahi menu',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                color: textDark,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${_filtered.length} produk dari ${umkm.name}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${_filtered.length} item',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: primaryGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildProductGrid(),
                  const SizedBox(height: 30),
                  _buildReviewsSection(),
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
      expandedHeight: 270,
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
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            shape: BoxShape.circle,
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
          ),
          child: FavoriteButton(
            umkmId: umkm.id,
            size: 20,
            buttonSize: 40,
            backgroundColor: Colors.transparent,
            inactiveColor: textDark,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            shape: BoxShape.circle,
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
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
        const SizedBox(width: 8),
        AnimatedBuilder(
          animation: _cartService,
          builder: (context, _) {
            final count = _cartService.totalQuantity;
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                shape: BoxShape.circle,
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
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
                          color: primaryGreen,
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
            AppNetworkImage(
              url: umkm.imageUrl,
              fit: BoxFit.cover,
              errorWidget: _headerFallback(),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.12),
                      Colors.black.withValues(alpha: 0.12),
                      const Color(0xFF07190D).withValues(alpha: 0.86),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 22,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.hijauLembut,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 16,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        umkm.initials,
                        style: const TextStyle(
                          color: primaryGreen,
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
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
                                  fontSize: 21,
                                  height: 1.1,
                                  letterSpacing: -0.45,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            if (umkm.isVerified) ...[
                              const SizedBox(width: 5),
                              const Icon(
                                Icons.verified,
                                color: Color(0xFF62E69A),
                                size: 19,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 7),
                        Wrap(
                          spacing: 7,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              umkm.type,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (umkm.isVerified)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.24),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.verified_rounded,
                                      color: Color(0xFF62E69A),
                                      size: 12,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Terverifikasi',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(
                              Icons.place_outlined,
                              color: Colors.white.withValues(alpha: 0.8),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                umkm.pickupLocation,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 11.5,
                                ),
                              ),
                            ),
                          ],
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
      color: const Color(0xFF047857),
      child: const Icon(Icons.storefront, size: 90, color: Colors.white24),
    );
  }

  // ---------------------------------------------------------------- Stats
  Widget _buildStatsRow(int productCount) {
    final displayRating = _avgRating > 0
        ? _avgRating.toStringAsFixed(1)
        : (umkm.rating > 0 ? umkm.rating.toStringAsFixed(1) : 'Baru');

    return Container(
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.symmetric(vertical: 17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0B17251B),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          _statItem(
            displayRating,
            _totalReviews > 0 ? 'Dari $_totalReviews ulasan' : 'Penilaian',
            Icons.star_rounded,
            const Color(0xFF5B9E68),
          ),
          _divider(),
          _statItem(
            '$productCount',
            'Pilihan menu',
            Icons.grid_view_rounded,
            primaryGreen,
          ),
          _divider(),
          _statItem(
            '${umkm.soldCount}',
            'Pesanan selesai',
            Icons.shopping_bag_outlined,
            const Color(0xFF3977D5),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 19, color: color),
          const SizedBox(height: 7),
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: const TextStyle(fontSize: 10.5, color: textMuted),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 38,
        color: const Color(0xFFEAF3EC),
      );

  Widget _buildStoreProfile() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 3,
              decoration: BoxDecoration(
                color: const Color(0xFF5B9E68),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'CERITA DI BALIK USAHA',
              style: TextStyle(
                color: primaryGreen,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          umkm.description,
          style: const TextStyle(
            color: Color(0xFF48544C),
            fontSize: 14,
            height: 1.55,
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------- Layanan
  Widget _buildServiceCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 13),
      decoration: BoxDecoration(
        color: AppColors.hijauLembut,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: primaryGreen,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lokasi usaha',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      umkm.pickupLocation,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                        color: textDark,
                      ),
                    ),
                  ],
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
                backgroundColor: Colors.white,
                side: BorderSide.none,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
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
              fontSize: 10.5,
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0917251B),
            blurRadius: 16,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Cari menu di ${umkm.name}',
          hintStyle: const TextStyle(color: Color(0xFF89938C), fontSize: 13),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 21,
            color: primaryGreen,
          ),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                ),
          filled: true,
          fillColor: Colors.transparent,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: primaryGreen, width: 1.2),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  // ------------------------------------------------------------- Filter PO
  Widget _buildOrderTypeFilter() {
    const types = ['Semua', 'Pesan Sekarang', 'Pre-Order'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.hijauLembut,
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
                      color: textMuted,
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
        mainAxisExtent: 268,
      ),
      itemBuilder: (context, index) {
        final product = items[index];
        final isHighlighted = widget.highlightedProductId != null &&
            product.id == widget.highlightedProductId;
        final card = ProductCard(
          product: product,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(product: product),
            ),
          ),
          onAddToCart: () => _addToCart(product),
        );
        if (!isHighlighted) return card;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: primaryGreen, width: 2),
          ),
          child: card,
        );
      },
    );
  }

  // ---------------------------------------------------------------- Ulasan
  Widget _buildReviewsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE8DE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star_rounded, color: Color(0xFF5B9E68), size: 24),
              const SizedBox(width: 8),
              const Text(
                'Ulasan Produk',
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
              const Spacer(),
              if (_avgRating > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF3EC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFDCE8DE)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 4),
                      Text(
                        '${_avgRating.toStringAsFixed(1)} ($_totalReviews)',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF047857),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (_loadingReviews)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: CircularProgressIndicator(strokeWidth: 2, color: primaryGreen),
              ),
            )
          else if (_reviews.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F7F3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                children: [
                  Icon(Icons.rate_review_outlined, size: 36, color: Color(0xFF94A3B8)),
                  SizedBox(height: 8),
                  Text(
                    'Belum Ada Ulasan',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                      color: textDark,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Belum ada produk yang mendapatkan ulasan dari pelanggan.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: textMuted),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _reviews.length,
              separatorBuilder: (_, _) =>
                  const Divider(color: AppColors.garis, height: 20),
              itemBuilder: (context, i) {
                final r = _reviews[i];
                final rating = (r['rating'] as num?)?.toInt() ?? 5;
                final nama = (r['nama_pelanggan'] ?? 'Warga DJajan').toString();
                final komentar = (r['komentar'] ?? '').toString();
                final tanggal = (r['tanggal'] ?? '').toString();
                final namaProduk = (r['nama_produk'] ?? 'Produk').toString();
                final gambarProduk = (r['gambar_url'] ?? '').toString();
                final idPesanan = (r['id_pesanan'] ?? '').toString();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AppNetworkImage(
                          url: gambarProduk,
                          width: 42,
                          height: 42,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                namaProduk,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: textDark,
                                ),
                              ),
                              if (idPesanan.isNotEmpty)
                                Text(
                                  'Pesanan $idPesanan',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    color: textMuted,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: AppColors.garis,
                          child: Text(
                            nama.isNotEmpty ? nama[0].toUpperCase() : 'W',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nama,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: textDark,
                                ),
                              ),
                              if (tanggal.isNotEmpty)
                                Text(
                                  tanggal,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    color: textMuted,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Row(
                          children: List.generate(
                            5,
                            (starIndex) => Icon(
                              starIndex < rating
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: 16,
                              color: AppColors.kuning,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (komentar.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F7F3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          komentar,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: textDark,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  String _rupiah(int value) => value.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      );
}
