import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/brand_config.dart';
import '../theme/app_colors.dart';

class BrandLogoWidget extends StatelessWidget {
  final double size;
  final bool showText;
  final bool isHorizontal;
  final Color? textColor;

  const BrandLogoWidget({
    super.key,
    this.size = 64,
    this.showText = true,
    this.isHorizontal = false,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    Widget logoIcon;

    if (BrandConfig.customLogoAsset != null) {
      logoIcon = ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.22),
        child: Image.asset(
          BrandConfig.customLogoAsset!,
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => _buildVectorLogo(),
        ),
      );
    } else {
      logoIcon = _buildVectorLogo();
    }

    if (!showText) {
      return logoIcon;
    }

    final effectiveTextColor = textColor ?? AppColors.textPrimary;

    final textWidget = Column(
      crossAxisAlignment:
          isHorizontal ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          BrandConfig.appName,
          style: GoogleFonts.getFont(
            BrandConfig.fontFamily,
            fontSize: size * (isHorizontal ? 0.45 : 0.35),
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: effectiveTextColor,
          ),
        ),
        if (!isHorizontal) const SizedBox(height: 2),
        Text(
          BrandConfig.appTagline,
          style: GoogleFonts.getFont(
            BrandConfig.fontFamily,
            fontSize: size * (isHorizontal ? 0.22 : 0.18),
            fontWeight: FontWeight.w500,
            color: effectiveTextColor.withValues(alpha: 0.7),
          ),
        ),
      ],
    );

    if (isHorizontal) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          logoIcon,
          const SizedBox(width: 12),
          textWidget,
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        logoIcon,
        const SizedBox(height: 12),
        textWidget,
      ],
    );
  }

  Widget _buildVectorLogo() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            BrandConfig.primaryColor,
            BrandConfig.primaryDark,
          ],
        ),
        borderRadius: BorderRadius.circular(size * 0.24),
        boxShadow: [
          BoxShadow(
            color: BrandConfig.primaryColor.withValues(alpha: 0.3),
            blurRadius: size * 0.25,
            offset: Offset(0, size * 0.1),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: size * 0.65,
          height: size * 0.65,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: BrandConfig.accentColor.withValues(alpha: 0.18),
          ),
          child: Icon(
            Icons.flash_on_rounded,
            size: size * 0.48,
            color: BrandConfig.accentColor,
          ),
        ),
      ),
    );
  }
}

