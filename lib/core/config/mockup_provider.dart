import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/auth_notifier.dart';
import '../security/secure_storage_service.dart';
import 'app_config.dart';

final mockupModeProvider = StateNotifierProvider<MockupModeNotifier, bool>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return MockupModeNotifier(storage);
});

class MockupModeNotifier extends StateNotifier<bool> {
  final SecureStorageService _storage;

  MockupModeNotifier(this._storage) : super(AppConfig.isMockupEnabled) {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    final saved = await _storage.isMockupEnabled();
    if (saved != null) {
      state = saved;
      AppConfig.setMockupEnabled(saved);
    }
  }

  Future<void> setEnabled(bool value) async {
    state = value;
    AppConfig.setMockupEnabled(value);
    await _storage.setMockupEnabled(value);
  }
}

