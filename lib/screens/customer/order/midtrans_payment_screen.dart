import 'dart:async';

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
  bool _completed = false;
  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent('DJajanMobile/1.0')
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (url) {
            if (mounted) setState(() => _loading = false);
            if (url.contains('/payment/finish')) {
              _handleFinishRedirect();
            }
          },
          onNavigationRequest: (request) {
            if (request.url.contains('/payment/finish')) {
              _handleFinishRedirect();
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
      _statusTimer = Timer.periodic(
        const Duration(seconds: 5),
        (_) => _pollPaymentStatus(),
      );
    }
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
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
      final status = await _service.refreshPaymentStatusUntilSettled(
        widget.orderId,
      );

      if (!mounted) return;
      final paid =
          status == 'paid' || status == 'settlement' || status == 'capture';
      if (paid) _completed = true;
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

  void _handleFinishRedirect() {
    if (_finishDetected || !mounted) return;
    _finishDetected = true;
    _checkPaymentStatus();
  }

  Future<void> _pollPaymentStatus() async {
    if (_checkingStatus || _completed || !mounted) return;
    try {
      final status = await _service.refreshPaymentStatus(widget.orderId);
      if (!mounted ||
          (status != 'paid' && status != 'settlement' && status != 'capture')) {
        return;
      }

      _completed = true;
      _statusTimer?.cancel();
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Pembayaran berhasil'),
          content: const Text(
            'Pembayaran sudah diterima. Pesanan menunggu diproses UMKM.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException {
      // The next polling cycle retries while the payment screen is open.
    }
  }
}
