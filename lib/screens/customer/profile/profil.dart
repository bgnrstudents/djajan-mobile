import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../config/app_config.dart';
import '../../../routes/app_routes.dart';
import '../favorite/favorite_screen.dart';
import '../favorite/favorite_service.dart';
import '../order/order_widgets.dart';

const String kreonganKeyword = 'kreongan';

class ProfileUser {
  final String name;
  final String phoneNumber;

  const ProfileUser({required this.name, required this.phoneNumber});
}

class ProfileFormField {
  final String label;
  final String initialValue;
  final TextInputType keyboardType;
  final int maxLines;
  final String? helperText;
  final bool requiresKreongan;
  final bool requiredField;
  final IconData? prefixIcon;

  const ProfileFormField({
    required this.label,
    required this.initialValue,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.helperText,
    this.requiresKreongan = false,
    this.requiredField = true,
    this.prefixIcon,
  });
}

class ProfileMenuItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    this.trailing,
    this.onTap,
  });
}

void showProfileHelp(BuildContext context) {
  const primaryColor = AppConfig.primaryColor;
  const inkColor = Color(0xFF1E293B);
  const mutedColor = Color(0xFF64748B);

  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      icon: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFFEAF3EC),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(
          Icons.headset_mic_outlined,
          color: primaryColor,
          size: 32,
        ),
      ),
      title: const Text(
        'Pusat Bantuan',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: inkColor,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Butuh bantuan dengan pesanan atau akun? Hubungi Admin Djajan via WhatsApp.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: mutedColor,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.phone, size: 16, color: primaryColor),
                    SizedBox(width: 8),
                    SelectableText(
                      '0812-3456-7890',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: inkColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  'Layanan: Setiap hari, 08.00 - 20.00 WIB',
                  style: TextStyle(fontSize: 12, color: mutedColor),
                ),
              ],
            ),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () async {
            await Clipboard.setData(
              const ClipboardData(text: '081234567890'),
            );
            if (!context.mounted) return;
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Nomor admin berhasil disalin'),
                backgroundColor: primaryColor,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          child: const Text('Salin Nomor'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup'),
        ),
      ],
    ),
  );
}

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  bool _notificationsEnabled = true;
  String _addressLabel = 'Kantor';
  String _address = 'RT 02 / RW 01 Kreongan';
  String? _businessName;
  String? _businessAddress;

  ProfileUser _user = const ProfileUser(
    name: 'Della',
    phoneNumber: '0812-3456-7890',
  );

  List<ProfileFormField> get _accountFields => [
    ProfileFormField(label: 'Nama Lengkap', initialValue: _user.name, prefixIcon: Icons.person_outline),
    ProfileFormField(
      label: 'Nomor Handphone',
      initialValue: _user.phoneNumber,
      keyboardType: TextInputType.phone,
      prefixIcon: Icons.phone_outlined,
    ),
    const ProfileFormField(
      label: 'Email',
      initialValue: 'della@email.com',
      keyboardType: TextInputType.emailAddress,
      prefixIcon: Icons.email_outlined,
    ),
  ];

  List<ProfileFormField> get _addressFields => [
    ProfileFormField(label: 'Label Alamat', initialValue: _addressLabel, prefixIcon: Icons.label_outline),
    ProfileFormField(
      label: 'Alamat Lengkap',
      initialValue: _address,
      maxLines: 3,
      prefixIcon: Icons.location_on_outlined,
    ),
    const ProfileFormField(
      label: 'Patokan',
      initialValue: '',
      requiredField: false,
      prefixIcon: Icons.near_me_outlined,
    ),
  ];

  List<ProfileFormField> get _businessFields => [
    ProfileFormField(label: 'Nama Usaha', initialValue: _businessName ?? '', prefixIcon: Icons.storefront_outlined),
    ProfileFormField(label: 'Nama Pemilik', initialValue: _user.name, prefixIcon: Icons.badge_outlined),
    ProfileFormField(
      label: 'Nomor Handphone',
      initialValue: _user.phoneNumber,
      keyboardType: TextInputType.phone,
      prefixIcon: Icons.phone_outlined,
    ),
    ProfileFormField(
      label: 'Alamat Usaha di Kreongan',
      initialValue: _businessAddress ?? '',
      maxLines: 3,
      helperText: 'Pendaftaran usaha hanya untuk warga Kreongan.',
      requiresKreongan: true,
      prefixIcon: Icons.location_on_outlined,
    ),
  ];

  List<ProfileMenuItem> get _menuItems => [
    ProfileMenuItem(
      icon: Icons.favorite_border,
      title: 'Favorit Saya',
      subtitle: _favoriteSubtitle,
      iconColor: const Color(0xFFE11D48),
      onTap: _openFavorites,
    ),
    ProfileMenuItem(
      icon: Icons.location_on_outlined,
      title: 'Daftar Alamat Pengiriman',
      subtitle: '$_addressLabel: $_address',
      iconColor: const Color(0xFF45B7C8),
      onTap: _openAddressForm,
    ),
    ProfileMenuItem(
      icon: Icons.notifications_none,
      title: 'Notifikasi Pesanan',
      subtitle: 'Pemberitahuan status kiriman & promo',
      iconColor: const Color(0xFFFFB43A),
      trailing: Switch.adaptive(
        value: _notificationsEnabled,
        onChanged: _setNotificationsEnabled,
      ),
    ),
    if (_businessName != null)
      ProfileMenuItem(
        icon: Icons.storefront_outlined,
        title: 'Hapus Status Mitra',
        subtitle: 'Kembali menggunakan akun sebagai pelanggan biasa',
        iconColor: const Color(0xFFE67E22),
        onTap: _confirmRemoveBusiness,
      ),
    ProfileMenuItem(
      icon: Icons.info_outline,
      title: 'Tentang Djajan',
      subtitle: 'Pemberdayaan warung & petani desa',
      iconColor: const Color(0xFF7094B6),
      onTap: _openAboutDjajan,
    ),
    ProfileMenuItem(
      icon: Icons.logout,
      title: 'Keluar Akun',
      subtitle: 'Selesaikan sesi belanja di perangkat ini',
      iconColor: const Color(0xFFEF6461),
      onTap: _confirmLogout,
    ),
  ];

  String get _favoriteSubtitle {
    final favorites = FavoriteService();
    if (favorites.isEmpty) {
      return 'Simpan produk & warung langganan Anda';
    }
    return '${favorites.productCount} produk • ${favorites.umkmCount} UMKM disimpan';
  }

  void _openFavorites() {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (_) => const FavoriteScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: FavoriteService(),
      builder: (context, _) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DjajanPageHeader(
              title: 'Profil Saya',
              subtitle: 'Kelola akun dan preferensi belanja lokal Anda',
              rightAction: Icon(Icons.settings_outlined, color: OC.muted, size: 24),
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),
            _ProfileHeader(
              user: _user,
              businessName: _businessName,
              onEdit: _editProfile,
            ),
            const SizedBox(height: 14),
            _PromoBanner(
              businessName: _businessName,
              onTap: _openBusinessRegistration,
            ),
            const SizedBox(height: 14),
            _ProfileMenu(items: _menuItems),
            const SizedBox(height: 20),
            const _SafetyNotice(),
          ],
        ),
      ),
    );
  }

  void _editProfile() {
    if (_businessName == null) {
      _openAccountForm();
      return;
    }

    _openBusinessRegistration(editing: true);
  }

  Future<void> _openAccountForm() async {
    final values = await _openFormPage(
      title: 'Informasi Akun',
      subtitle: 'Perbarui data diri Anda',
      icon: Icons.person_outline,
      fields: _accountFields,
    );

    if (values == null || !mounted) return;

    setState(() {
      _user = ProfileUser(
        name: values['Nama Lengkap']!,
        phoneNumber: values['Nomor Handphone']!,
      );
    });
  }

  Future<void> _openAddressForm() async {
    final values = await _openFormPage(
      title: 'Alamat Pengiriman',
      subtitle: 'Pastikan alamat akurat untuk pengantaran',
      icon: Icons.location_on_outlined,
      fields: _addressFields,
    );

    if (values == null || !mounted) return;

    setState(() {
      _addressLabel = values['Label Alamat']!;
      _address = values['Alamat Lengkap']!;
    });
  }

  Future<void> _openBusinessRegistration({bool editing = false}) async {
    final values = await _openFormPage(
      title: editing ? 'Edit Data Usaha' : 'Daftarkan Usaha',
      subtitle: editing
          ? 'Perbarui informasi UMKM Anda'
          : 'Bergabung sebagai mitra UMKM Djajan',
      icon: Icons.storefront_outlined,
      fields: _businessFields,
    );

    if (values == null || !mounted) return;

    setState(() {
      _businessName = values['Nama Usaha'];
      _businessAddress = values['Alamat Usaha di Kreongan'];
    });
  }

  Future<void> _confirmRemoveBusiness() async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus status mitra?'),
        content: const Text(
          'Usaha akan dihapus dari profil, tetapi akun tetap dapat digunakan sebagai pelanggan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus Usaha'),
          ),
        ],
      ),
    );

    if (shouldRemove == true && mounted) {
      setState(() {
        _businessName = null;
        _businessAddress = null;
      });
    }
  }

  void _setNotificationsEnabled(bool value) {
    setState(() => _notificationsEnabled = value);
  }

  void _openAboutDjajan() {
    _openSimplePage(
      title: 'Tentang Djajan',
      message:
          'Djajan adalah platform pemesanan makanan dan jajanan hyperlocal yang memberdayakan UMKM di Desa Kreyongan Atas.\n\n'
          'Kami percaya setiap warung, dapur, dan kerajinan warga punya potensi besar untuk berkembang.\n\n'
          'Djajan membantu menghubungkan tetangga dengan produk lokal berkualitas, '
          'memperkuat ekonomi desa, dan menjaga cita rasa otentik kuliner rumahan.',
      icon: Icons.eco,
    );
  }

  void _openSimplePage({
    required String title,
    required String message,
    required IconData icon,
  }) {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => _InfoPage(title: title, message: message, icon: icon),
      ),
    );
  }

  Future<Map<String, String>?> _openFormPage({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<ProfileFormField> fields,
  }) {
    return Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute<Map<String, String>>(
        builder: (_) => _ProfileFormPage(
          title: title,
          subtitle: subtitle,
          icon: icon,
          fields: fields,
        ),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text('Sesi belanja di perangkat ini akan diakhiri.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
    }
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.user,
    required this.businessName,
    required this.onEdit,
  });

  final ProfileUser user;
  final String? businessName;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppConfig.primaryColor,
            child: Text(
              _initials(businessName ?? user.name),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  businessName ?? user.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  businessName == null
                      ? user.phoneNumber
                      : 'Mitra Usaha Desa • ${user.name}',
                  style: _mutedTextStyle,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit profil',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFEAF4EE),
              foregroundColor: AppConfig.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.take(2).map((part) => part[0]).join().toUpperCase();
  }
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner({required this.businessName, required this.onTap});

  final String? businessName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppConfig.primaryColor,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.storefront, color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Mitra Usaha Desa',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    businessName == null
                        ? 'Punya Usaha di Kreongan Atas?'
                        : '$businessName sudah terdaftar',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    businessName == null
                        ? 'Jangkau lebih banyak pembeli lewat Djajan.'
                        : 'Data usaha tersimpan di profil Anda.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.arrow_forward, size: 15),
                    label: Text(
                      businessName == null
                          ? 'Daftarkan Usaha Saya'
                          : 'Ubah Data Usaha',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppConfig.primaryColor,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.eco, size: 64, color: Colors.white24),
          ],
        ),
      ),
    );
  }
}

