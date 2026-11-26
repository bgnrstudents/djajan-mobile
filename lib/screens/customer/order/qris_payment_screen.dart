import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../../services/api_service.dart';
import '../../../services/order_service.dart';
import 'midtrans_payment_screen.dart';
import 'order_widgets.dart';

class QrisPaymentScreen extends StatefulWidget {
  final String orderId;
  final String? qrCodeUrl;
  final String? qrString;
  final double? totalAmount;
  final DateTime? expiryTime;

  const QrisPaymentScreen({
    super.key,
    required this.orderId,
    this.qrCodeUrl,
    this.qrString,
    this.totalAmount,
    this.expiryTime,
  });

  @override
  State<QrisPaymentScreen> createState() => _QrisPaymentScreenState();
}

class _QrisPaymentScreenState extends State<QrisPaymentScreen> {
  final OrderService _service = OrderService();

  String? _qrCodeUrl;
  String? _qrString;
  double? _totalAmount;
  DateTime? _expiryTime;

  bool _loadingDetails = false;
  bool _downloading = false;
  bool _checkingStatus = false;
  bool _completed = false;
  bool _showHowToPay = false;
  int _imageReloadKey = 0;

  Timer? _statusTimer;
  Timer? _countdownTimer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final existing = _service.findById(widget.orderId);

    _qrCodeUrl = _nonEmpty(widget.qrCodeUrl) ??
        _nonEmpty(existing?.qrCodeUrl) ??
        _nonEmpty(existing?.paymentUrl);
    _qrString = _nonEmpty(widget.qrString) ??
        _nonEmpty(existing?.qrString) ??
        _nonEmpty(existing?.snapToken);
    _totalAmount = widget.totalAmount ?? existing?.total;
    _expiryTime = widget.expiryTime ??
        existing?.expiryTime ??
        existing?.paymentDeadline;

    if (_qrCodeUrl == null || _totalAmount == null || _expiryTime == null) {
      setState(() => _loadingDetails = true);
      try {
        final synced = await _service.syncOrder(widget.orderId);
        if (synced != null && mounted) {
          _qrCodeUrl ??=
              _nonEmpty(synced.qrCodeUrl) ?? _nonEmpty(synced.paymentUrl);
          _qrString ??=
              _nonEmpty(synced.qrString) ?? _nonEmpty(synced.snapToken);
          _totalAmount ??= synced.total;
          _expiryTime ??= synced.expiryTime ?? synced.paymentDeadline;
        }
      } catch (_) {
        // Fallback ditangani pada tampilan error/refresh
      }
      if (mounted) setState(() => _loadingDetails = false);
    }

