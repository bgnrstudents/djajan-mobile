import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../config/api_config.dart';
import '../theme/app_theme.dart';

// ======================================================= NOTIFIKASI
void pesanSukses(BuildContext context, String teks) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle, color: Colors.white, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(teks)),
      ]),
      backgroundColor: AppColors.hijauTua,
    ));
}

void pesanGagal(BuildContext context, String teks) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline, color: Colors.white, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(teks)),
      ]),
      backgroundColor: AppColors.danger,
      duration: const Duration(seconds: 5),
    ));
}

// ======================================================= KARTU DASAR
class KartuPutih extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  const KartuPutih({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 18,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

class MiniBadge extends StatelessWidget {
  final String teks;
  final Color bg;
  final Color fg;
  final IconData? ikon;

  const MiniBadge(
    this.teks, {
    super.key,
    this.bg = AppColors.bgLavender,
    this.fg = AppColors.textDark,
    this.ikon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (ikon != null) ...[
            Icon(ikon, size: 11, color: fg),
            const SizedBox(width: 4),
          ],
          Text(teks,
              style: TextStyle(
                  fontSize: 10.5, color: fg, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ================================================== GAMBAR DARI SERVER =
/// Menyesuaikan URL gambar dari server agar selalu bisa diakses dari
/// perangkat yang sedang memakai aplikasi.
///
/// Server mengirim URL absolut berdasarkan APP_URL (mis. `127.0.0.1:8000`).
/// URL seperti itu tidak bisa dibuka dari emulator Android (`10.0.2.2`) atau
/// HP asli (IP LAN), jadi host-nya diganti dengan [ApiConfig.baseUrl].
///
/// Selain itu, path `/uploads/{folder}/{file}` diarahkan ke route Laravel
/// `/file_gambar/{folder}/{file}`. File di `/uploads/` disajikan langsung oleh
/// web server TANPA header CORS, sehingga Flutter Web (Chrome) menolak
/// memuatnya ("Gambar tidak bisa dimuat"). Route `/file_gambar` mengirim
/// file yang sama lengkap dengan header CORS.
String? sesuaikanUrlGambar(String? url) {
  if (url == null || url.trim().isEmpty) return null;

  final s = url.trim();

  // Ambil path (+ query) dari URL absolut maupun relatif.
  String path;
  String query = '';
  if (s.startsWith('http://') || s.startsWith('https://')) {
    try {
      final uri = Uri.parse(s);
      path = uri.path;
      query = uri.hasQuery ? '?${uri.query}' : '';
    } catch (_) {
      return s;
    }
  } else {
    path = '/${s.replaceFirst(RegExp(r'^/+'), '')}';
  }

  // /uploads/produk/x.jpg  ->  /file_gambar/produk/x.jpg
  final cocok = RegExp(r'^/uploads/(produk|profil)/([^/]+)$').firstMatch(path);
  if (cocok != null) {
    return '${ApiConfig.baseUrl}/file_gambar/${cocok.group(1)}/${cocok.group(2)}$query';
  }

  // Bukan file upload: pakai apa adanya (URL luar) atau tempel ke baseUrl.
  if (s.startsWith('http://') || s.startsWith('https://')) return s;
  return '${ApiConfig.baseUrl}$path$query';
}

/// Menampilkan gambar produk/profil dari server, lengkap dengan indikator
/// memuat dan tampilan cadangan bila gambar belum ada atau gagal dimuat.
class GambarJaringan extends StatelessWidget {
  final String? url;
  final double width;
  final double height;
  final double radius;
  final IconData ikonKosong;

  /// Gunakan timestamp atau hash pada [cacheBuster] jika gambar sering diupdate
  /// agar menghindari cache browser lama di Flutter Web.
  final String? cacheBuster;

  const GambarJaringan({
    super.key,
    required this.url,
    this.width = 60,
    this.height = 60,
    this.radius = 12,
    this.ikonKosong = Icons.image_outlined,
    this.cacheBuster,
  });

  @override
  Widget build(BuildContext context) {
    var urlFix = sesuaikanUrlGambar(url);
    if (urlFix != null && urlFix.isNotEmpty && cacheBuster != null) {
      urlFix += (urlFix.contains('?') ? '&' : '?') + 'cb=$cacheBuster';
    }

    final kosong = urlFix == null || urlFix.isEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: width,
        height: height,
        child: kosong
            ? _placeholder(ikonKosong)
            : Image.network(
                urlFix,
                key: ValueKey(urlFix),
                width: width,
                height: height,
                fit: BoxFit.cover,
                // Di Flutter Web: bila gambar ditolak karena CORS, pakai elemen
                // <img> HTML biasa yang tidak terkena aturan CORS.
                webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                errorBuilder: (_, __, ___) => _placeholder(ikonKosong),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: AppColors.krem,
                    alignment: Alignment.center,
                    child: const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.hijauTua),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _placeholder(IconData ikon) => Container(
        color: AppColors.krem,
        alignment: Alignment.center,
        child: Icon(ikon,
            color: AppColors.hijauTua.withValues(alpha: 0.55),
            size: width * 0.4),
      );
}

Future<void> tampilkanZoomGambarJaringan(
  BuildContext context,
  String? url,
) {
  final urlDasar = sesuaikanUrlGambar(url);
  if (urlDasar == null || urlDasar.isEmpty) return Future.value();
  final urlFix = '$urlDasar${urlDasar.contains('?') ? '&' : '?'}'
      'cb=${DateTime.now().millisecondsSinceEpoch}';

  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.86),
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          InteractiveViewer(
            minScale: 0.8,
            maxScale: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                urlFix,
                fit: BoxFit.contain,
                webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                errorBuilder: (_, __, ___) => Container(
                  padding: const EdgeInsets.all(24),
                  color: Colors.white12,
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.broken_image_outlined,
                          color: Colors.white70, size: 40),
                      SizedBox(height: 10),
                      Text(
                        'Gambar tidak bisa dimuat',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black54,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    ),
  );
}

/// Pratinjau gambar yang baru dipilih dari galeri/kamera (belum diunggah).
class PratinjauGambarLokal extends StatelessWidget {
  final Uint8List bytes;
  final double width;
  final double height;
  final double radius;

  const PratinjauGambarLokal({
    super.key,
    required this.bytes,
    this.width = 140,
    this.height = 140,
    this.radius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.memory(
        bytes,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(Icons.broken_image_outlined),
      ),
    );
  }

  Widget _placeholder(IconData ikon) => Container(
        color: AppColors.krem,
        alignment: Alignment.center,
        child: Icon(ikon,
            color: AppColors.hijauTua.withValues(alpha: 0.55),
            size: width * 0.4),
      );
}

Future<void> tampilkanZoomGambarLokal(
  BuildContext context,
  Uint8List bytes,
) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.86),
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          InteractiveViewer(
            minScale: 0.8,
            maxScale: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(bytes, fit: BoxFit.contain),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black54,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    ),
  );
}

// ================================================ PEMILIH SUMBER FOTO
/// Menampilkan pilihan Kamera / Galeri lalu mengembalikan file terpilih.
Future<XFile?> pilihGambar(BuildContext context,
    {bool bolehHapus = false}) async {
  final picker = ImagePicker();

  final pilihan = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.garis,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 14),
          const Text('Pilih Sumber Foto',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 6),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppColors.chipGreenBg,
              child:
                  Icon(Icons.photo_library_outlined, color: AppColors.hijauTua),
            ),
            title: const Text('Ambil dari Galeri'),
            subtitle:
                const Text('Pilih foto yang sudah tersimpan di perangkat'),
            onTap: () => Navigator.pop(ctx, 'galeri'),
          ),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppColors.chipOrange,
              child: Icon(Icons.photo_camera_outlined,
                  color: AppColors.chipOrangeText),
            ),
            title: const Text('Foto Langsung dengan Kamera'),
            subtitle: const Text('Ambil foto produk saat ini juga'),
            onTap: () => Navigator.pop(ctx, 'kamera'),
          ),
          const SizedBox(height: 10),
        ],
      ),
    ),
  );

  if (pilihan == null) return null;

  // Gambar dikompres agar hemat kuota dan cepat saat diunggah.
  return picker.pickImage(
    source: pilihan == 'kamera' ? ImageSource.camera : ImageSource.gallery,
    maxWidth: 1280,
    imageQuality: 80,
  );
}

