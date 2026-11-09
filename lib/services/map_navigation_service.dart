import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

/// Service untuk menangani navigasi peta eksternal (Google Maps / Waze)
/// dan kalkulasi rute hyperlocal untuk kurir warga dan pelanggan DJajan.
class MapNavigationService {
  MapNavigationService._();

  /// Titik default pusat Desa Kreyongan Atas, Patrang, Jember (-8.1585, 113.7025)
  static const LatLng defaultKreyonganCenter = LatLng(-8.1585, 113.7025);

  /// Titik estimasi pemukiman pelanggan di sekitar Desa Kreyongan Atas
  static const LatLng defaultCustomerLocation = LatLng(-8.1630, 113.7100);

  /// Menghasilkan URL navigasi Google Maps turn-by-turn.
  /// Jika [origin] tidak diisi, Google Maps akan menggunakan lokasi GPS kurir saat ini.
  static Uri buildGoogleMapsDirUri({
    required LatLng destination,
    LatLng? origin,
    String mode = 'driving',
  }) {
    final params = <String, String>{
      'api': '1',
      'destination': '${destination.latitude},${destination.longitude}',
      'travelmode': mode,
    };

    if (origin != null) {
      params['origin'] = '${origin.latitude},${origin.longitude}';
    }

    return Uri.https('www.google.com', '/maps/dir/', params);
  }

  /// Menghasilkan URL pencarian titik koordinat di Google Maps.
  static Uri buildGoogleMapsSearchUri(LatLng location, {String? label}) {
    final query = label != null && label.isNotEmpty
        ? '${location.latitude},${location.longitude}($label)'
        : '${location.latitude},${location.longitude}';
    return Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': query,
    });
  }

  /// Membuka aplikasi Google Maps (atau browser jika app belum terinstall)
  /// dengan rute navigasi dari UMKM menuju alamat pembeli.
  static Future<bool> openTurnByTurnNavigation(
    BuildContext context, {
    required LatLng destination,
    LatLng? origin,
    String? destinationLabel,
  }) async {
    final uri = buildGoogleMapsDirUri(
      destination: destination,
      origin: origin,
    );

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (launched) return true;

      // Fallback ke browser platform default
      return await launchUrl(uri, mode: LaunchMode.platformDefault);
    } catch (_) {
      // Fallback intent Android 'geo:' jika http diblokir
      final geoUri = Uri.parse(
        'geo:${destination.latitude},${destination.longitude}?q=${destination.latitude},${destination.longitude}${destinationLabel != null ? "($destinationLabel)" : ""}',
      );
      try {
        return await launchUrl(geoUri, mode: LaunchMode.externalApplication);
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tidak dapat membuka aplikasi peta navigasi.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return false;
      }
    }
  }

  /// Membuka satu titik lokasi di Google Maps.
  static Future<bool> openLocation(
    BuildContext context, {
    required LatLng location,
    String? label,
  }) async {
    final uri = buildGoogleMapsSearchUri(location, label: label);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (launched) return true;
      return await launchUrl(uri, mode: LaunchMode.platformDefault);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak dapat membuka aplikasi peta.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  /// Menghitung jarak lurus (Haversine) dalam kilometer.
  static double calculateDistanceKm(LatLng a, LatLng b) {
    const earthRadiusKm = 6371.0;
    final dLat = _degToRad(b.latitude - a.latitude);
    final dLon = _degToRad(b.longitude - a.longitude);

    final lat1 = _degToRad(a.latitude);
    final lat2 = _degToRad(b.latitude);

    final sinDLat = math.sin(dLat / 2);
    final sinDLon = math.sin(dLon / 2);

    final h = sinDLat * sinDLat +
        math.sin(lat1) * math.sin(lat2) * sinDLon * sinDLon;
    final c = 2 * math.asin(math.sqrt(h.clamp(0.0, 1.0)));

    return double.parse((earthRadiusKm * c).toStringAsFixed(2));
  }

  /// Estimasi durasi pengantaran kurir motor desa dalam menit:
  /// Asumsi kecepatan motor rata-rata di jalan desa 22 km/jam + 5 menit buffer penyerahan.
  static int estimateDeliveryMinutes(double distanceKm) {
    if (distanceKm <= 0.2) return 5;
    final travelMinutes = (distanceKm / 22.0 * 60.0).round();
    return (travelMinutes + 5).clamp(5, 60);
  }

  static double _degToRad(double deg) => deg * (math.pi / 180.0);
}

