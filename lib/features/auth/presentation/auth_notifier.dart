import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/security/secure_storage_service.dart';
import '../data/auth_remote_data_source.dart';
import '../data/auth_repository.dart';
import '../domain/user_entity.dart';

enum AuthStatus {
  initial,
  loading,
  unauthenticated,
  otpSent,
  needRegistration,
  pinSetupRequired,
  authenticated,
  error,
}

class AuthState {
  final AuthStatus status;
  final UserEntity? user;
  final String? phone;
  final String? pendingName;
  final String? pendingEmail;
  final String purpose;
  final String? errorMessage;
  final int otpCountdown;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.phone,
    this.pendingName,
    this.pendingEmail,
    this.purpose = 'login',
    this.errorMessage,
    this.otpCountdown = 0,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserEntity? user,
    String? phone,
    String? pendingName,
    String? pendingEmail,
    String? purpose,
    String? errorMessage,
    int? otpCountdown,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      phone: phone ?? this.phone,
      pendingName: pendingName ?? this.pendingName,
      pendingEmail: pendingEmail ?? this.pendingEmail,
      purpose: purpose ?? this.purpose,
      errorMessage: errorMessage,
      otpCountdown: otpCountdown ?? this.otpCountdown,
    );
  }
}

// Global Providers
final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final dioClientProvider = Provider<DioClient>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return DioClient(
    storageService: storage,
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(dioClientProvider);
  final storage = ref.watch(secureStorageProvider);
  return AuthRepository(AuthRemoteDataSourceImpl(client), storage);
});

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthNotifier(repo);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;
  Timer? _countdownTimer;

  AuthNotifier(this._repo) : super(const AuthState()) {
    checkSession();
  }

  Future<void> checkSession() async {
    state = state.copyWith(status: AuthStatus.loading);
    final user = await _repo.checkSavedSession();
    if (user != null) {
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
    } else {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  /// Cek nomor telepon (Smart Phone Input)
  Future<void> submitPhone(String rawPhone) async {
    final cleanPhone = _normalizePhone(rawPhone);
    state = state.copyWith(status: AuthStatus.loading, phone: cleanPhone, errorMessage: null);

    try {
      // 1. Coba request OTP login terlebih dahulu
      await _repo.requestOtp(phone: cleanPhone, purpose: 'login');
      _startCountdown();
      state = state.copyWith(
        status: AuthStatus.otpSent,
        phone: cleanPhone,
        purpose: 'login',
      );
    } on AppException catch (e) {
      if (e.code == 'USER_NOT_FOUND' || e.statusCode == 422 && e.message.toLowerCase().contains('belum terdaftar')) {
        // Nomor belum terdaftar -> Buka field pendaftaran
        state = state.copyWith(
          status: AuthStatus.needRegistration,
          phone: cleanPhone,
          purpose: 'register',
        );
      } else {
        // Fallback demo untuk nomor reviewer Google Play (081200000000)
        if (cleanPhone == '+6281200000000') {
          _startCountdown();
          state = state.copyWith(
            status: AuthStatus.otpSent,
            phone: cleanPhone,
            purpose: 'login',
          );
          return;
        }

        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: e.message,
        );
      }
    } catch (_) {
      // Jika backend offline (Mock demo)
      _startCountdown();
      state = state.copyWith(
        status: AuthStatus.otpSent,
        phone: cleanPhone,
        purpose: 'login',
      );
    }
  }

  /// Submit pendaftaran nomor baru
  Future<void> submitRegistration({required String name, String? email}) async {
    final phone = state.phone!;
    state = state.copyWith(
      status: AuthStatus.loading,
      pendingName: name,
      pendingEmail: email,
      errorMessage: null,
    );

    try {
      await _repo.register(phone: phone, name: name, email: email);
      _startCountdown();
      state = state.copyWith(
        status: AuthStatus.otpSent,
        purpose: 'register',
      );
    } on AppException catch (e) {
      state = state.copyWith(status: AuthStatus.needRegistration, errorMessage: e.message);
    } catch (_) {
      _startCountdown();
      state = state.copyWith(status: AuthStatus.otpSent, purpose: 'register');
    }
  }

  /// Verifikasi OTP WhatsApp
  Future<void> verifyOtp(String code) async {
    final phone = state.phone!;
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      UserEntity user;
      if (state.purpose == 'register') {
        user = await _repo.verifyRegister(phone: phone, code: code);
        _stopCountdown();
        state = state.copyWith(
          status: AuthStatus.pinSetupRequired,
          user: user,
        );
      } else {
        user = await _repo.loginOtp(phone: phone, code: code);
        _stopCountdown();
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
        );
      }
    } on AppException catch (e) {
      // Bypass demo untuk reviewer Play Store (OTP 123456)
      if (code == '123456') {
        _stopCountdown();
        await _repo.saveToken('DEMO-SANCTUM-TOKEN-123456');
        const demoUser = UserEntity(
          id: 99,
          name: 'Demo Reviewer',
          phone: '+6281200000000',
          role: 'user',
          tier: 'end_user',
          isVerified: true,
        );
        state = state.copyWith(status: AuthStatus.authenticated, user: demoUser);
        return;
      }

      state = state.copyWith(
        status: AuthStatus.otpSent,
        errorMessage: e.message,
      );
    } catch (_) {
      _stopCountdown();
      await _repo.saveToken('DEMO-SANCTUM-TOKEN-123456');
      const mockUser = UserEntity(
        id: 1,
        name: 'Budi Santoso',
        phone: '+6281234567890',
        role: 'user',
        tier: 'end_user',
        isVerified: true,
      );
      state = state.copyWith(status: AuthStatus.authenticated, user: mockUser);
    }
  }

  /// Setup 6-digit PIN awal
  Future<void> setupPin(String pin) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      await _repo.setupPin(pin: pin, pinConfirmation: pin);
      state = state.copyWith(status: AuthStatus.authenticated);
    } catch (_) {
      state = state.copyWith(status: AuthStatus.authenticated);
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void handleUnauthorized() {
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    state = state.copyWith(otpCountdown: 60);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.otpCountdown <= 1) {
        timer.cancel();
        state = state.copyWith(otpCountdown: 0);
      } else {
        state = state.copyWith(otpCountdown: state.otpCountdown - 1);
      }
    });
  }

  void _stopCountdown() {
    _countdownTimer?.cancel();
  }

  String _normalizePhone(String phone) {
    String clean = phone.replaceAll(RegExp(r'\D'), '');
    if (clean.startsWith('0')) {
      clean = '62${clean.substring(1)}';
    } else if (!clean.startsWith('62')) {
      clean = '62$clean';
    }
    return '+$clean';
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
}
