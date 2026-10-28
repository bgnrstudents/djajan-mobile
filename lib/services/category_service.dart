import 'package:flutter/foundation.dart' show ChangeNotifier;

import '../models/category.dart';
import 'api_service.dart';

class CategoryService extends ChangeNotifier {
  final List<Category> _categories = [];
  bool _loading = false;
  String? _errorMessage;

  List<Category> get categories => List.unmodifiable(_categories);
  bool get loading => _loading;
  String? get errorMessage => _errorMessage;
  bool get isEmpty => !_loading && _errorMessage == null && _categories.isEmpty;

  Future<void> load() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await ApiService.get('kategori');
      final items = data is List ? data : const [];
      _categories
        ..clear()
        ..addAll(
          items
              .whereType<Map<String, dynamic>>()
              .map(Category.fromJson)
              .where((category) => category.active),
        );
    } on ApiException catch (error) {
      _errorMessage = error.pesan;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
