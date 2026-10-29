import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../models/umkm_seller_models.dart';
import 'api_service.dart';

/// Sumber data tunggal untuk role UMKM.
class UmkmDataService extends ChangeNotifier {
  UmkmProfile? _profile;
  final List<Produk> _produkList = [];
  final List<Pesanan> _pesananList = [];
  RingkasanDashboard _ringkasan = const RingkasanDashboard();

  bool _memuat = false;
  String? _pesanError;

  // ------------------------------------------------------------- getter
  UmkmProfile get profile => _profile!;
  bool get sudahLogin => _profile != null;
  List<Produk> get produkList => List.unmodifiable(_produkList);
  List<Pesanan> get pesananList => List.unmodifiable(_pesananList);
  RingkasanDashboard get ringkasan => _ringkasan;
  bool get memuat => _memuat;
  String? get pesanError => _pesanError;

  int get jumlahPoBaru =>
      _pesananList.where((p) => p.status == StatusPesanan.poBaru).length;

  Pesanan? cariPesanan(String idPesanan) {
    for (final p in _pesananList) {
      if (p.idPesanan == idPesanan) return p;
    }
    return null;
  }

  // ------------------------------------------------------------- LOGIN
  Future<void> login(String identifier, String password) async {
    final data = await ApiService.post('login', {
      'identifier': identifier.trim(),
      'password': password,
    });
    final hasil = data as Map<String, dynamic>;
    ApiService.setToken(hasil['token']?.toString());
    _profile = UmkmProfile.fromJson(hasil);
    notifyListeners();
  }

  void loadProfileFromLogin(Map<String, dynamic> data) {
    _profile = UmkmProfile.fromJson(data);
    _pesanError = null;
    notifyListeners();
  }

  // -------------------------------------------------------- REGISTRASI
  Future<String> register({
    required String namaUsaha,
    required String spesialis,
    required String noTelpUsaha,
    required String emailUsaha,
    required String password,
    required String passwordKonfirmasi,
    required String alamat,
  }) async {
    await ApiService.post('register', {
      'nama_usaha': namaUsaha,
      'spesialis': spesialis,
      'no_telp_usaha': noTelpUsaha,
      'email_usaha': emailUsaha,
      'password': password,
      'password_konfirmasi': passwordKonfirmasi,
      'alamat': alamat,
    });
    return 'Akun UMKM berhasil didaftarkan. Menunggu verifikasi admin desa.';
  }

  void logout() {
    ApiService.setToken(null);
    _profile = null;
    _produkList.clear();
    _pesananList.clear();
    _ringkasan = const RingkasanDashboard();
    _pesanError = null;
    notifyListeners();
  }

  // --------------------------------------------------- MUAT SELURUH DATA
  /// Dipanggil saat dashboard dibuka dan setiap kali pengguna menarik layar
  /// untuk refresh (pull-to-refresh).
  Future<void> muatSemua({bool tampilkanLoading = true}) async {
    if (_profile == null) return;
    if (tampilkanLoading) {
      _memuat = true;
      _pesanError = null;
      notifyListeners();
    }

    try {
      final hasil = await Future.wait([
        ApiService.get('produk_list',
            query: {'id_umkm': '${_profile!.idUmkm}'}),
        ApiService.get('pesanan_list',
            query: {'id_umkm': '${_profile!.idUmkm}'}),
        ApiService.get('ringkasan', query: {'id_umkm': '${_profile!.idUmkm}'}),
        ApiService.get('profil_get', query: {'id_umkm': '${_profile!.idUmkm}'}),
      ]);

      _produkList
        ..clear()
        ..addAll((hasil[0] as List)
            .map((e) => Produk.fromJson(e as Map<String, dynamic>)));

      _pesananList
        ..clear()
        ..addAll((hasil[1] as List)
            .map((e) => Pesanan.fromJson(e as Map<String, dynamic>)));

      _ringkasan =
          RingkasanDashboard.fromJson(hasil[2] as Map<String, dynamic>);
      _profile = UmkmProfile.fromJson(hasil[3] as Map<String, dynamic>);
      _pesanError = null;
    } on ApiException catch (e) {
      _pesanError = e.pesan;
    } catch (e) {
      _pesanError = 'Terjadi kesalahan: $e';
    } finally {
      _memuat = false;
      notifyListeners();
    }
  }

  // -------------------------------------------------------- MUAT SATUAN
  Future<void> _muatProduk() async {
    final data = await ApiService.get(
      'produk_list',
      query: {'id_umkm': '${_profile!.idUmkm}'},
    );
    _produkList
      ..clear()
      ..addAll((data as List)
          .map((e) => Produk.fromJson(e as Map<String, dynamic>)));
    await _muatRingkasan();
  }

