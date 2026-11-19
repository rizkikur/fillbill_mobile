import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_config.dart';
import '../../../core/config/mockup_provider.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
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

  // State Inquiry Token (Prabayar)
  Map<String, dynamic>? _tokenInquiryResult;
  String? _tokenInquiryError;

  // State Inquiry Tagihan (Pascabayar)
  Map<String, dynamic>? _postpaidInquiryResult;
  String? _postpaidInquiryError;

  /// Validasi nomor meter/ID Pelanggan: harus angka dan panjang 11 - 12 digit
  bool get _isMeterValid {
    final text = _meterController.text.trim();
    return RegExp(r'^\d{11,12}$').hasMatch(text);
  }

  @override
  void initState() {
    super.initState();
    _activeType = widget.initialType;
    final isMockup = ref.read(mockupModeProvider);
    if (isMockup) {
      _meterController.text = '12000000001';
      _tokenInquiryResult = null;
      _selectedToken = null;
    } else {
      _meterController.clear();
      _tokenInquiryResult = null;
      _selectedToken = null;
      _tokenInquiryError = null;
      _postpaidInquiryResult = null;
      _postpaidInquiryError = null;
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

  /// Alur Prabayar:
  /// 1. Nomor meter lolos validasi (11-12 digit angka) -> Produk baru muncul.
  /// 2. User klik nominal token -> Langsung inquiry ke BE.
  /// 3. Respon inquiry & info akun ditampilkan di POPUP (Modal Bottom Sheet).
  /// 4. User klik "Bayar Sekarang" di popup -> Dialog PIN -> Eksekusi Pembayaran.
  Future<void> _onTokenSelected(Map<String, dynamic> token) async {
    final meterNo = _meterController.text.trim();
    if (!_isMeterValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nomor meter tidak valid. Harus 11-12 digit angka.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _selectedToken = token;
      _isInquiring = true;
      _tokenInquiryError = null;
    });

    final isMockup = ref.read(mockupModeProvider);

    try {
      final repo = ref.read(productRepositoryProvider);
      final result = await repo.inquireProduct(
        skuCode: token['sku'],
        customerNumber: meterNo,
      );

      if (!mounted) return;
      final inqResult = {
        'id': result['id'],
        'idpel': meterNo,
        'name': result['customer_name'] ?? 'PELANGGAN PLN / $meterNo',
        'tarif': result['tariff_power'] ?? 'R1 / 2200 VA',
      };

      setState(() {
        _isInquiring = false;
        _tokenInquiryResult = inqResult;
      });

      // Tampilkan info akun & konfirmasi di POPUP (Modal Bottom Sheet)
      _showTokenConfirmationSheet(context, token, inqResult);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isInquiring = false);

      String errorMsg = 'Gagal melakukan inquiry PLN.';
      if (e is AppException && e.statusCode != null) {
        errorMsg = e.message;
      } else if (isMockup) {
        if (meterNo == '12000000000') {
          errorMsg = 'Inquiry PLN gagal [RC: 007]: Gagal - Nomor tidak ditemukan';
        } else if (meterNo == '12000000004') {
          errorMsg = 'Inquiry PLN gagal [RC: 006]: Gagal - Gangguan Biller';
        } else {
          // Mockup fallback success
          final inqResult = {
            'id': 999,
            'idpel': meterNo,
            'name': 'MAHAYANA GARBILEKA 01',
            'tarif': 'R1 / 2200 VA',
          };
          setState(() {
            _tokenInquiryResult = inqResult;
          });
          _showTokenConfirmationSheet(context, token, inqResult);
          return;
        }
      } else {
        errorMsg = 'Gagal menghubungi server backend (${AppConfig.instance.apiBaseUrl}). Pastikan server aktif.';
      }

      setState(() {
        _tokenInquiryError = errorMsg;
      });

      _showErrorDialog(context, errorMsg);
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 24),
            const SizedBox(width: 8),
            Text(
              'Inquiry Gagal',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.error,
              ),
            ),
          ],
        ),
        content: Text(message, style: AppTypography.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Mengerti', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  /// POPUP Modal Bottom Sheet: Menampilkan data akun & rincian pembayaran
  void _showTokenConfirmationSheet(
    BuildContext context,
    Map<String, dynamic> token,
    Map<String, dynamic> inquiryData,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final priceDisplay = CurrencyFormatter.clean(token['priceDisplay'] ?? 'Rp ${token['price']}');

        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header Popup
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.bolt, color: Colors.orange, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Konfirmasi Pembelian Token',
                            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Periksa data pelanggan sebelum membayar',
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(sheetContext),
                    ),
                  ],
                ),

                const Divider(height: 24, color: AppColors.borderLight),

                // 1. DATA AKUN / PELANGGAN
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.verified_user_rounded, color: AppColors.accentEmeraldDark, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'DATA PELANGGAN PLN',
                                style: AppTypography.bodySmall.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.accentEmeraldDark,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accentMint,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Terverifikasi',
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.accentEmeraldDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildRow('No. Meter / IDPEL', inquiryData['idpel'] ?? '-'),
                      _buildRow('Nama Pelanggan', inquiryData['name'] ?? '-'),
                      _buildRow('Tarif / Daya', inquiryData['tarif'] ?? '-'),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // 2. RINCIAN PEMBAYARAN
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.receipt_rounded, color: AppColors.primaryNavy, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'RINCIAN PEMBAYARAN',
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryNavy,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildRow('Produk', token['name']),
                      _buildRow('Harga Token', priceDisplay),
                      _buildRow('Biaya Admin', 'Gratis (Rp 0)'),
                      const SizedBox(height: 6),
                      const DashedDivider(color: Color(0xFFCBD5E1), dashWidth: 5, dashSpace: 4),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Bayar', style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700)),
                          Text(
                            priceDisplay,
                            style: AppTypography.titleLarge.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.accentEmeraldDark,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Tombol Bayar Sekarang
                CustomButton(
                  text: 'Bayar Sekarang',
                  backgroundColor: AppColors.primaryNavy,
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    _executeTokenPayment(token, inquiryData);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _executeTokenPayment(
    Map<String, dynamic> token,
    Map<String, dynamic> inquiryData,
  ) async {
    final pin = await PinDialog.show(context);
    if (pin != null && pin.length == 6) {
      if (!mounted) return;

      final meterNo = _meterController.text.trim();
      final priceInt = (token['price'] as int? ?? 0);
      final cleanPrice = CurrencyFormatter.clean(token['priceDisplay'] ?? 'Rp ${token['price']}');

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
          inquiryId: inquiryData['id'] as int?,
        ),
      );
    }
  }

  void _inquirePostpaidBill(String idpel) async {
    if (idpel.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan 11-12 digit ID Pelanggan PLN')),
      );
      return;
    }

    setState(() {
      _isInquiring = true;
      _postpaidInquiryError = null;
      _postpaidInquiryResult = null;
    });

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
        _postpaidInquiryResult = {
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
        setState(() {
          _postpaidInquiryError = e.message;
        });
        return;
      }

      if (isMockup) {
        if (idpel == '12000000000') {
          setState(() {
            _postpaidInquiryError = 'Inquiry PLN gagal [RC: 007]: Gagal - Nomor tidak ditemukan';
          });
          return;
        }
        setState(() {
          _postpaidInquiryResult = {
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
        setState(() {
          _postpaidInquiryError = 'Tagihan tidak ditemukan atau koneksi ke backend gagal (${AppConfig.instance.apiBaseUrl}).';
        });
      }
    }
  }

  Future<void> _handlePostpaidPayment() async {
    if (_postpaidInquiryResult == null) return;

    final pin = await PinDialog.show(context);
    if (pin != null && pin.length == 6) {
      if (!mounted) return;

      final tempTx = TransactionEntity(
        id: 0,
        skuCode: 'PLNPOST',
        productName: 'Tagihan Listrik PLN (${_postpaidInquiryResult!['name'] ?? _postpaidInquiryResult!['idpel']})',
        customerNumber: _postpaidInquiryResult!['idpel'],
        amountCents: 0,
        amountDisplay: CurrencyFormatter.clean(_postpaidInquiryResult!['total']),
        sellPriceCents: 0,
        sellPriceDisplay: CurrencyFormatter.clean(_postpaidInquiryResult!['total']),
        status: 'pending',
        providerRef: null,
        createdAt: DateTime.now(),
      );

      context.pushReplacement(
        '/receipt',
        extra: ReceiptArgs(
          transaction: tempTx,
          pinToExecute: pin,
          inquiryId: _postpaidInquiryResult!['id'] as int?,
        ),
      );
    }
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodySmall),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(mockupModeProvider, (previous, next) {
      if (mounted) {
        setState(() {
          if (!next) {
            _meterController.clear();
            _tokenInquiryResult = null;
            _selectedToken = null;
            _tokenInquiryError = null;
            _postpaidInquiryResult = null;
            _postpaidInquiryError = null;
          } else {
            _meterController.text = '12000000001';
            _tokenInquiryResult = null;
            _selectedToken = null;
          }
        });
      }
    });

    final isMockup = ref.watch(mockupModeProvider);
    final meterText = _meterController.text.trim();
    final isMeterValid = _isMeterValid;

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
            // Banner Mode Pengujian: Live API vs Demo Mockup
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
                          _tokenInquiryResult = null;
                          _tokenInquiryError = null;
                          _selectedToken = null;
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
                          _postpaidInquiryResult = null;
                          _postpaidInquiryError = null;
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
                border: Border.all(
                  color: isMeterValid ? AppColors.accentEmeraldDark : AppColors.borderLight,
                  width: isMeterValid ? 1.5 : 1,
                ),
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
                          color: isMeterValid
                              ? AppColors.accentMint
                              : Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isMeterValid ? Icons.check_circle : Icons.bolt,
                              size: 14,
                              color: isMeterValid ? AppColors.accentEmeraldDark : Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isMeterValid ? '11-12 Digit Sesuai' : 'PLN Prabayar',
                              style: AppTypography.bodySmall.copyWith(
                                color: isMeterValid ? AppColors.accentEmeraldDark : Colors.orange.shade800,
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
                    hint: isMockup ? 'Contoh: 12000000001' : 'Masukkan 11-12 digit No. Meter / IDPEL',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(12),
                    ],
                    prefix: const Icon(Icons.pin, color: AppColors.textSecondary),
                    onChanged: (val) {
                      setState(() {
                        if (_tokenInquiryResult != null || _tokenInquiryError != null) {
                          _tokenInquiryResult = null;
                          _tokenInquiryError = null;
                        }
                        if (_postpaidInquiryResult != null || _postpaidInquiryError != null) {
                          _postpaidInquiryResult = null;
                          _postpaidInquiryError = null;
                        }
                      });
                    },
                    suffix: isMockup
                        ? IconButton(
                            icon: const Icon(Icons.flash_on, color: Colors.amber),
                            tooltip: 'Pakai ID Pelanggan Tester M-Link',
                            onPressed: () {
                              setState(() {
                                _meterController.text = '12000000001';
                                _tokenInquiryResult = null;
                                _tokenInquiryError = null;
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

            // ═══════════════════════════════════════════════════════════════════
            // BAGIAN TOKEN LISTRIK (PRABAYAR)
            // ═══════════════════════════════════════════════════════════════════
            if (_activeType == 'token') ...[
              // VALIDASI: Produk HANYA muncul jika nomor meter sudah 11-12 digit angka!
              if (!isMeterValid) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.primaryNavy.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.dialpad_rounded, size: 30, color: AppColors.primaryNavy),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Masukkan Nomor Meter / IDPEL',
                        style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        meterText.isEmpty
                            ? 'Ketik 11-12 digit No. Meter PLN di atas untuk menampilkan daftar pilihan nominal token listrik.'
                            : 'No. Meter harus 11-12 digit angka.\n(Saat ini baru terisi ${meterText.length} digit)',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall.copyWith(
                          color: meterText.isEmpty ? AppColors.textSecondary : Colors.orange.shade800,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // NOMOR VALID -> MUNCULKAN PILIHAN PRODUK
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Pilih Nominal Token', style: AppTypography.titleMedium),
                    if (_isInquiring)
                      Row(
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentEmeraldDark),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Memeriksa Akun...',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.accentEmeraldDark,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        'Klik untuk cek akun & bayar',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Grid Nominal Token Listrik
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
                      onTap: _isInquiring ? null : () => _onTokenSelected(token),
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
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.accentEmeraldDark.withValues(alpha: 0.12),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: isProcessingThis
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentEmeraldDark),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Inquiry...',
                                      style: AppTypography.bodySmall.copyWith(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.accentEmeraldDark,
                                      ),
                                    ),
                                  ],
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

                const SizedBox(height: 20),

                // Error Card jika inquiry gagal
                if (_tokenInquiryError != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.errorBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Inquiry Pelanggan Gagal',
                                style: AppTypography.titleSmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.error,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _tokenInquiryError!,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.error,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ],
            ] else ...[
              // ═════════════════════════════════════════════════════════════════
              // BAGIAN TAGIHAN LISTRIK (PASCABAYAR)
              // ═════════════════════════════════════════════════════════════════
              CustomButton(
                text: 'Cek Tagihan Listrik',
                isLoading: _isInquiring,
                backgroundColor: meterText.length >= 8 ? AppColors.primaryNavy : AppColors.borderLight,
                textColor: meterText.length >= 8 ? Colors.white : AppColors.textSecondary,
                onPressed: meterText.length >= 8 ? () => _inquirePostpaidBill(meterText) : null,
              ),

              const SizedBox(height: 20),

              if (_postpaidInquiryError != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.errorBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _postpaidInquiryError!,
                          style: AppTypography.bodySmall.copyWith(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              if (_postpaidInquiryResult != null) ...[
                // Hasil Rincian Tagihan Listrik
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
                      _buildRow('ID Pelanggan', _postpaidInquiryResult!['idpel'] ?? '-'),
                      _buildRow('Nama Pelanggan', _postpaidInquiryResult!['name'] ?? '-'),
                      _buildRow('Tarif / Daya', _postpaidInquiryResult!['tarif'] ?? '-'),
                      _buildRow('Periode', _postpaidInquiryResult!['periode'] ?? '-'),
                      _buildRow('Stand Meter', _postpaidInquiryResult!['standMeter'] ?? '-'),
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: AppColors.borderLight),
                      const SizedBox(height: 16),
                      Text(
                        'Detail Pembayaran',
                        style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      _buildRow('Tagihan Listrik', CurrencyFormatter.clean(_postpaidInquiryResult!['tagihan'] ?? '0')),
                      _buildRow('Biaya Transaksi', CurrencyFormatter.clean(_postpaidInquiryResult!['admin'] ?? '0')),
                      const SizedBox(height: 14),
                      const DashedDivider(color: Color(0xFFCBD5E1), dashWidth: 5, dashSpace: 4),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Pembayaran', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600)),
                          Text(
                            CurrencyFormatter.clean(_postpaidInquiryResult!['total'] ?? '0'),
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
                        onPressed: _handlePostpaidPayment,
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
