import 'package:flutter/material.dart';

import '../utils/image_url_resolver.dart';

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

  /// Resolve uploaded files through Laravel's CORS-enabled image route.
  static String? resolveUrl(String? rawUrl) => resolveImageUrl(rawUrl);

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
        webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ??
              Container(
                width: width,
                height: height,
                color: const Color(0xFFF3F7F3),
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
                      color: const Color(0xFF047857),
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
      color: const Color(0xFFF3F7F3),
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

