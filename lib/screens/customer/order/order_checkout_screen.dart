import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'midtrans_payment_screen.dart';
import 'order_model.dart';
import 'order_payment_screen.dart';
import 'order_service.dart';
import 'order_widgets.dart';

/// Tahap 1 alur pesanan: Checkout.
///
/// Gaya "ringkas": latar netral, kartu bersih tanpa kotak berlapis, satu bahasa
/// warna (hijau brand), dan total hanya muncul sekali di bilah bawah.
class OrderCheckoutScreen extends StatefulWidget {
  final List<CartLine> cartLines;

  /// Isian awal (opsional) untuk UMKM Pre-Order, dipakai pada mode demo.
  final String? initialPurpose;
  final String? initialNote;
  final PaymentMethod initialMethod;

  const OrderCheckoutScreen({
    super.key,
    required this.cartLines,
    this.initialPurpose,
    this.initialNote,
    this.initialMethod = PaymentMethod.midtrans,
  });

  @override
  State<OrderCheckoutScreen> createState() => _OrderCheckoutScreenState();
}

class _VendorDraft {
  final String umkmId;
  final String umkmName;
  final String umkmType;
  final List<CartLine> lines;
  final bool isPreOrder;
  final double? courierFee;
  final String pickupLocation;

  DeliveryMethod delivery;
  DateTime? requiredAt;
  final TextEditingController purpose = TextEditingController();
  final TextEditingController note = TextEditingController();

  _VendorDraft({
    required this.umkmId,
    required this.umkmName,
    required this.umkmType,
    required this.lines,
    required this.isPreOrder,
    required this.courierFee,
    required this.pickupLocation,
  }) : delivery =
            courierFee != null ? DeliveryMethod.courier : DeliveryMethod.pickup;

  double get subtotal => lines.fold(0.0, (s, l) => s + l.subtotal);
  double get fee => delivery == DeliveryMethod.courier ? (courierFee ?? 0) : 0;
}

class _OrderCheckoutScreenState extends State<OrderCheckoutScreen> {
  final OrderService _service = OrderService();
  late final List<_VendorDraft> _vendors;

  Recipient _recipient = const Recipient(
    name: 'Muhammad Rizki',
    phone: '0812-3456-7890',
    address: 'Jl. Merpati No. 14, RT 02 / RW 01, Desa Kreyongan Atas',
    addressNote: 'Rumah pagar hijau samping pos ronda desa',
  );

