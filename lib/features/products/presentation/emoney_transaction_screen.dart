import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/config/mockup_provider.dart';
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

class EmoneyTransactionScreen extends ConsumerStatefulWidget {
  const EmoneyTransactionScreen({super.key});

  @override
  ConsumerState<EmoneyTransactionScreen> createState() => _EmoneyTransactionScreenState();
}

class _EmoneyTransactionScreenState extends ConsumerState<EmoneyTransactionScreen> {
  // Step navigation: 0 = Hub/Daftar Top-up ala Livin', 1 = Input Nomor, 2 = Nominal & Pilihan
  int _currentStep = 0;

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nominalController = TextEditingController();

  final List<Map<String, dynamic>> _wallets = [
    {'name': 'ShopeePay', 'code': 'SPAY', 'providerCode': 'shopeepay', 'color': Color(0xFFEE4D2D), 'brandTag': 'S Pay'},
    {'name': 'LinkAja!', 'code': 'LINKAJA', 'providerCode': 'linkaja', 'color': Color(0xFFED1C24), 'brandTag': 'LinkAja!'},
    {'name': 'DANA', 'code': 'DNAP', 'providerCode': 'dana', 'color': Color(0xFF118EEA), 'brandTag': 'DANA'},
    {'name': 'GoPay', 'code': 'GOPAY', 'providerCode': 'gopay', 'color': Color(0xFF00AED6), 'brandTag': 'gopay'},
    {'name': 'OVO', 'code': 'OVO', 'providerCode': 'ovo', 'color': Color(0xFF4C3494), 'brandTag': 'OVO'},
  ];

  // Daftar Top-up Terakhir & Favorit (Sesuai Screenshot Livin' by Mandiri)
  final List<Map<String, dynamic>> _savedRecipients = [
    {
      'name': 'GoPay Customer - NUR D...',
      'phone': '08561234890',
      'walletCode': 'GOPAY',
      'walletName': 'GoPay',
      'isFavorite': true,
      'color': Color(0xFF00AED6),
    },
    {
      'name': 'ShopeePay - nXXXXXXXX...',
      'phone': '893085612399',
      'walletCode': 'SPAY',
      'walletName': 'ShopeePay',
      'isFavorite': true,
      'color': Color(0xFFEE4D2D),
    },
    {
      'name': 'ShopeePay - Rizki kurnia...',
      'phone': '893085688123',
      'walletCode': 'SPAY',
      'walletName': 'ShopeePay',
      'isFavorite': true,
      'color': Color(0xFFEE4D2D),
    },
    {
      'name': 'OVO - Pay OVO 0856...',
      'phone': '085655781290',
      'walletCode': 'OVO',
      'walletName': 'OVO',
      'isFavorite': true,
      'color': Color(0xFF4C3494),
    },
    {
      'name': 'GoPay Customer - GP-08...',
      'phone': '085655700192',
      'walletCode': 'GOPAY',
      'walletName': 'GoPay',
      'isFavorite': true,
      'color': Color(0xFF00AED6),
    },
    {
      'name': 'DANA - Budi Santoso',
      'phone': '081289012345',
      'walletCode': 'DNAP',
      'walletName': 'DANA',
      'isFavorite': true,
      'color': Color(0xFF118EEA),
    },
  ];

  late Map<String, dynamic> _selectedWallet;
  String _verifiedCustomerName = '';
  bool _isInquiring = false;

  List<Map<String, dynamic>> _denoms = [
    {'sku': 'DNAP20', 'amount': 20000, 'label': 'Rp 20.000', 'priceDisplay': 'Rp 20.000', 'adminFee': 1000},
    {'sku': 'DNAP50', 'amount': 50000, 'label': 'Rp 50.000', 'priceDisplay': 'Rp 50.000', 'adminFee': 1000},
    {'sku': 'DNAP100', 'amount': 100000, 'label': 'Rp 100.000', 'priceDisplay': 'Rp 100.000', 'adminFee': 1000},
    {'sku': 'DNAP200', 'amount': 200000, 'label': 'Rp 200.000', 'priceDisplay': 'Rp 200.000', 'adminFee': 1000},
    {'sku': 'DNAP300', 'amount': 300000, 'label': 'Rp 300.000', 'priceDisplay': 'Rp 300.000', 'adminFee': 1000},
    {'sku': 'DNAP500', 'amount': 500000, 'label': 'Rp 500.000', 'priceDisplay': 'Rp 500.000', 'adminFee': 1000},
  ];

