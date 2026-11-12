import 'package:flutter/material.dart';

import '../config/api_config.dart';

/// Helper widget untuk memuat gambar network secara andal di seluruh aplikasi DJajan.
///
/// Fitur:
/// - Otomatis me-resolve host `localhost` / `127.0.0.1` ke host aktif [ApiConfig.baseUrl]
///   (agar gambar tetap tampil saat dites di HP fisik).
/// - Fallback placeholder elegan bernuansa kuliner desa jika gambar gagal dimuat (404/offline).
/// - Loading indicator yang halus.
class AppNetworkImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  const AppNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  });

  /// Mengubah URL gambar dari backend agar selalu bisa diakses perangkat.
  static String? resolveUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return null;
    final trimmed = rawUrl.trim();

    // Jika URL mengarah ke localhost/127.0.0.1 dari laptop
    final uri = Uri.tryParse(trimmed);
    if (uri != null &&
        (uri.host == 'localhost' ||
            uri.host == '127.0.0.1' ||
            uri.host == '10.0.2.2')) {
      final base = Uri.parse(ApiConfig.baseUrl);
      return uri
          .replace(
            scheme: base.scheme,
            host: base.host,
            port: base.hasPort ? base.port : (base.scheme == 'https' ? 443 : 80),
          )
          .toString();
    }

    // Jika URL berupa path relatif
    if (trimmed.startsWith('/uploads/') || trimmed.startsWith('uploads/')) {
      final path = trimmed.startsWith('/') ? trimmed.substring(1) : trimmed;
      return '${ApiConfig.baseUrl}/$path';
    }

    return trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final cleanUrl = resolveUrl(url);

    Widget imageContent;

    if (cleanUrl == null || cleanUrl.isEmpty) {
      imageContent = errorWidget ?? _defaultFallback();
    } else {
      imageContent = Image.network(
        cleanUrl,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ??
              Container(
                width: width,
                height: height,
                color: const Color(0xFFF1F5F9),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      color: const Color(0xFF175D2B),
                    ),
                  ),
                ),
              );
        },
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ?? _defaultFallback();
        },
      );
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageContent,
      );
    }

    return imageContent;
  }

  Widget _defaultFallback() {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFF1F5F9),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_rounded,
              size: (height != null && height! < 60) ? 22 : 32,
              color: const Color(0xFF94A3B8),
            ),
            if (height == null || height! >= 80) ...[
              const SizedBox(height: 4),
              const Text(
                'DJajan',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

