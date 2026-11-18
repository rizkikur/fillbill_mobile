import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/status_badge.dart';
import '../../auth/presentation/auth_notifier.dart';
import '../../products/domain/product_entity.dart';
import '../../products/presentation/product_notifier.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeNotifierProvider.notifier).fetchDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final homeState = ref.watch(homeNotifierProvider);
    final userName = authState.user?.name.isNotEmpty == true ? authState.user!.name : 'Budi Santoso';
    final balanceDisplay = homeState.isBalanceHidden
        ? '••••••••'
        : CurrencyFormatter.clean(homeState.data?.balanceDisplay ?? 'Rp. 250.000');

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(homeNotifierProvider.notifier).fetchDashboard();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, userName),
                const SizedBox(height: 20),
                _buildBalanceCard(context, ref, balanceDisplay, homeState.isBalanceHidden),
                const SizedBox(height: 24),
                _buildCategoryGrid(context),
                const SizedBox(height: 28),
                _buildRecentTransactions(context, homeState.data?.recentTransactions ?? []),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String name) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Halo, Selamat Datang! 👋', style: AppTypography.bodySmall),
              const SizedBox(height: 2),
              Text(name, style: AppTypography.titleLarge, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        InkWell(
          onTap: () => context.push('/notifications'),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderLight),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.notifications_none_rounded,
                  size: 22,
                  color: AppColors.primaryNavy,
                ),
                Positioned(
                  top: 10,
                  right: 11,
                  child: Container(
                    height: 8,
                    width: 8,
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surfaceWhite, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard(BuildContext context, WidgetRef ref, String balance, bool isHidden) {
    final cardBg = AppColors.primaryNavy;
    final isLightCard = cardBg.computeLuminance() > 0.42;
    final cardTextColor = isLightCard ? const Color(0xFF0F172A) : AppColors.textWhite;
    final cardSubtextColor = isLightCard ? const Color(0xFF334155) : AppColors.textTertiary;
    final iconColor = isLightCard ? const Color(0xFF0F172A) : AppColors.textWhite;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: cardBg.withValues(alpha: isLightCard ? 0.35 : 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Saldo Dompet FillBill',
                style: AppTypography.bodyMedium.copyWith(
                  color: cardSubtextColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  isHidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: iconColor,
                  size: 20,
                ),
                onPressed: () {
                  ref.read(homeNotifierProvider.notifier).toggleBalanceVisibility();
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            balance,
            style: AppTypography.moneyText.copyWith(
              color: cardTextColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    key: const Key('home_topup_button'),
                    onPressed: () => context.push('/topup'),
                    icon: Icon(
                      Icons.add_circle_outline,
                      size: 18,
                      color: isLightCard ? const Color(0xFF0F172A) : AppColors.textWhite,
                    ),
                    label: Text(
                      'Top Up',
                      style: AppTypography.labelLarge.copyWith(
                        color: isLightCard ? const Color(0xFF0F172A) : AppColors.textWhite,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLightCard ? Colors.white : AppColors.accentEmerald,
                      foregroundColor: isLightCard ? const Color(0xFF0F172A) : AppColors.textWhite,
                      elevation: isLightCard ? 2 : 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/wallet'),
                    icon: Icon(
                      Icons.history_rounded,
                      size: 18,
                      color: isLightCard ? const Color(0xFF0F172A) : AppColors.textWhite,
                    ),
                    label: Text(
                      'Riwayat',
                      style: AppTypography.labelLarge.copyWith(
                        color: isLightCard ? const Color(0xFF0F172A) : AppColors.textWhite,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLightCard
                          ? Colors.white.withValues(alpha: 0.85)
                          : Colors.white.withValues(alpha: 0.12),
                      foregroundColor: isLightCard ? const Color(0xFF0F172A) : AppColors.textWhite,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      side: BorderSide(
                        color: isLightCard
                            ? Colors.black.withValues(alpha: 0.08)
                            : Colors.white.withValues(alpha: 0.18),
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid(BuildContext context) {
    final categories = [
      {'name': 'Pulsa', 'code': 'pulsa', 'icon': Icons.phone_android, 'color': Colors.blue},
      {'name': 'Paket Data', 'code': 'paket_data', 'icon': Icons.wifi, 'color': Colors.indigo},
      {'name': 'Token PLN', 'code': 'token_listrik', 'icon': Icons.bolt, 'color': Colors.amber},
      {'name': 'Tagihan PLN', 'code': 'tagihan_listrik', 'icon': Icons.receipt_long, 'color': Colors.orange},
      {'name': 'E-Money', 'code': 'emoney', 'icon': Icons.account_balance_wallet, 'color': Colors.teal},
      {'name': 'PDAM Air', 'code': 'pdam', 'icon': Icons.water_drop, 'color': Colors.lightBlue},
      {'name': 'BPJS', 'code': 'bpjs', 'icon': Icons.health_and_safety, 'color': Colors.green},
      {'name': 'Voucher Game', 'code': 'game', 'icon': Icons.sports_esports, 'color': Colors.purple},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Layanan PPOB', style: AppTypography.titleMedium),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 16,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemBuilder: (context, index) {
            final cat = categories[index];
            return InkWell(
              onTap: () {
                final code = cat['code'] as String;
                switch (code) {
                  case 'token_listrik':
                    context.push('/transaction/pln?type=token');
                    break;
                  case 'tagihan_listrik':
                    context.push('/transaction/pln?type=tagihan');
                    break;
                  case 'emoney':
                    context.push('/transaction/emoney');
                    break;
                  case 'pdam':
                    context.push('/transaction/bill?service=pdam');
                    break;
                  case 'bpjs':
                    context.push('/transaction/bill?service=bpjs');
                    break;
                  case 'game':
                    context.push('/transaction/game');
                    break;
                  case 'pulsa':
                  case 'paket_data':
                  default:
                    context.push('/transaction/prepaid?category=$code');
                    break;
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Column(
                children: [
                  Container(
                    height: 52,
                    width: 52,
                    decoration: BoxDecoration(
                      color: (cat['color'] as Color).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(cat['icon'] as IconData, color: cat['color'] as Color, size: 26),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    cat['name'] as String,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentTransactions(BuildContext context, List<HomeRecentTransaction> recentList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Transaksi Terkini', style: AppTypography.titleMedium),
            TextButton(
              onPressed: () => context.go('/transactions'),
              child: Text(
                'Lihat Semua',
                style: AppTypography.labelMedium.copyWith(color: AppColors.accentEmeraldDark),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (recentList.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Center(
              child: Text(
                'Belum ada transaksi terkini',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentList.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final tx = recentList[index];
              final cleanPrice = CurrencyFormatter.clean(tx.sellPriceDisplay);
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Row(
                  children: [
                    Container(
                      height: 44,
                      width: 44,
                      decoration: BoxDecoration(
                        color: AppColors.accentMint,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.receipt_long_rounded, color: AppColors.accentEmeraldDark),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tx.productName,
                            style: AppTypography.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            tx.customerNumber,
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(cleanPrice, style: AppTypography.labelLarge),
                        const SizedBox(height: 4),
                        StatusBadge(status: tx.status),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
