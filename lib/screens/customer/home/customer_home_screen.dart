import 'package:flutter/material.dart';

import '../../../../widgets/app_bottom_navigation.dart';
import '../profile/cart.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: currentIndex == 2
          ? null
          : AppBar(
              title: Text(_getAppBarTitle()),
              actions: [
                if (currentIndex == 0)
                  IconButton(
                    icon: const Badge(
                      label: Text('2'),
                      backgroundColor: Color(0xFF006B45),
                      child: Icon(Icons.shopping_cart_outlined),
                    ),
                    tooltip: 'Keranjang',
                    onPressed: () {
                      setState(() {
                        currentIndex = 2;
                      });
                    },
                  ),
                const SizedBox(width: 8),
              ],
            ),

      body: _buildCurrentPage(),

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

  String _getAppBarTitle() {
    switch (currentIndex) {
      case 0:
        return 'Djajan';
      case 1:
        return 'Pesanan';
      case 2:
        return 'Keranjang';
      case 3:
        return 'Profil';
      default:
        return 'Djajan';
    }
  }

  Widget _buildCurrentPage() {
    switch (currentIndex) {
      case 0:
        return _buildHomePage();

      case 1:
        return _buildPesananPage();

      case 2:
        return _buildKeranjangPage();

      case 3:
        return _buildProfilPage();

      default:
        return _buildHomePage();
    }
  }

  Widget _buildHomePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mau jajan apa hari ini?',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 16),

          // Search
          TextField(
            decoration: InputDecoration(
              hintText: 'Cari produk atau UMKM...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Kategori
          const Text(
            'Kategori',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          SizedBox(
            height: 105,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildCategoryItem(icon: Icons.restaurant, label: 'Makanan'),
                _buildCategoryItem(icon: Icons.local_drink, label: 'Minuman'),
                _buildCategoryItem(icon: Icons.cake, label: 'Jajanan'),
                _buildCategoryItem(icon: Icons.more_horiz, label: 'Lainnya'),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // UMKM
          const Text(
            'UMKM Pilihan',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          _buildUmkmCard(
            name: 'Contoh UMKM',
            description: 'Makanan dan jajanan lokal',
          ),

          const SizedBox(height: 12),

          _buildUmkmCard(
            name: 'Warung Desa',
            description: 'Aneka makanan rumahan',
          ),

          const SizedBox(height: 24),

          // Produk
          const Text(
            'Produk',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildProductCard(name: 'Produk 1', price: 'Rp10.000'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildProductCard(name: 'Produk 2', price: 'Rp15.000'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem({required IconData icon, required String label}) {
    return Container(
      width: 90,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).colorScheme.primary
                  .withValues(alpha: 0.1),
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary),
          ),

          const SizedBox(height: 6),

          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildUmkmCard({required String name, required String description}) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.store)),
        title: Text(name),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios),
      ),
    );
  }

  Widget _buildProductCard({required String name, required String price}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade200,
              ),
              child: const Icon(Icons.image, size: 40),
            ),

            const SizedBox(height: 8),

            Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),

            const SizedBox(height: 4),

            Text(price),
          ],
        ),
      ),
    );
  }

  Widget _buildPesananPage() {
    return const Center(
      child: Text(
        'Halaman Pesanan',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildKeranjangPage() {
    return CartScreen(
      showAppBar: true,
      onBack: () {
        setState(() {
          currentIndex = 0;
        });
      },
    );
  }

  Widget _buildProfilPage() {
    return const Center(
      child: Text(
        'Halaman Profil',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }
}
