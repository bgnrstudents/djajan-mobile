import 'package:flutter/material.dart';

import '../../../../widgets/app_bottom_navigation.dart';
import '../../../../widgets/product_card.dart';
import '../../../../models/product.dart';

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

  final List<Product> products = [
    Product(
      name: 'Nasi Kotak Ayam Geprek',
      umkm: 'Bu Minten',
      price: 15000,
      rating: 4.8,
      category: 'Makanan',
      orderType: 'Pre-Order',
    ),
    Product(
      name: 'Es Teh Solo Original',
      umkm: 'Toko Pak Budi',
      price: 5000,
      rating: 4.9,
      category: 'Minuman',
      orderType: 'Pesan Sekarang',
    ),
    Product(
      name: 'Brownies Lumer',
      umkm: 'Dapur Mba Rina',
      price: 25000,
      rating: 4.7,
      category: 'Jajanan',
      orderType: 'Pre-Order',
    ),
    Product(
      name: 'Gorengan Hangat Combo',
      umkm: 'Warung Bu Siti',
      price: 10000,
      rating: 4.8,
      category: 'Jajanan',
      orderType: 'Pesan Sekarang',
    ),
  ];

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
        return const Center(child: Text('Halaman Pesanan'));

      case 2:
        return const Center(child: Text('Halaman Keranjang'));

      case 3:
        return const Center(child: Text('Halaman Profil'));

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

          // const SizedBox(height: 20),
          _buildCategorySection(),

          const SizedBox(height: 20),

          _buildProductSection(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
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
          ),

          IconButton(
            onPressed: () {},
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none, size: 27),

                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
        decoration: InputDecoration(
          hintText: 'Cari makanan, jajanan, atau UMKM...',
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
          prefixIcon: const Icon(Icons.search, size: 22),
          suffixIcon: IconButton(
            onPressed: () {},
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

              TextButton(onPressed: () {}, child: const Text('Lihat Semua')),
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
                mainAxisExtent: 220,
              ),
              itemBuilder: (context, index) {
                final product = filteredProducts[index];

                return ProductCard(
                  product: product,
                  onAddToCart: () {
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
