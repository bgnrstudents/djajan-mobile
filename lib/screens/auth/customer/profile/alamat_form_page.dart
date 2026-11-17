import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../../models/customer_settings_models.dart';
import '../../../../services/api_service.dart';
import '../../../../services/customer_location_service.dart';
import '../../../../services/customer_settings_service.dart';
import '../../../../widgets/osm_map_picker.dart';
import '../../../../widgets/umkm_app_bar.dart';
import '../order/order_widgets.dart';

/// Hasil yang dikembalikan oleh [AlamatFormPage] ke pemanggil.
class AlamatFormResult {
  final String label;
  final String address;
  final String recipient;
  final String phone;
  final String note;
  final double? latitude;
  final double? longitude;

  const AlamatFormResult({
    required this.label,
    required this.address,
    required this.recipient,
    required this.phone,
    required this.note,
    this.latitude,
    this.longitude,
  });
}

/// Halaman form tambah/edit alamat pengiriman pelanggan dengan map picker OSM.
///
/// Mengembalikan [AlamatFormResult] bila berhasil disimpan, atau null bila
/// user membatalkan.
class AlamatFormPage extends StatefulWidget {
  final CustomerAddress? existing;
  final String defaultName;
  final String defaultPhone;
  final CustomerSettingsService settings;

  const AlamatFormPage({
    super.key,
    this.existing,
    this.defaultName = '',
    this.defaultPhone = '',
    required this.settings,
  });

  @override
  State<AlamatFormPage> createState() => _AlamatFormPageState();
}