  Map<String, dynamic>? _selectedDenom;
  int _activeRequestId = 0;
  bool _isLoadingProducts = false;

  final NumberFormat _thousandFormatter = NumberFormat('#,###', 'id_ID');

  @override
  void initState() {
    super.initState();
    _selectedWallet = _wallets[2]; // Default DANA
    final isMockup = ref.read(mockupModeProvider);
    if (isMockup) {
      _phoneController.text = '081380312000';
    } else {
      _phoneController.clear();
    }
    _loadLiveEmoneyProducts();
  }

  int get _parsedNominal {
    final rawDigits = _nominalController.text.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(rawDigits) ?? 0;
  }

  int get _adminFee {
    if (_parsedNominal <= 0) return 0;
    if (_selectedDenom != null && _selectedDenom!['adminFee'] != null) {
      return _selectedDenom!['adminFee'] as int;
    }
    if (_denoms.isNotEmpty && _denoms.first['adminFee'] != null) {
      return _denoms.first['adminFee'] as int;
    }
    return 1000;
  }

  int get _totalPayment => _parsedNominal + _adminFee;

  bool get _isNominalValid {
    final nominal = _parsedNominal;
    return nominal >= 10000 && nominal <= 10000000;
  }

  void _onNominalChanged(String text) {
    final rawDigits = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (rawDigits.isEmpty) {
      setState(() {
        _selectedDenom = null;
      });
      return;
    }

    final val = int.tryParse(rawDigits) ?? 0;
    final formatted = _thousandFormatter.format(val);

    if (_nominalController.text != formatted) {
      _nominalController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }

    Map<String, dynamic>? match;
    for (final d in _denoms) {
      if ((d['amount'] as int?) == val) {
        match = d;
        break;
      }
    }

    setState(() {
      _selectedDenom = match;
    });
  }

  void _selectPresetDenom(Map<String, dynamic> denom) {
    final amount = denom['amount'] as int;
    final formatted = _thousandFormatter.format(amount);
    setState(() {
      _selectedDenom = denom;
      _nominalController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    });
  }

  Future<void> _loadLiveEmoneyProducts() async {
    final currentReqId = ++_activeRequestId;
    final requestedProvider = _selectedWallet['providerCode'] ?? 'dana';

    setState(() {
      _isLoadingProducts = true;
    });

    final repo = ref.read(productRepositoryProvider);
    final items = await repo.getProducts(category: 'emoney', provider: requestedProvider);

    if (!mounted || currentReqId != _activeRequestId) {
      return;
    }

    setState(() {
      _isLoadingProducts = false;
      if (items.isNotEmpty) {
        _denoms = items.map((p) {
          final fee = p.adminFeeCents > 0 ? p.adminFeeCents ~/ 100 : 1000;
          final baseAmount = (p.sellPriceCents - p.adminFeeCents) > 0
              ? (p.sellPriceCents - p.adminFeeCents) ~/ 100
              : p.sellPriceCents ~/ 100;
          return {
            'sku': p.skuCode,
            'amount': baseAmount,
            'label': p.name,
            'priceDisplay': p.sellPriceDisplay,
            'adminFee': fee,
          };
        }).toList();
      } else {
        final code = _selectedWallet['code'] as String;
        _denoms = [
          {'sku': '${code}20', 'amount': 20000, 'label': 'Rp 20.000', 'priceDisplay': 'Rp 20.000', 'adminFee': 1000},
          {'sku': '${code}50', 'amount': 50000, 'label': 'Rp 50.000', 'priceDisplay': 'Rp 50.000', 'adminFee': 1000},
          {'sku': '${code}100', 'amount': 100000, 'label': 'Rp 100.000', 'priceDisplay': 'Rp 100.000', 'adminFee': 1000},
          {'sku': '${code}200', 'amount': 200000, 'label': 'Rp 200.000', 'priceDisplay': 'Rp 200.000', 'adminFee': 1000},
          {'sku': '${code}300', 'amount': 300000, 'label': 'Rp 300.000', 'priceDisplay': 'Rp 300.000', 'adminFee': 1000},
          {'sku': '${code}500', 'amount': 500000, 'label': 'Rp 500.000', 'priceDisplay': 'Rp 500.000', 'adminFee': 1000},
        ];
      }
    });
  }

