import 'package:flutter/material.dart';

import '../models/order.dart';
import '../models/product.dart';
import '../services/cart_service.dart';
import '../theme/app_theme.dart';
import 'app_network_image.dart';

/// Menampilkan bottom sheet pemilihan mode pembelian untuk produk dengan mode "keduanya"
Future<void> showProductOrderTypeSheet(
  BuildContext context, {
  required Product product,
  VoidCallback? onAdded,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _ProductOrderTypeSheetWidget(
      product: product,
      onAdded: onAdded,
    ),
  );
}

class _ProductOrderTypeSheetWidget extends StatefulWidget {
  final Product product;
  final VoidCallback? onAdded;

  const _ProductOrderTypeSheetWidget({
    required this.product,
    this.onAdded,
  });

  @override
  State<_ProductOrderTypeSheetWidget> createState() =>
      _ProductOrderTypeSheetWidgetState();
}

class _ProductOrderTypeSheetWidgetState
    extends State<_ProductOrderTypeSheetWidget> {
  OrderType _selectedType = OrderType.instant;
  late int _quantity;

  Product get p => widget.product;
  int get minPo => p.minOrderPo > 0 ? p.minOrderPo : 1;

  @override
  void initState() {
    super.initState();
    _quantity = _selectedType == OrderType.preOrder ? minPo : 1;
  }

  void _onTypeChanged(OrderType type) {
    setState(() {
      _selectedType = type;
      if (type == OrderType.preOrder) {
        if (_quantity < minPo) {
          _quantity = minPo;
        }
      } else {
        if (_quantity < 1) {
          _quantity = 1;
        }
      }
    });
  }

  void _increaseQty() {
    setState(() => _quantity++);
  }

  void _decreaseQty() {
    final minLimit = _selectedType == OrderType.preOrder ? minPo : 1;
    if (_quantity > minLimit) {
      setState(() => _quantity--);
    }
  }

  void _confirmAddToCart() {
    CartService().addProduct(p, quantity: _quantity, type: _selectedType);
    Navigator.of(context).pop();
    widget.onAdded?.call();

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$_quantity x ${p.name} (${_selectedType == OrderType.preOrder ? 'Pre-Order' : 'Ready Stock'}) berhasil ditambahkan ke keranjang!',
        ),
        backgroundColor: AppColors.hijauTua,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPoSelected = _selectedType == OrderType.preOrder;
    final int subtotal = p.price * _quantity;
    final int minLimit = isPoSelected ? minPo : 1;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 12,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header Produk Ringkas
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 58,
                  height: 58,
                  child: AppNetworkImage(url: p.imageUrl, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${formatRupiah(p.price)} / ${p.unit.toLowerCase()}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.hijauTua,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: AppColors.garis),
          const SizedBox(height: 16),

          const Text(
            'Pilih Cara Pemesanan',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Produk ini mendukung pembelian langsung maupun pre-order untuk acara.',
            style: TextStyle(fontSize: 12, color: AppColors.textGrey, height: 1.3),
          ),
          const SizedBox(height: 14),

          // Pilihan 1: Ready Stock (Pesan Sekarang)
          _buildOptionCard(
            type: OrderType.instant,
            title: 'Pesan Sekarang (Ready Stock)',
            subtitle: p.stock != null && p.stock! > 0
                ? 'Stok ready: ${p.stock} ${p.unit}. Dikirim hari ini.'
                : 'Langsung dibuat dan diantar oleh penjual.',
            icon: Icons.bolt_rounded,
            accentColor: AppColors.hijauTua,
            selected: !isPoSelected,
            onTap: () => _onTypeChanged(OrderType.instant),
          ),
          const SizedBox(height: 10),

          // Pilihan 2: Pre-Order (PO Acara)
          _buildOptionCard(
            type: OrderType.preOrder,
            title: 'Pre-Order (PO Acara / Katering)',
            subtitle: p.minOrderPo > 1
                ? 'Minimal pembelian ${p.minOrderPo} ${p.unit}. Atur jadwal acara nanti di keranjang.'
                : 'Pesan untuk kebutuhan acara di tanggal tertentu.',
            icon: Icons.event_available_rounded,
            accentColor: const Color(0xFFD97706),
            selected: isPoSelected,
            onTap: () => _onTypeChanged(OrderType.preOrder),
          ),
          const SizedBox(height: 20),

          // Kontrol Kuantitas
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Jumlah Pembelian',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  if (isPoSelected && p.minOrderPo > 1) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Min. ${p.minOrderPo} ${p.unit}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFD97706),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.latar,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.garis),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_rounded, size: 18),
                      onPressed: _quantity > minLimit ? _decreaseQty : null,
                      color: AppColors.hijauTua,
                      splashRadius: 18,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        '$_quantity',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_rounded, size: 18),
                      onPressed: _increaseQty,
                      color: AppColors.hijauTua,
                      splashRadius: 18,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Subtotal & Tombol Tambah
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Harga',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textGrey,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatRupiah(subtotal),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.hijauTua,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _confirmAddToCart,
                  icon: const Icon(Icons.shopping_cart_outlined, size: 18),
                  label: const Text(
                    'Tambah ke Keranjang',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.hijauTua,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required OrderType type,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? accentColor.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? accentColor : AppColors.garis,
            width: selected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accentColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: selected ? accentColor : AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textGrey,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? accentColor : Colors.grey.shade400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
