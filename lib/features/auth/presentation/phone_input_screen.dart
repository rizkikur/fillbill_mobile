import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/brand_logo_widget.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import 'auth_notifier.dart';

class PhoneInputScreen extends ConsumerStatefulWidget {
  const PhoneInputScreen({super.key});

  @override
  ConsumerState<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends ConsumerState<PhoneInputScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Widget _buildDevChip(String label, String phone) {
    final cleanDisplay = phone.startsWith('0') ? phone.substring(1) : phone;
    return InkWell(
      onTap: () {
        setState(() {
          _phoneController.text = cleanDisplay;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primaryNavy.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.primaryNavy,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isNeedRegistration = authState.status == AuthStatus.needRegistration;
    final isLoading = authState.status == AuthStatus.loading;

    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (previous?.status != next.status) {
        if (next.status == AuthStatus.otpSent) {
          context.push('/auth/otp');
        } else if (next.status == AuthStatus.authenticated) {
          context.go('/home');
        }
      }
    });

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                // Logo & Header Dinamis
                const Center(
                  child: BrandLogoWidget(
                    size: 72,
                    showText: true,
                  ),
                ),
                const SizedBox(height: 32),

                // Dev Account Quick Selector Banner
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primaryNavy.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primaryNavy.withValues(alpha: 0.15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.flash_on, size: 16, color: AppColors.accentEmeraldDark),
                          const SizedBox(width: 6),
                          Text(
                            'Pilih Cepat Akun Dev (Production Flow):',
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryNavy,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildDevChip('Budi (Rp 1 Jt)', '081234567890'),
                          _buildDevChip('Agen Retail (Rp 2.5 Jt)', '081200000002'),
                          _buildDevChip('Reseller (Rp 5 Jt)', '081300000003'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '💡 OTP masuk & PIN transaksi untuk testing: 123456',
                        style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),

                // Error Banner
                if (authState.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.errorBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            authState.errorMessage!,
                            style: AppTypography.bodySmall.copyWith(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Input Nomor Telepon
                CustomTextField(
                  controller: _phoneController,
                  label: 'Nomor WhatsApp',
                  hint: '812 3456 7890',
                  keyboardType: TextInputType.phone,
                  readOnly: isNeedRegistration,
                  prefix: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    child: Text(
                      '+62',
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().length < 8) {
                      return 'Masukkan nomor WhatsApp yang valid';
                    }
                    return null;
                  },
                ),

                // Form Registrasi (Animasi jika nomor belum terdaftar)
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 300),
                  crossFadeState: isNeedRegistration ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  firstChild: const SizedBox.shrink(),
                  secondChild: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.infoBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: AppColors.info, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Nomor Anda belum terdaftar. Lengkapi nama untuk membuat akun baru.',
                                style: AppTypography.bodySmall.copyWith(color: AppColors.info),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _nameController,
                        label: 'Nama Lengkap',
                        hint: 'Contoh: Budi Santoso',
                        validator: (value) {
                          if (isNeedRegistration && (value == null || value.trim().isEmpty)) {
                            return 'Nama lengkap wajib diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _emailController,
                        label: 'Email (Opsional)',
                        hint: 'budi@example.com',
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Tombol Lanjut
                CustomButton(
                  text: isNeedRegistration ? 'Daftar Sekarang' : 'Lanjut',
                  isLoading: isLoading,
                  backgroundColor: AppColors.primaryNavy,
                  onPressed: () {
                    if (_formKey.currentState?.validate() ?? false) {
                      if (isNeedRegistration) {
                        ref.read(authNotifierProvider.notifier).submitRegistration(
                              name: _nameController.text.trim(),
                              email: _emailController.text.trim(),
                            );
                      } else {
                        ref.read(authNotifierProvider.notifier).submitPhone(_phoneController.text.trim());
                      }
                    }
                  },
                ),

                const SizedBox(height: 32),
                Center(
                  child: Text(
                    'Dengan masuk, Anda menyetujui Syarat & Ketentuan FillBill.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
