import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

class BillTransactionScreen extends ConsumerStatefulWidget {
  final String service; // 'pdam' or 'bpjs'

  const BillTransactionScreen({super.key, this.service = 'pdam'});

  @override
  ConsumerState<BillTransactionScreen> createState() => _BillTransactionScreenState();
}

class _BillTransactionScreenState extends ConsumerState<BillTransactionScreen> {
  final TextEditingController _customerNumberController = TextEditingController();

  final List<String> _pdamProviders = [
    'PDAM DKI Jakarta (PAM JAYA)',
    'PDAM Surabaya (Surya Sembada)',
    'PDAM Kota Bandung (Tirtawening)',
    'PDAM Kota Semarang (Tirta Moedal)',
    'PDAM Kota Medan (Tirtanadi)',
    'PDAM Kota Palembang (Tirta Musi)',
  ];

  late String _selectedProvider;
  bool _isInquiring = false;
  Map<String, dynamic>? _billDetails;

  @override
  void initState() {
    super.initState();
    _selectedProvider = _pdamProviders.first;
    final isMockup = ref.read(mockupModeProvider);
    if (isMockup) {
      _customerNumberController.text = widget.service == 'pdam' ? '0189028371' : '8888801234567890';
      _billDetails = {
        'noPelanggan': widget.service == 'pdam' ? '0189028371' : '8888801234567890',
        'nama': widget.service == 'pdam' ? 'AHMAD SYARIFUDDIN' : 'KELUARGA BUDI SANTOSO (3 JIWA)',
        'layanan': widget.service == 'pdam' ? 'Perumda Tirtawening Kota' : 'BPJS Kesehatan Kelas 1',
        'periode': 'Nov 2026',
        'pemakaian': widget.service == 'pdam' ? '28 m³ (001240 - 001268)' : '1 Bulan (3 Peserta)',
        'tagihan': widget.service == 'pdam' ? 'Rp 142.500' : 'Rp 450.000',
        'admin': 'Rp 2.500',
        'total': widget.service == 'pdam' ? 'Rp 145.000' : 'Rp 452.500',
      };
    } else {
      _customerNumberController.clear();
      _billDetails = null;
    }
  }

  @override
  void dispose() {
    _customerNumberController.dispose();
    super.dispose();
  }

  void _checkBill() async {
    final num = _customerNumberController.text.trim();
    if (num.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan nomor pelanggan yang valid')),
      );
      return;
    }

    setState(() => _isInquiring = true);
    final repo = ref.read(productRepositoryProvider);
    final skuCode = widget.service == 'pdam' ? 'PDAM_KOTA' : 'BPJSKES';
    final result = await repo.inquirePostpaid(
      skuCode: skuCode,
      customerNumber: num,
    );

    if (!mounted) return;
    setState(() => _isInquiring = false);

