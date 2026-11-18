import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_client.dart';
import '../domain/user_entity.dart';

abstract class AuthRemoteDataSource {
  Future<ApiResponse<void>> requestOtp({required String phone, required String purpose});
  Future<ApiResponse<UserEntity>> register({required String phone, required String name, String? email});
  Future<ApiResponse<AuthTokenResult>> verifyRegister({required String phone, required String code});
  Future<ApiResponse<AuthTokenResult>> loginOtp({required String phone, required String code});
  Future<ApiResponse<UserEntity>> getProfile();
  Future<ApiResponse<void>> setupPin({required String pin, required String pinConfirmation});
  Future<void> logout();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient _client;

  AuthRemoteDataSourceImpl(this._client);

  @override
  Future<ApiResponse<void>> requestOtp({required String phone, required String purpose}) async {
    final res = await _client.post(
      ApiEndpoints.requestOtp,
      data: {'phone': phone, 'purpose': purpose},
    );
    return ApiResponse.fromJson(res.data, null);
  }

  @override
  Future<ApiResponse<UserEntity>> register({
    required String phone,
    required String name,
    String? email,
  }) async {
    final res = await _client.post(
      ApiEndpoints.register,
      data: {
        'phone': phone,
        'name': name,
        if (email != null && email.isNotEmpty) 'email': email,
      },
    );
    return ApiResponse.fromJson(
      res.data,
      (json) => UserEntity.fromJson(json['user'] as Map<String, dynamic>? ?? json),
    );
  }

  @override
  Future<ApiResponse<AuthTokenResult>> verifyRegister({
    required String phone,
    required String code,
  }) async {
    final res = await _client.post(
      ApiEndpoints.verifyRegister,
      data: {'phone': phone, 'code': code},
    );
    return ApiResponse.fromJson(
      res.data,
      (json) => AuthTokenResult.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<ApiResponse<AuthTokenResult>> loginOtp({
    required String phone,
    required String code,
  }) async {
    final res = await _client.post(
      ApiEndpoints.loginOtp,
      data: {'phone': phone, 'code': code},
    );
    return ApiResponse.fromJson(
      res.data,
      (json) => AuthTokenResult.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<ApiResponse<UserEntity>> getProfile() async {
    final res = await _client.get(ApiEndpoints.profileMe);
    return ApiResponse.fromJson(
      res.data,
      (json) => UserEntity.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<ApiResponse<void>> setupPin({
    required String pin,
    required String pinConfirmation,
  }) async {
    final res = await _client.post(
      ApiEndpoints.setupPin,
      data: {
        'pin': pin,
        'pin_confirmation': pinConfirmation,
      },
    );
    return ApiResponse.fromJson(res.data, null);
  }

  @override
  Future<void> logout() async {
    try {
      await _client.post(ApiEndpoints.logout);
    } catch (_) {}
  }
}

