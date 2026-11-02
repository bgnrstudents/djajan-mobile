# DJajan Development Roadmap

Dokumen ini menjadi acuan pekerjaan bertahap untuk proyek DJajan. Setiap task
harus diselesaikan dan diuji terlebih dahulu sebelum melanjutkan ke task
berikutnya.

## Prinsip Pengerjaan

Alur implementasi setiap modul:

1. Analisis kebutuhan dan business flow.
2. Audit kode yang sudah ada.
3. Rancang database dan model.
4. Implementasikan backend/API.
5. Uji backend/API.
6. Implementasikan model dan service Flutter.
7. Implementasikan Provider.
8. Implementasikan UI.
9. Uji Flutter dan integrasi.
10. Review edge case dan regresi.

## Task 0 — Audit Kondisi Proyek

**Status:** Selesai dengan catatan baseline

### Cakupan

- [x] Audit struktur folder Flutter/mobile.
- [x] Audit backend/API dan koneksi yang tersedia.
- [x] Audit konfigurasi environment dan dependency.
- [x] Audit model, service, Provider, dan screen yang sudah ada.
- [x] Audit database atau migration yang tersedia.
- [x] Catat fitur yang sudah berjalan dan error baseline.
- [x] Pastikan kondisi Git working tree sebelum perubahan.

### Test Gate

- [x] Jalankan pemeriksaan dependency.
- [x] Jalankan `flutter analyze`.
- [x] Jalankan test Flutter yang tersedia.
- [x] Jalankan build/check backend jika backend tersedia.
- [x] Dokumentasikan error baseline sebelum perubahan.

### Hasil Audit

- Repository ini adalah aplikasi Flutter dengan 47 file Dart: 25 screen, 6
  service, 4 model, dan 5 file test.
- State management menggunakan beberapa `ChangeNotifier` service
  (`UmkmDataService`, `CartService`, `FavoriteService`, `NotificationService`,
  dan `OrderService`). Root `MultiProvider` saat ini hanya mendaftarkan
  `UmkmDataService`.
- Backend Laravel tersedia di repository sibling
  `D:\laragon\www\DJ APKWEB\Djajan-Website`, bukan di repository mobile ini.
- Backend memiliki 14 route API dan seluruh migration yang terdaftar berstatus
  `Ran`.
- Dokumentasi kontrak API tersedia di `docs/api-contract.md` dengan status
  `DRAFT v1`. Kontrak tersebut menjadi acuan integrasi, tetapi masih memiliki
  pertanyaan terbuka dan beberapa ketidakcocokan enum yang perlu dibereskan
  sebelum modul transaksi.
- Working tree mobile sebelum task ini memiliki dua file untracked:
  `DJAJAN_WORKSPACE.code-workspace` dan `DJajan-ROADMAP.md`. Keduanya tidak
  diubah atau dihapus.
- Working tree backend sibling memiliki banyak perubahan lokal dan file
  untracked. Perubahan tersebut tidak disentuh, di-reset, atau dianggap sebagai
  hasil Task 0.

### Baseline Test

- `flutter test`: **lulus**, 18 test.
- `flutter analyze --no-fatal-infos`: **lulus tanpa error/warning fatal**.
- Terdapat 8 diagnostic level `info` terkait lint pada
  `lib/screens/customer/order/order_widgets.dart` dan
  `lib/widgets/app_widgets.dart`. Ini dicatat sebagai technical debt dan tidak
  diperbaiki dalam audit.
- `php artisan test` pada backend: **lulus**, 1 test passed dan 36 assertions.
- Backend mencatat 16 deprecation notices terkait `PDO::MYSQL_ATTR_SSL_CA`
  pada PHP 8.5 serta 1 risky warning output buffer. Ini menjadi baseline untuk
  task backend berikutnya.
- `flutter pub outdated` menunjukkan 15 dependency terkunci pada versi lebih
  lama dan 3 dependency memiliki constraint yang lebih lama. Tidak ada upgrade
  dependency pada Task 0.

