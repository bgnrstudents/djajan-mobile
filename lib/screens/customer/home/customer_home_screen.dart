import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../routes/app_routes.dart';
import '../../../services/auth_service.dart';
import '../../../data/sample_catalog.dart';
import '../../../services/catalog_service.dart';
import '../../../models/product.dart';
import '../../../models/umkm.dart';
import '../../../models/customer_settings_models.dart';
import '../../../widgets/app_bottom_navigation.dart';
import '../../../widgets/floating_cart_button.dart';
import '../../../widgets/product_card.dart';
import '../../../widgets/umkm_card.dart';
import '../catalog/catalog_list_screen.dart';
import '../cart/cart.dart';
import '../notification/notification_screen.dart';
import '../../../services/notification_service.dart';
import '../order/order_list_screen.dart';
import '../order/order_widgets.dart';
import '../profile/profil.dart';
import '../../../services/cart_service.dart';
import '../../../services/customer_settings_service.dart';
import '../order/address_picker_sheet.dart';
import '../product/product_detail_screen.dart';
import '../umkm/umkm_storefront_screen.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/umkm_app_bar.dart';
import '../../auth/auth_widgets.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  int currentIndex = 0;
  String selectedCategory = 'Semua';
  String selectedOrderType = 'Semua';
  ProductSortOrder _sortOrder = ProductSortOrder.newest;
  final TextEditingController searchController = TextEditingController();

  CatalogService? _catalog;

  CustomerAddress? _activeAddress;
  String _locationLabel = 'Pilih alamat';

  List<Product> get products =>
      _catalog == null ? SampleCatalog.products : _catalog!.products;

  List<Umkm> get umkms =>
      _catalog == null ? SampleCatalog.umkms : _catalog!.umkms;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadLocation();
      }
    });
  }

  Future<void> _loadLocation({CustomerAddress? selected}) async {
    final settings = CustomerSettingsService();
    await settings.load();
    if (!mounted) return;
    final address =
        selected ??
        settings.primaryAddress ??
        (settings.addresses.isNotEmpty ? settings.addresses.first : null);
    setState(() {
      _activeAddress = address;
      _locationLabel = address == null
          ? 'Pilih alamat'
          : address.address.isNotEmpty
          ? address.address
          : address.label;
    });
  }

  void _openStorefront(Umkm umkm) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => UmkmStorefrontScreen(umkm: umkm)));
  }

  void _openCatalog({String category = 'Semua', String query = ''}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CatalogListScreen(
          initialCategory: category,
          initialQuery: query,
          initialSort: _sortOrder,
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
    _catalog = Provider.of<CatalogService?>(context);
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: currentIndex,
          children: [
            _buildHomePage(),
            const OrderListScreen(),
            CartScreen(
              onExploreProducts: () {
                setState(() {
                  currentIndex = 0;
                });
              },
            ),
            const ProfilScreen(),
          ],
        ),
      ),
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

  Widget _buildHomePage() {
    final cartService = CartService();
    return RefreshIndicator(
      onRefresh: () async {
        await _catalog?.load();
      },
      color: AppColors.hijauTua,
      child: AnimatedBuilder(
        animation: cartService,
        builder: (context, _) => Stack(
          fit: StackFit.expand,
          children: [
            const Positioned.fill(child: ColoredBox(color: AppColors.latar)),
            const HeaderBotanicalBackdrop(height: 250),
            SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(
                bottom: cartService.isNotEmpty ? 108 : 28,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  _buildSearchBar(),
                  const SizedBox(height: 12),
                  _buildHeroBanner(),
                  const SizedBox(height: 16),
                  _buildCategorySection(),
                  const SizedBox(height: 18),
                  _buildUmkmSection(),
                  const SizedBox(height: 18),
                  _buildProductSection(),
                ],
              ),
            ),
            Positioned(
              right: 18,
              bottom: 12,
              child: FloatingCartButton(
                onPressed: () => setState(() => currentIndex = 2),
              ),
            ),
          ],
        ),
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
          child: _buildSectionHeader(
            title: 'UMKM di Desa',
            subtitle: 'Warung & dapur warga sekitar Anda',
            icon: Icons.storefront_rounded,
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.hijauLembut,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${umkms.length} Toko',
                style: const TextStyle(
                  color: AppColors.hijauTua,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 9),
        SizedBox(
          height: 256,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(18, 3, 18, 3),
            scrollDirection: Axis.horizontal,
            itemCount: umkms.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final umkm = umkms[index];
              return UmkmCard(
                umkm: umkm,
                productCount: _catalog == null
                    ? SampleCatalog.productsOf(umkm.id).length
                    : _catalog!.productsOf(umkm.id).length,
                featured: true,
                onTap: () => _openStorefront(umkm),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
    Widget? trailing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.hijauLembut,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 17, color: AppColors.hijauTua),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.35,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 18,
                    height: 2,
                    decoration: BoxDecoration(
                      color: AppColors.hijauMuda,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textGrey,
                        fontSize: 11.5,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          trailing,
        ],
      ],
    );
  }

  Widget _buildHeader() {
    final auth = context.watch<AuthService>();
    return DjajanPageHeader(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
      leftWidget: GestureDetector(
        onTap: auth.isLoggedIn
            ? () async {
                final selected = await showAddressPickerSheet(
                  context,
                  currentAddressId: _activeAddress?.id,
                );
                if (mounted && selected != null) {
                  await _loadLocation(selected: selected);
                }
              }
            : null,
        behavior: HitTestBehavior.opaque,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.hijauLembut,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.location_on_rounded,
                size: 20,
                color: AppColors.hijauTua,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'KIRIM KE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppColors.textGrey,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          _locationLabel,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      if (auth.isLoggedIn)
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 19,
                          color: AppColors.hijauTua,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      rightAction: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (!auth.isLoggedIn) ...[
            Container(
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.hijauTua,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.hijauTua.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.pushNamed(context, AppRoutes.login),
                  borderRadius: BorderRadius.circular(14),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 13),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.login_rounded,
                          size: 17,
                          color: Colors.white,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Masuk',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
          AnimatedBuilder(
            animation: NotificationService(),
            builder: (context, _) {
              final unread = NotificationService().unreadCount;
              return IconButton(
                tooltip: 'Notifikasi',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NotificationScreen()),
                ),
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.putih,
                        borderRadius: BorderRadius.circular(14),
                        border: const Border.fromBorderSide(
                          BorderSide(color: AppColors.garis),
                        ),
                      ),
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        size: 22,
                        color: AppColors.hijauTua,
                      ),
                    ),
                    if (unread > 0)
                      Positioned(
                        right: -1,
                        top: -1,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          constraints: const BoxConstraints(minWidth: 16),
                          decoration: BoxDecoration(
                            color: AppColors.hijauTua,
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
        onSubmitted: (value) => _openCatalog(query: value.trim()),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Cari makanan, jajanan, atau UMKM...',
          hintStyle: const TextStyle(color: AppColors.textGrey, fontSize: 13.5),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 22,
            color: AppColors.hijauTua,
          ),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (searchController.text.isNotEmpty)
                IconButton(
                  tooltip: 'Hapus pencarian',
                  onPressed: () {
                    setState(() {
                      searchController.clear();
                    });
                  },
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 19,
                    color: AppColors.textGrey,
                  ),
                ),
              PopupMenuButton<ProductSortOrder>(
                tooltip: 'Urutkan hasil',
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      size: 21,
                      color: _sortOrder == ProductSortOrder.newest
                          ? AppColors.textGrey
                          : AppColors.hijauTua,
                    ),
                    if (_sortOrder != ProductSortOrder.newest)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppColors.hijauTua,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                onSelected: (order) => setState(() => _sortOrder = order),
                itemBuilder: (context) => ProductSortOrder.values
                    .map(
                      (order) => PopupMenuItem<ProductSortOrder>(
                        value: order,
                        child: Row(
                          children: [
                            Icon(
                              _sortOrder == order
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              size: 18,
                              color: _sortOrder == order
                                  ? AppColors.hijauTua
                                  : AppColors.textGrey,
                            ),
                            const SizedBox(width: 10),
                            Text(productSortLabel(order)),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
          filled: true,
          fillColor: AppColors.putih,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.garis),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.garis),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.hijauTua, width: 1.4),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Container(
            key: const ValueKey('customer-home-hero'),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Color(0xFFF3FAF5),
                  Color(0xFFEAF3EC),
                ],
                stops: [0.0, 0.58, 1.0],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFDCE8DE)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F2E1B).withValues(alpha: 0.05),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 330;
                final storeWidth = compact ? 92.0 : 124.0;
                final storeHeight = compact ? 88.0 : 116.0;

                return Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(painter: _HomeHeroBackdropPainter()),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        compact ? 14 : 18,
                        compact ? 15 : 18,
                        compact ? 10 : 14,
                        compact ? 14 : 16,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE2EFE5),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6.5,
                                        height: 6.5,
                                        decoration: const BoxDecoration(
                                          color: AppColors.hijauTua,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          '${umkms.length} Warung Sekitar Aktif',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: AppColors.hijauTua,
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Jajanan Desa,\nLangsung ke Rumah.',
                                  style: TextStyle(
                                    color: AppColors.textDark,
                                    fontSize: compact ? 17.5 : 20,
                                    fontWeight: FontWeight.w800,
                                    height: 1.15,
                                    letterSpacing: -0.45,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Pesan menu siap santap atau pre-order dari UMKM terdekat.',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: AppColors.textGrey,
                                    fontSize: compact ? 11 : 11.5,
                                    height: 1.38,
                                  ),
                                ),
                                const SizedBox(height: 13),
                                Material(
                                  color: AppColors.hijauTua,
                                  borderRadius: BorderRadius.circular(24),
                                  child: InkWell(
                                    onTap: () => _openCatalog(
                                      category: selectedCategory,
                                      query: searchController.text.trim(),
                                    ),
                                    borderRadius: BorderRadius.circular(24),
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: compact ? 12 : 14,
                                        vertical: 9,
                                      ),
                                      child: const FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'Jelajahi Menu',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            SizedBox(width: 6),
                                            Icon(
                                              Icons.arrow_forward_rounded,
                                              color: Colors.white,
                                              size: 15,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          SizedBox(
                            width: storeWidth,
                            height: storeHeight,
                            child: CustomPaint(
                              painter: StorefrontIllustrationPainter(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    final categories = _catalog?.categories ?? SampleCatalog.categories;
    IconData iconFor(String name) {
      switch (name.toLowerCase()) {
        case 'semua':
          return Icons.grid_view_rounded;
        case 'minuman':
          return Icons.local_drink;
        case 'jajanan':
        case 'camilan':
          return Icons.bakery_dining;
        case 'kue':
          return Icons.cake_rounded;
        case 'makanan':
          return Icons.restaurant;
        default:
          return Icons.category_rounded;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: _buildSectionHeader(
            title: 'Kategori',
            subtitle: 'Jelajahi menu favorit Anda',
            icon: Icons.grid_view_rounded,
          ),
        ),

        const SizedBox(height: 10),

        SizedBox(
          height: 40,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (context, index) {
              return const SizedBox(width: 8);
            },
            itemBuilder: (context, index) {
              final category = categories[index];
              final name = category;
              final icon = iconFor(name);

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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 13),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? primaryColor : AppColors.garis,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : primaryColor,
            ),

            const SizedBox(width: 6),

            Text(
              name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductSection() {
    final String searchQuery = searchController.text.trim().toLowerCase();

    final filteredProducts = sortProducts(
      products.where((product) {
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
      }),
      _sortOrder,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: _buildSectionHeader(
            title: 'Jajanan Paling Menggoda',
            subtitle: 'Bahan segar, diolah langsung saat ada pesanan',
            icon: Icons.local_fire_department_rounded,
            trailing: TextButton(
              onPressed: () => _openCatalog(
                category: selectedCategory,
                query: searchController.text.trim(),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.hijauTua,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Lihat Semua',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(width: 2),
                  Icon(Icons.chevron_right_rounded, size: 17),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        _buildOrderTypeFilter(),

        const SizedBox(height: 12),

        if (filteredProducts.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 30),
            child: Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.search_off_rounded,
                    size: 48,
                    color: AppColors.textGrey,
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
                    style: TextStyle(fontSize: 13, color: AppColors.textGrey),
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
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 900
                        ? 4
                        : constraints.maxWidth >= 620
                        ? 3
                        : 2;
                    final cardWidth =
                        (constraints.maxWidth - 14 * (columns - 1)) / columns;

                    return Wrap(
                      spacing: 14,
                      runSpacing: 12,
                      children: filteredProducts.map((product) {
                        final umkm = _catalog == null
                            ? SampleCatalog.umkmById(product.umkmId)
                            : _catalog!.umkmById(product.umkmId);

                        return SizedBox(
                          width: cardWidth,
                          child: ProductCard(
                            product: product,
                            featured: true,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ProductDetailScreen(product: product),
                                ),
                              );
                            },
                            onUmkmTap: umkm == null
                                ? null
                                : () => _openStorefront(umkm),
                            onAddToCart: () {
                              CartService().addProduct(product);
                            },
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
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
        color: AppColors.hijauLembut,
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
                  boxShadow: isSelected
                      ? const [
                          BoxShadow(
                            color: Color(0x0D17251B),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ]
                      : null,
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
                              ? AppColors.hijauMuda
                              : AppColors.hijauTua,
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
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? AppColors.hijauTua
                              : AppColors.textGrey,
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

class _HomeHeroBackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final arcPaint = Paint()
      ..color = const Color(0xFFD6EAD9).withValues(alpha: 0.55);
    final arcPath = Path()
      ..moveTo(size.width * 0.56, size.height)
      ..quadraticBezierTo(
        size.width * 0.66,
        size.height * 0.25,
        size.width,
        0,
      )
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(arcPath, arcPaint);

    final innerArc = Paint()
      ..color = const Color(0xFF175D2B).withValues(alpha: 0.06);
    canvas.drawCircle(
      Offset(size.width * 0.92, size.height * 0.96),
      size.height * 0.42,
      innerArc,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
