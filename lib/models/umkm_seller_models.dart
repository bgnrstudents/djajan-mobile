/// Model-model berikut merepresentasikan entitas pada ERD:
/// `umkm`, `produk`, `pesanan`, `detail_pesanan`.
/// Setiap model punya factory `fromJson` untuk membaca balasan API PHP.
library;

// =============================================================== UMKM
class UmkmProfile {
  final int idUmkm;
  String namaUsaha;
  String spesialis;
  String deskripsiUsaha;
  String alamat;
  String noTelpUsaha;
  String emailUsaha;
  String? fotoProfilUrl;
  String statusVerifikasi;
  bool tokoAktif;

  // Kebijakan pembayaran
  bool transferBankAktif;
  String bankKode;
  String bankNama;
  String noRekening;
  String atasNama;
  bool codAktif;
  String skemaPO;

  // Layanan & ongkir
  bool pickupAktif;
  bool kurirWargaAktif;
  int biayaPengantaran; // legacy/tarif flat lama, tidak dipakai lagi untuk hitung ongkir

  // Lokasi dapur & ongkir berbasis zona jarak
  double? latitude;
  double? longitude;
  double radiusGratisKm;
  double? jarakMaksimalKm;
  List<ZonaOngkir> zonaOngkir;

  UmkmProfile({
    required this.idUmkm,
    required this.namaUsaha,
    required this.spesialis,
    required this.deskripsiUsaha,
    required this.alamat,
    required this.noTelpUsaha,
    required this.emailUsaha,
    required this.fotoProfilUrl,
    required this.statusVerifikasi,
    required this.tokoAktif,
    required this.transferBankAktif,
    required this.bankKode,
    required this.bankNama,
    required this.noRekening,
    required this.atasNama,
    required this.codAktif,
    required this.skemaPO,
    required this.pickupAktif,
    required this.kurirWargaAktif,
    required this.biayaPengantaran,
    this.latitude,
    this.longitude,
    this.radiusGratisKm = 0,
    this.jarakMaksimalKm,
    this.zonaOngkir = const [],
  });

  bool get terverifikasi => statusVerifikasi == 'terverifikasi';

  /// Lokasi dapur UMKM sudah diisi (dibutuhkan sebelum ongkir bisa dihitung).
  bool get lokasiTersedia => latitude != null && longitude != null;

