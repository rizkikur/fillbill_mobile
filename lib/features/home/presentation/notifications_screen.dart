import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _activeTabIndex = 0;

  final List<Map<String, dynamic>> _notifications = [
    {
      'id': 'notif-1',
      'title': 'Transaksi Pulsa Sukses',
      'body': 'Pembelian Telkomsel 10.000 ke 081234567890 berhasil diproses. SN: 0041000180894618.',
      'time': '10 menit lalu',
      'type': 'transaction',
      'isRead': false,
    },
    {
      'id': 'notif-2',
      'title': 'Top Up Saldo Diterima',
      'body': 'Top Up deposit Rp 100.000 via BCA Virtual Account telah berhasil masuk ke saldo dompet FillBill.',
      'time': '2 jam lalu',
      'type': 'topup',
      'isRead': false,
    },
    {
      'id': 'notif-3',
      'title': 'Login Akun Berhasil',
      'body': 'Deteksi sesi login baru pada FillBill Mobile. Jika ini bukan Anda, segera perbarui PIN keamanan Anda di menu Profil.',
      'time': 'Kemarin, 20:15 WIB',
      'type': 'security',
      'isRead': true,
    },
  ];

  final List<Map<String, dynamic>> _promos = [
    {
      'id': 'promo-1',
      'badge': 'PROMO SPESIAL',
      'title': 'Cashback 10% Saldo Deposit',
      'description': 'Dapatkan ekstra cashback saldo dompet 10% untuk setiap top up minimal Rp 50.000 via Virtual Account & QRIS.',
      'code': 'HEMAT10',
      'validUntil': '30 Nov 2026',
      'color': AppColors.accentEmerald,
      'targetRoute': '/topup',
      'terms': [
        'Berlaku untuk seluruh metode Virtual Account Bank (BCA, Mandiri, BRI) dan QRIS.',
        'Minimal deposit top up adalah Rp 50.000.',
        'Maksimal cashback saldo yang diberikan adalah Rp 25.000 per akun.',
        'Cashback langsung dikreditkan ke saldo dompet FillBill secara instan.',
        'Periode promo berlaku sampai 30 November 2026.',
      ],
    },
    {
      'id': 'promo-2',
      'badge': 'FLASH SALE',
      'title': 'Diskon Biaya Admin Token PLN',
      'description': 'Beli token listrik semua nominal makin hemat dengan potongan biaya admin Rp 2.000 khusus akhir pekan ini.',
      'code': 'PLNHEMAT',
      'validUntil': 'Setiap Sabtu & Minggu',
      'color': Colors.amber.shade700,
      'targetRoute': '/transaction/pln',
      'terms': [
        'Berlaku untuk seluruh nominal token listrik PLN Prabayar (20rb s.d. 1jt).',
        'Potongan admin Rp 2.000 otomatis diterapkan saat konfirmasi pembayaran.',
        'Dapat digunakan berkali-kali tanpa batas kuota selama periode promo aktif.',
        'Berlaku khusus setiap hari Sabtu dan Minggu sepanjang bulan ini.',
      ],
    },
    {
      'id': 'promo-3',
      'badge': 'INFO SISTEM',
      'title': 'Pemeliharaan Biller PDAM',
      'description': 'Pembaruan jalur koneksi upstream PDAM terjadwal pada 12 Nov 2026 pukul 01:00 - 03:00 WIB. Layanan lainnya tetap normal.',
      'code': null,
      'validUntil': '12 Nov 2026',
      'color': Colors.indigo,
      'targetRoute': '/transaction/bill?service=pdam',
      'terms': [
        'Pemeliharaan hanya berdampak pada layanan inquiry dan bayar tagihan air PDAM.',
        'Transaksi Pulsa, Paket Data, Token Listrik, dan E-Money beroperasi normal tanpa kendala.',
        'Untuk kendala transaksi, hubungi Customer Care melalui menu Profil.',
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging || _tabController.index != _activeTabIndex) {
        setState(() {
          _activeTabIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _markAllAsRead() {
    setState(() {
      for (var item in _notifications) {
        item['isRead'] = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Semua notifikasi ditandai sudah dibaca'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => n['isRead'] == false).length;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Notifications',
          style: AppTypography.displayMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          if (_activeTabIndex == 0 && unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: Text(
                'Tandai Dibaca',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.accentEmeraldDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // OVO Style Full-Width Underline TabBar
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primaryNavy,
              indicatorWeight: 3.0,
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: AppColors.primaryNavy,
              unselectedLabelColor: const Color(0xFF8E9BAE),
              labelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
              tabs: [
                Tab(
                  text: unreadCount > 0 ? 'Notifikasi ($unreadCount)' : 'Notifikasi',
                ),
                Tab(
                  text: 'Pesan (${_promos.length})',
                ),
              ],
            ),
          ),

          // Tab Bar View Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNotificationsList(),
                _buildPromosList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    if (_notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_outlined, size: 56, color: AppColors.textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text('Belum ada notifikasi', style: AppTypography.bodyMedium),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: _notifications.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _notifications[index];
        final isRead = item['isRead'] as bool;
        final type = item['type'] as String;

        IconData icon;
        Color iconBg;
        Color iconColor;

        if (type == 'transaction') {
          icon = Icons.check_circle_outline_rounded;
          iconBg = AppColors.accentMint;
          iconColor = AppColors.accentEmeraldDark;
        } else if (type == 'topup') {
          icon = Icons.account_balance_wallet_outlined;
          iconBg = Colors.blue.shade50;
          iconColor = Colors.blue.shade700;
        } else {
          icon = Icons.security_rounded;
          iconBg = Colors.purple.shade50;
          iconColor = Colors.purple.shade700;
        }

        return InkWell(
          onTap: () {
            setState(() {
              item['isRead'] = true;
            });
            if (type == 'transaction') {
              context.go('/transactions');
            } else if (type == 'topup') {
              context.go('/wallet');
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isRead ? AppColors.surfaceWhite : const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isRead ? AppColors.borderLight : AppColors.accentEmerald.withValues(alpha: 0.35),
                width: isRead ? 1 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item['title'],
                              style: AppTypography.titleMedium.copyWith(
                                fontWeight: isRead ? FontWeight.w600 : FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            item['time'],
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['body'],
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isRead) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      color: AppColors.accentEmerald,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPromosList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: _promos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final item = _promos[index];
        final badge = item['badge'] as String;
        final color = item['color'] as Color;
        final code = item['code'] as String?;

        return InkWell(
          onTap: () => context.push('/promo-detail', extra: item),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mini Banner Visual Header (Ala OVO)
                Container(
                  height: 110,
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color,
                        color.withValues(alpha: 0.82),
                        AppColors.primaryNavy,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badge,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.timer_outlined, size: 12, color: Colors.white70),
                              const SizedBox(width: 4),
                              Text(
                                item['validUntil'],
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Text(
                        item['title'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Card Body
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['description'],
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (code != null)
                            Row(
                              children: [
                                Icon(Icons.confirmation_number_outlined, size: 16, color: AppColors.accentEmeraldDark),
                                const SizedBox(width: 6),
                                Text(
                                  code,
                                  style: AppTypography.titleMedium.copyWith(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryNavy,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            )
                          else
                            const SizedBox(),
                          Row(
                            children: [
                              Text(
                                'Lihat Detail',
                                style: AppTypography.labelMedium.copyWith(
                                  color: AppColors.accentEmeraldDark,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(Icons.chevron_right, size: 16, color: AppColors.accentEmeraldDark),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