    _startCountdown();
    _startPolling();
  }

  String? _nonEmpty(String? v) {
    final trimmed = v?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _updateRemaining();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _updateRemaining();
    });
  }

  void _updateRemaining() {
    if (_expiryTime == null) {
      setState(() => _remaining = Duration.zero);
      return;
    }
    final diff = _expiryTime!.difference(DateTime.now());
    setState(() => _remaining = diff.isNegative ? Duration.zero : diff);
  }

  void _startPolling() {
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _pollPaymentStatus(),
    );
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  bool get _isLegacySnapUrl {
    final url = _qrCodeUrl ?? '';
    return url.contains('/snap/');
  }

  String _formatCountdown(Duration d) {
    if (d <= Duration.zero) return '00:00:00';
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Future<void> _handleClose() async {
    if (_completed) {
      if (mounted) Navigator.of(context).pop(true);
      return;
    }

    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Keluar dari Pembayaran?',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        content: const Text(
          'Pesanan Anda tetap tersimpan di status Menunggu Pembayaran. Anda bisa membuka kembali QRIS kapan saja dari halaman Detail Pesanan.',
          style: TextStyle(fontSize: 13.5, color: OC.muted, height: 1.4),
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

  Future<void> _downloadQrImage() async {
    final url = _qrCodeUrl;
    if (url == null || url.isEmpty || _downloading) return;

    setState(() => _downloading = true);
    try {
      if (kIsWeb) {
        final launched = await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );
        if (!mounted) return;
        showToast(
          context,
          launched
              ? 'Gambar QRIS dibuka di tab baru untuk diunduh.'
              : 'Gagal membuka gambar QRIS.',
          error: !launched,
        );
        return;
      }

      final hasAccess = await Gal.hasAccess(toAlbum: false);
      if (!hasAccess) {
        final granted = await Gal.requestAccess(toAlbum: false);
        if (!granted) {
          if (mounted) {
            showToast(
              context,
              'Izin penyimpanan/galeri diperlukan untuk mengunduh QRIS.',
              error: true,
            );
          }
          return;
        }
      }

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        throw Exception('Gagal mengunduh gambar QRIS (HTTP ${response.statusCode})');
      }

      final safeOrderId = widget.orderId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
      await Gal.putImageBytes(
        response.bodyBytes,
        name: 'QRIS_Djajan_$safeOrderId',
      );

      if (mounted) {
        showToast(context, 'Gambar QRIS berhasil disimpan ke Galeri');
      }
    } on GalException catch (e) {
      if (mounted) {
        showToast(context, 'Gagal menyimpan ke galeri: ${e.type.message}', error: true);
      }
    } catch (e) {
      if (mounted) {
        showToast(context, 'Gagal mengunduh QRIS: $e', error: true);
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Future<void> _copyText(String text, String successMessage) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      showToast(context, successMessage);
    }
  }

  Future<void> _checkPaymentStatus({bool popIfPending = false}) async {
    if (_checkingStatus) return;
    setState(() => _checkingStatus = true);
    try {
      final status = await _service.refreshPaymentStatusUntilSettled(
        widget.orderId,
        attempts: 2,
      );
      if (!mounted) return;

      final paid =
          status == 'paid' || status == 'settlement' || status == 'capture';
      if (paid) {
        await _onPaymentConfirmed();
        return;
      }

      if (!popIfPending) {
        showToast(
          context,
          'Pembayaran masih menunggu konfirmasi. Silakan scan / bayar QRIS terlebih dahulu.',
        );
      }
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.pesan, error: true);
    } catch (_) {
      if (mounted) {
        showToast(context, 'Gagal memeriksa status pembayaran.', error: true);
      }
    } finally {
      if (mounted) setState(() => _checkingStatus = false);
    }
  }

  Future<void> _pollPaymentStatus() async {
    if (_checkingStatus || _completed || !mounted) return;
    try {
      final status = await _service.refreshPaymentStatus(widget.orderId);
      if (!mounted) return;
      if (status == 'paid' || status == 'settlement' || status == 'capture') {
        await _onPaymentConfirmed();
      }
    } on ApiException {
      // Abaikan dan lanjutkan polling siklus berikutnya
    } catch (_) {}
  }

  Future<void> _onPaymentConfirmed() async {
    if (_completed) return;
    _completed = true;
    _statusTimer?.cancel();
    _countdownTimer?.cancel();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: OC.primary, size: 26),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Pembayaran Berhasil!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ),
          ],
        ),
        content: const Text(
          'Pembayaran QRIS Anda telah diterima. Pesanan sekarang diteruskan ke UMKM untuk diproses.',
          style: TextStyle(fontSize: 13.5, color: OC.muted, height: 1.4),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: OC.primary),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Lihat Detail Pesanan'),
          ),
        ],
      ),
    );
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final bool isExpired = _expiryTime != null && _remaining == Duration.zero;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _handleClose();
      },
      child: Scaffold(
        backgroundColor: OC.bg,
        appBar: AppBar(
          backgroundColor: OC.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            key: const ValueKey('qris-close-button'),
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Tutup',
            onPressed: _handleClose,
          ),
          title: const Text(
            'Pembayaran QRIS',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Muat ulang',
              onPressed: () {
                setState(() => _imageReloadKey++);
                _checkPaymentStatus();
              },
            ),
          ],
        ),
        body: _loadingDetails
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: OC.primary),
                    SizedBox(height: 14),
                    Text(
                      'Menyiapkan kode QRIS...',
                      style: TextStyle(fontSize: 14, color: OC.muted),
                    ),
                  ],
                ),
              )
            : _isLegacySnapUrl
            ? _buildLegacySnapFallback()
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                child: Column(
                  children: [
                    _buildHeaderTotalCard(isExpired),
                    const SizedBox(height: 14),
                    _buildQrisCard(isExpired),
                    const SizedBox(height: 16),
                    _buildActionButtons(),
                    const SizedBox(height: 16),
                    _buildPollingIndicator(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeaderTotalCard(bool isExpired) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: OC.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Total Tagihan',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: OC.muted,
                  ),
                ),
              ),
              if (_expiryTime != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isExpired ? OC.dangerSoft : OC.peach,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 13,
                        color: isExpired ? OC.danger : OC.amber,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isExpired
                            ? 'Kedaluwarsa'
                            : 'Bayar dalam ${_formatCountdown(_remaining)}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isExpired ? OC.danger : OC.amber,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _totalAmount != null ? rupiah(_totalAmount!) : '-',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: OC.primary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: () => _copyText(widget.orderId, 'Order ID disalin'),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Order ID #${widget.orderId}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: OC.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.copy_rounded, size: 13, color: OC.muted),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrisCard(bool isExpired) {
    final url = _qrCodeUrl;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: OC.line),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.qr_code_2_rounded, color: OC.primary, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Scan QRIS Djajan',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: OC.ink,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: OC.mint,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'QRIS • GPN',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: OC.mintText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: OC.line),
            ),
            child: url == null
                ? const SizedBox(
                    width: 220,
                    height: 220,
                    child: Center(
                      child: Text(
                        'Kode QRIS belum tersedia.\nTekan muat ulang di pojok kanan atas.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12.5, color: OC.muted),
                      ),
                    ),
                  )
                : Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.network(
                        url,
                        key: ValueKey('qris-img-$_imageReloadKey'),
                        width: 240,
                        height: 240,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const SizedBox(
                            width: 240,
                            height: 240,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: OC.primary,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (_, _, _) => SizedBox(
                          width: 240,
                          height: 240,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.broken_image_outlined,
                                size: 42,
                                color: OC.muted,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Gagal memuat gambar QRIS',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: OC.muted,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: () =>
                                    setState(() => _imageReloadKey++),
                                icon: const Icon(Icons.refresh, size: 16),
                                label: const Text('Muat Ulang'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (isExpired)
                        Container(
                          width: 240,
                          height: 240,
                          color: Colors.white.withValues(alpha: 0.85),
                          alignment: Alignment.center,
                          child: const Text(
                            'QRIS Kedaluwarsa',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: OC.danger,
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Mendukung GoPay, OVO, DANA, ShopeePay, LinkAja, & Mobile Banking QRIS',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, color: OC.muted),
          ),
          const Divider(height: 24, color: OC.line),
          InkWell(
            onTap: () => setState(() => _showHowToPay = !_showHowToPay),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.help_outline_rounded, size: 18, color: OC.primary),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Cara Bayar QRIS',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: OC.ink,
                      ),
                    ),
                  ),
                  Icon(
                    _showHowToPay
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: OC.muted,
                  ),
                ],
              ),
            ),
          ),
          if (_showHowToPay) ...[
            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '1. Buka aplikasi e-Wallet atau Mobile Banking Anda.\n'
                '2. Pilih Scan QRIS, lalu scan kode di atas (atau Download Gambar QRIS untuk unggah dari galeri).\n'
                '3. Untuk uji coba Midtrans Sandbox Simulator, tekan "Salin Link QRIS" lalu tempel di simulator.\n'
                '4. Setelah membayar, tekan "Cek Status Pembayaran" atau tunggu verifikasi otomatis.',
                style: TextStyle(fontSize: 12, color: OC.muted, height: 1.5),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final hasUrl = _qrCodeUrl != null && _qrCodeUrl!.isNotEmpty;
    final hasQrString = _qrString != null && _qrString!.isNotEmpty;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                key: const ValueKey('qris-download-button'),
                onPressed: hasUrl && !_downloading ? _downloadQrImage : null,
                icon: _downloading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: OC.primary,
                        ),
                      )
                    : const Icon(Icons.download_rounded, size: 18),
                label: Text(
                  _downloading ? 'Menyimpan...' : 'Download QRIS',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: OC.primary,
                  side: const BorderSide(color: OC.primary),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                key: const ValueKey('qris-copy-link-button'),
                onPressed: hasUrl
                    ? () => _copyText(
                          _qrCodeUrl!,
                          'Link QRIS disalin, siap ditempel di Sandbox Simulator',
                        )
                    : null,
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text(
                  'Salin Link QRIS',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: OC.primary,
                  side: const BorderSide(color: OC.primary),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (hasQrString) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => _copyText(
                _qrString!,
                'String payload QRIS berhasil disalin',
              ),
              icon: const Icon(Icons.qr_code_rounded, size: 16),
              label: const Text(
                'Salin Payload QR String (EMV)',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
              style: TextButton.styleFrom(foregroundColor: OC.muted),
            ),
          ),
        ],
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton.icon(
            key: const ValueKey('qris-check-status-button'),
            onPressed: _checkingStatus ? null : () => _checkPaymentStatus(),
            icon: _checkingStatus
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.verified_outlined, size: 19),
            label: Text(
              _checkingStatus ? 'Memeriksa status...' : 'Cek Status Pembayaran',
              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: OC.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: _handleClose,
            child: const Text(
              'Tutup & Bayar Nanti',
              style: TextStyle(color: OC.muted, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPollingIndicator() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 13,
          height: 13,
          child: CircularProgressIndicator(strokeWidth: 2, color: OC.primary),
        ),
        SizedBox(width: 8),
        Text(
          'Menunggu konfirmasi pembayaran otomatis...',
          style: TextStyle(fontSize: 11.5, color: OC.muted),
        ),
      ],
    );
  }

  Widget _buildLegacySnapFallback() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long_rounded, size: 52, color: OC.primary),
            const SizedBox(height: 14),
            const Text(
              'Pesanan ini menggunakan tautan pembayaran versi sebelumnya.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: OC.ink),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: OC.primary),
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => MidtransPaymentScreen(
                      orderId: widget.orderId,
                      paymentUrl: _qrCodeUrl,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: const Text('Lanjutkan Pembayaran'),
            ),
          ],
        ),
      ),
    );
  }
}
