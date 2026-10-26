import 'package:flutter/material.dart';

import '../../../data/sample_catalog.dart';
import '../../../models/product.dart';
import '../../../models/umkm.dart';
import '../../../widgets/app_bottom_navigation.dart';
import '../../../widgets/product_card.dart';
import '../../../widgets/umkm_card.dart';
import '../catalog/catalog_list_screen.dart';
import '../notification/notification_screen.dart';
import '../../../services/notification_service.dart';
import '../order/order_list_screen.dart';
import '../order/order_widgets.dart';
import '../profile/profil.dart';
import '../cart/cart.dart';
import '../../../services/cart_service.dart';
import '../product/product_detail_screen.dart';
import '../umkm/umkm_storefront_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  int currentIndex = 0;
  String selectedCategory = 'Semua';
  String selectedOrderType = 'Semua';
  final TextEditingController searchController = TextEditingController();

  // Sumber data katalog bersama (beranda, katalog, storefront).
  final List<Product> products = SampleCatalog.products;
  final List<Umkm> umkms = SampleCatalog.umkms;

  void _openStorefront(Umkm umkm) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => UmkmStorefrontScreen(umkm: umkm)),
    );
  }

  void _openCatalog({String category = 'Semua', String query = ''}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CatalogListScreen(
          initialCategory: category,
          initialQuery: query,
        ),
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _buildCurrentPage()),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            currentIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildCurrentPage() {
    switch (currentIndex) {
      case 0:
        return _buildHomePage();

      case 1:
        return const OrderListScreen();

      case 2:
        return CartScreen(
          onExploreProducts: () {
            setState(() {
              currentIndex = 0;
            });
          },
        );

      case 3:
        return const ProfilScreen();

      default:
        return _buildHomePage();
    }
  }

  Widget _buildHomePage() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildSearchBar(),

          const SizedBox(height: 20),

          _buildHeroBanner(),

          _buildCategorySection(),

          const SizedBox(height: 22),

          _buildUmkmSection(),

          const SizedBox(height: 22),

          _buildProductSection(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ---------------------------------------------------------- UMKM Section
  Widget _buildUmkmSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'UMKM di Desa',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Warung & dapur warga sekitar Anda',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => _openCatalog(),
                child: const Text('Lihat Semua'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 196,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            scrollDirection: Axis.horizontal,
            itemCount: umkms.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final umkm = umkms[index];
              return UmkmCard(
                umkm: umkm,
                productCount: SampleCatalog.productsOf(umkm.id).length,
                onTap: () => _openStorefront(umkm),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return DjajanPageHeader(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
      leftWidget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lokasi Anda',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 4),
              const Flexible(
                child: Text(
                  'Desa Kreyongan Atas',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.keyboard_arrow_down,
                size: 18,
                color: Colors.grey,
              ),
            ],
          ),
        ],
      ),
      rightAction: AnimatedBuilder(
        animation: NotificationService(),
        builder: (context, _) {
          final unread = NotificationService().unreadCount;
          return IconButton(
            tooltip: 'Notifikasi',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const NotificationScreen(),
              ),
            ),
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none, size: 27),
                if (unread > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      constraints: const BoxConstraints(minWidth: 16),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: Colors.white, width: 1.2),
                      ),
                      child: Text(
                        unread > 9 ? '9+' : '$unread',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: TextField(
        controller: searchController,
        onChanged: (value) {
          setState(() {});
        },
        onSubmitted: (value) => _openCatalog(query: value.trim()),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Cari makanan, jajanan, atau UMKM...',
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
          prefixIcon: const Icon(Icons.search, size: 22),
          suffixIcon: IconButton(
            tooltip: 'Cari & filter lanjutan',
            onPressed: () => _openCatalog(query: searchController.text.trim()),
            icon: const Icon(Icons.tune, size: 21),
          ),
          filled: true,
          fillColor: const Color(0xFFF3F6F8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        width: double.infinity,
        height: 170,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: const Color(0xFF175D2B),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(
                Icons.restaurant,
                size: 150,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFBE25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'DARI DESA, UNTUK SEMUA',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF175D2B),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Dukung UMKM Kreyongan Atas',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    'Nikmati aneka jajanan & kuliner rumahan '
                    'khas dapur tetangga Anda.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: Colors.white,
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

  Widget _buildCategorySection() {
    final categories = [
      {'name': 'Semua', 'icon': Icons.grid_view_rounded},
      {'name': 'Makanan', 'icon': Icons.restaurant},
      {'name': 'Minuman', 'icon': Icons.local_drink},
      {'name': 'Jajanan', 'icon': Icons.bakery_dining},
      {'name': 'Lainnya', 'icon': Icons.more_horiz},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Kategori',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              TextButton(
                onPressed: () => _openCatalog(category: selectedCategory),
                child: const Text('Lihat Semua'),
              ),
            ],
          ),
        ),

        const SizedBox(height: 4),

        SizedBox(
          height: 42,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (context, index) {
              return const SizedBox(width: 8);
            },
            itemBuilder: (context, index) {
              final category = categories[index];

              final String name = category['name'] as String;
              final IconData icon = category['icon'] as IconData;

              final bool isSelected = selectedCategory == name;

              return _buildCategoryChip(
                name: name,
                icon: icon,
                isSelected: isSelected,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip({
    required String name,
    required IconData icon,
    required bool isSelected,
  }) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = name;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? primaryColor : const Color(0xFFDDE3E8),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 17,
              color: isSelected ? Colors.white : primaryColor,
            ),

            const SizedBox(width: 7),

            Text(
              name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF20252B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductSection() {
    final String searchQuery = searchController.text.trim().toLowerCase();

    final filteredProducts = products.where((product) {
      final bool categoryMatch =
          selectedCategory == 'Semua' || product.category == selectedCategory;

      final bool orderTypeMatch =
          selectedOrderType == 'Semua' ||
          product.orderType == selectedOrderType;

      final bool searchMatch =
          searchQuery.isEmpty ||
          product.name.toString().toLowerCase().contains(searchQuery) ||
          product.umkm.toString().toLowerCase().contains(searchQuery);

      return categoryMatch && orderTypeMatch && searchMatch;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Rekomendasi UMKM Terdekat',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 4),

              const Text(
                'Langsung matang & diantar warga sekitar',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        _buildOrderTypeFilter(),

        const SizedBox(height: 14),

        if (filteredProducts.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 30),
            child: Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.search_off_rounded,
                    size: 48,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Produk tidak ditemukan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Coba ubah kata pencarian atau filter yang dipilih.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        searchController.clear();
                        selectedCategory = 'Semua';
                        selectedOrderType = 'Semua';
                      });
                    },
                    child: const Text('Reset Filter'),
                  ),
                ],
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredProducts.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 235,
              ),
              itemBuilder: (context, index) {
                final product = filteredProducts[index];
                final umkm = SampleCatalog.umkmById(product.umkmId);

                return ProductCard(
                  product: product,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ProductDetailScreen(product: product),
                      ),
                    );
                  },
                  onUmkmTap: umkm == null ? null : () => _openStorefront(umkm),
                  onAddToCart: () {
                    CartService().addProduct(product);
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${product.name} ditambahkan ke keranjang',
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildOrderTypeFilter() {
    final orderTypes = ['Semua', 'Pesan Sekarang', 'Pre-Order'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE9EEF2),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: orderTypes.map((type) {
          final bool isSelected = selectedOrderType == type;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {   
                  selectedOrderType = type;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (type != 'Semua')
                      Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.only(right: 5),
                        decoration: BoxDecoration(
                          color: type == 'Pre-Order'
                              ? const Color(0xFFC56500)
                              : const Color(0xFF16834A),
                          shape: BoxShape.circle,
                        ),
                      ),

                    Flexible(
                      child: Text(
                        type,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: const Color(0xFF59636E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
