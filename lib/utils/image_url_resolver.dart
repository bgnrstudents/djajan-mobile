import '../config/api_config.dart';

String? resolveImageUrl(String? rawUrl) {
  if (rawUrl == null || rawUrl.trim().isEmpty) return null;

  final value = rawUrl.trim();
  final uri = Uri.tryParse(value);
  if (uri == null) return value;

  final isAbsolute = uri.hasScheme && uri.hasAuthority;
  final path = isAbsolute ? uri.path : value.split('?').first;
  final query = uri.hasQuery ? '?${uri.query}' : '';
  final upload = RegExp(
    r'(?:^|/)uploads/(produk|profil)/([^/]+)$',
  ).firstMatch(path);

  if (upload != null) {
    return '${ApiConfig.baseUrl}/file_gambar/${upload.group(1)}/${upload.group(2)}$query';
  }

  if (isAbsolute) return value;
  return '${ApiConfig.baseUrl}$path$query';
}
