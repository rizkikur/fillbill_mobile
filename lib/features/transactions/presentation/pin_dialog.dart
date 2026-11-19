import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/security/biometric_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/pin_dots_display.dart';
import '../../../core/widgets/pin_keypad.dart';
import '../../auth/presentation/auth_notifier.dart';

class PinDialog extends ConsumerStatefulWidget {
  final String title;
  final String subtitle;

  const PinDialog({
    super.key,
    this.title = 'Masukkan PIN Transaksi',
    this.subtitle = 'Ketik 6 digit PIN Anda untuk mengonfirmasi pembayaran.',
  });

  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PinDialog(),
    );
  }

  @override
  ConsumerState<PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends ConsumerState<PinDialog> {
  String _enteredPin = '';
  bool _isBiometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    try {
      final storage = ref.read(secureStorageProvider);
      final biometric = ref.read(biometricServiceProvider);

      final isEnabled = await storage.isBiometricEnabled();
      final isSupported = await biometric.isDeviceSupported();
      final savedPin = await storage.getEncryptedPin();

      if (mounted && isEnabled && isSupported && savedPin != null) {
        setState(() {
          _isBiometricAvailable = true;
        });
        // Berikan opsi otomatis prompt biometrik
        _handleBiometricAuth();
      }
    } catch (_) {}
  }

  Future<void> _handleBiometricAuth() async {
    final biometric = ref.read(biometricServiceProvider);
    final storage = ref.read(secureStorageProvider);

    final authenticated = await biometric.authenticate(
      reason: 'Pindai sidik jari untuk mengonfirmasi transaksi FillBill',
    );

    if (authenticated && mounted) {
      final savedPin = await storage.getEncryptedPin();
      if (savedPin != null && mounted) {
        Navigator.of(context).pop(savedPin);
      }
    }
  }

  void _onKeyPressed(String key) {
    if (_enteredPin.length < 6) {
      setState(() {
        _enteredPin += key;
      });

      if (_enteredPin.length == 6) {
        Navigator.of(context).pop(_enteredPin);
      }
    }
  }

  void _onBackspacePressed() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
          const SizedBox(height: 20),
          Text(widget.title, style: AppTypography.titleLarge),
          const SizedBox(height: 6),
          Text(
            widget.subtitle,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 24),

          // Indikator 6 Bulatan PIN
          PinDotsDisplay(
            length: 6,
            enteredLength: _enteredPin.length,
          ),

          const SizedBox(height: 24),

          // Custom Keypad dengan Biometrik jika diaktifkan
          PinKeypad(
            onKeyPressed: _onKeyPressed,
            onBackspacePressed: _onBackspacePressed,
            showBiometric: _isBiometricAvailable,
            onBiometricPressed: _handleBiometricAuth,
          ),
        ],
      ),
    );
  }
}
