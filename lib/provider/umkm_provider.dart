import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import '../models/umkm_models.dart';
import '../services/umkm_data_service.dart';

/// Provider wrapper untuk UmkmDataService agar bisa digunakan di
/// MultiProvider di main.dart tanpa conflict singleton.
class UmkmProvider with ChangeNotifier {
  final UmkmDataService _service = UmkmDataService();

  UmkmProfile get profile => _service.profile;
  bool get sudahLogin => _service.sudahLogin;
  List<Produk> get produkList => List.unmodifiable(_service.produkList);
  List<Pesanan> get pesananList => List.unmodifiable(_service.pesananList);
  RingkasanDashboard get ringkasan => _service.ringkasan;

  Future<void> login(String identifier, String password) async {
    await _service.login(identifier, password);
    notifyListeners();
  }

  void logout() {
    _service.logout();
    notifyListeners();
  }

  Future<void> muatSemua({bool tampilkanLoading = true}) async {
    await _service.muatSemua(tampilkanLoading: tampilkanLoading);
    notifyListeners();
  }
}