  factory UmkmProfile.fromJson(Map<String, dynamic> j) => UmkmProfile(
        idUmkm: _int(j['id_umkm']),
        namaUsaha: _str(j['nama_usaha']),
        spesialis: _str(j['spesialis']),
        deskripsiUsaha: _str(j['deskripsi_usaha']),
        alamat: _str(j['alamat']),
        noTelpUsaha: _str(j['no_telp_usaha']),
        emailUsaha: _str(j['email_usaha']),
        fotoProfilUrl: _strOrNull(j['foto_profil_url']) ??
            (_strOrNull(j['foto_profil']) == null
                ? null
                : 'file_gambar/profil/${_strOrNull(j['foto_profil'])}'),
        statusVerifikasi: _str(j['status_verifikasi'], 'terverifikasi'),
        tokoAktif: _bool(j['toko_aktif']),
        transferBankAktif: _bool(j['transfer_bank_aktif']),
        bankKode: _str(j['bank_kode'], 'BRI'),
        bankNama: _str(j['bank_nama']),
        noRekening: _str(j['no_rekening']),
        atasNama: _str(j['atas_nama']),
        codAktif: _bool(j['cod_aktif']),
        skemaPO: _str(j['skema_po']),
        pickupAktif: _bool(j['pickup_aktif']),
        kurirWargaAktif: _bool(j['kurir_warga_aktif']),
        biayaPengantaran: _int(j['biaya_pengantaran']),
        latitude: _doubleOrNull(j['latitude']),
        longitude: _doubleOrNull(j['longitude']),
        radiusGratisKm: _double(j['radius_gratis_km']),
        jarakMaksimalKm: _doubleOrNull(j['jarak_maksimal_km']),
        zonaOngkir: ((j['zona_ongkir'] as List?) ?? [])
            .map((e) => ZonaOngkir.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

// ====================================================== ZONA ONGKIR
/// Satu baris zona ongkir milik satu UMKM.
/// Aturan boundary: berlaku untuk jarak > [jarakMin] sampai <= [jarakMax]
/// (mis. zona ">1-3 KM" berarti jarakMin = 1, jarakMax = 3).
class ZonaOngkir {
  /// null berarti zona baru yang belum pernah tersimpan ke database.
  final int? idZona;
  double jarakMin;
  double jarakMax;
  int biaya;

  ZonaOngkir({
    this.idZona,
    required this.jarakMin,
    required this.jarakMax,
    required this.biaya,
  });

  factory ZonaOngkir.fromJson(Map<String, dynamic> j) => ZonaOngkir(
        idZona: j['id_zona'] == null ? null : _int(j['id_zona']),
        jarakMin: _double(j['jarak_min']),
        jarakMax: _double(j['jarak_max']),
        biaya: _int(j['biaya']),
      );

  /// Bentuk yang dikirim ke `ongkir_simpan.php` (di dalam array `zona`).
  Map<String, dynamic> toJson() => {
        'jarak_min': jarakMin,
        'jarak_max': jarakMax,
        'biaya': biaya,
      };
}

// ============================================================= PRODUK
enum ModePenjualan { ready, preOrder, keduanya }

extension ModePenjualanX on ModePenjualan {
  /// Nilai yang disimpan pada kolom ENUM `mode_penjualan` di MySQL.
  String get kodeDb => switch (this) {
        ModePenjualan.ready => 'ready',
        ModePenjualan.preOrder => 'pre_order',
        ModePenjualan.keduanya => 'keduanya',
      };

  String get label => switch (this) {
        ModePenjualan.ready => 'Ready',
        ModePenjualan.preOrder => 'Pre-Order',
        ModePenjualan.keduanya => 'Ready + PO',
      };

  static ModePenjualan dariDb(String? kode) => switch (kode) {
        'ready' => ModePenjualan.ready,
        'pre_order' => ModePenjualan.preOrder,
        _ => ModePenjualan.keduanya,
      };
}

class Produk {
  final int idProduk;
  final int idUmkm;
  int? idKategori;
  String namaProduk;
  String kategori;
  int harga;
  String deskripsi;
  ModePenjualan modePenjualan;
  int stok;
  int minOrderPO;
  String waktuMasakPO;
  bool tampilkanDiWarung;
  String? gambarUrl;

  Produk({
    required this.idProduk,
    required this.idUmkm,
    this.idKategori,
    required this.namaProduk,
    required this.kategori,
    required this.harga,
    required this.deskripsi,
    required this.modePenjualan,
    required this.stok,
    required this.minOrderPO,
    required this.waktuMasakPO,
    required this.tampilkanDiWarung,
    this.gambarUrl,
  });

  bool get punyaFoto => gambarUrl != null && gambarUrl!.isNotEmpty;

  factory Produk.fromJson(Map<String, dynamic> j) => Produk(
        idProduk: _int(j['id_produk']),
        idUmkm: _int(j['id_umkm']),
        idKategori: j['id_kategori'] == null ? null : _int(j['id_kategori']),
        namaProduk: _str(j['nama_produk']),
        kategori: _str(j['kategori']),
        harga: _int(j['harga']),
        deskripsi: _str(j['deskripsi']),
        modePenjualan: ModePenjualanX.dariDb(j['mode_penjualan'] as String?),
        stok: _int(j['stok']),
        minOrderPO: _int(j['min_order_po']),
        waktuMasakPO: _str(j['waktu_masak_po'], 'H-2 Hari'),
        tampilkanDiWarung: _bool(j['status_ketersediaan']),
        gambarUrl: _strOrNull(j['gambar_url']) ??
            (_strOrNull(j['gambar_produk']) == null
                ? null
                : 'uploads/produk/${_strOrNull(j['gambar_produk'])}'),
      );
}

// ============================================================ PESANAN
enum StatusPesanan { poBaru, diterima, ditolak, selesai }

extension StatusPesananX on StatusPesanan {
  String get kodeDb => switch (this) {
        StatusPesanan.poBaru => 'po_baru',
        StatusPesanan.diterima => 'diterima',
        StatusPesanan.ditolak => 'ditolak',
        StatusPesanan.selesai => 'selesai',
      };

  String get label => switch (this) {
        StatusPesanan.poBaru => 'PO Baru',
        StatusPesanan.diterima => 'Diterima',
        StatusPesanan.ditolak => 'Ditolak',
        StatusPesanan.selesai => 'Selesai',
      };

  static StatusPesanan dariDb(String? kode) => switch (kode) {
        'diterima' => StatusPesanan.diterima,
        'ditolak' => StatusPesanan.ditolak,
        'selesai' => StatusPesanan.selesai,
        _ => StatusPesanan.poBaru,
      };
}

class ItemPesanan {
  final String namaProduk;
  final String satuan;
  final int jumlah;
  final int hargaSatuan;
  final int subtotal;
  final String? gambarUrl;

  ItemPesanan({
    required this.namaProduk,
    required this.satuan,
    required this.jumlah,
    required this.hargaSatuan,
    required this.subtotal,
    this.gambarUrl,
  });

  factory ItemPesanan.fromJson(Map<String, dynamic> j) => ItemPesanan(
        namaProduk: _str(j['nama_produk']),
        satuan: _str(j['satuan'], 'Porsi'),
        jumlah: _int(j['jumlah']),
        hargaSatuan: _int(j['harga_satuan']),
        subtotal: _int(j['subtotal']),
        gambarUrl: _strOrNull(j['gambar_url']),
      );
}

class Pesanan {
  final String idPesanan;
  final String namaPembeli;
  final String noTelp;
  final DateTime tanggalPesan;
  final DateTime? waktuDibutuhkan;
  final DateTime? batasKonfirmasi;
  final String keperluanAcara;
  final String metodePengiriman;
  final String alamatTujuan;
  final String catatan;
  final String metodePembayaran;
  final String statusPembayaran;
  final int biayaPengantaran;
  final int biayaLayanan;
  final int subtotal;
  final int totalHarga;
  final List<ItemPesanan> items;
  StatusPesanan status;

  Pesanan({
    required this.idPesanan,
    required this.namaPembeli,
    required this.noTelp,
    required this.tanggalPesan,
    required this.waktuDibutuhkan,
    required this.batasKonfirmasi,
    required this.keperluanAcara,
    required this.metodePengiriman,
    required this.alamatTujuan,
    required this.catatan,
    required this.metodePembayaran,
    required this.statusPembayaran,
    required this.biayaPengantaran,
    required this.biayaLayanan,
    required this.subtotal,
    required this.totalHarga,
    required this.items,
    required this.status,
  });

  int get totalPorsi => items.fold(0, (s, i) => s + i.jumlah);

  /// Total yang diterima mitra = subtotal item + ongkir + biaya layanan.
  int get totalDiterimaMitra => subtotal + biayaPengantaran + biayaLayanan;

  bool get belumDiputuskan => status == StatusPesanan.poBaru;

  /// Sisa waktu konfirmasi, dihitung dari kolom `batas_konfirmasi` di database.
  Duration get sisaWaktuKonfirmasi {
    if (batasKonfirmasi == null) return Duration.zero;
    final sisa = batasKonfirmasi!.difference(DateTime.now());
    return sisa.isNegative ? Duration.zero : sisa;
  }

  factory Pesanan.fromJson(Map<String, dynamic> j) => Pesanan(
        idPesanan: _str(j['id_pesanan']),
        namaPembeli: _str(j['nama_pembeli'], 'Pelanggan'),
        noTelp: _str(j['no_telp']),
        tanggalPesan: _tanggal(j['tanggal_pesan']) ?? DateTime.now(),
        waktuDibutuhkan: _tanggal(j['waktu_dibutuhkan']),
        batasKonfirmasi: _tanggal(j['batas_konfirmasi']),
        keperluanAcara: _str(j['keperluan_acara'], '-'),
        metodePengiriman: _str(j['metode_pengiriman'], '-'),
        alamatTujuan: _str(j['alamat_tujuan'], '-'),
        catatan: _str(j['catatan']),
        metodePembayaran: _str(j['metode_pembayaran'], '-'),
        statusPembayaran: _str(j['status_pembayaran'], 'belum_bayar'),
        biayaPengantaran: _int(j['biaya_pengantaran']),
        biayaLayanan: _int(j['biaya_layanan']),
        subtotal: _int(j['subtotal']),
        totalHarga: _int(j['total_harga']),
        status: StatusPesananX.dariDb(j['status_pesanan'] as String?),
        items: ((j['items'] as List?) ?? [])
            .map((e) => ItemPesanan.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

// ========================================================== RINGKASAN
class RingkasanDashboard {
  final int totalProduk;
  final int produkTayang;
  final int stokHabis;
  final int pesananBaru;
  final int pesananDiterima;
  final int omzetDiterima;

  const RingkasanDashboard({
    this.totalProduk = 0,
    this.produkTayang = 0,
    this.stokHabis = 0,
    this.pesananBaru = 0,
    this.pesananDiterima = 0,
    this.omzetDiterima = 0,
  });

  factory RingkasanDashboard.fromJson(Map<String, dynamic> j) =>
      RingkasanDashboard(
        totalProduk: _int(j['total_produk']),
        produkTayang: _int(j['produk_tayang']),
        stokHabis: _int(j['stok_habis']),
        pesananBaru: _int(j['pesanan_baru']),
        pesananDiterima: _int(j['pesanan_diterima']),
        omzetDiterima: _int(j['omzet_diterima']),
      );
}

// ============================================ helper parsing yang aman
int _int(dynamic v) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

double _double(dynamic v, [double fallback = 0]) {
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? fallback;
  return fallback;
}

double? _doubleOrNull(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

bool _bool(dynamic v) {
  if (v is bool) return v;
  if (v is int) return v == 1;
  if (v is String) return v == '1' || v.toLowerCase() == 'true';
  return false;
}

String _str(dynamic v, [String fallback = '']) {
  if (v == null) return fallback;
  final s = v.toString();
  return s.isEmpty ? fallback : s;
}

String? _strOrNull(dynamic v) {
  if (v == null) return null;
  final s = v.toString();
  return s.isEmpty ? null : s;
}

DateTime? _tanggal(dynamic v) {
  if (v == null) return null;
  return DateTime.tryParse(v.toString().replaceFirst(' ', 'T'));
}
