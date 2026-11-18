import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../products/presentation/product_notifier.dart';
import '../snap_webview_screen.dart';
import '../wallet_notifier.dart';

class QuickTopUpSheet extends ConsumerWidget {
  const QuickTopUpSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const QuickTopUpSheet(),
    );
  }

  static const List<int> _nominals = [
    2000000, // 20k
    5000000, // 50k
    10000000, // 100k
    20000000, // 200k
    50000000, // 500k
    100000000, // 1jt
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeNotifierProvider);
    final walletState = ref.watch(walletNotifierProvider);
    final balanceDisplay = homeState.isBalanceHidden
        ? '••••••••'
        : (homeState.data?.balanceDisplay ?? 'Rp 250.000');

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
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
          const SizedBox(height: 14),

          // Header with Close
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accentMint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.add_card, color: AppColors.accentEmeraldDark, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Top Up Saldo Instan', style: AppTypography.titleLarge),
                      Text('Saldo saat ini: $balanceDisplay', style: AppTypography.bodySmall),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textSecondary),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),

          const Divider(height: 24),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PILIH NOMINAL DEPOSIT', style: AppTypography.labelSmall.copyWith(letterSpacing: 1.1)),
                  const SizedBox(height: 12),

                  // Grid Nominal Chips
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _nominals.map((nominal) {
                      final isSelected = walletState.selectedNominalCents == nominal;
                      final nominalRp = nominal ~/ 100;
                      final label = 'Rp ${nominalRp >= 1000000 ? '${nominalRp ~/ 1000000} Juta' : '${nominalRp ~/ 1000} Ribu'}';

                      return InkWell(
                        onTap: () {
                          ref.read(walletNotifierProvider.notifier).selectNominal(nominal);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: (MediaQuery.of(context).size.width - 60) / 3,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.accentMint : AppColors.surfaceWhite,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppColors.accentEmeraldDark : AppColors.borderLight,
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              label,
                              style: AppTypography.labelMedium.copyWith(
                                color: isSelected ? AppColors.accentEmeraldDark : AppColors.textPrimary,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),
                  Text('METODE PEMBAYARAN', style: AppTypography.labelSmall.copyWith(letterSpacing: 1.1)),
                  const SizedBox(height: 12),

                  // Daftar Channel Pembayaran
                  ...walletState.channelGroups.map((group) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.groupName,
                          style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        ...group.items.map((channel) {
                          final isSelected = walletState.selectedChannel?.code == channel.code;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceWhite,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? AppColors.accentEmeraldDark : AppColors.borderLight,
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: ListTile(
                                onTap: () {
                                  ref.read(walletNotifierProvider.notifier).selectChannel(channel);
                                },
                                leading: Icon(
                                  channel.code.contains('va') ? Icons.account_balance : Icons.qr_code,
                                  color: AppColors.primaryNavy,
                                ),
                                title: Text(channel.name, style: AppTypography.titleMedium),
                                subtitle: Text('Biaya Admin: ${channel.feeDisplay}', style: AppTypography.bodySmall),
                                trailing: isSelected
                                    ? Icon(Icons.check_circle, color: AppColors.accentEmeraldDark)
                                    : const Icon(Icons.radio_button_unchecked, color: AppColors.textTertiary),
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 8),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Tombol Lanjutkan Top Up
          CustomButton(
            text: 'Bayar Deposit Sekarang',
            backgroundColor: AppColors.accentEmerald,
            isLoading: walletState.isLoading,
            onPressed: () async {
              final topupResult = await ref.read(walletNotifierProvider.notifier).proceedTopup();
              if (topupResult != null && context.mounted) {
                final isSuccess = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (context) => SnapWebviewScreen(paymentUrl: topupResult.paymentUrl),
                  ),
                );

                if (isSuccess == true && context.mounted) {
                  Navigator.of(context).pop(); // Tutup bottomsheet
                  ref.read(homeNotifierProvider.notifier).fetchDashboard();
                  ref.read(walletNotifierProvider.notifier).fetchMutations();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.accentEmeraldDark,
                      content: const Text('Pembayaran berhasil! Saldo dompet Anda telah bertambah.'),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

