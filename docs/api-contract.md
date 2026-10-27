# Kontrak API — Djajan

> Dokumen ini adalah **sumber kebenaran (single source of truth)** untuk komunikasi
> antara aplikasi mobile dan backend. Backend yang dipakai: **Laravel** (`Djajan-Website`)
> dengan autentikasi **Sanctum**.
>
> Dibuat dari hasil audit kode yang **sudah ada**:
> - `D:\laragon\www\DJ APKWEB\djajan_app` → aplikasi Flutter **role UMKM** (sudah jalan penuh)
> - `D:\laragon\www\DJ APKWEB\Djajan-Website` → backend Laravel (API role UMKM + web admin)
> - `D:\laragon\www\Djajan\djajan_mobile` → aplikasi Flutter **role Pelanggan** (belum ada backend)
>
> Status: `DRAFT v1` — menunggu keputusan pada bagian **9. Pertanyaan Terbuka**.

---

## 1. Konvensi Umum

### 1.1 Base URL
| Lingkungan | Base URL |
|---|---|
| Emulator Android | `http://10.0.2.2:8000/api` |
| Chrome / Windows | `http://localhost:8000/api` |
| HP fisik (satu WiFi) | `http://<IP-Laptop>:8000/api` |
| Apache/Laragon (port 80) | `http://<host>/Djajan-Website/public/api` |

Backend dijalankan: `php artisan serve --host=0.0.0.0 --port=8000`.

### 1.2 Bentuk balasan (envelope) — WAJIB sama untuk semua endpoint
```json
{
  "sukses": true,
  "pesan": "Produk \"Nasi Geprek\" berhasil disimpan ke database.",
  "data": { }
}
```
- `sukses` : `true` = berhasil, `false` = gagal (pesan berisi alasan berbahasa Indonesia).
- `pesan`  : selalu ada, aman untuk ditampilkan langsung ke pengguna.
- `data`   : bebas — bisa `object`, `array`, atau `null`.

### 1.3 Kode HTTP
| Kode | Arti | Catatan untuk mobile |
|---|---|---|
| 200 | Sukses | — |
| 201 | Berhasil dibuat (create/register) | — |
| 400 | Validasi / parameter kurang | tampilkan `pesan` |
| 401 | Kredensial salah / token tidak valid | arahkan login ulang |
| 403 | Belum diverifikasi / akses ditolak | tampilkan `pesan` |
| 404 | Data/endpoint tidak ditemukan | tampilkan `pesan` |
| 409 | Data bentrok (duplikat) | tandai field di `data.field` |
| 422 | Validasi Laravel (framework) | normalisasi ke `pesan` |
| 500 | Error server | tampilkan `pesan` |

### 1.4 Autentikasi
- Login mengembalikan `token` (Sanctum) di dalam `data`.
- Semua endpoint privat butuh header:
  ```
  Authorization: Bearer <token>
  Accept: application/json
  ```
- Token disimpan di perangkat (`shared_preferences` / `flutter_secure_storage`).
- `401` kapan pun → hapus token lokal + lempar ke halaman login.

### 1.5 Format data
| Tipe | Aturan |
|---|---|
| Uang | `integer` rupiah, tanpa desimal & tanpa titik (contoh `15000`) |
| Waktu | string `"YYYY-MM-DD HH:MM:SS"`, tanpa timezone (dianggap waktu lokal desa) |
| Tanggal | string `"YYYY-MM-DD"` |
| Boolean | `true` / `false` (bukan `1`/`0` di **balasan**; saat **mengirim** boleh pakai `1`/`0`) |
| Nomor telepon | dinormalkan ke `0xxxxxxxxxx` (buang spasi/`-`/`.`, `+62`/`62` → `0`) |
| Gambar | dikirim sebagai file (`multipart/form-data`); balasan menyertakan `*_url` absolut |
| Nullable | di balasan jadi `""` untuk string (kecuali dinyatakan lain) |

