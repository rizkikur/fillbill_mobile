import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/custom_button.dart';
import '../../products/presentation/product_notifier.dart';
import '../../wallet/presentation/wallet_notifier.dart';
import 'transaction_notifier.dart';

class ProcessingPaymentDialog extends ConsumerStatefulWidget {
  final BuildContext parentContext;

  const ProcessingPaymentDialog({
    super.key,
    required this.parentContext,
  });

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (dialogContext) => ProcessingPaymentDialog(parentContext: context),
    );
  }

  @override
  ConsumerState<ProcessingPaymentDialog> createState() => _ProcessingPaymentDialogState();
}

class _ProcessingPaymentDialogState extends ConsumerState<ProcessingPaymentDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _hasCompleted = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onSuccess(TransactionExecutionState state) {
    if (_hasCompleted) return;
    _hasCompleted = true;

    // Refresh saldo dompet dan riwayat mutasi dari backend
    ref.read(homeNotifierProvider.notifier).fetchDashboard();
    ref.read(walletNotifierProvider.notifier).fetchMutations();
    ref.read(transactionHistoryProvider.notifier).fetchHistory();

    // Tunggu 750ms agar animasi sukses terlihat oleh pengguna
    Future.delayed(const Duration(milliseconds: 750), () {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        if (widget.parentContext.mounted && state.transaction != null) {
          widget.parentContext.push('/receipt', extra: state.transaction);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transactionExecutionProvider);

    if (state.status == ExecutionStatus.success && !_hasCompleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _onSuccess(state));
    }

    final isFailed = state.status == ExecutionStatus.failed;
    final isSuccess = state.status == ExecutionStatus.success;

    return PopScope(
      canPop: isFailed,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          width: 340,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Visual Icon & Animation
              _buildAnimatedHeader(state.status),
              const SizedBox(height: 22),

              // Title Text
              Text(
                _getTitle(state.status),
                textAlign: TextAlign.center,
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 19,
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle / Description Text
              Text(
                _getSubtitle(state),
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: isFailed ? AppColors.error : AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // Step Progress Dots (for in-flight states)
              if (!isFailed && !isSuccess) ...[
                _buildStepIndicators(state.status),
                const SizedBox(height: 12),
              ],

              // Close / Retry Button (Only when failed)
              if (isFailed) ...[
                CustomButton(
                  text: 'Tutup',
                  backgroundColor: AppColors.primaryNavy,
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).pop();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedHeader(ExecutionStatus status) {
    if (status == ExecutionStatus.success) {
      return TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 400),
        curve: Curves.elasticOut,
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFDCFCE7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 46,
                color: Color(0xFF10B981),
              ),
            ),
          );
        },
      );
    }

    if (status == ExecutionStatus.failed) {
      return TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 400),
        curve: Curves.elasticOut,
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cancel_rounded,
                size: 46,
                color: AppColors.error,
              ),
            ),
          );
        },
      );
    }

    // Processing / Loading State
    return ScaleTransition(
      scale: _pulseAnimation,
      child: Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          color: AppColors.primaryNavy.withOpacity(0.06),
          shape: BoxShape.circle,
        ),
        padding: const EdgeInsets.all(8),
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                strokeWidth: 3.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryNavy),
                backgroundColor: const Color(0xFFE2E8F0),
              ),
            ),
            Icon(
              _getStatusIcon(status),
              size: 26,
              color: AppColors.primaryNavy,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(ExecutionStatus status) {
    switch (status) {
      case ExecutionStatus.authenticatingPin:
        return Icons.lock_outline_rounded;
      case ExecutionStatus.executing:
        return Icons.currency_exchange_rounded;
      case ExecutionStatus.polling:
        return Icons.sync_rounded;
      default:
        return Icons.credit_card_rounded;
    }
  }

  String _getTitle(ExecutionStatus status) {
    switch (status) {
      case ExecutionStatus.authenticatingPin:
        return 'Memverifikasi PIN';
      case ExecutionStatus.executing:
        return 'Memproses Pembayaran';
      case ExecutionStatus.polling:
        return 'Menghubungkan ke Biller';
      case ExecutionStatus.success:
        return 'Pembayaran Berhasil!';
      case ExecutionStatus.failed:
        return 'Pembayaran Gagal';
      default:
        return 'Sedang Memproses...';
    }
  }

  String _getSubtitle(TransactionExecutionState state) {
    switch (state.status) {
      case ExecutionStatus.authenticatingPin:
        return 'Sedang memvalidasi keamanan dan otorisasi transaksi Anda.';
      case ExecutionStatus.executing:
        return 'Meneruskan instruksi transaksi ke penyedia layanan secara aman.';
      case ExecutionStatus.polling:
        return 'Menunggu konfirmasi nomor seri produk dari sistem operator...';
      case ExecutionStatus.success:
        return 'Transaksi berhasil dikonfirmasi! Membuka bukti pembayaran...';
      case ExecutionStatus.failed:
        return state.errorMessage ?? 'Transaksi tidak dapat diselesaikan saat ini.';
      default:
        return 'Mohon tunggu sebentar, jangan tutup atau keluar dari aplikasi.';
    }
  }

  Widget _buildStepIndicators(ExecutionStatus status) {
    int activeStep = 1;
    if (status == ExecutionStatus.authenticatingPin) {
      activeStep = 1;
    } else if (status == ExecutionStatus.executing) {
      activeStep = 2;
    } else if (status == ExecutionStatus.polling) {
      activeStep = 3;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildDot(activeStep >= 1, 'Otorisasi'),
        _buildConnector(activeStep >= 2),
        _buildDot(activeStep >= 2, 'Pembayaran'),
        _buildConnector(activeStep >= 3),
        _buildDot(activeStep >= 3, 'Biller'),
      ],
    );
  }

  Widget _buildDot(bool isActive, String label) {
    return Column(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primaryNavy : const Color(0xFFCBD5E1),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive ? AppColors.primaryNavy : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildConnector(bool isActive) {
    return Container(
      width: 24,
      height: 2,
      margin: const EdgeInsets.only(bottom: 16, left: 4, right: 4),
      color: isActive ? AppColors.primaryNavy : const Color(0xFFE2E8F0),
    );
  }
}

