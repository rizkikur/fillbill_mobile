import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/state_views.dart';
import '../../auth/presentation/auth_notifier.dart';
import '../../products/presentation/product_notifier.dart';
import '../domain/wallet_entity.dart';
import 'wallet_notifier.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  String _selectedFilter = 'all'; // 'all', 'credit', 'debit'

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeNotifierProvider);
    final walletState = ref.watch(walletNotifierProvider);
    final authState = ref.watch(authNotifierProvider);

    final balanceDisplay = homeState.isBalanceHidden
        ? '••••••••'
        : (homeState.data?.balanceDisplay ?? 'Rp 250.000');

    final user = authState.user;
    final isAgent = user?.tier == 'agent' || user?.tier == 'agen';
    final userPhone = user?.phone ?? '-';

    // Calculate dynamic totals for Credit & Debit
    int totalCreditCents = 0;
    int totalDebitCents = 0;
    for (final m in walletState.mutations) {
      if (m.type == 'credit') {
        totalCreditCents += m.amountCents;
      } else if (m.type == 'debit') {
        totalDebitCents += m.amountCents;
      }
    }

    // Filter mutations
    final filteredMutations = walletState.mutations.where((m) {
      if (_selectedFilter == 'credit') return m.type == 'credit';
      if (_selectedFilter == 'debit') return m.type == 'debit';
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Dompet Saya',
          style: AppTypography.displayMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(homeNotifierProvider.notifier).fetchDashboard();
          await ref.read(walletNotifierProvider.notifier).fetchMutations();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Kartu Rekening Finansial (Saldo Card)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryNavy, AppColors.primaryNavyDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryNavy.withValues(alpha: 0.28),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Baris Status & Nomor Akun / Salin
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isAgent
                                ? AppColors.warning.withValues(alpha: 0.25)
                                : AppColors.accentEmerald.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isAgent ? Icons.star_rounded : Icons.verified_user_rounded,
                                size: 13,
                                color: isAgent ? AppColors.warning : AppColors.accentEmeraldLight,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                isAgent ? 'Rekening Agen' : 'Rekening Utama',
                                style: AppTypography.labelSmall.copyWith(
                                  color: isAgent ? AppColors.warning : AppColors.accentEmeraldLight,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Tombol Mata Sembunyikan Saldo
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            homeState.isBalanceHidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                            color: Colors.white.withValues(alpha: 0.85),
                            size: 20,
                          ),
                          onPressed: () {
                            ref.read(homeNotifierProvider.notifier).toggleBalanceVisibility();
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Label & Nominal Saldo
                    Text(
                      'Saldo Aktif FillBill',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      balanceDisplay,
                      style: AppTypography.moneyText.copyWith(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    // Baris Nomor Akun & Tombol Salin
                    if (userPhone.isNotEmpty && userPhone != '-') ...[
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: userPhone));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Nomor akun disalin ke clipboard'),
                              duration: Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'No. Akun: $userPhone',
                                style: AppTypography.bodySmall.copyWith(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.copy_rounded,
                                size: 12,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                    Divider(color: Colors.white.withValues(alpha: 0.15), height: 1),
                    const SizedBox(height: 14),

                    // Footer Kartu: Limit BI & Tombol Top Up Lebih Lebar/Tinggi (46px)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Limit Bulanan BI',
                              style: AppTypography.bodySmall.copyWith(
                                color: Colors.white.withValues(alpha: 0.65),
                                fontSize: 10.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Rp 20.000.000 / bln',
                              style: AppTypography.labelSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),

                        // Tombol Top Up yang Lebih Kokoh, Tebal & Nyaman Ditekan (Height 46)
                        SizedBox(
                          height: 46,
                          child: ElevatedButton.icon(
                            key: const Key('wallet_topup_button'),
                            onPressed: () => context.push('/topup'),
                            icon: const Icon(Icons.add_circle_rounded, size: 18),
                            label: Text(
                              'Top Up',
                              style: AppTypography.labelLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentEmerald,
                              foregroundColor: Colors.white,
                              elevation: 3,
                              padding: const EdgeInsets.symmetric(horizontal: 22),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 2. Ringkasan Finansial: Uang Masuk & Uang Keluar (Dihitung Dinamis)
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWhite,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderLight),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            height: 38,
                            width: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.arrow_downward_rounded,
                              color: Color(0xFF059669),
                              size: 19,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Uang Masuk',
                                  style: AppTypography.bodySmall.copyWith(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  totalCreditCents > 0
                                      ? '+ ${CurrencyFormatter.formatCents(totalCreditCents)}'
                                      : '+ Rp. 0',
                                  style: AppTypography.labelMedium.copyWith(
                                    color: const Color(0xFF059669),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWhite,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderLight),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            height: 38,
                            width: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF1F2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.arrow_upward_rounded,
                              color: Color(0xFFE11D48),
                              size: 19,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Uang Keluar',
                                  style: AppTypography.bodySmall.copyWith(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  totalDebitCents > 0
                                      ? '- ${CurrencyFormatter.formatCents(totalDebitCents)}'
                                      : '- Rp. 0',
                                  style: AppTypography.labelMedium.copyWith(
                                    color: const Color(0xFFE11D48),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 3. Header Riwayat Mutasi & Total Transaksi
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Riwayat Mutasi',
                    style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${filteredMutations.length} Mutasi',
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 4. Segmented Control Filter Tabs (Full Width, Simetris, Tidak Pernah Terpotong)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSegmentTab(
                        label: 'Semua',
                        filterValue: 'all',
                        icon: Icons.list_alt_rounded,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _buildSegmentTab(
                        label: 'Masuk',
                        filterValue: 'credit',
                        statusDotColor: const Color(0xFF059669),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _buildSegmentTab(
                        label: 'Keluar',
                        filterValue: 'debit',
                        statusDotColor: const Color(0xFFE11D48),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 5. Daftar Item Mutasi
              if (walletState.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                )
              else if (filteredMutations.isEmpty)
                const EmptyDataView(
                  title: 'Belum Ada Riwayat Mutasi',
                  message: 'Seluruh mutasi debit dan kredit dompet Anda akan tercatat lengkap dan aman di sini.',
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredMutations.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = filteredMutations[index];
                    return _buildMutationCard(item);
                  },
                ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentTab({
    required String label,
    required String filterValue,
    IconData? icon,
    Color? statusDotColor,
  }) {
    final isSelected = _selectedFilter == filterValue;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = filterValue;
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryNavy : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryNavy.withValues(alpha: 0.22),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
            ] else if (statusDotColor != null) ...[
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : statusDotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMutationCard(WalletMutationEntity item) {
    final isCredit = item.type == 'credit';
    final isRefund = item.referenceType.toLowerCase() == 'refund';

    // Icon & Color styling based on mutation type
    final Color bgColor = isCredit
        ? const Color(0xFFECFDF5)
        : (isRefund ? const Color(0xFFEFF6FF) : const Color(0xFFFFF1F2));
    final Color iconColor = isCredit
        ? const Color(0xFF059669)
        : (isRefund ? const Color(0xFF2563EB) : const Color(0xFFE11D48));
    final IconData icon = isCredit
        ? Icons.add_circle_outline_rounded
        : (isRefund ? Icons.replay_rounded : Icons.remove_circle_outline_rounded);

    final title = item.note?.isNotEmpty == true
        ? item.note!
        : (isCredit ? 'Top Up Saldo' : (isRefund ? 'Pengembalian Dana' : 'Pembayaran Tagihan'));

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '${_formatRefLabel(item.referenceType, item.id)} • ${_formatDate(item.createdAt)}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
                  ),
                  child: Text(
                    'Sisa: ${CurrencyFormatter.clean(item.balanceAfterDisplay)}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isCredit ? '+ ${CurrencyFormatter.clean(item.amountDisplay)}' : '- ${CurrencyFormatter.clean(item.amountDisplay)}',
            style: AppTypography.labelLarge.copyWith(
              color: isCredit ? const Color(0xFF059669) : const Color(0xFFE11D48),
              fontWeight: FontWeight.w800,
              fontSize: 13.5,
            ),
          ),
        ],
      ),
    );
  }

  String _formatRefLabel(String refType, int id) {
    final typeUpper = refType.toUpperCase();
    if (typeUpper.contains('TOPUP') || typeUpper.contains('DEPOSIT')) {
      return 'Top Up #$id';
    } else if (typeUpper.contains('TRANSACTION')) {
      return 'Trx #$id';
    } else if (typeUpper.contains('REFUND')) {
      return 'Refund #$id';
    }
    return 'Ref #$id';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Hari ini';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
