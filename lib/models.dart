import 'dart:typed_data';

enum OrderStatus {
  waitingPayment,
  reviewing,
  processing,
  delivering,
  completed,
  cancelled,
}

enum OrderType { instant, preOrder }

enum DeliveryMethod { courier, pickup }

enum PaymentMethod { cod, qris }

extension OrderStatusX on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.waitingPayment:
        return 'Menunggu Pembayaran';
      case OrderStatus.reviewing:
        return 'Menunggu Persetujuan UMKM';
      case OrderStatus.processing:
        return 'Diproses & Dimasak';
      case OrderStatus.delivering:
        return 'Dalam Pengantaran';
      case OrderStatus.completed:
        return 'Selesai';
      case OrderStatus.cancelled:
        return 'Dibatalkan';
    }
  }

  bool get isActive =>
      this != OrderStatus.completed && this != OrderStatus.cancelled;

  bool get canCancel =>
      this == OrderStatus.waitingPayment || this == OrderStatus.reviewing;

  bool get canEdit => canCancel;
}

/// Satu baris produk di keranjang (dikirim dari halaman Keranjang ke Checkout).
class CartLine {
  final String productId;
  final String productName;
  final String variant;
  final String unit;
  final String imageUrl;
  final int quantity;
  final double price;
  final OrderType type;

  final String umkmId;
  final String umkmName;
  final String umkmType;

  /// null = UMKM tidak menyediakan kurir (hanya ambil sendiri).
  final double? courierFee;
  final String pickupLocation;

  const CartLine({
    required this.productId,
    required this.productName,
    required this.variant,
    required this.unit,
    required this.imageUrl,
    required this.quantity,
    required this.price,
    required this.type,
    required this.umkmId,
    required this.umkmName,
    required this.umkmType,
    this.courierFee,
    required this.pickupLocation,
  });

  double get subtotal => quantity * price;
}

class OrderItem {
  final String productId;
  final String productName;
  final String variant;
  final String unit;
  final String imageUrl;
  final int quantity;
  final double price;

  const OrderItem({
    required this.productId,
    required this.productName,
    required this.variant,
    required this.unit,
    required this.imageUrl,
    required this.quantity,
    required this.price,
  });

  double get subtotal => quantity * price;
}

class OrderVendor {
  final String umkmId;
  final String umkmName;
  final String umkmType;
  final OrderType type;
  final List<OrderItem> items;
  final DeliveryMethod delivery;
  final double deliveryFee;
  final String pickupLocation;
  final DateTime? requiredAt;
  final String? purpose;
  final String? note;

  const OrderVendor({
    required this.umkmId,
    required this.umkmName,
    required this.umkmType,
    required this.type,
    required this.items,
    required this.delivery,
    required this.deliveryFee,
    required this.pickupLocation,
    this.requiredAt,
    this.purpose,
    this.note,
  });

  double get subtotal => items.fold(0.0, (s, i) => s + i.subtotal);
  int get totalQty => items.fold(0, (s, i) => s + i.quantity);
  bool get isPreOrder => type == OrderType.preOrder;
}

class Recipient {
  final String name;
  final String phone;
  final String address;
  final String? addressNote;

  const Recipient({
    required this.name,
    required this.phone,
    required this.address,
    this.addressNote,
  });

  Recipient copyWith({
    String? name,
    String? phone,
    String? address,
    String? addressNote,
  }) {
    return Recipient(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      addressNote: addressNote ?? this.addressNote,
    );
  }
}

class PaymentAccount {
  final String bank;
  final String bankFullName;
  final String number;
  final String holder;

  const PaymentAccount({
    required this.bank,
    required this.bankFullName,
    required this.number,
    required this.holder,
  });
}

class Order {
  final String id;
  final String refId;
  final DateTime createdAt;
  final List<OrderVendor> vendors;
  final Recipient recipient;
  final PaymentMethod paymentMethod;
  final double serviceFee;
  final double discount;
  final OrderStatus status;
  final PaymentAccount account;
  final DateTime? paymentDeadline;
  final Uint8List? proofBytes;
  final String? proofName;
  final DateTime? proofUploadedAt;

  const Order({
    required this.id,
    required this.refId,
    required this.createdAt,
    required this.vendors,
    required this.recipient,
    required this.paymentMethod,
    required this.serviceFee,
    required this.discount,
    required this.status,
    required this.account,
    this.paymentDeadline,
    this.proofBytes,
    this.proofName,
    this.proofUploadedAt,
  });

