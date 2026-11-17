import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../services/customer_location_service.dart';
import '../screens/auth/customer/order/order_widgets.dart';

/// Hasil yang dikembalikan oleh [OsmMapPicker].
class OsmPickerResult {
  final double latitude;
  final double longitude;

  /// Nama/alamat lokasi hasil reverse geocoding (mungkin kosong jika gagal).
  final String alamatTeks;

  const OsmPickerResult({
    required this.latitude,
    required this.longitude,
    this.alamatTeks = '',
  });
}

/// Widget map picker fullscreen menggunakan OpenStreetMap via flutter_map.
///
/// Cara pakai:
/// ```dart
/// final result = await Navigator.push<OsmPickerResult>(
///   context,
///   MaterialPageRoute(builder: (_) => OsmMapPicker(
///     initialLatLng: LatLng(-7.9, 113.3),
///   )),
/// );
/// ```
///
/// Atau via bottom sheet:
/// ```dart
/// final result = await showOsmMapPicker(context);
/// ```
class OsmMapPicker extends StatefulWidget {
  /// Koordinat awal saat peta dibuka. Jika null, peta akan minta GPS device.
  final LatLng? initialLatLng;

  /// Label tombol konfirmasi (default: 'Pilih Lokasi Ini').
  final String confirmLabel;

  const OsmMapPicker({
    super.key,
    this.initialLatLng,
    this.confirmLabel = 'Pilih Lokasi Ini',
  });

  @override
  State<OsmMapPicker> createState() => _OsmMapPickerState();
}

class _OsmMapPickerState extends State<OsmMapPicker> {
  static const _defaultCenter = LatLng(-2.5, 118.0);
  static const _defaultZoom = 4.5;
  static const _searchZoom = 16.0;

  late final MapController _mapController;
  late LatLng _pinCenter;

