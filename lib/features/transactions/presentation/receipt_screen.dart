import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/dashed_divider.dart';
import '../../../core/widgets/status_badge.dart';
import '../../products/presentation/product_notifier.dart';
import '../../wallet/presentation/wallet_notifier.dart';
import '../domain/transaction_entity.dart';
import 'transaction_notifier.dart';

class ReceiptArgs {
  final TransactionEntity transaction;
  final String? pinToExecute;
  final int? inquiryId;
  final int? amount;

  const ReceiptArgs({
    required this.transaction,
    this.pinToExecute,
    this.inquiryId,
    this.amount,
  });
}

class ReceiptScreen extends ConsumerStatefulWidget {
  final TransactionEntity transaction;
  final String? pinToExecute;
  final int? inquiryId;
  final int? amount;

  const ReceiptScreen({
    super.key,
    required this.transaction,
    this.pinToExecute,
    this.inquiryId,
    this.amount,
  });

  @override
  ConsumerState<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends ConsumerState<ReceiptScreen> with SingleTickerProviderStateMixin {
  late TransactionEntity _currentTx;
  StreamSubscription<TransactionEntity>? _pollingSub;
  bool _isManualRefreshing = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _currentTx = widget.transaction;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Jika dipanggil dengan PIN, eksekusi pembayaran di background struk (Zero-Wait Transition)
    // Gunakan addPostFrameCallback agar tidak memodifikasi Riverpod provider saat widget tree sedang build (initState)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.pinToExecute != null && widget.pinToExecute!.isNotEmpty) {
        _executeInitialPayment(widget.pinToExecute!, widget.inquiryId);
      } else if (_isProcessing && _currentTx.id > 0) {
        _startBackgroundPolling();
      }
    });
  }

  @override
  void dispose() {
    _pollingSub?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  bool get _isProcessing =>
      _currentTx.status.toLowerCase() == 'pending' ||
      _currentTx.status.toLowerCase() == 'processing';

  bool get _isSuccess => _currentTx.status.toLowerCase() == 'success';

  bool get _isFailed =>
      _currentTx.status.toLowerCase() == 'failed' ||
      _currentTx.status.toLowerCase() == 'cancelled';

  Future<void> _executeInitialPayment(String pin, int? inquiryId) async {
    try {
      final realTx = await ref.read(transactionExecutionProvider.notifier).submitPayment(
        skuCode: _currentTx.skuCode,
        customerNumber: _currentTx.customerNumber,
        inquiryId: inquiryId,
        amount: widget.amount ?? (_currentTx.amountCents > 0 ? _currentTx.amountCents : null),
        pin: pin,
      );

      if (mounted) {
        setState(() {
          _currentTx = realTx;
        });

        if (realTx.status.toLowerCase() == 'success') {
          _triggerSuccessRefresh();
        } else if (_isProcessing && realTx.id > 0) {
          _startBackgroundPolling();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentTx = _currentTx.copyWith(
            status: 'failed',
            failureReason: e.toString().replaceAll('Exception: ', ''),
          );
        });
      }
    }
  }

  void _startBackgroundPolling() {
    if (_currentTx.id <= 0) return;
    _pollingSub?.cancel();
    final repo = ref.read(transactionRepositoryProvider);
    _pollingSub = repo.pollTransactionStatus(_currentTx.id).listen((updatedTx) {
      if (mounted) {
        setState(() {
          _currentTx = updatedTx;
        });

        if (updatedTx.status.toLowerCase() == 'success') {
          _triggerSuccessRefresh();
        }
      }
    });
  }

  Future<void> _refreshStatusManually() async {
    if (_isManualRefreshing || _currentTx.id <= 0) return;
    setState(() => _isManualRefreshing = true);

    try {
      final repo = ref.read(transactionRepositoryProvider);
      final fresh = await repo.getDetail(_currentTx.id);
      if (fresh != null && mounted) {
        setState(() {
          _currentTx = fresh;
        });

        if (fresh.status.toLowerCase() == 'success') {
          _triggerSuccessRefresh();
        }
      }
    } catch (_) {
      // Abaikan jika error jaringan saat pull refresh
    } finally {
      if (mounted) {
        setState(() => _isManualRefreshing = false);
      }
    }
  }

  void _triggerSuccessRefresh() {
    // Refresh saldo dompet dan riwayat mutasi setelah frame selesai
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(homeNotifierProvider.notifier).fetchDashboard();
      ref.read(walletNotifierProvider.notifier).fetchMutations();
      ref.read(transactionHistoryProvider.notifier).fetchHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final sn = _currentTx.effectiveSerialNumber;
    final hasSn = sn.isNotEmpty && sn != '-';

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text(
          _isProcessing
              ? 'Status Transaksi'
              : _isSuccess
                  ? 'Bukti Transaksi Resmi'
                  : 'Rincian Transaksi',
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Tutup ke Beranda',
            icon: const Icon(Icons.close),
            onPressed: () => context.go('/home'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshStatusManually,
        color: AppColors.primaryNavy,
        backgroundColor: AppColors.surfaceWhite,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              // Banner petunjuk drag untuk refresh jika transaksi masih diproses
              if (_isProcessing)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.swipe_down_rounded, size: 16, color: AppColors.textPrimary),
                      const SizedBox(width: 8),
                      Text(
                        'Tarik layar ke bawah untuk cek status terbaru',
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

              // Kartu Slip Struk Transaksi
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Column(
                  children: [
                    // Icon Status Dinamis
                    _buildStatusIcon(),

                    const SizedBox(height: 16),

                    // Judul Status
                    _buildStatusTitle(),

                    const SizedBox(height: 4),

                    // Nominal Pembayaran
                    Text(
                      CurrencyFormatter.clean(_currentTx.sellPriceDisplay),
                      style: AppTypography.displayMedium.copyWith(
                        color: AppColors.primaryNavy,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Badge Status
                    StatusBadge(status: _currentTx.status),

                    const SizedBox(height: 20),
                    const DashedDivider(color: Color(0xFFCBD5E1), dashWidth: 5, dashSpace: 4),
                    const SizedBox(height: 20),

                    // Rincian Transaksi
                    _buildRow('Nama Produk', _currentTx.productName),
                    _buildRow('Nomor Tujuan', _currentTx.customerNumber),
                    _buildRow('Waktu Transaksi', _formatDate(_currentTx.createdAt)),
                    _buildRow(
                      'No. Referensi Transaksi',
                      _currentTx.displayId,
                    ),
                    if (_currentTx.providerRef != null &&
                        _currentTx.providerRef!.isNotEmpty &&
                        _currentTx.providerRef != '-' &&
                        _currentTx.providerRef != sn)
                      _buildRow('No. Ref Supplier', _currentTx.providerRef!),

                    const SizedBox(height: 18),
                    const DashedDivider(color: Color(0xFFCBD5E1), dashWidth: 5, dashSpace: 4),
                    const SizedBox(height: 18),

                    // Kotak SN (Jika Sukses & Ada SN) ATAU Kotak Status Proses
                    if (hasSn) ...[
                      _buildSerialBox(sn),
                      const SizedBox(height: 16),
                    ] else if (_isProcessing) ...[
                      _buildProcessingBox(),
                      const SizedBox(height: 16),
                    ] else if (_isFailed) ...[
                      _buildFailedBox(),
                      const SizedBox(height: 16),
                    ],

                    Text(
                      _isProcessing
                          ? 'Transaksi Anda aman. Anda dapat menutup halaman ini kapan saja dan memantau statusnya di menu Riwayat.'
                          : 'Simpan bukti transaksi ini sebagai tanda terima yang sah.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Tombol-Tombol Aksi
              if (_isSuccess) ...[
                CustomButton(
                  text: 'Bagikan Struk ke WhatsApp',
                  icon: Icons.share,
                  backgroundColor: AppColors.accentEmerald,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Membuka WhatsApp untuk membagikan bukti transaksi...'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                CustomButton(
                  text: 'Cetak ke Printer Bluetooth',
                  icon: Icons.print,
                  isOutlined: true,
                  textColor: AppColors.primaryNavy,
                  onPressed: () {
                    _showBluetoothPrinterDialog(context);
                  },
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.go('/home'),
                  child: Text(
                    'Kembali ke Beranda',
                    style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ] else ...[
                // Transaksi Sedang Diproses / Gagal:
                // Tidak ada tombol redundan "Cek Status" (otomatis polling background & pull-to-refresh)
                CustomButton(
                  text: 'Kembali ke Beranda',
                  icon: Icons.home_rounded,
                  backgroundColor: AppColors.primaryNavy,
                  onPressed: () => context.go('/home'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    if (_isSuccess) {
      return Container(
        height: 64,
        width: 64,
        decoration: BoxDecoration(
          color: AppColors.accentMint,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.check_circle, color: AppColors.accentEmeraldDark, size: 40),
      );
    } else if (_isFailed) {
      return Container(
        height: 64,
        width: 64,
        decoration: BoxDecoration(
          color: AppColors.errorBg,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.cancel, color: AppColors.error, size: 40),
      );
    } else {
      // Pending / Processing
      return ScaleTransition(
        scale: _pulseAnimation,
        child: Container(
          height: 64,
          width: 64,
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.hourglass_top_rounded, color: const Color(0xFFD97706), size: 36),
        ),
      );
    }
  }

  Widget _buildStatusTitle() {
    if (_isSuccess) {
      return Text('Transaksi Berhasil!', style: AppTypography.titleLarge);
    } else if (_isFailed) {
      return Text(
        'Transaksi Gagal',
        style: AppTypography.titleLarge.copyWith(color: AppColors.error),
      );
    } else {
      return Text(
        'Transaksi Sedang Diproses',
        style: AppTypography.titleLarge.copyWith(color: const Color(0xFFD97706)),
      );
    }
  }

  Widget _buildProcessingBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFD97706)),
              ),
              const SizedBox(width: 8),
              Text(
                'Pesanan Sedang Diproses',
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFB45309),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Transaksi Anda sedang dalam proses. Nomor Seri (SN) akan otomatis tampil di sini setelah selesai.',
            style: AppTypography.bodySmall.copyWith(
              color: const Color(0xFF92400E),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFailedBox() {
    final reason = _currentTx.failureReason ?? 'Terjadi kendala saat memproses pesanan.';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: AppColors.error),
              const SizedBox(width: 8),
              Text(
                'Keterangan Kegagalan',
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            reason,
            style: AppTypography.bodySmall.copyWith(color: AppColors.error, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            'Saldo Anda tidak terpotong (atau otomatis dikembalikan).',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSerialBox(String sn) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _currentTx.productName.toLowerCase().contains('token')
                    ? 'TOKEN LISTRIK PLN (20 DIGIT)'
                    : 'NOMOR SERI / SN',
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: sn));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _currentTx.productName.toLowerCase().contains('token')
                            ? 'Token PLN berhasil disalin!'
                            : 'Nomor Seri / SN berhasil disalin!',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Icon(Icons.copy, size: 14, color: AppColors.accentEmeraldDark),
                    const SizedBox(width: 4),
                    Text(
                      'Salin',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.accentEmeraldDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            sn,
            style: AppTypography.titleLarge.copyWith(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w800,
              color: AppColors.primaryNavy,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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

  String _formatDate(DateTime? date) {
    if (date == null) return '09 Nov 2026, 11:30';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showBluetoothPrinterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.bluetooth_searching, color: AppColors.primaryNavy),
              const SizedBox(width: 8),
              Text('Pilih Printer Bluetooth', style: AppTypography.titleMedium),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.print, color: AppColors.accentEmeraldDark),
                title: const Text('Thermal Printer 58mm'),
                subtitle: const Text('Status: Siap Cetak (Terhubung)'),
                onTap: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Struk kasir berhasil dicetak!')),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
          ],
        );
      },
    );
  }
}
