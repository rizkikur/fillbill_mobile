import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/mockup_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/custom_bottom_sheet.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/dashed_divider.dart';
import '../../transactions/domain/transaction_entity.dart';
import '../../transactions/presentation/pin_dialog.dart';
import '../../transactions/presentation/receipt_screen.dart';
import 'product_notifier.dart';

class GameVoucherScreen extends ConsumerStatefulWidget {
  const GameVoucherScreen({super.key});

  @override
  ConsumerState<GameVoucherScreen> createState() => _GameVoucherScreenState();
}

class _GameVoucherScreenState extends ConsumerState<GameVoucherScreen> {
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _zoneIdController = TextEditingController();

  final List<Map<String, dynamic>> _games = [
    {'name': 'Mobile Legends', 'code': 'MLBB', 'providerCode': 'mlbb', 'icon': Icons.shield, 'color': Colors.blue},
    {'name': 'Free Fire', 'code': 'FF', 'providerCode': 'freefire', 'icon': Icons.local_fire_department, 'color': Colors.orange},
    {'name': 'PUBG Mobile', 'code': 'PUBG', 'providerCode': 'pubgm', 'icon': Icons.sports_kabaddi, 'color': Colors.amber},
    {'name': 'Genshin Impact', 'code': 'GENSHIN', 'providerCode': 'genshin', 'icon': Icons.auto_awesome, 'color': Colors.purple},
  ];

  late Map<String, dynamic> _selectedGame;

  List<Map<String, dynamic>> _items = [
    {'name': '86 Diamonds Mobile Legends', 'price': 23500, 'priceDisplay': 'Rp 23.500', 'sku': 'MLBB_86'},
    {'name': '172 Diamonds Mobile Legends', 'price': 46500, 'priceDisplay': 'Rp 46.500', 'sku': 'MLBB_172'},
    {'name': '257 Diamonds Mobile Legends', 'price': 69500, 'priceDisplay': 'Rp 69.500', 'sku': 'MLBB_257'},
    {'name': '706 Diamonds Mobile Legends', 'price': 185000, 'priceDisplay': 'Rp 185.000', 'sku': 'MLBB_706'},
    {'name': 'Weekly Diamond Pass', 'price': 28500, 'priceDisplay': 'Rp 28.500', 'sku': 'MLBB_WP'},
  ];

  Map<String, dynamic>? _selectedItem;

  @override
  void initState() {
    super.initState();
    _selectedGame = _games.first;
    final isMockup = ref.read(mockupModeProvider);
    if (isMockup) {
      _userIdController.text = '12894567';
      _zoneIdController.text = '2041';
    } else {
      _userIdController.clear();
      _zoneIdController.clear();
    }
    _loadLiveGameItems();
  }

  Future<void> _loadLiveGameItems() async {
    final repo = ref.read(productRepositoryProvider);
    final providerCode = _selectedGame['providerCode'] ?? 'mlbb';
    final items = await repo.getProducts(category: 'game', provider: providerCode);
    if (items.isNotEmpty && mounted) {
      setState(() {
        _items = items.map((p) => {
          'name': p.name,
          'price': p.sellPriceCents ~/ 100,
          'priceDisplay': p.sellPriceDisplay,
          'sku': p.skuCode,
        }).toList();
        _selectedItem = null;
      });
    }
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _zoneIdController.dispose();
    super.dispose();
  }

