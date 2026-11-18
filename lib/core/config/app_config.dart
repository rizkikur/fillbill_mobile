import '../security/secure_storage_service.dart';

enum AppEnvironment { dev, staging, prod }

class AppConfig {
  final AppEnvironment environment;
  final String apiBaseUrl;
  final int connectTimeoutMs;
  final int receiveTimeoutMs;
  final bool enableLogging;
  final bool enableMockFallback;
  bool enableAutoMockup;

  AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    this.connectTimeoutMs = 15000,
    this.receiveTimeoutMs = 15000,
    this.enableLogging = true,
    this.enableMockFallback = false,
    this.enableAutoMockup = false,
  });

  static late AppConfig _instance;
  static AppConfig get instance => _instance;

  /// Global flag: jika true, seluruh menu mengaktifkan contoh auto mockup (demo).
  /// Jika false (default), aplikasi berjalan murni live/prod (input kosong & API riil).
  static bool get isMockupEnabled => _instance.enableAutoMockup;

  static void setMockupEnabled(bool value) {
    _instance.enableAutoMockup = value;
  }

  static Future<void> loadSavedMockupPreference(SecureStorageService storage) async {
    final saved = await storage.isMockupEnabled();
    if (saved != null) {
      _instance.enableAutoMockup = saved;
    }
  }

  static void initialize(AppConfig config) {
    _instance = config;
  }

  static AppConfig dev() {
    return AppConfig(
      environment: AppEnvironment.dev,
      apiBaseUrl: 'http://127.0.0.1:8000/api/v1',
      connectTimeoutMs: 15000,
      receiveTimeoutMs: 15000,
      enableLogging: true,
      enableMockFallback: false,
      // Ubah defaultValue di bawah menjadi true jika ingin auto-mockup aktif secara default,
      // atau gunakan --dart-define=ENABLE_MOCKUP=true saat build
      enableAutoMockup: const bool.fromEnvironment('ENABLE_MOCKUP', defaultValue: false),
    );
  }

  static AppConfig prod() {
    return AppConfig(
      environment: AppEnvironment.prod,
      apiBaseUrl: 'https://api.fillbill.com/api/v1',
      enableLogging: false,
      enableMockFallback: false,
      enableAutoMockup: false,
    );
  }
}
