# 📋 Panduan Pengujian Manual Lengkap Sistem Pesanan DJajan
**Platform Hyperlocal UMKM Kuliner Desa Kreyongan Atas**  
*Mencakup Verifikasi Item A.1 s/d A.7 dan Item B.1 s/d B.5*

---

## 🛠️ 1. Persiapan Lingkungan Uji (*Prerequisites*)

Pastikan kedua environment (Backend & Mobile) telah berjalan sebelum memulai pengujian manual:

### A. Backend Laravel (`Djajan-Website`)
1. Buka terminal di folder backend: `D:\laragon\www\DJ APKWEB\Djajan-Website`
2. Pastikan web server dan MySQL di Laragon aktif.
3. Jalankan server lokal:
   ```bash
   php artisan serve --host=0.0.0.0 --port=8000
   ```
4. *(Opsional)* Pastikan konfigurasi Midtrans Sandbox Server Key di file `.env` sudah terpasang.

### B. Mobile Flutter (`djajan_mobile`)
1. Buka terminal di folder mobile: `d:\laragon\www\Djajan\djajan_mobile`
2. Pastikan IP laptop di file `lib/config/api_config.dart` sudah sesuai dengan IP WiFi laptop Anda (cek via `ipconfig`).
3. Jalankan aplikasi di Emulator atau HP fisik:
   ```bash
   flutter run
   ```

---

## 👥 2. Rekomendasi Akun untuk Testing

Untuk mensimulasikan transaksi dua arah (Pembeli & Penjual), siapkan dua perangkat atau login bergantian:
* **Akun Pelanggan (Pembeli):** Login menggunakan nomor HP pelanggan terdaftar (atau buat akun baru di halaman registrasi pelanggan).
* **Akun UMKM Mitra (Penjual):** Login menggunakan akun penjual UMKM di Desa Kreyongan Atas (misal akun UMKM demo atau warung kue).

---

## 🧪 3. Skenario Pengujian Step-by-Step Per Item

---

### 🟢 Uji 1: Item A.1 — Midtrans Payment Flow Lag & Direct Redirect (🔴 P0)
**Tujuan:** Memastikan pembayaran digital via Midtrans tidak mengalami keterlambatan (*lag*), tautan Snap terbuka instan, dan status langsung tersinkronisasi saat kembali ke aplikasi.

1. Buka aplikasi sebagai **Pelanggan**.
2. Masukkan produk jajan apa saja ke keranjang, lalu masuk ke halaman **Checkout**.
3. Pada kartu **Metode Pembayaran**, pilih **Pembayaran Digital (Midtrans/QRIS)**.
4. Tekan tombol **"Bayar Sekarang"**.
5. **Ekspektasi Verifikasi:**
   * Halaman pembayaran Midtrans Snap terbuka secara instan (tanpa *loading spinner* macet).
   * Pilih metode pembayaran (misal GoPay / QRIS Simulator atau ShopeePay).
   * Selesaikan pembayaran di simulator Midtrans.
   * Tekan tombol **"Selesai / Kembali ke Toko"**.
   * Halaman pesanan langsung ter-redirect otomatis ke **Detail Pesanan** dengan status pembayaran **"Lunas" / "Menunggu Konfirmasi UMKM"** tanpa perlu me-refresh aplikasi manual.

---

### 🟢 Uji 2: Item A.2 — COD Real-time Sync & Disabled Lock (🔴 P0)
**Tujuan:** Memastikan pengaturan COD di dashboard UMKM langsung berdampak *real-time* ke keranjang pembeli dan opsi COD otomatis terkunci (*disabled*) jika penjual menonaktifkannya.

1. **Di sisi UMKM:**
   * Buka menu **Profil / Pengaturan Toko**.
   * Nonaktifkan tombol toggle **"Terima Pembayaran COD"** (matikan COD).
2. **Di sisi Pelanggan:**
   * Masukkan produk dari UMKM tersebut ke keranjang belanja.
   * Masuk ke halaman **Checkout**.