### 1.6 Tipe konten permintaan
- **Data biasa** → `application/x-www-form-urlencoded` (aman untuk web & mobile).
- **Ada upload gambar** → `multipart/form-data`, nama field file:
  - produk → `gambar_produk`
  - profil UMKM / foto pelanggan → `foto_profil`
  - bukti pembayaran → `bukti_pembayaran`
- Batas ukuran gambar: **5 MB**.

---

## 2. Tabel & Enum (kondisi saat ini)

Tabel yang **sudah ada** (migrasi Laravel di `Djajan-Website`):

### 2.1 `umkm`
| Kolom | Tipe | Catatan |
|---|---|---|
| `id_umkm` | bigint PK | |
| `id_pelanggan` | int null | untuk role Pelanggan (belum dipakai) |
| `nama_usaha` | string | |
| `spesialis` | string null | contoh "Spesialis Katering" |
| `deskripsi_usaha` | text null | |
| `alamat` | text null | |
| `no_telp_usaha` | string(50) | dipakai sebagai username login |
| `email_usaha` | string null | alternatif login |
| `password` | string null | **SHA-256** (mendukung bcrypt) |
| `foto_profil` | string null | nama file |
| `status_verifikasi` | string | `menunggu` / `terverifikasi` / `ditolak` |
| `toko_aktif` | bool | |
| `transfer_bank_aktif` | bool | |
| `bank_kode`, `bank_nama`, `no_rekening`, `atas_nama` | string null | rekening penerima |
| `cod_aktif` | bool | |
| `skema_po` | string null | |
| `pickup_aktif` | bool | |
| `kurir_warga_aktif` | bool | |
| `biaya_pengantaran` | int | tarif flat lama (dianggap legacy) |
| `latitude`, `longitude` | decimal(10,7) null | lokasi dapur |
| `radius_gratis_km` | decimal(5,2) | |
| `jarak_maksimal_km` | decimal(5,2) null | |
| `created_at` | timestamp null | **tidak ada** `updated_at` |

### 2.2 `produk`
| Kolom | Tipe | Catatan |
|---|---|---|
| `id_produk` | bigint PK | |
| `id_umkm` | bigint FK | cascade |
| `nama_produk` | string | |
| `kategori` | string null | |
| `harga` | int | |
| `deskripsi` | text null | |
| `mode_penjualan` | string | **`ready` / `pre_order` / `keduanya`** |
| `stok` | int | `pre_order` selalu 0 |
| `min_order_po` | int | |
| `waktu_masak_po` | string null | contoh "H-2 Hari" |
| `status_ketersediaan` | bool | tayang/tidak di warung |
| `gambar_produk` | string null | nama file |
| `created_at`, `updated_at` | timestamp | |

### 2.3 `pesanan`
| Kolom | Tipe | Catatan |
|---|---|---|
| `id_pesanan` | string PK | contoh `PO-20260915` |
| `id_pelanggan` | bigint FK | |
| `id_umkm` | bigint FK | **1 pesanan = 1 UMKM** |
| `tanggal_pesan` | date | |
| `waktu_dibutuhkan` | datetime null | untuk pre-order |
| `batas_konfirmasi` | datetime null | hitung mundur UMKM |
| `keperluan_acara` | string null | |
| `metode_pengiriman` | string null | |
| `alamat_tujuan` | text null | |
| `catatan` | text null | |
| `metode_pembayaran` | string null | |
| `status_pembayaran` | string | default `belum_bayar` |
| `bukti_pembayaran` | string null | nama file |
| `biaya_pengantaran` | int | |
| `biaya_layanan` | int | |
| `total_harga` | int | |
| `status_pesanan` | string | default `menunggu_konfirmasi` |

### 2.4 `detail_pesanan`
`id_detail` PK, `id_pesanan` FK, `id_produk` FK (nullable, set null), `nama_produk`, `satuan` (default `pcs`), `jumlah`, `harga_satuan`, `subtotal`.

