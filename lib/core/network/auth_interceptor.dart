import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../constants/api_endpoints.dart';
import '../security/secure_storage_service.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorageService _storageService;
  final VoidCallback? onUnauthorized;
  bool _isAutoAuthenticating = false;

  AuthInterceptor(this._storageService, {this.onUnauthorized});

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    options.headers['Accept'] = 'application/json';
    options.headers['Content-Type'] = 'application/json';

    String? token = await _storageService.getAuthToken();

    // Auto-login tester di Dev environment jika belum login (misal via browser web)
    if ((token == null || token.isEmpty) &&
        !_isAutoAuthenticating &&
        !options.path.contains('/auth/') &&
        AppConfig.instance.environment == AppEnvironment.dev) {
      _isAutoAuthenticating = true;
      try {
        final authDio = Dio(BaseOptions(
          baseUrl: options.baseUrl,
          headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
          connectTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 4),
        ));
        final loginRes = await authDio.post(
          ApiEndpoints.loginOtp,
          data: {'phone': '081234567890', 'code': '123456'},
        );
        token = loginRes.data?['data']?['token'];
        if (token != null && token.isNotEmpty) {
          await _storageService.saveAuthToken(token);
          await _storageService.saveEncryptedPin('123456');
        }
      } catch (_) {
        // Abaikan jika server backend belum siap
      } finally {
        _isAutoAuthenticating = false;
      }
    }

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      onUnauthorized?.call();
    }
    handler.next(err);
  }
}

typedef VoidCallback = void Function();


