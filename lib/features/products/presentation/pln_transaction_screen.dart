import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _activeType = widget.initialType;
    final isMockup = ref.read(mockupModeProvider);
    if (isMockup) {
      _meterController.text = '12000000001';
      if (_activeType == 'token') {
        _tokenInquiryResult = {
          'id': 999,
          'idpel': '12000000001',
          'name': 'MAHAYANA GARBILEKA 01',
          'tarif': 'R1 / 2200 VA',
        };
        _selectedToken = _plnTokens.first;
      } else {
        _postpaidInquiryResult = {
          'id': 999,
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

  Future<void> _inquireTokenCustomer(String meterNo) async {
    if (meterNo.length < 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap masukkan 11-12 digit No. Meter / ID Pelanggan')),
      );
      return;
    }

    setState(() {
      _isInquiring = true;
      _tokenInquiryError = null;
      _tokenInquiryResult = null;
      _selectedToken = null;
    });

    final isMockup = ref.read(mockupModeProvider);

    try {
      final repo = ref.read(productRepositoryProvider);
      final result = await repo.inquireProduct(
        skuCode: 'PLN20',
        customerNumber: meterNo,
      );

      if (!mounted) return;
      setState(() {
        _isInquiring = false;
        _tokenInquiryResult = {
          'id': result['id'],
          'idpel': meterNo,
          'name': result['customer_name'] ?? 'PELANGGAN PLN / $meterNo',
          'tarif': result['tariff_power'] ?? 'R1 / 2200 VA',
        };
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isInquiring = false);

      if (e is AppException && e.statusCode != null) {
        setState(() {
          _tokenInquiryError = e.message;
        });
        return;
      }

      if (isMockup) {
        if (meterNo == '12000000000') {
          setState(() {
            _tokenInquiryError = 'Inquiry PLN gagal [RC: 007]: Gagal - Nomor tidak ditemukan';
          });
          return;
        }
        if (meterNo == '12000000004') {
          setState(() {
            _tokenInquiryError = 'Inquiry PLN gagal [RC: 006]: Gagal - Gangguan Biller';
          });
          return;
        }

        setState(() {
          _tokenInquiryResult = {
            'id': 999,
            'idpel': meterNo,
            'name': 'MAHAYANA GARBILEKA 01',
            'tarif': 'R1 / 2200 VA',
          };
        });
      } else {
        setState(() {
          _tokenInquiryError = 'Gagal menghubungi server backend (${AppConfig.instance.apiBaseUrl}). Pastikan server aktif.';
        });
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

  Future<void> _handleTokenPayment() async {
    if (_selectedToken == null || _tokenInquiryResult == null) return;

    final pin = await PinDialog.show(context);
    if (pin != null && pin.length == 6) {
      if (!mounted) return;

      final meterNo = _meterController.text.trim();
      final priceInt = (_selectedToken!['price'] as int? ?? 0);
      final cleanPrice = CurrencyFormatter.clean(_selectedToken!['priceDisplay'] ?? 'Rp ${_selectedToken!['price']}');

      final tempTx = TransactionEntity(
        id: 0,
        skuCode: _selectedToken!['sku'],
        productName: _selectedToken!['name'] ?? 'Token PLN ${_selectedToken!['sku']}',
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
          inquiryId: _tokenInquiryResult!['id'] as int?,
        ),
      );
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
            if (_activeType == 'token') {
              _tokenInquiryResult = {
                'id': 999,
                'idpel': '12000000001',
                'name': 'MAHAYANA GARBILEKA 01',
                'tarif': 'R1 / 2200 VA',
              };
              _selectedToken = _plnTokens.first;
            } else {
              _postpaidInquiryResult = {
                'id': 999,
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
          }
        });
      }
    });

    final isMockup = ref.watch(mockupModeProvider);
    final meterText = _meterController.text.trim();
    final canInquire = meterText.length >= 11;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: const Text('Listrik PLN'),
      ),
      bottomNavigationBar: (_activeType == 'token' && _selectedToken != null && _tokenInquiryResult != null)
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Pembayaran', style: AppTypography.bodySmall),
                          const SizedBox(height: 2),
                          Text(
                            CurrencyFormatter.clean(_selectedToken!['priceDisplay'] ?? 'Rp ${_selectedToken!['price']}'),
                            style: AppTypography.titleLarge.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.accentEmeraldDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomButton(
                        text: 'Bayar Sekarang',
                        backgroundColor: AppColors.primaryNavy,
                        onPressed: _handleTokenPayment,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
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
                            _tokenInquiryResult = {
                              'id': 999,
                              'idpel': '12000000001',
                              'name': 'MAHAYANA GARBILEKA 01',
                              'tarif': 'R1 / 2200 VA',
                            };
                            _selectedToken = _plnTokens.first;
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
                            _postpaidInquiryResult = {
                              'id': 999,
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
                    onChanged: (val) {
                      setState(() {
                        // Reset inquiry state saat input berubah
                        if (_tokenInquiryResult != null || _tokenInquiryError != null) {
                          _tokenInquiryResult = null;
                          _tokenInquiryError = null;
                          _selectedToken = null;
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
                              });
                              _inquireTokenCustomer('12000000001');
                            },
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  // Tombol Cek ID Pelanggan
                  CustomButton(
                    text: _activeType == 'token' ? 'Cek ID Pelanggan' : 'Cek Tagihan Listrik',
                    isLoading: _isInquiring,
                    backgroundColor: canInquire ? AppColors.primaryNavy : AppColors.borderLight,
                    textColor: canInquire ? Colors.white : AppColors.textSecondary,
                    onPressed: canInquire
                        ? () {
                            if (_activeType == 'token') {
                              _inquireTokenCustomer(meterText);
                            } else {
                              _inquirePostpaidBill(meterText);
                            }
                          }
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
              // Kasus 1: Error Inquiry
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

              // Kasus 2: Berhasil Inquiry -> Tampilkan Kartu Pelanggan Terverifikasi
              if (_tokenInquiryResult != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.accentEmeraldDark.withValues(alpha: 0.5)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentEmeraldDark.withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
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
                              Icon(Icons.check_circle_rounded, color: AppColors.accentEmeraldDark, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Data Pelanggan PLN',
                                style: AppTypography.titleSmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryNavy,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.accentMint,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.verified, size: 12, color: AppColors.accentEmeraldDark),
                                const SizedBox(width: 4),
                                Text(
                                  'Terverifikasi',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.accentEmeraldDark,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20, color: AppColors.borderLight),
                      _buildRow('No. Meter / IDPEL', _tokenInquiryResult!['idpel'] ?? '-'),
                      _buildRow('Nama Pelanggan', _tokenInquiryResult!['name'] ?? '-'),
                      _buildRow('Tarif / Daya', _tokenInquiryResult!['tarif'] ?? '-'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Grid Nominal Token Listrik (Aktif setelah nomor meter terverifikasi)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Pilih Nominal Token', style: AppTypography.titleMedium),
                    Text(
                      'Harga Netto',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
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
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedToken = token;
                        });
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
                        child: Column(
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
                const SizedBox(height: 60),
              ] else if (_tokenInquiryError == null) ...[
                // Placeholder bersih saat belum dilakukan inquiry
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
                        'Masukkan & Periksa Nomor Meter',
                        style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ketik 11-12 digit No. Meter atau ID Pelanggan Anda di atas, lalu klik "Cek ID Pelanggan" untuk memverifikasi data dan memilih nominal token listrik.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ] else ...[
              // ═════════════════════════════════════════════════════════════════
              // BAGIAN TAGIHAN LISTRIK (PASCABAYAR)
              // ═════════════════════════════════════════════════════════════════
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
