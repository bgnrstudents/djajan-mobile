import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../routes/app_routes.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';
import '../../services/umkm_data_service.dart';
import '../../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  final Duration minimumDisplayDuration;

  const SplashScreen({
    super.key,
    this.minimumDisplayDuration = const Duration(seconds: 4),
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const _tips = [
    _SplashTip(
      title: 'Belanja dekat, dampak nyata',
      description: 'Temukan berbagai produk UMKM lokal di sekitar Anda.',
    ),
    _SplashTip(
      title: 'Bantu usaha desa berkembang',
      description: 'Setiap pesanan mendukung pelaku usaha di lingkungan Anda.',
    ),
    _SplashTip(
      title: 'Pesan jadi lebih mudah',
      description: 'Pilih makanan dan minuman favorit langsung melalui Djajan.',
    ),
    _SplashTip(
      title: 'Kenali produk unggulan sekitar',
      description: 'Jelajahi warung dan produk pilihan Desa Kreongan Atas.',
    ),
    _SplashTip(
      title: 'Pilihan lokal, manfaat bersama',
      description: 'Belanja praktis sambil menggerakkan ekonomi desa.',
    ),
  ];

  static const _illustrationIcons = [
    Icons.storefront_rounded,
    Icons.shopping_basket_rounded,
    Icons.local_cafe_rounded,
    Icons.restaurant_rounded,
    Icons.eco_rounded,
  ];

  late final AnimationController _entranceController;
  late final AnimationController _ambientController;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  Timer? _tipTimer;
  Timer? _illustrationTimer;

  int _tipIndex = 0;
  int _illustrationIndex = 0;
  String _statusMessage = 'Menyiapkan Djajan untuk Anda...';
  String? _errorMessage;
  String _errorTitle = 'Koneksi belum tersedia';
  bool _isLoading = false;
  bool _navigationStarted = false;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
    _logoFade = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );
    _logoScale = Tween<double>(begin: 0.78, end: 1).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutBack),
    );

    _tipTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted && !_navigationStarted) {
        setState(() => _tipIndex = (_tipIndex + 1) % _tips.length);
      }
    });
    _illustrationTimer = Timer.periodic(const Duration(milliseconds: 3200), (
      _,
    ) {
      if (mounted && !_navigationStarted) {
        setState(
          () => _illustrationIndex =
              (_illustrationIndex + 1) % _illustrationIcons.length,
        );
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _restoreSession();
    });
  }

  Future<void> _restoreSession() async {
    if (_isLoading || _navigationStarted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _statusMessage = 'Menyiapkan Djajan untuk Anda...';
    });

    final startedAt = DateTime.now();

    try {
      final session = await context.read<AuthService>().restoreSession();
      if (!mounted) return;

      if (session != null) {
        if (session.role == AuthRole.umkm) {
          context.read<UmkmDataService>().loadProfileFromLogin(session.data);
          setState(() => _statusMessage = 'Menyiapkan halaman usaha...');
        } else {
          setState(() => _statusMessage = 'Membuka etalase UMKM...');
          // Muat riwayat pesanan di latar belakang agar tidak menahan masuk beranda.
          unawaited(
            context.read<OrderService>().loadFromApi().catchError((_) {}),
          );
        }
      }

      final remaining =
          widget.minimumDisplayDuration - DateTime.now().difference(startedAt);
      if (remaining > Duration.zero) {
        await Future<void>.delayed(remaining);
      }
      if (!mounted) return;
      _openApp(session);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorTitle = 'Belum dapat terhubung';
        _errorMessage = error.pesan;
      });
    }
  }

  void _openApp(AuthSession? session) {
    if (!mounted || _navigationStarted) return;
    _navigationStarted = true;
    Navigator.pushReplacementNamed(
      context,
      session == null
          ? AppRoutes.customerHome
          : session.role == AuthRole.umkm
          ? AppRoutes.umkmDashboard
          : AppRoutes.customerHome,
    );
  }

  @override
  void dispose() {
    _tipTimer?.cancel();
    _illustrationTimer?.cancel();
    _entranceController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.latar,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxHeight <= 0 || constraints.maxWidth <= 0) {
              return const SizedBox.shrink();
            }
            final compact = constraints.maxHeight < 700;
            final minContentHeight = math.max(
              0.0,
              constraints.maxHeight - (compact ? 22.0 : 38.0),
            );
            return Stack(
              fit: StackFit.expand,
              children: [
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFF9FCF9), Color(0xFFEDF5EF)],
                    ),
                  ),
                ),
                Positioned(
                  top: -105,
                  right: -85,
                  child: _AmbientCircle(
                    size: 245,
                    color: const Color(0xFFB9DCC0).withValues(alpha: 0.2),
                  ),
                ),
                Positioned(
                  left: -105,
                  bottom: 60,
                  child: _AmbientCircle(
                    size: 210,
                    color: const Color(0xFFF4D98B).withValues(alpha: 0.12),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: -34,
                  height: compact ? 150 : 190,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: 0.1,
                      child: Image.asset(
                        'assets/images/javanese_village_background.png',
                        fit: BoxFit.cover,
                        alignment: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    22,
                    compact ? 10 : 18,
                    22,
                    compact ? 12 : 20,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: minContentHeight,
                    ),
                    child: Column(
                      children: [
                        _buildBrandPill(),
                        const Spacer(flex: 2),
                        _buildBrandStage(compact),
                        SizedBox(height: compact ? 8 : 18),
                        _buildInfoCard(compact),
                        const Spacer(flex: 2),
                        _buildLoadingArea(),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBrandPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        border: Border.all(color: AppColors.garis),
        borderRadius: BorderRadius.circular(30),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.eco_rounded, color: AppColors.hijauTua, size: 15),
          SizedBox(width: 7),
          Text(
            'DARI DESA, UNTUK SEMUA',
            style: TextStyle(
              color: AppColors.hijauTua,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandStage(bool compact) {
    return SizedBox(
      height: compact ? 196 : 236,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: compact ? 168 : 190,
            height: compact ? 168 : 190,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [Color(0xFFFFFFFF), Color(0xFFDCEEE0)],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.hijauTua.withValues(alpha: 0.08),
                  blurRadius: 35,
                  spreadRadius: 4,
                ),
              ],
            ),
          ),
          _floatingBadge(
            icon: Icons.storefront_rounded,
            color: AppColors.hijauTua,
            background: const Color(0xFFE6F2E8),
            left: 12,
            top: 28,
            phase: 0,
          ),
          _floatingBadge(
            icon: Icons.wb_sunny_rounded,
            color: const Color(0xFFD89A00),
            background: const Color(0xFFFFF3CE),
            right: 16,
            top: 24,
            phase: 1.4,
          ),
          _floatingBadge(
            icon: Icons.eco_rounded,
            color: const Color(0xFF5B9E68),
            background: const Color(0xFFE8F3E9),
            left: 24,
            bottom: 22,
            phase: 2.5,
          ),
          _floatingBadge(
            icon: Icons.shopping_basket_rounded,
            color: const Color(0xFFB77D17),
            background: const Color(0xFFFFF5DB),
            right: 12,
            bottom: 18,
            phase: 3.5,
          ),
          AnimatedBuilder(
            animation: _ambientController,
            builder: (context, child) {
              final offset = math.sin(_ambientController.value * math.pi) * 3;
              return Transform.translate(
                offset: Offset(0, -offset),
                child: FadeTransition(
                  opacity: _logoFade,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: child,
                  ),
                ),
              );
            },
            child: Image.asset(
              'assets/images/logoNoBg.png',
              width: compact ? 166 : 190,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }

  Widget _floatingBadge({
    required IconData icon,
    required Color color,
    required Color background,
    required double phase,
    double? left,
    double? right,
    double? top,
    double? bottom,
  }) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: AnimatedBuilder(
        animation: _ambientController,
        builder: (context, child) {
          final wave = math.sin(
            _ambientController.value * math.pi * 2 + phase,
          );
          return Transform.translate(
            offset: Offset(0, wave * 4),
            child: Transform.rotate(
              angle: wave * 0.035,
              child: child,
            ),
          );
        },
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.hijauTua.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }

  Widget _buildInfoCard(bool compact) {
    final tip = _tips[_tipIndex];
    final icon = _illustrationIcons[_illustrationIndex];
    return Container(
      constraints: BoxConstraints(minHeight: compact ? 116 : 130),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.garis),
        boxShadow: [
          BoxShadow(
            color: AppColors.hijauTua.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            switchInCurve: Curves.easeOutBack,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: animation, child: child),
            ),
            child: Container(
              key: ValueKey(icon),
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF3EC),
                borderRadius: BorderRadius.circular(17),
              ),
              child: Icon(icon, color: AppColors.hijauTua, size: 27),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SEPUTAR DJAJAN',
                  style: TextStyle(
                    color: AppColors.hijauTua,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 5),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 420),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.04, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: Column(
                    key: ValueKey(_tipIndex),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tip.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        tip.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 11,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingArea() {
    if (_errorMessage != null) {
      return _buildErrorPanel();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.garis),
        boxShadow: [
          BoxShadow(
            color: AppColors.hijauTua.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 15,
            height: 15,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.hijauTua,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              _statusMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textGrey,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF0),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1DCA8)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                color: Color(0xFF9A6B0B),
                size: 19,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _errorTitle,
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: AppColors.textGrey,
                        fontSize: 10.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          FilledButton.icon(
            onPressed: _isLoading ? null : _restoreSession,
            icon: const Icon(Icons.refresh_rounded, size: 17),
            label: const Text('Coba lagi'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.hijauTua,
              foregroundColor: Colors.white,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }
}

class _AmbientCircle extends StatelessWidget {
  const _AmbientCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

class _SplashTip {
  const _SplashTip({required this.title, required this.description});

  final String title;
  final String description;
}
