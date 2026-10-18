import 'package:flutter/material.dart';

import 'order_model.dart';
import 'order_service.dart';
import 'order_widgets.dart';
import 'order_confirmation_screen.dart';

/// VERSI NATIVE DJAJAN (IJO TUA)
/// Membuang total UI biru Midtrans agar konsisten dengan branding Djajan.
class MidtransPaymentScreen extends StatefulWidget {
  final String orderId;

  const MidtransPaymentScreen({super.key, required this.orderId});

  @override
  State<MidtransPaymentScreen> createState() => _MidtransPaymentScreenState();
}

class _MidtransPaymentScreenState extends State<MidtransPaymentScreen> {
  final OrderService _service = OrderService();
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final order = _service.findById(widget.orderId);
    if (order == null) return const Scaffold(body: Center(child: Text('Order tidak ditemukan')));

    return Scaffold(
      backgroundColor: OC.bg,
      body: Column(
        children: [
          _buildNativeHeader(order),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              children: [
                _methodSection('DOMPET DIGITAL (E-WALLET)', [
                  _payMethodTile('QRIS (Gopay, ShopeePay, dll)', 'Scan kode QR untuk bayar instan', Icons.qr_code_scanner_rounded),
                  _payMethodTile('GoPay', 'Konfirmasi langsung di aplikasi Gojek', Icons.wallet_membership_outlined),
                  _payMethodTile('ShopeePay', 'Konfirmasi langsung di aplikasi Shopee', Icons.shopping_bag_outlined),
                ]),
                _methodSection('TRANSFER VIRTUAL ACCOUNT', [
                  _payMethodTile('Mandiri Bill Payment', 'Cek otomatis tanpa unggah bukti', Icons.account_balance_rounded),
                  _payMethodTile('BCA Virtual Account', 'Cek otomatis tanpa unggah bukti', Icons.account_balance_rounded),
                  _payMethodTile('BNI Virtual Account', 'Cek otomatis tanpa unggah bukti', Icons.account_balance_rounded),
                ]),
                _methodSection('GERAI RETAIL', [
                  _payMethodTile('Alfamart', 'Tunjukkan kode ke kasir Alfamart', Icons.storefront_rounded),
                  _payMethodTile('Indomaret', 'Tunjukkan kode ke kasir Indomaret', Icons.storefront_rounded),
                ]),
              ],
            ),
          ),
          _buildSecureFooter(),
        ],
      ),
    );
  }

  Widget _buildNativeHeader(Order o) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 10, 16, 24),
      decoration: const BoxDecoration(
        color: OC.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 24),
                onPressed: () => Navigator.pop(context),
              ),
              const Expanded(
                child: Text('PEMBAYARAN DJAJAN PAY', 
                  textAlign: TextAlign.center, 
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.2)
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 20),
          Text('TOTAL YANG HARUS DIBAYAR', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(rupiah(o.total), style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
            child: Text('NO. PESANAN: ${o.refId}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _methodSection(String title, List<Widget> items) {
    return TitledCard(
      title: title,
      child: Column(
        children: List.generate(items.length, (index) {
          return Column(
            children: [
              items[index],
              if (index != items.length - 1) const Divider(height: 1, color: OC.line, indent: 56),
            ],
          );
        }),
      ),
    );
  }

  Widget _payMethodTile(String name, String sub, IconData icon) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      leading: Container(
        width: 44, height: 44, 
        decoration: BoxDecoration(color: OC.primarySoft, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: OC.primary, size: 22),
      ),
      title: Text(name, style: OT.item),
      subtitle: Text(sub, style: OT.caption),
      trailing: const Icon(Icons.chevron_right_rounded, color: OC.line, size: 20),
      onTap: () => _simulatePayment(name),
    );
  }

  Widget _buildSecureFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: OC.line))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.verified_user_rounded, color: OC.primary, size: 14),
          const SizedBox(width: 8),
          Text('Pembayaran aman & terenkripsi oleh Djajan Pay', style: OT.caption.copyWith(fontWeight: FontWeight.bold, color: OC.primary)),
        ],
      ),
    );
  }

  Future<void> _simulatePayment(String method) async {
    if (_busy) return;
    setState(() => _busy = true);
    
    showDialog(
      context: context, 
      barrierDismissible: false,
      builder: (ctx) => Center(child: Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: const CircularProgressIndicator(color: OC.primary)))
    );

    await Future.delayed(const Duration(seconds: 2));
    
    final order = _service.findById(widget.orderId);
    if (order != null) {
      await _service.markAsPaidViaMidtrans(widget.orderId);
      if (!mounted) return;
      Navigator.pop(context);
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => OrderConfirmationScreen(order: order, orderService: _service)));
    }
  }
}