  bool _loading = false;
  String? _locationError;
  String _alamatTeks = '';
  String _searchQuery = '';
  String? _searchError;
  bool _searchLoading = false;
  List<Map<String, dynamic>> _searchResults = [];
  bool _showSearch = false;
  Timer? _reverseGeocodeTimer;
  int _reverseGeocodeRequest = 0;

  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _pinCenter = widget.initialLatLng ?? _defaultCenter;
    if (widget.initialLatLng == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _getDeviceLocation());
    } else {
      _reverseGeocode(_pinCenter);
    }
  }

  @override
  void dispose() {
    _reverseGeocodeTimer?.cancel();
    _mapController.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // ------------------------------------------------- GPS device
  Future<void> _getDeviceLocation() async {
    setState(() => _loading = true);
    try {
      final pos = await CustomerLocationService.getCurrentPosition();
      if (!mounted) return;
      final latLng = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _pinCenter = latLng;
        _locationError = null;
      });
      _mapController.move(latLng, _defaultZoom);
      await _reverseGeocode(latLng);
    } on DeviceLocationException catch (error) {
      if (mounted) setState(() => _locationError = error.message);
    } catch (_) {
      if (mounted) {
        setState(() {
          _locationError =
              'Lokasi tidak dapat diakses. Cari alamat atau pilih titik secara manual.';
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ------------------------------------------------- reverse geocoding
  Future<void> _reverseGeocode(LatLng pos) async {
    final requestId = ++_reverseGeocodeRequest;
    try {
      final address = await CustomerLocationService.reverseGeocode(pos);
      if (!mounted || requestId != _reverseGeocodeRequest) return;
      setState(() {
        _alamatTeks = address;
        _locationError = null;
      });
    } catch (_) {
      if (mounted && requestId == _reverseGeocodeRequest) {
        setState(() {
          _alamatTeks = '';
          _locationError =
              'Alamat tidak ditemukan. Anda tetap bisa menggeser peta dan mengisi alamat secara manual.';
        });
      }
    }
  }

  // ------------------------------------------------- Nominatim search
  Future<void> _searchAlamat(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _searchLoading = true);
    _searchError = null;
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': query,
        'format': 'jsonv2',
        'limit': '6',
        'accept-language': 'id',
      });
      final res = await http.get(uri, headers: {
        'User-Agent': 'DjajanMobile/1.0',
      }).timeout(const Duration(seconds: 8));
      if (!mounted) return;
      if (res.statusCode == 200) {
        final list = json.decode(res.body) as List<dynamic>;
        setState(() {
          _searchResults =
              list.map((e) => e as Map<String, dynamic>).toList();
        });
      } else {
        setState(() => _searchError = 'Pencarian alamat sedang bermasalah.');
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _searchError =
              'Gagal mencari alamat. Periksa koneksi, atau pilih titik langsung di peta.';
        });
      }
    } finally {
      if (mounted) setState(() => _searchLoading = false);
    }
  }

  void _selectSearchResult(Map<String, dynamic> result) {
    final lat = double.tryParse(result['lat']?.toString() ?? '');
    final lon = double.tryParse(result['lon']?.toString() ?? '');
    if (lat == null || lon == null) return;
    _reverseGeocodeRequest++;
    _reverseGeocodeTimer?.cancel();
    final latLng = LatLng(lat, lon);
    setState(() {
      _pinCenter = latLng;
      _alamatTeks = result['display_name']?.toString() ?? '';
      _locationError = null;
      _searchResults = [];
      _showSearch = false;
    });
    _searchCtrl.clear();
    _searchFocus.unfocus();
    _mapController.move(latLng, _searchZoom);
  }

  void _onMapEvent(MapEvent event) {
    if (event is MapEventMoveEnd || event is MapEventScrollWheelZoom) {
      final center = _mapController.camera.center;
      if (_pinCenter != center) {
        _reverseGeocodeRequest++;
        _reverseGeocodeTimer?.cancel();
        setState(() {
          _pinCenter = center;
          _alamatTeks = '';
          _locationError = null;
        });
        _reverseGeocodeTimer = Timer(
          const Duration(milliseconds: 900),
          () => _reverseGeocode(center),
        );
      }
    }
  }

  Future<void> _confirm() async {
    var alamat = _alamatTeks.trim();
    if (alamat.isEmpty) {
      setState(() => _loading = true);
      try {
        alamat = await CustomerLocationService.reverseGeocode(_pinCenter);
      } catch (_) {
        if (mounted) {
          setState(() {
            _locationError =
                'Alamat tidak ditemukan. Lengkapi alamat secara manual setelah memilih titik.';
          });
        }
      }
      if (mounted) setState(() => _loading = false);
    }

    if (!mounted) return;
    Navigator.of(context).pop(OsmPickerResult(
      latitude: _pinCenter.latitude,
      longitude: _pinCenter.longitude,
      alamatTeks: alamat,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ---- Peta ----
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _pinCenter,
              initialZoom: _defaultZoom,
              onMapEvent: _onMapEvent,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.djajan.mobile',
                maxZoom: 19,
              ),
              // Atribusi OSM wajib sesuai lisensi ODbL
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    '© OpenStreetMap contributors',
                    onTap: null,
                  ),
                ],
              ),
            ],
          ),

          // ---- Pin tengah ----
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_on, color: OC.primary, size: 46),
                SizedBox(height: 42), // offset titik pin ada di bawah icon
              ],
            ),
          ),

          // ---- Loading overlay GPS ----
          if (_loading)
            Container(
              color: Colors.black38,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text('Mendapatkan lokasi GPS...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // ---- App bar + search ----
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                if (_showSearch) _buildSearchPanel(),
              ],
            ),
          ),

          // ---- Bottom bar: alamat + konfirmasi ----
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: _buildBottomBar(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).maybePop(),
            tooltip: 'Kembali',
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _showSearch = !_showSearch);
                if (_showSearch) {
                  Future.microtask(() => _searchFocus.requestFocus());
                }
              },
              child: Text(
                _showSearch ? 'Cari alamat...' : 'Pilih lokasi di peta',
                style: TextStyle(
                  color: _showSearch ? OC.primary : OC.muted,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              _showSearch ? Icons.close : Icons.search,
              color: OC.primary,
            ),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchCtrl.clear();
                  _searchResults = [];
                }
              });
              if (_showSearch) {
                Future.microtask(() => _searchFocus.requestFocus());
              }
            },
            tooltip: _showSearch ? 'Tutup pencarian' : 'Cari alamat',
          ),
          IconButton(
            icon: const Icon(Icons.my_location, color: OC.primary),
            onPressed: _loading ? null : _getDeviceLocation,
            tooltip: 'Gunakan lokasi saya',
          ),
        ],
      ),
    );
  }

  Widget _buildSearchPanel() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            focusNode: _searchFocus,
            decoration: InputDecoration(
              hintText: 'Cari nama jalan, desa, kecamatan...',
              prefixIcon: const Icon(Icons.search, color: OC.muted),
              suffixIcon: _searchLoading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
            ),
            onChanged: (q) {
              _searchQuery = q;
              Future.delayed(const Duration(milliseconds: 600), () {
                if (_searchQuery == q) _searchAlamat(q);
              });
            },
            onSubmitted: _searchAlamat,
          ),
          if (_searchResults.isNotEmpty)
            const Divider(height: 1),
          if (_searchError != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              child: Text(
                _searchError!,
                style: const TextStyle(fontSize: 12, color: OC.muted),
              ),
            ),
          ..._searchResults.map(
            (r) => ListTile(
              dense: true,
              leading: const Icon(Icons.place_outlined, color: OC.primary),
              title: Text(
                r['display_name']?.toString() ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
              onTap: () => _selectSearchResult(r),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 14,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on, color: OC.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _alamatTeks.isNotEmpty
                          ? _alamatTeks
                          : 'Geser peta untuk memilih lokasi...',
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            _alamatTeks.isNotEmpty ? OC.ink : OC.muted,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_locationError != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _locationError!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF9A6700),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      '${_pinCenter.latitude.toStringAsFixed(6)}, '
                      '${_pinCenter.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: OC.muted,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _confirm,
            icon: const Icon(Icons.check_circle_outline),
            label: Text(widget.confirmLabel),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper — buka map picker sebagai halaman fullscreen.
/// Mengembalikan [OsmPickerResult] atau null jika user batal.
Future<OsmPickerResult?> showOsmMapPicker(
  BuildContext context, {
  LatLng? initialLatLng,
  String confirmLabel = 'Pilih Lokasi Ini',
}) {
  return Navigator.of(context).push<OsmPickerResult>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => OsmMapPicker(
        initialLatLng: initialLatLng,
        confirmLabel: confirmLabel,
      ),
    ),
  );
}

