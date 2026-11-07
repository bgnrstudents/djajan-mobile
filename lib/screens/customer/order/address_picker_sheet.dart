import 'package:flutter/material.dart';

import '../../../models/customer_settings_models.dart';
import '../../../services/customer_settings_service.dart';
import '../profile/alamat_form_page.dart';
import 'order_widgets.dart';

/// Modal bottom sheet untuk memilih alamat pengiriman dari daftar alamat
/// tersimpan milik pelanggan di [CustomerSettingsService].
///
/// Mengembalikan [CustomerAddress] yang dipilih, atau null jika dibatalkan.
Future<CustomerAddress?> showAddressPickerSheet(
  BuildContext context, {
  int? currentAddressId,
}) async {
  final settings = CustomerSettingsService();
  await settings.load();

  if (!context.mounted) return null;

  return showModalBottomSheet<CustomerAddress>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _AddressPickerSheet(
      settings: settings,
      currentAddressId: currentAddressId,
    ),
  );
}

class _AddressPickerSheet extends StatefulWidget {
  final CustomerSettingsService settings;
  final int? currentAddressId;

  const _AddressPickerSheet({
    required this.settings,
    this.currentAddressId,
  });

  @override
  State<_AddressPickerSheet> createState() => _AddressPickerSheetState();
}

