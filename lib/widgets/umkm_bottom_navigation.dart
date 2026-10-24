import 'package:flutter/material.dart';

/// Floating pill navigation bar untuk halaman UMKM.
/// 2 tab: Produk (index 0) dan Pesanan (index 1).
/// Mendukung badge merah pada tab Pesanan untuk pesanan baru.
class UmkmBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  /// Jumlah pesanan baru (PO Baru). Jika > 0, tampil badge merah.
  final int pesananBaru;

  const UmkmBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    this.pesananBaru = 0,
  });

  static const Color _primary = Color(0xFF175D2B);
  static const Color _inactive = Color(0xFF8A939B);
  static const Color _activeBg = Color(0xFFEAF3EC);

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem(
        icon: Icons.storefront_outlined,
        activeIcon: Icons.storefront,
        badge: 0,
      ),
      _NavItem(
        icon: Icons.receipt_long_outlined,
        activeIcon: Icons.receipt_long,
        badge: pesananBaru,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: SafeArea(
        top: false,
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: const Color(0xFFE8ECEF), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double itemWidth = constraints.maxWidth / items.length;

              return Stack(
                children: [
                  // Animated highlight pill
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                    left: (itemWidth * currentIndex) + (itemWidth - 50) / 2,
                    top: 10,
                    width: 50,
                    height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _activeBg,
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),

                  Row(
                    children: List.generate(items.length, (index) {
                      final bool isSelected = currentIndex == index;
                      final item = items[index];

                      return Expanded(
                        child: GestureDetector(
                          onTap: () => onDestinationSelected(index),
                          behavior: HitTestBehavior.opaque,
                          child: Center(
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                AnimatedScale(
                                  scale: isSelected ? 1.0 : 0.88,
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOutBack,
                                  child: AnimatedSwitcher(
                                    duration:
                                        const Duration(milliseconds: 180),
                                    switchInCurve: Curves.easeOutBack,
                                    switchOutCurve: Curves.easeIn,
                                    transitionBuilder: (child, animation) {
                                      return ScaleTransition(
                                        scale: animation,
                                        child: FadeTransition(
                                          opacity: animation,
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: Icon(
                                      isSelected
                                          ? item.activeIcon
                                          : item.icon,
                                      key: ValueKey(isSelected),
                                      size: 30,
                                      color: isSelected ? _primary : _inactive,
                                    ),
                                  ),
                                ),

                                // Badge pesanan baru
                                if (item.badge > 0)
                                  Positioned(
                                    top: -3,
                                    right: -7,
                                    child: Container(
                                      padding: const EdgeInsets.all(3.5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFBA1A1A),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 1.5,
                                        ),
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 18,
                                        minHeight: 18,
                                      ),
                                      child: Text(
                                        item.badge > 99
                                            ? '99+'
                                            : '${item.badge}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                          height: 1,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final int badge;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    this.badge = 0,
  });
}
