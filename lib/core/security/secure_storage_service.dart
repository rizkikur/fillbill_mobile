import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/storage_keys.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  Future<void> saveAuthToken(String token) async {
    await _storage.write(key: StorageKeys.authToken, value: token);
  }

  Future<String?> getAuthToken() async {
    return await _storage.read(key: StorageKeys.authToken);
  }

  Future<void> clearAuthToken() async {
    await _storage.delete(key: StorageKeys.authToken);
  }

  Future<void> saveEncryptedPin(String pin) async {
    await _storage.write(key: StorageKeys.encryptedPin, value: pin);
  }

  Future<String?> getEncryptedPin() async {
    return await _storage.read(key: StorageKeys.encryptedPin);
  }

  Future<void> clearEncryptedPin() async {
    await _storage.delete(key: StorageKeys.encryptedPin);
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(
      key: StorageKeys.biometricEnabled,
      value: enabled.toString(),
    );
  }

  Future<bool> isBiometricEnabled() async {
    final val = await _storage.read(key: StorageKeys.biometricEnabled);
    return val == 'true';
  }

  Future<void> setMockupEnabled(bool enabled) async {
    await _storage.write(
      key: StorageKeys.mockupEnabled,
      value: enabled.toString(),
    );
  }

  Future<bool?> isMockupEnabled() async {
    final val = await _storage.read(key: StorageKeys.mockupEnabled);
    if (val == null) return null;
    return val == 'true';
  }

  Future<void> setOnboardingCompleted(bool completed) async {
    await _storage.write(
      key: StorageKeys.onboardingCompleted,
      value: completed.toString(),
    );
  }

  Future<bool> isOnboardingCompleted() async {
    final val = await _storage.read(key: StorageKeys.onboardingCompleted);
    return val == 'true';
  }

  Future<void> clearOnboardingCompleted() async {
    await _storage.delete(key: StorageKeys.onboardingCompleted);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}

