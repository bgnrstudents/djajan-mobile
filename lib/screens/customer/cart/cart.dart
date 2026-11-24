import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../order/midtrans_payment_screen.dart';
import '../order/order_detail_screen.dart';
import '../../../models/order.dart';
import '../../../models/umkm.dart';
import '../../../services/auth_service.dart';
import '../../../services/catalog_service.dart';
import '../../../services/order_service.dart';
import '../../auth/login_screen.dart';
import '../order/order_widgets.dart';
import '../../../services/cart_service.dart';
import '../../../services/customer_settings_service.dart';
import '../order/address_picker_sheet.dart';
import '../../../widgets/app_network_image.dart';
import '../../../widgets/umkm_app_bar.dart';

/// Composite key agar produk "keduanya" bisa masuk keranjang
/// sebagai dua baris terpisah (instant vs PO) tanpa bentrok productId.
String _cartKey(CartLine item) => '${item.productId}_${item.type.name}';

class CartScreen extends StatefulWidget {
  final bool showAppBar;
  final VoidCallback? onBack;
  final VoidCallback? onExploreProducts;

  const CartScreen({
    super.key,
    this.showAppBar = true,
    this.onBack,
    this.onExploreProducts,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _cartService = CartService();
  final OrderService _orderService = OrderService();
  final Set<String> _selectedKeys = {};
  final Set<String> _knownKeys = {};

  // Recipient state
  bool _addressHasCoords = false;
  Recipient _recipient = const Recipient(name: '', phone: '', address: '');
  String? _addressError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadAddress();
      }
    });
  }

  Future<void> _loadAddress() async {
    final settings = CustomerSettingsService();
    await settings.load();
    if (!mounted) return;
    final a =
        settings.primaryAddress ??
        (settings.addresses.isNotEmpty ? settings.addresses.first : null);
    setState(() {
      _addressError = settings.errorMessage;
      if (a != null && a.id != 0) {
        _recipient = Recipient(
          addressId: a.id,
          name: a.recipient,
          phone: a.phone,
          address: a.address,
          addressNote: a.note,
          latitude: a.latitude,
          longitude: a.longitude,
        );
        _addressHasCoords = a.latitude != null && a.longitude != null;
      }
    });
    if (_addressHasCoords) {
      _calculateOngkirAllUmkm();
    }
  }

  /// Hitung ongkir untuk semua UMKM yang aktif punya layanan kurir
  Future<void> _calculateOngkirAllUmkm() async {
    if (!_addressHasCoords) return;
    final grouped = _cartService.itemsByUmkm;
    for (final entry in grouped.entries) {
      final umkmId = entry.key;
      final lines = entry.value;
      if (lines.isEmpty) continue;
      // Hanya hitung jika UMKM ini ada layanan kurir
      if (lines.first.courierFee != null) {
        await _calculateOngkirForUmkm(umkmId, lines.first);
      }
    }
  }

  /// Hitung ongkir untuk satu UMKM tertentu dari API ongkir_hitung
  Future<void> _calculateOngkirForUmkm(String umkmId, CartLine firstLine) async {
    final umkmIdInt = int.tryParse(umkmId);
    if (umkmIdInt == null || !_addressHasCoords) {
      _courierFees[umkmId] = firstLine.courierFee?.round() ?? 0;
      return;
    }
    if (_ongkirLoading[umkmId] == true || _courierFees.containsKey(umkmId)) {
      return; // Sudah loading atau sudah ada hasil
    }

    final auth = context.read<AuthService>();
    if (!auth.isLoggedIn || !auth.isPelanggan) {
      // User belum login sebagai pelanggan, gunakan ongkir default toko agar tidak 401 looping
      _courierFees[umkmId] = firstLine.courierFee?.round() ?? 0;
      return;
    }

    if (mounted) setState(() => _ongkirLoading[umkmId] = true);
    try {
      final result = await _orderService.calculateDeliveryFee(
        umkmId: umkmIdInt,
        delivery: DeliveryMethod.courier,
        addressId: _recipient.addressId,
        latitude: _recipient.latitude,
        longitude: _recipient.longitude,
      );
      if (!mounted) return;
      setState(() {
        _ongkirLoading[umkmId] = false;
        if (result.isOutOfRange) {
          // Di luar jangkauan — set ke -1 sebagai tanda error
          _courierFees[umkmId] = -1;
          _ongkirMessage[umkmId] = 'Di luar jangkauan kurir';
        } else {
          _courierFees[umkmId] = result.deliveryFee.round();
          _ongkirMessage[umkmId] = result.message;
          _ongkirDistance[umkmId] = result.distanceKm;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _ongkirLoading[umkmId] = false;
        // Fallback ke tarif default toko agar _courierFees.containsKey(umkmId) bernilai TRUE dan tidak memicu loop rebuild!
        _courierFees[umkmId] = firstLine.courierFee?.round() ?? 0;
        _ongkirMessage[umkmId] = 'Tarif standar kurir';
      });
    }
  }

  // Delivery options per UMKM (0: Kurir, 1: Pickup)
  final Map<String, int> _deliveryOptions = {};

  // Hasil hitung ongkir dinamis per UMKM (dari API ongkir_hitung)
  final Map<String, int> _courierFees = {};
  final Map<String, bool> _ongkirLoading = {};
  final Map<String, String?> _ongkirMessage = {};
  final Map<String, double?> _ongkirDistance = {};

  // Pre-Order options per UMKM
  final Map<String, DateTime?> _poRequiredDates = {};
  final Map<String, TextEditingController> _poPurposeControllers = {};
  final Map<String, TextEditingController> _poNoteControllers = {};

  // Payment method (0: COD, 1: QRIS)
  int _selectedPayment = 1; // Default QRIS
  bool _isSubmitting = false;

  void _syncSelection() {
    final keys = _cartService.items.map(_cartKey).toSet();
    _selectedKeys.removeWhere((k) => !keys.contains(k));
    _selectedKeys.addAll(keys.difference(_knownKeys));
    _knownKeys
      ..removeWhere((k) => !keys.contains(k))
      ..addAll(keys);
  }

  List<CartLine> get _selectedItems => _cartService.items
      .where((item) => _selectedKeys.contains(_cartKey(item)))
      .toList();

  void _toggleProduct(String key, bool selected) {
    setState(() {
      if (selected) {
        _selectedKeys.add(key);
      } else {
        _selectedKeys.remove(key);
      }
    });
  }

  void _toggleAll(bool selected) {
    setState(() {
      if (selected) {
        _selectedKeys
          ..clear()
          ..addAll(_cartService.items.map(_cartKey));
      } else {
        _selectedKeys.clear();
      }
    });
  }

  @override
  void dispose() {
    for (final c in _poPurposeControllers.values) {
      c.dispose();
    }
    for (final c in _poNoteControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _getPurposeController(String umkmId) {
    return _poPurposeControllers.putIfAbsent(
      umkmId,
      () => TextEditingController(),
    );
  }

  TextEditingController _getNoteController(String umkmId) {
    return _poNoteControllers.putIfAbsent(
      umkmId,
      () => TextEditingController(),
    );
  }

  DateTime? _getPoDate(String umkmId) {
    return _poRequiredDates[umkmId];
  }

  Future<void> _pickDateTime(String umkmId) async {
    final now = DateTime.now();
    final first = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 1));
    final current =
        _poRequiredDates[umkmId] ??
        DateTime(first.year, first.month, first.day, 11, 0);

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: current.isBefore(first) ? first : current,
      firstDate: first,
      lastDate: first.add(const Duration(days: 180)),
      helpText: 'Pilih Tanggal Acara / Dibutuhkan',
    );

    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
      helpText: 'Pilih Jam Acara / Dibutuhkan',
    );

    if (pickedTime == null || !mounted) return;

    setState(() {
      _poRequiredDates[umkmId] = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _editRecipient() async {
    final picked = await showAddressPickerSheet(
      context,
      currentAddressId: _recipient.addressId,
    );
    if (picked != null && mounted) {
      setState(() {
        _recipient = Recipient(
          addressId: picked.id,
          name: picked.recipient,
          phone: picked.phone,
          address: picked.address,
          addressNote: picked.note,
          latitude: picked.latitude,
          longitude: picked.longitude,
        );
        _addressHasCoords = picked.latitude != null && picked.longitude != null;
        _addressError = null;
        // Reset ongkir lama karena alamat berubah
        _courierFees.clear();
        _ongkirLoading.clear();
        _ongkirMessage.clear();
        _ongkirDistance.clear();
      });
      // Recalculate ongkir dengan alamat baru jika punya GPS
      if (_addressHasCoords) {
        _calculateOngkirAllUmkm();
      }
    }
  }

  Future<bool?> _showLoginRequiredSheet() {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCE8DE),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: OC.mint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  size: 32,
                  color: OC.primary,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Masuk Dulu Yuk!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: OC.ink,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Masuk ke akun Djajan untuk melanjutkan pesanan dan mengatur alamat pengantaran Anda.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: OC.muted, height: 1.45),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx, true);
                    final ok = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                    if (ok == true && mounted) {
                      _handleCheckout();
                    }
                  },
                  icon: const Icon(
                    Icons.login_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  label: const Text(
                    'Masuk / Daftar Sekarang',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: OC.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(
                  'Lanjut Lihat Menu Lain',
                  style: TextStyle(
                    color: OC.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  DateTime? _lastCheckoutTime;

  Future<void> _handleCheckout() async {
    if (_isSubmitting) return;

    final auth = context.read<AuthService>();
    if (!auth.isLoggedIn || !auth.isPelanggan) {
      await _showLoginRequiredSheet();
      return;
    }

    // 1.5s minimum delay to prevent rapid successive calls
    if (_lastCheckoutTime != null &&
        DateTime.now().difference(_lastCheckoutTime!) < Duration(seconds: 1)) {
      return;
    }

    _lastCheckoutTime = DateTime.now();

    final items = _selectedItems;
    if (items.isEmpty) {
      showToast(
        context,
        'Pilih minimal satu produk untuk checkout.',
        error: true,
      );
      return;
    }

    final grouped = <String, List<CartLine>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.umkmId, () => []).add(item);
    }
    // Validasi minimal pembelian PO dan tanggal pre-order
    for (final entry in grouped.entries) {
      for (final line in entry.value) {
        if (line.type == OrderType.preOrder &&
            line.minOrderPo > 1 &&
            line.quantity < line.minOrderPo) {
          showToast(
            context,
            'Minimal pemesanan Pre-Order "${line.productName}" adalah ${line.minOrderPo} ${line.unit}.',
            error: true,
          );
          return;
        }
      }

      final isPO = entry.value.any((item) => item.type == OrderType.preOrder);
      if (isPO) {
        final date = _getPoDate(entry.key);
        if (date == null) {
          showToast(
            context,
            'Pilih waktu dibutuhkan untuk pesanan Pre-Order dari ${entry.value.first.umkmName}.',
            error: true,
          );
          return;
        }
        if (date.isBefore(DateTime.now())) {
          showToast(
            context,
            'Waktu dibutuhkan untuk ${entry.value.first.umkmName} sudah terlewat.',
            error: true,
          );
          return;
        }
      }
    }

    setState(() => _isSubmitting = true);
    bool dialogShown = false;

    try {
      final options = <String, VendorCheckout>{};
      for (final entry in grouped.entries) {
        final umkmId = entry.key;
        final lines = entry.value;
        final isPO = lines.any((item) => item.type == OrderType.preOrder);
        final deliveryOpt =
            _deliveryOptions[umkmId] ??
            (lines.first.courierFee != null ? 0 : 1);

        options[umkmId] = VendorCheckout(
          delivery: deliveryOpt == 0
              ? DeliveryMethod.courier
              : DeliveryMethod.pickup,
          requiredAt: isPO ? _getPoDate(umkmId) : null,
          purpose: isPO ? _getPurposeController(umkmId).text.trim() : null,
          note: isPO ? _getNoteController(umkmId).text.trim() : null,
        );
      }

      // Validasi koordinat jika ada UMKM yang menggunakan kurir
      final hasCourier = options.values.any(
        (opt) => opt.delivery == DeliveryMethod.courier,
      );
      if (_recipient.addressId == null) {
        showToast(
          context,
          'Pilih atau tambahkan alamat penerima terlebih dahulu.',
          error: true,
        );
        return;
      }
      if (hasCourier && (_recipient.addressId == null || !_addressHasCoords)) {
        showToast(
          context,
          'Alamat pengiriman belum memiliki titik GPS untuk kurir. Klik "Ubah" pada Kontak & Alamat untuk memilih alamat dengan GPS.',
          error: true,
        );
        return;
      }

      final paymentMethod = _selectedPayment == 0
          ? PaymentMethod.cod
          : PaymentMethod.midtrans;

      // Validasi ketersediaan COD per UMKM yang dipilih
      final disabledCodUmkms = items
          .where((item) => !item.codAvailable)
          .map((item) => item.umkmName)
          .toSet()
          .toList();

      if (paymentMethod == PaymentMethod.cod && disabledCodUmkms.isNotEmpty) {
        setState(() => _selectedPayment = 1);
        showToast(
          context,
          'Metode COD dinonaktifkan oleh ${disabledCodUmkms.join(", ")}. Dialihkan ke pembayaran online.',
          error: true,
        );
        return;
      }

      // Tampilkan loader modal tanpa henti agar interaksi terkunci dan transisi mulus
      dialogShown = true;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => PopScope(
          canPop: false,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(30),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(
                      color: OC.primary,
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    paymentMethod == PaymentMethod.midtrans
                        ? 'Menghubungkan ke Midtrans...'
                        : 'Membuat pesanan...',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: OC.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Mohon tunggu sebentar',
                    style: TextStyle(fontSize: 13, color: OC.muted),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final order = await _orderService.createOrder(
        lines: items,
        recipient: _recipient,
        paymentMethod: paymentMethod,
        options: options,
      );

      _cartService.removeProducts(items.map((item) => item.productId));

      // Tutup dialog loader sebelum berpindah layar
      if (dialogShown && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        dialogShown = false;
      }

      if (!mounted) return;

      if (paymentMethod == PaymentMethod.midtrans) {
        // Langsung buka layar pembayaran Midtrans tanpa jeda
        await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => MidtransPaymentScreen(
              orderId: order.id,
              paymentUrl: order.paymentUrl,
            ),
          ),
        );

        if (!mounted) return;

        // Setelah selesai dari Midtrans (baik dibayar maupun kembali), arahkan langsung ke Detail Pesanan.
        // Menjamin user tidak pernah stuck di halaman keranjang lagi!
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OrderDetailScreen(orderId: order.id),
          ),
        );
      } else {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OrderDetailScreen(orderId: order.id),
          ),
        );
      }
    } on OrderException catch (e) {
      if (dialogShown && mounted) {
        Navigator.of(
          context,
          rootNavigator: true,
        ).pop(); // Tutup dialog loader jika gagal
        dialogShown = false;
      }
      if (mounted) {
        showToast(context, e.message, error: true);
      }
    } catch (e) {
      if (dialogShown && mounted) {
        Navigator.of(
          context,
          rootNavigator: true,
        ).pop(); // Tutup dialog loader jika gagal
        dialogShown = false;
      }
      if (mounted) {
        showToast(context, 'Terjadi kesalahan: $e', error: true);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _cartService,
      builder: (context, _) {
        _syncSelection();

        // Sinkronkan ketersediaan COD dan pengantaran dengan katalog realtime
        final grouped = _cartService.itemsByUmkm;
        final bool isEmpty = grouped.isEmpty;

        final selected = _selectedItems;
        final bool hasPoSelected =
            selected.any((item) => item.type == OrderType.preOrder);

        // Cari UMKM data untuk skema PO — gunakan Provider CatalogService
        Umkm? activeUmkm;
        if (selected.isNotEmpty) {
          final firstUmkmId = selected.first.umkmId;
          activeUmkm = context.read<CatalogService>().umkmById(firstUmkmId);
        }
        final String skemaPo =
            activeUmkm?.skemaPo ?? 'Lunas di Awal (Full Payment)';
        final bool isTanpaDp = skemaPo.toLowerCase().contains('tanpa dp') ||
            skemaPo.toLowerCase().contains('bayar saat');
        final bool isDp30 = skemaPo.contains('30%');
        final bool isDp50 = skemaPo.contains('50%');

        final disabledCodUmkms = selected
            .where((item) => !item.codAvailable)
            .map((item) => item.umkmName)
            .toSet()
            .toList();

        // Jika ada item PO dan skema toko BUKAN Tanpa DP, COD dinonaktifkan
        if (hasPoSelected && !isTanpaDp && activeUmkm != null) {
          if (!disabledCodUmkms.contains(activeUmkm.name)) {
            disabledCodUmkms.add(
              '${activeUmkm.name} (Pre-Order wajib ${isDp30 ? 'DP 30%' : (isDp50 ? 'DP 50%' : 'Lunas')})',
            );
          }
        }

        final bool isCodAvailable = selected.isNotEmpty &&
            disabledCodUmkms.isEmpty &&
            (!hasPoSelected || isTanpaDp);

        // Jika opsi COD dinonaktifkan oleh UMKM yang dipilih, otomatis pindahkan ke Midtrans
        if (!isCodAvailable && _selectedPayment == 0 && selected.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _selectedPayment == 0) {
              setState(() => _selectedPayment = 1);
            }
          });
        }

        // Compute subtotals & delivery
        int subtotalProduk = 0;
        int totalOngkir = 0;

        for (final entry in grouped.entries) {
          final umkmId = entry.key;
          final lines = entry.value
              .where((item) => _selectedKeys.contains(_cartKey(item)))
              .toList();
          if (lines.isEmpty) continue;
          final int umkmItemsTotal = lines.fold(
            0,
            (sum, l) => sum + l.subtotal.round(),
          );
          subtotalProduk += umkmItemsTotal;

          final deliveryChoice =
              _deliveryOptions[umkmId] ??
              (lines.first.courierFee != null ? 0 : 1);
          if (deliveryChoice == 0 && lines.first.courierFee != null) {
            // Gunakan ongkir hasil kalkulasi dinamis jika sudah tersedia
            final calculatedFee = _courierFees[umkmId];
            if (calculatedFee != null && calculatedFee >= 0) {
              totalOngkir += calculatedFee;
            }
            // Jika belum ada (masih loading / belum dihitung), tidak ditambahkan dulu
          }
        }

        // Trigger kalkulasi ongkir jika belum dilakukan dan alamat sudah ada GPS
        if (_addressHasCoords) {
          for (final entry in grouped.entries) {
            final umkmId = entry.key;
            final lines = entry.value;
            if (lines.isEmpty) continue;
            final deliveryChoice =
                _deliveryOptions[umkmId] ??
                (lines.first.courierFee != null ? 0 : 1);
            if (deliveryChoice == 0 &&
                lines.first.courierFee != null &&
                !_courierFees.containsKey(umkmId) &&
                _ongkirLoading[umkmId] != true) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _calculateOngkirForUmkm(umkmId, lines.first);
              });
            }
          }
        }

        final int totalPembayaran = subtotalProduk + totalOngkir;

        final bool isDpScheme = hasPoSelected && (isDp30 || isDp50);
        final String dpLabel = isDp30 ? 'DP 30%' : (isDp50 ? 'DP 50%' : 'DP');
        final int nominalDp = isDpScheme
            ? (totalPembayaran * (isDp30 ? 0.30 : 0.50)).round()
            : totalPembayaran;
        final int sisaPelunasan = totalPembayaran - nominalDp;

        final needsBackButton =
            widget.onBack != null || Navigator.canPop(context);

        return Scaffold(
          backgroundColor: OC.bg,
          body: Stack(
            children: [
              const HeaderBotanicalBackdrop(height: 220),
              SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    // Header dengan back button jika diperlukan
                    if (needsBackButton)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                        child: Row(
                          children: [
                            DjajanBackButton(
                              onPressed:
                                  widget.onBack ?? () => Navigator.pop(context),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Keranjang Belanja',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: OC.ink,
                                      letterSpacing: -0.3,
                                      height: 1.15,
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    'Cek kembali item jajan & katering pilihanmu',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: OC.muted,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      height: 1.15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.fromLTRB(14, 10, 14, 10),
                        child: UmkmHeaderRow(
                          padding: EdgeInsets.zero,
                          iconBadge: UmkmSquircleIcon(
                            icon: Icons.shopping_cart_rounded,
                          ),
                          title: 'Keranjang Belanja',
                          subtitle: 'Cek kembali item jajan & katering pilihanmu',
                        ),
                      ),
                    // Content
                    Expanded(
                      child: isEmpty
                          ? _buildEmptyCart()
                          : ListView(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              children: [
                                // 1. Notice banner
                                _buildNoticeBanner(grouped.length),
                                const SizedBox(height: 10),
                                _buildSelectionBar(),
                                const SizedBox(height: 10),

                                // 2. Receiver info
                                _buildReceiverCard(),
                                const SizedBox(height: 10),

                                // 3. Vendor Cards (per UMKM)
                                for (final entry in grouped.entries) ...[
                                  _buildUmkmCard(entry.key, entry.value),
                                  const SizedBox(height: 10),
                                ],

                                // 4. Payment method
                                if (_selectedItems.isNotEmpty) ...[
                                  _buildPaymentMethodCard(
                                    isCodAvailable: isCodAvailable,
                                    disabledCodUmkmNames: disabledCodUmkms,
                                  ),
                                  const SizedBox(height: 10),
                                ],

                                // 5. Payment summary
                                _buildPaymentSummaryCard(
                                  subtotalProduk: subtotalProduk,
                                  totalOngkir: totalOngkir,
                                  totalPembayaran: totalPembayaran,
                                  isDpScheme: isDpScheme,
                                  dpLabel: dpLabel,
                                  nominalDp: nominalDp,
                                  sisaPelunasan: sisaPelunasan,
                                ),
                                const SizedBox(height: 14),

                                // 6. Trust footer
                                _buildTrustFooter(),
                                const SizedBox(height: 12),

                                // 7. Action button
                                _buildCheckoutButton(
                                  totalPembayaran,
                                  isDpScheme: isDpScheme,
                                  dpLabel: dpLabel,
                                  nominalDp: nominalDp,
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------- Empty Cart
  Widget _buildEmptyCart() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: const BoxDecoration(
                color: OC.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                size: 46,
                color: OC.primary,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Keranjang Belanja Kosong',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: OC.ink,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Temukan makanan dan jajanan favorit dari usaha lokal di sekitar Anda.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: OC.muted, height: 1.4),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: OC.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed:
                    widget.onExploreProducts ??
                    () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
                icon: const Icon(Icons.storefront_outlined),
                label: const Text(
                  'Mulai Belanja',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1. Notice banner
  Widget _buildNoticeBanner(int umkmCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: OC.banner,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: OC.line),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: OC.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.storefront, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pesanan dari $umkmCount UMKM Berbeda',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                    color: OC.ink,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Sistem mengelompokkan pengantaran per masing-masing UMKM',
                  style: TextStyle(fontSize: 11.5, color: OC.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionBar() {
    final itemCount = _cartService.items.length;
    final selectedCount = _selectedItems.length;
    final allSelected = itemCount > 0 && selectedCount == itemCount;

    return _card(
      child: Row(
        children: [
          Checkbox(
            value: allSelected,
            tristate: selectedCount > 0 && !allSelected,
            activeColor: OC.primary,
            onChanged: (value) => _toggleAll(value ?? false),
          ),
          const Expanded(
            child: Text(
              'Pilih produk untuk checkout',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13.5,
                color: OC.ink,
              ),
            ),
          ),
          Text(
            '$selectedCount/$itemCount dipilih',
            style: const TextStyle(
              fontSize: 12,
              color: OC.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // 2. Receiver info
  Widget _buildReceiverCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: OC.primary, size: 18),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Kontak & Alamat Penerima',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                    color: OC.ink,
                  ),
                ),
              ),
              InkWell(
                onTap: _editRecipient,
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    'Ubah',
                    style: TextStyle(
                      color: OC.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 18, color: OC.line),
          Row(
            children: [
              Flexible(
                child: Text(
                  _recipient.name.isEmpty
                      ? 'Alamat penerima belum dipilih'
                      : _recipient.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: OC.ink,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (_recipient.phone.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: OC.mint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat_bubble, size: 10, color: OC.mintText),
                      SizedBox(width: 4),
                      Text(
                        'WhatsApp Aktif',
                        style: TextStyle(
                          color: OC.mintText,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(width: 6),
              if (_recipient.addressId == null)
                const Pill(
                  text: 'Pilih Alamat',
                  bg: OC.peach,
                  fg: OC.amber,
                  icon: Icons.warning_amber_rounded,
                )
              else if (_addressHasCoords)
                const Pill(
                  text: 'GPS Aktif',
                  bg: OC.mint,
                  fg: OC.primary,
                  icon: Icons.location_on,
                )
              else
                const Pill(
                  text: 'Belum Ada GPS',
                  bg: OC.peach,
                  fg: OC.amber,
                  icon: Icons.location_off_outlined,
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              if (_recipient.phone.isNotEmpty) ...[
                const Icon(Icons.phone_outlined, size: 14, color: OC.primary),
                const SizedBox(width: 6),
                Text(
                  _recipient.phone,
                  style: const TextStyle(
                    fontSize: 13,
                    color: OC.muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _recipient.address.isEmpty
                ? 'Tambahkan alamat sebelum melanjutkan pesanan.'
                : _recipient.address,
            style: const TextStyle(
              fontSize: 12.5,
              color: OC.muted,
              height: 1.3,
            ),
          ),
          if (_addressError != null) ...[
            const SizedBox(height: 6),
            Text(
              _addressError!,
              style: const TextStyle(color: OC.danger, fontSize: 11.5),
            ),
          ],
          if (_recipient.addressNote != null &&
              _recipient.addressNote!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              '(${_recipient.addressNote})',
              style: const TextStyle(
                fontSize: 11.5,
                fontStyle: FontStyle.italic,
                color: OC.faint,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 3. Card for each UMKM
  Widget _buildUmkmCard(String umkmId, List<CartLine> lines) {
    final first = lines.first;
    final selectedLines = lines
        .where((item) => _selectedKeys.contains(_cartKey(item)))
        .toList();
    final bool hasPreOrder = selectedLines.any(
      (l) => l.type == OrderType.preOrder,
    );
    final bool hasInstant = selectedLines.any(
      (l) => l.type == OrderType.instant,
    );

    final int deliveryChoice =
        _deliveryOptions[umkmId] ?? (first.courierFee != null ? 0 : 1);

    // Gunakan ongkir dari hasil kalkulasi API; jika belum ada, tampilkan 0 sementara
    final bool ongkirLoading = _ongkirLoading[umkmId] == true;
    final int? calculatedOngkir = _courierFees[umkmId];
    final bool ongkirOutOfRange = calculatedOngkir == -1;
    final String? ongkirDistance = _ongkirDistance[umkmId] != null
        ? '~${_ongkirDistance[umkmId]!.toStringAsFixed(1)} km'
        : null;

    final int courierFee;
    if (deliveryChoice == 0 && first.courierFee != null) {
      if (calculatedOngkir != null && calculatedOngkir >= 0) {
        courierFee = calculatedOngkir;
      } else {
        courierFee = 0; // Belum dihitung / loading
      }
    } else {
      courierFee = 0;
    }

    final int itemsSubtotal = selectedLines.fold(
      0,
      (s, l) => s + l.subtotal.round(),
    );
    final int umkmTotal = itemsSubtotal + courierFee;

    // Header badge
    String headerBadgeText;
    Color headerBadgeBg;
    Color headerBadgeFg;
    IconData headerBadgeIcon;

    if (hasPreOrder && hasInstant) {
      headerBadgeText = 'PO & INSTANT';
      headerBadgeBg = OC.mint;
      headerBadgeFg = OC.mintText;
      headerBadgeIcon = Icons.inventory_2_outlined;
    } else if (hasPreOrder) {
      headerBadgeText = 'PRE-ORDER';
      headerBadgeBg = OC.peach;
      headerBadgeFg = OC.amber;
      headerBadgeIcon = Icons.emoji_events_outlined;
    } else {
      headerBadgeText = 'PESAN SEKARANG';
      headerBadgeBg = OC.mint;
      headerBadgeFg = OC.mintText;
      headerBadgeIcon = Icons.flash_on;
    }

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header UMKM
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: OC.mintSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.soup_kitchen_outlined,
                  color: OC.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      first.umkmName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: OC.ink,
                      ),
                    ),
                    Text(
                      first.umkmType,
                      style: const TextStyle(fontSize: 11.5, color: OC.muted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: headerBadgeBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(headerBadgeIcon, size: 12, color: headerBadgeFg),
                    const SizedBox(width: 4),
                    Text(
                      headerBadgeText,
                      style: TextStyle(
                        color: headerBadgeFg,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),

          // Items inside this UMKM
          for (final item in lines) ...[
            const Divider(height: 1, color: OC.line),
            _buildCartItemRow(item),
          ],

          // Pre-Order Details Box (if this UMKM has any Pre-Order products)
          if (hasPreOrder) ...[
            const Divider(height: 1, color: OC.line),
            const SizedBox(height: 10),
            _buildPreOrderSection(umkmId),
          ],

          const Divider(height: 22, color: OC.line),

          // Delivery Options
          const Text(
            'Opsi Pengantaran',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12.5,
              color: OC.ink,
            ),
          ),
          const SizedBox(height: 8),

          // Option 1: Diantar Kurir
          if (first.courierFee != null) ...[
            _choiceTile(
              selected: deliveryChoice == 0,
              onTap: () {
                setState(() {
                  _deliveryOptions[umkmId] = 0;
                });
                // Trigger kalkulasi jika belum ada dan alamat sudah GPS
                if (_addressHasCoords &&
                    !_courierFees.containsKey(umkmId) &&
                    _ongkirLoading[umkmId] != true) {
                  _calculateOngkirForUmkm(umkmId, first);
                }
              },
              title: 'Diantar Kurir',
              subtitle: ongkirLoading
                  ? (ongkirDistance != null
                        ? 'Jarak $ongkirDistance • Menghitung tarif...'
                        : 'Menghitung tarif ongkir...')
                  : ongkirOutOfRange
                  ? 'Di luar jangkauan kurir UMKM ini'
                  : ongkirDistance != null
                  ? 'Jarak $ongkirDistance • Langsung diantar ke rumah'
                  : 'Langsung diantar ke rumah',
              trailing: ongkirLoading
                  ? '...'
                  : ongkirOutOfRange
                  ? 'Tidak tersedia'
                  : (calculatedOngkir != null && calculatedOngkir == 0)
                  ? 'Gratis'
                  : calculatedOngkir != null
                  ? '+${_formatRupiah(calculatedOngkir)}'
                  : _addressHasCoords
                  ? 'Menghitung...'
                  : 'Butuh GPS',
            ),
            const SizedBox(height: 8),
          ],

          // Option 2: Ambil Sendiri (Pickup)
          _choiceTile(
            selected: deliveryChoice == 1,
            onTap: () {
              setState(() {
                _deliveryOptions[umkmId] = 1;
              });
            },
            title: 'Ambil Sendiri (Pickup)',
            subtitle: 'Lokasi: ${first.pickupLocation}',
            trailing: 'Gratis',
          ),

          const Divider(height: 22, color: OC.line),

          // Subtotal UMKM
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Subtotal (${first.umkmName})',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: OC.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                _formatRupiah(umkmTotal),
                style: const TextStyle(
                  fontSize: 13.5,
                  color: OC.ink,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Radio-style choice tile (delivery options)
  Widget _choiceTile({
    required bool selected,
    required VoidCallback onTap,
    required String title,
    required String subtitle,
    required String trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? OC.mintSoft : Colors.white,
          border: Border.all(color: selected ? OC.primary : OC.line),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? OC.primary : OC.faint,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                      color: OC.ink,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11.5, color: OC.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              trailing,
              style: const TextStyle(
                color: OC.primary,
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Row for each Product Item in Cart
  Widget _buildCartItemRow(CartLine item) {
    final bool isPO = item.type == OrderType.preOrder;
    final bool isSelected = _selectedKeys.contains(_cartKey(item));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: isSelected,
            activeColor: OC.primary,
            onChanged: (value) =>
                _toggleProduct(_cartKey(item), value ?? false),
          ),
          _productImage(
            imageUrl: item.imageUrl,
            fallbackIcon: isPO ? Icons.lunch_dining : Icons.local_drink,
            fallbackColor: isPO ? OC.amber : OC.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.productName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                          color: OC.ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Badge PO / Instant per item
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isPO ? OC.peach : OC.mint,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isPO ? 'PO' : 'Ready',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: isPO ? OC.amber : OC.mintText,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.variant} • ${_formatRupiah(item.price.round())} / ${item.unit}',
                  style: const TextStyle(fontSize: 11.5, color: OC.muted),
                ),
                if (isPO && item.minOrderPo > 1) ...[
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: item.quantity < item.minOrderPo
                          ? const Color(0xFFFEF2F2)
                          : const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: item.quantity < item.minOrderPo
                            ? const Color(0xFFFECACA)
                            : const Color(0xFFFDE68A),
                      ),
                    ),
                    child: Text(
                      item.quantity < item.minOrderPo
                          ? 'Min. order: ${item.minOrderPo} ${item.unit} (Belum tercapai)'
                          : 'Min. order: ${item.minOrderPo} ${item.unit}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: item.quantity < item.minOrderPo
                            ? const Color(0xFFDC2626)
                            : const Color(0xFFB45309),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatRupiah(item.subtotal.round()),
                      style: const TextStyle(
                        color: OC.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    // Quantity Stepper: [-] [qty] [+]
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: OC.line),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () {
                              _cartService.updateQuantity(
                                item.productId,
                                item.quantity - 1,
                                type: item.type,
                              );
                            },
                            borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(8),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              child: Icon(
                                item.quantity == 1
                                    ? Icons.delete_outline
                                    : Icons.remove,
                                size: 16,
                                color: item.quantity == 1 ? OC.danger : OC.ink,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            child: Text(
                              '${item.quantity}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: OC.ink,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              _cartService.updateQuantity(
                                item.productId,
                                item.quantity + 1,
                                type: item.type,
                              );
                            },
                            borderRadius: const BorderRadius.horizontal(
                              right: Radius.circular(8),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              child: Icon(Icons.add, size: 16, color: OC.ink),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Pre-Order Section per UMKM
  Widget _buildPreOrderSection(String umkmId) {
    final date = _getPoDate(umkmId);
    final purposeCtrl = _getPurposeController(umkmId);
    final noteCtrl = _getNoteController(umkmId);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: OC.peachSoft,
        border: Border.all(color: OC.peach),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.event_note, color: OC.amber, size: 16),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Detail Jadwal & Keperluan Pre-Order',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                    color: OC.amber,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Waktu Dibutuhkan
          InkWell(
            onTap: () => _pickDateTime(umkmId),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: date == null ? OC.danger.withAlpha(120) : OC.peach,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 15,
                    color: date == null ? OC.danger : OC.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Waktu Dibutuhkan',
                          style: TextStyle(fontSize: 10.5, color: OC.muted),
                        ),
                        Text(
                          date != null
                              ? fmtDateComma(date)
                              : 'Ketuk untuk pilih tanggal & waktu acara',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: date != null ? OC.ink : OC.danger,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: OC.muted),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Keperluan Acara
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: OC.peach),
            ),
            child: TextField(
              controller: purposeCtrl,
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                labelText: 'Keperluan Acara',
                labelStyle: TextStyle(fontSize: 12, color: OC.muted),
                hintText: 'Contoh: Rapat RT, Pengajian, Hajatan',
                hintStyle: TextStyle(fontSize: 12, color: OC.faint),
              ),
              style: const TextStyle(fontSize: 12.5, color: OC.ink),
            ),
          ),
          const SizedBox(height: 6),

          // Catatan Kemasan
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: OC.peach),
            ),
            child: TextField(
              controller: noteCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                labelText: 'Catatan Pengemasan / Pesanan',
                labelStyle: TextStyle(fontSize: 12, color: OC.muted),
                hintText: 'Contoh: Sambal dipisah, kemangi dipacking rapi...',
                hintStyle: TextStyle(fontSize: 12, color: OC.faint),
              ),
              style: const TextStyle(fontSize: 12.5, color: OC.ink),
            ),
          ),
        ],
      ),
    );
  }

  // 4. Payment method
  Widget _buildPaymentMethodCard({
    required bool isCodAvailable,
    required List<String> disabledCodUmkmNames,
  }) {
    final String disabledReason = disabledCodUmkmNames.isNotEmpty
        ? (disabledCodUmkmNames.length == 1
              ? '${disabledCodUmkmNames.first} tidak melayani COD'
              : 'Beberapa UMKM tidak melayani COD')
        : 'COD tidak tersedia untuk produk ini';

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.payment, color: OC.primary, size: 18),
              SizedBox(width: 6),
              Text(
                'Metode Pembayaran',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: OC.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // COD
              Expanded(
                child: _paymentTile(
                  selected: isCodAvailable && _selectedPayment == 0,
                  enabled: isCodAvailable,
                  disabledReason: disabledReason,
                  onTap: isCodAvailable
                      ? () {
                          setState(() {
                            _selectedPayment = 0;
                          });
                        }
                      : () {
                          showToast(
                            context,
                            'Opsi COD dinonaktifkan oleh toko: ${disabledCodUmkmNames.join(", ")}',
                            error: true,
                          );
                        },
                  icon: Icons.payments_outlined,
                  title: 'Bayar di Tempat (COD)',
                  subtitle: isCodAvailable
                      ? 'Titip tunai ke kurir warga'
                      : disabledReason,
                ),
              ),
              const SizedBox(width: 8),

              // Midtrans / Pembayaran Instan
              Expanded(
                child: _paymentTile(
                  selected: _selectedPayment == 1,
                  enabled: true,
                  onTap: () {
                    setState(() {
                      _selectedPayment = 1;
                    });
                  },
                  icon: Icons.bolt,
                  title: 'Bayar Sekarang',
                  subtitle: 'QRIS, GoPay, ShopeePay, VA',
                ),
              ),
            ],
          ),
          if (!isCodAvailable && _selectedItems.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: OC.dangerSoft,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: OC.danger.withAlpha(50)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 15, color: OC.danger),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Pilihan COD dinonaktifkan oleh ${disabledCodUmkmNames.join(", ")}. Silakan gunakan pembayaran instan.',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: OC.danger,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _paymentTile({
    required bool selected,
    required VoidCallback? onTap,
    required IconData icon,
    required String title,
    required String subtitle,
    bool enabled = true,
    String? disabledReason,
  }) {
    final bgColor = !enabled
        ? OC.box
        : selected
        ? OC.mintSoft
        : Colors.white;

    final borderColor = !enabled
        ? OC.line
        : selected
        ? OC.primary
        : OC.line;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  icon,
                  color: enabled
                      ? (selected ? OC.primary : OC.muted)
                      : OC.faint,
                  size: 22,
                ),
                Icon(
                  !enabled
                      ? Icons.lock_outline
                      : selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: !enabled
                      ? OC.faint
                      : selected
                      ? OC.primary
                      : OC.faint,
                  size: 18,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: enabled ? OC.ink : OC.muted,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                color: !enabled ? OC.danger : OC.muted,
                fontWeight: !enabled ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 5. Payment Summary Card
  Widget _buildPaymentSummaryCard({
    required int subtotalProduk,
    required int totalOngkir,
    required int totalPembayaran,
    bool isDpScheme = false,
    String dpLabel = 'DP',
    int nominalDp = 0,
    int sisaPelunasan = 0,
  }) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.receipt_long_outlined, color: OC.primary, size: 18),
              SizedBox(width: 6),
              Text(
                'Rincian Pembayaran',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: OC.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _summaryRow('Subtotal Produk', _formatRupiah(subtotalProduk)),
          _summaryRow(
            'Total Ongkir Kurir UMKM',
            totalOngkir == 0 ? 'Gratis (Rp 0)' : _formatRupiah(totalOngkir),
          ),
          const Divider(height: 20, color: OC.line),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Pembayaran',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: OC.ink,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Sudah termasuk biaya kemasan',
                    style: TextStyle(fontSize: 11, color: OC.muted),
                  ),
                ],
              ),
              Text(
                _formatRupiah(totalPembayaran),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: OC.primary,
                ),
              ),
            ],
          ),
          if (isDpScheme) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bayar Sekarang ($dpLabel)',
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: OC.primary,
                            ),
                          ),
                          const Text(
                            'Uang muka via Midtrans / QRIS',
                            style: TextStyle(fontSize: 11, color: OC.muted),
                          ),
                        ],
                      ),
                      Text(
                        _formatRupiah(nominalDp),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: OC.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sisa Pelunasan',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFD97706),
                            ),
                          ),
                          Text(
                            'Dibayar saat pesanan diantar',
                            style: TextStyle(fontSize: 10.5, color: OC.muted),
                          ),
                        ],
                      ),
                      Text(
                        _formatRupiah(sisaPelunasan),
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD97706),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 6. Trust Footer
  Widget _buildTrustFooter() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.verified_user_outlined, size: 15, color: OC.primary),
        SizedBox(width: 6),
        Flexible(
          child: Text(
            'Belanja aman langsung memajukan tetangga & UMKM desa',
            style: TextStyle(color: OC.muted, fontSize: 11.5),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  // 7. Checkout Button
  Widget _buildCheckoutButton(
    int total, {
    bool isDpScheme = false,
    String dpLabel = 'DP',
    int nominalDp = 0,
  }) {
    final String buttonLabel;
    if (_selectedItems.isEmpty) {
      buttonLabel = 'Pilih produk terlebih dahulu';
    } else if (isDpScheme) {
      buttonLabel = 'Bayar $dpLabel Sekarang (${_formatRupiah(nominalDp)})';
    } else {
      buttonLabel = 'Pesan Sekarang (${_formatRupiah(total)})';
    }

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: OC.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: _isSubmitting || _selectedItems.isEmpty
            ? null
            : _handleCheckout,
        child: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                buttonLabel,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _productImage({
    required String imageUrl,
    required IconData fallbackIcon,
    required Color fallbackColor,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: AppNetworkImage(
        url: imageUrl,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorWidget: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: fallbackColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(fallbackIcon, size: 24, color: fallbackColor),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12.5, color: OC.muted)),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: OC.ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: OC.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: OC.line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  String _formatRupiah(int amount) {
    final str = amount.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i > 0) {
        buffer.write('.');
      }
    }
    return 'Rp ${buffer.toString().split('').reversed.join('')}';
  }
}