  void _showConfirmationSheet(Map<String, dynamic> item, String userId, String zoneId) {
    final target = zoneId.isNotEmpty ? '$userId ($zoneId)' : userId;
    final cleanPrice = CurrencyFormatter.clean(item['priceDisplay']);

    CustomBottomSheet.show(
      context: context,
      title: 'Konfirmasi Top Up ${_selectedGame['name']}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRow('Game', _selectedGame['name']),
          _buildRow('ID Akun / User ID', target),
          _buildRow('Nickname Akun', ref.read(mockupModeProvider) ? 'PRO_PLAYER_99' : 'AKUN ${item['sku'] ?? 'GAME'}'),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 16),
          Text(
            'Detail Pembayaran',
            style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          _buildRow('Harga', cleanPrice),
          _buildRow('Biaya Transaksi', 'Gratis (Rp. 0)'),
          const SizedBox(height: 14),
          const DashedDivider(color: Color(0xFFCBD5E1), dashWidth: 5, dashSpace: 4),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Pembayaran',
                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                cleanPrice,
                style: AppTypography.titleLarge.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.accentEmeraldDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Bayar Sekarang',
            backgroundColor: AppColors.primaryNavy,
            onPressed: () async {
              Navigator.of(context).pop();
              final pin = await PinDialog.show(context);
              if (pin != null && pin.length == 6) {
                if (!context.mounted) return;

                final tempTx = TransactionEntity(
                  id: 0,
                  skuCode: item['sku'],
                  productName: '${item['name']}',
                  customerNumber: '$userId$zoneId',
                  amountCents: item['price'] as int? ?? 0,
                  amountDisplay: cleanPrice,
                  sellPriceCents: item['price'] as int? ?? 0,
                  sellPriceDisplay: cleanPrice,
                  status: 'pending',
                  providerRef: null,
                  createdAt: DateTime.now(),
                );

                context.pushReplacement(
                  '/receipt',
                  extra: ReceiptArgs(
                    transaction: tempTx,
                    pinToExecute: pin,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodySmall),
          Text(value, style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(mockupModeProvider, (previous, next) {
      if (!next && mounted) {
        setState(() {
          _userIdController.clear();
          _zoneIdController.clear();
          _selectedItem = null;
        });
      }
    });
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: const Text('Voucher Game'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pilihan Game Chips
            Text('Pilih Game Favorit', style: AppTypography.titleMedium),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _games.map((game) {
                  final isSelected = _selectedGame == game;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedGame = game;
                          _selectedItem = null;
                          final isMockup = ref.read(mockupModeProvider);
    if (isMockup) {
                            _userIdController.text = '12894567';
                            _zoneIdController.text = '2041';
                          } else {
                            _userIdController.clear();
                            _zoneIdController.clear();
                          }
                        });
                        _loadLiveGameItems();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primaryNavy : AppColors.surfaceWhite,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppColors.primaryNavy : AppColors.borderLight,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              game['icon'] as IconData,
                              size: 16,
                              color: isSelected ? Colors.white : (game['color'] as Color),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              game['name'] as String,
                              style: AppTypography.bodySmall.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isSelected ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            // Card Input User ID & Zone ID
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ID Akun ${_selectedGame['name']}', style: AppTypography.titleSmall),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: CustomTextField(
                          controller: _userIdController,
                          hint: 'User ID (cth: 12894567)',
                          keyboardType: TextInputType.number,
                          prefix: const Icon(Icons.person_outline, color: AppColors.textSecondary),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 1,
                        child: CustomTextField(
                          controller: _zoneIdController,
                          hint: 'Zone ID',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Pilihan Denom Diamond / Voucher
            Text('Pilih Nominal Item', style: AppTypography.titleMedium),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _items.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.6,
              ),
              itemBuilder: (context, index) {
                final item = _items[index];
                final isSelected = _selectedItem == item;
                return InkWell(
                  onTap: () {
                    setState(() => _selectedItem = item);
                    if (_userIdController.text.trim().isNotEmpty) {
                      _showConfirmationSheet(
                        item,
                        _userIdController.text.trim(),
                        _zoneIdController.text.trim(),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Harap isi User ID terlebih dahulu')),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.accentMint.withValues(alpha: 0.3) : AppColors.surfaceWhite,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? AppColors.accentEmeraldDark : AppColors.borderLight,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(item['name'], style: AppTypography.titleSmall),
                        const SizedBox(height: 4),
                        Text(
                          item['priceDisplay'],
                          style: AppTypography.titleMedium.copyWith(color: AppColors.accentEmeraldDark),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

