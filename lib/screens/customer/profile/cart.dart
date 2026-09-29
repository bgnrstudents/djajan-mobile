import 'package:flutter/material.dart';

class CartScreen extends StatefulWidget {
  final bool showAppBar;
  final VoidCallback? onBack;

  const CartScreen({
    super.key,
    this.showAppBar = true,
    this.onBack,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // Theme colors matching design
  static const Color primaryGreen = Color(0xFF006B45);
  static const Color darkGreen = Color(0xFF0F6848);
  static const Color softBlueCard = Color(0xFFEFF3FD);
  static const Color softBlueNotice = Color(0xFFE8EEFD);
  static const Color background = Color(0xFFF8F9FD);
  static const Color textDark = Color(0xFF1E293B);
  static const Color textMuted = Color(0xFF64748B);

  // Interactive states
  int _mintenDeliveryOption = 0; // 0: Kurir (+5000), 1: Pickup (0)
  int _selectedPayment = 0; // 0: COD, 1: QRIS

  @override
  Widget build(BuildContext context) {
    final int buMintenOngkir = _mintenDeliveryOption == 0 ? 5000 : 0;
    final int buMintenSubtotal = 150000 + buMintenOngkir;
    const int pakBudiSubtotal = 25000;
    const int subtotalProduk = 150000 + 25000;
    final int totalOngkir = buMintenOngkir;
    final int totalPembayaran = subtotalProduk + totalOngkir;

    return Scaffold(
      backgroundColor: background,
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: background,
              elevation: 0,
              centerTitle: true,
              leading: widget.onBack != null
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back, color: textDark),
                      onPressed: widget.onBack,
                    )
                  : (Navigator.canPop(context)
                      ? IconButton(
                          icon: const Icon(Icons.arrow_back, color: textDark),
                          onPressed: () => Navigator.pop(context),
                        )
                      : null),
              title: const Text(
                'Keranjang',
                style: TextStyle(
                  color: textDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // 1. Notice banner
          _buildNoticeBanner(),
          const SizedBox(height: 14),

          // 2. Receiver info
          _buildReceiverCard(),
          const SizedBox(height: 14),

          // 3. Seller 1: Dapur Bu Minten
          _buildBuMintenCard(buMintenSubtotal),
          const SizedBox(height: 14),

          // 4. Seller 2: Toko Pak Budi
          _buildPakBudiCard(pakBudiSubtotal),
          const SizedBox(height: 14),

          // 5. Payment method
          _buildPaymentMethodCard(),
          const SizedBox(height: 14),

          // 6. Payment summary
          _buildPaymentSummaryCard(
            subtotalProduk: subtotalProduk,
            totalOngkir: totalOngkir,
            totalPembayaran: totalPembayaran,
          ),
          const SizedBox(height: 16),

          // 7. Trust footer
          _buildTrustFooter(),
          const SizedBox(height: 16),

          // 8. Action button
          _buildCheckoutButton(totalPembayaran),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // 1. Notice banner
  Widget _buildNoticeBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: softBlueNotice,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: darkGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.storefront,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pesanan dari 2 UMKM Berbeda',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Sistem mengelompokkan pengantaran per masing-masing UMKM',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF4B5563),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 2. Receiver Card
  Widget _buildReceiverCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: primaryGreen, size: 20),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Kontak & Alamat Penerima',
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ubah alamat penerima'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    'Ubah',
                    style: TextStyle(
                      color: primaryGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: softBlueCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Muhammad Rizki',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.chat_bubble, size: 10, color: Color(0xFF16A34A)),
                          SizedBox(width: 4),
                          Text(
                            'WhatsApp Aktif',
                            style: TextStyle(
                              color: Color(0xFF16A34A),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: const [
                    Icon(Icons.phone_outlined, size: 15, color: primaryGreen),
                    SizedBox(width: 6),
                    Text(
                      '0812-3456-7890',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF334155),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Jl. Merpati No. 14, RT 02 / RW 01, Desa Kreyongan Atas',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF334155),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  '(Rumah pagar hijau samping pos ronda desa)',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 3. Seller 1: Dapur Bu Minten
  Widget _buildBuMintenCard(int subtotal) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEEAD9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.soup_kitchen_outlined,
                  color: Color(0xFF9A4C16),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dapur Bu Minten',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: textDark,
                      ),
                    ),
                    Text(
                      'Spesialis Katering & Kotakan',
                      style: TextStyle(
                        fontSize: 12,
                        color: textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBE5D2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.emoji_events_outlined,
                      size: 13,
                      color: Color(0xFF8D4A18),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'PRE-ORDER',
                      style: TextStyle(
                        color: Color(0xFF8D4A18),
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Product Container
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: softBlueCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _productImage(
                  imageUrl:
                      'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?w=200&q=80',
                  fallbackIcon: Icons.lunch_dining,
                  fallbackColor: Colors.orange.shade400,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nasi Kotak Ayam Geprek',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: textDark,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Porsi Spesial Kenduri • x10 Kotak',
                        style: TextStyle(
                          fontSize: 12,
                          color: textMuted,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Rp 150.000',
                        style: TextStyle(
                          color: primaryGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Pre-order Info Block
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: softBlueCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: const [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 15,
                            color: Color(0xFF475569),
                          ),
                          SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Waktu Dibutuhkan:',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF334155),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '20 Sept 2026 (11:00 WIB)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: const [
                          Icon(
                            Icons.groups_outlined,
                            size: 17,
                            color: primaryGreen,
                          ),
                          SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Keperluan:',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF334155),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Rapat Desa RT 02',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: const [
                    Icon(
                      Icons.edit_note,
                      size: 18,
                      color: Color(0xFF475569),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Catatan Rasa / Kemasan:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF334155),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '"Sambal dipisah, kemangi dipacking rapi untuk bapak-bapak lurah"',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF334155),
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Opsi Pengantaran UMKM
          const Text(
            'Opsi Pengantaran UMKM',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: textDark,
            ),
          ),
          const SizedBox(height: 8),

          // Option 1: Diantar Kurir
          InkWell(
            onTap: () {
              setState(() {
                _mintenDeliveryOption = 0;
              });
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _mintenDeliveryOption == 0
                    ? const Color(0xFFE5F8ED)
                    : softBlueCard,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    _mintenDeliveryOption == 0
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: _mintenDeliveryOption == 0
                        ? primaryGreen
                        : const Color(0xFF94A3B8),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Diantar Kurir Warga / UMKM',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                            color: textDark,
                          ),
                        ),
                        Text(
                          'Langsung diantar ke balai / rumah',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    '+Rp 5.000',
                    style: TextStyle(
                      color: primaryGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Option 2: Ambil Sendiri
          InkWell(
            onTap: () {
              setState(() {
                _mintenDeliveryOption = 1;
              });
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _mintenDeliveryOption == 1
                    ? const Color(0xFFE5F8ED)
                    : softBlueCard,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    _mintenDeliveryOption == 1
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: _mintenDeliveryOption == 1
                        ? primaryGreen
                        : const Color(0xFF94A3B8),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ambil Sendiri (Pickup)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                            color: textDark,
                          ),
                        ),
                        Text(
                          'Ke dapur Bu Minten RT 01',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    'Rp 0',
                    style: TextStyle(
                      color: textMuted,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Subtotal Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: softBlueCard,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Subtotal Dapur Bu Minten',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
                Text(
                  _formatRupiah(subtotal),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                    color: primaryGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 4. Seller 2: Toko Pak Budi
  Widget _buildPakBudiCard(int subtotal) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFD4F8D3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_cafe_outlined,
                  color: Color(0xFF15803D),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Toko Pak Budi',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: textDark,
                      ),
                    ),
                    Text(
                      'Warung Kelontong & Es Tradisional',
                      style: TextStyle(
                        fontSize: 12,
                        color: textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF75ED85),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.flash_on,
                      size: 13,
                      color: Color(0xFF14532D),
                    ),
                    SizedBox(width: 3),
                    Text(
                      'PESAN SEKARANG',
                      style: TextStyle(
                        color: Color(0xFF14532D),
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Product Container
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: softBlueCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _productImage(
                  imageUrl:
                      'https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=200&q=80',
                  fallbackIcon: Icons.local_drink,
                  fallbackColor: Colors.teal.shade300,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Es Teh Solo Original',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: textDark,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Gula Asli, Cup Jumbo • x5 Gelas',
                        style: TextStyle(
                          fontSize: 12,
                          color: textMuted,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Rp 25.000',
                        style: TextStyle(
                          color: primaryGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Opsi Pengantaran UMKM
          const Text(
            'Opsi Pengantaran UMKM',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: textDark,
            ),
          ),
          const SizedBox(height: 8),

          // Pickup Selected
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE5F8ED),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: const [
                Icon(
                  Icons.check_circle,
                  color: primaryGreen,
                  size: 20,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Pickup (Ambil Sendiri di Toko)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                      color: textDark,
                    ),
                  ),
                ),
                Text(
                  'Gratis (Rp 0)',
                  style: TextStyle(
                    color: primaryGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Subtotal Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: softBlueCard,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Subtotal Toko Pak Budi',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
                Text(
                  _formatRupiah(subtotal),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                    color: primaryGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 5. Payment Method Card
  Widget _buildPaymentMethodCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.payments_outlined, color: primaryGreen, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Metode Pembayaran',
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: darkGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Praktis',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // COD
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedPayment = 0;
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _selectedPayment == 0
                          ? const Color(0xFFE5F8ED)
                          : softBlueCard,
                      border: Border.all(
                        color: _selectedPayment == 0
                            ? primaryGreen
                            : Colors.transparent,
                        width: 1.2,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD2F5DC),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.payments_outlined,
                                color: primaryGreen,
                                size: 18,
                              ),
                            ),
                            Icon(
                              _selectedPayment == 0
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: _selectedPayment == 0
                                  ? primaryGreen
                                  : const Color(0xFF94A3B8),
                              size: 18,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Bayar di Tempat (COD)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Titip tunai ke kurir warga',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // QRIS Warga
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedPayment = 1;
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _selectedPayment == 1
                          ? const Color(0xFFE5F8ED)
                          : softBlueCard,
                      border: Border.all(
                        color: _selectedPayment == 1
                            ? primaryGreen
                            : Colors.transparent,
                        width: 1.2,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Icon(
                              Icons.qr_code_2,
                              color: Color(0xFF334155),
                              size: 24,
                            ),
                            Icon(
                              _selectedPayment == 1
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: _selectedPayment == 1
                                  ? primaryGreen
                                  : const Color(0xFF94A3B8),
                              size: 18,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'QRIS Warga',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'BCA, Mandiri, Dana, GoPay',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 6. Payment Summary Card
  Widget _buildPaymentSummaryCard({
    required int subtotalProduk,
    required int totalOngkir,
    required int totalPembayaran,
  }) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.receipt_long_outlined, color: primaryGreen, size: 20),
              SizedBox(width: 8),
              Text(
                'Rincian Pembayaran',
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _summaryRow('Subtotal Produk (15 item)', _formatRupiah(subtotalProduk)),
          _summaryRow('Total Ongkir Pengantaran', _formatRupiah(totalOngkir)),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Text(
                      'Biaya Layanan Aplikasi',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF334155),
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.cached,
                      size: 14,
                      color: primaryGreen,
                    ),
                  ],
                ),
                const Text(
                  'Gratis (Desa Berdaya)',
                  style: TextStyle(
                    color: primaryGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFFE2E8F0), thickness: 1, height: 18),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Pembayaran',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Sudah termasuk biaya kemasan',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: textMuted,
                    ),
                  ),
                ],
              ),
              Text(
                _formatRupiah(totalPembayaran),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 7. Trust Footer
  Widget _buildTrustFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.verified_user_outlined, size: 16, color: primaryGreen),
        SizedBox(width: 6),
        Flexible(
          child: Text(
            'Belanja aman langsung memajukan tetangga & UMKM desa',
            style: TextStyle(color: Color(0xFF475569), fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  // 8. Checkout Button
  Widget _buildCheckoutButton(int total) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Pesanan berhasil dibuat! Total: ${_formatRupiah(total)}',
              ),
              backgroundColor: primaryGreen,
            ),
          );
        },
        child: Text(
          'Pesan Sekarang (${_formatRupiah(total)})',
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
      child: Image.network(
        imageUrl,
        width: 68,
        height: 68,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: fallbackColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(fallbackIcon, size: 30, color: fallbackColor),
          );
        },
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF334155),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13.5,
              color: textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 4),
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