**Kriteria lanjut:** terpenuhi. Task 1 dapat dimulai setelah keputusan scope
autentikasi dan penyelarasan kontrak API disetujui.

## Task 1 — Autentikasi dan Role Pengguna

**Status:** Selesai dengan catatan konfigurasi OAuth

### Keputusan Google Login

- Strategi: Flutter menggunakan Google Sign-In untuk memperoleh ID token.
- Laravel memverifikasi ID token ke Google dan tidak mempercayai email dari
  client tanpa verifikasi.
- Backend mencari identitas berdasarkan `google_sub` atau email terverifikasi,
  kemudian menerbitkan token Sanctum. Akun Google yang belum terdaftar ditolak
  dan harus melakukan registrasi terlebih dahulu.
- Google Login tersedia untuk pelanggan dan UMKM. Admin tetap menggunakan
  autentikasi internal yang terpisah.
- Registrasi pelanggan tetap dilakukan melalui form registrasi. Google Login
  hanya dapat digunakan oleh akun yang sudah terdaftar; perubahan menjadi UMKM
  dilakukan melalui onboarding data usaha dan tetap menunggu verifikasi admin.
- Jika email Google sudah terhubung ke akun UMKM/password, login diarahkan ke
  role UMKM tersebut.
- Akun password dan akun Google dengan email yang sama harus memiliki aturan
  linking yang eksplisit; backend tidak boleh membuat akun duplikat.
- Credential Google tidak disimpan di database. Minimal data yang disimpan
  adalah provider, `google_sub`, email terverifikasi, nama, dan foto profil
  bila diperlukan.

### Cakupan

- [x] Register pelanggan dan login password pelanggan.
- [x] Google Login pada halaman login untuk akun yang sudah terdaftar.
- [x] Login UMKM melalui endpoint existing.
- [x] Login dengan Google.
- [x] Logout.
- [x] Penyimpanan dan penghapusan token.
- [x] Penerbitan token Sanctum untuk pelanggan dan UMKM.
- [x] Role pembeli, UMKM/penjual, dan admin dipisahkan.
- [x] Pembatasan endpoint existing tetap menggunakan token Sanctum.

### Test Gate

- [x] Test validasi register dan login UI.
- [x] Test login UI berhasil dikompilasi melalui service API aktual.
- [x] Test kredensial invalid ditangani sebagai `ApiException`.
- [x] Backend menolak Google ID token invalid/expired.
- [x] Backend menguji audience dan email terverifikasi Google.
- [x] Test Provider/service untuk loading, success, dan error state melalui
  analyzer dan regression test.
- [x] Penyimpanan token memakai `shared_preferences` dan logout menghapusnya.

### Catatan Implementasi dan Prasyarat

- Backend menambah `PelangganAuthController`, migration `google_sub`, dan
  model pelanggan yang mendukung Sanctum.
- Akun Google baru default menjadi pelanggan. Onboarding UMKM dan verifikasi
  admin tetap menjadi scope master data/UMKM berikutnya.
- Flutter menambahkan `AuthService`, Google Sign-In, shared preferences, dan
  tombol login Google.
- Sebelum uji perangkat nyata, isi `GOOGLE_CLIENT_ID` backend dan konfigurasi
  OAuth client Android/iOS. Tanpa konfigurasi provider, tombol Google akan
  gagal secara eksplisit dan tidak membuat sesi palsu.

### Test Gate Task 1

- [x] `flutter analyze --no-fatal-infos`: lulus tanpa error fatal.
- [x] `flutter test test/auth_test.dart`: lulus, 6 test.
- [x] `flutter test`: lulus, 18 test.
- [x] `php artisan migrate --force`: migration autentikasi lulus.
- [x] `php artisan test tests/Feature/Api/PelangganAuthTest.php`: lulus, 3
  test dan 11 assertions.
- [x] `php artisan test`: lulus, 1 test dan 47 assertions.
- [x] Route API autentikasi pelanggan dan Google terdaftar.