### 2.5 Tabel lain
- `pelanggan` — `id_pelanggan`, `nama`, `email` (unik), `password`, `no_telp`, `alamat`.
- `verifikasi_umkm` — riwayat verifikasi UMKM oleh admin.
- `umkm_zona_ongkir` — model `UmkmZonaOngkir` **ada**, tapi migrasinya belum ditemukan → **perlu diverifikasi**.

### ⚠️ 2.6 Ketidakcocokan nilai enum yang harus dibetulkan
| Kolom | Default di migrasi | Nilai yang dipakai controller/model | Rekomendasi |
|---|---|---|---|
| `produk.mode_penjualan` | `reguler` | `ready` / `pre_order` / `keduanya` | samakan ke 3 nilai controller |
| `pesanan.status_pesanan` | `menunggu_konfirmasi` | `po_baru` / `diterima` / `ditolak` / `selesai` | perlu enum baru (lihat §6) |
| `umkm.status_verifikasi` | `menunggu` | register menulis `pending`; login menerima `terverifikasi` | standarkan: `menunggu`/`terverifikasi`/`ditolak` |

---

## 3. Pemetaan Data Mobile ↔ Backend

Supaya `djajan_mobile` bisa memakai API yang sudah ada tanpa model baru yang aneh.

| Konsep di `djajan_mobile` | Padanan backend |
|---|---|
| `Umkm.name` | `umkm.nama_usaha` |
| `Umkm.type` | `umkm.spesialis` |
| `Umkm.phone` | `umkm.no_telp_usaha` |
| `Umkm.rating`, `distanceKm` | **belum ada** di DB → perlu kolom/tabel ulasan & lokasi pelanggan |
| `Umkm.hasCourier` / `isPickupOnly` | `umkm.kurir_warga_aktif` / `pickup_aktif` |
| `Product.orderType` (`Instant`/`Pre-Order`) | `produk.mode_penjualan` (`ready`/`pre_order`/`keduanya`) |
| `Product.price` | `produk.harga` |
| `Product.unit` | `detail_pesanan.satuan` |
| `CartLine.courierFee` | hasil `ongkir_hitung` (zona jarak), bukan `umkm.biaya_pengantaran` |
| `Order.status` | `pesanan.status_pesanan` (lihat §6) |
| `Order.paymentMethod` | `pesanan.metode_pembayaran` |
| `Order.recipient` | `pesanan.alamat_tujuan` + `pelanggan` |

---

## 4. API Autentikasi Pelanggan — Task 1

### `POST /api/pelanggan/register`

Request form:

```text
nama, no_telp, email (opsional), password, password_confirmation
```

Response `201` mengembalikan `data` berisi `role: pelanggan`, identitas
pelanggan, dan token Sanctum. Email boleh kosong; nomor telepon tetap wajib.

### `POST /api/pelanggan/login`

Request form:

```text
identifier, password
```

`identifier` dapat berupa email atau nomor WhatsApp. Response `200`
mengembalikan `role: pelanggan` dan token Sanctum.

### `POST /api/auth/google`

Request form:

```text
id_token
```

Laravel memverifikasi token ke Google dan memeriksa `aud` terhadap
`GOOGLE_CLIENT_ID` serta `email_verified`. Akun baru dibuat sebagai pelanggan.
Jika email telah terhubung ke UMKM, response mengembalikan `role: umkm`.

### `POST /api/pelanggan/logout`

Membutuhkan Bearer token Sanctum dan menghapus token aktif.

### Konfigurasi

- Backend membutuhkan `GOOGLE_CLIENT_ID` di `.env`.
- Flutter membutuhkan konfigurasi OAuth client Android/iOS dari Google Cloud
  Console. Credential tidak boleh disimpan di repository.
- `google_sub` disimpan unik pada tabel `pelanggan` untuk mencegah akun Google
  duplikat.

## 5. API Role UMKM — SUDAH ADA (jangan diubah seenaknya)