  Future<void> _muatPesanan() async {
    final data = await ApiService.get(
      'pesanan_list',
      query: {'id_umkm': '${_profile!.idUmkm}'},
    );
    _pesananList
      ..clear()
      ..addAll((data as List)
          .map((e) => Pesanan.fromJson(e as Map<String, dynamic>)));
    await _muatRingkasan();
  }

  Future<void> _muatRingkasan() async {
    final data = await ApiService.get(
      'ringkasan',
      query: {'id_umkm': '${_profile!.idUmkm}'},
    );
    _ringkasan = RingkasanDashboard.fromJson(data as Map<String, dynamic>);
  }

  // =================================================== CRUD PRODUK

  /// CREATE — menyimpan produk baru ke tabel `produk`, beserta fotonya.
  Future<String> tambahProduk({
    required String namaProduk,
    required int idKategori,
    required String kategori,
    required int harga,
    required String deskripsi,
    required ModePenjualan modePenjualan,
    required int stok,
    required int minOrderPO,
    required String waktuMasakPO,
    required bool tampilkanDiWarung,
    XFile? gambar,
  }) async {
    final data = await ApiService.postDenganGambar(
      'produk_create',
      {
        'id_umkm': _profile!.idUmkm,
        'id_kategori': idKategori,
        'nama_produk': namaProduk,
        'kategori': kategori,
        'harga': harga,
        'deskripsi': deskripsi,
        'mode_penjualan': modePenjualan.kodeDb,
        'stok': stok,
        'min_order_po': minOrderPO,
        'waktu_masak_po': waktuMasakPO,
        'status_ketersediaan': tampilkanDiWarung,
      },
      gambar: gambar,
    );

    await _muatProduk();
    notifyListeners();
    return '"${Produk.fromJson(data as Map<String, dynamic>).namaProduk}" tersimpan di database.';
  }

  /// UPDATE — memperbarui baris produk yang sudah ada.
  Future<String> updateProduk({
    required int idProduk,
    required int idKategori,
    required String namaProduk,
    required String kategori,
    required int harga,
    required String deskripsi,
    required ModePenjualan modePenjualan,
    required int stok,
    required int minOrderPO,
    required String waktuMasakPO,
    required bool tampilkanDiWarung,
    XFile? gambarBaru,
  }) async {
    await ApiService.postDenganGambar(
      'produk_update',
      {
        'id_produk': idProduk,
        'id_kategori': idKategori,
        'nama_produk': namaProduk,
        'kategori': kategori,
        'harga': harga,
        'deskripsi': deskripsi,
        'mode_penjualan': modePenjualan.kodeDb,
        'stok': stok,
        'min_order_po': minOrderPO,
        'waktu_masak_po': waktuMasakPO,
        'status_ketersediaan': tampilkanDiWarung,
      },
      gambar: gambarBaru,
    );

    await _muatProduk();
    notifyListeners();
    return '"$namaProduk" berhasil diperbarui.';
  }

  /// Ubah cepat status tayang dari kartu produk di dashboard.
  Future<void> ubahStatusTayang(Produk produk, bool tayang) async {
    await ApiService.post('produk_update', {
      'id_produk': produk.idProduk,
      'status_ketersediaan': tayang,
    });
    await _muatProduk();
    notifyListeners();
  }

  /// Ubah stok langsung dari dashboard tanpa membuka form penuh.
  Future<void> ubahStok(Produk produk, int stokBaru) async {
    await ApiService.post('produk_update', {
      'id_produk': produk.idProduk,
      'stok': stokBaru < 0 ? 0 : stokBaru,
    });
    await _muatProduk();
    notifyListeners();
  }

  /// DELETE — menghapus produk beserta file gambarnya di server.
  Future<String> hapusProduk(Produk produk) async {
    await ApiService.post('produk_delete', {'id_produk': produk.idProduk});
    await _muatProduk();
    notifyListeners();
    return '"${produk.namaProduk}" dihapus dari database.';
  }

  // ============================================ PROFIL & PENGATURAN =====

