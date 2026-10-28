import 'package:djajan_mobile/models/category.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Category parses the API response shape', () {
    final category = Category.fromJson({
      'id_kategori': 3,
      'nama': 'Camilan',
      'slug': 'camilan',
      'aktif': true,
    });

    expect(category.id, 3);
    expect(category.name, 'Camilan');
    expect(category.slug, 'camilan');
    expect(category.active, isTrue);
  });

  test('Category treats numeric active flags correctly', () {
    expect(
      Category.fromJson({
        'id_kategori': '4',
        'nama': 'Minuman',
        'slug': 'minuman',
        'aktif': 0,
      }).active,
      isFalse,
    );
  });
}