Sudah jalan & dipakai `djajan_app`. Balasan `data` mengikuti `keFormatJson()` di model.

### 4.1 `POST /api/login` (publik)
Req: `identifier` (no. WA / email), `password`
Res `data`: seluruh field `umkm` + `token`
```json
{
  "sukses": true,
  "pesan": "Selamat datang, Dapur Bu Minten!",
  "data": {
    "id_umkm": 1,
    "nama_usaha": "Dapur Bu Minten",
    "spesialis": "Spesialis Katering",
    "deskripsi_usaha": "",
    "alamat": "RT 01 Desa Kreyongan Atas",
    "no_telp_usaha": "081234567890",
    "email_usaha": "minten@djajan.desa.id",
    "foto_profil": null,
    "foto_profil_url": null,
    "status_verifikasi": "terverifikasi",
    "toko_aktif": true,
    "transfer_bank_aktif": true,
    "bank_kode": "BRI",
    "bank_nama": "Bank Rakyat Indonesia",
    "no_rekening": "324101098273531",
    "atas_nama": "Bu Minten",
    "cod_aktif": true,
    "skema_po": "DP 50%",
    "pickup_aktif": true,
    "kurir_warga_aktif": true,
    "biaya_pengantaran": 5000,
    "latitude": -7.1234567,
    "longitude": 110.1234567,
    "radius_gratis_km": 1.0,
    "jarak_maksimal_km": 5.0,
    "zona_ongkir": [],
    "token": "1|abcdef..."
  }
}
```
Gagal: `400` (field kosong), `401` (akun tidak ada / sandi salah), `403` (menunggu/ditolak verifikasi).

### 4.2 `POST /api/register` (publik)
Req (multipart bila ada foto): `nama_usaha`, `spesialis`, `no_telp_usaha`, `email_usaha`,
`password`, `password_konfirmasi`, `alamat`, `foto_profil?`
Res `201` `data` = `umkm` (tanpa token). `409` mengembalikan `data.field` (mis. `nama_usaha`,
`no_telp_usaha`, `email_usaha`) untuk menandai kolom bermasalah.

### 4.3 `POST /api/logout` (privat)
Res `data: null`.

### 4.4 `GET /api/profil_get` (privat)
Res `data` = objek `umkm` (sama seperti 4.1 tanpa `token`), `zona_ongkir` terisi.

### 4.5 `POST /api/profil_update` (privat)
Update parsial — kirim hanya field yang berubah:
`nama_usaha`, `spesialis`, `alamat`, `no_telp_usaha`, `deskripsi_usaha`,
`toko_aktif`, `transfer_bank_aktif`, `cod_aktif`, `skema_po`, `pickup_aktif`,
`kurir_warga_aktif`, `biaya_pengantaran`, `bank_kode`, `bank_nama`, `no_rekening`,
`atas_nama`, `foto_profil?` (file).
Res `data` = objek `umkm` terbaru. `400` bila tidak ada field berubah.

### 4.6 `POST /api/ongkir_simpan` (privat)
Req: `latitude`, `longitude`, `radius_gratis_km`, `jarak_maksimal_km`,
`zona` = **JSON string** berisi array `[{"jarak_min":0,"jarak_max":1,"biaya":0}, ...]`
(boundary: berlaku untuk jarak `> jarak_min` sampai `<= jarak_max`).
Res `data` = objek `umkm` terbaru.

### 4.7 `GET /api/produk_list` (privat)
Query opsional: `cari` (nama/kategori).
Res `data` = array:
```json
[{
  "id_produk": 12, "id_umkm": 1, "nama_produk": "Nasi Kotak Ayam Geprek",
  "kategori": "Makanan & Catering", "harga": 15000, "deskripsi": "...",
  "mode_penjualan": "keduanya", "stok": 25, "min_order_po": 10,
  "waktu_masak_po": "H-2 Hari", "status_ketersediaan": true,
  "gambar_produk": "prod_xxx.jpg",
  "gambar_url": "http://host/storage/produk/prod_xxx.jpg"
}]
```

