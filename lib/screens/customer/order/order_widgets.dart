import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/app_config.dart';
import 'order_model.dart';

/// Palet tunggal untuk seluruh halaman pesanan.
///
/// Sengaja memakai hijau brand Djajan + warna netral saja, supaya halaman
/// keranjang/checkout/pesanan terasa satu aplikasi dengan halaman lain.
/// (Sebelumnya halaman ini memakai palet lavender-biru yang lepas dari brand.)
class OC {
  static const Color primary = AppConfig.primaryColor; // #175D2B
  static const Color primarySoft = Color(0xFFEAF3EC);
  static const Color accent = AppConfig.secondaryColor; // #FFBE25

  static const Color bg = Color(0xFFF6F7F6);
  static const Color card = Colors.white;

  static const Color ink = Color(0xFF16201A);
  static const Color muted = Color(0xFF5F6B64);
  static const Color faint = Color(0xFF98A29C);
  static const Color line = Color(0xFFE8EAE8);

  static const Color box = Color(0xFFF4F6F4); // blok informasi netral
  static const Color banner = Color(0xFFEDF4EE); // banner hijau muda

  static const Color mint = Color(0xFFDCEFE1); // chip hijau
  static const Color mintSoft = Color(0xFFEDF6EF); // keadaan terpilih
  static const Color mintText = Color(0xFF14532D);

  static const Color peach = Color(0xFFFDF0D9); // chip pre-order
  static const Color peachSoft = Color(0xFFFFF7EA);
  static const Color amber = Color(0xFF8A5A00);

  static const Color danger = Color(0xFFBA1A1A);
  static const Color dangerSoft = Color(0xFFFDE7E4);
}

/// Skala tipografi bersama untuk seluruh halaman pesanan.
///
/// Tujuannya supaya ukuran teks konsisten antar halaman. Sebelumnya banyak
/// judul berukuran 20-27px yang saling berebut perhatian sehingga tidak ada
/// hierarki (nama UMKM sekaligus judul halaman sekaligus total pembayaran).
class OT {
  /// Judul halaman, mis. "Pesanan Saya".
  static const TextStyle pageTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: OC.ink,
    height: 1.2,
  );

  /// Judul di dalam kartu, mis. "Rincian Pembayaran".
  static const TextStyle cardTitle = TextStyle(
    fontSize: 15.5,
    fontWeight: FontWeight.w700,
    color: OC.ink,
    height: 1.2,
  );

  /// Judul bagian di dalam satu halaman (di bawah judul halaman).
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w800,
    color: OC.ink,
    height: 1.2,
  );

  /// Nama produk / baris penting.
  static const TextStyle item = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w600,
    color: OC.ink,
  );

  /// Label kecil huruf besar, mis. "CATATAN KHUSUS".
  static const TextStyle label = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: OC.muted,
    letterSpacing: 0.4,
  );

  /// Teks isi.
  static const TextStyle body = TextStyle(
    fontSize: 13,
    color: OC.ink,
    height: 1.35,
  );

  /// Teks pendukung.
  static const TextStyle secondary = TextStyle(fontSize: 12.5, color: OC.muted);

  /// Teks paling kecil / samar.
  static const TextStyle caption = TextStyle(fontSize: 11.5, color: OC.faint);

  /// Angka uang ukuran sedang.
  static const TextStyle money = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w800,
    color: OC.ink,
  );

  /// Angka uang ukuran besar (total).
  static const TextStyle moneyLarge = TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w800,
    color: OC.primary,
  );
}

// ------------------------------------------------------------ Header Reusable

/// Header standar untuk halaman utama Djajan.
/// Digunakan di Home, Pesanan, Keranjang, Profil untuk konsistensi.
class DjajanPageHeader extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget? leftWidget; // Custom widget (mis. location picker di Home)
  final Widget? rightAction; // Notification badge, settings icon, etc.
  final EdgeInsets padding;

  const DjajanPageHeader({
    super.key,
    this.title,
    this.subtitle,
    this.leftWidget,
    this.rightAction,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 8),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side: title+subtitle atau custom widget
          Expanded(
            child: leftWidget ??
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null)
                      Text(
                        title!,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: OC.ink,
                        ),
                      ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: OC.muted,
                        ),
                      ),
                    ],
                  ],
                ),
          ),
          // Right action
          if (rightAction != null) ...[
            const SizedBox(width: 12),
            rightAction!,
          ],
        ],
      ),
    );
  }
}

// ------------------------------------------------------------ formatters

