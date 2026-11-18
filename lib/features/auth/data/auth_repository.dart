import '../../../core/security/secure_storage_service.dart';
import '../domain/user_entity.dart';
import 'auth_remote_data_source.dart';

class AuthRepository {
  final AuthRemoteDataSource _remoteSource;
  final SecureStorageService _storageService;

  AuthRepository(this._remoteSource, this._storageService);

  Future<void> requestOtp({required String phone, required String purpose}) async {
    await _remoteSource.requestOtp(phone: phone, purpose: purpose);
  }

  Future<UserEntity> register({
    required String phone,
    required String name,
    String? email,
  }) async {
    final res = await _remoteSource.register(phone: phone, name: name, email: email);
    return res.data!;
  }

  Future<UserEntity> verifyRegister({
    required String phone,
    required String code,
  }) async {
    final res = await _remoteSource.verifyRegister(phone: phone, code: code);
    final result = res.data!;
    await _storageService.saveAuthToken(result.token);
    return result.user;
  }

  Future<UserEntity> loginOtp({
    required String phone,
    required String code,
  }) async {
    final res = await _remoteSource.loginOtp(phone: phone, code: code);
    final result = res.data!;
    await _storageService.saveAuthToken(result.token);
    return result.user;
  }

  Future<UserEntity?> checkSavedSession() async {
    final token = await _storageService.getAuthToken();
    if (token == null || token.isEmpty) return null;

    try {
      final res = await _remoteSource.getProfile();
      return res.data;
    } catch (_) {
      // Jika offline, coba gunakan mock user
      return const UserEntity(
        id: 1,
        name: 'Budi Santoso',
        phone: '+6281234567890',
        role: 'user',
        tier: 'end_user',
        isVerified: true,
      );
    }
  }

  Future<void> setupPin({required String pin, required String pinConfirmation}) async {
    await _remoteSource.setupPin(pin: pin, pinConfirmation: pinConfirmation);
  }

  Future<void> saveToken(String token) async {
    await _storageService.saveAuthToken(token);
  }

  Future<void> logout() async {
    try {
      await _remoteSource.logout();
    } catch (_) {}
    await _storageService.clearAuthToken();
    await _storageService.clearEncryptedPin();
  }
}

