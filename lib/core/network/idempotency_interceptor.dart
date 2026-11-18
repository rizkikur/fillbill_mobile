import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

class IdempotencyInterceptor extends Interceptor {
  final Uuid _uuid = const Uuid();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Endpoints yang mengubah saldo finansial mewajibkan Idempotency-Key
    final isFinancialMutation = options.method == 'POST' &&
        (options.path.contains('/transactions') || options.path.contains('/wallet/topup'));

    if (isFinancialMutation && !options.headers.containsKey('Idempotency-Key')) {
      options.headers['Idempotency-Key'] = _uuid.v4();
    }

    handler.next(options);
  }
}

