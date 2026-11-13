import 'package:flutter/material.dart';
import '../screens/customer/order/order_widgets.dart';

/// App Bar standar untuk layar UMKM (Dashboard, Katalog, Pesanan, Pengaturan).
/// Clean flat design: title bold 20px, hairline border bawah, tanpa subtitle.
class UmkmAppBar extends StatelessWidget {
  final String? title;
  final Widget? leftWidget;
  final Widget? leading;
  final Widget? rightAction;
  final Widget? bottom;
  final bool showBottomBorder;
  final EdgeInsetsGeometry padding;

  const UmkmAppBar({
    super.key,
    this.title,
    this.leftWidget,
    this.leading,
    this.rightAction,
    this.bottom,
    this.showBottomBorder = true,
    this.padding = const EdgeInsets.fromLTRB(16, 14, 16, 14),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: showBottomBorder
            ? const Border(
                bottom: BorderSide(color: Color(0xFFEFEFEF), width: 1),
              )
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: padding,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: leftWidget ??
                      (title != null
                          ? Text(
                              title!,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: OC.ink,
                                letterSpacing: -0.3,
                                height: 1.2,
                              ),
                            )
                          : const SizedBox.shrink()),
                ),
                if (rightAction != null) ...[
                  const SizedBox(width: 10),
                  rightAction!,
                ],
              ],
            ),
          ),
          ?bottom,
        ],
      ),
    );
  }
}
