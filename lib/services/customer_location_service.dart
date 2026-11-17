import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class DeviceLocationException implements Exception {
  final String message;

  const DeviceLocationException(this.message);

  @override
  String toString() => message;
}

class CustomerLocationService {
  static Future<Position> getCurrentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const DeviceLocationException(
        'Layanan lokasi perangkat tidak aktif. Aktifkan GPS, atau pilih alamat secara manual.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw const DeviceLocationException(
        'Izin lokasi ditolak permanen. Aktifkan izin lokasi di pengaturan browser atau perangkat.',
      );
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.unableToDetermine) {
      throw const DeviceLocationException(
        'Izin lokasi tidak diberikan. Anda tetap bisa memilih alamat secara manual.',
      );
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } on LocationServiceDisabledException {
      throw const DeviceLocationException(
        'Layanan lokasi perangkat tidak aktif. Aktifkan GPS, atau pilih alamat secara manual.',
      );
    } on PermissionDeniedException {
      throw const DeviceLocationException(
        'Izin lokasi tidak diberikan. Anda tetap bisa memilih alamat secara manual.',
      );
    }
  }

  static Future<String> reverseGeocode(LatLng location) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'lat': location.latitude.toString(),
      'lon': location.longitude.toString(),
      'format': 'jsonv2',
      'addressdetails': '1',
      'accept-language': 'id',
    });
    final response = await http
        .get(uri, headers: const {'User-Agent': 'DjajanMobile/1.0'})
        .timeout(const Duration(seconds: 8));

    if (response.statusCode != 200) {
      throw const FormatException('Layanan pencarian alamat sedang bermasalah.');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Format alamat dari layanan peta tidak valid.');
    }

    final rawAddress = decoded['address'];
    if (rawAddress is Map) {
      final address = Map<String, dynamic>.from(rawAddress);
      String firstOf(List<String> keys) {
        for (final key in keys) {
          final value = address[key]?.toString().trim();
          if (value != null && value.isNotEmpty) return value;
        }
        return '';
      }

      final parts = <String>[
        [
          firstOf(['house_number']),
          firstOf(['road', 'pedestrian', 'residential', 'footway']),
        ].where((part) => part.isNotEmpty).join(' '),
        firstOf(['neighbourhood', 'quarter', 'suburb', 'village', 'hamlet']),
        firstOf([
          'city_district',
          'state_district',
          'district',
          'county',
          'municipality',
        ]),
        firstOf(['city', 'town']),
        firstOf(['state']),
        firstOf(['postcode']),
        firstOf(['country']),
      ].where((part) => part.isNotEmpty).toList();

      final uniqueParts = <String>[];
      for (final part in parts) {
        if (!uniqueParts.any((existing) =>
            existing.toLowerCase() == part.toLowerCase())) {
          uniqueParts.add(part);
        }
      }
      if (uniqueParts.isNotEmpty) return uniqueParts.join(', ');
    }

    final displayName = decoded['display_name']?.toString().trim() ?? '';
    if (displayName.isEmpty) {
      throw const FormatException('Alamat untuk titik ini tidak ditemukan.');
    }
    return displayName;
  }
}
