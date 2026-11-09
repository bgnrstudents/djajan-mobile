import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../screens/customer/order/order_widgets.dart';
import '../services/map_navigation_service.dart';

/// Kartu visualisasi peta dan navigasi pengantaran kurir warga DJajan (OpenStreetMap & Google Maps).
/// Digunakan di sisi Pelanggan (Item A.5) maupun sisi UMKM / Kurir (Item B.4).
class OrderDeliveryMapCard extends StatefulWidget {
  final LatLng origin;
  final LatLng destination;
  final String originLabel;
  final String destinationLabel;
  final String recipientAddress;
  final String? recipientNote;
  final double? distanceKm;
  final bool isDelivering;
  final bool isUmkmView;
  final String? contactPhone;
  final String? orderId;

  const OrderDeliveryMapCard({
    super.key,
    required this.origin,
    required this.destination,
    this.originLabel = 'Dapur UMKM',
    this.destinationLabel = 'Lokasi Penerima',
    required this.recipientAddress,
    this.recipientNote,
    this.distanceKm,
    this.isDelivering = false,
    this.isUmkmView = false,
    this.contactPhone,
    this.orderId,
  });

  @override
  State<OrderDeliveryMapCard> createState() => _OrderDeliveryMapCardState();
}

class _OrderDeliveryMapCardState extends State<OrderDeliveryMapCard> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  LatLng get _midpoint {
    return LatLng(
      (widget.origin.latitude + widget.destination.latitude) / 2,
      (widget.origin.longitude + widget.destination.longitude) / 2,
    );
  }

  double get _effectiveDistance {
    if (widget.distanceKm != null && widget.distanceKm! > 0) {
      return widget.distanceKm!;
    }
    return MapNavigationService.calculateDistanceKm(
      widget.origin,
      widget.destination,
    );
  }

  double get _initialZoom {
    final dist = _effectiveDistance;
    if (dist <= 1.0) return 15.0;
    if (dist <= 3.0) return 14.0;
    if (dist <= 7.0) return 13.0;
    return 12.0;
  }

  @override
  Widget build(BuildContext context) {
    final dist = _effectiveDistance;
    final estimatedMinutes = MapNavigationService.estimateDeliveryMinutes(dist);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isDelivering
              ? OC.primary.withValues(alpha: 0.35)
              : OC.line,
          width: widget.isDelivering ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header info
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: widget.isDelivering
                        ? OC.primary.withValues(alpha: 0.12)
                        : const Color(0xFFF2F4F7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.two_wheeler_rounded,
                    color: widget.isDelivering ? OC.primary : OC.ink,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isUmkmView
                            ? 'Rute Pengantaran Kurir'
                            : 'Pelacakan Pengantaran',
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: OC.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Jarak ~$dist km • Estimasi ~$estimatedMinutes mnt',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: OC.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.isDelivering
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.isDelivering
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFFEF6C00),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        widget.isDelivering ? 'Sedang OTW' : 'Kurir Warga',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: widget.isDelivering
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFFEF6C00),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Peta OpenStreetMap (flutter_map)
          Container(
            height: 180,
            margin: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: OC.line),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _midpoint,
                    initialZoom: _initialZoom,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.djajan.mobile',
                      maxZoom: 19,
                    ),
                    // Garis rute pengantaran
                    PolylineLayer(
                      polylines: [
                        // Casing garis
                        Polyline(
                          points: [widget.origin, widget.destination],
                          strokeWidth: 6.0,
                          color: Colors.black26,
                        ),
                        // Garis utama rute
                        Polyline(
                          points: [widget.origin, widget.destination],
                          strokeWidth: 4.0,
                          color: OC.primary,
                        ),
                      ],
                    ),
                    // Marker UMKM & Pembeli
                    MarkerLayer(
                      markers: [
                        // Pin Toko UMKM
                        Marker(
                          point: widget.origin,
                          width: 42,
                          height: 42,
                          child: _buildMapPin(
                            icon: Icons.storefront_rounded,
                            bgColor: const Color(0xFFF57C00),
                            label: 'UMKM',
                          ),
                        ),
                        // Pin Rumah Pembeli
                        Marker(
                          point: widget.destination,
                          width: 42,
                          height: 42,
                          child: _buildMapPin(
                            icon: Icons.home_rounded,
                            bgColor: OC.primary,
                            label: 'Tujuan',
                          ),
                        ),
                      ],
                    ),
                    const RichAttributionWidget(
                      attributions: [
                        TextSourceAttribution(
                          '© OpenStreetMap',
                          onTap: null,
                        ),
                      ],
                    ),
                  ],
                ),

                // Tombol reset view / center
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: Colors.white,
                    elevation: 2,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        _mapController.move(_midpoint, _initialZoom);
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(
                          Icons.crop_free_rounded,
                          size: 18,
                          color: OC.ink,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Detail Alamat & Patokan
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: OC.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.place_outlined,
                        size: 16,
                        color: OC.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.recipientAddress.trim().isNotEmpty
                              ? widget.recipientAddress
                              : 'Alamat tujuan Desa Kreyongan Atas',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: OC.ink,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (widget.recipientNote != null &&
                      widget.recipientNote!.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 15,
                          color: OC.amber,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Patokan: ${widget.recipientNote}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: OC.muted,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Tombol Aksi
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: OC.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      MapNavigationService.openTurnByTurnNavigation(
                        context,
                        destination: widget.destination,
                        origin: widget.origin,
                        destinationLabel: widget.destinationLabel,
                      );
                    },
                    icon: const Icon(
                      Icons.near_me_rounded,
                      size: 18,
                    ),
                    label: Text(
                      widget.isUmkmView
                          ? 'Mulai Navigasi Google Maps'
                          : 'Buka Rute di Google Maps',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                if (widget.contactPhone != null &&
                    widget.contactPhone!.trim().isNotEmpty) ...[
                  const SizedBox(width: 8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF25D366),
                      side: const BorderSide(color: Color(0xFF25D366)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      final pesan = widget.isUmkmView
                          ? 'Halo Kak, kurir DJajan sedang mengantar pesanan *${widget.orderId ?? ""}* ke alamatmu.'
                          : 'Halo, saya ingin menanyakan pengantaran pesanan *${widget.orderId ?? ""}*.';
                      openWhatsApp(
                        context,
                        phone: widget.contactPhone!,
                        message: pesan,
                      );
                    },
                    child: const Icon(
                      Icons.chat_bubble_outline,
                      size: 18,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPin({
    required IconData icon,
    required Color bgColor,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 17),
        ),
      ],
    );
  }
}

