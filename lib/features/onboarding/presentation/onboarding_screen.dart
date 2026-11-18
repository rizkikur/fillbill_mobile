import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/brand_config.dart';
import '../../../core/security/secure_storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/brand_logo_widget.dart';
import '../../../core/widgets/custom_button.dart';
import '../../auth/presentation/auth_notifier.dart';

class OnboardingSlideModel {
  final String title;
  final String subtitle;
  final IconData heroIcon;
  final List<BadgeData> badges;
  final List<String> tags;

  const OnboardingSlideModel({
    required this.title,
    required this.subtitle,
    required this.heroIcon,
    required this.badges,
    required this.tags,
  });
}

class BadgeData {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color bgColor;

  const BadgeData({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.bgColor,
  });
}

class OnboardingScreen extends ConsumerStatefulWidget {
  final SecureStorageService? storageService;

  const OnboardingScreen({
    super.key,
    this.storageService,
  });

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isCompleting = false;

  final List<OnboardingSlideModel> _slides = [
    OnboardingSlideModel(
      title: 'Transaksi PPOB Instan & Super Cepat',
      subtitle:
          'Beli pulsa, paket data, token PLN, bayar PDAM, hingga BPJS dalam hitungan detik dengan harga agen termurah dan konfirmasi otomatis.',
      heroIcon: Icons.flash_on_rounded,
      badges: [
        BadgeData(
          icon: Icons.phone_android_rounded,
          label: 'Pulsa & Data',
          iconColor: AppColors.info,
          bgColor: AppColors.infoBg,
        ),
        BadgeData(
          icon: Icons.bolt_rounded,
          label: 'Token PLN 24/7',
          iconColor: AppColors.warning,
          bgColor: AppColors.warningBg,
        ),
        BadgeData(
          icon: Icons.receipt_long_rounded,
          label: 'PDAM & BPJS',
          iconColor: AppColors.success,
          bgColor: AppColors.successBg,
        ),
      ],
      tags: ['⚡ Proses 3 Detik', '💰 Harga Grosir', '🔄 Realtime 24/7'],
    ),
    OnboardingSlideModel(
      title: 'Dompet Digital Finansial Terpercaya',
      subtitle:
          'Kelola saldo akun dengan keamanan enkripsi tingkat perbankan, top up fleksibel via VA & QRIS, serta proteksi biometrik.',
      heroIcon: Icons.account_balance_wallet_rounded,
      badges: [
        BadgeData(
          icon: Icons.qr_code_scanner_rounded,
          label: 'QRIS & VA Instan',
          iconColor: AppColors.neoGreenDark,
          bgColor: AppColors.neoGreenSurface,
        ),
        BadgeData(
          icon: Icons.fingerprint_rounded,
          label: 'Biometrik & PIN',
          iconColor: AppColors.accentEmerald,
          bgColor: AppColors.accentMint,
        ),
        BadgeData(
          icon: Icons.verified_user_rounded,
          label: 'Enkripsi AES',
          iconColor: AppColors.info,
          bgColor: AppColors.infoBg,
        ),
      ],
      tags: ['🔒 Enkripsi Hardware', '📱 Biometrik & PIN', '🛡️ Saldo Terjamin'],
    ),
    OnboardingSlideModel(
      title: 'Harga Grosir & Riwayat Transparan',
      subtitle:
          'Dapatkan harga agen langsung tanpa biaya tersembunyi, laporan mutasi saldo real-time, dan struk profesional siap cetak atau dibagikan.',
      heroIcon: Icons.price_check_rounded,
      badges: [
        BadgeData(
          icon: Icons.sell_rounded,
          label: 'Margin Maksimal',
          iconColor: AppColors.neoGreenDark,
          bgColor: AppColors.neoGreenSurface,
        ),
        BadgeData(
          icon: Icons.print_rounded,
          label: 'Cetak Struk & PDF',
          iconColor: AppColors.info,
          bgColor: AppColors.infoBg,
        ),
        BadgeData(
          icon: Icons.insights_rounded,
          label: 'Mutasi Rinci',
          iconColor: AppColors.success,
          bgColor: AppColors.successBg,
        ),
      ],
      tags: ['🧾 Cetak Struk Bluetooth', '📊 Laporan Real-Time', '🏷️ 100% Transparan'],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    if (_isCompleting) return;
    setState(() => _isCompleting = true);

    try {
      final SecureStorageService storage = widget.storageService ?? ref.read(secureStorageProvider);
      await storage.setOnboardingCompleted(true);
    } catch (e) {
      debugPrint('Onboarding persistence error: $e');
    }

    if (!mounted) return;
    context.go('/home');
  }

  void _onNextPressed() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentPage > 0) {
          _pageController.previousPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bgLight,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  // Top Navigation Bar (Logo on left, Skip on right)
                  _buildTopBar(),

                  // Carousel
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _slides.length,
                      physics: const BouncingScrollPhysics(),
                      onPageChanged: (index) {
                        setState(() => _currentPage = index);
                      },
                      itemBuilder: (context, index) {
                        return _buildSlide(_slides[index]);
                      },
                    ),
                  ),

                  // Bottom Controls (Pill Indicators & Action Button)
                  _buildBottomControls(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const BrandLogoWidget(
            size: 26,
            showText: true,
            isHorizontal: true,
          ),
          AnimatedOpacity(
            opacity: _currentPage == _slides.length - 1 ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: IgnorePointer(
              ignoring: _currentPage == _slides.length - 1,
              child: TextButton(
                key: const Key('onboarding_skip_button'),
                onPressed: _completeOnboarding,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                child: Text(
                  'Lewati',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide(OnboardingSlideModel slide) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Vector Illustration Card
              _buildIllustrationCard(slide),
              const SizedBox(height: 32),

              // Title
              Text(
                slide.title,
                textAlign: TextAlign.center,
                style: AppTypography.displayMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 14),

              // Subtitle
              Text(
                slide.subtitle,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),

              // Tag Chips Row
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: slide.tags.map((tag) => _buildTagChip(tag)).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIllustrationCard(OnboardingSlideModel slide) {
    return Container(
      width: double.infinity,
      height: 230,
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.neoGreen.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.neoGreenGlow.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background ambient circles
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.neoGreenSurface.withValues(alpha: 0.8),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: BrandConfig.primaryColor.withValues(alpha: 0.04),
              ),
            ),
          ),

          // Central Hero Avatar
          Center(
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    BrandConfig.primaryColor,
                    BrandConfig.primaryDark,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: BrandConfig.primaryColor.withValues(alpha: 0.25),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                slide.heroIcon,
                size: 44,
                color: AppColors.neoGreen,
              ),
            ),
          ),

          // Floating Badges
          Positioned(
            top: 20,
            left: 20,
            child: _buildBadge(slide.badges[0]),
          ),
          Positioned(
            bottom: 22,
            left: 18,
            child: _buildBadge(slide.badges[1]),
          ),
          Positioned(
            bottom: 22,
            right: 18,
            child: _buildBadge(slide.badges[2]),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(BadgeData badge) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: badge.bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: badge.iconColor.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badge.icon, size: 16, color: badge.iconColor),
          const SizedBox(width: 5),
          Text(
            badge.label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagChip(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Text(
        tag,
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    final isLastSlide = _currentPage == _slides.length - 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated Dot / Pill Indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_slides.length, (index) {
              final isActive = index == _currentPage;
              return GestureDetector(
                onTap: () {
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 28 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.neoGreen : AppColors.borderLight,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: AppColors.neoGreenGlow,
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),

          // Action Button
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: isLastSlide
                ? CustomButton(
                    key: const Key('onboarding_finish_button'),
                    text: 'Mulai Sekarang',
                    icon: Icons.arrow_forward_rounded,
                    backgroundColor: AppColors.neoGreen,
                    textColor: AppColors.neoGreenContrast,
                    isLoading: _isCompleting,
                    onPressed: _completeOnboarding,
                  )
                : CustomButton(
                    key: const Key('onboarding_next_button'),
                    text: 'Lanjut',
                    icon: Icons.arrow_forward_rounded,
                    backgroundColor: AppColors.primaryNavy,
                    textColor: AppColors.textWhite,
                    onPressed: _onNextPressed,
                  ),
          ),
        ],
      ),
    );
  }
}