class _AlamatFormPageState extends State<AlamatFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _labelCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _recipientCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _noteCtrl;

  double? _latitude;
  double? _longitude;
  bool _saving = false;
  bool _gettingGps = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _labelCtrl = TextEditingController(text: e?.label ?? '');
    _addressCtrl = TextEditingController(text: e?.address ?? '');
    _recipientCtrl = TextEditingController(text: e?.recipient ?? widget.defaultName);
    _phoneCtrl = TextEditingController(text: e?.phone ?? widget.defaultPhone);
    _noteCtrl = TextEditingController(text: e?.note ?? '');
    _latitude = e?.latitude;
    _longitude = e?.longitude;
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _addressCtrl.dispose();
    _recipientCtrl.dispose();
    _phoneCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    LatLng? initial;
    if (_latitude != null && _longitude != null) {
      initial = LatLng(_latitude!, _longitude!);
    }
    final result = await showOsmMapPicker(
      context,
      initialLatLng: initial,
      confirmLabel: 'Gunakan Lokasi Ini',
    );
    if (result == null || !mounted) return;
    setState(() {
      _latitude = result.latitude;
      _longitude = result.longitude;
      if (result.alamatTeks.isNotEmpty) {
        _addressCtrl.text = result.alamatTeks;
      } else {
        _addressCtrl.clear();
      }
    });
    if (result.alamatTeks.isNotEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alamat lengkap diperbarui sesuai titik di peta.'),
          duration: Duration(seconds: 2),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Titik tersimpan, tetapi alamat tidak ditemukan. Isi alamat secara manual.',
          ),
        ),
      );
    }
  }

  Future<void> _getCurrentGpsLocation() async {
    setState(() => _gettingGps = true);
    try {
      final pos = await CustomerLocationService.getCurrentPosition();
      if (!mounted) return;
      final location = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _latitude = location.latitude;
        _longitude = location.longitude;
        _addressCtrl.clear();
      });
      try {
        final address = await CustomerLocationService.reverseGeocode(location);
        if (!mounted) return;
        _addressCtrl.text = address;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lokasi GPS dan alamat lengkap berhasil diisi.'),
            duration: Duration(seconds: 2),
          ),
        );
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Koordinat GPS tersimpan, tetapi alamat tidak ditemukan. Isi alamat secara manual.',
            ),
          ),
        );
      }
    } on DeviceLocationException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal mendapatkan lokasi. Anda tetap bisa mengisi alamat atau memilih titik di peta. ($e)',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _gettingGps = false);
    }
  }

  void _clearLocation() {
    setState(() {
      _latitude = null;
      _longitude = null;
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await widget.settings.saveAddress(
        id: widget.existing?.id,
        label: _labelCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        recipient: _recipientCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        note: _noteCtrl.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        primary: true,
      );
      if (!mounted) return;
      Navigator.of(context).pop(AlamatFormResult(
        label: _labelCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        recipient: _recipientCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        note: _noteCtrl.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
      ));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.pesan)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final hasLocation = _latitude != null && _longitude != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F6),
      appBar: DjajanAppBar(title: isEdit ? 'Edit Alamat' : 'Tambah Alamat'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: OC.primary,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Row(
                children: [
                  Icon(Icons.location_on_rounded, color: Colors.white, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Alamat tujuan',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Tentukan titik peta, lalu lengkapi detail penerima.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildLocationSection(hasLocation),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: 'Detail alamat',
              subtitle: 'Bantu kurir mengenali lokasi tujuan.',
              children: [
                _buildField(
                  controller: _labelCtrl,
                  label: 'Label alamat',
                  hint: 'Contoh: Rumah, Kantor',
                  icon: Icons.label_outline,
                  required: true,
                ),
                const SizedBox(height: 12),
                _buildField(
                  controller: _addressCtrl,
                  label: 'Alamat lengkap',
                  hint: 'Jalan, nomor rumah, RT/RW, kelurahan, kecamatan...',
                  icon: Icons.location_on_outlined,
                  maxLines: 3,
                  required: true,
                ),
                const SizedBox(height: 12),
                _buildField(
                  controller: _noteCtrl,
                  label: 'Patokan / catatan (opsional)',
                  hint: 'Contoh: pagar hijau, dekat masjid',
                  icon: Icons.near_me_outlined,
                  required: false,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: 'Informasi penerima',
              subtitle: 'Nomor ini akan digunakan kurir untuk menghubungi Anda.',
              children: [
                _buildField(
                  controller: _recipientCtrl,
                  label: 'Nama penerima',
                  hint: 'Nama lengkap penerima',
                  icon: Icons.person_outline,
                  required: true,
                ),
                const SizedBox(height: 12),
                _buildField(
                  controller: _phoneCtrl,
                  label: 'Nomor handphone',
                  hint: 'Nomor yang bisa dihubungi kurir',
                  icon: Icons.phone_outlined,
                  inputType: TextInputType.phone,
                  required: true,
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_circle_outline),
            label: Text(_saving ? 'Menyimpan...' : 'Simpan Alamat'),
            style: FilledButton.styleFrom(
              backgroundColor: OC.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType inputType = TextInputType.text,
    int maxLines = 1,
    required bool required,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        alignLabelWithHint: maxLines > 1,
        prefixIcon: Padding(
          padding: EdgeInsets.only(bottom: maxLines > 1 ? 34 : 0),
          child: Icon(icon, color: OC.primary, size: 20),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: OC.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: OC.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: OC.primary, width: 1.5),
        ),
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? '$label wajib diisi' : null
          : null,
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: OC.line),
        boxShadow: [
          BoxShadow(
            color: OC.primary.withValues(alpha: 0.035),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: OC.ink,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: OC.muted),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildLocationSection(bool hasLocation) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: OC.line),
            boxShadow: [
              BoxShadow(
                color: OC.primary.withValues(alpha: 0.035),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      color: OC.mintSoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.map_outlined, color: OC.primary),
                  ),
                  const SizedBox(width: 11),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Titik lokasi',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: OC.ink,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Pilih GPS atau tentukan langsung di peta.',
                          style: TextStyle(fontSize: 11.5, color: OC.muted),
                        ),
                      ],
                    ),
                  ),
                  if (hasLocation)
                    IconButton(
                      onPressed: _clearLocation,
                      tooltip: 'Hapus titik lokasi',
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: OC.primary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: hasLocation ? OC.mintSoft : OC.peachSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      hasLocation
                          ? Icons.check_circle_outline
                          : Icons.info_outline,
                      color: hasLocation ? OC.primary : OC.muted,
                      size: 19,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        hasLocation
                            ? 'Titik lokasi tersimpan untuk membantu kurir menghitung ongkir.'
                            : 'Lokasi belum dipilih. Anda tetap dapat menyimpan alamat secara manual.',
                        style: TextStyle(
                          fontSize: 12,
                          color: hasLocation ? OC.primary : OC.muted,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (hasLocation) ...[
                const SizedBox(height: 8),
                Text(
                  '${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: OC.muted,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed:
                          _gettingGps ? null : _getCurrentGpsLocation,
                      icon: _gettingGps
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location_rounded, size: 18),
                      label: Text(_gettingGps ? 'Mencari...' : 'Gunakan GPS'),
                      style: FilledButton.styleFrom(
                        foregroundColor: OC.primary,
                        backgroundColor: OC.mintSoft,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickLocation,
                      icon: const Icon(Icons.map_outlined, size: 18),
                      label: const Text('Pilih di peta'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: OC.primary,
                        side: const BorderSide(color: OC.primary),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

