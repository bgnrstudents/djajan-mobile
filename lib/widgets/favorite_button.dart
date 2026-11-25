import 'package:flutter/material.dart';

import '../services/favorite_service.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

/// Tombol hati (favorit) yang otomatis memperbarui diri saat status berubah.
///
/// Isi salah satu dari [productId] atau [umkmId].
class FavoriteButton extends StatelessWidget {
  final String? productId;
  final String? umkmId;
  final double size;
  final double? buttonSize;
  final Color? backgroundColor;
  final Color? inactiveColor;

  const FavoriteButton({
    super.key,
    this.productId,
    this.umkmId,
    this.size = 18,
    this.buttonSize,
    this.backgroundColor,
    this.inactiveColor,
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

        final icon = Icon(
          isFav ? Icons.favorite : Icons.favorite_border,
          size: size,
          color: isFav
              ? AppColors.hijauTua
              : (inactiveColor ?? AppColors.textGrey),
        );

        return Material(
          color: backgroundColor ?? Colors.white.withValues(alpha: 0.92),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () async {
              final nowFavorite = productId != null
                  ? favorites.toggleProduct(productId!)
                  : favorites.toggleUmkm(umkmId!);

              try {
                if (!ApiService.hasToken) {
                  _showFavoriteSnackBar(context, nowFavorite);
                  return;
                }
                if (productId != null) {
                  await favorites.syncProduct(productId!, nowFavorite);
                } else {
                  await favorites.syncUmkm(umkmId!, nowFavorite);
                }
              } on ApiException catch (error) {
                if (productId != null) {
                  favorites.toggleProduct(productId!);
                } else {
                  favorites.toggleUmkm(umkmId!);
                }
                if (!context.mounted) return;
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(error.pesan)));
                return;
              }

              if (context.mounted) {
                _showFavoriteSnackBar(context, nowFavorite);
              }
            },
            child: buttonSize != null
                ? SizedBox(
                    width: buttonSize,
                    height: buttonSize,
                    child: Center(child: icon),
                  )
                : Padding(
                    padding: const EdgeInsets.all(6),
                    child: icon,
                  ),
          ),
        );
      },
    );
  }

  void _showFavoriteSnackBar(BuildContext context, bool favorite) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            favorite ? 'Ditambahkan ke favorit' : 'Dihapus dari favorit',
          ),
          duration: const Duration(seconds: 1),
        ),
      );
  }
}