class _ProfileMenu extends StatelessWidget {
  const _ProfileMenu({required this.items});

  final List<ProfileMenuItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E8F0)),
      ),
      child: Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            _ProfileMenuTile(item: items[index]),
            if (index < items.length - 1)
              const Divider(height: 1, indent: 64, endIndent: 16),
          ],
        ],
      ),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  const _ProfileMenuTile({required this.item});

  final ProfileMenuItem item;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: item.onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      leading: CircleAvatar(
        radius: 17,
        backgroundColor: item.iconColor.withValues(alpha: 0.15),
        foregroundColor: item.iconColor,
        child: Icon(item.icon, size: 19),
      ),
      title: Text(
        item.title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(item.subtitle, style: _mutedTextStyle),
      trailing: item.trailing ?? const Icon(Icons.chevron_right, size: 20),
    );
  }
}

class _InfoPage extends StatelessWidget {
  const _InfoPage({
    required this.title,
    required this.message,
    required this.icon,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    const primaryColor = AppConfig.primaryColor;
    const inkColor = Color(0xFF1E293B);
    const mutedColor = Color(0xFF64748B);
    const bgColor = Color(0xFFF8F9FD);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: inkColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: inkColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF3EC),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(icon, color: primaryColor, size: 40),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: inkColor,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: mutedColor,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileFormPage extends StatefulWidget {
  const _ProfileFormPage({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.fields,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<ProfileFormField> fields;

  @override
  State<_ProfileFormPage> createState() => _ProfileFormPageState();
}

class _ProfileFormPageState extends State<_ProfileFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final List<TextEditingController> _controllers;

  static const primaryColor = AppConfig.primaryColor;
  static const inkColor = Color(0xFF1E293B);
  static const mutedColor = Color(0xFF64748B);
  static const faintColor = Color(0xFF94A3B8);
  static const lineColor = Color(0xFFE2E8F0);
  static const bgColor = Color(0xFFF8F9FD);

  @override
  void initState() {
    super.initState();
    _controllers = [
      for (final field in widget.fields)
        TextEditingController(text: field.initialValue),
    ];
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: inkColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
            color: inkColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            // Header Info Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF3EC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(widget.icon, color: primaryColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: inkColor,
                          ),
                        ),
                        Text(
                          widget.subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: mutedColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Form Fields Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: lineColor),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var index = 0; index < widget.fields.length; index++) ...[
                    Text(
                      widget.fields[index].label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: inkColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _controllers[index],
                      keyboardType: widget.fields[index].keyboardType,
                      maxLines: widget.fields[index].maxLines,
                      decoration: InputDecoration(
                        hintText: 'Masukkan ${widget.fields[index].label.toLowerCase()}',
                        hintStyle: const TextStyle(
                          fontSize: 13.5,
                          color: faintColor,
                        ),
                        helperText: widget.fields[index].helperText,
                        helperStyle: const TextStyle(fontSize: 11.5, color: mutedColor),
                        prefixIcon: widget.fields[index].prefixIcon != null
                            ? Icon(
                                widget.fields[index].prefixIcon,
                                size: 20,
                                color: mutedColor,
                              )
                            : null,
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: lineColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: lineColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: primaryColor, width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFEF4444)),
                        ),
                      ),
                      validator: (value) {
                        if (widget.fields[index].requiredField &&
                            (value == null || value.trim().isEmpty)) {
                          return '${widget.fields[index].label} wajib diisi';
                        }
                        if (value != null &&
                            value.trim().isNotEmpty &&
                            widget.fields[index].requiresKreongan &&
                            !value.toLowerCase().contains(kreonganKeyword)) {
                          return 'Alamat usaha harus berada di wilayah Kreongan';
                        }
                        return null;
                      },
                    ),
                    if (index < widget.fields.length - 1)
                      const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: _saveForm,
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text(
                  'Simpan Perubahan',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveForm() {
    if (!_formKey.currentState!.validate()) return;

    final values = <String, String>{
      for (var index = 0; index < widget.fields.length; index++)
        widget.fields[index].label: _controllers[index].text.trim(),
    };

    Navigator.pop(context, values);
  }
}

class _SafetyNotice extends StatelessWidget {
  const _SafetyNotice();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Djajan Kreongan Atas, Untuk Semua Tetangga',
        style: TextStyle(fontSize: 10, color: AppConfig.secondaryTextColor),
      ),
    );
  }
}

const TextStyle _mutedTextStyle = TextStyle(
  color: AppConfig.secondaryTextColor,
  fontSize: 11,
);