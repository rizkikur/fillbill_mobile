import 'package:flutter/material.dart';

/// Preset Tema Warna Siap Pakai
enum BrandColorPalette {
  deepNavyEmerald(
    name: 'Deep Navy & Emerald (Default FillBill)',
    primary: Color(0xFF0D2137),
    accent: Color(0xFF10B981),
  ),
  royalBlueAmber(
    name: 'Royal Blue & Amber Gold (Gaya Perbankan)',
    primary: Color(0xFF1E3A8A),
    accent: Color(0xFFF59E0B),
  ),
  cyberPurpleMint(
    name: 'Cyber Purple & Mint (Gaya Modern E-Wallet)',
    primary: Color(0xFF4C1D95),
    accent: Color(0xFF10B981),
  ),
  elegantTealCyan(
    name: 'Elegant Teal & Cyan (Fintech Global)',
    primary: Color(0xFF0F766E),
    accent: Color(0xFF06B6D4),
  ),
  rubyCrimsonGold(
    name: 'Ruby Crimson & Gold (Gaya Premium)',
    primary: Color(0xFF881337),
    accent: Color(0xFFEAB308),
  ),
  neoLimeVibrant(
    name: 'Neo Lime & Clean White (Sesuai Screenshot)',
    primary: Color(0xFF9EE834),
    accent: Color(0xFF84CC16),
  ),
  freshLimeObsidian(
    name: 'Fresh Lime & Dark Obsidian (Gaya Modern)',
    primary: Color(0xFF161F28),
    accent: Color(0xFFA3E635),
  ),
  appleGreenClean(
    name: 'Apple Green & Forest (Gaya Hijau Segar)',
    primary: Color(0xFF0F3923),
    accent: Color(0xFF84CC16),
  );

  final String name;
  final Color primary;
  final Color accent;

  const BrandColorPalette({
    required this.name,
    required this.primary,
    required this.accent,
  });
}

/// Konfigurasi Utama Branding & White-Label Aplikasi
/// Ubah nilai di file ini untuk mengganti Nama, Slogan, Logo, Font, dan Warna di SELURUH aplikasi!
class BrandConfig {
  BrandConfig._();

  // ==========================================
  // 1. IDENTITAS BRAND (NAMA & SLOGAN)
  // ==========================================
  static String appName = 'FillBill';
  static String appTagline = 'Financial-grade PPOB & Payment Engine';
  static String companyName = 'PT Xymetri Teknologi Indonesia';
  static String csWhatsApp = '6281234567890';
  static String supportEmail = 'support@fillbill.com';

  // ==========================================
  // 2. LOGO APLIKASI
  // ==========================================
  // Jika Anda punya file gambar logo PNG/SVG sendiri di folder assets:
  // Isikan path-nya di sini (misal: 'assets/images/logo.png').
  // Jika null/kosong, aplikasi otomatis memakai vector emblem modern bawaan.
  static String? customLogoAsset;

  // ==========================================
  // 3. FONT GOOGLE (TIPOGRAFI)
  // ==========================================
  // Pilihan populer:
  // - 'Plus Jakarta Sans' (Modern Fintech - Default)
  // - 'Poppins' (Populer, Friendly, Bulat)
  // - 'Inter' (Sangat bersih & tegas)
  // - 'Roboto' (Standar Google Android)
  // - 'Outfit' (Minimalis modern)
  // - 'Nunito' (Lembut & Elegan)
  static String fontFamily = 'Plus Jakarta Sans';

  // ==========================================
  // 4. PALET WARNA UTAMA
  // ==========================================
  // Anda bisa mengganti warna secara manual di bawah ini:
  static Color primaryColor = const Color(0xFF0D2137); // Warna Utama (Header, Tombol Utama)
  static Color accentColor = const Color(0xFF10B981);  // Warna Aksen / Aksi (Sukses, Saldo, Badge)

  // Warna turunan yang dihitung otomatis dari warna di atas
  static Color get primaryDark => Color.lerp(primaryColor, Colors.black, 0.25) ?? primaryColor;
  static Color get primaryLight => Color.lerp(primaryColor, Colors.white, 0.2) ?? primaryColor;
  
  static Color get accentDark => Color.lerp(accentColor, Colors.black, 0.2) ?? accentColor;
  static Color get accentLight => Color.lerp(accentColor, Colors.white, 0.25) ?? accentColor;
  static Color get accentMint => Color.lerp(accentColor, Colors.white, 0.85) ?? const Color(0xFFD1FAE5);

  /// Helper untuk mengubah tema menggunakan salah satu Palette Preset
  static void applyPalette(BrandColorPalette palette) {
    primaryColor = palette.primary;
    accentColor = palette.accent;
  }

  /// Helper untuk mereset ke tema asli FillBill
  static void resetToDefault() {
    appName = 'FillBill';
    appTagline = 'Financial-grade PPOB & Payment Engine';
    fontFamily = 'Plus Jakarta Sans';
    primaryColor = const Color(0xFF0D2137);
    accentColor = const Color(0xFF10B981);
    customLogoAsset = null;
  }
}

