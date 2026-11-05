  import 'package:flutter_test/flutter_test.dart';
import 'package:djajan_mobile/models/order.dart';

void main() {
  group('OngkirCalculation Model Test', () {
    test('fromJson parses standard zone ongkir response correctly', () {
      final json = {
        'id_umkm': 10,
        'nama_umkm': 'Dapur Berkah',
        'metode_pengiriman': 'kurir',
        'jarak_km': 2.75,
        'biaya_ongkir': 5000,
        'gratis': false,
        'zona_ongkir_id': 3,
        'pesan': 'Tarif zona (1.0 - 3.0 km)',
        'di_luar_jangkauan': false,
      };

      final calc = OngkirCalculation.fromJson(json);

      expect(calc.umkmId, 10);
      expect(calc.umkmName, 'Dapur Berkah');
      expect(calc.deliveryMethod, 'kurir');
      expect(calc.distanceKm, 2.75);
      expect(calc.deliveryFee, 5000.0);
      expect(calc.isFree, isFalse);
      expect(calc.zoneId, 3);
      expect(calc.isOutOfRange, isFalse);
    });

    test('fromJson handles free radius correctly', () {
      final json = {
        'id_umkm': 10,
        'nama_umkm': 'Dapur Berkah',
        'metode_pengiriman': 'kurir',
        'jarak_km': 0.8,
        'biaya_ongkir': 0,
        'gratis': true,
        'zona_ongkir_id': null,
        'pesan': 'Gratis ongkir (radius 1 km)',
        'di_luar_jangkauan': false,
      };

      final calc = OngkirCalculation.fromJson(json);

      expect(calc.deliveryFee, 0.0);
      expect(calc.isFree, isTrue);
      expect(calc.distanceKm, 0.8);
      expect(calc.isOutOfRange, isFalse);
    });

    test('fromJson handles pickup mode correctly', () {
      final json = {
        'id_umkm': 10,
        'nama_umkm': 'Dapur Berkah',
        'metode_pengiriman': 'pickup',
        'jarak_km': null,
        'biaya_ongkir': 0,
        'gratis': true,
        'zona_ongkir_id': null,
        'pesan': 'Ambil sendiri di toko (Gratis)',
        'di_luar_jangkauan': false,
      };

      final calc = OngkirCalculation.fromJson(json);

      expect(calc.deliveryFee, 0.0);
      expect(calc.isFree, isTrue);
      expect(calc.distanceKm, isNull);
      expect(calc.isOutOfRange, isFalse);
    });

    test('fromJson handles out of range correctly', () {
      final json = {
        'id_umkm': 10,
        'nama_umkm': 'Dapur Berkah',
        'metode_pengiriman': 'kurir',
        'jarak_km': null,
        'biaya_ongkir': 0,
        'gratis': false,
        'pesan': 'Alamat pengiriman berada di luar jangkauan kurir UMKM (10 km).',
        'di_luar_jangkauan': true,
      };

      final calc = OngkirCalculation.fromJson(json);

      expect(calc.isOutOfRange, isTrue);
      expect(calc.message, contains('di luar jangkauan'));
    });
  });

  group('Order Model distance snapshot test', () {
    test('Order.fromJson correctly parses jarak_km', () {
      final json = {
        'id_pesanan': 'PO-20261105-ABC123',
        'id_umkm': 5,
        'nama_umkm': 'Warung Soto',
        'metode_pengiriman': 'kurir',
        'biaya_pengantaran': 6000,
        'jarak_km': 3.45,
        'biaya_layanan': 0,
        'total_harga': 36000,
        'status_pesanan': 'po_baru',
        'items': [],
      };

      final order = Order.fromJson(json);
      expect(order.vendors.first.distanceKm, 3.45);
      expect(order.vendors.first.deliveryFee, 6000.0);
    });
  });
}

