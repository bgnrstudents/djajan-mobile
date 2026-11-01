import 'package:flutter/foundation.dart';

import '../models/customer_settings_models.dart';
import 'api_service.dart';
import 'favorite_service.dart';

class CustomerSettingsService extends ChangeNotifier {
  CustomerSettingsService._();
  static final CustomerSettingsService _instance = CustomerSettingsService._();
  factory CustomerSettingsService() => _instance;

  final List<CustomerAddress> _addresses = [];
  bool loading = false;
  String? errorMessage;

  List<CustomerAddress> get addresses => List.unmodifiable(_addresses);
  CustomerAddress? get primaryAddress {
    for (final address in _addresses) {
      if (address.primary) return address;
    }
    return null;
  }

  Future<void> load() async {
    if (!ApiService.hasToken) return;
    loading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        ApiService.get('pelanggan/alamat_list'),
        ApiService.get('pelanggan/favorit'),
      ]);
      _addresses
        ..clear()
        ..addAll(
          (results[0] as List).map(
            (item) => CustomerAddress.fromJson(item as Map<String, dynamic>),
          ),
        );
      FavoriteService().setFromApi(results[1] as Map<String, dynamic>);
    } on ApiException catch (error) {
      errorMessage = error.pesan;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> saveAddress({
    int? id,
    required String label,
    required String recipient,
    required String phone,
    required String address,
    String note = '',
    bool primary = false,
  }) async {
    final data = await ApiService.post('pelanggan/alamat_simpan', {
      if (id != null) 'id_alamat': id,
      'label': label,
      'nama_penerima': recipient,
      'no_telp': phone,
      'alamat': address,
      'catatan': note,
      'utama': primary,
    });
    final saved = CustomerAddress.fromJson(data as Map<String, dynamic>);
    final index = _addresses.indexWhere((item) => item.id == saved.id);
    if (index >= 0) {
      _addresses[index] = saved;
    } else {
      _addresses.add(saved);
    }
    if (saved.primary) {
      for (var i = 0; i < _addresses.length; i++) {
        if (_addresses[i].id != saved.id) {
          _addresses[i] = CustomerAddress(
            id: _addresses[i].id,
            label: _addresses[i].label,
            recipient: _addresses[i].recipient,
            phone: _addresses[i].phone,
            address: _addresses[i].address,
            note: _addresses[i].note,
          );
        }
      }
    }
    notifyListeners();
  }

  Future<void> deleteAddress(int id) async {
    await ApiService.post('pelanggan/alamat_hapus', {'id_alamat': id});
    _addresses.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  Future<void> setPrimary(int id) async {
    final data = await ApiService.post('pelanggan/alamat_utama', {
      'id_alamat': id,
    });
    final primary = CustomerAddress.fromJson(data as Map<String, dynamic>);
    for (var i = 0; i < _addresses.length; i++) {
      final item = _addresses[i];
      _addresses[i] = CustomerAddress(
        id: item.id,
        label: item.label,
        recipient: item.recipient,
        phone: item.phone,
        address: item.address,
        note: item.note,
        primary: item.id == primary.id,
      );
    }
    notifyListeners();
  }

  void clear() {
    _addresses.clear();
    FavoriteService().clear();
    notifyListeners();
  }
}
