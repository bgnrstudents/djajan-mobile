import 'package:flutter/material.dart';

class AppBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  static const Color primaryColor = Color(0xFF175D2B);
  static const Color inactiveColor = Color(0xFF8A939B);
  static const Color activeBackground = Color(0xFFEAF3EC);

  @override
  Widget build(BuildContext context) {
    final items = [
      {'icon': Icons.home_outlined, 'activeIcon': Icons.home},
      {'icon': Icons.receipt_long_outlined, 'activeIcon': Icons.receipt_long},
      {'icon': Icons.shopping_cart_outlined, 'activeIcon': Icons.shopping_cart},
      {'icon': Icons.person_outline, 'activeIcon': Icons.person},
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
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                    left: (itemWidth * currentIndex) + (itemWidth - 50) / 2,
                    top: 10,
                    width: 50,
                    height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        color: activeBackground,
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),

                  Row(
                    children: List.generate(items.length, (index) {
                      final bool isSelected = currentIndex == index;

                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            onDestinationSelected(index);
                          },
                          behavior: HitTestBehavior.opaque,
                          child: Center(
                            child: AnimatedScale(
                              scale: isSelected ? 1.0 : 0.88,
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOutBack,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 180),
                                switchInCurve: Curves.easeOutBack,
                                switchOutCurve: Curves.easeIn,
                                transitionBuilder:
                                    (
                                      Widget child,
                                      Animation<double> animation,
                                    ) {
                                      return ScaleTransition(
                                        scale: animation,
                                        child: FadeTransition(
                                          opacity: animation,
                                          child: child,
                                        ),
                                      );
                                    },
                                child: Icon(
                                  (isSelected
                                          ? items[index]['activeIcon']
                                          : items[index]['icon'])
                                      as IconData,
                                  key: ValueKey(isSelected),
                                  size: 30,
                                  color: isSelected
                                      ? primaryColor
                                      : inactiveColor,
                                ),
                              ),
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
