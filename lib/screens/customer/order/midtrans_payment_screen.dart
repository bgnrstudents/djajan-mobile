import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../services/api_service.dart';
import '../../../services/order_service.dart';
import 'order_widgets.dart';

class MidtransPaymentScreen extends StatefulWidget {
  final String orderId;

  const MidtransPaymentScreen({super.key, required this.orderId});

  @override
  State<MidtransPaymentScreen> createState() => _MidtransPaymentScreenState();
}

class _MidtransPaymentScreenState extends State<MidtransPaymentScreen> {
  final OrderService _service = OrderService();
  late final WebViewController _controller;
  bool _loading = true;
  bool _checkingStatus = false;
  bool _finishDetected = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onNavigationRequest: (request) {
            if (request.url.contains('/payment/finish')) {
              if (!_finishDetected) {
                _finishDetected = true;
                _checkPaymentStatus();
              }
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onWebResourceError: (error) {
            if (mounted) {
              showToast(
                context,
                'Halaman pembayaran gagal dimuat.',
                error: true,
              );
            }
          },
        ),
      );

    final order = _service.findById(widget.orderId);
    final paymentUrl = order?.paymentUrl;
    if (paymentUrl != null && paymentUrl.isNotEmpty) {
      final uri = Uri.parse(paymentUrl).replace(
        queryParameters: {
          ...Uri.parse(paymentUrl).queryParameters,
          'ngrok-skip-browser-warning': 'true',
        },
      );
      _controller.loadRequest(
        uri,
        headers: const {'ngrok-skip-browser-warning': 'true'},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = _service.findById(widget.orderId);
    if (order == null) {
      return const Scaffold(body: Center(child: Text('Order tidak ditemukan')));
    }
    if (order.paymentUrl == null || order.paymentUrl!.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Link pembayaran belum tersedia.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembayaran Midtrans'),
        backgroundColor: OC.primary,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading) const LinearProgressIndicator(color: OC.primary),
        ],
      ),
    );
  }

  Future<void> _checkPaymentStatus() async {
    if (_checkingStatus) return;
    _checkingStatus = true;
    try {
      String? status;
      for (var attempt = 0; attempt < 4; attempt++) {
        await Future<void>.delayed(Duration(seconds: attempt == 0 ? 2 : 3));
        status = await _service.refreshPaymentStatus(widget.orderId);
        if (status == 'paid' || status == 'settlement') break;
      }
      if (!mounted) return;
      final paid = status == 'paid' || status == 'settlement';
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(paid ? 'Pembayaran berhasil' : 'Pembayaran diproses'),
          content: Text(
            paid
                ? 'Pembayaran sudah diterima. Pesanan menunggu diproses UMKM.'
                : 'Pembayaran sudah dikirim. Status akan diperbarui setelah notifikasi Midtrans diterima.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        ),
      );
      if (mounted) {
        Navigator.of(context).pop(paid);
      }
    } on ApiException catch (error) {
      if (mounted) showToast(context, error.pesan, error: true);
    } finally {
      _checkingStatus = false;
    }
  }
}
