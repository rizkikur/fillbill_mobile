import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class PinKeypad extends StatelessWidget {
  final ValueChanged<String> onKeyPressed;
  final VoidCallback onBackspacePressed;
  final VoidCallback? onBiometricPressed;
  final bool showBiometric;

  const PinKeypad({
    super.key,
    required this.onKeyPressed,
    required this.onBackspacePressed,
    this.onBiometricPressed,
    this.showBiometric = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRow(['1', '2', '3']),
          const SizedBox(height: 16),
          _buildRow(['4', '5', '6']),
          const SizedBox(height: 16),
          _buildRow(['7', '8', '9']),
          const SizedBox(height: 16),
          _buildBottomRow(),
        ],
      ),
    );
  }

  Widget _buildRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((key) => _buildNumberButton(key)).toList(),
    );
  }

  Widget _buildBottomRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Tombol Biometrik (kiri bawah)
        if (showBiometric && onBiometricPressed != null)
          _buildIconButton(
            icon: Icons.fingerprint,
            onPressed: () {
              HapticFeedback.lightImpact();
              onBiometricPressed?.call();
            },
          )
        else
          const SizedBox(width: 72, height: 72),

        // Angka 0 (tengah bawah)
        _buildNumberButton('0'),

        // Tombol Backspace (kanan bawah)
        _buildIconButton(
          icon: Icons.backspace_outlined,
          onPressed: () {
            HapticFeedback.lightImpact();
            onBackspacePressed();
          },
        ),
      ],
    );
  }

  Widget _buildNumberButton(String text) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.borderLight, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(36),
          onTap: () {
            HapticFeedback.lightImpact();
            onKeyPressed(text);
          },
          child: Center(
            child: Text(
              text,
              style: AppTypography.titleLarge.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryNavy,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(36),
          onTap: onPressed,
          child: Center(
            child: Icon(icon, color: AppColors.primaryNavy, size: 28),
          ),
        ),
      ),
    );
  }
}

