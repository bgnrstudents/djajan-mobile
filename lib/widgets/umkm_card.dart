import 'package:flutter/material.dart';

import '../models/umkm.dart';
import '../theme/app_theme.dart';
import 'app_network_image.dart';

/// Kartu ringkas UMKM untuk carousel di beranda.
class UmkmCard extends StatelessWidget {
  final Umkm umkm;
  final int productCount;
  final VoidCallback? onTap;
  final bool featured;

  const UmkmCard({
    super.key,
    required this.umkm,
    required this.productCount,
    this.onTap,
    this.featured = false,
  });

  static const Color _primary = AppColors.hijauTua;
  static const Color _ink = AppColors.textDark;
  static const Color _muted = AppColors.textGrey;

  @override
  Widget build(BuildContext context) {
    return featured ? _buildFeaturedCard() : _buildCompactCard();
  }

  Widget _buildFeaturedCard() {
    return SizedBox(
      width: 230,
      height: 248,
      child: Material(
        color: Colors.white,
        elevation: 2,
        shadowColor: const Color(0x1A123C24),
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFD9E8DD)),
            ),
            child: Column(
              children: [
                _buildAwning(),
                SizedBox(
                  height: 104,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AppNetworkImage(
                        url: umkm.imageUrl,
                        fit: BoxFit.cover,
                        errorWidget: _bannerFallback(),
                      ),
                      if (umkm.isVerified)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.96),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified_rounded,
                                  size: 11,
                                  color: _primary,
                                ),
                                SizedBox(width: 3),
                                Text(
                                  'Terverifikasi',
                                  style: TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w700,
                                    color: _primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          umkm.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: _ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 5,
                          runSpacing: 3,
                          children: [
                            _infoChip(Icons.restaurant_menu_rounded, umkm.type),
                            _infoChip(
                              umkm.hasCourier
                                  ? Icons.delivery_dining_rounded
                                  : Icons.storefront_outlined,
                              umkm.hasCourier
                                  ? 'Antar tersedia'
                                  : 'Ambil sendiri',
                            ),
                          ],
                        ),
                        const Spacer(),
                        const Divider(height: 6, color: AppColors.garis),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: AppColors.kuning,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              umkm.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: _ink,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.hijauLembut,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$productCount menu',
                                style: const TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w700,
                                  color: _primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (umkm.pickupLocation.trim().isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 12,
                                color: _muted,
                              ),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  umkm.pickupLocation,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    color: _muted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAwning() {
    return SizedBox(
      height: 20,
      child: Column(
        children: [
          Expanded(
            child: Container(
              color: const Color(0xFF174B2A),
              child: Row(
                children: List.generate(
                  10,
                  (index) => Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: index.isEven
                              ? const Color(0xFF5B9E68)
                              : const Color(0xFF2E7040),
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(5),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Container(height: 3, color: const Color(0xFFC9A66B)),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 250),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3EC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: _primary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactCard() {
    return SizedBox(
      width: 190,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.garis),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                SizedBox(
                  height: 104,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AppNetworkImage(
                        url: umkm.imageUrl,
                        fit: BoxFit.cover,
                        errorWidget: _bannerFallback(),
                      ),
                      if (umkm.isVerified)
                        Positioned(
                          top: 9,
                          right: 9,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified_rounded,
                                  size: 11,
                                  color: AppColors.hijauTua,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Terverifikasi',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.hijauTua,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          umkm.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _ink,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          umkm.type,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: _muted),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 15,
                              color: AppColors.kuning,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              umkm.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _ink,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.hijauLembut,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$productCount produk',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: _primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bannerFallback() {
    return Container(
      color: AppColors.latar,
      child: const Icon(
        Icons.storefront_outlined,
        size: 34,
        color: AppColors.textGrey,
      ),
    );
  }
}
