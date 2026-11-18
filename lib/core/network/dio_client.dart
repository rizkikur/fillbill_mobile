import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../config/app_config.dart';
import '../errors/app_exception.dart';
import '../security/secure_storage_service.dart';
import 'auth_interceptor.dart';
import 'idempotency_interceptor.dart';
import 'mock_interceptor.dart';

class DioClient {
  final Dio _dio;

  DioClient({
    Dio? dio,
    required SecureStorageService storageService,
    VoidCallback? onUnauthorized,
  }) : _dio = dio ?? Dio() {
    final config = AppConfig.instance;

    _dio.options = BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: Duration(milliseconds: config.connectTimeoutMs),
      receiveTimeout: Duration(milliseconds: config.receiveTimeoutMs),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );

    _dio.interceptors.addAll([
      AuthInterceptor(storageService, onUnauthorized: onUnauthorized),
      IdempotencyInterceptor(),
      MockInterceptor(),
      if (config.enableLogging)
        PrettyDioLogger(
          requestHeader: false,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          error: true,
          compact: true,
        ),
    ]);
  }

  Dio get rawDio => _dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(path, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(path, data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put<T>(path, data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  AppException _handleError(DioException error) {
    if (error.response?.data is Map<String, dynamic>) {
      return AppException.fromResponse(
        error.response!.data as Map<String, dynamic>,
        error.response?.statusCode,
      );
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return AppException.network();
    }

    return AppException(
      message: error.message ?? 'Terjadi kesalahan sistem tidak dikenal',
      statusCode: error.response?.statusCode,
    );
  }
}

