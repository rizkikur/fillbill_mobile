import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    String label;

    switch (status.toLowerCase()) {
      case 'success':
      case 'paid':
        bg = AppColors.successBg;
        text = AppColors.success;
        label = 'Berhasil';
        break;
      case 'pending':
        bg = AppColors.warningBg;
        text = AppColors.warning;
        label = 'Menunggu';
        break;
      case 'processing':
        bg = AppColors.infoBg;
        text = AppColors.info;
        label = 'Diproses';
        break;
      case 'failed':
      case 'failure':
        bg = AppColors.errorBg;
        text = AppColors.error;
        label = 'Gagal';
        break;
      case 'refunded':
        bg = AppColors.infoBg;
        text = AppColors.info;
        label = 'Dikembalikan';
        break;
      default:
        bg = AppColors.bgLight;
        text = AppColors.textSecondary;
        label = status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTypography.bodySmall.copyWith(
          color: text,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