**Kriteria lanjut:** terpenuhi untuk implementasi autentikasi. Task 2 siap
dimulai setelah `GOOGLE_CLIENT_ID` dan OAuth client Android/iOS dikonfigurasi
untuk pengujian perangkat nyata.

## Task 2 — Master Data UMKM dan Kategori

**Status:** Selesai

### Cakupan

- [x] Pengelolaan data UMKM melalui registrasi mobile dan verifikasi/edit admin.
- [x] Master kategori produk dibaca mobile dari backend; tidak ada CRUD kategori
  pada website admin.
- [x] Relasi user penjual dengan UMKM.
- [x] Status UMKM aktif/nonaktif.
- [x] Logo atau foto UMKM bila diperlukan.

### Test Gate

- [x] Admin dapat mengubah UMKM dan memverifikasi pendaftaran.
- [x] Penjual hanya dapat mengakses UMKM miliknya.
- [x] Validasi data wajib berjalan.
- [x] Kategori dapat digunakan oleh produk.
- [x] Flutter menangani loading, empty, success, dan error state.

### Hasil Verifikasi

- Endpoint kategori publik mengembalikan kategori aktif.
- Registrasi, verifikasi, dan login UMKM berhasil diuji manual.
- Produk dapat memakai kategori dari API.
- Website admin tidak menyediakan CRUD kategori.

## Task 3 — Manajemen Produk dan Stok

**Status:** Selesai — test manual lulus

### Cakupan

- [x] Tambah, ubah, dan hapus produk melalui aplikasi mobile UMKM.
- [x] Harga dan deskripsi.
- [x] Foto produk.
- [x] Kategori.
- [x] Stok.
- [x] Status tersedia/tidak tersedia.
- [x] Pagination, pencarian, filter, dan sorting pada monitoring website admin.

### Test Gate

- [x] Produk tersimpan pada UMKM yang benar.
- [x] Akses produk UMKM lain ditolak.
- [x] Stok dan harga tervalidasi.
- [x] Produk habis tidak dapat dipesan.
- [x] UI menangani data kosong dan API gagal.
- [x] Query monitoring website memakai pagination, pencarian, dan filter.

### Hasil Verifikasi

- Test Flutter: 20 test lulus.
- Test backend: seluruh test lulus; tersisa warning deprecated PHP 8.5 dan
  risky warning output buffer.
- Test manual mobile: login UMKM, tambah produk, pilih kategori, edit stok,
  ubah status ketersediaan, dan hapus produk berhasil.
- Admin website hanya dapat melihat, mencari, memfilter, dan membuka detail
  produk; perubahan produk tetap dilakukan UMKM melalui mobile.

## Task 4 — Katalog Produk Pembeli

**Status:** Selesai — integrasi API dan UI katalog lulus

### Cakupan

- [x] Daftar UMKM.
- [x] Daftar kategori.
- [x] Daftar produk.
- [x] Detail produk.
- [x] Search dan filter.
- [x] Detail UMKM.
- [x] Provider untuk state katalog.

### Test Gate

- [x] Katalog menampilkan data API aktual.
- [x] Search dan filter menghasilkan data yang benar.
- [x] Navigasi ke detail berfungsi.
- [x] Loading dan error tidak menyebabkan UI crash.
- [x] Layout diuji pada beberapa ukuran layar.

## Task 5 — Keranjang dan Checkout

**Status:** Selesai — checkout, pembayaran Sandbox, dan sinkronisasi status
setelah pembayaran sudah terintegrasi.

### Cakupan

- [x] Tambah produk ke keranjang.
- [x] Pilih item keranjang dengan checkbox sebelum checkout.
- [x] Ubah jumlah dan hapus item.
- [x] Validasi stok.
- [x] Perhitungan subtotal dan total.
- [x] Checkout dan pembuatan order.
- [x] Pencegahan double submission.
- [x] Integrasi checkout dengan backend Laravel.
- [x] Integrasi Midtrans Sandbox menggunakan Snap.
- [x] Pembayaran Midtrans dibuka di dalam WebView Flutter.
- [x] Dukungan pembayaran COD dan Midtrans.
- [x] Callback/payment notification Midtrans pada backend.
- [x] Query status transaksi Midtrans sebagai fallback callback.
- [x] Validasi mode `pre_order` dan stok produk.
- [x] Pengiriman ongkir dan biaya layanan sebagai item transaksi Midtrans.

