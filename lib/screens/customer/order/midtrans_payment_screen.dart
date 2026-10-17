import 'package:flutter/material.dart';
import 'order_service.dart';
import 'order_detail_screen.dart';
import '../../../config/app_config.dart';

class MidtransPaymentScreen extends StatefulWidget {
  final String orderId;

  const MidtransPaymentScreen({super.key, required this.orderId});

  @override
  State<MidtransPaymentScreen> createState() => _MidtransPaymentScreenState();
}

class _MidtransPaymentScreenState extends State<MidtransPaymentScreen> {
  final OrderService _orderService = OrderService();
  bool _isLoading = false;

  // Midtrans Colors
  static const Color midtransPrimary = Color(0xFF013293);
  static const Color midtransBlueLight = Color(0xFFE6EDF5);
  static const Color midtransText = Color(0xFF2E3E5C);

  @override
  Widget build(BuildContext context) {
    final order = _orderService.findById(widget.orderId);

    if (order == null) {
      return const Scaffold(body: Center(child: Text('Pesanan tidak ditemukan')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.security, color: midtransPrimary, size: 18),
            const SizedBox(width: 6),
            const Text(
              'MIDTRANS SECURE PAYMENT',
              style: TextStyle(
                color: midtransPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: midtransPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Order Summary Mini Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL PEMBAYARAN',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _formatRupiah(order.total.round()),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: midtransPrimary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: midtransBlueLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    order.refId,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: midtransPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1),

          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: midtransPrimary))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text(
                      'Pilih Metode Pembayaran',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: midtransText,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // E-Wallets
                    _sectionTitle('E-Wallet (GoPay, ShopeePay, dll)'),
                    _paymentTile(
                      icon: Icons.qr_code_scanner,
                      name: 'QRIS',
                      description: 'GoPay, ShopeePay, OVO, Dana & LinkAja',
                      onTap: () => _simulatePayment(context, 'QRIS'),
                    ),
                    _paymentTile(
                      icon: Icons.account_balance_wallet,
                      name: 'GoPay',
                      description: 'Bayar pakai aplikasi Gojek',
                      onTap: () => _simulatePayment(context, 'GoPay'),
                    ),
                    _paymentTile(
                      icon: Icons.shopping_bag,
                      name: 'ShopeePay',
                      description: 'Bayar pakai aplikasi Shopee',
                      onTap: () => _simulatePayment(context, 'ShopeePay'),
                    ),

                    const SizedBox(height: 20),

                    // Bank Transfer (VA)
                    _sectionTitle('Virtual Account (Transfer Bank)'),
                    _paymentTile(
                      icon: Icons.account_balance,
                      name: 'Mandiri Bill Payment',
                      description: 'Konfirmasi otomatis dalam 1 menit',
                      onTap: () => _simulatePayment(context, 'Mandiri VA'),
                    ),
                    _paymentTile(
                      icon: Icons.account_balance,
                      name: 'BCA Virtual Account',
                      description: 'Konfirmasi otomatis dalam 1 menit',
                      onTap: () => _simulatePayment(context, 'BCA VA'),
                    ),
                    _paymentTile(
                      icon: Icons.account_balance,
                      name: 'BNI Virtual Account',
                      description: 'Konfirmasi otomatis dalam 1 menit',
                      onTap: () => _simulatePayment(context, 'BNI VA'),
                    ),

                    const SizedBox(height: 20),

                    // Alfamart/Indomaret
                    _sectionTitle('Gerai Retail'),
                    _paymentTile(
                      icon: Icons.store,
                      name: 'Alfamart',
                      description: 'Bayar di Alfamart / Alfamidi',
                      onTap: () => _simulatePayment(context, 'Alfamart'),
                    ),
                  ],
                ),
          ),

          // Footer info
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock, size: 14, color: Colors.grey.shade400),
                const SizedBox(width: 6),
                Text(
                  'Transaksi Anda dijamin aman & terenkripsi',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _paymentTile({
    required IconData icon,
    required String name,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: midtransBlueLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: midtransPrimary, size: 24),
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: midtransText,
          ),
        ),
        subtitle: Text(
          description,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
        trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
      ),
    );
  }

  Future<void> _simulatePayment(BuildContext context, String method) async {
    setState(() => _isLoading = true);
    
    // Simulate API call to Midtrans or status check
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // In a real app, status check would be done via Webhook or polling
    // Here we simulate a successful payment to the OrderService
    await _orderService.markAsPaidViaMidtrans(widget.orderId);
    
    if (!mounted) return;

    _showSuccessDialog(method);
  }

  void _showSuccessDialog(String method) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 20),
            const Text(
              'Pembayaran Berhasil!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Pembayaran via $method telah diterima oleh sistem Djajan.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppConfig.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(ctx); // Close dialog
                  Navigator.pop(context); // Close Midtrans Screen
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderDetailScreen(orderId: widget.orderId),
                    ),
                  );
                },
                child: const Text('Lihat Pesanan'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatRupiah(int val) {
    return 'Rp ${val.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }
}
