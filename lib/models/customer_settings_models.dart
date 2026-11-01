class CustomerAddress {
  final int id;
  final String label;
  final String recipient;
  final String phone;
  final String address;
  final String note;
  final bool primary;

  const CustomerAddress({
    required this.id,
    required this.label,
    required this.recipient,
    required this.phone,
    required this.address,
    this.note = '',
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
        primary: json['utama'] == true || json['utama'] == 1,
      );
}