### 4.8 `POST /api/produk_create` (privat, multipart)
Req: `nama_produk`, `kategori`, `harga`, `deskripsi`, `mode_penjualan`,
`stok`, `min_order_po`, `waktu_masak_po`, `status_ketersediaan`, `gambar_produk?`
Res `201` `data` = objek produk. `409` `data.field = "nama_produk"` bila duplikat.

### 4.9 `POST /api/produk_update` (privat, multipart)
Req parsial: `id_produk` (wajib) + field yang diubah + `gambar_produk?` (file baru) /
`hapus_gambar=1`. Endpoint ini juga dipakai untuk **ubah stok cepat** dan **toggle tayang**.
Res `data` = objek produk terbaru.

### 4.10 `POST /api/produk_delete` (privat)
Req: `id_produk`. Res `data: { "id_produk": 12 }`.

### 4.11 `GET /api/pesanan_list` (privat)
Res `data` = array pesanan (urut `po_baru → diterima → selesai → ditolak`):
```json
[{
  "id_pesanan": "PO-20260915", "id_pelanggan": 3,
  "nama_pembeli": "Muhammad Rizki", "no_telp": "081234567890",
  "tanggal_pesan": "2026-09-15",
  "waktu_dibutuhkan": "2026-09-20 11:00:00",
  "batas_konfirmasi": "2026-09-16 09:00:00",
  "keperluan_acara": "Rapat Desa", "metode_pengiriman": "kurir_warga",
  "alamat_tujuan": "RT 03 / RW 02, Balai RW", "catatan": "Sambal dipisah",
  "metode_pembayaran": "cod", "status_pembayaran": "belum_bayar",
  "biaya_pengantaran": 5000, "biaya_layanan": 1000,
  "subtotal": 150000, "total_harga": 156000,
  "status_pesanan": "po_baru",
  "items": [{
    "id_detail": 1, "id_produk": 12, "nama_produk": "Nasi Kotak Ayam Geprek",
    "satuan": "box", "jumlah": 10, "harga_satuan": 15000, "subtotal": 150000,
    "gambar_url": "http://host/storage/produk/prod_xxx.jpg"
  }]
}]
```

### 4.12 `GET /api/pesanan_detail` (privat)
Query: `id_pesanan`. Res `data` = satu objek pesanan (bentuk sama 4.11).

### 4.13 `POST /api/pesanan_status` (privat)
Req: `id_pesanan`, `status` ∈ `po_baru|diterima|ditolak|selesai`.
Status `diterima` **otomatis mengurangi stok** produk terkait.
Res `data` = objek pesanan terbaru. `409` bila pesanan sudah diproses (kecuali → `selesai`).

### 4.14 `GET /api/ringkasan` (privat)
Res `data`:
```json
{
  "total_produk": 8, "produk_tayang": 6, "stok_habis": 1,
  "pesanan_baru": 3, "pesanan_diterima": 5, "omzet_diterima": 750000
}
```

---

## 6. API Role PELANGGAN — Endpoint Lanjutan

Ini yang belum ada sama sekali dan dibutuhkan `djajan_mobile`.
Semua mengikuti konvensi §1. Prefix disarankan `/api/pelanggan/...` agar tidak bentrok
dengan endpoint role UMKM.

### 5.1 Auth Pelanggan
| Method | Endpoint | Req | Res `data` |
|---|---|---|---|
| POST | `/api/pelanggan/register` | `nama`, `email`, `no_telp`, `password`, `password_konfirmasi` | objek pelanggan + `token` |
| POST | `/api/pelanggan/login` | `identifier` (email/no.telp), `password` | objek pelanggan + `token` |
| POST | `/api/pelanggan/logout` | — | `null` |
| GET | `/api/pelanggan/profil` | — | objek pelanggan |
| POST | `/api/pelanggan/profil_update` | `nama`, `no_telp`, `email` | objek pelanggan |

