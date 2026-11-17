import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/cart_service.dart';
import '../theme/app_theme.dart';

class FloatingCartButton extends StatelessWidget {
  final VoidCallback onPressed;

  const FloatingCartButton({super.key, required this.onPressed});

  static final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    final cart = CartService();

    return AnimatedBuilder(
      animation: cart,
      builder: (context, _) {
        final hasItems = cart.isNotEmpty;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.94, end: 1).animate(animation),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.12),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
          ),
          child: hasItems
              ? _buildButton(cart, key: const ValueKey('floating-cart-visible'))
              : const SizedBox.shrink(
                  key: ValueKey('floating-cart-hidden'),
                ),
        );
      },
    );
  }

  Widget _buildButton(CartService cart, {required Key key}) {
    return Semantics(
      key: key,
      button: true,
      label:
          'Buka keranjang, ${cart.totalQuantity} item, subtotal ${_currencyFormat.format(cart.subtotal)}',
      child: Material(
        color: AppColors.hijauTua,
        elevation: 8,
        shadowColor: AppColors.hijauTua.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          key: const ValueKey('floating-cart-button'),
          onTap: onPressed,
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            width: 224,
            height: 62,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.shopping_bag_outlined,
                        color: Colors.white,
                        size: 23,
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${cart.totalQuantity} item di keranjang',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Subtotal ${_currencyFormat.format(cart.subtotal)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white,
                        size: 15,
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: -6,
                  left: 31,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 19),
                    height: 19,
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.hijauMuda,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Text(
                      cart.totalQuantity > 99
                          ? '99+'
                          : '${cart.totalQuantity}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
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
}
