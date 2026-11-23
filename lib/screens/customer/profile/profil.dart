import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../config/app_config.dart';
import '../../../routes/app_routes.dart';
import '../favorite/favorite_screen.dart';
import '../../../services/favorite_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/order_service.dart';
import '../../../services/notification_service.dart';
import '../../../services/customer_settings_service.dart';
import '../../../services/api_service.dart';
import '../../../services/umkm_data_service.dart';
import '../../../models/customer_settings_models.dart';
import '../../../theme/app_theme.dart';
import 'alamat_form_page.dart';
import '../order/order_widgets.dart';
import '../../../widgets/umkm_app_bar.dart';
import '../../../widgets/osm_map_picker.dart';

const String kreonganKeyword = 'kreongan';

class ProfileUser {
  final String name;
  final String phoneNumber;
  final String email;

  const ProfileUser({
    required this.name,
    required this.phoneNumber,
    this.email = '',
  });
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
  final bool isLocationPicker;
  final double? initialLatitude;
  final double? initialLongitude;

  const ProfileFormField({
    required this.label,
    required this.initialValue,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.helperText,
    this.requiresKreongan = false,
    this.requiredField = true,
    this.prefixIcon,
    this.isLocationPicker = false,
    this.initialLatitude,
    this.initialLongitude,
  });
}

class ProfileMenuItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final Color? iconBg;
  final Color? iconBorderColor;
  final Color? textColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    this.iconBg,
    this.iconBorderColor,
    this.textColor,
    this.trailing,
    this.onTap,
  });
}