// ================================================= STATE KOSONG/ERROR
class TampilanKosong extends StatelessWidget {
  final IconData ikon;
  final String judul;
  final String pesan;
  final Widget? aksi;

  const TampilanKosong({
    super.key,
    required this.ikon,
    required this.judul,
    required this.pesan,
    this.aksi,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                  color: AppColors.krem, shape: BoxShape.circle),
              child: Icon(ikon, size: 40, color: AppColors.hijauTua),
            ),
            const SizedBox(height: 16),
            Text(judul,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 16.5)),
            const SizedBox(height: 6),
            Text(pesan,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(color: AppColors.textGrey, fontSize: 13.5)),
            if (aksi != null) ...[const SizedBox(height: 18), aksi!],
          ],
        ),
      ),
    );
  }
}

class TampilanError extends StatelessWidget {
  final String pesan;
  final VoidCallback onCobaLagi;

  const TampilanError(
      {super.key, required this.pesan, required this.onCobaLagi});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                  color: AppColors.dangerBg, shape: BoxShape.circle),
              child: const Icon(Icons.wifi_off_rounded,
                  size: 38, color: AppColors.danger),
            ),
            const SizedBox(height: 16),
            const Text('Gagal Memuat Data',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16.5)),
            const SizedBox(height: 8),
            Text(pesan,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(color: AppColors.textGrey, fontSize: 13)),
            const SizedBox(height: 20),
            SizedBox(
              width: 200,
              child: ElevatedButton.icon(
                onPressed: onCobaLagi,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ========================================================= LOGO DJAJAN
/// Ikon (lambang) Djajan tanpa tulisan — dipakai pada AppBar / tombol kecil.
/// Sumber berkas: assets/images/logo_djajan_mark.png
class LogoDjajanIkon extends StatelessWidget {
  final double size;

  /// Bila true, ikon diletakkan di atas kotak putih membulat seperti
  /// versi app icon pada brand guideline.
  final bool berlatar;

  const LogoDjajanIkon({super.key, this.size = 36, this.berlatar = false});

  @override
  Widget build(BuildContext context) {
    final gambar = Image.asset(
      'assets/images/logo_djajan_mark.png',
      width: berlatar ? size * 0.72 : size,
      height: berlatar ? size * 0.72 : size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );

    if (!berlatar) return SizedBox(width: size, height: size, child: gambar);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: AppColors.garis),
      ),
      alignment: Alignment.center,
      child: gambar,
    );
  }
}

/// Logo lengkap Djajan (lambang + tulisan "Djajan" + tagline).
/// Sumber berkas: assets/images/logo_djajan.png
class LogoDjajanLengkap extends StatelessWidget {
  final double width;

  const LogoDjajanLengkap({super.key, this.width = 180});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo_djajan.png',
      width: width,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }
}