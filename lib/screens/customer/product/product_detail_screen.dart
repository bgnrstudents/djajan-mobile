import 'package:flutter/material.dart';

import '../../../config/app_config.dart';
import '../../../data/sample_catalog.dart';
import '../../../models/product.dart';
import '../../../widgets/favorite_button.dart';
import '../../../widgets/app_network_image.dart';
import '../cart/cart.dart';
import '../../../services/cart_service.dart';
import '../../../theme/app_theme.dart';
import '../order/order_widgets.dart';
import '../umkm/umkm_storefront_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final CartService _cartService = CartService();
  int _quantity = 1;

  static const Color primaryGreen = AppConfig.primaryColor;
  static const Color textDark = AppColors.textDark;
  static const Color textMuted = AppColors.textGrey;
  static const Color background = AppColors.latar;

  Product get p => widget.product;

  void _increaseQty() {
    setState(() {
      _quantity++;
    });
  }

  void _decreaseQty() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  void _addToCart() {
    _cartService.addProduct(p, quantity: _quantity);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$_quantity x ${p.name} ditambahkan ke keranjang',
        ),
        backgroundColor: primaryGreen,
        action: SnackBarAction(
          label: 'Lihat',
          textColor: Colors.white,
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CartScreen()),
            );
          },
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _buyNow() {
    _cartService.addProduct(p, quantity: _quantity);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CartScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isPO = p.isPreOrder;
    final int subtotal = p.price * _quantity;

    return Scaffold(
      backgroundColor: background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 190),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBadges(isPO),
                      const SizedBox(height: 14),
                      Text(
                        p.name,
                        style: const TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                          color: textDark,
                          height: 1.12,
                        ),
                      ),
                      const SizedBox(height: 11),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            rupiah(p.price),
                            style: const TextStyle(
                              fontSize: 29,
                              fontWeight: FontWeight.w800,
                              color: primaryGreen,
                              letterSpacing: -0.7,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '/ ${p.unit.toLowerCase()}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 13),
                      _buildRatingRow(),
                      const SizedBox(height: 18),
                      _buildOrderTypeNotice(isPO),
                      const SizedBox(height: 24),
                      _buildDescriptionSection(),
                      const SizedBox(height: 26),
                      _buildVendorCard(),
                      const SizedBox(height: 18),
                      _buildDeliveryInfoCard(),
                    ],
                  ),
                ),
              ),
            ],
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomBar(subtotal),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 350,
      pinned: true,
      backgroundColor: primaryGreen,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
            ),
          ],
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        // Favorite
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: FavoriteButton(productId: p.id),
        ),
        const SizedBox(width: 6),

        // Cart icon with badge
        AnimatedBuilder(
          animation: _cartService,
          builder: (context, _) {
            final count = _cartService.totalQuantity;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 6),
                ],
              ),
              child: Stack(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.shopping_cart_outlined,
                      color: textDark,
                      size: 20,
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CartScreen()),
                      );
                    },
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
              url: p.imageUrl,
              fit: BoxFit.cover,
              errorWidget: Container(
                color: AppColors.hijauLembut,
                child: const Icon(
                  Icons.restaurant_rounded,
                  size: 78,
                  color: Color(0xFF5D7263),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 108,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.44),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 20,
              bottom: 18,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.38),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.26),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.restaurant_menu_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      p.category,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadges(bool isPO) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: isPO ? const Color(0xFFFFFBEB) : const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPO ? Icons.schedule_rounded : Icons.bolt_rounded,
                size: 15,
                color: isPO ? const Color(0xFFD97706) : primaryGreen,
              ),
              const SizedBox(width: 4),
              Text(
                isPO ? 'PRE-ORDER' : 'READY STOCK',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.55,
                  color: isPO ? const Color(0xFFD97706) : primaryGreen,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRatingRow() {
    return Row(
      children: [
        const Icon(Icons.star_rounded, size: 18, color: Color(0xFFF59E0B)),
        const SizedBox(width: 4),
        Text(
          p.rating.toStringAsFixed(1),
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            color: textDark,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 3,
          height: 3,
          decoration: const BoxDecoration(
            color: Color(0xFFB7D3BC),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'Dibuat oleh UMKM lokal',
          style: TextStyle(fontSize: 12, color: textMuted),
        ),
      ],
    );
  }

  Widget _buildOrderTypeNotice(bool isPO) {
    final color = isPO ? const Color(0xFFD97706) : primaryGreen;
    final backgroundColor =
        isPO ? const Color(0xFFFFFBEB) : const Color(0xFFE8F5E9);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            isPO ? Icons.event_available_rounded : Icons.check_circle_rounded,
            color: color,
            size: 19,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isPO
                  ? 'Disiapkan fresh mengikuti jadwal pesanan.'
                  : 'Siap disiapkan penjual setelah dipesan.',
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    final desc = p.description.isNotEmpty
        ? p.description
        : 'Disiapkan dengan bahan segar pilihan dan resep khas rumahan. '
            'Higienis, dijamin halal, serta diolah langsung oleh warga lokal untuk menjaga cita rasa otentik.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Deskripsi Produk',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: textDark,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          desc,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF536057),
            height: 1.6,
          ),
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(13, 12, 14, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.garis),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.tune_rounded,
                size: 18,
                color: primaryGreen,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pilihan produk',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      p.variant,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVendorCard() {
    final umkm = SampleCatalog.umkmById(p.umkmId);

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.garis),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informasi UMKM & Dapur',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: textDark,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.hijauLembut,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    umkm?.initials ?? _initials(p.umkm),
                    style: const TextStyle(
                      color: primaryGreen,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            p.umkm,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: textDark,
                            ),
                          ),
                        ),
                        if (umkm?.isVerified ?? false) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified,
                            color: Color(0xFF16A34A),
                            size: 15,
                          ),
                        ],
                      ],
                    ),
                    Text(
                      p.umkmType,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.latar,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: primaryGreen,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Lokasi: ${p.pickupLocation}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (umkm != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryGreen,
                      side: const BorderSide(color: AppColors.garis),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => openWhatsApp(
                      context,
                      phone: umkm.phone.isNotEmpty
                          ? umkm.phone
                          : kUmkmWhatsApp,
                      message:
                          'Halo ${umkm.name}, saya mau tanya soal ${p.name} di Djajan.',
                    ),
                    icon: const Icon(Icons.chat_bubble_outline, size: 17),
                    label: const Text(
                      'Hubungi',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: primaryGreen,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => UmkmStorefrontScreen(umkm: umkm),
                      ),
                    ),
                    icon: const Icon(Icons.storefront_outlined, size: 18),
                    label: const Text(
                      'Kunjungi Toko',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.take(2).map((x) => x.isEmpty ? '' : x[0]).join().toUpperCase();
  }

  Widget _buildDeliveryInfoCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.latar,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.delivery_dining_outlined,
            color: primaryGreen,
            size: 21,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              p.courierFee != null
                  ? 'Bisa diantar kurir warga (+${rupiah(p.courierFee!)}) atau ambil sendiri gratis ke dapur penjual.'
                  : 'Pesanan dapat diambil langsung di toko / dapur ${p.umkm}.',
              style: const TextStyle(
                fontSize: 11.5,
                color: Color(0xFF46534A),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(int subtotal) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 11, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0x14101B13),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'JUMLAH',
                        style: TextStyle(
                          fontSize: 9.5,
                          letterSpacing: 0.7,
                          fontWeight: FontWeight.w800,
                          color: textMuted,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.hijauLembut,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                        children: [
                          _quantityControl(
                            icon: Icons.remove_rounded,
                            enabled: _quantity > 1,
                            onTap: _decreaseQty,
                            borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(10),
                            ),
                          ),
                          SizedBox(
                            width: 34,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 160),
                              transitionBuilder: (child, animation) =>
                                  ScaleTransition(
                                scale: animation,
                                child: child,
                              ),
                              child: Text(
                                '$_quantity',
                                key: ValueKey(_quantity),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: textDark,
                                ),
                              ),
                            ),
                          ),
                          _quantityControl(
                            icon: Icons.add_rounded,
                            enabled: true,
                            onTap: _increaseQty,
                            borderRadius: const BorderRadius.horizontal(
                              right: Radius.circular(10),
                            ),
                          ),
                        ],
                      ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'SUBTOTAL',
                      style: TextStyle(
                        fontSize: 9.5,
                        letterSpacing: 0.7,
                        fontWeight: FontWeight.w800,
                        color: textMuted,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      rupiah(subtotal),
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: primaryGreen,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  flex: 4,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryGreen,
                      side: const BorderSide(color: AppColors.garis),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      minimumSize: const Size(0, 46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _addToCart,
                    icon: const Icon(Icons.add_shopping_cart, size: 18),
                    label: const Text(
                      '+ Keranjang',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 5,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      minimumSize: const Size(0, 46),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _buyNow,
                    child: const Text(
                      'Pesan Sekarang',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _quantityControl({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
    required BorderRadius borderRadius,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: borderRadius,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: borderRadius,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            icon,
            size: 18,
            color: enabled ? primaryGreen : AppColors.textGrey,
          ),
        ),
      ),
    );
  }
}