void showProfileHelp(BuildContext context) {
  const primaryColor = AppConfig.primaryColor;

  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      icon: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.hijauLembut,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD8EBD8)),
        ),
        child: const Icon(
          Icons.headset_mic_rounded,
          color: primaryColor,
          size: 32,
        ),
      ),
      title: const Text(
        'Pusat Bantuan',
        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Butuh bantuan dengan pesanan atau akun? Hubungi Admin Djajan via WhatsApp.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textGrey, height: 1.4),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.latar,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.garis),
            ),
            child: const Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.phone_rounded, size: 16, color: primaryColor),
                    SizedBox(width: 8),
                    SelectableText(
                      '0812-3456-7890',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  'Layanan: Setiap hari, 08.00 - 20.00 WIB',
                  style: TextStyle(fontSize: 12, color: AppColors.textGrey),
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
            await Clipboard.setData(const ClipboardData(text: '081234567890'));
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
  final CustomerSettingsService _settings = CustomerSettingsService();
  bool _notificationsEnabled = true;
  String? _businessName;
  String? _businessAddress;
  String? _businessStatus;
  String? _businessSpecialty;
  double? _businessLatitude;
  double? _businessLongitude;
  bool _loadingBusiness = false;

  ProfileUser _user = const ProfileUser(name: '', phoneNumber: '');

  @override
  void initState() {
    super.initState();
    final session = context.read<AuthService>().session;
    final data = session?.data;
    if (data != null) {
      _user = ProfileUser(
        name: data['nama']?.toString() ?? '',
        phoneNumber: data['no_telp']?.toString() ?? '',
        email: data['email']?.toString() ?? '',
      );
      if (data['umkm'] is Map) {
        final b = data['umkm'] as Map;
        _businessName = b['nama_usaha']?.toString();
        _businessAddress = b['alamat']?.toString();
        _businessSpecialty = b['spesialis']?.toString();
        _businessStatus = b['status_verifikasi']?.toString();
        _businessLatitude = double.tryParse(b['latitude']?.toString() ?? '');
        _businessLongitude = double.tryParse(b['longitude']?.toString() ?? '');
      }
      _loadingBusiness = _businessName == null;
      _settings.load();
      _loadBusinessApplication();
    }
  }

  Future<void> _loadBusinessApplication() async {
    Map? business;
    String? errorMessage;
    try {
      final data = await ApiService.get('pelanggan/profil');
      if (data is Map && data['umkm'] is Map) {
        business = data['umkm'] as Map;
      }
    } on ApiException catch (error) {
      errorMessage = error.pesan;
    }
    if (!mounted) return;
    setState(() {
      if (business != null) {
        _businessName = business['nama_usaha']?.toString();
        _businessAddress = business['alamat']?.toString();
        _businessSpecialty = business['spesialis']?.toString();
        _businessStatus = business['status_verifikasi']?.toString();
        _businessLatitude = double.tryParse(business['latitude']?.toString() ?? '');
        _businessLongitude = double.tryParse(business['longitude']?.toString() ?? '');
      }
      if (errorMessage != null) _settings.errorMessage = errorMessage;
      _loadingBusiness = false;
    });
  }

  List<ProfileFormField> get _accountFields => [
    ProfileFormField(
      label: 'Nama Lengkap',
      initialValue: _user.name,
      prefixIcon: Icons.person_outline,
    ),
    ProfileFormField(
      label: 'Nomor Handphone',
      initialValue: _user.phoneNumber,
      keyboardType: TextInputType.phone,
      prefixIcon: Icons.phone_outlined,
    ),
    ProfileFormField(
      label: 'Email',
      initialValue: _user.email,
      keyboardType: TextInputType.emailAddress,
      prefixIcon: Icons.email_outlined,
    ),
  ];

  List<ProfileFormField> get _businessFields => [
    ProfileFormField(
      label: 'Nama Usaha',
      initialValue: _businessName ?? '',
      prefixIcon: Icons.storefront_outlined,
    ),
    ProfileFormField(
      label: 'Nama Pemilik',
      initialValue: _user.name,
      prefixIcon: Icons.badge_outlined,
    ),
    ProfileFormField(
      label: 'Spesialisasi Usaha',
      initialValue: _businessSpecialty ?? '',
      prefixIcon: Icons.category_outlined,
    ),
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
      isLocationPicker: true,
      initialLatitude: _businessLatitude,
      initialLongitude: _businessLongitude,
    ),
  ];

  List<ProfileMenuItem> get _menuItems => [
    ProfileMenuItem(
      icon: Icons.favorite_rounded,
      title: 'Favorit Saya',
      subtitle: _favoriteSubtitle,
      iconColor: const Color(0xFFE11D48),
      iconBg: const Color(0xFFFFF1F2),
      iconBorderColor: const Color(0xFFFFE4E6),
      onTap: _openFavorites,
    ),
    ProfileMenuItem(
      icon: Icons.location_on_rounded,
      title: 'Daftar Alamat Pengiriman',
      subtitle: _settings.primaryAddress == null
          ? 'Belum ada alamat tersimpan'
          : '${_settings.primaryAddress!.label}: ${_settings.primaryAddress!.address}',
      iconColor: AppColors.hijauTua,
      onTap: _openAddressForm,
    ),
    ProfileMenuItem(
      icon: Icons.notifications_rounded,
      title: 'Notifikasi Pesanan',
      subtitle: 'Pemberitahuan status kiriman & promo',
      iconColor: AppColors.hijauTua,
      trailing: Switch.adaptive(
        value: _notificationsEnabled,
        onChanged: _setNotificationsEnabled,
      ),
    ),
    if (_businessName != null && _businessStatus == 'terverifikasi')
      ProfileMenuItem(
        icon: Icons.storefront_rounded,
        title: 'Buka Mode UMKM',
        subtitle: 'Kelola usaha melalui dashboard UMKM',
        iconColor: AppColors.hijauTua,
        onTap: _switchToUmkm,
      ),
    if (_businessName != null && _businessStatus != 'terverifikasi')
      ProfileMenuItem(
        icon: Icons.hourglass_top_rounded,
        title: _businessStatus == 'dihapus'
            ? 'Akun UMKM Dihapus'
            : 'Status Pengajuan UMKM',
        subtitle: _businessStatus == 'dihapus'
            ? 'Pendaftaran UMKM kembali tidak tersedia'
            : _businessStatus == 'ditolak'
            ? 'Pengajuan ditolak, periksa kembali data usaha'
            : 'Menunggu verifikasi admin desa',
        iconColor: const Color(0xFFD97706),
        iconBg: const Color(0xFFFEF3C7),
        iconBorderColor: const Color(0xFFFDE68A),
        onTap: _businessStatus == 'dihapus'
            ? null
            : () => _openBusinessRegistration(editing: true),
      ),
    if (_businessName != null && _businessStatus != 'dihapus')
      ProfileMenuItem(
        icon: Icons.storefront_rounded,
        title: 'Hapus Status Mitra',
        subtitle: 'Kembali menggunakan akun sebagai pelanggan biasa',
        iconColor: AppColors.textGrey,
        iconBg: AppColors.latar,
        iconBorderColor: AppColors.garis,
        onTap: _confirmRemoveBusiness,
      ),
    ProfileMenuItem(
      icon: Icons.info_outline_rounded,
      title: 'Tentang Djajan',
      subtitle: 'Pemberdayaan warung & petani desa',
      iconColor: AppColors.hijauTua,
      onTap: _openAboutDjajan,
    ),
    ProfileMenuItem(
      icon: Icons.logout_rounded,
      title: 'Keluar Akun',
      subtitle: 'Selesaikan sesi belanja di perangkat ini',
      iconColor: AppColors.danger,
      iconBg: AppColors.dangerBg,
      iconBorderColor: const Color(0xFFFECACA),
      textColor: AppColors.danger,
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
    final auth = context.watch<AuthService>();
    if (!auth.isLoggedIn || !auth.isPelanggan) {
      return _buildGuestProfile(context);
    }

    final data = auth.session?.data;
    if (data != null) {
      final name = data['nama']?.toString() ?? '';
      final phone = data['no_telp']?.toString() ?? '';
      final email = data['email']?.toString() ?? '';
      if (_user.name.isEmpty || _user.name != name || _user.phoneNumber != phone) {
        _user = ProfileUser(name: name, phoneNumber: phone, email: email);
      }
      if (_businessName == null && data['umkm'] is Map) {
        final b = data['umkm'] as Map;
        _businessName = b['nama_usaha']?.toString();
        _businessAddress = b['alamat']?.toString();
        _businessSpecialty = b['spesialis']?.toString();
        _businessStatus = b['status_verifikasi']?.toString();
        _businessLatitude = double.tryParse(b['latitude']?.toString() ?? '');
        _businessLongitude = double.tryParse(b['longitude']?.toString() ?? '');
        _loadingBusiness = false;
      }
    }

    return AnimatedBuilder(
      animation: Listenable.merge([FavoriteService(), _settings]),
      builder: (context, _) => ColoredBox(
        color: OC.bg,
        child: Stack(
          children: [
            const HeaderBotanicalBackdrop(height: 220),
            RefreshIndicator(
              onRefresh: () async {
                await Future.wait([
                  _settings.load(),
                  _loadBusinessApplication(),
                ]);
              },
              color: AppColors.hijauTua,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_settings.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          _settings.errorMessage!,
                          style: const TextStyle(color: AppColors.danger),
                        ),
                      ),
                    UmkmHeaderRow(
                      padding: EdgeInsets.zero,
                      iconBadge: const UmkmSquircleIcon(
                        icon: Icons.person_rounded,
                      ),
                      title: 'Profil Saya',
                      subtitle: 'Kelola akun dan preferensi belanja lokal Anda',
                      rightAction: IconButton(
                        tooltip: 'Pusat bantuan',
                        onPressed: () => showProfileHelp(context),
                        icon: const Icon(
                          Icons.help_outline_rounded,
                          color: OC.muted,
                          size: 23,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _ProfileHeader(
                      user: _user,
                      businessName: _businessName,
                      businessStatus: _businessStatus,
                      onEdit: _editProfile,
                    ),
                    const SizedBox(height: 16),
                    _PromoBanner(
                      businessName: _businessName,
                      businessStatus: _businessStatus,
                      loading: _loadingBusiness,
                      onTap: _businessStatus == 'dihapus'
                          ? null
                          : _businessStatus == 'terverifikasi'
                          ? _switchToUmkm
                          : _openBusinessRegistration,
                    ),
                    const SizedBox(height: 22),
                    _ProfileMenu(items: _menuItems),
                    const SizedBox(height: 20),
                    const _SafetyNotice(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestProfile(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const UmkmHeaderRow(
            padding: EdgeInsets.zero,
            iconBadge: UmkmSquircleIcon(
              icon: Icons.person_rounded,
            ),
            title: 'Profil Saya',
            subtitle: 'Kelola akun dan preferensi belanja lokal Anda',
          ),
          const SizedBox(height: 16),
          // Guest Header Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: const BoxDecoration(
                    color: OC.mint,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    size: 38,
                    color: OC.primary,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Halo, Pengunjung Desa!',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: OC.ink,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Masuk ke akun DJajan Anda untuk kemudahan memesan jajanan, menyimpan alamat, dan melacak pesanan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: OC.muted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.login),
                    icon: const Icon(
                      Icons.login_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    label: const Text(
                      'Masuk / Buat Akun Baru',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: OC.primary,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Mitra UMKM Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.hijauLembut, AppColors.latar],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.garis),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.hijauLembut,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    color: AppColors.hijauTua,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Punya Usaha Kuliner di Desa?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                          color: AppColors.hijauTua,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Kelola menu & pesanan lewat dashboard UMKM',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.login),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.hijauTua,
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  child: const Text('Masuk'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Info Menu
          _ProfileMenu(
            items: [
              ProfileMenuItem(
                icon: Icons.info_outline_rounded,
                title: 'Tentang DJajan',
                subtitle: 'Pemberdayaan kuliner dan UMKM lokal',
                iconColor: AppColors.hijauTua,
                onTap: _openAboutDjajan,
              ),
            ],
          ),
          const SizedBox(height: 20),
          const _SafetyNotice(),
        ],
      ),
    );
  }

  void _editProfile() {
    _openAccountForm();
  }

  Future<void> _openAccountForm() async {
    final values = await _openFormPage(
      title: 'Informasi Akun',
      subtitle: 'Perbarui data diri Anda',
      icon: Icons.person_outline,
      fields: _accountFields,
    );

    if (values == null || !mounted) return;

    try {
      await context.read<AuthService>().updateCustomerProfile(
        name: values['Nama Lengkap']!,
        phone: values['Nomor Handphone']!,
        email: values['Email']!,
      );
      if (!mounted) return;
      setState(() {
        _user = ProfileUser(
          name: values['Nama Lengkap']!,
          phoneNumber: values['Nomor Handphone']!,
          email: values['Email']!,
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil diperbarui.')),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.pesan)));
    }
  }

  Future<void> _openAddressForm() async {
    int? selectedId = _settings.primaryAddress?.id;
    if (_settings.addresses.isNotEmpty) {
      selectedId = await showModalBottomSheet<int>(
        context: context,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              const Text(
                'Pilih alamat pengiriman',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._settings.addresses.map(
                (address) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    address.primary
                        ? Icons.radio_button_checked
                        : Icons.location_on_outlined,
                    color: AppConfig.primaryColor,
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${address.label}${address.primary ? ' • Utama' : ''}',
                        ),
                      ),
                      if (address.latitude != null)
                        const Tooltip(
                          message: 'Lokasi GPS tersimpan',
                          child: Icon(
                            Icons.location_on,
                            size: 16,
                            color: AppConfig.primaryColor,
                          ),
                        )
                      else
                        const Tooltip(
                          message: 'Belum ada koordinat GPS',
                          child: Icon(
                            Icons.location_off_outlined,
                            size: 16,
                            color: AppColors.hijauMuda,
                          ),
                        ),
                    ],
                  ),
                  subtitle: Text(address.address),
                  onTap: () => Navigator.pop(context, address.id),
                  trailing: IconButton(
                    tooltip: 'Hapus alamat',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      await _settings.deleteAddress(address.id);
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context, -1),
                icon: const Icon(Icons.add),
                label: const Text('Tambah alamat baru'),
              ),
            ],
          ),
        ),
      );
      if (!mounted) return;
      if (selectedId == null) return;
      if (selectedId == -1) selectedId = null;
    }

    CustomerAddress? selected;
    for (final address in _settings.addresses) {
      if (address.id == selectedId) selected = address;
    }

    await Navigator.of(context).push<AlamatFormResult>(
      MaterialPageRoute(
        builder: (_) => AlamatFormPage(
          existing: selected,
          defaultName: _user.name,
          defaultPhone: _user.phoneNumber,
          settings: _settings,
        ),
      ),
    );
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

    try {
      final data = await ApiService.post('pelanggan/umkm_daftar', {
        'nama_usaha': values['Nama Usaha'],
        'spesialis': values['Spesialisasi Usaha'],
        'alamat': values['Alamat Usaha di Kreongan'],
        'no_telp_usaha': values['Nomor Handphone'],
        'email_usaha': _user.email,
        if (values['latitude'] != null) 'latitude': values['latitude'],
        if (values['longitude'] != null) 'longitude': values['longitude'],
      }) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _businessName = data['nama_usaha']?.toString();
        _businessAddress = data['alamat']?.toString();
        _businessSpecialty = data['spesialis']?.toString();
        _businessStatus = data['status_verifikasi']?.toString();
        _businessLatitude = double.tryParse(data['latitude']?.toString() ?? '');
        _businessLongitude = double.tryParse(data['longitude']?.toString() ?? '');
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pengajuan UMKM berhasil dikirim. Menunggu verifikasi admin.',
          ),
        ),
      );
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.pesan)));
      }
    }
  }

  Future<void> _switchToUmkm() async {
    try {
      final session = await context.read<AuthService>().switchToUmkm();
      if (!mounted) return;
      context.read<UmkmDataService>().loadProfileFromLogin(session.data);
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.umkmDashboard,
        (_) => false,
      );
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.pesan)));
      }
    }
  }

  Future<void> _confirmRemoveBusiness() async {
    final passwordController = TextEditingController();
    final reasonController = TextEditingController();
    final confirmationController = TextEditingController();
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus akun UMKM permanen?'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Semua produk akan dihapus. Riwayat pesanan tetap disimpan. '
                'Akun ini tidak dapat mendaftar UMKM lagi.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                minLines: 2,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Alasan penghapusan',
                  hintText: 'Minimal 10 karakter',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password pelanggan',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: confirmationController,
                decoration: const InputDecoration(
                  labelText: 'Ketik HAPUS untuk konfirmasi',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.hijauTua,
            ),
            onPressed: () {
              Navigator.pop(dialogContext, {
                'password': passwordController.text,
                'alasan': reasonController.text,
                'konfirmasi': confirmationController.text,
              });
            },
            child: const Text('Hapus Permanen'),
          ),
        ],
      ),
    );
    passwordController.dispose();
    reasonController.dispose();
    confirmationController.dispose();

    if (result == null || !mounted) return;
    try {
      await ApiService.post('pelanggan/umkm_hapus', result);
      if (!mounted) return;
      setState(() {
        _businessStatus = 'dihapus';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Akun UMKM dihapus permanen. Anda tidak dapat mendaftar UMKM lagi.',
          ),
        ),
      );
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.pesan)));
      }
    }
  }

  void _setNotificationsEnabled(bool value) {
    setState(() => _notificationsEnabled = value);
  }

  void _openAboutDjajan() {
    _openSimplePage(
      title: 'Tentang Djajan',
      message:
          'Djajan adalah platform pemesanan makanan dan jajanan yang menghubungkan pelanggan dengan UMKM lokal.\n\n'
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

  Future<Map<String, dynamic>?> _openFormPage({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<ProfileFormField> fields,
  }) {
    return Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute<Map<String, dynamic>>(
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
      await context.read<AuthService>().logout();
      OrderService().clear();
      NotificationService().clear();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.customerHome,
        (_) => false,
      );
    }
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.user,
    required this.businessName,
    required this.businessStatus,
    required this.onEdit,
  });

  final ProfileUser user;
  final String? businessName;
  final String? businessStatus;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.garis),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0917251B),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.hijauLembut,
              borderRadius: BorderRadius.circular(19),
            ),
            child: Center(
              child: user.name.trim().isEmpty
                  ? const Icon(
                      Icons.person_rounded,
                      color: AppConfig.primaryColor,
                      size: 28,
                    )
                  : Text(
                      _initials(user.name),
                      style: const TextStyle(
                        color: AppConfig.primaryColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name.isEmpty ? 'Profil pelanggan' : user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    height: 1.15,
                    letterSpacing: -0.3,
                    fontWeight: FontWeight.w800,
                    color: OC.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.phone_rounded, size: 13, color: OC.muted),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        user.phoneNumber.isEmpty
                            ? 'Nomor telepon belum tersedia'
                            : user.phoneNumber,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11.5, color: OC.muted),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 5,
                  children: [
                    _profileRoleTag(
                      icon: Icons.person_outline_rounded,
                      label: 'Pelanggan',
                      background: AppColors.hijauLembut,
                      foreground: AppConfig.primaryColor,
                    ),
                    if (businessName != null && businessStatus != 'dihapus')
                      _profileRoleTag(
                        icon: Icons.storefront_outlined,
                        label: 'Mitra UMKM',
                        background: AppColors.latar,
                        foreground: AppColors.hijauTua,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Edit profil pelanggan',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 19),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.hijauLembut,
              foregroundColor: AppConfig.primaryColor,
              minimumSize: const Size(42, 42),
              maximumSize: const Size(42, 42),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileRoleTag({
    required IconData icon,
    required String label,
    required Color background,
    required Color foreground,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: foreground),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts
        .take(2)
        .map((part) => part.isEmpty ? '' : part[0])
        .join()
        .toUpperCase();
  }
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner({
    required this.businessName,
    required this.businessStatus,
    required this.loading,
    required this.onTap,
  });

  final String? businessName;
  final String? businessStatus;
  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasBusiness = businessName != null;
    final statusLabel = switch (businessStatus) {
      'terverifikasi' => 'TERVERIFIKASI',
      'ditolak' => 'PERLU PERBAIKAN',
      'dihapus' => 'DINONAKTIFKAN',
      _ => 'MENUNGGU VERIFIKASI',
    };
    final actionLabel = loading
        ? 'Memuat status usaha...'
        : !hasBusiness
        ? 'Daftarkan Usaha'
        : businessStatus == 'terverifikasi'
        ? 'Buka Dashboard'
        : businessStatus == 'dihapus'
        ? 'Akun Dinonaktifkan'
        : 'Perbarui Pengajuan';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.hijauLembut,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDCE8DE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  hasBusiness
                      ? Icons.storefront_rounded
                      : Icons.store_mall_directory_outlined,
                  color: AppConfig.primaryColor,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loading
                          ? 'STATUS USAHA'
                          : hasBusiness
                          ? 'TOKO ANDA'
                          : 'MITRA USAHA DESA',
                      style: const TextStyle(
                        color: AppConfig.primaryColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.9,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      loading
                          ? 'Memeriksa akun usaha...'
                          : hasBusiness
                          ? businessName!
                          : 'Punya usaha di Kreongan Atas?',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: OC.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              if (!loading && hasBusiness)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: businessStatus == 'terverifikasi'
                        ? AppColors.hijauLembut
                        : AppColors.latar,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: businessStatus == 'terverifikasi'
                          ? AppConfig.primaryColor
                          : const Color(0xFF9A5A10),
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            loading
                ? 'Memuat status kemitraan Anda.'
                : hasBusiness
                ? businessStatus == 'terverifikasi'
                      ? 'Usaha terdaftar. Kelola produk dan pesanan melalui dashboard UMKM.'
                      : businessStatus == 'dihapus'
                      ? 'Status kemitraan usaha ini telah dinonaktifkan.'
                      : 'Periksa dan lengkapi data pengajuan usaha Anda.'
                : 'Jangkau lebih banyak pembeli lokal melalui Djajan.',
            style: const TextStyle(
              color: OC.muted,
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: loading || businessStatus == 'dihapus' ? null : onTap,
              icon: Icon(
                businessStatus == 'terverifikasi'
                    ? Icons.arrow_outward_rounded
                    : Icons.arrow_forward_rounded,
                size: 17,
              ),
              label: Text(actionLabel),
              style: FilledButton.styleFrom(
                backgroundColor: AppConfig.primaryColor,
                disabledBackgroundColor: const Color(0xFFDCE4DD),
                foregroundColor: Colors.white,
                disabledForegroundColor: OC.muted,
                minimumSize: const Size(0, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileMenu extends StatelessWidget {
  const _ProfileMenu({required this.items});

  final List<ProfileMenuItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < items.length; index++) ...[
          _ProfileMenuTile(item: items[index]),
          if (index < items.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  const _ProfileMenuTile({required this.item});

  final ProfileMenuItem item;

  @override
  Widget build(BuildContext context) {
    final bg = item.iconBg ?? AppColors.hijauLembut;
    final border = item.iconBorderColor ?? const Color(0xFFD8EBD8);
    final titleColor = item.textColor ?? AppColors.textDark;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.garis),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0717251B),
                blurRadius: 12,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: border, width: 1),
                ),
                child: Center(
                  child: Icon(item.icon, size: 21, color: item.iconColor),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
              if (item.trailing != null)
                item.trailing!
              else
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppColors.textGrey,
                ),
            ],
          ),
        ),
      ),
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
    const inkColor = Color(0xFF16201A);
    const mutedColor = Color(0xFF5F6B64);
    const bgColor = Color(0xFFF3F7F3);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: DjajanAppBar(title: title),
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
                border: Border.all(color: AppColors.garis),
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
  double? _selectedLatitude;
  double? _selectedLongitude;

  static const primaryColor = AppConfig.primaryColor;
  static const inkColor = Color(0xFF16201A);
  static const mutedColor = Color(0xFF5F6B64);
  static const faintColor = Color(0xFF7C9583);
  static const lineColor = AppColors.garis;
  static const bgColor = Color(0xFFF3F7F3);

  @override
  void initState() {
    super.initState();
    _controllers = [
      for (final field in widget.fields)
        TextEditingController(text: field.initialValue),
    ];
    for (final field in widget.fields) {
      if (field.isLocationPicker) {
        _selectedLatitude = field.initialLatitude;
        _selectedLongitude = field.initialLongitude;
        break;
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickLocation(int fieldIndex) async {
    LatLng? initial;
    if (_selectedLatitude != null && _selectedLongitude != null) {
      initial = LatLng(_selectedLatitude!, _selectedLongitude!);
    } else {
      // Pusat Desa Kreyongan Atas, Jember (-8.1630, 113.7100)
      initial = const LatLng(-8.1630, 113.7100);
    }

    final result = await showOsmMapPicker(
      context,
      initialLatLng: initial,
      confirmLabel: 'Gunakan Lokasi Usaha Ini',
    );

    if (result == null || !mounted) return;

    setState(() {
      _selectedLatitude = result.latitude;
      _selectedLongitude = result.longitude;
      if (result.alamatTeks.isNotEmpty) {
        final alamat = result.alamatTeks;
        if (!alamat.toLowerCase().contains(kreonganKeyword)) {
          _controllers[fieldIndex].text = '$alamat, Kreongan Atas';
        } else {
          _controllers[fieldIndex].text = alamat;
        }
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Titik lokasi usaha berhasil ditentukan dari peta.'),
          duration: Duration(seconds: 2),
          backgroundColor: primaryColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: DjajanAppBar(title: widget.title),
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
                  for (
                    var index = 0;
                    index < widget.fields.length;
                    index++
                  ) ...[
                    Row(
                      children: [
                        Text(
                          widget.fields[index].label,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: inkColor,
                          ),
                        ),
                        if (widget.fields[index].isLocationPicker) ...[
                          const Spacer(),
                          InkWell(
                            onTap: () => _pickLocation(index),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.hijauLembut,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFD8EBD8)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.map_rounded,
                                    size: 14,
                                    color: primaryColor,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Pilih di Peta',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _controllers[index],
                      keyboardType: widget.fields[index].keyboardType,
                      maxLines: widget.fields[index].maxLines,
                      decoration: InputDecoration(
                        hintText:
                            'Masukkan ${widget.fields[index].label.toLowerCase()}',
                        hintStyle: const TextStyle(
                          fontSize: 13.5,
                          color: faintColor,
                        ),
                        helperText: widget.fields[index].helperText,
                        helperStyle: const TextStyle(
                          fontSize: 11.5,
                          color: mutedColor,
                        ),
                        prefixIcon: widget.fields[index].prefixIcon != null
                            ? Icon(
                                widget.fields[index].prefixIcon,
                                size: 20,
                                color: mutedColor,
                              )
                            : null,
                        filled: true,
                        fillColor: AppColors.latar,
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
                          borderSide: const BorderSide(
                            color: primaryColor,
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.danger,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (widget.fields[index].requiredField &&
                            (value == null || value.trim().isEmpty)) {
                          return '${widget.fields[index].label} wajib diisi';
                        }
                        if (widget.fields[index].requiresKreongan) {
                          final isMapPicked = _selectedLatitude != null &&
                              _selectedLongitude != null;
                          final containsKeyword = value != null &&
                              value.toLowerCase().contains(kreonganKeyword);
                          if (!isMapPicked && !containsKeyword) {
                            return 'Alamat usaha harus berada di wilayah Kreongan (pilih dari peta)';
                          }
                        }
                        return null;
                      },
                    ),
                    if (widget.fields[index].isLocationPicker &&
                        _selectedLatitude != null &&
                        _selectedLongitude != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 16,
                              color: primaryColor,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Titik tersimpan: ${_selectedLatitude!.toStringAsFixed(5)}, ${_selectedLongitude!.toStringAsFixed(5)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 16,
                              color: primaryColor,
                            ),
                          ],
                        ),
                      ),
                    ],
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
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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

    final values = <String, dynamic>{
      for (var index = 0; index < widget.fields.length; index++)
        widget.fields[index].label: _controllers[index].text.trim(),
    };
    if (_selectedLatitude != null) {
      values['latitude'] = _selectedLatitude;
    }
    if (_selectedLongitude != null) {
      values['longitude'] = _selectedLongitude;
    }

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
