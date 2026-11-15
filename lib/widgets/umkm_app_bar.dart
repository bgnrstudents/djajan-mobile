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
  final Color backgroundColor;
  final EdgeInsetsGeometry padding;

  const UmkmAppBar({
    super.key,
    this.title,
    this.subtitle,
    this.leftWidget,
    this.leading,
    this.rightAction,
    this.bottom,
    this.showBottomBorder = false,
    this.backgroundColor = Colors.transparent,
    this.padding = const EdgeInsets.fromLTRB(16, 11, 16, 11),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
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

/// Backdrop dekoratif ambient gelombang daun hijau di bagian header atas
/// sesuai desain referensi UMKM Djajan.
class HeaderBotanicalBackdrop extends StatelessWidget {
  final double height;

  const HeaderBotanicalBackdrop({super.key, this.height = 240});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: height,
      child: IgnorePointer(
        child: CustomPaint(
          size: Size(double.infinity, height),
          painter: _BotanicalLeafPainter(),
        ),
      ),
    );
  }
}

class _BotanicalLeafPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Lapisan terluar: Cahaya ambient lembut (Radial gradient glow)
    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.85, -0.65),
        radius: 0.9,
        colors: [
          const Color(0xFF66BB6A).withValues(alpha: 0.28),
          const Color(0xFF81C784).withValues(alpha: 0.16),
          const Color(0xFFA5D6A7).withValues(alpha: 0.06),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 0.75, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawCircle(Offset(w * 0.88, h * 0.18), w * 0.48, glowPaint);

    // 2. Daun / Kurva Organik Utama 1 (Lapisan dasar mint lembut)
    final leafPaint1 = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          Color(0x3881C784), // ~22%
          Color(0x24A5D6A7), // ~14%
          Color(0x00C8E6C9), // 0%
        ],
        stops: [0.0, 0.6, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final path1 = Path()
      ..moveTo(w * 0.38, 0)
      ..cubicTo(
        w * 0.52, h * 0.25,
        w * 0.68, h * 0.60,
        w, h * 0.45,
      )
      ..lineTo(w, 0)
      ..close();
    canvas.drawPath(path1, leafPaint1);

    // 3. Daun / Kurva Organik Utama 2 (Siluet daun kedua yang lebih tegas & anggun)
    final leafPaint2 = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          Color(0x404CAF50), // ~25%
          Color(0x2281C784), // ~13%
          Color(0x00A5D6A7), // 0%
        ],
        stops: [0.0, 0.55, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final path2 = Path()
      ..moveTo(w * 0.58, 0)
      ..cubicTo(
        w * 0.66, h * 0.45,
        w * 0.82, h * 0.85,
        w, h * 0.72,
      )
      ..lineTo(w, 0)
      ..close();
    canvas.drawPath(path2, leafPaint2);

    // 4. Aksen daun oval kecil / siluet organik halus di pojok kanan
    final leafPaint3 = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          Color(0x352E7D32), // ~20%
          Color(0x184CAF50), // ~9%
          Color(0x0081C784), // 0%
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final path3 = Path()
      ..moveTo(w * 0.76, 0)
      ..cubicTo(
        w * 0.78, h * 0.30,
        w * 0.90, h * 0.45,
        w, h * 0.32,
      )
      ..lineTo(w, 0)
      ..close();
    canvas.drawPath(path3, leafPaint3);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Container kartu ngambang bergaya glassmorphism untuk App Bar UMKM Djajan
class UmkmFloatingHeaderCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;

  const UmkmFloatingHeaderCard({
    super.key,
    required this.child,
    this.margin = const EdgeInsets.only(bottom: 20),
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.95),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F2E1B).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: const Color(0xFF0F2E1B).withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Squircle icon box hijau mint standar untuk App Bar UMKM Djajan
class UmkmSquircleIcon extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final Color? backgroundColor;
  final Color? borderColor;
  final double size;

  const UmkmSquircleIcon({
    super.key,
    required this.icon,
    this.color,
    this.backgroundColor,
    this.borderColor,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor ?? const Color(0xFFD8EBD8),
          width: 1,
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          size: 22,
          color: color ?? const Color(0xFF047857),
        ),
      ),
    );
  }
}

/// Header baris judul scrollable standar untuk halaman UMKM Djajan (Katalog, Pesanan, Pengaturan)
class UmkmHeaderRow extends StatelessWidget {
  final Widget iconBadge;
  final String title;
  final String subtitle;
  final Widget? rightAction;
  final EdgeInsetsGeometry padding;

  const UmkmHeaderRow({
    super.key,
    required this.iconBadge,
    required this.title,
    required this.subtitle,
    this.rightAction,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 14),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          iconBadge,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: OC.ink,
                    letterSpacing: -0.3,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
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
            ),
          ),
          if (rightAction != null) ...[
            const SizedBox(width: 10),
            rightAction!,
          ],
        ],
      ),
    );
  }
}
