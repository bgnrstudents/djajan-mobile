class Category {
  final int id;
  final String name;
  final String slug;
  final bool active;

  const Category({
    required this.id,
    required this.name,
    required this.slug,
    required this.active,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: int.tryParse(json['id_kategori']?.toString() ?? '') ?? 0,
      name: json['nama']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      active: json['aktif'] == true || json['aktif'] == 1 || json['aktif'] == '1',
    );
  }
}
