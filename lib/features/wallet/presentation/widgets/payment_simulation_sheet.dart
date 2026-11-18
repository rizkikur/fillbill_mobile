import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../products/presentation/product_notifier.dart';
import '../../data/mock_wallet_store.dart';
import '../../domain/wallet_entity.dart';
import '../wallet_notifier.dart';

/// Modal bottom sheet simulating realistic payment gateway instructions
/// and enabling zero-network top-up verification in mockup mode.
class PaymentSimulationSheet extends ConsumerWidget {
  final int nominalCents;
  final TopupChannelEntity channel;

  const PaymentSimulationSheet({
    super.key,
    required this.nominalCents,
    required this.channel,
  });

  /// Displays the simulation bottom sheet modally.
  static Future<bool?> show(
    BuildContext context, {
    required int nominalCents,
    required TopupChannelEntity channel,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PaymentSimulationSheet(
        nominalCents: nominalCents,
        channel: channel,
      ),
    );
  }

  String _resolvePaymentNumber() {
    if (channel.accountNumber != null && channel.accountNumber!.isNotEmpty) {
      return channel.accountNumber!;
    }
    if (channel.code.contains('va')) {
      return '8808 0812 3456 7890';
    }
    if (channel.code.contains('manual')) {
      return '1234567890';
    }
    return 'QRIS-SIM-1082938';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int feeCents = channel.calculateFeeCents(nominalCents);
    final int totalCents = nominalCents + feeCents;
    final String paymentNumber = _resolvePaymentNumber();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle Indicator
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

            // Header Row with Neo-Green Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.neoGreenSurface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.neoGreen),
                      ),
                      child: const Icon(
                        Icons.bolt_rounded,
                        color: AppColors.neoGreenDark,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Instruksi Pembayaran',
                      style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.neoGreenSurface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.neoGreen),
                  ),
                  child: Text(
                    'Mode Simulasi',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.neoGreenContrast,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.borderLight),
            const SizedBox(height: 16),

            // Channel & Account Info Container
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.bgLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          channel.name,
                          style: AppTypography.labelLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 20,
                        color: AppColors.primaryNavy,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Kode / Nomor Pembayaran:',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          paymentNumber,
                          style: AppTypography.moneyText.copyWith(
                            fontSize: 16,
                            color: AppColors.primaryNavy,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: paymentNumber.replaceAll(' ', '')));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Nomor pembayaran disalin!'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Text(
                            'Salin',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.primaryNavy,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Payment Breakdown Table
            _buildSummaryRow(
              'Nominal Deposit',
              CurrencyFormatter.formatCents(nominalCents),
            ),
            const SizedBox(height: 8),
            _buildSummaryRow(
              'Biaya Admin',
              feeCents == 0 ? 'Gratis' : CurrencyFormatter.formatCents(feeCents),
            ),
            const SizedBox(height: 8),
            const Divider(height: 12, color: AppColors.borderLight),
            _buildSummaryRow(
              'Total Pembayaran',
              CurrencyFormatter.formatCents(totalCents),
              isBold: true,
            ),
            const SizedBox(height: 18),

            // Simulation Mode Notice Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.neoGreenSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.neoGreenLight),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppColors.neoGreenDark,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Mode simulasi aktif. Tapping tombol di bawah akan mengkreditkan saldo secara instan ke dompet Anda tanpa pemotongan uang riil.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.neoGreenContrast,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Action Button: "Simulasikan Pembayaran Berhasil"
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                key: const Key('topup_simulation_pay_button'),
                onPressed: () async {
                  // 1. Mutate in-memory store
                  MockWalletStore.instance.addTopup(
                    amountCents: nominalCents,
                    channelCode: channel.code,
                    channelName: channel.name,
                  );

                  // 2. Synchronize Riverpod state
                  await ref.read(homeNotifierProvider.notifier).fetchDashboard();
                  await ref.read(walletNotifierProvider.notifier).fetchMutations();

                  // 3. Dismiss bottom sheet with success
                  if (context.mounted) {
                    Navigator.of(context).pop(true);
                  }
                },
                icon: const Icon(Icons.check_circle_rounded, color: AppColors.neoGreenContrast),
                label: Text(
                  'Simulasikan Pembayaran Berhasil',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.neoGreenContrast,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neoGreen,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isBold
              ? AppTypography.labelMedium.copyWith(fontWeight: FontWeight.bold)
              : AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: isBold
              ? AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryNavy,
                )
              : AppTypography.labelSmall.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
