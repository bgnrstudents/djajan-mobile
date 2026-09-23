# Djajan Mobile
Aplikasi mobile **Djajan** untuk mendukung pengelolaan dan pemasaran UMKM Desa Kreyongan Atas.
Project ini dikembangkan sebagai bagian dari tugas PjBL Semester 3 Teknik Informatika.
---
## 👥 Pembagian Tugas Tim
Setiap anggota bertanggung jawab terhadap satu bagian UI Mobile.
| No | Anggota | Bagian | Branch |
|---|---|---|---|
| 1 | Iyazz | Login / Register | `feature/login-register` |
| 2 | Rizki | Beranda | `feature/beranda` |
| 3 | Danda | Pesanan | `feature/pesanan` |
| 4 | Sukma | Keranjang | `feature/keranjang` |
| 5 | Dela | Profil | `feature/profil` |

Setiap anggota **wajib bekerja pada branch masing-masing** dan tidak langsung melakukan perubahan pada `main`.
---
## 📁 Struktur Project

Struktur utama project:

```text
lib/
├── main.dart
│
├── config/
│   └── app_config.dart
│
├── routes/
│   └── app_routes.dart
│
├── models/
│
├── services/
│
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   │
│   ├── customer/
│   │   ├── home/
│   │   ├── umkm/
│   │   ├── product/
│   │   ├── cart/
│   │   ├── checkout/
│   │   ├── order/
│   │   └── profile/
│   │
│   └── umkm/
│       ├── home/
│       ├── order/
│       ├── product/
│       └── business/
│
└── widgets/
```

### Folder yang digunakan untuk tugas UI saat ini

**Login / Register**

```text
lib/screens/auth/
```

PIC: **Iyazz**

**Beranda**

```text
lib/screens/customer/home/
```

PIC: **Rizki**

**Pesanan**

```text
lib/screens/customer/order/
```

PIC: **Danda**

**Keranjang**

```text
lib/screens/customer/cart/
```

PIC: **Sukma**

**Profil**

```text
lib/screens/customer/profile/
```

PIC: **Dela**

---

# 🌿 Git Branch

Branch digunakan agar setiap anggota dapat mengerjakan bagian masing-masing tanpa langsung mengubah `main`.

### Branch utama

```text
main
```

Branch `main` digunakan untuk versi project yang sudah digabungkan dan relatif stabil.

### Branch fitur

Format branch:

```text
feature/nama-fitur
```

Branch yang digunakan:

```text
feature/login-register
feature/beranda
feature/pesanan
feature/keranjang
feature/profil
```

---
# 🌱 Membuat Branch
Setelah clone repository, pastikan berada di `main`:

```bash
git checkout main
```

Ambil versi `main` terbaru:

```bash
git pull origin main
```

Kemudian buat branch sesuai tugas.

Contoh untuk bagian Beranda:

```bash
git checkout -b feature/beranda
```

Kemudian push branch pertama kali:

```bash
git push -u origin feature/beranda
```

Setelah itu, pekerjaan dilakukan di branch tersebut.

---

# 🔄 Workflow Pengerjaan

Gunakan workflow berikut:

```text
Clone Repository
       ↓
Update main
       ↓
Buat Branch
       ↓
Kerjakan UI
       ↓
Test
       ↓
git add
       ↓
git commit
       ↓
git push
       ↓
Pull Request
       ↓
Review
       ↓
Merge ke main
```

---

# 💾 Commit

Setiap perubahan yang sudah memiliki satu tujuan yang jelas sebaiknya dibuat menjadi commit.

### Format

```text
type: deskripsi perubahan
```

### Jenis Commit

| Type | Penggunaan |
|---|---|
| `feat` | Menambahkan fitur atau bagian UI baru |
| `fix` | Memperbaiki bug |
| `style` | Perubahan tampilan atau styling |
| `refactor` | Merapikan struktur kode tanpa mengubah fungsi utama |
| `chore` | Setup atau perubahan konfigurasi project |

### Contoh Commit yang Baik

```bash
git commit -m "feat: create customer home screen"
```

```bash
git commit -m "feat: add category section"
```

```bash
git commit -m "feat: add product cards"
```

