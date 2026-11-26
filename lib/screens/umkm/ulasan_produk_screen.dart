import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../widgets/app_network_image.dart';

class UlasanProdukScreen extends StatefulWidget {
  final int umkmId;

  const UlasanProdukScreen({super.key, required this.umkmId});

  @override
  State<UlasanProdukScreen> createState() => _UlasanProdukScreenState();
}

class _UlasanProdukScreenState extends State<UlasanProdukScreen> {
  bool _loading = true;
  String? _error;
  double _average = 0;
  int _total = 0;
  List<Map<String, dynamic>> _reviews = [];

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await ApiService.get(
        'umkm/ulasan',
        query: {'id_umkm': '${widget.umkmId}'},
      );
      if (response is! Map) {
        throw ApiException('Data ulasan produk tidak dapat dibaca.');
      }
      final reviews = response['daftar_ulasan'];
      if (!mounted) return;
      setState(() {
        _average = (response['rata_rata'] as num?)?.toDouble() ?? 0;
        _total = (response['total_ulasan'] as num?)?.toInt() ?? 0;
        _reviews = reviews is List
            ? reviews.whereType<Map>().map(Map<String, dynamic>.from).toList()
            : [];
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.pesan);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F3),
      appBar: AppBar(
        title: const Text('Ulasan Produk'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF17251B),
      ),
      body: RefreshIndicator(
        onRefresh: _loadReviews,
        child: _loading && _reviews.isEmpty
            ? ListView(
                children: [
                  SizedBox(
                    height: 360,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
              )
            : _error != null && _reviews.isEmpty
            ? ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 110),
                  const Icon(Icons.cloud_off_outlined, size: 42),
                  const SizedBox(height: 12),
                  Text(_error!, textAlign: TextAlign.center),
                  TextButton(
                    onPressed: _loadReviews,
                    child: const Text('Coba lagi'),
                  ),
                ],
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _summaryCard(),
                  const SizedBox(height: 12),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  if (_reviews.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Belum ada ulasan untuk produk Anda.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    for (final review in _reviews) ...[
                      _reviewCard(review),
                      const SizedBox(height: 10),
                    ],
                ],
              ),
      ),
    );
  }

  Widget _summaryCard() {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.star_rounded, color: Color(0xFFE7A523), size: 28),
            const SizedBox(width: 10),
            Text(
              _average.toStringAsFixed(1),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 8),
            Text('($_total ulasan produk)'),
          ],
        ),
      ),
    );
  }

  Widget _reviewCard(Map<String, dynamic> review) {
    final orderId = review['id_pesanan']?.toString() ?? '';
    final name = review['nama_produk']?.toString() ?? 'Produk';
    final image = review['gambar_url']?.toString() ?? '';
    final rating = (review['rating'] as num?)?.toInt() ?? 0;
    final customer = review['nama_pelanggan']?.toString() ?? 'Pelanggan';
    final comment = review['komentar']?.toString() ?? '';
    final date = review['tanggal_format']?.toString() ??
        review['tanggal']?.toString() ??
        '';

    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppNetworkImage(
                  url: image,
                  width: 54,
                  height: 54,
                  borderRadius: BorderRadius.circular(10),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      if (orderId.isNotEmpty)
                        Text(
                          'Pesanan $orderId',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF758178),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 22),
            Row(
              children: [
                Expanded(
                  child: Text(
                    customer,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  '${'★' * rating}${'☆' * (5 - rating)}',
                  style: const TextStyle(color: Color(0xFFE7A523)),
                ),
              ],
            ),
            if (date.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                date,
                style: const TextStyle(fontSize: 11, color: Color(0xFF758178)),
              ),
            ],
            if (comment.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(comment),
            ],
          ],
        ),
      ),
    );
  }
}
