import 'package:flutter/material.dart';

/// Floating pill navigation bar untuk halaman UMKM dengan label teks.
/// 4 tab: Home (0), Katalog (1), Pesanan (2), Setelan (3).
/// Mendukung badge merah pada tab Pesanan untuk pesanan baru yang perlu konfirmasi.
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

  static const Color primaryColor = Color(0xFF175D2B);
  static const Color inactiveColor = Color(0xFF718096);
  static const Color activeBackground = Color(0xFFEAF3EC);

  @override
  Widget build(BuildContext context) {
    final items = [
      const _NavItem(
        label: 'Home',
        icon: Icons.storefront_outlined,
        activeIcon: Icons.storefront_rounded,
        badge: 0,
      ),
      const _NavItem(
        label: 'Katalog',
        icon: Icons.inventory_2_outlined,
        activeIcon: Icons.inventory_2_rounded,
        badge: 0,
      ),
      _NavItem(
        label: 'Pesanan',
        icon: Icons.receipt_long_outlined,
        activeIcon: Icons.receipt_long_rounded,
        badge: pesananBaru,
      ),
      const _NavItem(
        label: 'Setelan',
        icon: Icons.settings_outlined,
        activeIcon: Icons.settings_rounded,
        badge: 0,
      ),
    ];

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
                              isSelected ? item.activeIcon : item.icon,
                              size: 23,
                              color: isSelected ? primaryColor : inactiveColor,
                            ),
                            if (item.badge > 0)
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
                                    item.badge > 99 ? '99+' : '${item.badge}',
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
                          item.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
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
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final int badge;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    this.badge = 0,
  });
}
