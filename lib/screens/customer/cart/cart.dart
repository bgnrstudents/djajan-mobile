import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/order.dart';
import '../../../services/auth_service.dart';
import '../../../services/cart_service.dart';
import '../../../widgets/app_network_image.dart';
import '../../../widgets/umkm_app_bar.dart';
import '../../auth/login_screen.dart';
import '../order/order_checkout_screen.dart';
import '../order/order_widgets.dart';

class CartScreen extends StatefulWidget {
  final bool showAppBar;
  final VoidCallback? onBack;
  final VoidCallback? onExploreProducts;

  const CartScreen({
    super.key,
    this.showAppBar = true,
    this.onBack,
    this.onExploreProducts,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _cartService = CartService();

  Future<void> _showQuantityDialog(CartLine item) async {
    final controller = TextEditingController(text: '${item.quantity}');
    final isPo = item.type == OrderType.preOrder;
    final minAllowed = isPo && item.minOrderPo > 0 ? item.minOrderPo : 1;

    final result = await showDialog<int>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Ubah Jumlah',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.productName,
                style: const TextStyle(fontSize: 13, color: OC.muted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: OC.primary,
                ),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  filled: true,
                  fillColor: OC.mint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  helperText: isPo
                      ? 'Minimal pemesanan Pre-Order: $minAllowed ${item.unit}'
                      : 'Ketik 0 jika ingin menghapus dari keranjang',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Batal'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: OC.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                final input = int.tryParse(controller.text.trim());
                if (input != null && input >= 0) {
                  Navigator.pop(dialogCtx, input);
                } else {
                  Navigator.pop(dialogCtx);
                }
              },
              child: const Text('Terapkan'),
            ),
          ],
        );
      },
    );

    if (result != null && mounted) {
      if (result == 0) {
        _cartService.updateQuantity(item.productId, 0, type: item.type);
        return;
      }
      int finalQty = result;
      if (finalQty < minAllowed) {
        finalQty = minAllowed;
        showToast(
          context,
          'Jumlah disesuaikan ke minimal pemesanan: $minAllowed ${item.unit}',
        );
      }
      _cartService.updateQuantity(item.productId, finalQty, type: item.type);
    }
  }

  Future<bool?> _showLoginRequiredSheet(CartGroup group) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCE8DE),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: OC.mint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  size: 32,
                  color: OC.primary,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Masuk Dulu Yuk!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: OC.ink,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Masuk ke akun Djajan untuk melanjutkan checkout pesanan Anda.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: OC.muted, height: 1.45),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx, true);
                    final ok = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                    if (ok == true && mounted) {
                      _checkoutGroup(group);
                    }
                  },
                  icon: const Icon(
                    Icons.login_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  label: const Text(
                    'Masuk / Daftar Sekarang',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: OC.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(
                  'Lanjut Lihat Menu Lain',
                  style: TextStyle(
                    color: OC.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _checkoutGroup(CartGroup group) async {
    final auth = context.read<AuthService>();
    if (!auth.isLoggedIn || !auth.isPelanggan) {
      await _showLoginRequiredSheet(group);
      return;
    }

    for (final line in group.items) {
      if (line.type == OrderType.preOrder &&
          line.minOrderPo > 1 &&
          line.quantity < line.minOrderPo) {
        showToast(
          context,
          'Minimal pemesanan Pre-Order "${line.productName}" adalah ${line.minOrderPo} ${line.unit}.',
          error: true,
        );
        return;
      }
    }

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderCheckoutScreen(cartLines: group.items),
      ),
    );
  }

  Future<void> _confirmRemoveGroup(CartGroup group) async {
    final modeLabel = group.isPreOrder ? 'Pre-Order' : 'Ready Stock';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Hapus Pesanan Toko?',
          style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Hapus semua produk $modeLabel dari ${group.umkmName} di keranjang?',
          style: const TextStyle(fontSize: 13, color: OC.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: OC.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok == true) {
      _cartService.clearGroup(group.umkmId, group.orderType);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _cartService,
      builder: (context, _) {
        final groups = _cartService.groupedByStoreAndMode;
        final bool isEmpty = groups.isEmpty;
        final needsBackButton =
            widget.onBack != null || Navigator.canPop(context);

        return Scaffold(
          backgroundColor: OC.bg,
          body: Stack(
            children: [
              const HeaderBotanicalBackdrop(height: 220),
              SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    if (widget.showAppBar && needsBackButton)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                        child: Row(
                          children: [
                            DjajanBackButton(
                              onPressed:
                                  widget.onBack ?? () => Navigator.pop(context),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Keranjang Belanja',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: OC.ink,
                                      letterSpacing: -0.3,
                                      height: 1.15,
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    'Dikelompokkan per toko & mode pesanan',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: OC.muted,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      height: 1.15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.fromLTRB(14, 10, 14, 10),
                        child: UmkmHeaderRow(
                          padding: EdgeInsets.zero,
                          iconBadge: UmkmSquircleIcon(
                            icon: Icons.shopping_cart_rounded,
                          ),
                          title: 'Keranjang Belanja',
                          subtitle: 'Dikelompokkan per toko & mode pesanan',
                        ),
                      ),
                    Expanded(
                      child: isEmpty
                          ? _buildEmptyCart()
                          : ListView(
                              padding: const EdgeInsets.fromLTRB(
                                14,
                                8,
                                14,
                                28,
                              ),
                              children: [
                                _buildNoticeBanner(groups.length),
                                const SizedBox(height: 12),
                                for (final group in groups) ...[
                                  _buildStoreGroupCard(group),
                                  const SizedBox(height: 12),
                                ],
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: const BoxDecoration(
                color: OC.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                size: 46,
                color: OC.primary,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Keranjang Belanja Kosong',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: OC.ink,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Temukan makanan dan jajanan favorit dari usaha lokal di sekitar Anda.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: OC.muted, height: 1.4),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: OC.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed:
                    widget.onExploreProducts ??
                    () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
                icon: const Icon(Icons.storefront_outlined),
                label: const Text(
                  'Mulai Belanja',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoticeBanner(int groupCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: OC.banner,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: OC.line),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: OC.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$groupCount Keranjang Toko & Layanan',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                    color: OC.ink,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Ready Stock & Pre-Order serta antar toko di-checkout terpisah agar pengiriman akurat.',
                  style: TextStyle(fontSize: 11.5, color: OC.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreGroupCard(CartGroup group) {
    final bool isPO = group.isPreOrder;
    final Color badgeBg = isPO ? OC.peach : OC.mint;
    final Color badgeFg = isPO ? OC.amber : OC.mintText;
    final IconData badgeIcon =
        isPO ? Icons.schedule_rounded : Icons.bolt_rounded;
    final String badgeText = isPO ? 'PRE-ORDER' : 'READY STOCK';

    return Container(
      key: ValueKey('cart-group-${group.key}'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OC.line),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF17251B).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: OC.mintSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.soup_kitchen_outlined,
                  color: OC.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.umkmName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: OC.ink,
                      ),
                    ),
                    Text(
                      group.umkmType,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11.5, color: OC.muted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, size: 12, color: badgeFg),
                    const SizedBox(width: 4),
                    Text(
                      badgeText,
                      style: TextStyle(
                        color: badgeFg,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Hapus grup ini',
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 19,
                  color: OC.muted,
                ),
                onPressed: () => _confirmRemoveGroup(group),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (final item in group.items) ...[
            const Divider(height: 1, color: OC.line),
            _buildCartItemRow(item),
          ],
          const Divider(height: 20, color: OC.line),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Subtotal (${group.totalQuantity} item)',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: OC.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      rupiah(group.subtotal),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: OC.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                key: ValueKey('cart-checkout-${group.key}'),
                style: FilledButton.styleFrom(
                  backgroundColor: isPO ? OC.amber : OC.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _checkoutGroup(group),
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: Text(
                  isPO ? 'Checkout PO Ini' : 'Checkout Pesanan Ini',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemRow(CartLine item) {
    final bool isPO = item.type == OrderType.preOrder;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: AppNetworkImage(
              url: item.imageUrl,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorWidget: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: (isPO ? OC.amber : OC.primary).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isPO ? Icons.lunch_dining : Icons.local_drink,
                  size: 24,
                  color: isPO ? OC.amber : OC.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                    color: OC.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.variant} • ${rupiah(item.price)} / ${item.unit}',
                  style: const TextStyle(fontSize: 11.5, color: OC.muted),
                ),
                if (isPO && item.minOrderPo > 1) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: item.quantity < item.minOrderPo
                          ? const Color(0xFFFEF2F2)
                          : const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: item.quantity < item.minOrderPo
                            ? const Color(0xFFFECACA)
                            : const Color(0xFFFDE68A),
                      ),
                    ),
                    child: Text(
                      item.quantity < item.minOrderPo
                          ? 'Min. order: ${item.minOrderPo} ${item.unit} (Belum tercapai)'
                          : 'Min. order: ${item.minOrderPo} ${item.unit}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: item.quantity < item.minOrderPo
                            ? const Color(0xFFDC2626)
                            : const Color(0xFFB45309),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      rupiah(item.subtotal),
                      style: const TextStyle(
                        color: OC.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: OC.line),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () {
                              _cartService.updateQuantity(
                                item.productId,
                                item.quantity - 1,
                                type: item.type,
                              );
                            },
                            borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(8),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              child: Icon(
                                item.quantity == 1
                                    ? Icons.delete_outline
                                    : Icons.remove,
                                size: 16,
                                color: item.quantity == 1 ? OC.danger : OC.ink,
                              ),
                            ),
                          ),
                          Tooltip(
                            message: 'Ketuk untuk ketik jumlah',
                            child: InkWell(
                              onTap: () => _showQuantityDialog(item),
                              borderRadius: BorderRadius.circular(4),
                              child: Container(
                                constraints: const BoxConstraints(minWidth: 28),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                child: Text(
                                  '${item.quantity}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: OC.ink,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              _cartService.updateQuantity(
                                item.productId,
                                item.quantity + 1,
                                type: item.type,
                              );
                            },
                            borderRadius: const BorderRadius.horizontal(
                              right: Radius.circular(8),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              child: Icon(Icons.add, size: 16, color: OC.ink),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
