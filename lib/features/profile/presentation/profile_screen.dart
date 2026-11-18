import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/config/mockup_provider.dart';
import '../../../core/config/brand_config.dart';
import '../../../core/security/biometric_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/pin_dots_display.dart';
import '../../../core/widgets/pin_keypad.dart';
import '../../auth/presentation/auth_notifier.dart';
import '../../transactions/presentation/transaction_notifier.dart';
import '../../wallet/presentation/wallet_notifier.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isBiometricSupported = false;
  bool _isBiometricEnabled = false;
  bool _isLoadingBiometric = true;

  @override
  void initState() {
    super.initState();
    _loadBiometricSettings();
  }

  Future<void> _loadBiometricSettings() async {
    final biometricService = ref.read(biometricServiceProvider);
    final storageService = ref.read(secureStorageProvider);

    final supported = await biometricService.isDeviceSupported();
    final enabled = await storageService.isBiometricEnabled();

    if (mounted) {
      setState(() {
        _isBiometricSupported = supported;
        _isBiometricEnabled = enabled;
        _isLoadingBiometric = false;
      });
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    final biometricService = ref.read(biometricServiceProvider);
    final storageService = ref.read(secureStorageProvider);

    if (value) {
      // Autentikasi biometrik sebelum mengaktifkan
      final authenticated = await biometricService.authenticate(
        reason: 'Konfirmasi sidik jari Anda untuk mengaktifkan fitur biometrik',
      );

      if (authenticated) {
        await storageService.setBiometricEnabled(true);
        if (mounted) {
          setState(() => _isBiometricEnabled = true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.accentEmeraldDark,
              content: const Text('Autentikasi biometrik berhasil diaktifkan.'),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: AppColors.error,
              content: Text('Verifikasi biometrik gagal atau dibatalkan.'),
            ),
          );
        }
      }
    } else {
      await storageService.setBiometricEnabled(false);
      if (mounted) {
        setState(() => _isBiometricEnabled = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Autentikasi biometrik dinonaktifkan.'),
          ),
        );
      }
    }
  }

  void _handleChangePin() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _ChangePinBottomSheet(),
    );
  }

  Future<void> _openWhatsAppCs() async {
    final uri = Uri.parse(
      'https://wa.me/6281234567890?text=Halo%20Customer%20Service%20FillBill%2C%20saya%20membutuhkan%20bantuan%20terkait%20akun%20saya.',
    );
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tidak dapat membuka aplikasi WhatsApp.')),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menghubungkan ke WhatsApp CS.')),
        );
      }
    }
  }

  void _showThemeCustomizerBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ThemeCustomizerSheet(
        onThemeChanged: () {
          setState(() {});
        },
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryNavy,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.flash_on, color: AppColors.accentMint, size: 20),
            ),
            const SizedBox(width: 10),
            Text('Tentang FillBill', style: AppTypography.titleMedium),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('FillBill Mobile v1.0.0 (Production Release)', style: AppTypography.labelLarge),
            const SizedBox(height: 8),
            Text(
              'Aplikasi PPOB & Finansial dengan standar keamanan perbankan:\n'
              '• Arsitektur Bersih & Riverpod Reactive State\n'
              '• Idempotensi Transaksi V4 (Anti Tagihan Ganda)\n'
              '• Two-Step Challenge PIN Verification\n'
              '• Enkripsi Keystore Android & Biometrik\n'
              '• Deteksi Operator Seluler Instan 0ms',
              style: AppTypography.bodySmall.copyWith(height: 1.5),
            ),
            const SizedBox(height: 12),
            Text(
              'Hak Cipta © 2026 PT Xymetri Teknologi Indonesia. Seluruh hak cipta dilindungi.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary, fontSize: 11),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        bool isLoggingOut = false;

        return StatefulBuilder(
          builder: (ctx, setDialogState) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            backgroundColor: AppColors.surfaceWhite,
            elevation: 12,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Danger Icon Container
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      size: 32,
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Title
                  Text(
                    'Keluar dari Akun?',
                    textAlign: TextAlign.center,
                    style: AppTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Subtitle
                  Text(
                    'Sesi akun Anda akan ditutup dan seluruh data otentikasi lokal akan dihapus. Anda dapat masuk kembali kapan saja.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 26),

                  // Action Buttons: Symmetrical & Balanced
                  Row(
                    children: [
                      // Tombol Batal
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.borderLight, width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              backgroundColor: AppColors.bgLight,
                              foregroundColor: AppColors.textPrimary,
                              elevation: 0,
                            ),
                            onPressed: isLoggingOut ? null : () => Navigator.of(dialogCtx).pop(),
                            child: Text(
                              'Batal',
                              style: AppTypography.titleSmall.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Tombol Ya, Keluar
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: isLoggingOut
                                ? null
                                : () async {
                                    setDialogState(() => isLoggingOut = true);
                                    try {
                                      // 1. Clear session di server & secure storage
                                      await ref.read(authNotifierProvider.notifier).logout();

                                      // 2. Invalidate seluruh cached riverpod state
                                      ref.invalidate(walletNotifierProvider);
                                      ref.invalidate(transactionHistoryProvider);
                                      ref.invalidate(transactionExecutionProvider);
                                    } catch (_) {}

                                    if (dialogCtx.mounted) {
                                      Navigator.of(dialogCtx).pop();
                                    }

                                    if (context.mounted) {
                                      // 3. Navigasi bersih kembali ke layar login
                                      context.go('/auth/phone');
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          backgroundColor: AppColors.primaryNavy,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          content: const Row(
                                            children: [
                                              Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                                              SizedBox(width: 10),
                                              Text('Sesi berhasil diakhiri. Silakan login kembali.'),
                                            ],
                                          ),
                                        ),
                                      );
                                    }
                                  },
                            child: isLoggingOut
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.logout, size: 18, color: Colors.white),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Ya, Keluar',
                                        style: AppTypography.titleSmall.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return 'FB';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;

    final userName = user?.name ?? 'Pengguna FillBill';
    final userPhone = user?.phone ?? '+62 812-3456-7890';
    final isAgent = user?.tier == 'agent' || user?.tier == 'agen';
    final initials = _getInitials(user?.name);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: const Text('Akun & Pengaturan'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Header Profile Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: AppColors.primaryNavy,
                    child: Text(
                      initials,
                      style: AppTypography.titleLarge.copyWith(
                        color: AppColors.textWhite,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: AppTypography.titleLarge.copyWith(fontSize: 18),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userPhone,
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isAgent
                                    ? AppColors.warning.withValues(alpha: 0.15)
                                    : AppColors.accentMint,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isAgent ? '★ Mitra Agen' : '● Pelanggan Reguler',
                                style: AppTypography.labelSmall.copyWith(
                                  color: isAgent
                                      ? AppColors.warning
                                      : AppColors.accentEmeraldDark,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.accentEmeraldDark.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified, size: 12, color: AppColors.accentEmeraldDark),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Terverifikasi',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.accentEmeraldDark,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Section 1: Keamanan & PIN
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'KEAMANAN & TRANSAKSI',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                children: [
                  _buildListTile(
                    icon: Icons.lock_outline,
                    iconColor: AppColors.primaryNavy,
                    title: 'Ganti PIN Transaksi',
                    subtitle: 'Ubah 6 digit PIN keamanan pembayaran Anda',
                    onTap: _handleChangePin,
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 16),
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.accentMint,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.fingerprint, color: AppColors.accentEmeraldDark, size: 22),
                    ),
                    title: Text(
                      'Biometrik & Sidik Jari',
                      style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      _isBiometricSupported
                          ? 'Konfirmasi transaksi 1-ketuk tanpa ketik PIN'
                          : 'Perangkat tidak mendukung biometrik',
                      style: AppTypography.bodySmall,
                    ),
                    value: _isBiometricEnabled,
                    activeTrackColor: AppColors.accentEmeraldDark,
                    onChanged: _isLoadingBiometric || !_isBiometricSupported
                        ? null
                        : (val) => _toggleBiometric(val),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Section 2: Layanan & Dukungan
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'BANTUAN & INFORMASI',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                children: [
                  Builder(
                    builder: (context) {
                      final isMockup = ref.watch(mockupModeProvider);
                      return _buildListTile(
                        icon: Icons.science_outlined,
                        iconColor: Colors.deepPurple,
                        title: 'Mode Auto Mockup (Demo)',
                        subtitle: isMockup
                            ? 'Aktif: Form otomatis terisi contoh simulasi'
                            : 'Nonaktif: Mode live produksi (input manual kosong)',
                        trailing: Switch(
                          value: isMockup,
                          activeTrackColor: AppColors.accentEmeraldDark,
                          onChanged: (val) async {
                            await ref.read(mockupModeProvider.notifier).setEnabled(val);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    val
                                        ? 'Mode Auto Mockup DIAKTIFKAN. Seluruh menu akan otomatis terisi contoh.'
                                        : 'Mode Live Produksi DIAKTIFKAN. Seluruh input kosong & murni live.',
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 16),
                  _buildListTile(
                    icon: Icons.palette_outlined,
                    iconColor: AppColors.warning,
                    title: 'Tema Warna & Font Brand',
                    subtitle: 'Kustomisasi warna primer, aksen & jenis font aplikasi',
                    onTap: _showThemeCustomizerBottomSheet,
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 16),
                  _buildListTile(
                    icon: Icons.chat_outlined,
                    iconColor: AppColors.accentEmeraldDark,
                    title: 'Hubungi Customer Care WhatsApp',
                    subtitle: 'Bantuan instan 24/7 kendala transaksi PPOB',
                    onTap: _openWhatsAppCs,
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 16),
                  _buildListTile(
                    icon: Icons.info_outline,
                    iconColor: AppColors.info,
                    title: 'Tentang Aplikasi FillBill',
                    subtitle: 'Informasi versi, lisensi & enkripsi sistem',
                    onTap: _showAboutDialog,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Section 3: Logout
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: _buildListTile(
                icon: Icons.logout,
                iconColor: AppColors.error,
                title: 'Keluar dari Akun',
                subtitle: 'Sesi akun Anda akan ditutup dengan aman',
                isDestructive: true,
                onTap: _confirmLogout,
              ),
            ),

            const SizedBox(height: 32),

            // App Version Footer
            Center(
              child: Column(
                children: [
                  Text(
                    'FillBill Indonesia • v1.0.0+1',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Financial-grade PPOB Engine',
                    style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary, fontSize: 10),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
    bool isDestructive = false,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDestructive ? AppColors.errorBg : iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: AppTypography.bodyLarge.copyWith(
          fontWeight: FontWeight.w600,
          color: isDestructive ? AppColors.error : AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.bodySmall.copyWith(
          color: isDestructive ? AppColors.error.withValues(alpha: 0.8) : AppColors.textSecondary,
        ),
      ),
      trailing: trailing ??
          (isDestructive
              ? null
              : const Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 20)),
    );
  }
}

/// Bottom Sheet untuk Alur Ganti PIN Transaksi (Konfirmasi PIN Baru)
class _ChangePinBottomSheet extends ConsumerStatefulWidget {
  const _ChangePinBottomSheet();

  @override
  ConsumerState<_ChangePinBottomSheet> createState() => _ChangePinBottomSheetState();
}

class _ChangePinBottomSheetState extends ConsumerState<_ChangePinBottomSheet> {
  int _step = 1; // 1: Masukkan PIN Baru, 2: Konfirmasi PIN Baru
  String _newPin = '';
  String _confirmPin = '';
  String? _errorMessage;

  void _onKeyPressed(String key) {
    setState(() {
      _errorMessage = null;
      if (_step == 1) {
        if (_newPin.length < 6) {
          _newPin += key;
          if (_newPin.length == 6) {
            _step = 2;
          }
        }
      } else {
        if (_confirmPin.length < 6) {
          _confirmPin += key;
          if (_confirmPin.length == 6) {
            _handleFinishPinChange();
          }
        }
      }
    });
  }

  void _onBackspacePressed() {
    setState(() {
      _errorMessage = null;
      if (_step == 1) {
        if (_newPin.isNotEmpty) {
          _newPin = _newPin.substring(0, _newPin.length - 1);
        }
      } else {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        } else {
          _step = 1;
        }
      }
    });
  }

  Future<void> _handleFinishPinChange() async {
    if (_newPin != _confirmPin) {
      setState(() {
        _errorMessage = 'PIN Konfirmasi tidak cocok. Ulangi kembali.';
        _confirmPin = '';
        _step = 1;
        _newPin = '';
      });
      return;
    }

    // Panggil auth notifier / storage untuk simpan PIN baru
    final storage = ref.read(secureStorageProvider);
    await storage.saveEncryptedPin(_newPin);
    await ref.read(authNotifierProvider.notifier).setupPin(_newPin);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.accentEmeraldDark,
          content: const Text('PIN Transaksi berhasil diubah dan disimpan aman!'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _step == 1 ? 'Buat PIN Transaksi Baru' : 'Konfirmasi PIN Baru';
    final subtitle = _step == 1
        ? 'Ketik 6 digit angka PIN baru untuk keamanan akun FillBill Anda'
        : 'Masukkan kembali 6 digit angka yang baru saja Anda buat';
    final currentLength = _step == 1 ? _newPin.length : _confirmPin.length;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 20,
        right: 20,
        top: 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(title, style: AppTypography.titleLarge),
          const SizedBox(height: 6),
          Text(subtitle, textAlign: TextAlign.center, style: AppTypography.bodySmall),
          const SizedBox(height: 20),

          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.errorBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _errorMessage!,
                style: AppTypography.bodySmall.copyWith(color: AppColors.error),
              ),
            ),
            const SizedBox(height: 16),
          ],

          PinDotsDisplay(length: 6, enteredLength: currentLength),
          const SizedBox(height: 24),

          PinKeypad(
            onKeyPressed: _onKeyPressed,
            onBackspacePressed: _onBackspacePressed,
          ),
        ],
      ),
    );
  }
}

/// Bottom Sheet untuk Kustomisasi Tema, Warna, & Font
class _ThemeCustomizerSheet extends StatefulWidget {
  final VoidCallback onThemeChanged;

  const _ThemeCustomizerSheet({required this.onThemeChanged});

  @override
  State<_ThemeCustomizerSheet> createState() => _ThemeCustomizerSheetState();
}

class _ThemeCustomizerSheetState extends State<_ThemeCustomizerSheet> {
  final List<String> _availableFonts = [
    'Plus Jakarta Sans',
    'Poppins',
    'Inter',
    'Roboto',
    'Outfit',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 12,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Tema Warna & Tipografi', style: AppTypography.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Pilih tema palet warna dan jenis huruf yang diinginkan',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: 20),

            // Pilihan Palet Warna
            Text('PALET WARNA', style: AppTypography.labelSmall.copyWith(letterSpacing: 1.1)),
            const SizedBox(height: 10),
            Column(
              children: BrandColorPalette.values.map((palette) {
                final isSelected = BrandConfig.primaryColor == palette.primary;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? palette.accent : AppColors.borderLight,
                      width: isSelected ? 2 : 1,
                    ),
                    color: isSelected ? palette.accent.withValues(alpha: 0.05) : Colors.transparent,
                  ),
                  child: ListTile(
                    onTap: () {
                      setState(() {
                        BrandConfig.applyPalette(palette);
                      });
                      widget.onThemeChanged();
                    },
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: palette.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: palette.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    title: Text(
                      palette.name,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check_circle, color: palette.accent)
                        : null,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Pilihan Font
            Text('JENIS FONT (GOOGLE FONTS)', style: AppTypography.labelSmall.copyWith(letterSpacing: 1.1)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableFonts.map((font) {
                final isSelected = BrandConfig.fontFamily == font;
                return ChoiceChip(
                  label: Text(font),
                  selected: isSelected,
                  selectedColor: AppColors.accentMint,
                  labelStyle: TextStyle(
                    fontFamily: font,
                    color: isSelected ? AppColors.accentEmeraldDark : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        BrandConfig.fontFamily = font;
                      });
                      widget.onThemeChanged();
                    }
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Tombol Reset ke Default
            Center(
              child: TextButton.icon(
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reset ke Tema Bawaan FillBill'),
                onPressed: () {
                  setState(() {
                    BrandConfig.resetToDefault();
                  });
                  widget.onThemeChanged();
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
