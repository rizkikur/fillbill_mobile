import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_config.dart';
import '../../../core/config/mockup_provider.dart';
import '../../../core/errors/app_exception.dart';
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

class PlnTransactionScreen extends ConsumerStatefulWidget {
  final String initialType; // 'token' or 'tagihan'

  const PlnTransactionScreen({super.key, this.initialType = 'token'});

  @override
  ConsumerState<PlnTransactionScreen> createState() => _PlnTransactionScreenState();
}

class _PlnTransactionScreenState extends ConsumerState<PlnTransactionScreen> {
  late String _activeType;
  final TextEditingController _meterController = TextEditingController();

  List<Map<String, dynamic>> _plnTokens = [
    {'name': 'PLN Token Rp 20.000', 'sku': 'PLN20', 'price': 20500, 'priceDisplay': 'Rp 20.500'},
    {'name': 'PLN Token Rp 50.000', 'sku': 'PLN50', 'price': 50500, 'priceDisplay': 'Rp 50.500'},
    {'name': 'PLN Token Rp 100.000', 'sku': 'PLN100', 'price': 100500, 'priceDisplay': 'Rp 100.500'},
    {'name': 'PLN Token Rp 200.000', 'sku': 'PLN200', 'price': 200500, 'priceDisplay': 'Rp 200.500'},
    {'name': 'PLN Token Rp 500.000', 'sku': 'PLN500', 'price': 500500, 'priceDisplay': 'Rp 500.500'},
    {'name': 'PLN Token Rp 1.000.000', 'sku': 'PLN1000', 'price': 1000500, 'priceDisplay': 'Rp 1.000.500'},
  ];

  Map<String, dynamic>? _selectedToken;
  bool _isInquiring = false;
  Map<String, dynamic>? _inquiryResult;

  @override
  void initState() {
    super.initState();
    _activeType = widget.initialType;
    final isMockup = ref.read(mockupModeProvider);
    if (isMockup) {
      _meterController.text = '12000000001';
      if (_activeType == 'tagihan') {
        _inquiryResult = {
          'idpel': '12000000001',
          'name': 'MAHAYANA GARBILEKA',
          'tarif': 'R1 / 2200 VA',
          'periode': 'Nov 2026',
          'standMeter': '014820 - 015140 (320 kWh)',
          'tagihan': 'Rp 245.800',
          'admin': 'Rp 2.500',
          'total': 'Rp 248.300',
        };
      }
    } else {
      _meterController.clear();
      _inquiryResult = null;
    }
    _loadLiveTokens();
  }

  Future<void> _loadLiveTokens() async {
    final repo = ref.read(productRepositoryProvider);
    final items = await repo.getProducts(category: 'token_listrik');
    if (items.isNotEmpty && mounted) {
      setState(() {
        _plnTokens = items.map((p) => {
          'name': p.name,
          'sku': p.skuCode,
          'price': p.sellPriceCents ~/ 100,
          'priceDisplay': p.sellPriceDisplay,
        }).toList();
      });
    }
  }

  @override
  void dispose() {
    _meterController.dispose();
    super.dispose();
  }

