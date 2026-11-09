import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:djajan_mobile/models/order.dart';
import 'package:djajan_mobile/models/product.dart';
import 'package:djajan_mobile/models/umkm.dart';
import 'package:djajan_mobile/models/umkm_seller_models.dart' as umkm_models;
import 'package:djajan_mobile/screens/customer/order/order_widgets.dart';
import 'package:djajan_mobile/services/cart_service.dart';
import 'package:djajan_mobile/services/map_navigation_service.dart';
import 'package:djajan_mobile/services/order_service.dart';
import 'package:djajan_mobile/services/receipt_pdf_service.dart';

void main() {
  group('Order Model & Cancellation Tests (Task 9)', () {
    test('OrderStatus canCancel respects strict roadmap rules', () {
      expect(OrderStatus.waitingPayment.canCancel, isTrue);
      expect(OrderStatus.reviewing.canCancel, isTrue);

      expect(OrderStatus.processing.canCancel, isFalse);
      expect(OrderStatus.delivering.canCancel, isFalse);
      expect(OrderStatus.completed.canCancel, isFalse);
      expect(OrderStatus.cancelled.canCancel, isFalse);
    });

    test('Order parses cancellation metadata and UMKM name snapshot from JSON', () {
      final json = {
        'id_pesanan': 'PO-20261105-ABCD12',
        'id_checkout': 'CHK-20261105-XYZ',
        'nama_umkm': 'Dapur Bu Siti',
        'spesialis_umkm': 'Kue Basah',
        'alamat_umkm': 'Jl. Kenanga 12',
        'nama_pembeli': 'Andi',
        'no_telp': '081234567890',
        'tanggal_pesan': '2026-11-05 10:00:00',
        'metode_pengiriman': 'kurir',
        'alamat_tujuan': 'Jl. Melati 5',
        'metode_pembayaran': 'midtrans',
        'status_pembayaran': 'batal',
        'payment_status': 'cancel',
        'status_pesanan': 'ditolak',
        'alasan_batal': 'Salah alamat pengiriman',
        'dibatalkan_oleh': 'pelanggan',
        'dibatalkan_pada': '2026-11-05 10:15:00',
        'status_refund': 'perlu_refund',
        'biaya_pengantaran': 5000,
        'biaya_layanan': 0,
        'items': [
          {
            'id_produk': '10',
            'nama_produk': 'Kue Lumpur',
            'satuan': 'kotak',
            'jumlah': 2,
            'harga_satuan': 15000,
            'subtotal': 30000,
          }
        ],
      };

      final order = Order.fromJson(json);

      expect(order.id, 'PO-20261105-ABCD12');
      expect(order.status, OrderStatus.cancelled);
      expect(order.vendors.first.umkmName, 'Dapur Bu Siti');
      expect(order.cancelReason, 'Salah alamat pengiriman');
      expect(order.cancelledBy, 'pelanggan');
      expect(order.cancelledAt, isNotNull);
      expect(order.refundStatus, 'perlu_refund');
      expect(order.canCancel, isFalse);
    });

    test('OrderService rejects cancellation of processing order', () async {
      final service = OrderService();
      
      final order = Order(
        id: 'PO-TEST-1',
        refId: 'PO-TEST-1',
        createdAt: DateTime(2026, 11, 5),
        status: OrderStatus.processing,
        paymentMethod: PaymentMethod.cod,
        serviceFee: 0,
        discount: 0,
        account: PaymentAccount(bank: 'BRI', bankFullName: '', number: '', holder: ''),
        recipient: Recipient(
          name: 'Budi Santoso',
          phone: '08123456789',
          address: 'Jl. Desa Maju No. 10',
        ),
        vendors: [
          OrderVendor(
            umkmId: '1',
            umkmName: 'Toko Donat',
            umkmType: 'Kue',
            type: OrderType.instant,
            delivery: DeliveryMethod.pickup,
            deliveryFee: 0,
            pickupLocation: 'Jl. Toko Donat',
            items: [
              OrderItem(
                productId: '1',
                productName: 'Donat Gula',
                variant: 'Standar',
                unit: 'pcs',
                imageUrl: '',
                quantity: 2,
                price: 5000,
              ),
            ],
          ),
        ],
      );

      service.seedOrders([order]);

      // Attempting to cancel should throw OrderException
      expect(
        () => service.cancelOrder(order.id, reason: 'Mau batal'),
        throwsA(isA<OrderException>()),
      );
    });

    test('OrderService successfully cancels a waiting payment order', () async {
      final service = OrderService();
      
      final order = Order(
        id: 'PO-TEST-2',
        refId: 'PO-TEST-2',
        createdAt: DateTime(2026, 11, 5),
        status: OrderStatus.waitingPayment,
        paymentMethod: PaymentMethod.cod,
        serviceFee: 0,
        discount: 0,
        account: PaymentAccount(bank: 'BRI', bankFullName: '', number: '', holder: ''),
        recipient: Recipient(
          name: 'Siti Aminah',
          phone: '08123456788',
          address: 'Jl. Desa Maju No. 12',
        ),
        vendors: [
          OrderVendor(
            umkmId: '2',
            umkmName: 'Warung Bu Ani',
            umkmType: 'Jajanan',
            type: OrderType.instant,
            delivery: DeliveryMethod.pickup,
            deliveryFee: 0,
            pickupLocation: 'Jl. Pasar Desa',
            items: [
              OrderItem(
                productId: '2',
                productName: 'Pastel Basah',
                variant: 'Ayam',
                unit: 'pcs',
                imageUrl: '',
                quantity: 3,
                price: 4000,
              ),
            ],
          ),
        ],
      );

      service.seedOrders([order]);
      expect(order.status, OrderStatus.waitingPayment);

      final cancelled = await service.cancelOrder(
        order.id,
        reason: 'Ingin memesan produk lain',
      );

      expect(cancelled.status, OrderStatus.cancelled);
      expect(cancelled.cancelReason, 'Ingin memesan produk lain');
      expect(cancelled.cancelledBy, 'pelanggan');
      expect(cancelled.cancelledAt, isNotNull);
    });

    test('Umkm parses cod_available and cod_aktif correctly', () {
      final umkmCodActive = Umkm.fromJson({
        'id_umkm': '1',
        'nama_usaha': 'Warung Berkah',
        'cod_aktif': 1,
      });
      expect(umkmCodActive.codAvailable, isTrue);

      final umkmCodDisabled = Umkm.fromJson({
        'id_umkm': '2',
        'nama_usaha': 'Dapur Mama',
        'cod_aktif': 0,
      });
      expect(umkmCodDisabled.codAvailable, isFalse);
    });

    test('CartService syncWithCatalog dynamically updates codAvailable state', () {
      final cart = CartService();
      cart.clear();

      final initialLine = CartLine(
        productId: 'prod_1',
        productName: 'Lemper Ayam',
        variant: 'Original',
        unit: 'pcs',
        imageUrl: '',
        quantity: 2,
        price: 3000,
        type: OrderType.instant,
        umkmId: 'umkm_10',
        umkmName: 'Warung Lemper',
        umkmType: 'Jajanan Pasar',
        pickupLocation: 'Kreyongan',
        codAvailable: true,
      );
      cart.addCartLine(initialLine);

      expect(cart.items.first.codAvailable, isTrue);

      // Simulasikan UMKM menonaktifkan COD di dashboard dan katalog diperbarui
      final updatedCatalogProduct = Product(
        id: 'prod_1',
        name: 'Lemper Ayam',
        umkmId: 'umkm_10',
        umkm: 'Warung Lemper',
        price: 3000,
        rating: 4.8,
        category: 'Jajanan',
        orderType: 'Pesan Sekarang',
        imageUrl: '',
        description: 'Lemper ayam gurih',
        variant: 'Original',
        unit: 'pcs',
        pickupLocation: 'Kreyongan',
        codAvailable: false,
      );

      cart.syncWithCatalog([updatedCatalogProduct]);

      expect(cart.items.first.codAvailable, isFalse);
      cart.clear();
    });

    test('normalizeWaNumber converts diverse Indonesian phone formats to 628xxx', () {
      expect(normalizeWaNumber('081234567890'), '6281234567890');
      expect(normalizeWaNumber('+6281234567890'), '6281234567890');
      expect(normalizeWaNumber('6281234567890'), '6281234567890');
      expect(normalizeWaNumber('81234567890'), '6281234567890');
      expect(normalizeWaNumber('0812-3456-7890'), '6281234567890');
      expect(normalizeWaNumber(''), '');
    });

    test('generateOrderWhatsAppMessage builds detailed order summary', () {
      final order = Order(
        id: 'PO-TEST-WA',
        refId: 'PO-TEST-WA',
        createdAt: DateTime(2026, 11, 7),
        status: OrderStatus.waitingPayment,
        paymentMethod: PaymentMethod.midtrans,
        serviceFee: 0,
        discount: 0,
        account: const PaymentAccount(bank: 'BRI', bankFullName: '', number: '', holder: ''),
        recipient: const Recipient(
          name: 'Pak Budi',
          phone: '08123456789',
          address: 'Jl. Melati No. 5',
        ),
        vendors: const [
          OrderVendor(
            umkmId: '1',
            umkmName: 'Warung Bu Siti',
            umkmType: 'Jajanan',
            phone: '081987654321',
            type: OrderType.instant,
            delivery: DeliveryMethod.courier,
            deliveryFee: 5000,
            pickupLocation: 'Jl. Kenanga',
            items: [
              OrderItem(
                productId: '10',
                productName: 'Kue Lumpur',
                variant: 'Pandan',
                unit: 'kotak',
                imageUrl: '',
                quantity: 2,
                price: 10000,
              ),
            ],
          ),
        ],
      );

      final msg = generateOrderWhatsAppMessage(order);
      expect(msg, contains('Warung Bu Siti'));
      expect(msg, contains('PO-TEST-WA'));
      expect(msg, contains('Pak Budi'));
      expect(msg, contains('Kue Lumpur'));
      expect(msg, contains('Jl. Melati No. 5'));
      expect(msg, contains('Diantar Kurir Warga'));
    });

    test('Recipient with Kreyongan coordinates stores valid lat/lng and handles out of range correctly', () {
      const recipient = Recipient(
        name: 'Budi Pelanggan',
        phone: '081234567890',
        address: 'Jl. Merpati No. 14, RT 02 / RW 01, Desa Kreyongan Atas',
        latitude: -8.1588,
        longitude: 113.7032,
      );

      expect(recipient.latitude, -8.1588);
      expect(recipient.longitude, 113.7032);

      final inRange = OngkirCalculation.fromJson({
        'id_umkm': '1',
        'nama_umkm': 'Warung Enak',
        'metode_pengiriman': 'kurir',
        'jarak_km': 1.2,
        'biaya_ongkir': 4500,
        'gratis': false,
        'pesan': 'Tarif kurir warga desa (~1.2 km)',
        'di_luar_jangkauan': false,
      });

      expect(inRange.isOutOfRange, isFalse);
      expect(inRange.deliveryFee, 4500.0);
      expect(inRange.distanceKm, 1.2);

      final outOfRange = OngkirCalculation.fromJson({
        'id_umkm': '1',
        'nama_umkm': 'Warung Enak',
        'metode_pengiriman': 'kurir',
        'jarak_km': 25.0,
        'biaya_ongkir': 0,
        'gratis': false,
        'pesan': 'Alamat pengiriman berada di luar jangkauan kurir UMKM (10 km).',
        'di_luar_jangkauan': true,
      });

      expect(outOfRange.isOutOfRange, isTrue);
      expect(outOfRange.message, contains('di luar jangkauan'));
    });

    test('OrderStatus canComplete allows only delivering status', () {
      expect(OrderStatus.delivering.canComplete, isTrue);
      expect(OrderStatus.waitingPayment.canComplete, isFalse);
      expect(OrderStatus.reviewing.canComplete, isFalse);
      expect(OrderStatus.processing.canComplete, isFalse);
      expect(OrderStatus.completed.canComplete, isFalse);
      expect(OrderStatus.cancelled.canComplete, isFalse);
    });

    test('OrderService completeOrder transitions delivering order to completed', () async {
      final service = OrderService();
      final deliveringOrder = Order(
        id: 'PO-TEST-DELIVERING',
        refId: 'PO-TEST-DELIVERING',
        createdAt: DateTime(2026, 11, 7),
        status: OrderStatus.delivering,
        paymentMethod: PaymentMethod.cod,
        serviceFee: 0,
        discount: 0,
        account: const PaymentAccount(bank: 'BRI', bankFullName: '', number: '', holder: ''),
        recipient: const Recipient(
          name: 'Budi Santoso',
          phone: '08123456789',
          address: 'Jl. Desa Kreyongan No. 10',
        ),
        vendors: const [
          OrderVendor(
            umkmId: '1',
            umkmName: 'Warung Enak',
            umkmType: 'Jajanan',
            type: OrderType.instant,
            delivery: DeliveryMethod.courier,
            deliveryFee: 5000,
            pickupLocation: 'Jl. Kreyongan',
            items: [
              OrderItem(
                productId: '1',
                productName: 'Kue Cucur',
                variant: 'Original',
                unit: 'pcs',
                imageUrl: '',
                quantity: 2,
                price: 2500,
              ),
            ],
          ),
        ],
      );

      service.seedOrders([deliveringOrder]);
      expect(deliveringOrder.status, OrderStatus.delivering);
      expect(deliveringOrder.canComplete, isTrue);

      final completed = await service.completeOrder(deliveringOrder.id);
      expect(completed.status, OrderStatus.completed);
      expect(completed.canComplete, isFalse);
    });

    test('ReceiptData formats customer order and generates valid PDF bytes', () async {
      TestWidgetsFlutterBinding.ensureInitialized();

      final order = Order(
        id: 'PO-PDF-TEST',
        refId: 'PO-PDF-TEST',
        createdAt: DateTime(2026, 11, 8, 14, 30),
        status: OrderStatus.completed,
        paymentMethod: PaymentMethod.midtrans,
        serviceFee: 1000,
        discount: 2000,
        account: const PaymentAccount(bank: 'BRI', bankFullName: '', number: '', holder: ''),
        recipient: const Recipient(
          name: 'Pak Budi',
          phone: '081234567890',
          address: 'Jl. Merpati No. 12, Kreyongan Atas',
        ),
        vendors: const [
          OrderVendor(
            umkmId: '1',
            umkmName: 'Warung Bu Siti',
            umkmType: 'Jajanan',
            type: OrderType.instant,
            delivery: DeliveryMethod.courier,
            deliveryFee: 5000,
            pickupLocation: 'Jl. Kreyongan',
            items: [
              OrderItem(
                productId: '10',
                productName: 'Kue Lumpur',
                variant: 'Pandan',
                unit: 'kotak',
                imageUrl: '',
                quantity: 3,
                price: 10000,
              ),
            ],
          ),
        ],
      );

      final data = ReceiptData.fromCustomerOrder(order);
      expect(data.orderId, 'PO-PDF-TEST');
      expect(data.merchantName, 'Warung Bu Siti');
      expect(data.customerName, 'Pak Budi');
      expect(data.items.length, 1);
      expect(data.items.first.total, 30000.0);
      expect(data.subtotal, 30000.0);
      expect(data.total, 34000.0); // 30000 + 5000 + 1000 - 2000

      // Generate PDF bytes
      final pdfBytes = await ReceiptPdfService.generateReceiptPdf(data);
      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.sublist(0, 4), [0x25, 0x50, 0x44, 0x46]); // %PDF
    });

    test('MapNavigationService generates correct Google Maps turn-by-turn navigation URLs', () {
      final dest = const LatLng(-8.1630, 113.7100);
      final origin = const LatLng(-8.1585, 113.7025);

      final uriWithoutOrigin = MapNavigationService.buildGoogleMapsDirUri(destination: dest);
      expect(uriWithoutOrigin.scheme, 'https');
      expect(uriWithoutOrigin.host, 'www.google.com');
      expect(uriWithoutOrigin.path, '/maps/dir/');
      expect(uriWithoutOrigin.queryParameters['destination'], '-8.163,113.71');
      expect(uriWithoutOrigin.queryParameters['travelmode'], 'driving');
      expect(uriWithoutOrigin.queryParameters.containsKey('origin'), isFalse);

      final uriWithOrigin = MapNavigationService.buildGoogleMapsDirUri(
        destination: dest,
        origin: origin,
      );
      expect(uriWithOrigin.queryParameters['origin'], '-8.1585,113.7025');
      expect(uriWithOrigin.queryParameters['destination'], '-8.163,113.71');
    });

    test('MapNavigationService calculates Haversine distance and estimated delivery duration', () {
      final p1 = const LatLng(-8.1585, 113.7025);
      final p2 = const LatLng(-8.1630, 113.7100);

      final dist = MapNavigationService.calculateDistanceKm(p1, p2);
      expect(dist, inInclusiveRange(0.4, 1.0));

      final sameDist = MapNavigationService.calculateDistanceKm(p1, p1);
      expect(sameDist, 0.0);

      final shortDuration = MapNavigationService.estimateDeliveryMinutes(0.1);
      expect(shortDuration, 5); // 5 min buffer

      final travelDuration = MapNavigationService.estimateDeliveryMinutes(dist);
      expect(travelDuration, inInclusiveRange(5, 10));
    });

    test('Order and Pesanan models parse navigation coordinates from JSON', () {
      final customerJson = {
        'id_pesanan': 'ORD-MAP-TEST',
        'nama_pembeli': 'Rina Pembeli',
        'no_telp': '081234567891',
        'alamat_tujuan': 'Jl. Teratai No. 12',
        'catatan_alamat': 'Pagar hitam samping pos',
        'latitude_tujuan': -8.1620,
        'longitude_tujuan': 113.7080,
        'id_umkm': '1',
        'nama_umkm': 'Dapur Kreyongan',
        'alamat_umkm': 'Jl. Kreyongan Atas',
        'latitude_umkm': -8.1585,
        'longitude_umkm': 113.7025,
        'metode_pengiriman': 'kurir',
        'jarak_km': 1.1,
      };

      final order = Order.fromJson(customerJson);
      expect(order.recipient.latitude, -8.1620);
      expect(order.recipient.longitude, 113.7080);
      expect(order.recipient.addressNote, 'Pagar hitam samping pos');
      expect(order.vendors.first.latitude, -8.1585);
      expect(order.vendors.first.longitude, 113.7025);
      expect(order.vendors.first.distanceKm, 1.1);

      final umkmJson = {
        'id_pesanan': 'ORD-MAP-TEST',
        'nama_pembeli': 'Rina Pembeli',
        'no_telp': '081234567891',
        'alamat_tujuan': 'Jl. Teratai No. 12',
        'catatan': 'Pagar hitam',
        'metode_pengiriman': 'kurir',
        'status_pesanan': 'diantar',
        'status_pembayaran': 'bayar_di_tempat',
        'latitude_tujuan': -8.1620,
        'longitude_tujuan': 113.7080,
        'latitude_umkm': -8.1585,
        'longitude_umkm': 113.7025,
        'jarak_km': 1.1,
      };

      final pesanan = umkm_models.Pesanan.fromJson(umkmJson);
      expect(pesanan.latitudeTujuan, -8.1620);
      expect(pesanan.longitudeTujuan, 113.7080);
      expect(pesanan.latitudeUmkm, -8.1585);
      expect(pesanan.longitudeUmkm, 113.7025);
      expect(pesanan.jarakKm, 1.1);
    });
  });
}
