import 'package:dio/dio.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_client.dart';
import '../domain/transaction_entity.dart';

abstract class TransactionRemoteDataSource {
  Future<String> requestPinChallenge({String purpose = 'transaction'});
  Future<String> verifyPin({required String challengeId, required String pin, String purpose = 'transaction'});
  Future<ApiResponse<InquiryEntity>> createInquiry({required String skuCode, required String customerNumber});
  Future<ApiResponse<TransactionEntity>> executePayment({
    required String skuCode,
    required String customerNumber,
    int? inquiryId,
    int? amount,
    required String idempotencyKey,
    required String pinToken,
  });
  Future<ApiResponse<TransactionEntity>> getTransactionDetail(int id);
  Future<ApiResponse<List<TransactionEntity>>> getTransactionHistory({String? status, int page = 1});
}

class TransactionRemoteDataSourceImpl implements TransactionRemoteDataSource {
  final DioClient _client;

  TransactionRemoteDataSourceImpl(this._client);

  @override
  Future<String> requestPinChallenge({String purpose = 'transaction'}) async {
    final res = await _client.post(
      ApiEndpoints.pinChallenge,
      data: {'purpose': purpose},
    );
    final data = res.data['data'] as Map<String, dynamic>;
    return data['challenge_id'] as String;
  }

  @override
  Future<String> verifyPin({
    required String challengeId,
    required String pin,
    String purpose = 'transaction',
  }) async {
    final res = await _client.post(
      ApiEndpoints.pinVerify,
      data: {
        'challenge_id': challengeId,
        'pin': pin,
        'purpose': purpose,
      },
    );
    final data = res.data['data'] as Map<String, dynamic>;
    return (data['pin_verification_token'] ?? data['token']) as String;
  }

  @override
  Future<ApiResponse<InquiryEntity>> createInquiry({
    required String skuCode,
    required String customerNumber,
  }) async {
    final res = await _client.post(
      ApiEndpoints.inquiry,
      data: {
        'sku_code': skuCode,
        'customer_number': customerNumber,
      },
    );
    return ApiResponse.fromJson(
      res.data,
      (json) => InquiryEntity.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<ApiResponse<TransactionEntity>> executePayment({
    required String skuCode,
    required String customerNumber,
    int? inquiryId,
    int? amount,
    required String idempotencyKey,
    required String pinToken,
  }) async {
    final Map<String, dynamic> data = {
      'sku_code': skuCode,
      'customer_number': customerNumber,
    };
    if (inquiryId != null) {
      data['inquiry_id'] = inquiryId;
    }
    if (amount != null && amount > 0) {
      data['amount'] = amount;
    }

    final res = await _client.post(
      ApiEndpoints.transactions,
      data: data,
      options: Options(
        headers: {
          'Idempotency-Key': idempotencyKey,
          'X-Pin-Token': pinToken,
        },
      ),
    );

    return ApiResponse.fromJson(
      res.data,
      (json) => TransactionEntity.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<ApiResponse<TransactionEntity>> getTransactionDetail(int id) async {
    final res = await _client.get(ApiEndpoints.transactionDetail(id));
    return ApiResponse.fromJson(
      res.data,
      (json) => TransactionEntity.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<ApiResponse<List<TransactionEntity>>> getTransactionHistory({
    String? status,
    int page = 1,
  }) async {
    final Map<String, dynamic> query = {'page': page};
    if (status != null && status.isNotEmpty && status != 'all') {
      query['status'] = status;
    }

    final res = await _client.get(
      ApiEndpoints.transactions,
      queryParameters: query,
    );

    return ApiResponse.fromJson(
      res.data,
      (json) => (json as List).map((e) => TransactionEntity.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

