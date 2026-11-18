import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/mockup_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/operator_detector.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/custom_bottom_sheet.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/dashed_divider.dart';
import '../../../core/widgets/skeleton_loader.dart';
import 'package:go_router/go_router.dart';
import '../domain/product_entity.dart';
import '../../transactions/domain/transaction_entity.dart';
import '../../transactions/presentation/pin_dialog.dart';
import '../../transactions/presentation/receipt_screen.dart';
import 'product_notifier.dart';

class PrepaidTransactionScreen extends ConsumerStatefulWidget {
  final String initialCategory; // 'pulsa' or 'paket_data'

  const PrepaidTransactionScreen({
    super.key,
    this.initialCategory = 'pulsa',
  });

  @override
  ConsumerState<PrepaidTransactionScreen> createState() => _PrepaidTransactionScreenState();
}

class _PrepaidTransactionScreenState extends ConsumerState<PrepaidTransactionScreen> {
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isMockup = ref.read(mockupModeProvider);
      if (isMockup) {
        _phoneController.text = '081234567890';
        ref.read(prepaidNotifierProvider.notifier).setPhoneNumber('081234567890');
      } else {
        _phoneController.clear();
        ref.read(prepaidNotifierProvider.notifier).reset();
      }
      ref.read(prepaidNotifierProvider.notifier).setActiveTab(widget.initialCategory);
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _showConfirmationSheet(ProductEntity product, String phone) {
    final cleanPrice = CurrencyFormatter.clean(product.sellPriceDisplay);

    CustomBottomSheet.show(
      context: context,
      title: 'Konfirmasi Pembelian',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildReceiptRow('Produk', product.name),
          _buildReceiptRow('Nomor Tujuan', phone),
          _buildReceiptRow('Operator', product.provider),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 16),
          Text(
            'Detail Pembayaran',
            style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          _buildReceiptRow('Harga', cleanPrice),
          _buildReceiptRow('Biaya Transaksi', 'Gratis (Rp. 0)'),
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
                  skuCode: product.skuCode,
                  productName: product.name,
                  customerNumber: phone,
                  amountCents: product.sellPriceCents,
                  amountDisplay: CurrencyFormatter.clean(product.sellPriceDisplay),
                  sellPriceCents: product.sellPriceCents,
                  sellPriceDisplay: CurrencyFormatter.clean(product.sellPriceDisplay),
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

  Widget _buildReceiptRow(String label, String value) {
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
          _phoneController.clear();
        });
        ref.read(prepaidNotifierProvider.notifier).reset();
      }
    });

    final state = ref.watch(prepaidNotifierProvider);
    final isOperatorKnown = state.operatorInfo.type != CellularOperatorType.unknown;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text(state.activeTab == 'pulsa' ? 'Isi Pulsa' : 'Paket Data'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Field Nomor Tujuan dengan Operator Badge Real-Time
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Nomor Ponsel Tujuan', style: AppTypography.labelMedium),
                      // Badge Operator yang Terdeteksi Otomatis (0ms)
                      if (isOperatorKnown)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: state.operatorInfo.primaryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                state.operatorInfo.icon,
                                size: 14,
                                color: state.operatorInfo.primaryColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                state.operatorInfo.name,
                                style: AppTypography.bodySmall.copyWith(
                                  color: state.operatorInfo.primaryColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  CustomTextField(
                    controller: _phoneController,
                    hint: 'Contoh: 0812 3456 7890',
                    style: AppTypography.titleLarge.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                    hintStyle: AppTypography.bodyLarge.copyWith(
                      fontSize: 16,
                      color: AppColors.textTertiary,
                    ),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(14),
                    ],
                    prefix: const Icon(Icons.phone_android, color: AppColors.textSecondary, size: 24),
                    suffix: IconButton(
                      icon: Icon(Icons.contact_phone_outlined, color: AppColors.primaryNavy),
                      tooltip: 'Pilih dari Buku Kontak',
                      onPressed: () {
                        if (ref.read(mockupModeProvider)) {
                          _phoneController.text = '081234567890';
                          ref.read(prepaidNotifierProvider.notifier).setPhoneNumber('081234567890');
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Membuka kontak perangkat...')),
                          );
                        }
                      },
                    ),
                    onChanged: (value) {
                      ref.read(prepaidNotifierProvider.notifier).setPhoneNumber(value);
                    },
                  ),
                  Builder(
                    builder: (context) {
                      final phone = _phoneController.text.trim();
                      final validationMsg = _getValidationMessage(phone, state.operatorInfo);
                      final isComplete = _isPhoneValid(phone, state.operatorInfo);

                      if (validationMsg != null) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, size: 14, color: AppColors.warning),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  validationMsg,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.warning,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      } else if (isComplete) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_outline, size: 14, color: AppColors.success),
                              const SizedBox(width: 6),
                              Text(
                                'Nomor valid • ${state.operatorInfo.name}',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.accentEmeraldDark,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Tab Pilihan: Pulsa vs Paket Data
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTabButton('Pulsa Reguler', 'pulsa', state.activeTab),
                  ),
                  Expanded(
                    child: _buildTabButton('Paket Data', 'paket_data', state.activeTab),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Daftar Denominasi Produk
            Text('Pilih Nominal', style: AppTypography.titleMedium),
            const SizedBox(height: 12),

            () {
              final displayedProducts = state.products.where((p) {
                if (state.activeTab == 'pulsa') {
                  if (p.categoryCode != null && p.categoryCode != 'pulsa') return false;
                  final lowerName = p.name.toLowerCase();
                  final lowerSku = p.skuCode.toLowerCase();
                  if (lowerName.contains('data') || lowerName.contains('gb') || lowerName.contains('kuota') ||
                      lowerSku.contains('data') || lowerSku.contains('gb')) {
                    return false;
                  }
                  return true;
                } else {
                  if (p.categoryCode != null && p.categoryCode == 'pulsa') return false;
                  final lowerName = p.name.toLowerCase();
                  final lowerSku = p.skuCode.toLowerCase();
                  return lowerName.contains('data') || lowerName.contains('gb') || lowerName.contains('kuota') ||
                      lowerSku.contains('data') || lowerSku.contains('gb') || p.categoryCode == 'paket_data';
                }
              }).toList();

              if (state.isLoading) {
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 6,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.55,
                  ),
                  itemBuilder: (context, index) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWhite,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          SkeletonLoader(width: 70, height: 18, borderRadius: 4),
                          SizedBox(height: 6),
                          SkeletonLoader(width: 40, height: 12, borderRadius: 4),
                          SizedBox(height: 4),
                          SkeletonLoader(width: 80, height: 14, borderRadius: 4),
                        ],
                      ),
                    );
                  },
                );
              } else if (displayedProducts.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.dialpad, size: 40, color: AppColors.textTertiary),
                      const SizedBox(height: 12),
                      Text(
                        state.phone.length < 4
                            ? 'Ketik minimal 4 digit nomor HP untuk melihat pilihan denominasi.'
                            : 'Tidak ada produk untuk kategori ini.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                );
              } else if (state.activeTab == 'paket_data') {
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayedProducts.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final p = displayedProducts[index];
                    final cleanPrice = _formatCleanPrice(p.sellPriceDisplay);

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          final phone = _phoneController.text.trim();
                          if (!_isPhoneValid(phone, state.operatorInfo)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppColors.warning,
                                content: Text(
                                  phone.isEmpty
                                      ? 'Silakan masukkan nomor ponsel terlebih dahulu.'
                                      : (_getValidationMessage(phone, state.operatorInfo) ?? 'Nomor ponsel tidak valid.'),
                                ),
                              ),
                            );
                            return;
                          }
                          ref.read(prepaidNotifierProvider.notifier).selectProduct(p);
                          _showConfirmationSheet(p, phone);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceWhite,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.borderLight),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Row 1: Nama Paket di kiri & Tombol "Lihat detail" di kanan
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      p.name,
                                      style: AppTypography.titleMedium.copyWith(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => _showPackageDetailDialog(p),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                      child: Text(
                                        'Lihat detail',
                                        style: AppTypography.bodySmall.copyWith(
                                          color: AppColors.info,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              // Row 2: Rincian kuota (- Kuota utama ...)
                              Text(
                                '- ${p.description ?? 'Kuota utama internet'}',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Row 3: Harga
                              Text(
                                cleanPrice,
                                style: AppTypography.titleLarge.copyWith(
                                  color: AppColors.accentEmeraldDark,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              } else {
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayedProducts.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.55,
                  ),
                  itemBuilder: (context, index) {
                    final p = displayedProducts[index];
                    final denom = _formatDenom(p.name);
                    final isSelected = state.selectedProduct?.id == p.id;
                    final cleanPrice = _formatCleanPrice(p.sellPriceDisplay);

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          final phone = _phoneController.text.trim();
                          if (!_isPhoneValid(phone, state.operatorInfo)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppColors.warning,
                                content: Text(
                                  phone.isEmpty
                                      ? 'Silakan masukkan nomor ponsel terlebih dahulu.'
                                      : (_getValidationMessage(phone, state.operatorInfo) ?? 'Nomor ponsel tidak valid.'),
                                ),
                              ),
                            );
                            return;
                          }
                          ref.read(prepaidNotifierProvider.notifier).selectProduct(p);
                          _showConfirmationSheet(p, phone);
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceWhite,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? AppColors.primaryNavy : AppColors.borderLight,
                              width: isSelected ? 1.5 : 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // 1. Denom Nominal Bersih (contoh: 5.000)
                              Text(
                                denom,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 17,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              // 2. Tulisan "Harga"
                              Text(
                                'Harga',
                                style: AppTypography.bodySmall.copyWith(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              // 3. Harga Jual Bersih tanpa ,00 (contoh: Rp. 5.500)
                              Text(
                                cleanPrice,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.accentEmeraldDark,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              }
            }(),
          ],
        ),
      ),
    );
  }

  void _showPackageDetailDialog(ProductEntity product) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Pop-up
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Detail Paket Data',
                      style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w700),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20, color: AppColors.textSecondary),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.borderLight),
                const SizedBox(height: 14),

                // Nama Paket & Harga
                Text(
                  product.name,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryNavy,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatCleanPrice(product.sellPriceDisplay),
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.accentEmeraldDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 14),
                const DashedDivider(color: Color(0xFFCBD5E1), dashWidth: 5, dashSpace: 4),
                const SizedBox(height: 14),

                // Rincian Kuota
                Text('Rincian Kuota & Manfaat:', style: AppTypography.labelLarge),
                const SizedBox(height: 8),
                _buildBulletItem(product.description ?? 'Kuota Utama 24 Jam di semua jaringan'),
                _buildBulletItem('Masa aktif otomatis bertambah sejak aktivasi sukses'),
                _buildBulletItem('Dapat digunakan di seluruh jaringan 2G/3G/4G/5G nasional'),
                _buildBulletItem('Tanpa batasan kuota malam atau zonasi lokal'),

                const SizedBox(height: 20),
                CustomButton(
                  text: 'Pilih & Lanjut Pembelian',
                  backgroundColor: AppColors.primaryNavy,
                  onPressed: () {
                    Navigator.of(context).pop();
                    final phone = _phoneController.text.trim();
                    if (!_isPhoneValid(phone, ref.read(prepaidNotifierProvider).operatorInfo)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.warning,
                          content: Text(
                            phone.isEmpty
                                ? 'Silakan masukkan nomor ponsel terlebih dahulu.'
                                : (_getValidationMessage(phone, ref.read(prepaidNotifierProvider).operatorInfo) ?? 'Nomor ponsel tidak valid.'),
                          ),
                        ),
                      );
                      return;
                    }
                    ref.read(prepaidNotifierProvider.notifier).selectProduct(product);
                    _showConfirmationSheet(product, phone);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBulletItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: AppColors.success, fontSize: 14, fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textPrimary,
                fontSize: 13,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _getValidationMessage(String phone, CellularOperatorInfo operatorInfo) {
    if (phone.isEmpty) return null;
    if (phone.length < 4) {
      return 'Ketik minimal 4 digit untuk deteksi operator';
    }
    if (operatorInfo.type == CellularOperatorType.unknown) {
      return 'Operator seluler tidak dikenali (gunakan awalan 08xx / 628xx)';
    }
    if (phone.length < 10) {
      return 'Nomor ponsel belum lengkap (minimal 10 digit, saat ini ${phone.length})';
    }
    return null;
  }

  bool _isPhoneValid(String phone, CellularOperatorInfo operatorInfo) {
    return phone.length >= 10 &&
        phone.length <= 14 &&
        operatorInfo.type != CellularOperatorType.unknown;
  }

  String _formatCleanPrice(String rawPrice) {
    return CurrencyFormatter.clean(rawPrice);
  }

  String _formatDenom(String name) {
    // 1. Pola angka bertitik Indonesia (misal: 5.000, 10.000, 100.000)
    final dotMatch = RegExp(r'\b(\d{1,3}(?:\.\d{3})+)\b').firstMatch(name);
    if (dotMatch != null) {
      return dotMatch.group(1)!;
    }

    // 2. Pola singkatan K (misal: 5K, 10K, 25K)
    final kMatch = RegExp(r'\b(\d+)K\b', caseSensitive: false).firstMatch(name);
    if (kMatch != null) {
      return '${kMatch.group(1)}.000';
    }

    // 3. Pola angka murni 4 digit ke atas (misal: 5000 -> 5.000, 10000 -> 10.000)
    final numMatch = RegExp(r'\b(\d{4,})\b').firstMatch(name);
    if (numMatch != null) {
      final raw = numMatch.group(1)!;
      final thousands = raw.substring(0, raw.length - 3);
      return '$thousands.000';
    }

    return name;
  }

  Widget _buildTabButton(String title, String tabKey, String activeTab) {
    final isSelected = activeTab == tabKey;
    return InkWell(
      onTap: () {
        ref.read(prepaidNotifierProvider.notifier).setActiveTab(tabKey);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryNavy : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            title,
            style: AppTypography.labelLarge.copyWith(
              color: isSelected ? AppColors.textWhite : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