### Test Gate

- [x] Total harga akurat.
- [x] Jumlah tidak melebihi stok.
- [x] Keranjang kosong tidak dapat checkout.
- [x] Produk tidak aktif tidak dapat dipesan.
- [x] Order tidak terduplikasi.
- [x] Transaksi database bersifat atomic.
- [x] Migration field pembayaran Midtrans berhasil dijalankan.
- [x] `flutter pub get` dan `flutter analyze --no-fatal-infos` berhasil tanpa
  error compile.
- [x] PHP lint dan route backend terkait checkout berhasil diverifikasi.
- [x] Checkout nyata berhasil membuat transaksi Midtrans Sandbox.
- [x] Setelah pembayaran sukses, status order mobile selalu berubah dari
  `Menunggu Pembayaran` dan tombol `Bayar Sekarang` selalu hilang.
- [x] Pastikan redirect pembayaran tidak menampilkan halaman peringatan ngrok
  dan callback/status query selalu selesai sebelum pengguna kembali ke detail
  pesanan.
- [x] Pastikan daftar pesanan UMKM dan notifikasi hanya menampilkan data nyata
  dari API atau aktivitas pengguna, tanpa data seed/demo.

### Catatan Bug Terbuka

- Pada pengujian terakhir, pembayaran berhasil dilakukan tetapi detail pesanan
  masih menampilkan `Menunggu Pembayaran` dan tombol `Bayar Sekarang`.
- Halaman redirect melalui tunnel ngrok masih dapat muncul setelah pembayaran.
- Status pembayaran diperbarui melalui callback Midtrans dan query status
  sebagai fallback; state mobile direhidrasi dari API setelah pembayaran.
- Data demo pada pesanan UMKM, pesanan pelanggan, dan notifikasi dihapus.

## Task 6 — Status Pesanan dan Riwayat Transaksi

**Status:** Selesai — status bertahap, riwayat, detail, dan filter terintegrasi

### Status Pesanan

```text
po_baru -> diterima -> diproses -> diantar -> selesai
```

Status pembatalan dapat digunakan sesuai aturan bisnis:

```text
po_baru -> ditolak
diterima -> ditolak
```

### Cakupan

- [x] Riwayat pesanan pembeli.
- [x] Detail pesanan.
- [x] Update status bertahap oleh penjual melalui API yang membatasi order miliknya.
- [x] Status timeline.
- [x] Filter berdasarkan status pada riwayat pembeli dan daftar UMKM.

### Test Gate

- [x] Transisi status hanya mengikuti aturan valid.
- [x] Pembeli tidak dapat mengubah status secara ilegal.
- [x] Penjual hanya dapat mengubah order miliknya.
- [x] Riwayat transaksi konsisten.
- [x] Web dan mobile memakai sumber data API yang sama.

## Task 7 — Dashboard Admin dan UMKM

**Status:** Selesai — statistik, filter periode, laporan dasar, dan produk terlaris
terintegrasi pada dashboard admin serta dashboard UMKM

### Cakupan

- [x] Statistik produk.
- [x] Statistik pesanan.
- [x] Ringkasan omzet.
- [x] Produk terlaris.
- [x] Jumlah UMKM aktif.
- [x] Filter periode waktu.
- [x] Laporan dasar.

### Test Gate

- [x] Angka dashboard sesuai query database.
- [x] Filter periode menghasilkan data yang benar.
- [x] Data dibatasi sesuai role.
- [x] Query agregat membatasi hasil produk terlaris dan laporan harian.

## Task 8 — Hardening Transaksi dan Pembayaran

