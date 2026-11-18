import 'package:flutter/material.dart';
import '../config/brand_config.dart';

/// Palet Warna Finansial FillBill yang terhubung dinamis ke BrandConfig
class AppColors {
  AppColors._();

  // Dynamic Primary & Accent (Dapat diubah via BrandConfig)
  static Color get primaryNavy => BrandConfig.primaryColor;
  static Color get primaryNavyDark => BrandConfig.primaryDark;
  static Color get primaryNavyLight => BrandConfig.primaryLight;

  static Color get accentEmerald => BrandConfig.accentColor;
  static Color get accentEmeraldDark => BrandConfig.accentDark;
  static Color get accentEmeraldLight => BrandConfig.accentLight;
  static Color get accentMint => BrandConfig.accentMint;

  // Neo-Green Design System Tokens (Bottom Nav, Top-Up, Onboarding)
  static const Color neoGreen = Color(0xFFA3E635);
  static const Color neoGreenDark = Color(0xFF65A30D);
  static const Color neoGreenLight = Color(0xFFBEF264);
  static const Color neoGreenGlow = Color(0x66A3E635);
  static const Color neoGreenSurface = Color(0xFFF7FEE7);
  static const Color neoGreenContrast = Color(0xFF142900);

  // Backgrounds & Surface
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color bgDark = Color(0xFF0A1118);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF141E28);

  // Border & Dividers
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF1E293B);

  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textWhite = Color(0xFFFFFFFF);

  // Status Colors (Financial)
  static const Color success = Color(0xFF10B981);
  static const Color successBg = Color(0xFFECFDF5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningBg = Color(0xFFFFFBEB);
  static const Color error = Color(0xFFEF4444);
  static const Color errorBg = Color(0xFFFEF2F2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoBg = Color(0xFFEFF6FF);

  // Shimmer colors
  static const Color shimmerBase = Color(0xFFE2E8F0);
  static const Color shimmerHighlight = Color(0xFFF1F5F9);
}
