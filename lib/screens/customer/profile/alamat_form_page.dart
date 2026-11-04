import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../models/customer_settings_models.dart';
import '../../../services/api_service.dart';
import '../../../services/customer_settings_service.dart';
import '../../../widgets/osm_map_picker.dart';
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
      // Isi otomatis kolom alamat jika masih kosong atau pengguna mau update
      if (_addressCtrl.text.isEmpty && result.alamatTeks.isNotEmpty) {
        _addressCtrl.text = result.alamatTeks;
      }
    });
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
      backgroundColor: OC.bg,
      appBar: AppBar(
        backgroundColor: OC.bg,
        elevation: 0,
        title: Text(
          isEdit ? 'Edit Alamat' : 'Tambah Alamat',
          style: const TextStyle(
            color: OC.ink,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: OC.muted),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: [
            _buildField(
              controller: _labelCtrl,
              label: 'Label Alamat',
              hint: 'Contoh: Rumah, Kantor',
              icon: Icons.label_outline,
              required: true,
            ),
            const SizedBox(height: 14),
            _buildField(
              controller: _addressCtrl,
              label: 'Alamat Lengkap',
              hint: 'Nama jalan, nomor rumah, RT/RW, desa...',
              icon: Icons.location_on_outlined,
              maxLines: 3,
              required: true,
            ),
            const SizedBox(height: 14),
            _buildField(
              controller: _recipientCtrl,
              label: 'Nama Penerima',
              hint: 'Nama lengkap penerima',
              icon: Icons.person_outline,
              required: true,
            ),
            const SizedBox(height: 14),
            _buildField(
              controller: _phoneCtrl,
              label: 'Nomor Handphone',
              hint: 'Nomor yang bisa dihubungi kurir',
              icon: Icons.phone_outlined,
              inputType: TextInputType.phone,
              required: true,
            ),
            const SizedBox(height: 14),
            _buildField(
              controller: _noteCtrl,
              label: 'Patokan / Catatan',
              hint: 'Contoh: Rumah pagar hijau, dekat masjid',
              icon: Icons.near_me_outlined,
              required: false,
            ),
            const SizedBox(height: 20),

            // ---- Seksi lokasi peta ----
            _buildLocationSection(hasLocation),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: ElevatedButton.icon(
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
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
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
        prefixIcon: Icon(icon, color: OC.muted, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? '$label wajib diisi' : null
          : null,
    );
  }

  Widget _buildLocationSection(bool hasLocation) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.map_outlined, color: OC.primary, size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Lokasi di Peta',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: OC.ink,
                ),
              ),
            ),
            if (hasLocation)
              TextButton.icon(
                onPressed: _clearLocation,
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Hapus Lokasi'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
          ],
        ),
        const SizedBox(height: 6),
        // Info banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: hasLocation ? OC.mint : OC.box,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasLocation ? OC.primary.withValues(alpha: 0.3) : OC.line,
            ),
          ),
          child: Row(
            children: [
              Icon(
                hasLocation ? Icons.check_circle : Icons.info_outline,
                color: hasLocation ? OC.primary : OC.muted,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  hasLocation
                      ? '${_latitude!.toStringAsFixed(6)}, '
                          '${_longitude!.toStringAsFixed(6)}\n'
                          'Lokasi tersimpan — kurir dapat menghitung ongkir otomatis'
                      : 'Lokasi belum disetel. Tanpa lokasi, layanan kurir tidak dapat '
                          'menghitung ongkir otomatis.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: hasLocation ? OC.primary : OC.muted,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _pickLocation,
            icon: Icon(
              hasLocation ? Icons.edit_location_alt_outlined : Icons.add_location_outlined,
              color: OC.primary,
            ),
            label: Text(
              hasLocation ? 'Ubah Lokasi di Peta' : 'Pilih Lokasi di Peta',
              style: const TextStyle(color: OC.primary),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: OC.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Peta menggunakan OpenStreetMap. Geser peta atau cari alamat untuk menemukan lokasi yang tepat.',
          style: TextStyle(fontSize: 11.5, color: OC.muted),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