3. **Ekspektasi Verifikasi:**
   * Pada kartu **Metode Pembayaran**, opsi **"Bayar di Tempat (COD)"** otomatis berwarna abu-abu redup (*disabled*), tidak bisa diklik, dan muncul ikon gembok kecil.
   * Di bawah judul COD muncul teks peringatan: *"Dinonaktifkan oleh [Nama UMKM]"*.
   * Sistem otomatis mengalihkan pilihan pembayaran ke **Midtrans**.

---

### 🟢 Uji 3: Item A.3 & B.3 — Geolocation Radius Validation & Dynamic Courier Rates (🔴 P0)
**Tujuan:** Memvalidasi penghitungan ongkir kurir desa berbasis formula Haversine (maksimal 10 km dari UMKM) dan penolakan otomatis jika di luar jangkauan.

1. Masuk ke halaman **Checkout** sebagai pelanggan.
2. Buka kartu **Alamat Pengantaran** lalu tekan **"Pilih / Ubah Alamat"**.
3. **Skenario A (Dalam Desa Kreyongan < 1.0 km):**
   * Pilih alamat di area Kreyongan Atas (jarak < 1 km).
   * **Ekspektasi:** Biaya Ongkir tercatat **Rp 0 (Gratis Ongkir Warga Desa)**.
4. **Skenario B (Jarak Menengah 1.0 km - 3.0 km):**
   * Pilih alamat berjarak sekitar 1.5 km dari UMKM.
   * **Ekspektasi:** Biaya Ongkir otomatis terkalkulasi sebesar **Rp 3.000** (Tarif Zona Desa 1).
5. **Skenario C (Di Luar Radius > 10.0 km):**
   * Pilih atau geser pin lokasi ke luar kota (misal jarak > 10 km).
   * **Ekspektasi:** 
     * Pilihan pengiriman **Kurir Desa** otomatis dinonaktifkan dengan tulisan merah *"Di Luar Jangkauan Kurir (>10 km)"*.
     * Pilihan pengiriman otomatis dialihkan ke opsi **"Ambil Sendiri di Toko (Pickup)"**.
     * Tombol checkout memblokir order jika memaksa menggunakan kurir di luar jangkauan.

---

### 🟢 Uji 4: Item A.4 — Order Completion Flow & 24h Auto-Complete (🟡 P1)
**Tujuan:** Memastikan tombol "Pesanan Diterima" berfungsi menyelesaikan pesanan, dan pesanan yang lupa diselesaikan pelanggan akan selesai otomatis setelah 24 jam.

1. **Alur Pelanggan Konfirmasi Terima:**
   * Masuk ke akun UMKM, ubah status pesanan menjadi **"Serahkan ke Kurir"** (status: `diantar`).
   * Buka akun Pelanggan, masuk ke detail pesanan yang sedang diantar tersebut.
   * Tekan tombol hijau **"Pesanan Telah Diterima"**.
   * Muncul pop-up konfirmasi komitmen penerimaan makanan.
   * Tekan **"Ya, Sudah Diterima"**.
   * **Ekspektasi:** Status pesanan langsung berubah menjadi **"Selesai"**, dana otomatis diteruskan ke pendapatan bersih UMKM.
2. **Alur Simulasi Auto-Complete 24 Jam (Terminal):**
   * Buat pesanan baru berstatus `diantar`.
   * Buka terminal di folder backend dan jalankan perintah simulasi instan:
     ```bash
     php artisan pesanan:auto-complete --simulate-order={ID_PESANAN}
     ```
   * **Ekspektasi:** Terminal melaporkan pesanan berhasil diselesaikan. Refresh aplikasi pelanggan/UMKM, status pesanan seketika berubah jadi **"Selesai"**.

---

