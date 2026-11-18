import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../features/wallet/presentation/widgets/quick_topup_sheet.dart';

class MainNavShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainNavShell({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    final branchIndex = navigationShell.currentIndex;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: navigationShell,
      extendBody: true, // Allows smooth floating effect over content if desired
      bottomNavigationBar: SizedBox(
        key: const Key('nav_bar'),
        height: 72 + bottomPadding,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            // Custom Curved Background with Notch/Scoop
            CustomPaint(
              size: Size(MediaQuery.of(context).size.width, 68 + bottomPadding),
              painter: CurvedScoopPainter(
                color: AppColors.surfaceWhite,
                shadowColor: Colors.black.withValues(alpha: 0.08),
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: 66,
                  child: Row(
                    children: [
                      // Branch 0: Beranda
                      Expanded(
                        child: _buildNavItem(
                          itemKey: const Key('nav_tab_0'),
                          semanticKey: const Key('nav_tab_home'),
                          branchTarget: 0,
                          isSelected: branchIndex == 0,
                          icon: Icons.home_outlined,
                          selectedIcon: Icons.home_rounded,
                          label: 'Home',
                        ),
                      ),
                      // Branch 1: Riwayat Transaksi
                      Expanded(
                        child: _buildNavItem(
                          itemKey: const Key('nav_tab_1'),
                          semanticKey: const Key('nav_tab_history'),
                          branchTarget: 1,
                          isSelected: branchIndex == 1,
                          icon: Icons.receipt_long_outlined,
                          selectedIcon: Icons.receipt_long_rounded,
                          label: 'Riwayat',
                        ),
                      ),

                      // Center scooped space for the elevated FAB
                      const SizedBox(width: 76),

                      // Branch 2: Dompet Saya
                      Expanded(
                        child: _buildNavItem(
                          itemKey: const Key('nav_tab_2'),
                          semanticKey: const Key('nav_tab_wallet'),
                          branchTarget: 2,
                          isSelected: branchIndex == 2,
                          icon: Icons.account_balance_wallet_outlined,
                          selectedIcon: Icons.account_balance_wallet_rounded,
                          label: 'Dompet',
                        ),
                      ),
                      // Branch 3: Profil & Akun (Synchronized with /profile)
                      Expanded(
                        child: _buildNavItem(
                          itemKey: const Key('nav_tab_3'),
                          semanticKey: const Key('nav_tab_profile'),
                          branchTarget: 3,
                          isSelected: branchIndex == 3,
                          icon: Icons.person_outline_rounded,
                          selectedIcon: Icons.person_rounded,
                          label: 'Profil',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Elevated Floating Center Button (Floating in the Scoop)
            Positioned(
              top: 0,
              child: _buildCenterFloatingActionButton(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required Key itemKey,
    required Key semanticKey,
    required int branchTarget,
    required bool isSelected,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
  }) {
    // WCAG AAA Compliant active colors (15.06:1 on neoGreenSurface)
    const activeColor = AppColors.neoGreenContrast;
    // WCAG AA Compliant inactive color (4.76:1 on surfaceWhite)
    const inactiveColor = AppColors.textSecondary;

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: InkWell(
        key: itemKey,
        onTap: () {
          navigationShell.goBranch(
            branchTarget,
            initialLocation: branchTarget == navigationShell.currentIndex,
          );
        },
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Soft Pill Indicator
              AnimatedContainer(
                key: semanticKey,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.neoGreenSurface : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: isSelected
                      ? Border.all(
                          color: AppColors.neoGreen.withValues(alpha: 0.35),
                          width: 1.0,
                        )
                      : Border.all(
                          color: Colors.transparent,
                          width: 1.0,
                        ),
                ),
                child: Icon(
                  isSelected ? selectedIcon : icon,
                  color: isSelected ? activeColor : inactiveColor,
                  size: 22,
                ),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOutCubic,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? activeColor : inactiveColor,
                  letterSpacing: -0.2,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterFloatingActionButton(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Top Up Cepat',
      child: GestureDetector(
        key: const Key('nav_fab'),
        onTap: () {
          QuickTopUpSheet.show(context);
        },
        child: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [
                AppColors.neoGreenLight,
                AppColors.neoGreen,
                AppColors.neoGreenDark,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.38),
              width: 1.5,
            ),
            boxShadow: [
              // Signature Neo-Green Ambient Glow
              const BoxShadow(
                color: AppColors.neoGreenGlow,
                blurRadius: 16,
                spreadRadius: 1,
                offset: Offset(0, 5),
              ),
              // Grounding Elevation Shadow
              BoxShadow(
                color: AppColors.primaryNavy.withValues(alpha: 0.14),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.qr_code_scanner_rounded,
              color: AppColors.neoGreenContrast,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom Painter that draws a clean bar with an organic scooped cradle in the middle
class CurvedScoopPainter extends CustomPainter {
  final Color color;
  final Color shadowColor;

  CurvedScoopPainter({
    required this.color,
    required this.shadowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = shadowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final path = Path();
    final centerX = size.width / 2;
    const notchRadius = 38.0;
    const notchDepth = 26.0;

    // Start from top-left
    path.moveTo(0, 0);
    // Line to start of scoop
    path.lineTo(centerX - notchRadius - 16, 0);

    // Smooth cubic curve into the center cradle
    path.cubicTo(
      centerX - notchRadius,
      0,
      centerX - notchRadius + 6,
      notchDepth,
      centerX,
      notchDepth,
    );

    // Smooth cubic curve climbing out of cradle to right
    path.cubicTo(
      centerX + notchRadius - 6,
      notchDepth,
      centerX + notchRadius,
      0,
      centerX + notchRadius + 16,
      0,
    );

    // Line to top-right
    path.lineTo(size.width, 0);
    // Down to bottom-right
    path.lineTo(size.width, size.height);
    // Across to bottom-left
    path.lineTo(0, size.height);
    path.close();

    // Draw shadow path
    canvas.save();
    canvas.translate(0, -2);
    canvas.drawPath(path, shadowPaint);
    canvas.restore();

    // Draw solid bar
    canvas.drawPath(path, paint);

    // Draw subtle top border line tracing outer shoulders and cradle contour
    final borderPaint = Paint()
      ..color = AppColors.borderLight.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final borderPath = Path()
      ..moveTo(0, 0)
      ..lineTo(centerX - notchRadius - 16, 0)
      ..cubicTo(
        centerX - notchRadius,
        0,
        centerX - notchRadius + 6,
        notchDepth,
        centerX,
        notchDepth,
      )
      ..cubicTo(
        centerX + notchRadius - 6,
        notchDepth,
        centerX + notchRadius,
        0,
        centerX + notchRadius + 16,
        0,
      )
      ..lineTo(size.width, 0);

    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CurvedScoopPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.shadowColor != shadowColor;
  }
}