  void _showConfirmationSheet({
    required Map<String, dynamic> token,
    required String meterNo,
    required String customerName,
    required String tariffPower,
    int? inquiryId,
  }) {
    final cleanPrice = CurrencyFormatter.clean(token['priceDisplay'] ?? 'Rp ${token['price']}');

    CustomBottomSheet.show(
      context: context,
      title: 'Konfirmasi Pembelian Token PLN',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRow('Layanan', 'PLN Prabayar (Token)'),
          _buildRow('No. Meter / IDPEL', meterNo),
          _buildRow('Nama Pelanggan', customerName),
          _buildRow('Tarif / Daya', tariffPower),
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

                final priceInt = (token['price'] as int? ?? 0);
                final tempTx = TransactionEntity(
                  id: 0,
                  skuCode: token['sku'],
                  productName: token['name'] ?? 'Token PLN ${token['sku']}',
                  customerNumber: meterNo,
                  amountCents: priceInt * 100,
                  amountDisplay: cleanPrice,
                  sellPriceCents: priceInt * 100,
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
                    inquiryId: inquiryId,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _onTokenTap(Map<String, dynamic> token, String meterNo) async {
    setState(() => _selectedToken = token);

    if (meterNo.length < 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap masukkan 11-12 digit No. Meter')),
      );
      return;
    }

    final isMockup = ref.read(mockupModeProvider);
    setState(() => _isInquiring = true);

    try {
      // 1. Selalu jalankan inquiry ke Backend (Backend inquiry ke Supplier M-Link)
      final repo = ref.read(productRepositoryProvider);
      final result = await repo.inquireProduct(
        skuCode: token['sku'],
        customerNumber: meterNo,
      );

      if (!mounted) return;
      setState(() => _isInquiring = false);

      final custName = result['customer_name'] as String? ?? 'PELANGGAN PLN / $meterNo';
      final tariff = result['tariff_power'] as String? ?? 'R1 / 2200 VA';
      final inquiryId = result['id'] as int?;

      // Tampilkan popup konfirmasi dengan nama dan daya asli dari upstream M-Link
      _showConfirmationSheet(
        token: token,
        meterNo: meterNo,
        customerName: custName,
        tariffPower: tariff,
        inquiryId: inquiryId,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isInquiring = false);

      // 2. Jika backend merespon dengan error bisnis (RC 007 nomor tidak ditemukan, 006 gangguan biller, dsb)
      if (e is AppException && e.statusCode != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
        // Popup konfirmasi DIBLOKIR! Tidak ada pembayaran untuk nomor yang ditolak upstream!
        return;
      }

      // 3. Jika gagal koneksi (network/offline/server belum jalan):
      if (isMockup) {
        // Pada mode mockup simulasi sekalipun, nomor khusus pengujian gagal M-Link WAJIB DITOLAK!
        if (meterNo == '12000000000') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Inquiry PLN gagal [RC: 007]: Gagal - Nomor tidak ditemukan'),
              backgroundColor: AppColors.error,
              duration: Duration(seconds: 4),
            ),
          );
          return;
        }
        if (meterNo == '12000000004') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Inquiry PLN gagal [RC: 006]: Gagal - Gangguan Biller'),
              backgroundColor: AppColors.error,
              duration: Duration(seconds: 4),
            ),
          );
          return;
        }

        // Nomor simulasi sukses
        _showConfirmationSheet(
          token: token,
          meterNo: meterNo,
          customerName: 'MAHAYANA GARBILEKA',
          tariffPower: 'R1 / 2200 VA',
          inquiryId: 999,
        );
      } else {
        // Mode Live: Tampilkan info kegagalan koneksi ke backend
        final targetUrl = AppConfig.instance.apiBaseUrl;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghubungi backend ($targetUrl). Pastikan php artisan serve aktif.'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _inquirePostpaidBill(String idpel) async {
    if (idpel.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan 11-12 digit ID Pelanggan PLN')),
      );
      return;
    }

    setState(() => _isInquiring = true);
    final isMockup = ref.read(mockupModeProvider);

    try {
      final repo = ref.read(productRepositoryProvider);
      final result = await repo.inquireProduct(
        skuCode: 'PLNPOST',
        customerNumber: idpel,
      );

      if (!mounted) return;
      setState(() {
        _isInquiring = false;
        _inquiryResult = {
          'id': result['id'],
          'idpel': idpel,
          'name': result['customer_name'] ?? 'PELANGGAN PLN / $idpel',
          'tarif': result['tariff_power'] ?? result['raw']?['data']?['daya'] ?? 'R1 / 1300 VA',
          'periode': result['raw']?['bill_period'] ?? 'Bulan Berjalan',
          'standMeter': result['raw']?['stand_meter'] ?? '-',
          'tagihan': result['amount_display'] ?? 'Rp 250.000',
          'admin': result['admin_fee_display'] ?? 'Rp 2.500',
          'total': CurrencyFormatter.clean(result['amount_display'] ?? 'Rp 252.500'),
        };
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isInquiring = false);

      if (e is AppException && e.statusCode != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      if (isMockup) {
        if (idpel == '12000000000') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Inquiry PLN gagal [RC: 007]: Gagal - Nomor tidak ditemukan'),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }
        setState(() {
          _inquiryResult = {
            'id': 999,
            'idpel': idpel,
            'name': 'MAHAYANA GARBILEKA',
            'tarif': 'R1 / 2200 VA',
            'periode': 'Nov 2026',
            'standMeter': '014820 - 015140 (320 kWh)',
            'tagihan': 'Rp 245.800',
            'admin': 'Rp 2.500',
            'total': 'Rp 248.300',
          };
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tagihan tidak ditemukan atau koneksi ke backend gagal (${AppConfig.instance.apiBaseUrl}).'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
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
          _meterController.clear();
          _inquiryResult = null;
          _selectedToken = null;
        });
      }
    });

    final isMockup = ref.watch(mockupModeProvider);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: const Text('Listrik PLN'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Switch Banner Mode Pengujian: Live API vs Demo Mockup
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isMockup ? Colors.purple.shade50 : const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isMockup ? Colors.purple.shade200 : const Color(0xFFA7F3D0),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          isMockup ? Icons.science_outlined : Icons.cloud_done_rounded,
                          size: 18,
                          color: isMockup ? Colors.purple.shade700 : AppColors.accentEmeraldDark,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isMockup ? 'Mode Demo Mockup' : 'Mode Live API (M-Link Biller)',
                                style: AppTypography.titleSmall.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isMockup ? Colors.purple.shade900 : const Color(0xFF065F46),
                                ),
                              ),
                              Text(
                                isMockup
                                    ? 'Simulasi lokal otomatis'
                                    : 'Inquiry & bayar real-time ke upstream',
                                style: AppTypography.bodySmall.copyWith(
                                  fontSize: 10,
                                  color: isMockup ? Colors.purple.shade700 : const Color(0xFF047857),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Transform.scale(
                    scale: 0.8,
                    child: Switch.adaptive(
                      value: isMockup,
                      activeThumbColor: Colors.purple.shade600,
                      activeTrackColor: Colors.purple.shade200,
                      inactiveThumbColor: AppColors.accentEmeraldDark,
                      inactiveTrackColor: const Color(0xFFA7F3D0),
                      onChanged: (val) async {
                        await ref.read(mockupModeProvider.notifier).setEnabled(val);
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Tab Switcher: Token vs Tagihan
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderLight),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _activeType = 'token';
                          _inquiryResult = null;
                          if (isMockup) {
                            _meterController.text = '12000000001';
                          } else {
                            _meterController.clear();
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _activeType == 'token' ? AppColors.primaryNavy : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            'Token Listrik (Prabayar)',
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: _activeType == 'token' ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _activeType = 'tagihan';
                          if (isMockup) {
                            _meterController.text = '12000000001';
                            _inquiryResult = {
                              'idpel': '12000000001',
                              'name': 'MAHAYANA GARBILEKA',
                              'tarif': 'R1 / 2200 VA',
                              'periode': 'Nov 2026',
                              'standMeter': '014820 - 015140 (320 kWh)',
                              'tagihan': 'Rp 245.800',
                              'admin': 'Rp 2.500',
                              'total': 'Rp 248.300',
                            };
                          } else {
                            _meterController.clear();
                            _inquiryResult = null;
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _activeType == 'tagihan' ? AppColors.primaryNavy : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            'Tagihan Listrik (Pascabayar)',
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: _activeType == 'tagihan' ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Card Input No Meter / IDPEL
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
                      Text(
                        _activeType == 'token' ? 'No. Meter / ID Pelanggan' : 'ID Pelanggan (IDPEL)',
                        style: AppTypography.titleSmall,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.bolt, size: 14, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              'PLN',
                              style: AppTypography.bodySmall.copyWith(
                                color: Colors.orange.shade800,
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
                    controller: _meterController,
                    hint: isMockup ? 'Contoh: 1200 0000 001' : 'Masukkan 11-12 digit No. Meter / IDPEL',
                    keyboardType: TextInputType.number,
                    prefix: const Icon(Icons.pin, color: AppColors.textSecondary),
                    onChanged: (_) => setState(() {}),
                    suffix: isMockup
                        ? IconButton(
                            icon: const Icon(Icons.flash_on, color: Colors.amber),
                            tooltip: 'Pakai ID Pelanggan Tester M-Link',
                            onPressed: () {
                              setState(() {
                                _meterController.text = '12000000001';
                              });
                            },
                          )
                        : null,
                  ),
                  if (isMockup) ...[
                    const SizedBox(height: 8),
                    Text(
                      '💡 No. uji M-Link: 12000000001 (Sukses Token), 12000000000 (Gagal)',
                      style: AppTypography.bodySmall.copyWith(fontSize: 10, color: AppColors.textSecondary),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Content Mode: Token Listrik
            if (_activeType == 'token') ...[
              if (isMockup || _meterController.text.trim().length >= 11) ...[
                Text('Pilih Nominal Token', style: AppTypography.titleMedium),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _plnTokens.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.6,
                  ),
                  itemBuilder: (context, index) {
                    final token = _plnTokens[index];
                    final isSelected = _selectedToken == token;
                    final isProcessingThis = _isInquiring && isSelected;
                    return InkWell(
                      onTap: _isInquiring
                          ? null
                          : () => _onTokenTap(token, _meterController.text.trim()),
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
                        child: isProcessingThis
                            ? Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentEmeraldDark),
                                  ),
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(token['name'], style: AppTypography.titleSmall),
                                  const SizedBox(height: 4),
                                  Text(
                                    token['priceDisplay'],
                                    style: AppTypography.titleMedium.copyWith(color: AppColors.accentEmeraldDark),
                                  ),
                                ],
                              ),
                      ),
                    );
                  },
                ),
              ] else ...[
                // Placeholder bersih saat nomor meter belum diisi (Mode Live Prod)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.accentMint.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.bolt, size: 36, color: AppColors.accentEmeraldDark),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Masukkan Nomor Meter / IDPEL',
                        style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ketik 11-12 digit nomor meter atau ID pelanggan PLN Anda di atas untuk menampilkan pilihan nominal token listrik.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ] else ...[
              // Content Mode: Tagihan Listrik
              if (_inquiryResult == null) ...[
                CustomButton(
                  text: 'Cek Tagihan Listrik',
                  isLoading: _isInquiring,
                  backgroundColor: AppColors.primaryNavy,
                  onPressed: () => _inquirePostpaidBill(_meterController.text.trim()),
                ),
              ] else ...[
                // Hasil Inquiry Tagihan
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.accentEmeraldDark.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Rincian Tagihan Listrik', style: AppTypography.titleMedium),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.accentMint,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Belum Lunas',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.accentEmeraldDark,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      _buildRow('ID Pelanggan', _inquiryResult!['idpel']),
                      _buildRow('Nama Pelanggan', _inquiryResult!['name']),
                      _buildRow('Tarif / Daya', _inquiryResult!['tarif']),
                      _buildRow('Periode', _inquiryResult!['periode']),
                      _buildRow('Stand Meter', _inquiryResult!['standMeter']),
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: AppColors.borderLight),
                      const SizedBox(height: 16),
                      Text(
                        'Detail Pembayaran',
                        style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      _buildRow('Tagihan Listrik', CurrencyFormatter.clean(_inquiryResult!['tagihan'])),
                      _buildRow('Biaya Transaksi', CurrencyFormatter.clean(_inquiryResult!['admin'])),
                      const SizedBox(height: 14),
                      const DashedDivider(color: Color(0xFFCBD5E1), dashWidth: 5, dashSpace: 4),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Pembayaran', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600)),
                          Text(
                            CurrencyFormatter.clean(_inquiryResult!['total']),
                            style: AppTypography.titleLarge.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.accentEmeraldDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      CustomButton(
                        text: 'Bayar Tagihan Sekarang',
                        backgroundColor: AppColors.primaryNavy,
                        onPressed: () async {
                          final pin = await PinDialog.show(context);
                          if (pin != null && pin.length == 6) {
                            if (!context.mounted) return;

                            final tempTx = TransactionEntity(
                              id: 0,
                              skuCode: 'PLNPOST',
                              productName: 'Tagihan Listrik PLN (${_inquiryResult!['nama'] ?? _inquiryResult!['idpel']})',
                              customerNumber: _inquiryResult!['idpel'],
                              amountCents: 0,
                              amountDisplay: CurrencyFormatter.clean(_inquiryResult!['total']),
                              sellPriceCents: 0,
                              sellPriceDisplay: CurrencyFormatter.clean(_inquiryResult!['total']),
                              status: 'pending',
                              providerRef: null,
                              createdAt: DateTime.now(),
                            );

                            context.pushReplacement(
                              '/receipt',
                              extra: ReceiptArgs(
                                transaction: tempTx,
                                pinToExecute: pin,
                                inquiryId: _inquiryResult!['id'] as int?,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

