import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/config/brand_config.dart';
import '../../../core/security/secure_storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand_logo_widget.dart';
import '../../auth/presentation/auth_notifier.dart';

/// Splash Screen dengan tampilan branding polished, animasi transisi logo halus,
/// dan pengarah rute (dispatcher) otomatis berdasarkan status onboarding.
class SplashScreen extends ConsumerStatefulWidget {
  final SecureStorageService? storageService;

  const SplashScreen({
    super.key,
    this.storageService,
  });

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Setup animasi logo (Scale & Fade)
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _animationController.forward();

    // 2. Eksekusi logika dispatching setelah animasi mulai berjalan
    _dispatchRoute();
  }

  /// Mengevaluasi status lokal dan melakukan navigasi dengan durasi minimal 1.5 detik
  Future<void> _dispatchRoute() async {
    final stopwatch = Stopwatch()..start();

    // Baca status onboarding dari SecureStorageService (mendukung injeksi untuk pengujian)
    final SecureStorageService storage = widget.storageService ?? ref.read(secureStorageProvider);
    final isOnboardingCompleted = await storage.isOnboardingCompleted();

    // Pastikan splash tampil minimal 1.5 detik untuk estetika brand
    final elapsedMs = stopwatch.elapsedMilliseconds;
    if (elapsedMs < 1500) {
      await Future.delayed(Duration(milliseconds: 1500 - elapsedMs));
    }

    // Pastikan widget masih mounted sebelum navigasi via context
    if (!mounted) return;

    // Evaluasi keputusan rute:
    // Pengguna baru -> Onboarding
    // Pengguna yang sudah menyelesaikan onboarding -> Langsung ke layar utama (/home)
    try {
      if (!isOnboardingCompleted) {
        context.go('/onboarding');
      } else {
        context.go('/home');
      }
    } catch (e) {
      debugPrint('Splash navigation: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Mencegah pop / back navigation selama splash aktif
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: BrandConfig.primaryColor,
        body: Stack(
          children: [
            // 1. Background Gradient Brand
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      BrandConfig.primaryColor,
                      BrandConfig.primaryDark,
                    ],
                  ),
                ),
              ),
            ),

            // 2. Ambient Radial Glow (Neo-Green & Accent Blend)
            Positioned.fill(
              child: Center(
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.neoGreenGlow.withValues(alpha: 0.18),
                        BrandConfig.accentColor.withValues(alpha: 0.08),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // 3. Animated Brand Logo Center
            Center(
              child: ScaleTransition(
                key: const Key('splash_logo_scale'),
                scale: _scaleAnimation,
                child: FadeTransition(
                  key: const Key('splash_logo_fade'),
                  opacity: _fadeAnimation,
                  child: const BrandLogoWidget(
                    size: 88,
                    showText: true,
                    textColor: AppColors.textWhite,
                  ),
                ),
              ),
            ),

            // 4. Footer Branding & Loading Indicator
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 28.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Loading indicator dengan aksen Neo-Green
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.neoGreen,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Versi aplikasi
                      Text(
                        '${BrandConfig.appName} Mobile • v1.0.0',
                        style: GoogleFonts.getFont(
                          BrandConfig.fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textWhite.withValues(alpha: 0.6),
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Tagline keamanan & identitas
                      Text(
                        BrandConfig.appTagline,
                        style: GoogleFonts.getFont(
                          BrandConfig.fontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textWhite.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
