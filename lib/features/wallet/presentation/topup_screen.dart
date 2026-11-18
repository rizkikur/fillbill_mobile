import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/config/brand_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/rupiah_input_formatter.dart';
import '../../products/presentation/product_notifier.dart';
import '../data/mock_wallet_store.dart';
import '../data/wallet_repository.dart';
import '../domain/wallet_entity.dart';
import 'wallet_notifier.dart';
import 'widgets/payment_simulation_sheet.dart';

/// Full Top Up Screen for FillBill Mobile (Milestone 3).
/// Supports preset nominal chips, custom Rupiah text field with real-time formatting,
/// categorized payment channels, live fee/total calculation, and simulation dialog.
class TopupScreen extends ConsumerStatefulWidget {
  const TopupScreen({super.key});

  @override
  ConsumerState<TopupScreen> createState() => _TopupScreenState();
}

class _TopupScreenState extends ConsumerState<TopupScreen> {
  late final TextEditingController _amountController;
  final FocusNode _amountFocusNode = FocusNode();

  // 6 Quick-Pick Nominal Presets (in cents: rupiah * 100)
  static const List<int> presetNominals = [
    2000000,   // Rp 20.000
    5000000,   // Rp 50.000
    10000000,  // Rp 100.000
    20000000,  // Rp 200.000
    50000000,  // Rp 500.000
    100000000, // Rp 1.000.000
  ];

  static const Map<int, Key> chipKeys = {
    2000000: Key('topup_chip_20000'),
    5000000: Key('topup_chip_50000'),
    10000000: Key('topup_chip_100000'),
    20000000: Key('topup_chip_200000'),
    50000000: Key('topup_chip_500000'),
    100000000: Key('topup_chip_1000000'),
  };

  static const int minNominalCents = 1000000;    // Rp 10.000
  static const int maxNominalCents = 1000000000; // Rp 10.000.000

  @override
  void initState() {
    super.initState();
    final initialCents = ref.read(walletNotifierProvider).selectedNominalCents;
    final initialRupiah = initialCents ~/ 100;
    _amountController = TextEditingController(
      text: initialRupiah > 0 ? RupiahInputFormatter.format(initialRupiah) : '',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  void _onChipSelected(int cents) {
    ref.read(walletNotifierProvider.notifier).selectNominal(cents);
    final rupiah = cents ~/ 100;
    _amountController.text = RupiahInputFormatter.format(rupiah);
    _amountFocusNode.unfocus();
  }

  void _onAmountChanged(String value) {
    final rupiah = RupiahInputFormatter.parseRupiah(value);
    final cents = rupiah * 100;
    ref.read(walletNotifierProvider.notifier).selectNominal(cents);
  }

  void _clearAmount() {
    _amountController.clear();
    ref.read(walletNotifierProvider.notifier).selectNominal(0);
  }

  String? _getValidationMessage(int cents) {
    if (cents == 0) return null;
    if (cents < minNominalCents) {
      return 'Minimal top up Rp 10.000';
    }
    if (cents > maxNominalCents) {
      return 'Maksimal top up Rp 10.000.000';
    }
    return null;
  }

  bool _isAmountValid(int cents) {
    return cents >= minNominalCents && cents <= maxNominalCents;
  }

  int _calculateFeeCents(TopupChannelEntity? channel, int nominalCents) {
    if (channel == null) return 0;
    return channel.calculateFeeCents(nominalCents);
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeNotifierProvider);
    final walletState = ref.watch(walletNotifierProvider);

    // Dynamic Balance calculation
    final rawBalance = AppConfig.isMockupEnabled
        ? MockWalletStore.instance.balanceDisplay
        : (homeState.data?.balanceDisplay ?? 'Rp 250.000');
    final activeBalance = homeState.isBalanceHidden ? '••••••••' : rawBalance;

    final currentCents = walletState.selectedNominalCents;
    final validationError = _getValidationMessage(currentCents);
    final isValid = _isAmountValid(currentCents);

    // Channel fallback: use standard catalog if provider channelGroups not loaded yet
    final channelGroups = walletState.channelGroups.isNotEmpty
        ? walletState.channelGroups
        : WalletRepository.standardChannelGroups;

    final selectedChannel = walletState.selectedChannel ??
        (channelGroups.isNotEmpty && channelGroups.first.items.isNotEmpty
            ? channelGroups.first.items.first
            : null);

    final feeCents = _calculateFeeCents(selectedChannel, currentCents);
    final totalPaymentCents = isValid ? currentCents + feeCents : 0;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        leading: IconButton(
          key: const Key('topup_back_button'),
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(
          'Top Up Saldo',
          style: AppTypography.titleLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.surfaceWhite,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Balance Header Card
            _buildBalanceHeaderCard(activeBalance, homeState.isBalanceHidden),

            const SizedBox(height: 24),

            // 2. Section Header: Pilih Nominal
            Text(
              'Pilih Nominal Top Up',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Pilih nominal cepat atau masukkan jumlah sendiri',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 14),

            // 3. Quick-Pick Nominal Chips Grid (2x3)
            _buildNominalChipsGrid(currentCents),

            const SizedBox(height: 20),

            // 4. Custom Amount Input Field with Rupiah Formatter
            _buildCustomAmountField(validationError, isValid, currentCents),

            const SizedBox(height: 24),

            // 5. Payment Channel Selection Section
            _buildPaymentChannelSection(channelGroups, selectedChannel),

            const SizedBox(height: 24),

            // 6. Payment Summary Card
            _buildPaymentSummaryCard(
              nominalCents: currentCents,
              feeCents: feeCents,
              totalCents: totalPaymentCents,
              channel: selectedChannel,
              isValid: isValid,
            ),

            const SizedBox(height: 100), // Spacing for sticky CTA
          ],
        ),
      ),
      bottomNavigationBar: _buildStickyBottomCta(
        totalPaymentCents: totalPaymentCents,
        isValid: isValid && selectedChannel != null,
        isLoading: walletState.isLoading,
        onPressed: selectedChannel != null
            ? () => _handleProceedPayment(context, selectedChannel, currentCents)
            : () {},
      ),
    );
  }

