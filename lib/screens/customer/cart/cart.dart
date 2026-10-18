import 'package:flutter/material.dart';

import '../order/midtrans_payment_screen.dart';
import '../order/order_detail_screen.dart';
import '../order/order_model.dart';
import '../order/order_service.dart';
import '../order/order_widgets.dart';
import 'cart_service.dart';

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
  final OrderService _orderService = OrderService();

  // Recipient state
  Recipient _recipient = const Recipient(
    name: 'Muhammad Rizki',
    phone: '0812-3456-7890',
    address: 'Jl. Merpati No. 14, RT 02 / RW 01, Desa Kreyongan Atas',
    addressNote: 'Rumah pagar hijau samping pos ronda desa',
  );

  // Delivery options per UMKM (0: Kurir, 1: Pickup)
  final Map<String, int> _deliveryOptions = {};

  // Pre-Order options per UMKM
  final Map<String, DateTime> _poRequiredDates = {};
  final Map<String, TextEditingController> _poPurposeControllers = {};
  final Map<String, TextEditingController> _poNoteControllers = {};

  // Payment method (0: COD, 1: QRIS)
  int _selectedPayment = 1; // Default QRIS
  bool _isSubmitting = false;

  @override
  void dispose() {
    for (final c in _poPurposeControllers.values) {
      c.dispose();
    }
    for (final c in _poNoteControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _getPurposeController(String umkmId) {
    return _poPurposeControllers.putIfAbsent(
      umkmId,
      () => TextEditingController(text: 'Rapat Desa RT 02'),
    );
  }

  TextEditingController _getNoteController(String umkmId) {
    return _poNoteControllers.putIfAbsent(
      umkmId,
      () => TextEditingController(
        text: 'Sambal dipisah, kemangi dipacking rapi untuk bapak-bapak lurah',
      ),
    );
  }

  DateTime _getPoDate(String umkmId) {
    return _poRequiredDates.putIfAbsent(umkmId, () {
      final base = DateTime.now().add(const Duration(days: 3));
      return DateTime(base.year, base.month, base.day, 11, 0);
    });
  }

  Future<void> _pickDateTime(String umkmId) async {
    final now = DateTime.now();
    final first = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    final current = _getPoDate(umkmId);

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: current.isBefore(first) ? first : current,
      firstDate: first,
      lastDate: first.add(const Duration(days: 180)),
      helpText: 'Pilih Tanggal Acara / Dibutuhkan',
    );

    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
      helpText: 'Pilih Jam Acara / Dibutuhkan',
    );

    if (pickedTime == null || !mounted) return;

    setState(() {
      _poRequiredDates[umkmId] = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _editRecipient() async {
    final updated = await showRecipientSheet(context, _recipient);
    if (updated != null) {
      setState(() {
        _recipient = updated;
      });
    }
  }

  Future<void> _handleCheckout() async {
    if (_isSubmitting) return;

    final items = _cartService.items;
    if (items.isEmpty) {
      showToast(context, 'Keranjang belanja masih kosong.', error: true);
      return;
    }

    final grouped = _cartService.itemsByUmkm;

    // Validate pre-order dates
    for (final entry in grouped.entries) {
      final isPO = entry.value.any((item) => item.type == OrderType.preOrder);
      if (isPO) {
        final date = _getPoDate(entry.key);
        if (date.isBefore(DateTime.now())) {
          showToast(
            context,
            'Waktu dibutuhkan untuk ${entry.value.first.umkmName} sudah terlewat.',
            error: true,
          );
          return;
        }
      }
    }

    setState(() => _isSubmitting = true);

    try {
      final options = <String, VendorCheckout>{};
      for (final entry in grouped.entries) {
        final umkmId = entry.key;
        final lines = entry.value;
        final isPO = lines.any((item) => item.type == OrderType.preOrder);
        final deliveryOpt = _deliveryOptions[umkmId] ??
            (lines.first.courierFee != null ? 0 : 1);

        options[umkmId] = VendorCheckout(
          delivery: deliveryOpt == 0
              ? DeliveryMethod.courier
              : DeliveryMethod.pickup,
          requiredAt: isPO ? _getPoDate(umkmId) : null,
          purpose: isPO ? _getPurposeController(umkmId).text.trim() : null,
          note: isPO ? _getNoteController(umkmId).text.trim() : null,
        );
      }

      final paymentMethod =
          _selectedPayment == 0 ? PaymentMethod.cod : PaymentMethod.midtrans;

      final order = await _orderService.createOrder(
        lines: items,
        recipient: _recipient,
        paymentMethod: paymentMethod,
        options: options,
      );

      _cartService.clear();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pesanan ${order.refId} berhasil dibuat!'),
          backgroundColor: OC.primary,
        ),
      );

      if (paymentMethod == PaymentMethod.midtrans) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MidtransPaymentScreen(orderId: order.id),
          ),
        );
      } else {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OrderDetailScreen(orderId: order.id),
          ),
        );
      }
    } on OrderException catch (e) {
      if (mounted) showToast(context, e.message, error: true);
    } catch (e) {
      if (mounted) showToast(context, 'Terjadi kesalahan: $e', error: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _cartService,
      builder: (context, _) {
        final grouped = _cartService.itemsByUmkm;
        final bool isEmpty = grouped.isEmpty;

        // Compute subtotals & delivery
        int subtotalProduk = 0;
        int totalOngkir = 0;

        for (final entry in grouped.entries) {
          final umkmId = entry.key;
          final lines = entry.value;
          final int umkmItemsTotal =
              lines.fold(0, (sum, l) => sum + l.subtotal.round());
          subtotalProduk += umkmItemsTotal;

          final deliveryChoice = _deliveryOptions[umkmId] ??
              (lines.first.courierFee != null ? 0 : 1);
          if (deliveryChoice == 0 && lines.first.courierFee != null) {
            totalOngkir += lines.first.courierFee!.round();
          }
        }

        final int totalPembayaran = subtotalProduk + totalOngkir;

        return Scaffold(
          backgroundColor: OC.bg,
          appBar: widget.showAppBar
              ? AppBar(
                  backgroundColor: OC.bg,
                  elevation: 0,
                  centerTitle: false,
                  leading: widget.onBack != null
                      ? IconButton(
                          icon: const Icon(Icons.arrow_back, color: OC.ink),
                          onPressed: widget.onBack,
                        )
                      : (Navigator.canPop(context)
                          ? IconButton(
                              icon: const Icon(Icons.arrow_back, color: OC.ink),
                              onPressed: () => Navigator.pop(context),
                            )
                          : null),
                  titleSpacing: 0,
                  title: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Keranjang Belanja',
                          style: TextStyle(
                            color: OC.ink,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Cek kembali item jajan & katering pilihanmu',
                          style: TextStyle(
                            color: OC.muted,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : null,
          body: isEmpty
              ? _buildEmptyCart()
              : ListView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  children: [
                    // 1. Notice banner
                    _buildNoticeBanner(grouped.length),
                    const SizedBox(height: 10),

                    // 2. Receiver info
                    _buildReceiverCard(),
                    const SizedBox(height: 10),

                    // 3. Vendor Cards (per UMKM)
                    for (final entry in grouped.entries) ...[
                      _buildUmkmCard(entry.key, entry.value),
                      const SizedBox(height: 10),
                    ],

                    // 4. Payment method
                    _buildPaymentMethodCard(),
                    const SizedBox(height: 10),

                    // 5. Payment summary
                    _buildPaymentSummaryCard(
                      subtotalProduk: subtotalProduk,
                      totalOngkir: totalOngkir,
                      totalPembayaran: totalPembayaran,
                    ),
                    const SizedBox(height: 14),

                    // 6. Trust footer
                    _buildTrustFooter(),
                    const SizedBox(height: 12),

                    // 7. Action button
                    _buildCheckoutButton(totalPembayaran),
                    const SizedBox(height: 20),
                  ],
                ),
        );
      },
    );
  }

  // ------------------------------------------------------------- Empty Cart
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
              'Yuk dukung UMKM desa dengan memilih aneka jajanan dan kuliner lezat khas Kreyongan Atas!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: OC.muted,
                height: 1.4,
              ),
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
                onPressed: widget.onExploreProducts ??
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

  // 1. Notice banner
  Widget _buildNoticeBanner(int umkmCount) {
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
              Icons.storefront,
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
                  'Pesanan dari $umkmCount UMKM Berbeda',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                    color: OC.ink,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Sistem mengelompokkan pengantaran per masing-masing UMKM',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: OC.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 2. Receiver info
  Widget _buildReceiverCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: OC.primary, size: 18),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Kontak & Alamat Penerima',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                    color: OC.ink,
                  ),
                ),
              ),
              InkWell(
                onTap: _editRecipient,
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    'Ubah',
                    style: TextStyle(
                      color: OC.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 18, color: OC.line),
          Row(
            children: [
              Flexible(
                child: Text(
                  _recipient.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: OC.ink,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: OC.mint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chat_bubble, size: 10, color: OC.mintText),
                    SizedBox(width: 4),
                    Text(
                      'WhatsApp Aktif',
                      style: TextStyle(
                        color: OC.mintText,
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.phone_outlined, size: 14, color: OC.primary),
              const SizedBox(width: 6),
              Text(
                _recipient.phone,
                style: const TextStyle(
                  fontSize: 13,
                  color: OC.muted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _recipient.address,
            style: const TextStyle(
              fontSize: 12.5,
              color: OC.muted,
              height: 1.3,
            ),
          ),
          if (_recipient.addressNote != null &&
              _recipient.addressNote!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              '(${_recipient.addressNote})',
              style: const TextStyle(
                fontSize: 11.5,
                fontStyle: FontStyle.italic,
                color: OC.faint,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 3. Card for each UMKM
  Widget _buildUmkmCard(String umkmId, List<CartLine> lines) {
    final first = lines.first;
    final bool hasPreOrder = lines.any((l) => l.type == OrderType.preOrder);
    final bool hasInstant = lines.any((l) => l.type == OrderType.instant);

    final int deliveryChoice =
        _deliveryOptions[umkmId] ?? (first.courierFee != null ? 0 : 1);
    final int courierFee =
        (deliveryChoice == 0 && first.courierFee != null)
            ? first.courierFee!.round()
            : 0;

    final int itemsSubtotal = lines.fold(0, (s, l) => s + l.subtotal.round());
    final int umkmTotal = itemsSubtotal + courierFee;

    // Header badge
    String headerBadgeText;
    Color headerBadgeBg;
    Color headerBadgeFg;
    IconData headerBadgeIcon;

    if (hasPreOrder && hasInstant) {
      headerBadgeText = 'PO & INSTANT';
      headerBadgeBg = OC.mint;
      headerBadgeFg = OC.mintText;
      headerBadgeIcon = Icons.inventory_2_outlined;
    } else if (hasPreOrder) {
      headerBadgeText = 'PRE-ORDER';
      headerBadgeBg = OC.peach;
      headerBadgeFg = OC.amber;
      headerBadgeIcon = Icons.emoji_events_outlined;
    } else {
      headerBadgeText = 'PESAN SEKARANG';
      headerBadgeBg = OC.mint;
      headerBadgeFg = OC.mintText;
      headerBadgeIcon = Icons.flash_on;
    }

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header UMKM
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
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
                      first.umkmName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: OC.ink,
                      ),
                    ),
                    Text(
                      first.umkmType,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: OC.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: headerBadgeBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      headerBadgeIcon,
                      size: 12,
                      color: headerBadgeFg,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      headerBadgeText,
                      style: TextStyle(
                        color: headerBadgeFg,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),

          // Items inside this UMKM
          for (final item in lines) ...[
            const Divider(height: 1, color: OC.line),
            _buildCartItemRow(item),
          ],

          // Pre-Order Details Box (if this UMKM has any Pre-Order products)
          if (hasPreOrder) ...[
            const Divider(height: 1, color: OC.line),
            const SizedBox(height: 10),
            _buildPreOrderSection(umkmId),
          ],

          const Divider(height: 22, color: OC.line),

          // Delivery Options
          const Text(
            'Opsi Pengantaran UMKM',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12.5,
              color: OC.ink,
            ),
          ),
          const SizedBox(height: 8),

          // Option 1: Diantar Kurir Warga
          if (first.courierFee != null) ...[
            _choiceTile(
              selected: deliveryChoice == 0,
              onTap: () {
                setState(() {
                  _deliveryOptions[umkmId] = 0;
                });
              },
              title: 'Diantar Kurir Warga / UMKM',
              subtitle: 'Langsung diantar ke balai / rumah',
              trailing: '+${_formatRupiah(first.courierFee!.round())}',
            ),
            const SizedBox(height: 8),
          ],

          // Option 2: Ambil Sendiri (Pickup)
          _choiceTile(
            selected: deliveryChoice == 1,
            onTap: () {
              setState(() {
                _deliveryOptions[umkmId] = 1;
              });
            },
            title: 'Ambil Sendiri di Toko / Dapur (Pickup)',
            subtitle: 'Lokasi: ${first.pickupLocation}',
            trailing: 'Gratis (Rp 0)',
          ),

          const Divider(height: 22, color: OC.line),

          // Subtotal UMKM
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Subtotal (${first.umkmName})',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: OC.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                _formatRupiah(umkmTotal),
                style: const TextStyle(
                  fontSize: 13.5,
                  color: OC.ink,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Radio-style choice tile (delivery options)
  Widget _choiceTile({
    required bool selected,
    required VoidCallback onTap,
    required String title,
    required String subtitle,
    required String trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? OC.mintSoft : Colors.white,
          border: Border.all(color: selected ? OC.primary : OC.line),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? OC.primary : OC.faint,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                      color: OC.ink,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: OC.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              trailing,
              style: const TextStyle(
                color: OC.primary,
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Row for each Product Item in Cart
  Widget _buildCartItemRow(CartLine item) {
    final bool isPO = item.type == OrderType.preOrder;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _productImage(
            imageUrl: item.imageUrl,
            fallbackIcon: isPO ? Icons.lunch_dining : Icons.local_drink,
            fallbackColor: isPO ? OC.amber : OC.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.productName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                          color: OC.ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Badge PO / Instant per item
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isPO ? OC.peach : OC.mint,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isPO ? 'PO' : 'Ready',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: isPO ? OC.amber : OC.mintText,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.variant} • ${_formatRupiah(item.price.round())} / ${item.unit}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: OC.muted,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatRupiah(item.subtotal.round()),
                      style: const TextStyle(
                        color: OC.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    // Quantity Stepper: [-] [qty] [+]
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
                                color: item.quantity == 1
                                    ? OC.danger
                                    : OC.ink,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            child: Text(
                              '${item.quantity}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: OC.ink,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              _cartService.updateQuantity(
                                item.productId,
                                item.quantity + 1,
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
                              child: Icon(
                                Icons.add,
                                size: 16,
                                color: OC.ink,
                              ),
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

  // Pre-Order Section per UMKM
  Widget _buildPreOrderSection(String umkmId) {
    final date = _getPoDate(umkmId);
    final purposeCtrl = _getPurposeController(umkmId);
    final noteCtrl = _getNoteController(umkmId);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: OC.peachSoft,
        border: Border.all(color: OC.peach),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.event_note, color: OC.amber, size: 16),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Detail Jadwal & Keperluan Pre-Order',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                    color: OC.amber,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Waktu Dibutuhkan
          InkWell(
            onTap: () => _pickDateTime(umkmId),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: OC.peach),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 15, color: OC.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Waktu Dibutuhkan',
                          style: TextStyle(fontSize: 10.5, color: OC.muted),
                        ),
                        Text(
                          fmtDateComma(date),
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: OC.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: OC.muted),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Keperluan Acara
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: OC.peach),
            ),
            child: TextField(
              controller: purposeCtrl,
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                labelText: 'Keperluan Acara',
                labelStyle: TextStyle(fontSize: 12, color: OC.muted),
                hintText: 'Contoh: Rapat RT, Pengajian, Hajatan',
                hintStyle: TextStyle(fontSize: 12, color: OC.faint),
              ),
              style: const TextStyle(fontSize: 12.5, color: OC.ink),
            ),
          ),
          const SizedBox(height: 6),

          // Catatan Kemasan
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: OC.peach),
            ),
            child: TextField(
              controller: noteCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                labelText: 'Catatan Pengemasan / Pesanan',
                labelStyle: TextStyle(fontSize: 12, color: OC.muted),
                hintText: 'Contoh: Sambal dipisah, kemangi dipacking rapi...',
                hintStyle: TextStyle(fontSize: 12, color: OC.faint),
              ),
              style: const TextStyle(fontSize: 12.5, color: OC.ink),
            ),
          ),
        ],
      ),
    );
  }

  // 4. Payment method
  Widget _buildPaymentMethodCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.payment, color: OC.primary, size: 18),
              SizedBox(width: 6),
              Text(
                'Metode Pembayaran',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: OC.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // COD
              Expanded(
                child: _paymentTile(
                  selected: _selectedPayment == 0,
                  onTap: () {
                    setState(() {
                      _selectedPayment = 0;
                    });
                  },
                  icon: Icons.payments_outlined,
                  title: 'Bayar di Tempat (COD)',
                  subtitle: 'Titip tunai ke kurir warga',
                ),
              ),
              const SizedBox(width: 8),

              // Midtrans / Pembayaran Instan
              Expanded(
                child: _paymentTile(
                  selected: _selectedPayment == 1,
                  onTap: () {
                    setState(() {
                      _selectedPayment = 1;
                    });
                  },
                  icon: Icons.bolt,
                  title: 'Bayar Sekarang',
                  subtitle: 'QRIS, GoPay, ShopeePay, VA',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _paymentTile({
    required bool selected,
    required VoidCallback onTap,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected ? OC.mintSoft : Colors.white,
          border: Border.all(color: selected ? OC.primary : OC.line),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: OC.primary, size: 22),
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selected ? OC.primary : OC.faint,
                  size: 18,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: OC.ink,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 10.5,
                color: OC.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 5. Payment Summary Card
  Widget _buildPaymentSummaryCard({
    required int subtotalProduk,
    required int totalOngkir,
    required int totalPembayaran,
  }) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.receipt_long_outlined, color: OC.primary, size: 18),
              SizedBox(width: 6),
              Text(
                'Rincian Pembayaran',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: OC.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _summaryRow('Subtotal Produk', _formatRupiah(subtotalProduk)),
          _summaryRow(
            'Total Ongkir Kurir UMKM',
            totalOngkir == 0 ? 'Gratis (Rp 0)' : _formatRupiah(totalOngkir),
          ),
          _summaryRow('Biaya Layanan Aplikasi', 'Gratis (Rp 0)'),
          const Divider(height: 20, color: OC.line),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Pembayaran',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: OC.ink,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Sudah termasuk biaya kemasan',
                    style: TextStyle(
                      fontSize: 11,
                      color: OC.muted,
                    ),
                  ),
                ],
              ),
              Text(
                _formatRupiah(totalPembayaran),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: OC.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 6. Trust Footer
  Widget _buildTrustFooter() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.verified_user_outlined, size: 15, color: OC.primary),
        SizedBox(width: 6),
        Flexible(
          child: Text(
            'Belanja aman langsung memajukan tetangga & UMKM desa',
            style: TextStyle(color: OC.muted, fontSize: 11.5),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  // 7. Checkout Button
  Widget _buildCheckoutButton(int total) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: OC.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: _isSubmitting ? null : _handleCheckout,
        child: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                'Pesan Sekarang (${_formatRupiah(total)})',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _productImage({
    required String imageUrl,
    required IconData fallbackIcon,
    required Color fallbackColor,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        imageUrl,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: fallbackColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(fallbackIcon, size: 24, color: fallbackColor),
          );
        },
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              color: OC.muted,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: OC.ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: OC.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: OC.line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  String _formatRupiah(int amount) {
    final str = amount.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i > 0) {
        buffer.write('.');
      }
    }
    return 'Rp ${buffer.toString().split('').reversed.join('')}';
  }
}
