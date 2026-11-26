import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../services/cart_service.dart';
import '../theme/app_theme.dart';

class AppBottomNavigation extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  static const Color primaryColor = AppColors.hijauTua;
  static const Color inactiveColor = AppColors.textGrey;
  static const Color activeBackground = AppColors.hijauLembut;

  @override
  State<AppBottomNavigation> createState() => _AppBottomNavigationState();
}

class _AppBottomNavigationState extends State<AppBottomNavigation>
    with SingleTickerProviderStateMixin {
  static const _items = [
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

  late final AnimationController _indicatorController;

  @override
  void initState() {
    super.initState();
    _indicatorController = AnimationController.unbounded(
      vsync: this,
      value: widget.currentIndex.toDouble(),
    );
  }

  @override
  void didUpdateWidget(covariant AppBottomNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != oldWidget.currentIndex) {
      _indicatorController.animateWith(
        SpringSimulation(
          const SpringDescription(mass: 1, stiffness: 360, damping: 30),
          _indicatorController.value,
          widget.currentIndex.toDouble(),
          0,
        ),
      );
    }
  }

  @override
  void dispose() {
    _indicatorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartService = CartService();

    return AnimatedBuilder(
      animation: cartService,
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: SafeArea(
            top: false,
            child: Container(
              height: 66,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: AppColors.garis, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final itemWidth = constraints.maxWidth / _items.length;

                  return Stack(
                    children: [
                      AnimatedBuilder(
                        animation: _indicatorController,
                        builder: (context, child) => Positioned(
                          left: _indicatorController.value * itemWidth + 2,
                          top: 0,
                          bottom: 0,
                          width: itemWidth - 4,
                          child: child!,
                        ),
                        child: DecoratedBox(
                          key: const ValueKey('bottom-nav-indicator'),
                          decoration: BoxDecoration(
                            color: AppBottomNavigation.activeBackground,
                            borderRadius: BorderRadius.circular(21),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: List.generate(_items.length, (index) {
                            final selected = widget.currentIndex == index;
                            final item = _items[index];

                            return Expanded(
                              child: GestureDetector(
                                key: ValueKey('bottom-nav-item-$index'),
                                onTap: () => widget.onDestinationSelected(index),
                                behavior: HitTestBehavior.opaque,
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          AnimatedScale(
                                            scale: selected ? 1.06 : 1,
                                            duration: const Duration(
                                              milliseconds: 220,
                                            ),
                                            curve: Curves.easeOutCubic,
                                            child: AnimatedSwitcher(
                                              duration: const Duration(
                                                milliseconds: 180,
                                              ),
                                              switchInCurve: Curves.easeOutCubic,
                                              switchOutCurve: Curves.easeInCubic,
                                              transitionBuilder:
                                                  (child, animation) =>
                                                      FadeTransition(
                                                        opacity: animation,
                                                        child: ScaleTransition(
                                                          scale: Tween<double>(
                                                            begin: 0.88,
                                                            end: 1,
                                                          ).animate(animation),
                                                          child: child,
                                                        ),
                                                      ),
                                              child: Icon(
                                                (selected
                                                        ? item['activeIcon']
                                                        : item['icon'])
                                                    as IconData,
                                                key: ValueKey(
                                                  'nav-icon-$index-$selected',
                                                ),
                                                size: 22,
                                                color: selected
                                                    ? AppBottomNavigation
                                                          .primaryColor
                                                    : AppBottomNavigation
                                                          .inactiveColor,
                                              ),
                                            ),
                                          ),
                                          if (index == 2 &&
                                              cartService.totalQuantity > 0)
                                            Positioned(
                                              top: -4,
                                              right: -8,
                                              child: _CartBadge(
                                                count:
                                                    cartService.totalQuantity,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      AnimatedDefaultTextStyle(
                                        duration: const Duration(
                                          milliseconds: 220,
                                        ),
                                        curve: Curves.easeOutCubic,
                                        style: TextStyle(
                                          fontSize: 11,
                                          height: 1.1,
                                          fontWeight: selected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: selected
                                              ? AppBottomNavigation
                                                    .primaryColor
                                              : AppBottomNavigation
                                                    .inactiveColor,
                                        ),
                                        child: Text(
                                          item['label'] as String,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
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
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CartBadge extends StatelessWidget {
  final int count;

  const _CartBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? '99+' : '$count';

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) =>
          ScaleTransition(scale: animation, child: child),
      child: Container(
        key: ValueKey(label),
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppColors.hijauTua,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.bold,
            height: 1,
          ),
        ),
      ),
    );
  }
}