### 🟢 Uji 5: Item A.5 & B.4 — Turn-by-Turn Maps Nav & Tracking Rute OSM (🔵 P2)
**Tujuan:** Memastikan kurir/UMKM bisa membuka navigasi Google Maps belokan-demi-belokan, dan pelanggan bisa memantau rute pengantaran di peta OpenStreetMap.

1. **Navigasi Sisi UMKM / Kurir:**
   * Buka akun UMKM, masuk ke **Detail Pesanan** yang memilih metode pengiriman Kurir.
   * Gulir ke kartu **Peta Rute & Titik Pengantaran**.
   * Tekan tombol biru **"Buka Navigasi Rute (Google Maps)"**.
   * **Ekspektasi:** Aplikasi Google Maps (atau browser) otomatis terbuka langsung mengarahkan rute navigasi *turn-by-turn* GPS dari dapur UMKM menuju titik rumah pembeli.
2. **Pelacakan Rute Sisi Pelanggan:**
   * Buka akun Pelanggan, masuk ke **Detail Pesanan** yang berstatus `diantar`.
   * **Ekspektasi:** Muncul kartu peta interaktif OpenStreetMap yang menampilkan:
     * Pin Toko UMKM (oranye).
     * Pin Rumah Pelanggan (hijau).
     * Garis rute pengantaran (*polyline* biru) serta estimasi waktu tiba (ETA menit).

---

### 🟢 Uji 6: Item A.6 — Download & Cetak Struk PDF (🔵 P2)
**Tujuan:** Memastikan struk pesanan digital dapat diunduh dalam format PDF di HP pelanggan/UMKM, serta dapat dibuka via halaman web siap cetak.

1. **Download Struk PDF di Aplikasi Mobile:**
   * Buka **Detail Pesanan** apa saja di HP Pelanggan atau UMKM.
   * Tekan tombol / ikon **"Struk PDF"** di bagian bawah atau di bar judul atas.
   * **Ekspektasi:** File PDF struk vektor berlogo DJajan ter-generate rapi (memuat detail item, nama UMKM, alamat, ongkir, metode bayar, dan total harga). Muncul dialog native Android/iOS untuk mencetak atau membagikan PDF ke WhatsApp/Drive.
2. **Struk Web Siap Cetak (Browser):**
   * Buka browser laptop: `http://localhost:8000/pesanan/{ID_PESANAN}/struk`
   * **Ekspektasi:** Muncul struk berdesain nota kasir modern yang dilengkapi tombol **"Cetak Struk"** dan layout khusus print A4 / kertas thermal.

---

### 🟢 Uji 7: Item A.7 — Direct WhatsApp Action Button (🔵 P2)
**Tujuan:** Memastikan komunikasi antara pembeli, UMKM, dan kurir terhubung langsung via WhatsApp tanpa perlu menyimpan nomor manual.

1. **Di Sisi Pelanggan:**
   * Buka **Detail Pesanan**.
   * Gulir ke bawah, tekan tombol hijau **"Hubungi UMKM via WhatsApp"**.
   * **Ekspektasi:** Aplikasi WhatsApp otomatis terbuka menuju kontak UMKM dengan pesan template: *"Halo [Nama UMKM], saya ingin menanyakan pesanan [ID_PESANAN] atas nama [Nama Pelanggan]..."*.
2. **Di Sisi UMKM:**
   * Buka **Detail Pesanan** di akun UMKM.
   * Di samping nama & nomor telepon pembeli, tekan tombol hijau **"Chat WA"**.
   * **Ekspektasi:** WhatsApp otomatis terbuka menuju nomor pembeli untuk konfirmasi pesanan/alamat.

---

### 🟢 Uji 8: Item B.2 & B.5 — Skema Anti-COD Pre-Order & Alur PO Acara (🔴 P0 & 🟡 P1)
**Tujuan:** Melindungi modal belanja UMKM dari order fiktif dengan memblokir COD pada produk Pre-Order, mewajibkan jadwal acara, serta memisahkan alur PO di dasbor penjual.