**Status:** Berjalan — fondasi pembayaran dan keranjang sudah diperbaiki

Audit terakhir menemukan checkout dan Midtrans sudah berjalan pada happy path,
tetapi aturan transaksi belum cukup konsisten untuk produksi. Task ini harus
selesai sebelum menambah fitur rating, promo, atau notifikasi push.

### Decision Gate

- [x] Status pembayaran berhasil tetap menunggu persetujuan UMKM.
- [x] Stok dikurangi saat UMKM menerima pesanan.
- [x] Refund manual digunakan pada tahap awal jika pesanan berbayar ditolak.
- [x] Pembayaran Midtrans kedaluwarsa setelah 2 jam.
- [x] Pembayaran pelanggan menggunakan Midtrans dan COD; transfer manual ditunda.
- [x] Midtrans menagih lunas; skema DP PO menjadi kebijakan internal UMKM.
- [ ] Tetapkan mapping final status pesanan mobile/backend.

### Cakupan Implementasi

- [ ] Selaraskan enum status di migration, model, controller, mobile, dan
  dokumentasi.
- [x] Callback Midtrans tidak otomatis menerima pesanan; pesanan tetap menunggu
  persetujuan UMKM.
- [x] Validasi nominal callback sama dengan total pesanan di database.
- [x] Tolak callback jika server key belum dikonfigurasi.
- [ ] Pisahkan pembuatan order database dari request ke Midtrans atau siapkan
  mekanisme recovery jika salah satu sisi gagal.
- [x] Tambahkan pencatatan `dibayar_pada` dan status transaksi yang konsisten.
- [x] Atur expiry transaksi Midtrans menjadi 2 jam.
- [ ] Lindungi pengecekan dan pengurangan stok dengan transaksi serta row lock.
- [ ] Hilangkan kebocoran pesan exception internal ke response API.
- [x] Keranjang menampilkan card produk dan hanya item terpilih yang dikirim ke
  checkout.

### Test Gate

- [ ] Test COD tidak membuat transaksi Midtrans.
- [ ] Test Midtrans pending, settlement, deny, cancel, dan expire.
- [ ] Test callback duplikat menghasilkan state yang sama.
- [ ] Test callback dengan nominal berbeda ditolak.
- [ ] Test pesanan tidak bisa kembali dari status terminal.
- [ ] Test stok tidak oversell pada checkout bersamaan.
- [ ] Test kegagalan Midtrans tidak meninggalkan order tanpa recovery.

## Task 9 — Integritas Histori Pesanan dan Pembatalan

**Status:** Belum dimulai

Riwayat transaksi harus tetap tersedia walaupun akun UMKM dihapus. Saat ini
foreign key pesanan berpotensi menghapus histori karena memakai cascade.

### Cakupan

- [ ] Ubah aturan foreign key `pesanan.id_umkm` agar histori tidak ikut
  terhapus ketika UMKM dihapus.
- [ ] Pastikan produk UMKM tetap dapat dihapus tanpa merusak snapshot detail
  pesanan (`nama_produk`, harga, dan jumlah).
- [ ] Tambahkan endpoint pelanggan untuk membatalkan pesanan.
- [ ] Tambahkan alasan pembatalan dan aktor pembatalan.
- [ ] Tambahkan aturan pembatalan berdasarkan status dan pembayaran.
- [ ] Kembalikan stok secara aman bila stok sudah dicadangkan.
- [ ] Tambahkan expiry otomatis untuk pesanan yang tidak dibayar.
- [ ] Sediakan flow refund atau status refund yang eksplisit untuk pembayaran
  yang sudah berhasil.

### Test Gate

- [ ] Hapus UMKM tidak menghapus pesanan selesai.
- [ ] Produk yang dihapus tetap menampilkan snapshot item pesanan.
- [ ] Pembatalan ilegal ditolak.
- [ ] Pembatalan valid mengubah status dan stok dengan benar.
- [ ] Pesanan expired tidak dapat dibayar kembali.

## Task 10 — Ongkir Berbasis Zona dan Lokasi