class _AddressPickerSheetState extends State<_AddressPickerSheet> {
  late int? _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.currentAddressId ??
        widget.settings.primaryAddress?.id ??
        (widget.settings.addresses.isNotEmpty
            ? widget.settings.addresses.first.id
            : null);
  }

  Future<void> _openAddNew() async {
    final result = await Navigator.of(context).push<AlamatFormResult>(
      MaterialPageRoute(
        builder: (_) => AlamatFormPage(
          settings: widget.settings,
        ),
      ),
    );
    if (result != null && mounted) {
      await widget.settings.load();
      if (!mounted) return;
      // Auto-pilih alamat utama atau yang terakhir ditambahkan
      final latest = widget.settings.primaryAddress ??
          (widget.settings.addresses.isNotEmpty
              ? widget.settings.addresses.last
              : null);
      if (latest != null) {
        Navigator.of(context).pop(latest);
      } else {
        setState(() {});
      }
    }
  }

  Future<void> _editAddress(CustomerAddress address) async {
    final result = await Navigator.of(context).push<AlamatFormResult>(
      MaterialPageRoute(
        builder: (_) => AlamatFormPage(
          existing: address,
          settings: widget.settings,
        ),
      ),
    );
    if (result != null && mounted) {
      await widget.settings.load();
      if (!mounted) return;
      // Jika yang diedit adalah yang sedang dipilih, update selection
      final updated = widget.settings.addresses.firstWhere(
        (a) => a.id == address.id,
        orElse: () => address,
      );
      Navigator.of(context).pop(updated);
    }
  }

  Future<void> _useDemoKreyonganAddress() async {
    final existing = widget.settings.addresses.cast<CustomerAddress?>().firstWhere(
      (a) => a?.label == 'Rumah (Kreyongan Atas)',
      orElse: () => null,
    );
    if (existing != null) {
      Navigator.of(context).pop(existing);
      return;
    }

    try {
      await widget.settings.saveAddress(
        label: 'Rumah (Kreyongan Atas)',
        recipient: 'Budi Pelanggan',
        phone: '081234567890',
        address: 'Jl. Merpati No. 14, RT 02 / RW 01, Desa Kreyongan Atas',
        note: 'Dekat balai RT & pos ronda Kreyongan Atas',
        latitude: -8.1588,
        longitude: 113.7032,
        primary: true,
      );
      await widget.settings.load();
      final created = widget.settings.addresses.cast<CustomerAddress?>().firstWhere(
        (a) => a?.label == 'Rumah (Kreyongan Atas)',
        orElse: () => null,
      ) ?? widget.settings.primaryAddress;
      if (created != null && mounted) {
        Navigator.of(context).pop(created);
        return;
      }
    } catch (_) {
      const fallback = CustomerAddress(
        id: 9999,
        label: 'Rumah (Kreyongan Atas)',
        recipient: 'Budi Pelanggan',
        phone: '081234567890',
        address: 'Jl. Merpati No. 14, RT 02 / RW 01, Desa Kreyongan Atas',
        note: 'Dekat balai RT Kreyongan Atas',
        latitude: -8.1588,
        longitude: 113.7032,
        primary: true,
      );
      if (mounted) Navigator.of(context).pop(fallback);
    }
  }

  @override
  Widget build(BuildContext context) {
    final addresses = widget.settings.addresses;

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.78,
        ),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: OC.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.location_on, color: OC.primary, size: 20),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pilih Alamat Pengiriman',
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.bold,
                          color: OC.ink,
                        ),
                      ),
                      Text(
                        'Pilih alamat tujuan untuk pesanan Anda',
                        style: TextStyle(fontSize: 12, color: OC.muted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: OC.muted),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Tutup',
                ),
              ],
            ),
            const Divider(height: 20),

            // Demo / Fast Preset Banner Kreyongan Atas
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: OC.banner,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: OC.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.storefront_outlined, color: OC.primary, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Titik Kreyongan Atas (Demo/Cepat)',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: OC.primary,
                          ),
                        ),
                        Text(
                          'Gunakan alamat contoh di area Desa Kreyongan Atas',
                          style: TextStyle(fontSize: 11, color: OC.muted),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _useDemoKreyonganAddress,
                    style: TextButton.styleFrom(
                      backgroundColor: OC.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Pilih',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            // Daftar Alamat
            if (addresses.isEmpty) ...[
              const SizedBox(height: 24),
              const Center(
                child: Icon(Icons.location_off_outlined, size: 48, color: OC.muted),
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  'Belum ada alamat tersimpan',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              const SizedBox(height: 4),
              const Center(
                child: Text(
                  'Tambahkan alamat dan tentukan titik GPS di peta agar kurir dapat mengantar pesanan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.5, color: OC.muted),
                ),
              ),
              const SizedBox(height: 24),
            ] else ...[
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: addresses.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (ctx, index) {
                    final a = addresses[index];
                    final isSelected = a.id == _selectedId;
                    final hasGps = a.latitude != null && a.longitude != null;

                    return InkWell(
                      onTap: () => Navigator.of(context).pop(a),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? OC.mintSoft : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? OC.primary : OC.line,
                            width: isSelected ? 1.6 : 1.0,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Icon(
                                isSelected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                color: isSelected ? OC.primary : OC.muted,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        a.label.isNotEmpty ? a.label : 'Alamat',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: OC.ink,
                                        ),
                                      ),
                                      if (a.primary) ...[
                                        const SizedBox(width: 6),
                                        const Pill(text: 'Utama', bg: OC.mint, fg: OC.primary),
                                      ],
                                      const SizedBox(width: 6),
                                      if (hasGps)
                                        const Pill(text: 'GPS Aktif', bg: OC.mint, fg: OC.primary, icon: Icons.location_on)
                                      else
                                        const Pill(text: 'Belum Ada GPS', bg: OC.peach, fg: OC.amber, icon: Icons.location_off_outlined),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${a.recipient} • ${a.phone}',
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: OC.muted,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    a.address,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: OC.ink,
                                      height: 1.3,
                                    ),
                                  ),
                                  if (a.note.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Patokan: ${a.note}',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontStyle: FontStyle.italic,
                                        color: OC.muted,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18, color: OC.muted),
                              onPressed: () => _editAddress(a),
                              tooltip: 'Edit Alamat / GPS',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Tombol Tambah Alamat Baru
            OutlinedButton.icon(
              onPressed: _openAddNew,
              icon: const Icon(Icons.add_location_alt_outlined, color: OC.primary),
              label: const Text(
                'Tambah Alamat Baru di Peta',
                style: TextStyle(
                  color: OC.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 13),
                side: const BorderSide(color: OC.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

