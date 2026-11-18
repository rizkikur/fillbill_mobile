import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_client.dart';
import '../domain/product_entity.dart';

abstract class ProductRemoteDataSource {
  Future<ApiResponse<HomeDashboardData>> getHomeDashboard();
  Future<ApiResponse<List<ProductEntity>>> getProductsByOperatorPrefix(String phone, {String? category});
  Future<ApiResponse<List<ProductEntity>>> getProducts({String? category, String? provider, String? type});
  Future<ApiResponse<Map<String, dynamic>>> inquirePostpaid({required String skuCode, required String customerNumber});
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final DioClient _client;

  ProductRemoteDataSourceImpl(this._client);

  @override
  Future<ApiResponse<HomeDashboardData>> getHomeDashboard() async {
    final res = await _client.get(ApiEndpoints.home);
    return ApiResponse.fromJson(
      res.data,
      (json) => HomeDashboardData.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<ApiResponse<List<ProductEntity>>> getProductsByOperatorPrefix(String phone, {String? category}) async {
    final Map<String, dynamic> query = {'phone': phone};
    if (category != null) query['category'] = category;

    final res = await _client.get(
      ApiEndpoints.operatorPrefix,
      queryParameters: query,
    );
    return ApiResponse.fromJson(
      res.data,
      (json) {
        final rawList = json is Map<String, dynamic>
            ? (json['products'] as List? ?? [])
            : (json is List ? json : []);
        return rawList.map((e) => ProductEntity.fromJson(e as Map<String, dynamic>)).toList();
      },
    );
  }

  @override
  Future<ApiResponse<List<ProductEntity>>> getProducts({
    String? category,
    String? provider,
    String? type,
  }) async {
    final Map<String, dynamic> query = {};
    if (category != null) query['category'] = category;
    if (provider != null) query['provider'] = provider;
    if (type != null) query['product_type'] = type;

    final res = await _client.get(
      ApiEndpoints.products,
      queryParameters: query.isEmpty ? null : query,
    );
    return ApiResponse.fromJson(
      res.data,
      (json) => (json as List).map((e) => ProductEntity.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> inquirePostpaid({
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
      (json) => json as Map<String, dynamic>,
    );
  }
}