1. **Uji Penguncian COD pada Pre-Order (Checkout):**
   * Masukkan produk berjenis **Pre-Order** (misal: Tumpeng Mini / Katering Partai Besar) ke keranjang.
   * Masuk ke halaman **Checkout**.
   * **Ekspektasi:**
     * Opsi **"Bayar di Tempat (COD)"** otomatis terkunci dan tidak bisa dipilih.
     * Muncul keterangan edukatif: *"Khusus Pre-Order/Katering wajib pembayaran digital untuk jaminan modal dapur UMKM"*.
     * Wajib memilih **Tanggal & Jam Acara/Kebutuhan** (minimal H-1).
2. **Uji Tampilan Dasbor UMKM:**
   * Buka akun UMKM, masuk ke tab **Pesanan Masuk**.
   * **Ekspektasi:**
     * Terdapat filter chip baru: **Semua**, **⚡ Ready**, dan **🎂 Pre-Order / Acara**.
     * Pesanan Pre-Order memiliki badge oranye kue bertuliskan **"Pre-Order"** dan info jadwal acara: `Acara: [Tanggal, Jam]`.
     * Hitung mundur batas konfirmasi menampilkan: **"Konfirmasi 24 Jam"** (berbeda dengan Ready Stock yang berbatas **"30 Menit"**).

---

### 🟢 Uji 9: Item B.1 — Auto-Cancel Kedaluwarsa & Hybrid Midtrans Refund (🔴 P0)
**Tujuan:** Memverifikasi pembatalan otomatis saat UMKM tidak merespons, perlindungan pembatalan sepihak saat makanan dimasak, dan kemudahan klaim refund bagi pelanggan.

1. **Proteksi Anti-Batal Sepihak Saat Dimasak:**
   * UMKM menekan tombol **"Mulai Diproses"** (status: `diproses` = sedang dimasak di dapur).
   * Buka akun Pelanggan pada pesanan tersebut.
   * **Ekspektasi:** Tombol "Batalkan Pesanan" otomatis hilang / terkunci menjadi tulisan abu-abu *"Tidak dapat batal"*. Pelanggan tidak bisa membatalkan sepihak karena bahan makanan sudah dimasak.
2. **Simulasi Auto-Cancel Kedaluwarsa Konfirmasi (Terminal):**
   * Buat pesanan baru berstatus `po_baru`.
   * Buka terminal backend dan jalankan perintah simulasi:
     ```bash
     php artisan pesanan:auto-cancel --simulate-order={ID_PESANAN}
     ```
   * **Ekspektasi:** Pesanan otomatis dibatalkan oleh sistem dengan alasan: *"Batas waktu konfirmasi UMKM telah berakhir."*.
3. **Klaim Refund WhatsApp Pelanggan:**
   * Buka detail pesanan yang dibatalkan tersebut di aplikasi pelanggan.
   * **Ekspektasi:**
     * Muncul kartu informasi berwarna oranye: **"Pengembalian Dana Menunggu Konfirmasi"** beserta nominal uang yang harus kembali.
     * Tekan tombol hijau **"Klaim Refund ke Admin via WhatsApp"**.
     * WhatsApp otomatis terbuka menuju Admin DJajan dengan rincian ID Pesanan, nama pembeli, nominal refund, dan permohonan transfer balik.

---

## 🏁 4. Perintah Cepat Uji Otomatis (*Automated Regression Tests*)

Jika ingin memastikan seluruh baris kode backend dan mobile berada dalam kondisi 100% sehat kapan saja:

### Test Suite Backend (Laravel)
```bash
cd "D:\laragon\www\DJ APKWEB\Djajan-Website"
php artisan test
```
*(Hasil diharapkan: 55 passed, 171 assertions)*

### Test Suite Mobile (Flutter)
```bash
cd "d:\laragon\www\Djajan\djajan_mobile"
flutter test test/order_test.dart
```
*(Hasil diharapkan: 18 passed, All tests passed)*