Objek pelanggan:
```json
{ "id_pelanggan": 3, "nama": "Muhammad Rizki", "email": "rizki@mail.com",
  "no_telp": "081234567890", "alamat": "RT 03 Desa Kreyongan Atas" }
```

### 5.2 Buku Alamat (untuk menu "Alamat Pengiriman")
| Method | Endpoint | Req |
|---|---|---|
| GET | `/api/pelanggan/alamat_list` | — |
| POST | `/api/pelanggan/alamat_simpan` | `id_alamat?`, `label`, `nama_penerima`, `no_telp`, `alamat`, `catatan`, `latitude?`, `longitude?`, `utama?` |
| POST | `/api/pelanggan/alamat_hapus` | `id_alamat` |
| POST | `/api/pelanggan/alamat_utama` | `id_alamat` |

### 5.3 Katalog & Pencarian (boleh diakses tanpa login)
| Method | Endpoint | Query/Req | Res `data` |
|---|---|---|---|
| GET | `/api/katalog/umkm_list` | `cari`, `kategori`, `hanya_aktif=1` | array UMKM ringkas |
| GET | `/api/katalog/umkm_detail` | `id_umkm` | objek UMKM + `zona_ongkir` + `produk[]` + `rating` |
| GET | `/api/katalog/produk_detail` | `id_produk` | objek produk + `umkm` ringkas |
| GET | `/api/katalog/cari` | `q` | `{ "umkm": [...], "produk": [...] }` |
| GET | `/api/katalog/kategori_list` | — | array string kategori |

UMKM ringkas:
```json
{ "id_umkm": 1, "nama_usaha": "Dapur Bu Minten", "spesialis": "Spesialis Katering",
  "alamat": "RT 01 Desa Kreyongan Atas", "foto_profil_url": null,
  "kurir_warga_aktif": true, "pickup_aktif": true, "cod_aktif": true,
  "rating": 4.8, "jumlah_ulasan": 24, "jarak_km": 1.2 }
```

### 5.4 Ongkir (berbasis zona jarak)
`POST /api/ongkir_hitung`
Req: `id_umkm`, `latitude`, `longitude` (lokasi pelanggan).
Res `data`:
```json
{ "jarak_km": 1.4, "gratis": false, "biaya": 5000, "bisa_diantar": true,
  "zona": { "jarak_min": 1, "jarak_max": 3, "biaya": 5000 } }
```

### 5.5 Pesanan (Pelanggan)
> **Keputusan penting:** satu checkout bisa berisi produk dari **beberapa UMKM**,
> sedangkan tabel `pesanan` hanya punya satu `id_umkm`. Lihat §9.1.

`POST /api/pesanan_buat`
Req:
```json
{
  "nama_penerima": "Muhammad Rizki",
  "no_telp": "081234567890",
  "alamat_tujuan": "RT 03 / RW 02, Balai RW",
  "catatan_alamat": "Pagar hijau samping pos ronda",
  "latitude": -7.12, "longitude": 110.12,
  "metode_pembayaran": "cod",
  "items": [
    { "id_produk": 12, "jumlah": 10, "mode": "pre_order",
      "waktu_dibutuhkan": "2026-09-20 11:00:00", "keperluan_acara": "Rapat Desa" },
    { "id_produk": 5, "jumlah": 5, "mode": "ready", "metode_pengiriman": "pickup" }
  ]
}
```
Res `201` `data` = array pesanan yang terbentuk (satu per UMKM):
```json
[{ "id_pesanan": "PS-20260915-0001", "kode_pesanan": "#DJN-20260915-0001",
   "id_umkm": 1, "status_pesanan": "menunggu_pembayaran",
   "metode_pembayaran": "cod", "total_harga": 156000, "batas_konfirmasi": null }]
```