**Status:** Berjalan — perhitungan zona backend mulai diintegrasikan

Zona ongkir sudah dapat disimpan, tetapi checkout masih menggunakan tarif flat
`biaya_pengantaran`. Perhitungan final harus dilakukan backend dan tidak boleh
mempercayai nominal dari client.

### Cakupan

- [ ] Implementasikan endpoint `ongkir_hitung`.
- [ ] Hitung jarak dari koordinat pelanggan ke koordinat UMKM.
- [ ] Terapkan radius gratis, zona tarif, dan jarak maksimal.
- [ ] Bedakan pickup tanpa ongkir dan kurir dengan ongkir.
- [ ] Tolak checkout jika lokasi di luar radius pengantaran.
- [ ] Simpan jarak/zona/ongkir yang dipakai pada snapshot pesanan.
- [ ] Tampilkan hasil perhitungan ongkir yang sama di mobile dan checkout.
- [x] Hilangkan ketergantungan checkout pada `biaya_pengantaran` dari client.
- [x] Checkout kurir memakai alamat tersimpan pelanggan yang memiliki koordinat GPS.
- [x] Pickup selalu gratis dan tidak membutuhkan koordinat pelanggan.
- [x] Toggle layanan kurir menolak konfigurasi tanpa lokasi UMKM.
- [x] Kebijakan batas zona memakai `jarak > jarak_min` dan `jarak <= jarak_max`.
- [x] Produk ready dan PO dalam satu UMKM digabung; kebijakan PO tertinggi menjadi aturan bisnis.

### Rencana Peta dan Geocoding — OpenStreetMap

Implementasi lokasi berikutnya akan memakai OpenStreetMap agar UMKM dan
pelanggan tidak perlu memasukkan latitude/longitude secara manual.

- [ ] Tambahkan peta berbasis OpenStreetMap pada form alamat UMKM dan pelanggan.
- [ ] Tambahkan pencarian alamat melalui geocoding.
- [ ] Izinkan pengguna memilih dan menggeser pin untuk mengoreksi lokasi.
- [ ] Simpan alamat teks, latitude, dan longitude melalui API.
- [ ] Pertahankan Haversine untuk perhitungan ongkir MVP.
- [ ] Evaluasi OSRM atau layanan routing setelah alur peta stabil.
- [ ] Tampilkan atribusi OpenStreetMap sesuai ketentuan lisensi.
- [ ] Siapkan fallback manual untuk alamat lama yang belum memiliki koordinat.

### Test Gate

- [ ] Jarak dalam radius gratis menghasilkan biaya nol.
- [ ] Boundary zona mengikuti aturan `> jarak_min` dan `<= jarak_max`.
- [ ] Jarak di luar maksimum ditolak.
- [ ] Pickup selalu menghasilkan ongkir nol.
- [ ] Perubahan tarif setelah checkout tidak mengubah histori order.

## Task 11 — Strategi Checkout Multi-UMKM

**Status:** Berjalan — checkout group dan pembayaran gabungan sudah dibuat

Keranjang mobile dapat berisi beberapa UMKM, tetapi backend saat ini hanya
menerima satu UMKM per checkout. Perilaku ini harus dibuat eksplisit.

### Decision Gate

- [x] Izinkan item terpilih berasal dari beberapa UMKM dalam satu checkout.
- [x] Buat satu `checkout_group` sebagai induk pembayaran.
- [x] Buat satu pesanan internal per UMKM.
- [x] Gunakan satu transaksi Midtrans gabungan untuk seluruh checkout group.
- [x] Hitung opsi pengiriman dan ongkir per UMKM.
- [x] Sediakan status terpisah; penolakan satu UMKM tidak membatalkan pesanan
  UMKM lainnya.

### Cakupan Implementasi