  late PaymentMethod _method;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _method = widget.initialMethod;
    final Map<String, List<CartLine>> grouped = {};
    for (final l in widget.cartLines) {
      grouped.putIfAbsent(l.umkmId, () => []).add(l);
    }
    _vendors = grouped.values.map((lines) {
      final f = lines.first;
      final po = lines.any((l) => l.type == OrderType.preOrder);
      final d = _VendorDraft(
        umkmId: f.umkmId,
        umkmName: f.umkmName,
        umkmType: f.umkmType,
        lines: lines,
        isPreOrder: po,
        courierFee: f.courierFee,
        pickupLocation: f.pickupLocation,
      );
      if (po) {
        final base = DateTime.now().add(const Duration(days: 3));
        d.requiredAt = DateTime(base.year, base.month, base.day, 11, 0);
        d.purpose.text = widget.initialPurpose ?? '';
        d.note.text = widget.initialNote ?? '';
      }
      return d;
    }).toList();
  }

  @override
  void dispose() {
    for (final v in _vendors) {
      v.purpose.dispose();
      v.note.dispose();
    }
    super.dispose();
  }

  double get _subtotal => _vendors.fold(0.0, (s, v) => s + v.subtotal);
  double get _shipping => _vendors.fold(0.0, (s, v) => s + v.fee);
  double get _total => _subtotal + _shipping;
  int get _qty => widget.cartLines.fold(0, (s, l) => s + l.quantity);

  Future<void> _pickDateTime(_VendorDraft v) async {
    final now = DateTime.now();
    final first =
        DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    final current = v.requiredAt ?? first;
    final date = await showDatePicker(
      context: context,
      initialDate: current.isBefore(first) ? first : current,
      firstDate: first,
      lastDate: first.add(const Duration(days: 180)),
      helpText: 'Tanggal dibutuhkan',
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
      helpText: 'Jam dibutuhkan',
    );
    if (time == null || !mounted) return;
    setState(() {
      v.requiredAt =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _editRecipient() async {
    final r = await showRecipientSheet(context, _recipient);
    if (r != null) setState(() => _recipient = r);
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final order = await _service.createOrder(
        lines: widget.cartLines,
        recipient: _recipient,
        paymentMethod: _method,
        options: {
          for (final v in _vendors)
            v.umkmId: VendorCheckout(
              delivery: v.delivery,
              requiredAt: v.requiredAt,
              purpose: v.purpose.text,
              note: v.note.text,
            ),
        },
      );
      if (!mounted) return;
      // Selalu 3 halaman: Checkout -> Proses Checkout -> Status Pesanan.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => _method == PaymentMethod.midtrans
              ? MidtransPaymentScreen(orderId: order.id)
              : OrderPaymentScreen(orderId: order.id),
        ),
      );
    } on OrderException catch (e) {
      if (mounted) showToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ------------------------------------------------------------------ UI

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      body: Column(
        children: [
          const OrderHeader(title: 'Checkout'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
              children: [
                if (_vendors.length > 1) ...[
                  _multiUmkmBanner(),
                  const SizedBox(height: 10),
                ],
                _addressCard(),
                for (final v in _vendors) ...[
                  const SizedBox(height: 10),
                  _vendorCard(v),
                ],
                const SizedBox(height: 10),
                _paymentCard(),
                const SizedBox(height: 10),
                _summaryCard(),
                const SizedBox(height: 12),
                _trustNote(),
              ],
            ),
          ),
          _bottomBar(),
        ],
      ),
    );
  }

  // -------------------------------------------------------------- address

  Widget _addressCard() {
    return OrderCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.location_on_rounded, size: 20, color: OC.primary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _recipient.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: OC.ink,
                        ),
                      ),
                    ),
                    const Pill(
                      text: 'WA Aktif',
                      bg: OC.mint,
                      fg: OC.mintText,
                      fontSize: 10,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _recipient.phone,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: OC.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _recipient.address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: OC.ink,
                  ),
                ),
                if (_recipient.addressNote != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _recipient.addressNote!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontStyle: FontStyle.italic,
                      color: OC.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 4),
          TextButton(
            onPressed: _editRecipient,
            style: TextButton.styleFrom(
              foregroundColor: OC.primary,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              minimumSize: const Size(40, 30),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Ubah',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _multiUmkmBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: OC.banner,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.storefront_outlined, size: 18, color: OC.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Pesanan dari ${_vendors.length} UMKM — pengantaran '
              'dikelompokkan per UMKM.',
              style: const TextStyle(
                fontSize: 12,
                height: 1.3,
                color: OC.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------- vendor / order

  Widget _vendorCard(_VendorDraft v) {
    return OrderCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      v.umkmName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: OC.ink,
                      ),
                    ),
                    Text(
                      v.umkmType,
                      style: const TextStyle(fontSize: 12, color: OC.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              v.isPreOrder
                  ? const Pill(
                      text: 'PRE-ORDER',
                      bg: OC.peach,
                      fg: OC.amber,
                      icon: Icons.hourglass_top_rounded,
                      fontSize: 10,
                    )
                  : const Pill(
                      text: 'PESAN SEKARANG',
                      bg: OC.mint,
                      fg: OC.mintText,
                      icon: Icons.bolt_rounded,
                      fontSize: 10,
                    ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: OC.line),
          const SizedBox(height: 10),
          for (final l in v.lines) _lineTile(l),
          if (v.isPreOrder) ...[
            const SizedBox(height: 4),
            _preOrderForm(v),
          ],
          const SizedBox(height: 12),
          _sectionLabel('Pengantaran'),
          const SizedBox(height: 8),
          if (v.courierFee != null) ...[
            _deliveryOption(
              selected: v.delivery == DeliveryMethod.courier,
              title: 'Diantar Kurir Warga / UMKM',
              subtitle: 'Langsung diantar ke balai / rumah',
              price: '+${rupiah(v.courierFee!)}',
              onTap: () => setState(() => v.delivery = DeliveryMethod.courier),
            ),
            const SizedBox(height: 8),
          ],
          _deliveryOption(
            selected: v.delivery == DeliveryMethod.pickup,
            title: v.courierFee != null
                ? 'Ambil Sendiri (Pickup)'
                : 'Pickup (Ambil Sendiri di Toko)',
            subtitle: v.courierFee != null ? v.pickupLocation : null,
            price: rupiah(0),
            onTap: () => setState(() => v.delivery = DeliveryMethod.pickup),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: OC.line),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Subtotal ${v.umkmName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5, color: OC.muted),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                rupiah(v.subtotal + v.fee),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: OC.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        color: OC.ink,
      ),
    );
  }

  Widget _lineTile(CartLine l) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          NetImage(url: l.imageUrl, width: 56, height: 56, radius: 10),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: OC.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${l.variant} • x${l.quantity} ${l.unit}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: OC.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            rupiah(l.subtotal),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: OC.ink,
            ),
          ),
        ],
      ),
    );
  }

  /// Field pre-order: label di atas, input rata kiri, selebar kartu.
  Widget _preOrderForm(_VendorDraft v) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: OC.peachSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: OC.peach),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.event_note_rounded, size: 16, color: OC.amber),
              SizedBox(width: 6),
              Text(
                'Detail Pre-Order',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: OC.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _fieldLabel('Waktu dibutuhkan'),
          const SizedBox(height: 6),
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _pickDateTime(v),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: OC.line),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_rounded,
                      size: 17, color: OC.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      v.requiredAt == null
                          ? 'Pilih waktu'
                          : fmtDateTime(v.requiredAt!),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: OC.ink,
                      ),
                    ),
                  ),
                  const Icon(Icons.expand_more_rounded,
                      size: 18, color: OC.muted),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          _fieldLabel('Keperluan (opsional)'),
          const SizedBox(height: 6),
          _plainField(
            controller: v.purpose,
            hint: 'Cth: Rapat Desa RT 02',
            formatters: OrderInput.purpose,
          ),
          const SizedBox(height: 10),
          _fieldLabel('Catatan rasa / kemasan'),
          const SizedBox(height: 6),
          _plainField(
            controller: v.note,
            hint: 'Cth: Sambal dipisah, kemangi dipacking rapi',
            formatters: OrderInput.packing,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        color: OC.muted,
      ),
    );
  }

  Widget _plainField({
    required TextEditingController controller,
    required String hint,
    required List<TextInputFormatter> formatters,
    int maxLines = 1,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: OC.line),
      ),
      child: TextField(
        controller: controller,
        inputFormatters: formatters,
        maxLines: maxLines,
        minLines: maxLines,
        textCapitalization: TextCapitalization.sentences,
        style: const TextStyle(fontSize: 13, color: OC.ink),
        decoration: InputDecoration(
          isDense: true,
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 12.5, color: OC.faint),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 11),
        ),
      ),
    );
  }

  Widget _deliveryOption({
    required bool selected,
    required String title,
    String? subtitle,
    required String price,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? OC.mintSoft : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? OC.primary : OC.line,
            width: selected ? 1.2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? OC.primary : OC.faint,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: OC.ink,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11.5, color: OC.muted),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              price,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: selected ? OC.primary : OC.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------- payment

  Widget _paymentCard() {
    return OrderCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TitleRow(
            icon: Icons.payments_outlined,
            title: 'Metode Pembayaran',
          ),
          const SizedBox(height: 10),
          _methodRow(
            method: PaymentMethod.cod,
            icon: Icons.handshake_outlined,
            title: 'Bayar di Tempat (COD)',
            subtitle: 'Titip tunai ke kurir warga',
          ),
          const SizedBox(height: 8),
          _methodRow(
            method: PaymentMethod.midtrans,
            icon: Icons.bolt_rounded,
            title: 'Bayar Sekarang',
            subtitle: 'QRIS, GoPay, ShopeePay, VA',
          ),
        ],
      ),
    );
  }

  Widget _methodRow({
    required PaymentMethod method,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final sel = _method == method;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => setState(() => _method = method),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: sel ? OC.mintSoft : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: sel ? OC.primary : OC.line,
            width: sel ? 1.2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: sel ? OC.primary : OC.muted),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: OC.ink,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11.5, color: OC.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              sel ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              size: 20,
              color: sel ? OC.primary : OC.faint,
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------- summary

  Widget _summaryCard() {
    return OrderCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TitleRow(
            icon: Icons.receipt_long_outlined,
            title: 'Rincian Pembayaran',
          ),
          const SizedBox(height: 6),
          MoneyRow(
            label: 'Subtotal produk ($_qty item)',
            value: rupiah(_subtotal),
          ),
          MoneyRow(
            label: 'Ongkir pengantaran',
            value: _shipping == 0 ? 'Gratis' : rupiah(_shipping),
          ),
          const MoneyRow(
            label: 'Biaya layanan',
            value: 'Gratis',
            color: OC.primary,
          ),
        ],
      ),
    );
  }

  Widget _trustNote() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.verified_user_outlined, size: 15, color: OC.primary),
        SizedBox(width: 6),
        Flexible(
          child: Text(
            'Belanja amanah langsung memajukan tetangga & UMKM desa',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, color: OC.muted),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------- bottom bar

  Widget _bottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        14,
        10,
        14,
        MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: OC.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'TOTAL BAYAR',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: OC.muted,
                  ),
                ),
                Text(
                  rupiah(_total),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: OC.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: OC.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.arrow_forward_rounded, size: 20),
              label: const Text(
                'Buat Pesanan',
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
