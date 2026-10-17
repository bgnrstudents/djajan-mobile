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
  // Theme colors
  static const Color primaryGreen = Color(0xFF006B45);
  static const Color darkGreen = Color(0xFF0F6848);
  static const Color softBlueCard = Color(0xFFEFF3FD);
  static const Color softBlueNotice = Color(0xFFE8EEFD);
  static const Color background = Color(0xFFF8F9FD);
  static const Color textDark = Color(0xFF1E293B);
  static const Color textMuted = Color(0xFF64748B);

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
          backgroundColor: primaryGreen,
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
          backgroundColor: background,
          appBar: widget.showAppBar
              ? AppBar(
                  backgroundColor: background,
                  elevation: 0,
                  centerTitle: true,
                  leading: widget.onBack != null
                      ? IconButton(
                          icon: const Icon(Icons.arrow_back, color: textDark),
                          onPressed: widget.onBack,
                        )
                      : (Navigator.canPop(context)
                          ? IconButton(
                              icon: const Icon(Icons.arrow_back, color: textDark),
                              onPressed: () => Navigator.pop(context),
                            )
                          : null),
                  title: const Text(
                    'Keranjang',
                    style: TextStyle(
                      color: textDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                )
              : null,
          body: isEmpty
              ? _buildEmptyCart()
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  children: [
                    // 1. Notice banner
                    _buildNoticeBanner(grouped.length),
                    const SizedBox(height: 14),

                    // 2. Receiver info
                    _buildReceiverCard(),
                    const SizedBox(height: 14),

                    // 3. Vendor Cards (per UMKM)
                    for (final entry in grouped.entries) ...[
                      _buildUmkmCard(entry.key, entry.value),
                      const SizedBox(height: 14),
                    ],

                    // 4. Payment method
                    _buildPaymentMethodCard(),
                    const SizedBox(height: 14),

                    // 5. Payment summary
                    _buildPaymentSummaryCard(
                      subtotalProduk: subtotalProduk,
                      totalOngkir: totalOngkir,
                      totalPembayaran: totalPembayaran,
                    ),
                    const SizedBox(height: 16),

                    // 6. Trust footer
                    _buildTrustFooter(),
                    const SizedBox(height: 16),

                    // 7. Action button
                    _buildCheckoutButton(totalPembayaran),
                    const SizedBox(height: 24),
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
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF3EC),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                size: 50,
                color: primaryGreen,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Keranjang Belanja Kosong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Yuk dukung UMKM desa dengan memilih aneka jajanan dan kuliner lezat khas Kreyongan Atas!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: softBlueNotice,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: darkGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.storefront,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pesanan dari $umkmCount UMKM Berbeda',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Sistem mengelompokkan pengantaran per masing-masing UMKM',
                  style: TextStyle(
                    fontSize: 12,
                    color: textMuted,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.location_on, color: primaryGreen, size: 20),
                  SizedBox(width: 6),
                  Text(
                    'Kontak & Alamat Penerima',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: textDark,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: _editRecipient,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: const Text(
                    'Ubah',
                    style: TextStyle(
                      color: primaryGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: softBlueCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _recipient.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_bubble, size: 10, color: Color(0xFF16A34A)),
                          SizedBox(width: 4),
                          Text(
                            'WhatsApp Aktif',
                            style: TextStyle(
                              color: Color(0xFF16A34A),
                              fontSize: 11,
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
                    const Icon(Icons.phone_outlined, size: 15, color: primaryGreen),
                    const SizedBox(width: 6),
                    Text(
                      _recipient.phone,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF334155),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _recipient.address,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF334155),
                    height: 1.3,
                  ),
                ),
                if (_recipient.addressNote != null &&
                    _recipient.addressNote!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    '(${_recipient.addressNote})',
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
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
      headerBadgeBg = const Color(0xFFE0E7FF);
      headerBadgeFg = const Color(0xFF3730A3);
      headerBadgeIcon = Icons.inventory_2_outlined;
    } else if (hasPreOrder) {
      headerBadgeText = 'PRE-ORDER';
      headerBadgeBg = const Color(0xFFFBE5D2);
      headerBadgeFg = const Color(0xFF8D4A18);
      headerBadgeIcon = Icons.emoji_events_outlined;
    } else {
      headerBadgeText = 'PESAN SEKARANG';
      headerBadgeBg = const Color(0xFFDCFCE7);
      headerBadgeFg = const Color(0xFF14532D);
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
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEEAD9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.soup_kitchen_outlined,
                  color: Color(0xFF9A4C16),
                  size: 20,
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
                        fontSize: 16,
                        color: textDark,
                      ),
                    ),
                    Text(
                      first.umkmType,
                      style: const TextStyle(
                        fontSize: 12,
                        color: textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: headerBadgeBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      headerBadgeIcon,
                      size: 13,
                      color: headerBadgeFg,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      headerBadgeText,
                      style: TextStyle(
                        color: headerBadgeFg,
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Items inside this UMKM
          for (final item in lines) ...[
            _buildCartItemRow(item),
            const SizedBox(height: 10),
          ],

          // Pre-Order Details Box (if this UMKM has any Pre-Order products)
          if (hasPreOrder) ...[
            const SizedBox(height: 4),
            _buildPreOrderSection(umkmId),
            const SizedBox(height: 14),
          ],

          // Delivery Options
          const Text(
            'Opsi Pengantaran UMKM',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: textDark,
            ),
          ),
          const SizedBox(height: 8),

          // Option 1: Diantar Kurir Warga
          if (first.courierFee != null) ...[
            InkWell(
              onTap: () {
                setState(() {
                  _deliveryOptions[umkmId] = 0;
                });
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: deliveryChoice == 0
                      ? const Color(0xFFE5F8ED)
                      : softBlueCard,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      deliveryChoice == 0
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: deliveryChoice == 0
                          ? primaryGreen
                          : const Color(0xFF94A3B8),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Diantar Kurir Warga / UMKM',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12.5,
                              color: textDark,
                            ),
                          ),
                          Text(
                            'Langsung diantar ke balai / rumah',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '+${_formatRupiah(first.courierFee!.round())}',
                      style: const TextStyle(
                        color: primaryGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Option 2: Ambil Sendiri (Pickup)
          InkWell(
            onTap: () {
              setState(() {
                _deliveryOptions[umkmId] = 1;
              });
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: deliveryChoice == 1
                    ? const Color(0xFFE5F8ED)
                    : softBlueCard,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    deliveryChoice == 1
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: deliveryChoice == 1
                        ? primaryGreen
                        : const Color(0xFF94A3B8),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ambil Sendiri di Toko / Dapur (Pickup)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                            color: textDark,
                          ),
                        ),
                        Text(
                          'Lokasi: ${first.pickupLocation}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    'Gratis (Rp 0)',
                    style: TextStyle(
                      color: primaryGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Subtotal UMKM
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Subtotal (${first.umkmName})',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _formatRupiah(umkmTotal),
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: textDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Row for each Product Item in Cart
  Widget _buildCartItemRow(CartLine item) {
    final bool isPO = item.type == OrderType.preOrder;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: softBlueCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _productImage(
                imageUrl: item.imageUrl,
                fallbackIcon: isPO ? Icons.lunch_dining : Icons.local_drink,
                fallbackColor: isPO ? Colors.orange : Colors.teal,
              ),
              const SizedBox(width: 12),
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
                              fontSize: 14,
                              color: textDark,
                            ),
                          ),
                        ),
                        // Badge PO / Instant per item
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isPO
                                ? const Color(0xFFFFF0D8)
                                : const Color(0xFFDDF6E9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isPO ? 'PO' : 'Ready',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: isPO
                                  ? const Color(0xFFC56500)
                                  : const Color(0xFF08753E),
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
                        color: textMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatRupiah(item.subtotal.round()),
                          style: const TextStyle(
                            color: primaryGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
                          ),
                        ),
                        // Quantity Stepper: [-] [qty] [+]
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
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
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  child: Icon(
                                    item.quantity == 1
                                        ? Icons.delete_outline
                                        : Icons.remove,
                                    size: 16,
                                    color: item.quantity == 1
                                        ? Colors.red
                                        : textDark,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                child: Text(
                                  '${item.quantity}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: textDark,
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
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  child: Icon(
                                    Icons.add,
                                    size: 16,
                                    color: textDark,
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9ED),
        border: Border.all(color: const Color(0xFFFFDDB8)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.event_note, color: Color(0xFFC56500), size: 18),
              SizedBox(width: 6),
              Text(
                'Detail Jadwal & Keperluan Pre-Order',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF8D4A18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Waktu Dibutuhkan
          InkWell(
            onTap: () => _pickDateTime(umkmId),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFE0B2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: primaryGreen),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Waktu Dibutuhkan',
                          style: TextStyle(fontSize: 10.5, color: textMuted),
                        ),
                        Text(
                          fmtDateComma(date),
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: textMuted),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Keperluan Acara
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFFE0B2)),
            ),
            child: TextField(
              controller: purposeCtrl,
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                labelText: 'Keperluan Acara',
                labelStyle: TextStyle(fontSize: 12, color: textMuted),
                hintText: 'Contoh: Rapat RT, Pengajian, Hajatan',
                hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              style: const TextStyle(fontSize: 12.5, color: textDark),
            ),
          ),
          const SizedBox(height: 8),

          // Catatan Kemasan
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFFE0B2)),
            ),
            child: TextField(
              controller: noteCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                labelText: 'Catatan Pengemasan / Pesanan',
                labelStyle: TextStyle(fontSize: 12, color: textMuted),
                hintText: 'Contoh: Sambal dipisah, kemangi dipacking rapi...',
                hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              style: const TextStyle(fontSize: 12.5, color: textDark),
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
          Row(
            children: const [
              Icon(Icons.payment, color: primaryGreen, size: 20),
              SizedBox(width: 8),
              Text(
                'Metode Pembayaran',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // COD
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedPayment = 0;
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _selectedPayment == 0
                          ? const Color(0xFFE5F8ED)
                          : softBlueCard,
                      border: Border.all(
                        color: _selectedPayment == 0
                            ? primaryGreen
                            : Colors.transparent,
                        width: 1.2,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Icon(
                              Icons.payments_outlined,
                              color: primaryGreen,
                              size: 24,
                            ),
                            Icon(
                              _selectedPayment == 0
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: _selectedPayment == 0
                                  ? primaryGreen
                                  : const Color(0xFF94A3B8),
                              size: 18,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Bayar di Tempat (COD)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Titip tunai ke kurir warga',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Midtrans / Pembayaran Instan
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedPayment = 1;
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _selectedPayment == 1
                          ? const Color(0xFFE5F8ED)
                          : softBlueCard,
                      border: Border.all(
                        color: _selectedPayment == 1
                            ? primaryGreen
                            : Colors.transparent,
                        width: 1.2,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Icon(
                              Icons.bolt,
                              color: Color(0xFF334155),
                              size: 24,
                            ),
                            Icon(
                              _selectedPayment == 1
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: _selectedPayment == 1
                                  ? primaryGreen
                                  : const Color(0xFF94A3B8),
                              size: 18,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Bayar Sekarang',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'QRIS, GoPay, ShopeePay, VA',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: textMuted,
                          ),
                        ),
                      ],
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
          Row(
            children: const [
              Icon(Icons.receipt_long_outlined, color: primaryGreen, size: 20),
              SizedBox(width: 8),
              Text(
                'Rincian Pembayaran',
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _summaryRow('Subtotal Produk', _formatRupiah(subtotalProduk)),
          _summaryRow(
            'Total Ongkir Kurir UMKM',
            totalOngkir == 0 ? 'Gratis (Rp 0)' : _formatRupiah(totalOngkir),
          ),
          _summaryRow('Biaya Layanan Aplikasi', 'Gratis (Rp 0)'),
          const Divider(height: 20, color: Color(0xFFE2E8F0)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Pembayaran',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Sudah termasuk biaya kemasan',
                    style: TextStyle(
                      fontSize: 11,
                      color: textMuted,
                    ),
                  ),
                ],
              ),
              Text(
                _formatRupiah(totalPembayaran),
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: primaryGreen,
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
        Icon(Icons.verified_user_outlined, size: 16, color: primaryGreen),
        SizedBox(width: 6),
        Flexible(
          child: Text(
            'Belanja aman langsung memajukan tetangga & UMKM desa',
            style: TextStyle(color: Color(0xFF475569), fontSize: 12),
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
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 2,
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
        width: 68,
        height: 68,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: fallbackColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(fallbackIcon, size: 30, color: fallbackColor),
          );
        },
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF334155),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13.5,
              color: textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 4),
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
