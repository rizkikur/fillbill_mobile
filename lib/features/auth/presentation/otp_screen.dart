import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/pin_dots_display.dart';
import '../../../core/widgets/pin_keypad.dart';
import 'auth_notifier.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  String _enteredCode = '';

  void _onKeyPressed(String key) {
    if (_enteredCode.length < 6) {
      setState(() {
        _enteredCode += key;
      });

      if (_enteredCode.length == 6) {
        ref.read(authNotifierProvider.notifier).verifyOtp(_enteredCode);
      }
    }
  }

  void _onBackspacePressed() {
    if (_enteredCode.isNotEmpty) {
      setState(() {
        _enteredCode = _enteredCode.substring(0, _enteredCode.length - 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final phone = authState.phone ?? '';
    final countdown = authState.otpCountdown;
    final isLoading = authState.status == AuthStatus.loading;
    final hasError = authState.errorMessage != null;

    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (previous?.status != next.status) {
        if (next.status == AuthStatus.pinSetupRequired) {
          context.go('/auth/pin-setup');
        } else if (next.status == AuthStatus.authenticated) {
          context.go('/home');
        }
      }
      if (next.errorMessage != null && previous?.errorMessage != next.errorMessage) {
        setState(() {
          _enteredCode = '';
        });
      }
    });

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Text('Verifikasi Kode OTP', style: AppTypography.displayMedium),
                    const SizedBox(height: 8),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: AppTypography.bodyMedium,
                        children: [
                          const TextSpan(text: 'Masukkan 6 digit kode yang dikirim ke WhatsApp '),
                          TextSpan(
                            text: phone,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryNavy,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Indikator 6 Bulatan PIN
                    PinDotsDisplay(
                      length: 6,
                      enteredLength: _enteredCode.length,
                      hasError: hasError,
                    ),

                    const SizedBox(height: 20),

                    // Error Message
                    if (hasError) ...[
                      Text(
                        authState.errorMessage!,
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    if (isLoading) ...[
                      const SizedBox(height: 16),
                      const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Countdown & Resend
                    const SizedBox(height: 16),
                    if (countdown > 0)
                      Text(
                        'Kirim ulang kode dalam $countdown detik',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                      )
                    else
                      TextButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                ref.read(authNotifierProvider.notifier).submitPhone(phone);
                              },
                        child: Text(
                          'Kirim Ulang Kode OTP',
                          style: AppTypography.labelLarge.copyWith(color: AppColors.accentEmeraldDark),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Custom Numeric Keypad
            PinKeypad(
              onKeyPressed: isLoading ? (_) {} : _onKeyPressed,
              onBackspacePressed: isLoading ? () {} : _onBackspacePressed,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