| Method | Endpoint | Req | Fungsi |
|---|---|---|---|
| GET | `/api/pesanan_saya` | `status?` | daftar pesanan pelanggan |
| GET | `/api/pesanan_saya_detail` | `id_pesanan` | detail 1 pesanan |
| POST | `/api/pesanan_bukti` | `id_pesanan` + file `bukti_pembayaran` | unggah bukti transfer |
| POST | `/api/pesanan_batal` | `id_pesanan`, `alasan?` | batalkan (sebelum diproses) |
| POST | `/api/pesanan_midtrans_token` | `id_pesanan` | → `{ "snap_token": "...", "redirect_url": "..." }` |
| POST | `/api/midtrans/notification` | (webhook Midtrans, **tanpa** auth) | update `status_pembayaran` |

### 5.6 Favorit
| Method | Endpoint | Req |
|---|---|---|
| GET | `/api/favorit_list` | — |
| POST | `/api/favorit_toggle` | `tipe` (`produk`/`umkm`), `id_ref` |

Res `favorit_list`:
```json
{ "produk": [12, 5], "umkm": [1] }
```

### 5.7 Notifikasi
| Method | Endpoint | Req |
|---|---|---|
| GET | `/api/notifikasi_list` | `hanya_belum_dibaca?` |
| POST | `/api/notifikasi_baca` | `id_notifikasi` **atau** `semua: true` |

```json
[{ "id_notifikasi": 7, "tipe": "pesanan", "judul": "Pesanan Sedang Diproses",
   "pesan": "Dapur Bu Minten sedang menyiapkan pesanan #DJN-...",
   "id_pesanan": "PS-20260915-0001", "dibaca": false,
   "created_at": "2026-09-15 09:30:00" }]
```

---

## 7. Pemetaan Status Pesanan (HARUS disepakati)

Mobile (`OrderStatus`) vs backend saat ini (`status_pesanan`):

| Mobile | Usulan nilai backend | Siapa yang mengubah |
|---|---|---|
| `waitingPayment` | `menunggu_pembayaran` | sistem (saat dibuat) |
| `reviewing` | `ditinjau` | pelanggan unggah bukti / UMKM konfirmasi |
| `processing` | `diproses` | UMKM (terima pesanan) |
| `delivering` | `dikirim` | UMKM |
| `completed` | `selesai` | UMKM |
| `cancelled` | `dibatalkan` | pelanggan / sistem |

> Endpoint role UMKM (§4.13) saat ini hanya menerima `po_baru|diterima|ditolak|selesai`.
> **Perlu diselaraskan** — lihat §9.2.

---

## 8. Perubahan Skema DB yang Diperlukan

### 7.1 Tabel baru
```sql
-- 1. Zona ongkir per UMKM (model sudah ada, migrasi belum ditemukan)
umkm_zona_ongkir(id_zona PK, id_umkm FK, jarak_min DECIMAL(5,2),
                 jarak_max DECIMAL(5,2), biaya INT)

-- 2. Buku alamat pelanggan
pelanggan_alamat(id_alamat PK, id_pelanggan FK, label VARCHAR(50),
                 nama_penerima VARCHAR(100), no_telp VARCHAR(50),
                 alamat TEXT, catatan VARCHAR(255) NULL,
                 latitude DECIMAL(10,7) NULL, longitude DECIMAL(10,7) NULL,
                 utama TINYINT(1) DEFAULT 0)

-- 3. Favorit
favorit(id_favorit PK, id_pelanggan FK, tipe ENUM('produk','umkm'),
        id_ref BIGINT, created_at TIMESTAMP)

-- 4. Notifikasi
notifikasi(id_notifikasi PK, id_pelanggan FK, tipe VARCHAR(30),
           judul VARCHAR(150), pesan TEXT, id_pesanan VARCHAR(50) NULL,
           dibaca TINYINT(1) DEFAULT 0, created_at TIMESTAMP)
```

