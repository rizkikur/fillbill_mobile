import 'package:dio/dio.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_client.dart';
import '../domain/wallet_entity.dart';

abstract class WalletRemoteDataSource {
  Future<ApiResponse<Map<String, dynamic>>> getWalletBalance();
  Future<ApiResponse<List<TopupGroupEntity>>> getTopupChannels();
  Future<ApiResponse<TopupResultEntity>> requestTopup({
    required int amountCents,
    String method = 'payment_gateway',
    String paymentGateway = 'midtrans',
    required String idempotencyKey,
  });
  Future<ApiResponse<List<WalletMutationEntity>>> getMutations({String? type, int page = 1});
}

class WalletRemoteDataSourceImpl implements WalletRemoteDataSource {
  final DioClient _client;

  WalletRemoteDataSourceImpl(this._client);

  @override
  Future<ApiResponse<Map<String, dynamic>>> getWalletBalance() async {
    final res = await _client.get(ApiEndpoints.wallet);
    return ApiResponse.fromJson(
      res.data,
      (json) => json as Map<String, dynamic>,
    );
  }

  @override
  Future<ApiResponse<List<TopupGroupEntity>>> getTopupChannels() async {
    final res = await _client.get(ApiEndpoints.walletChannels);
    return ApiResponse.fromJson(
      res.data,
      (json) => (json as List).map((e) => TopupGroupEntity.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  @override
  Future<ApiResponse<TopupResultEntity>> requestTopup({
    required int amountCents,
    String method = 'payment_gateway',
    String paymentGateway = 'midtrans',
    required String idempotencyKey,
  }) async {
    final res = await _client.post(
      ApiEndpoints.walletTopup,
      data: {
        'amount': amountCents,
        'method': method,
        'payment_gateway': paymentGateway,
      },
      options: Options(
        headers: {
          'Idempotency-Key': idempotencyKey,
        },
      ),
    );

    return ApiResponse.fromJson(
      res.data,
      (json) => TopupResultEntity.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<ApiResponse<List<WalletMutationEntity>>> getMutations({String? type, int page = 1}) async {
    final Map<String, dynamic> query = {'page': page};
    if (type != null && type.isNotEmpty && type != 'all') {
      query['type'] = type;
    }

    final res = await _client.get(
      ApiEndpoints.walletMutations,
      queryParameters: query,
    );

    return ApiResponse.fromJson(
      res.data,
      (json) => (json as List).map((e) => WalletMutationEntity.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

