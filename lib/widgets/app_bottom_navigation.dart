import 'package:flutter/material.dart';

import '../services/cart_service.dart';

class AppBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  static const Color primaryColor = Color(0xFF175D2B);
  static const Color inactiveColor = Color(0xFF718096);
  static const Color activeBackground = Color(0xFFEAF3EC);

  @override
  Widget build(BuildContext context) {
    final cartService = CartService();

    final items = const [
      {
        'label': 'Beranda',
        'icon': Icons.home_outlined,
        'activeIcon': Icons.home_rounded,
      },
      {
        'label': 'Pesanan',
        'icon': Icons.receipt_long_outlined,
        'activeIcon': Icons.receipt_long_rounded,
      },
      {
        'label': 'Keranjang',
        'icon': Icons.shopping_cart_outlined,
        'activeIcon': Icons.shopping_cart_rounded,
      },
      {
        'label': 'Profil',
        'icon': Icons.person_outline_rounded,
        'activeIcon': Icons.person_rounded,
      },
    ];

    return AnimatedBuilder(
      animation: cartService,
      builder: (context, _) {
        final int cartCount = cartService.totalQuantity;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: SafeArea(
            top: false,
            child: Container(
              height: 68,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFE8ECEF), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: List.generate(items.length, (index) {
                  final bool isSelected = currentIndex == index;
                  final item = items[index];

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onDestinationSelected(index),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected ? activeBackground : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Icon(
                                  (isSelected ? item['activeIcon'] : item['icon']) as IconData,
                                  size: 23,
                                  color: isSelected ? primaryColor : inactiveColor,
                                ),
                                if (index == 2 && cartCount > 0)
                                  Positioned(
                                    top: -4,
                                    right: -8,
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFBA1A1A),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 1.5,
                                        ),
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 16,
                                        minHeight: 16,
                                      ),
                                      child: Text(
                                        cartCount > 99 ? '99+' : '$cartCount',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          height: 1,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item['label'] as String,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? primaryColor : inactiveColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }
}