### 7.2 Kolom baru pada `pesanan`
```sql
kode_pesanan        VARCHAR(30)  NULL   -- untuk tampilan, mis. "#DJN-20260915-0001"
alasan_batal        VARCHAR(255) NULL
dibayar_pada        DATETIME     NULL
midtrans_order_id   VARCHAR(100) NULL
midtrans_snap_token VARCHAR(255) NULL
midtrans_status     VARCHAR(50)  NULL
```

### 7.3 Kolom baru pada `umkm` (untuk tampilan katalog mobile)
```sql
rating        DECIMAL(3,2) DEFAULT 0   -- atau hitung dari tabel ulasan
jumlah_ulasan INT          DEFAULT 0
```

---

## 9. Urutan Implementasi Backend

1. **Selaraskan enum & status** (§2.6, §6) — tanpa ini data campur aduk.
2. Jalankan migrasi tabel baru (§7.1) + kolom (§7.2, §7.3).
3. Auth pelanggan (§5.1) + buku alamat (§5.2).
4. Katalog publik (§5.3) + ongkir (§5.4).
5. Pesanan pelanggan (§5.5) + favorit (§5.6) + notifikasi (§5.7).
6. Midtrans: buat `snap_token` (§5.5) + webhook (§5.5) → sambungkan ke `markAsPaidViaMidtrans`.
7. Ganti data in-memory di `djajan_mobile` (`SampleCatalog`, `OrderService`, `FavoriteService`,
   `NotificationService`) dengan `ApiClient` sungguhan.

---

## 10. Pertanyaan Terbuka (butuh keputusan)

### 9.1 Pesanan lintas UMKM
Satu keranjang di mobile bisa berisi produk dari 2+ UMKM, tapi `pesanan` hanya punya 1 `id_umkm`.
- **Opsi A (rekomendasi):** pecah otomatis jadi N pesanan (1 per UMKM), masing-masing dikonfirmasi
  UMKM sendiri; simpan `kode_checkout` untuk mengelompokkan. Skema tidak berubah.
- **Opsi B:** tambah `id_umkm` di `detail_pesanan`, izinkan 1 pesanan campur. Perlu ubah relasi &
  logika status/stok jadi per UMKM.

### 9.2 Status pesanan
Pakai 6 status mobile (§6) atau tetap 4 status lama (`po_baru|diterima|ditolak|selesai`)?
Kalau tetap 4, UI mobile harus dipetakan ulang (mis. `reviewing`+`processing` → `diterima`).

### 9.3 Bayar & konfirmasi
- Apakah UMKM wajib **menerima** dulu sebelum pelanggan bayar, atau bayar dulu baru diproses?
- Batas konfirmasi (`batas_konfirmasi`) diisi berapa jam setelah pesanan masuk?

### 9.4 Rating & ulasan
`Umkm.rating`/`distanceKm` belum ada di DB. Pakai tabel ulasan (`ulasan`) atau kolom agregat?
Jarak dihitung dari GPS pelanggan atau dari buku alamat?

### 9.5 Identitas
- Apakah role Pelanggan & role UMKM memakai satu akun (kolom `umkm.id_pelanggan` mengisyaratkan
  pelanggan bisa "naik kelas" jadi UMKM)?
- Verifikasi UMKM oleh admin desa: otomatis `terverifikasi` atau menunggu review (`verifikasi_umkm`)?

---

## 11. Lampiran — Endpoint Mobile Saat Ini (data palsu yang harus diganti)

| Fitur mobile | Sumber palsu sekarang | Endpoint target |
|---|---|---|
| Katalog UMKM & produk | `lib/data/sample_catalog.dart` | §5.3 |
| Pesanan | `SampleData` di `order_service.dart` | §5.5 |
| Favorit | `favorite_service.dart` (memori) | §5.6 |
| Notifikasi | `notification_service.dart` (memori) | §5.7 |
| Login/Register | layar ada, belum tersambung | §5.1 |
| Bukti transfer | file di memori saja | `POST /api/pesanan_bukti` |
| Midtrans | token palsu (simulasi) | §5.5 + webhook |
