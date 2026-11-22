import 'package:flutter/material.dart';

import '../services/cart_service.dart';
import '../models/product.dart';
import 'app_network_image.dart';
import 'favorite_button.dart';
import '../theme/app_theme.dart'; // includes AppColors + formatRupiah

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onAddToCart;
  final VoidCallback? onTap;

  /// Dipanggil saat nama UMKM pada kartu ditekan (membuka storefront).
  final VoidCallback? onUmkmTap;
  final bool featured;

  const ProductCard({
    super.key,
    required this.product,
    required this.onAddToCart,
    this.onTap,
    this.onUmkmTap,
    this.featured = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPreOrder = product.isPreOrder;
    final cartService = CartService();

    return AnimatedBuilder(
      animation: cartService,
      builder: (context, _) {
        final quantity = cartService.quantityForProduct(product);
        final cartProductId = product.toCartLine().productId;
        final compactFeatured =
            featured && MediaQuery.sizeOf(context).width < 380;
        final price = Text(
          formatRupiah(product.price),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: featured ? (compactFeatured ? 15 : 16) : 14,
            fontWeight: featured ? FontWeight.w700 : FontWeight.bold,
            color: featured ? AppColors.textDark : null,
          ),
        );
        const radius = 18.0;
        final image = Stack(
          fit: StackFit.expand,
          children: [
            AppNetworkImage(url: product.imageUrl, fit: BoxFit.cover),
            Positioned(
              top: featured ? 9 : 8,
              left: featured ? 9 : 8,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: featured ? 7 : 8,
                  vertical: featured ? 4 : 5,
                ),
                decoration: BoxDecoration(
                  color: isPreOrder
                      ? const Color(0xFFFFF7ED)
                      : const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isPreOrder
                        ? const Color(0xFFFFEDD5)
                        : const Color(0xFFDCFCE7),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPreOrder ? Icons.schedule_rounded : Icons.bolt_rounded,
                      size: featured ? 11 : 12,
                      color: isPreOrder
                          ? const Color(0xFFEA580C)
                          : const Color(0xFF16A34A),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isPreOrder ? 'Pre-Order' : 'Ready Stock',
                      style: TextStyle(
                        fontSize: featured ? 9.5 : 10.5,
                        fontWeight: FontWeight.w700,
                        color: isPreOrder
                            ? const Color(0xFFEA580C)
                            : const Color(0xFF15803D),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (product.id.isNotEmpty)
              Positioned(
                top: featured ? 7 : 6,
                right: featured ? 7 : 6,
                child: FavoriteButton(
                  productId: product.id,
                  size: featured ? 15 : 16,
                ),
              ),
            if (product.isOutOfStock)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.45),
                  alignment: Alignment.center,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'STOK HABIS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(radius),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(
                  color: featured ? const Color(0xFFE4EAE5) : AppColors.garis,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF17251B)
                        .withValues(alpha: featured ? 0.07 : 0.04),
                    blurRadius: featured ? 16 : 14,
                    offset: Offset(0, featured ? 5 : 5),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (featured)
                    AspectRatio(aspectRatio: 4 / 3, child: image)
                  else
                    SizedBox(height: 120, width: double.infinity, child: image),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      featured ? 9 : 11,
                      featured ? 7 : 9,
                      featured ? 9 : 11,
                      featured ? 8 : 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: onUmkmTap,
                                child: Text(
                                  product.umkm,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: featured || onUmkmTap != null
                                        ? AppColors.hijauTua
                                        : AppColors.textGrey,
                                    fontWeight: featured
                                        ? FontWeight.w500
                                        : onUmkmTap != null
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),

                            Icon(
                              Icons.star_rounded,
                              size: featured ? 13 : 14,
                              color: AppColors.kuning,
                            ),

                            const SizedBox(width: 2),

                            Text(
                              '${product.rating}',
                              style: TextStyle(
                                fontSize: featured ? 10.5 : 11,
                                fontWeight: FontWeight.w600,
                                color: featured ? AppColors.textGrey : null,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: featured ? 3 : 4),

                        SizedBox(
                          height: featured ? 32 : 34,
                          child: Text(
                            product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: featured ? 13.5 : 14,
                              height: featured ? 1.15 : 1.2,
                              fontWeight: featured
                                  ? FontWeight.w600
                                  : FontWeight.w700,
                              color: featured ? AppColors.textDark : null,
                            ),
                          ),
                        ),
                        SizedBox(height: featured ? 5 : 8),
                        if (featured) ...[
                          const Divider(height: 1, color: AppColors.garis),
                          const SizedBox(height: 5),
                        ],

                        SizedBox(
                          height: 38,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            switchInCurve: Curves.easeInOut,
                            switchOutCurve: Curves.easeInOut,
                            transitionBuilder: (child, animation) =>
                                FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                            child: quantity == 0
                                ? Row(
                                    key: ValueKey('product-add-$cartProductId'),
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (featured) ...[
                                              const Text(
                                                'HARGA',
                                                style: TextStyle(
                                                  fontSize: 8.5,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0.45,
                                                  color: AppColors.textGrey,
                                                ),
                                              ),
                                              const SizedBox(height: 1),
                                            ],
                                            price,
                                          ],
                                        ),
                                      ),
                                      InkWell(
                                        key: ValueKey(
                                          'product-card-add-$cartProductId',
                                        ),
                                        onTap: product.isOutOfStock
                                            ? null
                                            : onAddToCart,
                                        borderRadius: BorderRadius.circular(
                                          featured ? 20 : 18,
                                        ),
                                        child: Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: product.isOutOfStock
                                                ? Colors.grey.shade400
                                                : (featured
                                                    ? AppColors.hijauTua
                                                    : Theme.of(context)
                                                          .colorScheme
                                                          .primary),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(
                                                  alpha: 0.08,
                                                ),
                                                blurRadius: 5,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            product.isOutOfStock
                                                ? Icons.block
                                                : Icons.add,
                                            size: featured ? 18 : 20,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Row(
                                    key: ValueKey(
                                      'product-quantity-$cartProductId',
                                    ),
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (featured) ...const [
                                              Text(
                                                'HARGA',
                                                style: TextStyle(
                                                  fontSize: 8.5,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0.45,
                                                  color: AppColors.textGrey,
                                                ),
                                              ),
                                              SizedBox(height: 1),
                                            ],
                                            price,
                                          ],
                                        ),
                                      ),
                                      Container(
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: AppColors.latar,
                                          borderRadius: BorderRadius.circular(9),
                                          border: Border.all(
                                            color: AppColors.garis,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            _quantityButton(
                                              key: ValueKey(
                                                'product-card-decrease-$cartProductId',
                                              ),
                                              icon: Icons.remove,
                                              featured: featured,
                                              onTap: () =>
                                                  cartService.updateQuantity(
                                                    cartProductId,
                                                    quantity - 1,
                                                  ),
                                            ),
                                            SizedBox(
                                              key: ValueKey(
                                                'product-card-quantity-$cartProductId',
                                              ),
                                              width: 24,
                                              child: Text(
                                                '$quantity',
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.hijauTua,
                                                ),
                                              ),
                                            ),
                                            _quantityButton(
                                              key: ValueKey(
                                                'product-card-increase-$cartProductId',
                                              ),
                                              icon: Icons.add,
                                              featured: featured,
                                              onTap: product.isOutOfStock
                                                  ? () {}
                                                  : onAddToCart,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _quantityButton({
    required Key key,
    required IconData icon,
    required VoidCallback onTap,
    bool featured = false,
  }) {
    return InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: featured ? 28 : 30,
        height: 32,
        child: Icon(icon, size: 16, color: AppColors.hijauTua),
      ),
    );
  }
}
