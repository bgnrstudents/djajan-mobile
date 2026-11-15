import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../screens/customer/order/order_widgets.dart';

const _appBarInk = Color(0xFF16201A);
const _appBarMuted = Color(0xFF5F6B64);
const _appBarLine = Color(0xFFE8EAE8);
const _appBarPrimarySoft = Color(0xFFEAF3EC);

class DjajanAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> actions;
  final PreferredSizeWidget? bottom;
  final Color backgroundColor;
  final bool centerTitle;

  const DjajanAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.subtitle,
    this.leading,
    this.actions = const [],
    this.bottom,
    this.backgroundColor = Colors.white,
    this.centerTitle = false,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(64 + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final showBack =
        leading != null || (ModalRoute.of(context)?.canPop ?? false);

    return AppBar(
      toolbarHeight: 64,
      backgroundColor: backgroundColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: centerTitle,
      titleSpacing: showBack ? 2 : 20,
      leadingWidth: showBack ? 56 : 0,
      leading:
          leading ??
          (showBack
              ? Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: DjajanBackButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                )
              : null),
      title:
          titleWidget ??
          (title == null
              ? null
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _appBarInk,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.25,
                        height: 1.15,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _appBarMuted,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          height: 1.15,
                        ),
                      ),
                    ],
                  ],
                )),
      actions: actions.isEmpty ? null : actions,
      bottom: bottom,
      shape: const Border(bottom: BorderSide(color: _appBarLine)),
    );
  }
}

class DjajanBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String tooltip;

  const DjajanBackButton({super.key, this.onPressed, this.tooltip = 'Kembali'});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
      style: IconButton.styleFrom(
        backgroundColor: _appBarPrimarySoft,
        foregroundColor: AppConfig.primaryColor,
        fixedSize: const Size(40, 40),
        padding: EdgeInsets.zero,
      ),
      icon: const Icon(Icons.arrow_back_rounded, size: 20),
    );
  }
}

/// App bar standar untuk layar UMKM dengan hierarki yang ringkas dan konsisten.
class UmkmAppBar extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget? leftWidget;
  final Widget? leading;
  final Widget? rightAction;
  final Widget? bottom;
  final bool showBottomBorder;
  final EdgeInsetsGeometry padding;

  const UmkmAppBar({
    super.key,
    this.title,
    this.subtitle,
    this.leftWidget,
    this.leading,
    this.rightAction,
    this.bottom,
    this.showBottomBorder = true,
    this.padding = const EdgeInsets.fromLTRB(16, 11, 16, 11),
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
                if (leading != null) ...[leading!, const SizedBox(width: 10)],
                Expanded(
                  child:
                      leftWidget ??
                      (title != null
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                    color: OC.ink,
                                    letterSpacing: -0.3,
                                    height: 1.15,
                                  ),
                                ),
                                if (subtitle != null) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    subtitle!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: OC.muted,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      height: 1.15,
                                    ),
                                  ),
                                ],
                              ],
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
