import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/pin_dots_display.dart';
import '../../../core/widgets/pin_keypad.dart';
import 'auth_notifier.dart';

class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  String? _errorMessage;

  void _onKeyPressed(String key) {
    setState(() {
      _errorMessage = null;
    });

    if (!_isConfirming) {
      if (_pin.length < 6) {
        setState(() {
          _pin += key;
        });

        if (_pin.length == 6) {
          // Pindah ke tahap konfirmasi
          Future.delayed(const Duration(milliseconds: 250), () {
            setState(() {
              _isConfirming = true;
            });
          });
        }
      }
    } else {
      if (_confirmPin.length < 6) {
        setState(() {
          _confirmPin += key;
        });

        if (_confirmPin.length == 6) {
          if (_pin == _confirmPin) {
            // PIN cocok -> Simpan ke backend
            ref.read(authNotifierProvider.notifier).setupPin(_confirmPin);
          } else {
            // PIN tidak cocok -> Reset
            setState(() {
              _errorMessage = 'PIN tidak cocok. Silakan ulangi dari awal.';
              _pin = '';
              _confirmPin = '';
              _isConfirming = false;
            });
          }
        }
      }
    }
  }

  void _onBackspacePressed() {
    setState(() {
      _errorMessage = null;
      if (!_isConfirming) {
        if (_pin.isNotEmpty) {
          _pin = _pin.substring(0, _pin.length - 1);
        }
      } else {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.status == AuthStatus.loading;

    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated) {
        context.go('/home');
      }
    });

    final currentLength = _isConfirming ? _confirmPin.length : _pin.length;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 48),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.accentMint,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.lock_outline, color: AppColors.accentEmeraldDark, size: 36),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _isConfirming ? 'Konfirmasi PIN Transaksi' : 'Buat 6-Digit PIN Transaksi',
                      style: AppTypography.displayMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isConfirming
                          ? 'Ketik ulang 6 digit PIN untuk memastikan tidak ada kesalahan.'
                          : 'PIN ini akan digunakan untuk mengamankan setiap transaksi finansial Anda.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium,
                    ),
                    const SizedBox(height: 36),

                    // Indikator 6 Bulatan PIN
                    PinDotsDisplay(
                      length: 6,
                      enteredLength: currentLength,
                      hasError: _errorMessage != null,
                    ),

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],

                    if (isLoading) ...[
                      const SizedBox(height: 24),
                      const CircularProgressIndicator(strokeWidth: 2.5),
                    ],
                  ],
                ),
              ),
            ),

            // Custom Keypad
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