  double get subtotal => vendors.fold(0.0, (s, v) => s + v.subtotal);
  double get shippingTotal => vendors.fold(0.0, (s, v) => s + v.deliveryFee);
  double get total => subtotal + shippingTotal + serviceFee - discount;
  int get totalQty => vendors.fold(0, (s, v) => s + v.totalQty);
  bool get hasProof => proofBytes != null;
  bool get hasPreOrder => vendors.any((v) => v.isPreOrder);
  String get vendorNames => vendors.map((v) => v.umkmName).join(' & ');

  /// Vendor utama (dipakai untuk banner status & tombol WhatsApp).
  OrderVendor get mainVendor =>
      vendors.firstWhere((v) => v.isPreOrder, orElse: () => vendors.first);

  Order copyWith({
    List<OrderVendor>? vendors,
    Recipient? recipient,
    OrderStatus? status,
    DateTime? paymentDeadline,
    Uint8List? proofBytes,
    String? proofName,
    DateTime? proofUploadedAt,
    bool clearProof = false,
  }) {
    return Order(
      id: id,
      refId: refId,
      createdAt: createdAt,
      vendors: vendors ?? this.vendors,
      recipient: recipient ?? this.recipient,
      paymentMethod: paymentMethod,
      serviceFee: serviceFee,
      discount: discount,
      status: status ?? this.status,
      account: account,
      paymentDeadline: paymentDeadline ?? this.paymentDeadline,
      proofBytes: clearProof ? null : (proofBytes ?? this.proofBytes),
      proofName: clearProof ? null : (proofName ?? this.proofName),
      proofUploadedAt:
          clearProof ? null : (proofUploadedAt ?? this.proofUploadedAt),
    );
  }
}

/// Pilihan checkout per UMKM (diisi pengguna di halaman Checkout).
class VendorCheckout {
  final DeliveryMethod delivery;
  final DateTime? requiredAt;
  final String? purpose;
  final String? note;

  const VendorCheckout({
    required this.delivery,
    this.requiredAt,
    this.purpose,
    this.note,
  });
}

class OrderException implements Exception {
  final String message;
  const OrderException(this.message);

  @override
  String toString() => message;
}

/// Aturan validasi data pesanan. Dipakai oleh form (UI) DAN oleh
/// OrderService, sehingga data tidak valid tetap ditolak walau UI dilewati.
class OrderValidator {
  static const String _l = r'A-Za-z\u00C0-\u024F';

  static final RegExp _nameChars = RegExp("^[$_l .'\\-]+\$");
  static final RegExp _addressChars = RegExp("^[$_l" r"0-9 .,/\-]+$");
  static final RegExp _noteChars = RegExp("^[$_l" r"0-9 .,/\-']+$");
  static final RegExp _purposeChars = RegExp("^[$_l" r"0-9 .,/\-'&()]+$");
  static final RegExp _packChars = RegExp("^[$_l" r"""0-9 .,!?/\-'&()":;]+$""");

  static final RegExp _letter = RegExp('[$_l]');
  static final RegExp _repeat = RegExp(r'(.)\1{4,}');

  /// Rapikan spasi: trim + spasi/baris baru ganda menjadi satu spasi.
  static String clean(String? s) =>
      (s ?? '').trim().replaceAll(RegExp(r'\s+'), ' ');

  static int _letters(String s) => _letter.allMatches(s).length;

  // ------------------------------------------------------------ penerima

  static String? name(String? v) {
    final c = clean(v);
    if (c.isEmpty) return 'Nama penerima wajib diisi';
    if (RegExp(r'[#\$%\^&\*_\+=\[\]\{\}\|<>\\~`@!()0-9]').hasMatch(c)) {
      return 'Nama tidak boleh mengandung angka atau simbol';
    }
    if (!_nameChars.hasMatch(c)) {
      return 'Hanya boleh huruf, spasi, titik, apostrof dan tanda hubung';
    }
    if (!_letter.hasMatch(c[0])) return 'Nama harus diawali huruf';
    if (_letters(c) < 3) return 'Nama minimal 3 huruf';
    if (c.length > 50) return 'Nama maksimal 50 karakter';
    if (_repeat.hasMatch(c)) return 'Nama tidak valid';
    return null;
  }