String rupiah(num v) {
  final neg = v < 0;
  final s = v.abs().round().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return '${neg ? '-' : ''}Rp $buf';
}

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sept',
  'Okt',
  'Nov',
  'Des',
];

String _t(int v) => v.toString().padLeft(2, '0');

String fmtDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';
String fmtTime(DateTime d) => '${_t(d.hour)}:${_t(d.minute)} WIB';
String fmtDateTime(DateTime d) => '${fmtDate(d)} (${fmtTime(d)})';
String fmtDateComma(DateTime d) => '${fmtDate(d)}, ${fmtTime(d)}';

// --------------------------------------------------------------- helpers

void showToast(BuildContext context, String message, {bool error = false}) {
  final m = ScaffoldMessenger.of(context);
  m.hideCurrentSnackBar();
  m.showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      backgroundColor: error ? OC.danger : OC.ink,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ),
  );
}

Future<void> copyText(BuildContext context, String text, String message) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (context.mounted) showToast(context, message);
}

String _waNumber(String phone) {
  var d = phone.replaceAll(RegExp(r'[^0-9]'), '');
  if (d.startsWith('0')) d = '62${d.substring(1)}';
  return d;
}

Future<void> openWhatsApp(
  BuildContext context, {
  required String phone,
  required String message,
}) async {
  final uri = Uri.parse(
    'https://wa.me/${_waNumber(phone)}?text=${Uri.encodeComponent(message)}',
  );
  var ok = false;
  try {
    ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    ok = false;
  }
  if (!ok && context.mounted) {
    await copyText(
      context,
      uri.toString(),
      'WhatsApp tidak dapat dibuka. Tautan disalin.',
    );
  }
}

/// Nomor WhatsApp UMKM (contoh; nanti diambil dari data UMKM di backend).
const String kUmkmWhatsApp = '081234567890';

// ---------------------------------------------------------------- widgets

class OrderHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onBack;
  final Widget? trailing;

  const OrderHeader({
    super.key,
    required this.title,
    this.subtitle = 'Djajan · Dari Desa',
    this.onBack,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: OC.line)),
      ),
      padding: EdgeInsets.fromLTRB(
        4,
        MediaQuery.of(context).padding.top + 4,
        12,
        8,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: OC.ink, size: 22),
            onPressed: onBack ?? () => Navigator.maybePop(context),
          ),
          Image.asset(
            'assets/images/logoNoBg.png',
            width: 34,
            height: 34,
            errorBuilder: (_, _, _) =>
                const Icon(Icons.eco, color: OC.primary, size: 28),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: OC.ink,
                    height: 1.2,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: OC.muted,
                  ),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Kartu dengan Header berwarna (Style Paket 1: Struktur Tegas)
class TitledCard extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget child;
  final Widget? trailing;

  const TitledCard({
    super.key, 
    required this.title, 
    this.icon, 
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OC.line),
        boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: OC.primarySoft,
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: OC.primary),
                  const SizedBox(width: 8),
                ],
                Expanded(child: Text(title.toUpperCase(), style: OT.label.copyWith(color: OC.primary, fontWeight: FontWeight.bold))),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: child,
          ),
        ],
      ),
    );
  }
}

class OrderCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;

  const OrderCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OC.line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class Pill extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  final IconData? icon;
  final double fontSize;

  /// true jika Pill berada di dalam Flexible/Expanded dan teks boleh dipotong.
  final bool shrink;

  const Pill({
    super.key,
    required this.text,
    required this.bg,
    required this.fg,
    this.icon,
    this.fontSize = 11,
    this.shrink = false,
  });

  @override
  Widget build(BuildContext context) {
    final label = Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        color: fg,
        letterSpacing: 0.3,
      ),
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 2, color: fg),
            const SizedBox(width: 4),
          ],
          if (shrink) Flexible(child: label) else label,
        ],
      ),
    );
  }
}

class IconBadge extends StatelessWidget {
  final IconData icon;
  final Color bg;
  final Color fg;
  final double size;

  const IconBadge({
    super.key,
    required this.icon,
    required this.bg,
    required this.fg,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Icon(icon, color: fg, size: size * 0.5),
    );
  }
}

/// Gambar dari URL (Google/Unsplash dll). Aman jika URL rusak / offline.
class NetImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final double radius;

  const NetImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.radius = 10,
  });

  Widget _placeholder() => Container(
    width: width,
    height: height,
    color: OC.box,
    child: const Icon(Icons.restaurant, color: OC.faint),
  );

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: url.isEmpty
          ? _placeholder()
          : Image.network(
              url,
              width: width,
              height: height,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _placeholder(),
              loadingBuilder: (c, child, p) =>
                  p == null ? child : _placeholder(),
            ),
    );
  }
}

class TitleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;

  const TitleRow({
    super.key,
    required this.icon,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: OC.primary, size: 22),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: OC.ink,
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class MoneyRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final Widget? labelTrailing;

  const MoneyRow({
    super.key,
    required this.label,
    required this.value,
    this.color,
    this.labelTrailing,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? OC.muted;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: c)),
          if (labelTrailing != null) ...[
            const SizedBox(width: 4),
            labelTrailing!,
          ],
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color ?? OC.ink,
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------- input filters

/// Filter ketikan: karakter yang tidak diizinkan langsung tidak bisa diketik.
/// (Validasi akhir tetap dilakukan oleh OrderValidator.)
class OrderInput {
  static const String _l = r'A-Za-z\u00C0-\u024F';

  static final List<TextInputFormatter> name = [
    FilteringTextInputFormatter.allow(RegExp("[$_l .'\\-]")),
    LengthLimitingTextInputFormatter(50),
  ];

  static final List<TextInputFormatter> phone = [
    FilteringTextInputFormatter.allow(RegExp(r'[0-9+\- ]')),
    LengthLimitingTextInputFormatter(17),
  ];

  static final List<TextInputFormatter> address = [
    FilteringTextInputFormatter.allow(
      RegExp(
        "[$_l"
        r"0-9 .,/\-\n]",
      ),
    ),
    LengthLimitingTextInputFormatter(150),
  ];

  static final List<TextInputFormatter> landmark = [
    FilteringTextInputFormatter.allow(
      RegExp(
        "[$_l"
        r"0-9 .,/\-']",
      ),
    ),
    LengthLimitingTextInputFormatter(80),
  ];

  static final List<TextInputFormatter> purpose = [
    FilteringTextInputFormatter.allow(
      RegExp(
        "[$_l"
        r"0-9 .,/\-'&()]",
      ),
    ),
    LengthLimitingTextInputFormatter(60),
  ];

  static final List<TextInputFormatter> packing = [
    FilteringTextInputFormatter.allow(
      RegExp(
        "[$_l"
        r"""0-9 .,!?/\-'&()":;\n]""",
      ),
    ),
    LengthLimitingTextInputFormatter(120),
  ];
}

// ------------------------------------------------------ recipient editor

/// Sheet ubah kontak & alamat. Semua isian divalidasi; hasil sudah dinormalisasi.
Future<Recipient?> showRecipientSheet(
  BuildContext context,
  Recipient initial,
) async {
  final name = TextEditingController(text: initial.name);
  final phone = TextEditingController(text: initial.phone);
  final address = TextEditingController(text: initial.address);
  final note = TextEditingController(text: initial.addressNote ?? '');
  final formKey = GlobalKey<FormState>();

  InputDecoration deco(String label, IconData icon, {String? hint}) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: OC.primary),
        filled: true,
        fillColor: OC.box,
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: OC.danger, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: OC.danger, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: OC.primary, width: 1.5),
        ),
      );

  return await showModalBottomSheet<Recipient>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ubah Kontak & Alamat',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: OC.ink,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: name,
                    inputFormatters: OrderInput.name,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: deco(
                      'Nama penerima',
                      Icons.person_outline,
                      hint: 'Contoh: Muhammad Rizki',
                    ),
                    validator: OrderValidator.name,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phone,
                    inputFormatters: OrderInput.phone,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    decoration: deco(
                      'Nomor WhatsApp',
                      Icons.phone_outlined,
                      hint: '0812-3456-7890 atau +62 812...',
                    ),
                    validator: OrderValidator.phone,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: address,
                    inputFormatters: OrderInput.address,
                    keyboardType: TextInputType.streetAddress,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 3,
                    minLines: 2,
                    decoration: deco(
                      'Alamat lengkap',
                      Icons.location_on_outlined,
                      hint: 'Jl. Merpati No. 14, RT 02 / RW 01, Desa ...',
                    ),
                    validator: OrderValidator.address,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: note,
                    inputFormatters: OrderInput.landmark,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: deco(
                      'Patokan (opsional)',
                      Icons.home_outlined,
                      hint: 'Rumah pagar hijau samping pos ronda',
                    ),
                    validator: OrderValidator.landmark,
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: OC.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        if (!formKey.currentState!.validate()) return;
                        Navigator.pop(
                          ctx,
                          OrderValidator.normalizeRecipient(
                            Recipient(
                              name: name.text,
                              phone: phone.text,
                              address: address.text,
                              addressNote: note.text,
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        'Simpan',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
    },
  );
}