  Future<void> _performAccountInquiry() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nomor ponsel akun minimal 10 digit')),
      );
      return;
    }

    setState(() {
      _isInquiring = true;
    });

    await Future.delayed(const Duration(milliseconds: 550));

    if (!mounted) return;

    if (phone == '081380312001') {
      setState(() {
        _isInquiring = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Nomor akun tidak terdaftar di ${_selectedWallet['name']} (RC: 0014)'),
        ),
      );
      return;
    }

    setState(() {
      _isInquiring = false;
      _verifiedCustomerName = 'PENGGUNA ${_selectedWallet['name']} - ${phone.substring(phone.length - 4)}';
      _currentStep = 2; // Pindah ke layar nominal
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nominalController.dispose();
    super.dispose();
  }

  // Slide-up Bottom Sheet Konfirmasi Top-up Ala Livin' Mandiri
  void _showMandiriConfirmationSheet() {
    final phone = _phoneController.text.trim();
    final nominal = _parsedNominal;
    final fee = _adminFee;
    final total = _totalPayment;

    final nominalDisplay = CurrencyFormatter.format(nominal);
    final feeDisplay = fee > 0 ? CurrencyFormatter.format(fee) : 'Gratis (Rp. 0)';
    final totalDisplay = CurrencyFormatter.format(total);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        bool isExpanded = true;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Header Konfirmasi Top-up
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Konfirmasi Top-up',
                          style: AppTypography.displayMedium.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 22),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 16),

                  // Identitas E-Wallet Box (Logo + Nama + Nomor)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          _buildBrandAvatarCircle(_selectedWallet['code'] as String, size: 46),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedWallet['name'] as String,
                                  style: AppTypography.titleMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  phone,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Accordion Rincian Transaksi (Bisa Buka-Tutup ▾)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: InkWell(
                      onTap: () {
                        setSheetState(() {
                          isExpanded = !isExpanded;
                        });
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Rincian Transaksi',
                              style: AppTypography.titleSmall.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                fontSize: 14,
                              ),
                            ),
                            Icon(
                              isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                              color: AppColors.textSecondary,
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  if (isExpanded) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          const SizedBox(height: 4),
                          _buildSheetRow('ID Pelanggan', phone),
                          _buildSheetRow('Nama Pelanggan', _verifiedCustomerName),
                          _buildSheetRow('Nominal Top Up', nominalDisplay),
                          _buildSheetRow('Biaya Transaksi', feeDisplay),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 14),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: DashedDivider(color: Color(0xFFCBD5E1), dashWidth: 5, dashSpace: 4),
                  ),
                  const SizedBox(height: 14),

                  // Nominal Total Pembayaran
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Total Pembayaran',
                          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600, fontSize: 14.5),
                        ),
                        Text(
                          totalDisplay,
                          style: AppTypography.displayMedium.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.accentEmeraldDark,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tombol Geser untuk Bayar (Slide to Confirm) - Jarak Aman Bawah (bottom: 36px)
                  Padding(
                    padding: const EdgeInsets.only(top: 22, bottom: 36, left: 20, right: 20),
                    child: SlideToPayButton(
                      labelText: 'Geser untuk Top Up',
                      onCompleted: () async {
                        Navigator.of(context).pop(); // Tutup bottom sheet
                        final pin = await PinDialog.show(this.context);
                        if (pin != null && pin.length == 6) {
                          if (!this.context.mounted) return;

                          final sku = _selectedDenom != null
                              ? (_selectedDenom!['sku'] as String)
                              : '${_selectedWallet['code']}${nominal ~/ 1000}';

                          final tempTx = TransactionEntity(
                            id: 0,
                            skuCode: sku,
                            productName: '${_selectedWallet['name']} $nominalDisplay',
                            customerNumber: phone,
                            amountCents: nominal * 100,
                            amountDisplay: nominalDisplay,
                            sellPriceCents: total * 100,
                            sellPriceDisplay: totalDisplay,
                            status: 'pending',
                            providerRef: null,
                            createdAt: DateTime.now(),
                          );

                          this.context.pushReplacement(
                            '/receipt',
                            extra: ReceiptArgs(
                              transaction: tempTx,
                              pinToExecute: pin,
                              amount: nominal * 100,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSheetRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 13)),
          Text(value, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700, fontSize: 13.5)),
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
          _nominalController.clear();
          _selectedDenom = null;
        });
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                onPressed: () {
                  setState(() {
                    _currentStep--;
                  });
                },
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                onPressed: () => context.pop(),
              ),
        title: Text(
          _currentStep == 0
              ? 'Top Up E-Money'
              : (_currentStep == 1 ? 'Pilih Nomor Akun' : 'Nominal Top Up'),
          style: AppTypography.displayMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: _buildCurrentStepView(),
    );
  }

  Widget _buildCurrentStepView() {
    switch (_currentStep) {
      case 0:
        return _buildStep0HubView();
      case 1:
        return _buildStep1PhoneInputView();
      case 2:
      default:
        return _buildStep2NominalView();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 0: TAMPILAN PERSIS LIVIN' BY MANDIRI (Deretan e-Wallet Geser + Daftar Top-up)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStep0HubView() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),

          // 1. Header Section "e-Wallet"
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'e-Wallet',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.2,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 2. Deretan Tombol e-Wallet Sistem Geser Horizontal (Sesuai Screenshot Mandiri)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: _wallets.map((wallet) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedWallet = wallet;
                        _currentStep = 1; // Pindah ke form input nomor
                      });
                      _loadLiveEmoneyProducts();
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 78,
                      height: 72,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: _buildBrandLogoPill(wallet['code'] as String),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 20),

          // 3. Garis Pemisah Abu Halus Full-Width
          Container(
            height: 8,
            width: double.infinity,
            color: const Color(0xFFF8FAFC),
          ),

          const SizedBox(height: 18),

          // 4. Header "Daftar Top-up" & "Atur"
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Daftar Top-up',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF64748B),
                  ),
                ),
                InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Fitur atur kontak favorit akan segera hadir'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Text(
                      'Atur',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 5. List Daftar Top-up (Font Besar, Kontras Tinggi, Ramah Orang Tua)
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            itemCount: _savedRecipients.length,
            separatorBuilder: (context, index) => const Divider(height: 24, color: Color(0xFFF1F5F9)),
            itemBuilder: (context, index) {
              final recipient = _savedRecipients[index];

              return InkWell(
                onTap: () {
                  final matchWallet = _wallets.firstWhere(
                    (w) => w['code'] == recipient['walletCode'],
                    orElse: () => _wallets.first,
                  );

                  setState(() {
                    _selectedWallet = matchWallet;
                    _phoneController.text = recipient['phone'] as String;
                    _verifiedCustomerName = recipient['name'] as String;
                    _currentStep = 2; // Langsung loncat ke nominal
                  });
                  _loadLiveEmoneyProducts();
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      // Avatar Brand Bulat Lebih Besar (52px)
                      _buildBrandAvatarCircle(recipient['walletCode'] as String, size: 52),
                      const SizedBox(width: 16),

                      // Nama Besar (17.5px Bold) & Nomor Kontras Jelas (14.5px)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              recipient['name'] as String,
                              style: const TextStyle(
                                fontSize: 17.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              recipient['phone'] as String,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF64748B),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Ikon Bintang Emas Favorit Lebih Besar (26px) ⭐
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFF59E0B),
                        size: 26,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 1: Form Input Nomor Akun
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStep1PhoneInputView() {
    final isMockup = ref.watch(mockupModeProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner E-Wallet Terpilih
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                _buildBrandAvatarCircle(_selectedWallet['code'] as String, size: 48),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Top Up ${_selectedWallet['name']}',
                        style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Masukkan nomor akun terdaftar',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Kolom Input Nomor HP
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nomor Ponsel Akun', style: AppTypography.titleSmall),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: _phoneController,
                  hint: 'Contoh: 0812 3456 7890',
                  keyboardType: TextInputType.phone,
                  prefix: const Icon(Icons.phone_android_rounded, color: AppColors.textSecondary),
                  onChanged: (_) => setState(() {}),
                  suffix: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isMockup)
                        IconButton(
                          icon: Icon(Icons.flash_on_rounded, color: AppColors.accentEmeraldDark),
                          tooltip: 'No. Demo M-Link',
                          onPressed: () {
                            setState(() {
                              _phoneController.text = '081380312000';
                            });
                          },
                        ),
                      const Icon(Icons.contacts_rounded, color: AppColors.textSecondary, size: 20),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
                if (isMockup) ...[
                  const SizedBox(height: 6),
                  Text(
                    '💡 No. uji: 081380312000 (Valid), 081380312001 (Akun Tidak Ditemukan)',
                    style: AppTypography.bodySmall.copyWith(fontSize: 10, color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),

          const Spacer(),

          // Tombol Lanjutkan (Dinaikkan posisinya / bottom: 32px)
          Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: CustomButton(
              text: 'Lanjutkan',
              isLoading: _isInquiring,
              backgroundColor: _phoneController.text.trim().length >= 10
                  ? AppColors.primaryNavy
                  : const Color(0xFFCBD5E1),
              onPressed: _phoneController.text.trim().length >= 10 && !_isInquiring
                  ? _performAccountInquiry
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 2: Input Nominal & Pilihan Cepat
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStep2NominalView() {
    final nominal = _parsedNominal;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kartu Penerima Terverifikasi (Hasil Inquiry)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                _buildBrandAvatarCircle(_selectedWallet['code'] as String, size: 46),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _verifiedCustomerName.isNotEmpty
                                  ? _verifiedCustomerName
                                  : 'PENGGUNA ${_selectedWallet['name']}',
                              style: AppTypography.titleMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle_rounded, size: 10, color: Color(0xFF059669)),
                                const SizedBox(width: 3),
                                Text(
                                  'Terverifikasi',
                                  style: AppTypography.bodySmall.copyWith(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF059669),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_selectedWallet['name']} • ${_phoneController.text.trim()}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Input Nominal Manual
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Nominal Top Up', style: AppTypography.titleSmall),
                    Text(
                      'Min. Rp 10.000',
                      style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Box Input Rupiah
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: nominal > 0 && nominal < 10000
                          ? AppColors.error
                          : (nominal >= 10000 ? AppColors.accentEmerald : AppColors.borderLight),
                      width: nominal >= 10000 ? 1.5 : 1.0,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        'Rp',
                        style: AppTypography.titleLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _nominalController,
                          keyboardType: TextInputType.number,
                          onChanged: _onNominalChanged,
                          style: AppTypography.titleLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            letterSpacing: 0.5,
                          ),
                          decoration: InputDecoration(
                            hintText: '0',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontWeight: FontWeight.bold,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      if (_nominalController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.cancel_rounded, size: 18, color: AppColors.textTertiary),
                          onPressed: () {
                            _nominalController.clear();
                            setState(() {
                              _selectedDenom = null;
                            });
                          },
                        ),
                    ],
                  ),
                ),

                if (nominal > 0 && nominal < 10000) ...[
                  const SizedBox(height: 6),
                  Text(
                    '⚠️ Nominal minimum adalah Rp 10.000',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.error,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Pilihan Cepat Nominal Chips
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Pilihan Cepat Nominal', style: AppTypography.titleMedium),
              if (_isLoadingProducts)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 12),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _denoms.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.2,
            ),
            itemBuilder: (context, index) {
              final denom = _denoms[index];
              final isSelected = _selectedDenom != null && _selectedDenom!['sku'] == denom['sku'];

              return InkWell(
                onTap: () => _selectPresetDenom(denom),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryNavy : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primaryNavy : const Color(0xFFE2E8F0),
                      width: isSelected ? 1.5 : 1,
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
                  child: Center(
                    child: Text(
                      CurrencyFormatter.format(denom['amount'] as int),
                      style: AppTypography.labelMedium.copyWith(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
              },
            ),

            const SizedBox(height: 32),

            // Tombol Lanjutkan ke Bottom Sheet (Dinaikkan posisinya / bottom: 32px)
            Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: CustomButton(
                text: 'Lanjutkan',
                backgroundColor: _isNominalValid ? AppColors.accentEmerald : const Color(0xFFCBD5E1),
                onPressed: _isNominalValid ? _showMandiriConfirmationSheet : null,
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPER WIDGETS LOGO & AVATAR BRAND (SVG ASSET RESMI ALA LIVIN' MANDIRI)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildBrandLogoPill(String code) {
    String assetPath;
    switch (code) {
      case 'SPAY':
        assetPath = 'assets/icons/shopeepay.svg';
        break;
      case 'LINKAJA':
        assetPath = 'assets/icons/linkaja.svg';
        break;
      case 'GOPAY':
        assetPath = 'assets/icons/gopay.svg';
        break;
      case 'OVO':
        assetPath = 'assets/icons/ovo.svg';
        break;
      case 'DNAP':
      default:
        assetPath = 'assets/icons/dana.svg';
        break;
    }

    return SvgPicture.asset(
      assetPath,
      height: 32,
      fit: BoxFit.contain,
    );
  }

  Widget _buildBrandAvatarCircle(String code, {double size = 52}) {
    String assetPath;
    Color bg;

    switch (code) {
      case 'SPAY':
        assetPath = 'assets/icons/shopeepay.svg';
        bg = const Color(0xFFFFF1EE);
        break;
      case 'GOPAY':
        assetPath = 'assets/icons/gopay.svg';
        bg = const Color(0xFFE0F7FA);
        break;
      case 'OVO':
        assetPath = 'assets/icons/ovo.svg';
        bg = const Color(0xFFF3E8FF);
        break;
      case 'LINKAJA':
        assetPath = 'assets/icons/linkaja.svg';
        bg = const Color(0xFFFFECEC);
        break;
      case 'DNAP':
      default:
        assetPath = 'assets/icons/dana.svg';
        bg = const Color(0xFFE0F2FE);
        break;
    }

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      child: Center(
        child: SvgPicture.asset(
          assetPath,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SLIDE TO PAY BUTTON (SLIDER GESER UNTUK BAYAR ALA LIVIN' MANDIRI)
// ─────────────────────────────────────────────────────────────────────────────
class SlideToPayButton extends StatefulWidget {
  final String labelText;
  final VoidCallback onCompleted;

  const SlideToPayButton({
    super.key,
    required this.labelText,
    required this.onCompleted,
  });

  @override
  State<SlideToPayButton> createState() => _SlideToPayButtonState();
}

class _SlideToPayButtonState extends State<SlideToPayButton> {
  double _dragPosition = 0.0;
  bool _isCompleted = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final thumbSize = 48.0;
        final maxDrag = totalWidth - thumbSize - 8.0;

        return Container(
          width: totalWidth,
          height: 56,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Track Label Text
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.labelText,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF475569),
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF94A3B8)),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF64748B)),
                  ],
                ),
              ),

              // Draggable Thumb Button
              Positioned(
                left: _dragPosition,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    if (_isCompleted) return;
                    setState(() {
                      _dragPosition = (_dragPosition + details.delta.dx).clamp(0.0, maxDrag);
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    if (_isCompleted) return;
                    if (_dragPosition >= maxDrag * 0.75) {
                      // Geser berhasil mencapai target
                      setState(() {
                        _dragPosition = maxDrag;
                        _isCompleted = true;
                      });
                      widget.onCompleted();
                    } else {
                      // Kembali ke awal jika belum mencapai ujung
                      setState(() {
                        _dragPosition = 0.0;
                      });
                    }
                  },
                  child: Container(
                    width: thumbSize,
                    height: thumbSize,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF059669), Color(0xFF047857)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF059669).withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
