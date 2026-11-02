class CustomerAddress {
  final int id;
  final String label;
  final String recipient;
  final String phone;
  final String address;
  final String note;
  final double? latitude;
  final double? longitude;
  final bool primary;

  const CustomerAddress({
    required this.id,
    required this.label,
    required this.recipient,
    required this.phone,
    required this.address,
    this.note = '',
    this.latitude,
    this.longitude,
    this.primary = false,
  });

  factory CustomerAddress.fromJson(Map<String, dynamic> json) =>
      CustomerAddress(
        id: int.tryParse('${json['id_alamat']}') ?? 0,
        label: json['label']?.toString() ?? '',
        recipient: json['nama_penerima']?.toString() ?? '',
        phone: json['no_telp']?.toString() ?? '',
        address: json['alamat']?.toString() ?? '',
        note: json['catatan']?.toString() ?? '',
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        primary: json['utama'] == true || json['utama'] == 1,
      );
}
