import 'package:flutter/material.dart';

import '../../../config/app_config.dart';
import '../../../data/sample_catalog.dart';
import '../../../models/product.dart';
import '../../../models/umkm.dart';
import '../../../widgets/product_card.dart';
import '../../../widgets/umkm_card.dart';
import '../cart/cart.dart';
import '../../../services/cart_service.dart';
import '../product/product_detail_screen.dart';
import '../umkm/umkm_storefront_screen.dart';

/// Halaman katalog: pencarian semua produk + filter kategori & tipe pesanan.
class CatalogListScreen extends StatefulWidget {
  /// Kategori awal yang dipilih saat halaman dibuka.
  final String initialCategory;

  /// Kata kunci awal (opsional) saat halaman dibuka.
  final String initialQuery;

  const CatalogListScreen({
    super.key,
    this.initialCategory = 'Semua',
    this.initialQuery = '',
  });

  @override
  State<CatalogListScreen> createState() => _CatalogListScreenState();
}

class _CatalogListScreenState extends State<CatalogListScreen> {
  static const Color primaryGreen = AppConfig.primaryColor;
  static const Color textDark = Color(0xFF1E293B);
  static const Color textMuted = Color(0xFF64748B);
  static const Color background = Color(0xFFF8F9FD);

  final CartService _cartService = CartService();
  final TextEditingController _searchController = TextEditingController();

  late String _category;
  String _orderType = 'Semua';

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
    _searchController.text = widget.initialQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Product> get _results => SampleCatalog.search(
        _searchController.text,
        category: _category,
        orderType: _orderType,
      );

  List<Umkm> get _umkmResults {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return SampleCatalog.umkms.where((u) {
      return u.name.toLowerCase().contains(q) ||
          u.type.toLowerCase().contains(q);
    }).toList();
  }

  void _openStorefront(Umkm umkm) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => UmkmStorefrontScreen(umkm: umkm)),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Cari Produk & UMKM',
          style: TextStyle(
            color: textDark,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          _buildSearchField(),
          const SizedBox(height: 14),
          _buildCategoryChips(),
          const SizedBox(height: 12),
          _buildOrderTypeFilter(),
          const SizedBox(height: 18),

          // Hasil UMKM (hanya saat mengetik)
          if (_umkmResults.isNotEmpty) ...[
            _sectionTitle('UMKM Ditemukan', _umkmResults.length),
            const SizedBox(height: 10),
            SizedBox(
              height: 196,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _umkmResults.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final umkm = _umkmResults[i];
                  return UmkmCard(
                    umkm: umkm,
                    productCount: SampleCatalog.productsOf(umkm.id).length,
                    onTap: () => _openStorefront(umkm),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],

          _sectionTitle('Produk', _results.length),
          const SizedBox(height: 10),
          _buildProductGrid(),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: textDark,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF3EC),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: primaryGreen,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      autofocus: true,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: 'Cari makanan, jajanan, atau UMKM...',
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 13.5),
        prefixIcon: const Icon(Icons.search, size: 22),
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

  Widget _buildCategoryChips() {
    final categories = SampleCatalog.categories;
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final name = categories[i];
          final selected = _category == name;
          return GestureDetector(
            onTap: () => setState(() => _category = name),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? primaryGreen : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: selected ? primaryGreen : const Color(0xFFDDE3E8),
                ),
              ),
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : const Color(0xFF20252B),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

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
          final selected = _orderType == type;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _orderType = type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: selected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    type,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.normal,
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

  Widget _buildProductGrid() {
    final items = _results;

    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            const Icon(Icons.search_off_rounded, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              'Tidak ada produk',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Coba ubah kata pencarian atau filter.',
              style: TextStyle(fontSize: 13, color: textMuted),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => setState(() {
                _searchController.clear();
                _category = 'Semua';
                _orderType = 'Semua';
              }),
              child: const Text('Reset Filter'),
            ),
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
        final umkm = SampleCatalog.umkmById(product.umkmId);
        return ProductCard(
          product: product,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(product: product),
            ),
          ),
          onAddToCart: () => _addToCart(product),
          onUmkmTap: umkm == null ? null : () => _openStorefront(umkm),
        );
      },
    );
  }
}
