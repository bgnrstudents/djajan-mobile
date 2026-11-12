import 'package:flutter/material.dart';
import '../models/product.dart';
import 'app_network_image.dart';
import 'favorite_button.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onAddToCart;
  final VoidCallback? onTap;

  /// Dipanggil saat nama UMKM pada kartu ditekan (membuka storefront).
  final VoidCallback? onUmkmTap;

  const ProductCard({
    super.key,
    required this.product,
    required this.onAddToCart,
    this.onTap,
    this.onUmkmTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPreOrder = product.isPreOrder;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE0E5E9)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  AppNetworkImage(
                    url: product.imageUrl,
                    height: 105,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),

                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: isPreOrder
                            ? const Color(0xFFFFF7ED)
                            : const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isPreOrder
                              ? const Color(0xFFFED7AA)
                              : const Color(0xFFA7F3D0),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPreOrder
                                ? Icons.schedule_rounded
                                : Icons.bolt_rounded,
                            size: 11,
                            color: isPreOrder
                                ? const Color(0xFFEA580C)
                                : const Color(0xFF15803D),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            isPreOrder ? 'Pre-Order' : 'Ready Stock',
                            style: TextStyle(
                              fontSize: 10,
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
                      top: 6,
                      right: 6,
                      child: FavoriteButton(productId: product.id, size: 16),
                    ),
                ],
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
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
                                fontSize: 11,
                                color: onUmkmTap != null
                                    ? const Color(0xFF175D2B)
                                    : Colors.grey,
                                fontWeight: onUmkmTap != null
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),

                        const Icon(
                          Icons.star,
                          size: 14,
                          color: Color(0xFFF29B00),
                        ),

                        const SizedBox(width: 2),

                        Text(
                          '${product.rating}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Rp${product.price.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        GestureDetector(
                          onTap: onAddToCart,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.add,
                              size: 20,
                              color: Colors.white,
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
      ),
    );
  }
}
