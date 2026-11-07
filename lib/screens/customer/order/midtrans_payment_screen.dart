import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../services/api_service.dart';
import '../../../services/order_service.dart';
import 'order_widgets.dart';

class MidtransPaymentScreen extends StatefulWidget {
  final String orderId;
  final String? paymentUrl;

  const MidtransPaymentScreen({
    super.key,
    required this.orderId,
    this.paymentUrl,
  });

  @override
  State<MidtransPaymentScreen> createState() => _MidtransPaymentScreenState();
}

class _MidtransPaymentScreenState extends State<MidtransPaymentScreen> {
  final OrderService _service = OrderService();
  late final WebViewController _controller;
  bool _loading = true;
  bool _loadingUrl = false;
  bool _checkingStatus = false;
  bool _finishDetected = false;
  bool _completed = false;
  String? _errorMessage;
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
              setState(() => _loading = false);
              showToast(
                context,
                'Halaman pembayaran gagal dimuat. Coba refresh atau periksa koneksi.',
                error: true,
              );
            }
          },
        ),
      );

    _resolveAndLoadUrl();
  }

  Future<void> _resolveAndLoadUrl() async {
    String? url = widget.paymentUrl;
    if (url == null || url.isEmpty) {
      final order = _service.findById(widget.orderId);
      url = order?.paymentUrl;
    }

    if (url == null || url.isEmpty) {
      setState(() => _loadingUrl = true);
      try {
        final synced = await _service.syncOrder(widget.orderId);
        url = synced?.paymentUrl;
      } catch (_) {}
      if (mounted) setState(() => _loadingUrl = false);
    }

    if (url == null || url.isEmpty) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Tautan pembayaran Midtrans belum tersedia untuk pesanan ini.';
        });
      }
      return;
    }

    final uri = Uri.parse(url).replace(
      queryParameters: {
        ...Uri.parse(url).queryParameters,
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

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleBackPress() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return;
    }

    if (!mounted) return;
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari Pembayaran?'),
        content: const Text(
          'Pesanan Anda tetap tersimpan di status Menunggu Pembayaran. Anda dapat melanjutkan pembayaran kapan saja dari Detail Pesanan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Lanjutkan Bayar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: OC.primary),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Keluar'),
          ),
        ],
      ),
    );

    if (shouldLeave == true && mounted) {
      Navigator.of(context).pop(_completed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBackPress();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pembayaran Midtrans'),
          backgroundColor: OC.primary,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _handleBackPress,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Muat ulang',
              onPressed: () {
                _resolveAndLoadUrl();
              },
            ),
          ],
        ),
        body: _errorMessage != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.info_outline, size: 52, color: Colors.orange),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: OC.ink,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: OC.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Kembali ke Detail Pesanan'),
                      ),
                    ],
                  ),
                ),
              )
            : Stack(
                children: [
                  WebViewWidget(controller: _controller),
                  if (_loading || _loadingUrl)
                    Container(
                      color: Colors.white,
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: OC.primary),
                            SizedBox(height: 16),
                            Text(
                              'Menghubungkan ke gerbang pembayaran Midtrans...',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: OC.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
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