  Widget _buildBalanceHeaderCard(String balance, bool isHidden) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryNavy, AppColors.primaryNavyDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryNavy.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.neoGreen.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: AppColors.neoGreen,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Saldo Dompet Aktif',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              IconButton(
                key: const Key('topup_toggle_balance_button'),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  isHidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: Colors.white.withValues(alpha: 0.85),
                  size: 20,
                ),
                onPressed: () {
                  ref.read(homeNotifierProvider.notifier).toggleBalanceVisibility();
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            balance,
            key: const Key('topup_header_balance'),
            style: AppTypography.moneyText.copyWith(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Limit transaksi s/d Rp 20.000.000/bln',
              style: AppTypography.labelSmall.copyWith(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 10.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNominalChipsGrid(int selectedCents) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double itemWidth = (constraints.maxWidth - 20) / 3;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: presetNominals.map((cents) {
            final isSelected = selectedCents == cents;
            final rupiah = cents ~/ 100;
            final label = CurrencyFormatter.format(rupiah);
            final chipKey = chipKeys[cents] ?? Key('topup_chip_$rupiah');

            return InkWell(
              key: chipKey,
              onTap: () => _onChipSelected(cents),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: itemWidth,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.neoGreenSurface : AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.neoGreen : AppColors.borderLight,
                    width: isSelected ? 2.0 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          const BoxShadow(
                            color: AppColors.neoGreenGlow,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isSelected) ...[
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 13,
                            color: AppColors.neoGreenDark,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Flexible(
                          child: Text(
                            label,
                            style: AppTypography.labelMedium.copyWith(
                              color: isSelected
                                  ? AppColors.neoGreenContrast
                                  : AppColors.textPrimary,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              fontSize: 12.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildCustomAmountField(
    String? validationError,
    bool isValid,
    int currentCents,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Atau Masukkan Nominal Sendiri',
          style: AppTypography.labelMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          key: const Key('topup_nominal_input'),
          controller: _amountController,
          focusNode: _amountFocusNode,
          keyboardType: TextInputType.number,
          inputFormatters: [RupiahInputFormatter()],
          onChanged: _onAmountChanged,
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Rp 0',
            filled: true,
            fillColor: AppColors.surfaceWhite,
            prefixIcon: const Icon(
              Icons.edit_note_rounded,
              color: AppColors.textSecondary,
              size: 22,
            ),
            suffixIcon: _amountController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.cancel_rounded, size: 18, color: AppColors.textTertiary),
                    onPressed: _clearAmount,
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: validationError != null ? AppColors.error : AppColors.borderLight,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: validationError != null
                    ? AppColors.error
                    : (isValid ? AppColors.accentEmerald : AppColors.borderLight),
                width: isValid ? 1.5 : 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: validationError != null ? AppColors.error : AppColors.primaryNavy,
                width: 2.0,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        if (validationError != null)
          Container(
            key: const Key('topup_validation_warning'),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 14),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    validationError,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.error,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Minimal Rp 10.000',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              Text(
                'Maksimal Rp 10.000.000',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildPaymentChannelSection(
    List<TopupGroupEntity> channelGroups,
    TopupChannelEntity? selectedChannel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Metode Pembayaran',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Pilihan Tersedia',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...channelGroups.map((group) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  group.groupName,
                  style: AppTypography.labelSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              ...group.items.map((channel) {
                final isSelected = selectedChannel?.code == channel.code;
                final channelKey = Key('topup_channel_${channel.code}');

                return Container(
                  key: channelKey,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.neoGreenSurface : AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.neoGreen : AppColors.borderLight,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: ListTile(
                    dense: true,
                    onTap: () {
                      ref.read(walletNotifierProvider.notifier).selectChannel(channel);
                    },
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.neoGreenLight : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        channel.code.contains('va')
                            ? Icons.account_balance_rounded
                            : (channel.code.contains('manual')
                                ? Icons.payments_outlined
                                : Icons.qr_code_2_rounded),
                        color: isSelected ? AppColors.neoGreenContrast : AppColors.primaryNavy,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      channel.name,
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      'Biaya: ${channel.feeDisplay}',
                      style: AppTypography.bodySmall.copyWith(fontSize: 11),
                    ),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.neoGreenDark,
                            size: 22,
                          )
                        : const Icon(
                            Icons.radio_button_unchecked_rounded,
                            color: AppColors.textTertiary,
                            size: 22,
                          ),
                    ),
                  ),
                );
              }),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildPaymentSummaryCard({
    required int nominalCents,
    required int feeCents,
    required int totalCents,
    required TopupChannelEntity? channel,
    required bool isValid,
  }) {
    return Container(
      key: const Key('topup_summary_card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ringkasan Pembayaran',
            style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildSummaryRow(
            'Nominal Isi Ulang',
            isValid ? CurrencyFormatter.formatCents(nominalCents) : 'Rp 0',
            valueKey: const Key('topup_summary_nominal'),
          ),
          const SizedBox(height: 8),
          _buildSummaryRow(
            'Metode Pembayaran',
            channel?.name ?? 'Belum dipilih',
          ),
          const SizedBox(height: 8),
          _buildSummaryRow(
            'Biaya Transaksi / Admin',
            isValid && channel != null ? channel.feeDisplay : 'Rp 0',
            valueKey: const Key('topup_summary_fee'),
          ),
          const Divider(height: 20, color: AppColors.borderLight),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Pembayaran',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                isValid && channel != null
                    ? CurrencyFormatter.formatCents(totalCents)
                    : 'Rp 0',
                key: const Key('topup_summary_total'),
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryNavy,
                  fontSize: 16.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Key? valueKey}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        Text(
          value,
          key: valueKey,
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildStickyBottomCta({
    required int totalPaymentCents,
    required bool isValid,
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
        border: const Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Tagihan',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    isValid ? CurrencyFormatter.formatCents(totalPaymentCents) : 'Rp 0',
                    style: AppTypography.labelLarge.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryNavy,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 6,
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  key: const Key('topup_continue_button'),
                  onPressed: isValid && !isLoading ? onPressed : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BrandConfig.primaryColor,
                    disabledBackgroundColor: const Color(0xFFCBD5E1),
                    elevation: isValid ? 2 : 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Lanjutkan Pembayaran',
                          style: AppTypography.labelMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleProceedPayment(
    BuildContext context,
    TopupChannelEntity channel,
    int currentCents,
  ) async {
    if (AppConfig.isMockupEnabled) {
      final success = await PaymentSimulationSheet.show(
        context,
        nominalCents: currentCents,
        channel: channel,
      );

      if (success == true && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primaryNavy,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.neoGreen),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Top Up ${CurrencyFormatter.formatCents(currentCents)} Berhasil! Saldo telah bertambah.',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else {
      final topupResult = await ref.read(walletNotifierProvider.notifier).proceedTopup();
      if (topupResult != null && context.mounted) {
        if (topupResult.paymentUrl.isNotEmpty) {
          await ref.read(homeNotifierProvider.notifier).fetchDashboard();
          await ref.read(walletNotifierProvider.notifier).fetchMutations();
        }
      }
    }
  }
}