  /// Menyimpan seluruh pengaturan pembayaran & pengiriman ke tabel `umkm`.
  Future<String> simpanPengaturan({
    required bool tokoAktif,
    required bool transferBankAktif,
    required bool codAktif,
    required String skemaPO,
    required bool pickupAktif,
    required bool kurirWargaAktif,
    required int biayaPengantaran,
  }) async {
    final data = await ApiService.post('profil_update', {
      'id_umkm': _profile!.idUmkm,
      'toko_aktif': tokoAktif,
      'transfer_bank_aktif': transferBankAktif,
      'cod_aktif': codAktif,
      'skema_po': skemaPO,
      'pickup_aktif': pickupAktif,
      'kurir_warga_aktif': kurirWargaAktif,
      'biaya_pengantaran': biayaPengantaran,
    });
    _profile = UmkmProfile.fromJson(data as Map<String, dynamic>);
    notifyListeners();
    return 'Pengaturan tersimpan di database.';
  }

  /// Menyimpan lokasi dapur + pengaturan ongkir berbasis zona jarak ke
  /// tabel `umkm` & `umkm_zona_ongkir`. Validasi lengkap (celah/tumpang
  /// tindih zona, jarak negatif, dsb.) dilakukan di backend (ongkir_simpan)
  /// -- di sini kita cuma mengirim apa adanya.
  Future<String> simpanOngkir({
    double? latitude,
    double? longitude,
    required double radiusGratisKm,
    required double jarakMaksimalKm,
    required List<ZonaOngkir> zonaOngkir,
  }) async {
    final data = await ApiService.post('ongkir_simpan', {
      'id_umkm': _profile!.idUmkm,
      'latitude': latitude,
      'longitude': longitude,
      'radius_gratis_km': radiusGratisKm,
      'jarak_maksimal_km': jarakMaksimalKm,
      'zona': jsonEncode(zonaOngkir.map((z) => z.toJson()).toList()),
    });
    _profile = UmkmProfile.fromJson(data as Map<String, dynamic>);
    notifyListeners();
    return 'Pengaturan ongkir berhasil disimpan ke database.';
  }

  /// Memperbarui identitas usaha (nama, spesialis, alamat, no. telepon).
  Future<String> simpanIdentitasUsaha({
    required String namaUsaha,
    required String spesialis,
    required String alamat,
    required String noTelpUsaha,
  }) async {
    final data = await ApiService.post('profil_update', {
      'id_umkm': _profile!.idUmkm,
      'nama_usaha': namaUsaha,
      'spesialis': spesialis,
      'alamat': alamat,
      'no_telp_usaha': noTelpUsaha,
    });
    _profile = UmkmProfile.fromJson(data as Map<String, dynamic>);
    notifyListeners();
    return 'Identitas usaha berhasil diperbarui.';
  }

  /// Memperbarui data rekening penerima pembayaran.
  Future<String> simpanRekening({
    required String bankKode,
    required String bankNama,
    required String noRekening,
    required String atasNama,
  }) async {
    final data = await ApiService.post('profil_update', {
      'id_umkm': _profile!.idUmkm,
      'bank_kode': bankKode,
      'bank_nama': bankNama,
      'no_rekening': noRekening,
      'atas_nama': atasNama,
    });
    _profile = UmkmProfile.fromJson(data as Map<String, dynamic>);
    notifyListeners();
    return 'Rekening berhasil diperbarui.';
  }

  /// Mengunggah foto profil usaha baru ke server (folder `uploads/profil`).
  Future<String> gantiFotoProfil(XFile gambar) async {
    final data = await ApiService.postDenganGambar(
      'profil_update',
      {'id_umkm': _profile!.idUmkm},
      gambar: gambar,
      namaField: 'foto_profil',
    );
    _profile = UmkmProfile.fromJson(data as Map<String, dynamic>);
    notifyListeners();
    return 'Foto profil usaha berhasil diperbarui.';
  }

  // ==================================================== PESANAN

  /// Menerima pesanan: status berubah di database & stok otomatis berkurang.
  Future<String> terimaPesanan(String idPesanan) async {
    await ApiService.post('pesanan_status', {
      'id_pesanan': idPesanan,
      'status': StatusPesanan.diterima.kodeDb,
    });
    await _muatPesanan();
    await _muatProduk();
    notifyListeners();
    return 'Pesanan $idPesanan diterima. Stok produk sudah disesuaikan.';
  }

  Future<String> tolakPesanan(String idPesanan) async {
    await ApiService.post('pesanan_status', {
      'id_pesanan': idPesanan,
      'status': StatusPesanan.ditolak.kodeDb,
    });
    await _muatPesanan();
    notifyListeners();
    return 'Pesanan $idPesanan ditolak.';
  }

  Future<String> selesaikanPesanan(String idPesanan) async {
    await ApiService.post('pesanan_status', {
      'id_pesanan': idPesanan,
      'status': StatusPesanan.selesai.kodeDb,
    });
    await _muatPesanan();
    notifyListeners();
    return 'Pesanan $idPesanan ditandai selesai.';
  }

  }