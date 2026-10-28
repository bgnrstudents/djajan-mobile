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

**Status:** Siap dimulai

### Cakupan

- [ ] Daftar UMKM.
- [ ] Daftar kategori.
- [ ] Daftar produk.
- [ ] Detail produk.
- [ ] Search dan filter.
- [ ] Detail UMKM.
- [ ] Provider untuk state katalog.

### Test Gate

- [ ] Katalog menampilkan data API aktual.
- [ ] Search dan filter menghasilkan data yang benar.
- [ ] Navigasi ke detail berfungsi.
- [ ] Loading dan error tidak menyebabkan UI crash.
- [ ] Layout diuji pada beberapa ukuran layar.

## Task 5 — Keranjang dan Checkout

**Status:** Menunggu Task 4

### Cakupan

- [ ] Tambah produk ke keranjang.
- [ ] Ubah jumlah dan hapus item.
- [ ] Validasi stok.
- [ ] Perhitungan subtotal dan total.
- [ ] Checkout dan pembuatan order.
- [ ] Pencegahan double submission.

### Test Gate

- [ ] Total harga akurat.
- [ ] Jumlah tidak melebihi stok.
- [ ] Keranjang kosong tidak dapat checkout.
- [ ] Produk tidak aktif tidak dapat dipesan.
- [ ] Order tidak terduplikasi.
- [ ] Transaksi database bersifat atomic.

## Task 6 — Status Pesanan dan Riwayat Transaksi

**Status:** Menunggu Task 5

### Status Pesanan

```text
pending -> confirmed -> processing -> ready -> completed
```

Status pembatalan dapat digunakan sesuai aturan bisnis:

```text
pending -> cancelled
confirmed -> cancelled
```

### Cakupan

- [ ] Riwayat pesanan pembeli.
- [ ] Detail pesanan.
- [ ] Update status oleh penjual/admin.
- [ ] Status timeline.
- [ ] Filter berdasarkan status.

### Test Gate

- [ ] Transisi status hanya mengikuti aturan valid.
- [ ] Pembeli tidak dapat mengubah status secara ilegal.
- [ ] Penjual hanya dapat mengubah order miliknya.
- [ ] Riwayat transaksi konsisten.
- [ ] Web dan mobile memakai sumber data API yang sama.

## Task 7 — Dashboard Admin dan UMKM

**Status:** Menunggu Task 6

### Cakupan

- [ ] Statistik produk.
- [ ] Statistik pesanan.
- [ ] Ringkasan omzet.
- [ ] Produk terlaris.
- [ ] Jumlah UMKM aktif.
- [ ] Filter periode waktu.
- [ ] Laporan dasar.

### Test Gate

- [ ] Angka dashboard sesuai query database.
- [ ] Filter periode menghasilkan data yang benar.
- [ ] Data dibatasi sesuai role.
- [ ] Query tetap efisien pada data besar.

## Definition of Done

Satu task dianggap selesai apabila:

- Implementasi backend, mobile, dan UI yang relevan telah selesai.
- Test gate task tersebut lulus.
- Loading, empty, error, dan edge case utama telah ditangani.
- Tidak ada regresi pada test yang sudah tersedia.
- Perubahan terdokumentasi dan siap menjadi dasar task berikutnya.

## Urutan Eksekusi Saat Ini

1. Mulai **Task 0 — Audit Kondisi Proyek**.
2. Jalankan seluruh test gate Task 0.
3. Catat hasil audit dan error baseline.
4. Jangan mulai Task 1 sebelum Task 0 dinyatakan lulus.
5. Task 0, Task 1, Task 2, dan Task 3 sudah selesai.
6. Berikutnya mulai **Task 4 — Katalog Produk Pembeli** dan jalankan test gate
   sebelum melanjutkan ke Task 5.