  /// Hasil normalisasi nomor (format 0812-3456-7890) atau null jika tidak valid.
  static String? normalizePhone(String? v) {
    final raw = (v ?? '').trim();
    if (!RegExp(r'^\+?[0-9][0-9\- ]*$').hasMatch(raw)) return null;
    var d = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (d.startsWith('62')) d = '0${d.substring(2)}';
    if (!RegExp(r'^08[0-9]{8,11}$').hasMatch(d)) return null;
    if (RegExp(r'(\d)\1{6,}').hasMatch(d)) return null;
    return '${d.substring(0, 4)}-${d.substring(4, 8)}-${d.substring(8)}';
  }

  static String? phone(String? v) {
    final raw = (v ?? '').trim();
    if (raw.isEmpty) return 'Nomor WhatsApp wajib diisi';
    if (RegExp(r'[A-Za-z#\$%\^&\*_\+=\[\]\{\}\|<>\\~`@!().,/:;]').hasMatch(raw)) {
      return 'Nomor hanya boleh angka dan tanda plus (+62)';
    }
    if (!RegExp(r'^\+?[0-9][0-9\- ]*$').hasMatch(raw)) {
      return 'Hanya boleh angka (boleh diawali +62)';
    }
    if (normalizePhone(raw) == null) {
      return 'Gunakan nomor seluler Indonesia: 08xx atau +62 8xx (10–13 digit)';
    }
    return null;
  }

  static String? address(String? v) {
    final c = clean(v);
    if (c.isEmpty) return 'Alamat wajib diisi';
    if (RegExp(r'[#\$%\^&\*_\+=\[\]\{\}\|<>\\~`@!]').hasMatch(c)) {
      return 'Alamat tidak boleh mengandung simbol khusus';
    }
    if (!_addressChars.hasMatch(c)) {
      return 'Hanya boleh huruf, angka, spasi, titik, koma dan garis miring';
    }
    if (c.length < 10) return 'Alamat terlalu pendek (minimal 10 karakter)';
    if (c.length > 150) return 'Alamat maksimal 150 karakter';
    if (_letters(c) < 5) return 'Alamat harus memuat nama jalan / dusun / desa';
    if (_repeat.hasMatch(c)) return 'Alamat tidak valid';
    return null;
  }

  /// Patokan bersifat opsional.
  static String? landmark(String? v) {
    final c = clean(v);
    if (c.isEmpty) return null;
    if (!_noteChars.hasMatch(c)) {
      return 'Patokan hanya boleh huruf, angka, spasi, dan tanda . , / -';
    }
    if (_letters(c) < 3) return 'Patokan minimal 3 huruf';
    if (c.length > 80) return 'Patokan maksimal 80 karakter';
    if (_repeat.hasMatch(c)) return 'Patokan tidak valid';
    return null;
  }

  static String? recipientError(Recipient r) =>
      name(r.name) ?? phone(r.phone) ?? address(r.address) ?? landmark(r.addressNote);

  static Recipient normalizeRecipient(Recipient r) {
    final note = clean(r.addressNote);
    return Recipient(
      name: clean(r.name),
      phone: normalizePhone(r.phone) ?? r.phone.trim(),
      address: clean(r.address),
      addressNote: note.isEmpty ? null : note,
    );
  }

  // ---------------------------------------------------------- pre-order

  static String? purpose(String? v) {
    final c = clean(v);
    if (c.isEmpty) return null;
    if (!_purposeChars.hasMatch(c)) {
      return 'Hanya boleh huruf, angka, dan tanda baca standar';
    }
    if (_letters(c) < 3) return 'Minimal 3 huruf';
    if (c.length > 60) return 'Maksimal 60 karakter';
    if (_repeat.hasMatch(c)) return 'Input tidak valid';
    return null;
  }

  /// Catatan rasa / kemasan bersifat opsional.
  static String? packingNote(String? v) {
    final c = clean(v);
    if (c.isEmpty) return null;
    if (!_packChars.hasMatch(c)) {
      return 'Catatan hanya boleh huruf, angka, dan tanda baca umum';
    }
    if (_letters(c) < 3) return 'Catatan minimal 3 huruf';
    if (c.length > 120) return 'Catatan maksimal 120 karakter';
    if (_repeat.hasMatch(c)) return 'Catatan tidak valid';
    return null;
  }
}
