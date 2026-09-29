import 'dart:async';

import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _loadingController;

  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<double> _textFade;
  late Animation<double> _textSlide;

  @override
  void initState() {
    super.initState();

    // Controller untuk animasi logo
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // Controller untuk animasi tagline
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    // Controller untuk animasi loading
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    // Animasi logo: transparan → terlihat
    _logoFade = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOut,
    );

    // Animasi logo: sedikit kecil → ukuran normal
    _logoScale = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.easeOutBack,
      ),
    );

    // Animasi tagline: transparan → terlihat
    _textFade = CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOut,
    );

    // Animasi tagline: sedikit turun → posisi normal
    _textSlide = Tween<double>(
      begin: 12,
      end: 0,
    ).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeOutCubic,
      ),
    );

    _startAnimation();

    Timer(
      const Duration(seconds: 3),
      () {
        if (!mounted) return;

        Navigator.pushReplacementNamed(
          context,
          AppRoutes.login,
        );
      },
    );
  }

  Future<void> _startAnimation() async {
    await _logoController.forward();

    if (!mounted) return;

    await Future.delayed(
      const Duration(milliseconds: 150),
    );

    if (!mounted) return;

    _textController.forward();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _loadingController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              FadeTransition(
                opacity: _logoFade,
                child: ScaleTransition(
                  scale: _logoScale,
                  child: Image.asset(
                    'assets/images/logoNoBg.png',
                    width: 220,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Tagline
              AnimatedBuilder(
                animation: _textController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _textFade.value,
                    child: Transform.translate(
                      offset: Offset(
                        0,
                        _textSlide.value,
                      ),
                      child: child,
                    ),
                  );
                },
              ),

              const SizedBox(height: 28),

              // Loading dots
              AnimatedBuilder(
                animation: _loadingController,
                builder: (context, child) {
                  final value = _loadingController.value;

                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      3,
                      (index) {
                        final distance =
                            (value - (index * 0.2)).abs();

                        final scale = 1.0 +
                            (0.35 *
                                (1 -
                                    (distance.clamp(
                                      0.0,
                                      1.0,
                                    ))));

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 3,
                          ),
                          child: Transform.scale(
                            scale: scale,
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: Color(0xFF175D2B),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}