```bash
git commit -m "style: improve home page spacing"
```

```bash
git commit -m "fix: fix product card overflow"
```

### Hindari Commit Message seperti

```text
update
fix
revisi
coba
final
final banget
fix lagi
udah jadi
```

Commit message harus menjelaskan **apa yang berubah**.

---

# 📤 Menyimpan Perubahan ke GitHub

Setelah melakukan perubahan:

### 1. Cek perubahan

```bash
git status
```

### 2. Tambahkan perubahan

```bash
git add .
```

### 3. Buat commit

Contoh:

```bash
git commit -m "feat: add category section"
```

### 4. Push ke GitHub

```bash
git push
```

Jika branch baru pertama kali di-push:

```bash
git push -u origin feature/nama-branch
```
# ⚠️ Aturan Penting

### 1. Jangan bekerja langsung di `main`

Jangan mengerjakan UI langsung pada branch `main`.

Gunakan branch masing-masing:

```text
feature/login-register
feature/beranda
feature/pesanan
feature/keranjang
feature/profil
```

### 2. Jangan mengubah bagian anggota lain tanpa koordinasi

Contoh:

Danda sedang mengerjakan:

```text
lib/screens/customer/order/
```

Maka anggota lain tidak perlu mengubah file di folder tersebut tanpa koordinasi.

### 3. File global harus dikoordinasikan

Beberapa file digunakan oleh seluruh project:

```text
main.dart
app_routes.dart
app_config.dart
pubspec.yaml
```

Jika perlu mengubah file tersebut, **komunikasikan terlebih dahulu di grup**.

Hal ini untuk mengurangi kemungkinan merge conflict.

### 4. Jangan membuat folder baru sembarangan

Sebelum membuat folder atau file baru, perhatikan struktur project yang sudah ada.

Jika membutuhkan struktur baru, diskusikan terlebih dahulu dengan tim.

### 5. Test sebelum push

Sebelum melakukan push, pastikan project masih dapat dijalankan.

Minimal jalankan:

```bash
flutter analyze
```

dan:

```bash
flutter run
```

---

# 🔄 Update Project dengan Main Terbaru

Sebelum mulai mengerjakan sesuatu, ambil perubahan terbaru dari `main`.

```bash
git checkout main
git pull origin main
```

Kemudian kembali ke branch masing-masing:

```bash
git checkout feature/nama-branch
```

Jika terdapat perubahan besar pada `main` yang perlu dimasukkan ke branch, komunikasikan terlebih dahulu dengan tim agar proses penggabungan tidak menyebabkan conflict.


# 👥 Tanggung Jawab Setiap Anggota

Setiap anggota bertanggung jawab terhadap:

- UI sesuai bagian yang telah ditentukan.
- Struktur kode pada folder masing-masing.
- Commit yang jelas.
- Push branch secara berkala.
- Testing bagian yang dikerjakan.
- Memberikan informasi jika terdapat perubahan pada file bersama.
- Menyelesaikan conflict jika perubahan yang dibuat menyebabkan konflik.

---

# 🎯 Tujuan Workflow

Workflow GitHub ini digunakan agar:

1. Setiap anggota memiliki bagian pekerjaan yang jelas.
2. Perubahan setiap anggota dapat dilacak melalui commit.
3. Pengerjaan tidak dilakukan langsung pada `main`.
4. Perubahan dapat direview sebelum digabungkan.
5. Riwayat pengembangan project dapat terlihat dengan jelas.
6. Tim terbiasa menggunakan workflow pengembangan software secara kolaboratif.

---

# 📞 Komunikasi Tim

Jika terjadi:

- Merge conflict
- Error setelah pull
- Perubahan pada file global
- Perubahan struktur folder
- Kebutuhan membuat file yang digunakan bersama
- Masalah dependency

Sampaikan terlebih dahulu di grup tim sebelum melakukan perubahan besar.

---

# 📚 Catatan

Project ini dikembangkan sebagai project akademik Semester 3.

Struktur dan workflow dapat berkembang sesuai kebutuhan project, tetapi perubahan yang memengaruhi anggota lain harus dikomunikasikan terlebih dahulu.

---

## Djajan

**Dari Desa, Untuk Semua.**
