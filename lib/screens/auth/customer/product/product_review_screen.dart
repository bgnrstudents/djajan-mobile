import 'package:flutter/material.dart';

import '../../../../models/order.dart';
import '../../../../services/order_service.dart';
import '../../../../widgets/app_network_image.dart';

class ProductReviewScreen extends StatefulWidget {
  final Order order;
  final OrderVendor vendor;
  final OrderItem item;

  const ProductReviewScreen({
    super.key,
    required this.order,
    required this.vendor,
    required this.item,
  });

  @override
  State<ProductReviewScreen> createState() => _ProductReviewScreenState();
}

class _ProductReviewScreenState extends State<ProductReviewScreen> {
  final OrderService _orderService = OrderService();
  final TextEditingController _commentController = TextEditingController();
  int _rating = 0;
  bool _isSubmitting = false;
  String? _error;

  static const Color _green = Color(0xFF175D2B);
  static const Color _greenSoft = Color(0xFFEAF3EC);
  static const Color _ink = Color(0xFF17251B);
  static const Color _muted = Color(0xFF758178);

  bool get _hasOrderItemId =>
      widget.item.detailId.isNotEmpty && widget.item.productId.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _rating = widget.item.rating ?? 0;
    _commentController.text = widget.item.reviewNote ?? '';
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  String get _ratingLabel => switch (_rating) {
    1 => 'Kurang memuaskan',
    2 => 'Belum sesuai harapan',
    3 => 'Cukup baik',
    4 => 'Memuaskan',
    5 => 'Luar biasa!',
    _ => 'Ketuk bintang untuk memberi nilai',
  };

  Future<void> _submit() async {
    final comment = _commentController.text.trim();
    if (_rating == 0) {
      setState(() => _error = 'Pilih rating bintang terlebih dahulu.');
      return;
    }
    if (comment.isEmpty) {
      setState(() => _error = 'Tuliskan pengalamanmu sebelum mengirim ulasan.');
      return;
    }
    if (!_hasOrderItemId) {
      setState(
        () => _error = 'Ulasan tidak dapat dikirim karena data item pesanan tidak lengkap.',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await _orderService.submitOrderReview(
        orderId: widget.order.id,
        item: widget.item,
        rating: _rating,
        comment: comment,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ReviewSuccessScreen(
            productName: widget.item.productName,
            rating: _rating,
          ),
        ),
      );
    } on OrderException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPreviousReview = widget.item.rating != null;
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7FAF7),
        foregroundColor: _ink,
        elevation: 0,
        centerTitle: false,
        title: Text(
          hasPreviousReview ? 'Ubah Ulasan' : 'Tulis Ulasan',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  _productSummary(),
                  const SizedBox(height: 28),
                  const Text(
                    'Bagaimana rasanya?',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Penilaianmu membantu pelanggan lain memilih.',
                    style: TextStyle(color: _muted, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  _ratingPicker(),
                  const SizedBox(height: 26),
                  const Text(
                    'Ceritakan pengalamanmu',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _commentController,
                    minLines: 5,
                    maxLines: 7,
                    maxLength: 1000,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (_) {
                      if (_error != null) setState(() => _error = null);
                    },
                    decoration: InputDecoration(
                      hintText: 'Bagikan rasa, kualitas, atau hal yang paling kamu sukai...',
                      hintStyle: const TextStyle(
                        color: Color(0xFF9AA59C),
                        height: 1.45,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(16),
                      counterStyle: const TextStyle(color: _muted),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(color: Color(0xFFE5ECE6)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(color: Color(0xFFE5ECE6)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(color: _green, width: 1.5),
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    _errorNotice(_error!),
                  ],
                  if (!_hasOrderItemId) ...[
                    const SizedBox(height: 12),
                    _errorNotice(
                      'Data item pesanan tidak lengkap. Hubungi bantuan Djajan untuk melaporkan masalah ini.',
                    ),
                  ],
                ],
              ),
            ),
            _submitBar(hasPreviousReview),
          ],
        ),
      ),
    );
  }

  Widget _productSummary() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EEE9)),
      ),
      child: Row(
        children: [
          AppNetworkImage(
            url: widget.item.imageUrl,
            width: 76,
            height: 76,
            borderRadius: BorderRadius.circular(14),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.item.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 16,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.storefront_outlined,
                      color: _green,
                      size: 15,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        widget.vendor.umkmName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Pesanan ${widget.order.refId}',
                  style: const TextStyle(color: _muted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ratingPicker() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: _greenSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final value = index + 1;
              final selected = value <= _rating;
              return Semantics(
                button: true,
                label: 'Beri $value bintang',
                child: GestureDetector(
                  onTap: () => setState(() {
                    _rating = value;
                    _error = null;
                  }),
                  child: AnimatedScale(
                    scale: selected ? 1 : 0.9,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutBack,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Icon(
                        selected
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 42,
                        color: selected ? _green : const Color(0xFF9FBAA4),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            child: Text(
              _ratingLabel,
              key: ValueKey(_rating),
              style: const TextStyle(
                color: _green,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorNotice(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFB34335),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF9A372D),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _submitBar(bool hasPreviousReview) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE9EEE9))),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton(
          onPressed: _isSubmitting || !_hasOrderItemId ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: _green,
            disabledBackgroundColor: const Color(0xFFA8BBAA),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 21,
                  height: 21,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.3,
                  ),
                )
              : Text(
                  hasPreviousReview ? 'Simpan Perubahan' : 'Kirim Ulasan',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
        ),
      ),
    );
  }
}

class ReviewSuccessScreen extends StatelessWidget {
  final String productName;
  final int rating;

  const ReviewSuccessScreen({
    super.key,
    required this.productName,
    required this.rating,
  });

  static const Color _green = Color(0xFF175D2B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 112,
                height: 112,
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF3EC),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.rate_review_rounded,
                  color: _green,
                  size: 52,
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Terima Kasih atas Ulasanmu!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF17251B),
                  fontSize: 25,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Ulasanmu untuk $productName membantu UMKM lokal Djajan terus menyajikan yang terbaik.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF758178),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5ECE6)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...List.generate(
                      5,
                      (index) => Icon(
                        index < rating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: _green,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$rating/5',
                      style: const TextStyle(
                        color: _green,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Kembali ke Pesanan',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