    if (result != null) {
      setState(() {
        if (widget.service == 'pdam') {
          _billDetails = {
            'id': result['id'],
            'title': 'Tagihan PDAM Air Bersih',
            'customerName': result['customer_name'] ?? 'BAMBANG SOEPRAPTO',
            'customerNo': num,
            'provider': _selectedProvider,
            'periode': result['raw']?['bill_period'] ?? 'Bulan Berjalan',
            'meter': '00241 m³ - 00268 m³ (27 m³)',
            'tagihan': result['amount_display'] ?? 'Rp 86.400',
            'denda': 'Rp 0',
            'admin': result['admin_fee_display'] ?? 'Rp 2.500',
            'total': CurrencyFormatter.clean(result['amount_display'] ?? 'Rp 88.900'),
            'sku': skuCode,
          };
        } else {
          _billDetails = {
            'id': result['id'],
            'title': 'Iuran BPJS Kesehatan',
            'customerName': result['customer_name'] ?? 'KELUARGA BUDI SANTOSO',
            'customerNo': num,
            'provider': 'BPJS Kesehatan Mandiri',
            'periode': result['raw']?['bill_period'] ?? 'Bulan Berjalan',
            'jumlahJiwa': '3 Anggota Keluarga',
            'tagihan': result['amount_display'] ?? 'Rp 300.000',
            'denda': 'Rp 0',
            'admin': result['admin_fee_display'] ?? 'Rp 2.500',
            'total': CurrencyFormatter.clean(result['amount_display'] ?? 'Rp 302.500'),
            'sku': skuCode,
          };
        }
      });
    } else if (ref.read(mockupModeProvider)) {
      // Fallback lokal mockup mode
      setState(() {
        if (widget.service == 'pdam') {
          _billDetails = {
            'title': 'Tagihan PDAM Air Bersih',
            'customerName': 'BAMBANG SOEPRAPTO',
            'customerNo': num,
            'provider': _selectedProvider,
            'periode': 'Okt - Nov 2026',
            'meter': '00241 m³ - 00268 m³ (27 m³)',
            'tagihan': 'Rp 86.400',
            'denda': 'Rp 0',
            'admin': 'Rp 2.500',
            'total': 'Rp 88.900',
            'sku': skuCode,
          };
        } else {
          _billDetails = {
            'title': 'Iuran BPJS Kesehatan',
            'customerName': 'KELUARGA BUDI SANTOSO',
            'customerNo': num,
            'provider': 'BPJS Kesehatan Mandiri',
            'periode': 'Nov 2026 (1 Bulan)',
            'jumlahJiwa': '3 Anggota Keluarga (Kelas 2)',
            'tagihan': 'Rp 300.000',
            'denda': 'Rp 0',
            'admin': 'Rp 2.500',
            'total': 'Rp 302.500',
            'sku': skuCode,
          };
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tagihan tidak ditemukan atau nomor pelanggan salah.'),
          backgroundColor: AppColors.error,
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
          _customerNumberController.clear();
          _billDetails = null;
        });
      }
    });

    final isPdam = widget.service == 'pdam';
    final pageTitle = isPdam ? 'Tagihan PDAM Air' : 'BPJS Kesehatan';

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text(pageTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Provider Dropdown jika PDAM
            if (isPdam) ...[
              Text('Wilayah / Perumda PDAM', style: AppTypography.titleSmall),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedProvider,
                    isExpanded: true,
                    icon: Icon(Icons.keyboard_arrow_down, color: AppColors.primaryNavy),
                    items: _pdamProviders.map((item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(item, style: AppTypography.bodyMedium),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedProvider = val;
                          _billDetails = null;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 18),
            ],

            // Input Nomor Pelanggan
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
                  Text(
                    isPdam ? 'Nomor Pelanggan / No. Sambungan' : 'Nomor Virtual Account / No. Peserta BPJS',
                    style: AppTypography.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  CustomTextField(
                    controller: _customerNumberController,
                    hint: isPdam ? 'Contoh: 0189028371' : 'Contoh: 8888801234567890',
                    keyboardType: TextInputType.number,
                    prefix: Icon(
                      isPdam ? Icons.water_drop : Icons.health_and_safety,
                      color: isPdam ? Colors.blue : Colors.green,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Tombol Cek Tagihan jika belum di-inquiry
            if (_billDetails == null) ...[
              CustomButton(
                text: 'Cek Rincian Tagihan',
                isLoading: _isInquiring,
                backgroundColor: AppColors.primaryNavy,
                onPressed: _checkBill,
              ),
            ] else ...[
              // Lembar Rincian Tagihan
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.accentEmeraldDark.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
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
                        Text(_billDetails!['title'], style: AppTypography.titleMedium),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.accentMint,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Tagihan Siap Bayar',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.accentEmeraldDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildRow('Penyedia Layanan', _billDetails!['provider']),
                    _buildRow('Nomor Pelanggan', _billDetails!['customerNo']),
                    _buildRow('Nama Pelanggan', _billDetails!['customerName']),
                    _buildRow('Periode Tagihan', _billDetails!['periode']),
                    if (isPdam)
                      _buildRow('Pemakaian Air', _billDetails!['meter'])
                    else
                      _buildRow('Peserta Terdaftar', _billDetails!['jumlahJiwa']),
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: AppColors.borderLight),
                    const SizedBox(height: 16),
                    Text(
                      'Detail Pembayaran',
                      style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    _buildRow('Harga', CurrencyFormatter.clean(_billDetails!['tagihan'])),
                    _buildRow('Denda Keterlambatan', CurrencyFormatter.clean(_billDetails!['denda'])),
                    _buildRow('Biaya Transaksi', CurrencyFormatter.clean(_billDetails!['admin'])),
                    const SizedBox(height: 14),
                    const DashedDivider(color: Color(0xFFCBD5E1), dashWidth: 5, dashSpace: 4),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Pembayaran', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600)),
                        Text(
                          CurrencyFormatter.clean(_billDetails!['total']),
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
                      text: 'Bayar Tagihan Sekarang',
                      backgroundColor: AppColors.primaryNavy,
                      onPressed: () async {
                        final pin = await PinDialog.show(context);
                        if (pin != null && pin.length == 6) {
                          if (!context.mounted) return;

                          final tempTx = TransactionEntity(
                            id: 0,
                            skuCode: _billDetails!['sku'],
                            productName: _billDetails!['title'] ?? 'Tagihan ${widget.service.toUpperCase()}',
                            customerNumber: _billDetails!['customerNo'],
                            amountCents: 0,
                            amountDisplay: CurrencyFormatter.clean(_billDetails!['total']),
                            sellPriceCents: 0,
                            sellPriceDisplay: CurrencyFormatter.clean(_billDetails!['total']),
                            status: 'pending',
                            providerRef: null,
                            createdAt: DateTime.now(),
                          );

                          context.pushReplacement(
                            '/receipt',
                            extra: ReceiptArgs(
                              transaction: tempTx,
                              pinToExecute: pin,
                              inquiryId: _billDetails!['id'] as int?,
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
        ),
      ),
    );
  }
}
