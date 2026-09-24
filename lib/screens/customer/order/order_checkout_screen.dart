import 'package:flutter/material.dart';

import 'order_model.dart';
import 'order_service.dart';
import 'order_payment_screen.dart';
import 'order_widgets.dart';

/// Tahap 1 alur pesanan: Checkout (rincian per UMKM, pengantaran, metode bayar).
/// Dipanggil dari Keranjang dengan `cartLines`.
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
    this.initialMethod = PaymentMethod.qris,
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
  int get _qty =>
      widget.cartLines.fold(0, (s, l) => s + l.quantity);

  Future<void> _pickDateTime(_VendorDraft v) async {
    final now = DateTime.now();
    final first = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
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
            builder: (_) => OrderPaymentScreen(orderId: order.id)),
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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                if (_vendors.length > 1) ...[
                  _multiUmkmBanner(),
                  const SizedBox(height: 16),
                ],
                _recipientCard(),
                for (final v in _vendors) ...[
                  const SizedBox(height: 16),
                  _vendorCard(v),
                ],
                const SizedBox(height: 16),
                _paymentMethodCard(),
                const SizedBox(height: 16),
                _summaryCard(),
                const SizedBox(height: 16),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified_user_outlined, size: 18, color: OC.primary),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Belanja amanah langsung memajukan tetangga & UMKM desa',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: OC.muted),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _bottomBar(),
        ],
      ),
    );
  }

  Widget _multiUmkmBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: OC.banner, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          const IconBadge(icon: Icons.storefront_outlined, bg: OC.primary, fg: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pesanan dari ${_vendors.length} UMKM Berbeda',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700, color: OC.ink)),
                const Text(
                    'Sistem mengelompokkan pengantaran per masing-masing UMKM',
                    style: TextStyle(fontSize: 12.5, color: OC.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _recipientCard() {
    return OrderCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TitleRow(
            icon: Icons.location_on_outlined,
            title: 'Kontak & Alamat Penerima',
            trailing: TextButton(
              onPressed: _editRecipient,
              style: TextButton.styleFrom(
                  foregroundColor: OC.primary,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(40, 30)),
              child: const Text('Ubah',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: OC.box, borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(_recipient.name,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: OC.ink)),
                    ),
                    const SizedBox(width: 8),
                    const Pill(
                      text: 'WhatsApp Aktif',
                      bg: OC.mint,
                      fg: OC.mintText,
                      icon: Icons.verified_outlined,
                      fontSize: 11,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.phone_outlined, size: 16, color: OC.primary),
                    const SizedBox(width: 6),
                    Text(_recipient.phone,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: OC.primary)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(_recipient.address,
                    style: const TextStyle(fontSize: 14, color: OC.ink, height: 1.35)),
                if (_recipient.addressNote != null)
                  Text('(${_recipient.addressNote})',
                      style: const TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: OC.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _vendorCard(_VendorDraft v) {
    return OrderCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(
                icon: v.isPreOrder
                    ? Icons.soup_kitchen_outlined
                    : Icons.local_cafe_outlined,
                bg: v.isPreOrder ? OC.peach : OC.mint,
                fg: v.isPreOrder ? OC.amber : OC.mintText,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(v.umkmName,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: OC.ink)),
                    Text(v.umkmType,
                        style: const TextStyle(fontSize: 13, color: OC.muted)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              v.isPreOrder
                  ? const Pill(
                      text: 'PRE-ORDER',
                      bg: OC.peachSoft,
                      fg: OC.amber,
                      icon: Icons.hourglass_top_rounded)
                  : const Pill(
                      text: 'PESAN SEKARANG',
                      bg: OC.mint,
                      fg: OC.mintText,
                      icon: Icons.bolt_rounded),
            ],
          ),
          const SizedBox(height: 12),
          for (final l in v.lines) ...[
            _lineTile(l),
            const SizedBox(height: 8),
          ],
          if (v.isPreOrder) ...[
            const SizedBox(height: 4),
            _preOrderForm(v),
            const SizedBox(height: 14),
          ],
          const Padding(
            padding: EdgeInsets.only(bottom: 8, top: 4),
            child: Text('Opsi Pengantaran UMKM',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: OC.ink)),
          ),
          if (v.courierFee != null)
            _deliveryOption(
              selected: v.delivery == DeliveryMethod.courier,
              title: 'Diantar Kurir Warga / UMKM',
              subtitle: 'Langsung diantar ke balai / rumah',
              price: '+${rupiah(v.courierFee!)}',
              priceColor: OC.ink,
              onTap: () => setState(() => v.delivery = DeliveryMethod.courier),
            ),
          if (v.courierFee != null) const SizedBox(height: 8),
          _deliveryOption(
            selected: v.delivery == DeliveryMethod.pickup,
            title: v.courierFee != null
                ? 'Ambil Sendiri (Pickup)'
                : 'Pickup (Ambil Sendiri di Toko)',
            subtitle: v.courierFee != null ? v.pickupLocation : null,
            price: v.courierFee != null ? 'Rp 0' : 'Gratis (Rp 0)',
            priceColor: v.courierFee != null ? OC.muted : OC.primary,
            onTap: () => setState(() => v.delivery = DeliveryMethod.pickup),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
                color: OC.box, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Expanded(
                  child: Text('Subtotal ${v.umkmName}',
                      style: const TextStyle(fontSize: 14, color: OC.muted)),
                ),
                Text(rupiah(v.subtotal + v.fee),
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: OC.primary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _lineTile(CartLine l) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: OC.box, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          NetImage(url: l.imageUrl, width: 66, height: 66, radius: 10),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.productName,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700, color: OC.ink)),
                Text('${l.variant} • x${l.quantity} ${l.unit}',
                    style: const TextStyle(fontSize: 12.5, color: OC.muted)),
                const SizedBox(height: 4),
                Text(rupiah(l.subtotal),
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: OC.primary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _preOrderForm(_VendorDraft v) {
    const label = TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: OC.ink);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: OC.box, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_month_outlined, size: 18, color: OC.primary),
              const SizedBox(width: 6),
              const Text('Waktu Dibutuhkan:', style: label),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _pickDateTime(v),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      v.requiredAt == null
                          ? 'Pilih waktu'
                          : fmtDateTime(v.requiredAt!),
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: OC.ink),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.groups_outlined, size: 18, color: OC.primary),
              const SizedBox(width: 6),
              const Text('Keperluan (opsional):', style: label),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(8)),
                  child: TextField(
                    controller: v.purpose,
                    inputFormatters: OrderInput.purpose,
                    textAlign: TextAlign.end,
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: 'Cth: Rapat Desa RT 02',
                      hintStyle: TextStyle(fontSize: 12.5, color: OC.faint),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              Icon(Icons.edit_note_rounded, size: 20, color: OC.primary),
              SizedBox(width: 6),
              Text('Catatan Rasa / Kemasan:', style: label),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: TextField(
              controller: v.note,
              inputFormatters: OrderInput.packing,
              maxLines: 2,
              minLines: 2,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(fontSize: 13.5),
              decoration: const InputDecoration(
                hintText: 'Cth: Sambal dipisah, kemangi dipacking rapi',
                hintStyle: TextStyle(fontSize: 13, color: OC.faint),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _deliveryOption({
    required bool selected,
    required String title,
    String? subtitle,
    required String price,
    required Color priceColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? OC.mintSoft : OC.box,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: selected ? OC.primary : OC.faint,
              size: 26,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700, color: OC.ink)),
                  if (subtitle != null)
                    Text(subtitle,
                        style: const TextStyle(fontSize: 12.5, color: OC.muted)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(price,
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: priceColor)),
          ],
        ),
      ),
    );
  }

  Widget _paymentMethodCard() {
    return OrderCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TitleRow(
            icon: Icons.payments_outlined,
            title: 'Metode Pembayaran',
            trailing: Pill(text: 'Praktis', bg: OC.primary, fg: Colors.white),
          ),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _methodTile(
                    method: PaymentMethod.cod,
                    icon: Icons.handshake_outlined,
                    title: 'Bayar di Tempat (COD)',
                    subtitle: 'Titip tunai ke kurir warga',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _methodTile(
                    method: PaymentMethod.qris,
                    icon: Icons.qr_code_2_rounded,
                    title: 'QRIS Warga',
                    subtitle: 'BCA, Mandiri, Dana, GoPay',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _methodTile({
    required PaymentMethod method,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final sel = _method == method;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => setState(() => _method = method),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: sel ? OC.mintSoft : OC.box,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: OC.primary, size: 26),
                Icon(
                  sel ? Icons.check_circle_outline : Icons.radio_button_unchecked,
                  color: sel ? OC.primary : OC.faint,
                  size: 24,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(title,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: OC.ink)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: const TextStyle(fontSize: 12.5, color: OC.muted)),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard() {
    return OrderCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TitleRow(icon: Icons.receipt_long_outlined, title: 'Rincian Pembayaran'),
          const SizedBox(height: 10),
          MoneyRow(label: 'Subtotal Produk ($_qty item)', value: rupiah(_subtotal)),
          MoneyRow(label: 'Total Ongkir Pengantaran', value: rupiah(_shipping)),
          const MoneyRow(
            label: 'Biaya Layanan Aplikasi',
            value: 'Gratis (Desa Berdaya)',
            color: OC.primary,
            labelTrailing: Icon(Icons.eco_outlined, size: 15, color: OC.primary),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, thickness: 2, color: OC.line),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Pembayaran',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: OC.ink)),
                    Text('Sudah termasuk biaya kemasan',
                        style: TextStyle(fontSize: 12.5, color: OC.muted)),
                  ],
                ),
              ),
              Text(rupiah(_total),
                  style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: OC.primary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Color(0x14000000), blurRadius: 14, offset: Offset(0, -3)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('TOTAL BAYAR',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        color: OC.muted)),
                Text(rupiah(_total),
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: OC.primary)),
              ],
            ),
          ),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: OC.primary,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.arrow_forward_rounded),
              label: const Text(
                'Lanjutkan Pesanan',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
