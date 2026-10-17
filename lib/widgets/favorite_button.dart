import 'package:flutter/material.dart';

import '../screens/customer/favorite/favorite_service.dart';

/// Tombol hati (favorit) yang otomatis memperbarui diri saat status berubah.
///
/// Isi salah satu dari [productId] atau [umkmId].
class FavoriteButton extends StatelessWidget {
  final String? productId;
  final String? umkmId;
  final double size;
  final Color? backgroundColor;

  const FavoriteButton({
    super.key,
    this.productId,
    this.umkmId,
    this.size = 18,
    this.backgroundColor,
  }) : assert(
          (productId != null) ^ (umkmId != null),
          'Isi salah satu: productId atau umkmId.',
        );

  @override
  Widget build(BuildContext context) {
    final favorites = FavoriteService();

    return AnimatedBuilder(
      animation: favorites,
      builder: (context, _) {
        final isFav = productId != null
            ? favorites.isProductFavorite(productId!)
            : favorites.isUmkmFavorite(umkmId!);

        return Material(
          color: backgroundColor ?? Colors.white.withValues(alpha: 0.92),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              final nowFavorite = productId != null
                  ? favorites.toggleProduct(productId!)
                  : favorites.toggleUmkm(umkmId!);

              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    nowFavorite
                        ? 'Ditambahkan ke favorit'
                        : 'Dihapus dari favorit',
                  ),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                isFav ? Icons.favorite : Icons.favorite_border,
                size: size,
                color: isFav ? const Color(0xFFE11D48) : const Color(0xFF64748B),
              ),
            ),
          ),
        );
      },
    );
  }
}