- [x] Backend mengelompokkan item berdasarkan UMKM secara atomik.
- [x] Setiap UMKM memiliki status, ongkir, dan batas konfirmasi sendiri.
- [x] Mobile mengirim pilihan item dan opsi per UMKM dalam satu checkout.
- [ ] Mobile menampilkan ringkasan group dengan status per pesanan setelah reload.
- [ ] Pembatalan/refund dapat dilakukan per UMKM tanpa merusak order lain.
- [x] Dashboard UMKM hanya menerima pesanan miliknya.

### Test Gate

- [x] Keranjang satu UMKM tetap berfungsi seperti sebelumnya.
- [x] Keranjang beberapa UMKM dikirim sebagai satu checkout group.
- [x] Harga dan ongkir tiap UMKM dihitung terpisah.
- [x] Kegagalan validasi satu UMKM membatalkan transaksi secara atomik.
- [ ] Uji end-to-end pembayaran gabungan dan callback pada beberapa UMKM.

## Task 12 — Session, Role Guard, dan Sinkronisasi Akun

**Status:** Berjalan — restore session dan role guard dasar sudah dibuat

### Cakupan

- [x] Restore token dan role dari storage saat aplikasi dibuka kembali.
- [ ] Hapus sesi lokal otomatis saat API mengembalikan `401`.
- [x] Tambahkan guard role pelanggan pada seluruh endpoint pelanggan.
- [x] Tambahkan guard role UMKM pada seluruh endpoint UMKM.
- [x] Pastikan perpindahan mode tidak menghapus token baru.
- [ ] Sinkronkan favorit setelah login dan saat berganti akun.
- [ ] Bersihkan order, favorit, notifikasi, dan state mode saat logout.
- [ ] Gunakan secure storage untuk token jika kompatibel dengan target device.

### Test Gate

- [ ] Sesi tetap aktif setelah aplikasi ditutup dan dibuka kembali.
- [ ] Token pelanggan tidak dapat mengakses endpoint UMKM.
- [ ] Token UMKM tidak dapat mengakses endpoint pelanggan.
- [ ] Perpindahan mode lalu membuka Setting tidak menghasilkan error.
- [ ] Logout akun A tidak menampilkan data akun B.

## Task 13 — Notifikasi Persisten

**Status:** Belum dimulai

Notifikasi mobile saat ini masih in-memory dan dibuat dari sinkronisasi order.
Fitur ini perlu backend agar riwayat notifikasi tidak hilang setelah aplikasi
ditutup.

### Cakupan

- [ ] Buat tabel dan model notifikasi.
- [ ] Buat endpoint daftar notifikasi.
- [ ] Buat endpoint tandai satu atau semua sebagai dibaca.
- [ ] Buat notifikasi untuk order baru, status berubah, pembayaran, pembatalan,
  dan refund.
- [ ] Sinkronkan `NotificationService` dengan API.
- [ ] Tangani duplikasi notifikasi berdasarkan event/order/status.
- [ ] Evaluasi push notification setelah notifikasi API stabil.

### Test Gate

- [ ] Notifikasi tersimpan setelah restart aplikasi.
- [ ] Badge unread sesuai database.
- [ ] Menandai dibaca hanya memengaruhi akun yang benar.
- [ ] Event duplikat tidak membuat notifikasi ganda.

## Task 14 — Rating dan Ulasan

**Status:** Belum dimulai

Katalog saat ini mengembalikan rating `0.0` dan jumlah ulasan belum berasal dari
data nyata.

### Cakupan

- [ ] Buat tabel ulasan dengan relasi pelanggan, UMKM, produk, dan pesanan.
- [ ] Izinkan ulasan hanya untuk pesanan selesai milik pelanggan.
- [ ] Batasi satu ulasan per item/pesanan sesuai keputusan bisnis.
- [ ] Tambahkan endpoint buat, ubah, dan lihat ulasan.
- [ ] Hitung rating agregat dan jumlah ulasan.
- [ ] Tampilkan rating nyata pada katalog, detail UMKM, dan detail produk.
- [ ] Tambahkan moderasi atau penghapusan ulasan yang melanggar aturan.

### Test Gate

