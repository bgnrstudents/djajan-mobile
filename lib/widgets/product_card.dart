import 'package:flutter/material.dart';

import '../services/cart_service.dart';
import '../models/product.dart';
import 'app_network_image.dart';
import 'favorite_button.dart';
import '../theme/app_theme.dart';

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
          'Rp${product.price.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')}',
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
                  color: featured
                      ? isPreOrder
                            ? const Color(0xFFFFE6A6)
                            : const Color(0xFFEAF7EB)
                      : isPreOrder
                      ? AppColors.latar
                      : AppColors.hijauLembut,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: featured
                        ? isPreOrder
                              ? const Color(0xFFE8B33D)
                              : const Color(0xFF9BD49F)
                        : AppColors.garis,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPreOrder ? Icons.schedule_rounded : Icons.bolt_rounded,
                      size: featured ? 11 : 12,
                      color: featured
                          ? isPreOrder
                                ? const Color(0xFF8A5A00)
                                : AppColors.hijauTua
                          : isPreOrder
                          ? AppColors.hijauMuda
                          : AppColors.hijauTua,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isPreOrder ? 'Pre-Order' : 'Ready Stock',
                      style: TextStyle(
                        fontSize: featured ? 9.5 : 10.5,
                        fontWeight: FontWeight.w700,
                        color: featured
                            ? isPreOrder
                                  ? const Color(0xFF754B00)
                                  : AppColors.hijauTua
                            : isPreOrder
                            ? AppColors.hijauMuda
                            : AppColors.hijauTua,
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
                                    fontSize: featured ? 10.5 : 10.5,
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
                              Icons.star,
                              size: featured ? 13 : 14,
                              color: featured
                                  ? const Color(0xFFFFB21A)
                                  : AppColors.hijauMuda,
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

                        Text(
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
                        if (featured &&
                            product.description.trim().isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            product.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10.5,
                              height: 1.2,
                              color: AppColors.textGrey,
                            ),
                          ),
                        ],
                        SizedBox(height: featured ? 5 : 8),
                        if (featured) ...[
                          const Divider(height: 1, color: AppColors.garis),
                          const SizedBox(height: 5),
                        ],

                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) =>
                              SizeTransition(
                                sizeFactor: animation,
                                axisAlignment: -1,
                                child: FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                              ),
                          child: quantity == 0
                              ? Row(
                                  key: ValueKey('product-add-$cartProductId'),
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (featured) ...[
                                            const Text(
                                              'HARGA',
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.45,
                                                color: AppColors.textGrey,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                          ],
                                          price,
                                        ],
                                      ),
                                    ),
                                    InkWell(
                                      key: ValueKey(
                                        'product-card-add-$cartProductId',
                                      ),
                                      onTap: onAddToCart,
                                      borderRadius: BorderRadius.circular(
                                        featured ? 20 : 18,
                                      ),
                                      child: Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: featured
                                              ? AppColors.hijauTua
                                              : Theme.of(context)
                                                    .colorScheme
                                                    .primary,
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
                                          Icons.add,
                                          size: featured ? 18 : 20,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  key: ValueKey(
                                    'product-quantity-$cartProductId',
                                  ),
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    if (featured) ...[
                                      const Text(
                                        'HARGA',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.6,
                                          color: AppColors.textGrey,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                    ],
                                    price,
                                    const SizedBox(height: 6),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Container(
                                        height: featured ? 30 : 32,
                                        decoration: BoxDecoration(
                                          color: AppColors.latar,
                                          borderRadius: BorderRadius.circular(
                                            9,
                                          ),
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
                                              onTap: onAddToCart,
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
        height: featured ? 28 : 30,
        child: Icon(icon, size: 16, color: AppColors.hijauTua),
      ),
    );
  }
}
