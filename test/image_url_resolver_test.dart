import 'package:djajan_mobile/config/api_config.dart';
import 'package:djajan_mobile/utils/image_url_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uploaded image URLs use the Laravel CORS route', () {
    expect(
      resolveImageUrl('/uploads/produk/menu.jpg'),
      '${ApiConfig.baseUrl}/file_gambar/produk/menu.jpg',
    );
    expect(
      resolveImageUrl(
        'http://localhost:8000/Djajan-Website/public/uploads/profil/toko.jpg?size=large',
      ),
      '${ApiConfig.baseUrl}/file_gambar/profil/toko.jpg?size=large',
    );
  });

  test('external image URLs remain unchanged', () {
    const url = 'https://images.example.com/menu.jpg';
    expect(resolveImageUrl(url), url);
  });
}
