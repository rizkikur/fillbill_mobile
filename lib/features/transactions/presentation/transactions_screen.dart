import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_badge.dart';
import '../domain/transaction_entity.dart';
import 'transaction_notifier.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(transactionHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Riwayat Transaksi',
          style: AppTypography.displayMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          // Modern Status Filter Chips Bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildModernFilterPill(
                    context: context,
                    ref: ref,
                    label: 'Semua',
                    filterValue: 'all',
                    currentFilter: state.activeFilter,
                    icon: Icons.grid_view_rounded,
                  ),
                  const SizedBox(width: 8),
                  _buildModernFilterPill(
                    context: context,
                    ref: ref,
                    label: 'Berhasil',
                    filterValue: 'success',
                    currentFilter: state.activeFilter,
                    statusDotColor: AppColors.accentEmerald,
                  ),
                  const SizedBox(width: 8),
                  _buildModernFilterPill(
                    context: context,
                    ref: ref,
                    label: 'Diproses',
                    filterValue: 'processing',
                    currentFilter: state.activeFilter,
                    statusDotColor: Colors.blue.shade500,
                  ),
                  const SizedBox(width: 8),
                  _buildModernFilterPill(
                    context: context,
                    ref: ref,
                    label: 'Gagal',
                    filterValue: 'failed',
                    currentFilter: state.activeFilter,
                    statusDotColor: AppColors.error,
                  ),
                ],
              ),
            ),
          ),

          // Transaction List Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref.read(transactionHistoryProvider.notifier).fetchHistory();
              },
              child: state.isLoading
                  ? ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: 4,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) => const TransactionSkeletonItem(),
                    )
                  : state.transactions.isEmpty
                      ? const EmptyDataView(
                          title: 'Belum Ada Transaksi',
                          message: 'Transaksi pembelian pulsa atau tagihan Anda akan muncul di sini.',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(20),
                          itemCount: state.transactions.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final tx = state.transactions[index];
                            return _buildTransactionCard(context, tx);
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernFilterPill({
    required BuildContext context,
    required WidgetRef ref,
    required String label,
    required String filterValue,
    required String currentFilter,
    IconData? icon,
    Color? statusDotColor,
  }) {
    final isSelected = filterValue == currentFilter;

    return InkWell(
      onTap: () {
        ref.read(transactionHistoryProvider.notifier).fetchHistory(filter: filterValue);
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryNavy : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryNavy : const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryNavy.withValues(alpha: 0.22),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13,
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
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(BuildContext context, TransactionEntity tx) {
    final iconData = _resolveProductIcon(tx.productName, tx.skuCode);

    return InkWell(
      onTap: () {
        context.push('/receipt', extra: tx);
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Bar: Icon Produk + Nama Produk + Status Badge
            Row(
              children: [
                // Lingkaran Ikon Pastel Kategori Produk
                Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    color: iconData.bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(iconData.icon, color: iconData.iconColor, size: 20),
                ),
                const SizedBox(width: 12),

                // Info Produk & Pelanggan
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx.productName,
                        style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${tx.customerNumber} • ${_formatDate(tx.createdAt)}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),
                StatusBadge(status: tx.status),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.borderLight),
            const SizedBox(height: 12),

            // Footer Bar: No. Ref Acak / SN + Nominal Harga + Chevron
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.tag_rounded, size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          tx.providerRef != null ? 'SN: ${tx.providerRef}' : 'Ref: ${tx.displayId}',
                          style: AppTypography.bodySmall.copyWith(
                            fontFamily: 'monospace',
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 11.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  children: [
                    Text(
                      CurrencyFormatter.clean(tx.sellPriceDisplay),
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.primaryNavy,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textSecondary),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  _ProductIconData _resolveProductIcon(String name, String sku) {
    final lower = (name + sku).toLowerCase();

    if (lower.contains('pln') || lower.contains('token') || lower.contains('listrik')) {
      return _ProductIconData(
        icon: Icons.bolt_rounded,
        bgColor: const Color(0xFFFEF3C7),
        iconColor: const Color(0xFFD97706),
      );
    } else if (lower.contains('dana') || lower.contains('ovo') || lower.contains('gopay') || lower.contains('shopee') || lower.contains('linkaja') || lower.contains('emoney') || lower.contains('wallet')) {
      return _ProductIconData(
        icon: Icons.account_balance_wallet_rounded,
        bgColor: const Color(0xFFECFDF5),
        iconColor: const Color(0xFF059669),
      );
    } else if (lower.contains('pdam') || lower.contains('air')) {
      return _ProductIconData(
        icon: Icons.water_drop_rounded,
        bgColor: const Color(0xFFE0F2FE),
        iconColor: const Color(0xFF0284C7),
      );
    } else if (lower.contains('bpjs')) {
      return _ProductIconData(
        icon: Icons.health_and_safety_rounded,
        bgColor: const Color(0xFFF0FDF4),
        iconColor: const Color(0xFF0D9488),
      );
    } else if (lower.contains('game') || lower.contains('mlbb') || lower.contains('free fire') || lower.contains('pubg') || lower.contains('diamond') || lower.contains('genshin')) {
      return _ProductIconData(
        icon: Icons.sports_esports_rounded,
        bgColor: const Color(0xFFF5F3FF),
        iconColor: const Color(0xFF7C3AED),
      );
    } else {
      // Pulsa / Paket Data / Telekomunikasi
      return _ProductIconData(
        icon: Icons.phone_android_rounded,
        bgColor: const Color(0xFFEFF6FF),
        iconColor: const Color(0xFF2563EB),
      );
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '09 Nov 2026';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _ProductIconData {
  final IconData icon;
  final Color bgColor;
  final Color iconColor;

  _ProductIconData({
    required this.icon,
    required this.bgColor,
    required this.iconColor,
  });
}