- [ ] Pelanggan tidak dapat mengulas order orang lain.
- [ ] Pesanan belum selesai tidak dapat diulas.
- [ ] Rating di katalog sama dengan agregasi database.
- [ ] Ulasan duplikat ditolak.

## Task 15 — Penghapusan Data Dummy dan Sinkronisasi Kontrak

**Status:** Belum dimulai

### Cakupan

- [ ] Hilangkan fallback `SampleCatalog` dari alur production.
- [ ] Tampilkan empty/error state jika API gagal, bukan data dummy.
- [ ] Audit semua endpoint yang dipanggil mobile terhadap `routes/api.php`.
- [ ] Perbarui [docs/api-contract.md](docs/api-contract.md) sesuai route aktual.
- [ ] Hapus endpoint rancangan yang belum tersedia atau tandai eksplisit sebagai
  backlog.
- [ ] Dokumentasikan format status final, ongkir, pembayaran, dan multi-UMKM.
- [ ] Perbarui roadmap setiap task selesai.

### Test Gate

- [ ] Tidak ada produk/order/notifikasi demo pada alur aplikasi.
- [ ] Semua endpoint yang dipakai mobile memiliki test kontrak.
- [ ] Response sukses dan error mengikuti envelope API.
- [ ] Dokumentasi tidak mengklaim fitur yang belum diimplementasikan.

## Task 16 — Production Readiness

**Status:** Belum dimulai

### Cakupan

- [ ] Validasi konfigurasi `.env` saat deployment.
- [ ] Pastikan URL callback Midtrans dapat diakses dari internet.
- [ ] Tambahkan rate limit login, register, checkout, dan callback.
- [ ] Tambahkan idempotency key untuk checkout.
- [ ] Audit authorization dan ownership seluruh endpoint.
- [ ] Audit upload file, ukuran, MIME type, dan nama file.
- [ ] Tambahkan logging terstruktur tanpa token atau data sensitif.
- [ ] Tambahkan backup database dan prosedur restore.
- [ ] Jalankan integration test pada perangkat Android nyata.
- [ ] Siapkan checklist release dan rollback.

### Test Gate

- [ ] Laravel test suite lulus.
- [ ] Flutter analyze lulus.
- [ ] Flutter test suite lulus.
- [ ] Test API end-to-end pada backend yang sama dengan perangkat.
- [ ] Uji pembayaran Sandbox dari awal sampai callback/status final.
- [ ] Uji logout, session restore, pembatalan, dan refund.

## Definition of Done

Satu task dianggap selesai apabila:

- Implementasi backend, mobile, dan UI yang relevan telah selesai.
- Test gate task tersebut lulus.
- Loading, empty, error, dan edge case utama telah ditangani.
- Tidak ada regresi pada test yang sudah tersedia.
- Perubahan terdokumentasi dan siap menjadi dasar task berikutnya.

## Urutan Eksekusi Saat Ini

1. Selesaikan sisa hardening **Task 12** dan uji perangkat nyata.
2. Selesaikan decision gate **Task 8** tentang status pesanan, stok, approval,
   refund, dan expiry.
3. Implementasikan **Task 8 — Hardening Transaksi dan Pembayaran**.
4. Implementasikan **Task 9 — Integritas Histori Pesanan dan Pembatalan**.
5. Implementasikan **Task 10 — Ongkir Berbasis Zona dan Lokasi**.
6. Putuskan dan implementasikan **Task 11 — Strategi Checkout Multi-UMKM**.
6. Implementasikan **Task 12 — Session, Role Guard, dan Sinkronisasi Akun**.
7. Implementasikan **Task 13 — Notifikasi Persisten**.
8. Implementasikan **Task 14 — Rating dan Ulasan**.
9. Bersihkan data dummy dan sinkronkan dokumentasi pada **Task 15**.
10. Tutup dengan audit keamanan, deployment, dan release gate pada **Task 16**.

Task tidak boleh diberi status selesai hanya karena happy path berhasil. Semua
decision gate, test gate, edge case, dan dokumentasi terkait harus terpenuhi.
