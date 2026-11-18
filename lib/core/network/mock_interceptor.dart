import 'package:dio/dio.dart';
import '../config/app_config.dart';

class MockInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (!AppConfig.instance.enableMockFallback) {
      return handler.next(err);
    }

    final isConnectionError = err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout;
    final isAuthError = err.response?.statusCode == 401;

    if (!isConnectionError && !isAuthError) {
      return handler.next(err);
    }

    final path = err.requestOptions.path;
    final mockData = _getMockResponse(path, err.requestOptions.method);

    if (mockData != null) {
      return handler.resolve(
        Response(
          requestOptions: err.requestOptions,
          statusCode: 200,
          data: mockData,
        ),
      );
    }

    handler.next(err);
  }

  Map<String, dynamic>? _getMockResponse(String path, String method) {
    if (path.contains('/auth/otp')) {
      return {
        'success': true,
        'message': 'Kode OTP berhasil dikirim ke nomor Anda',
        'data': {
          'phone': '081234567890',
          'otp': '123456',
          'expires_in': 300,
        },
      };
    }

    if (path.contains('/auth/login') || path.contains('/auth/verify-register')) {
      return {
        'success': true,
        'message': 'Autentikasi berhasil',
        'data': {
          'token': 'demo_token_${DateTime.now().millisecondsSinceEpoch}',
          'user': {
            'id': 1,
            'name': 'Budi Santoso',
            'phone': '+6281234567890',
            'email': 'budi@example.com',
            'tier': {'name': 'end_user', 'label': 'End User'},
            'is_verified': true,
          },
        },
      };
    }

    if (path.contains('/auth/register')) {
      return {
        'success': true,
        'message': 'Pendaftaran berhasil',
        'data': {
          'user': {
            'id': 1,
            'name': 'Budi Santoso',
            'phone': '+6281234567890',
            'email': 'budi@example.com',
            'tier': {'name': 'end_user', 'label': 'End User'},
            'is_verified': true,
          },
        },
      };
    }

    if (path.contains('/auth/me')) {
      return {
        'success': true,
        'data': {
          'id': 1,
          'name': 'Budi Santoso',
          'phone': '+6281234567890',
          'email': 'budi@example.com',
          'tier': {'name': 'end_user', 'label': 'End User'},
          'is_verified': true,
        },
      };
    }

    if (path.contains('/security/pin/challenge')) {
      return {
        'success': true,
        'message': 'Challenge PIN (Demo Fallback)',
        'data': {
          'challenge_id': 'CHALLENGE-DEMO-${DateTime.now().millisecondsSinceEpoch}',
        },
      };
    }

    if (path.contains('/security/pin/verify')) {
      return {
        'success': true,
        'message': 'Verifikasi PIN Sukses (Demo Fallback)',
        'data': {
          'token': 'PIN-TOKEN-DEMO-${DateTime.now().millisecondsSinceEpoch}',
        },
      };
    }

    if (path.contains('/transactions') && method.toUpperCase() == 'POST') {
      return {
        'success': true,
        'message': 'Transaksi Berhasil Diproses',
        'data': {
          'id': DateTime.now().millisecondsSinceEpoch ~/ 1000,
          'sku_code': 'TLS-10000',
          'product_name': 'Telkomsel 10.000',
          'customer_number': '081234567890',
          'amount_cents': 1000000,
          'amount_display': 'Rp 10.000,00',
          'sell_price_cents': 1085000,
          'sell_price_display': 'Rp 10.850,00',
          'status': 'success',
          'provider_ref': 'SN-0041${DateTime.now().millisecondsSinceEpoch % 1000000000}',
          'created_at': DateTime.now().toIso8601String(),
        },
      };
    }
    if (path.contains('/home')) {
      return {
        'success': true,
        'message': 'Mock Home Data (Offline Mode)',
        'data': {
          'user': {
            'id': 1,
            'name': 'Budi Santoso',
            'phone': '+6281234567890',
            'email': 'budi@example.com',
            'tier': {'name': 'end_user', 'label': 'End User'},
            'is_verified': true,
          },
          'wallet': {
            'balance_cents': 25000000,
            'balance_display': 'Rp 250.000,00',
            'currency': 'IDR',
          },
          'categories': [
            {'id': 1, 'name': 'Pulsa', 'code': 'pulsa', 'icon_url': null},
            {'id': 2, 'name': 'Paket Data', 'code': 'paket_data', 'icon_url': null},
            {'id': 3, 'name': 'Token Listrik', 'code': 'token_listrik', 'icon_url': null},
            {'id': 4, 'name': 'Tagihan Listrik', 'code': 'tagihan_listrik', 'icon_url': null},
            {'id': 5, 'name': 'E-Money', 'code': 'emoney', 'icon_url': null},
            {'id': 6, 'name': 'PDAM Air', 'code': 'pdam', 'icon_url': null},
          ],
          'recent_transactions': [
            {
              'id': 101,
              'sku_code': 'TLS-10000',
              'product_name': 'Telkomsel 10.000',
              'customer_number': '081234567890',
              'amount_cents': 1000000,
              'amount_display': 'Rp 10.000,00',
              'sell_price_cents': 1100000,
              'sell_price_display': 'Rp 11.000,00',
              'status': 'success',
              'provider_ref': 'SN-20261109-99124',
              'created_at': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
            }
          ]
        }
      };
    }

    if (path.contains('/products/operator-prefix')) {
      return {
        'success': true,
        'data': [
          {
            'id': 1,
            'sku_code': 'TLS-5000',
            'name': 'Telkomsel 5.000',
            'description': 'Masa aktif 7 hari',
            'product_type': 'prepaid',
            'sell_price': 585000,
            'sell_price_display': 'Rp 5.850,00',
            'provider': 'Telkomsel',
            'is_active': true,
          },
          {
            'id': 2,
            'sku_code': 'TLS-10000',
            'name': 'Telkomsel 10.000',
            'description': 'Masa aktif 15 hari',
            'product_type': 'prepaid',
            'sell_price': 1085000,
            'sell_price_display': 'Rp 10.850,00',
            'provider': 'Telkomsel',
            'is_active': true,
          },
        ]
      };
    }

    if (path.contains('/wallet/channels')) {
      return {
        'success': true,
        'data': [
          {
            'group': 'Virtual Account',
            'items': [
              {
                'code': 'bca_va',
                'name': 'BCA Virtual Account',
                'fee_display': 'Rp 2.500',
                'fee_type': 'flat',
                'is_active': true,
              },
              {
                'code': 'mandiri_va',
                'name': 'Mandiri Virtual Account',
                'fee_display': 'Rp 2.500',
                'fee_type': 'flat',
                'is_active': true,
              }
            ]
          },
          {
            'group': 'Instant QRIS',
            'items': [
              {
                'code': 'qris',
                'name': 'QRIS All Payment',
                'fee_display': '0.7%',
                'fee_type': 'percentage',
                'is_active': true,
              }
            ]
          }
        ]
      };
    }

    if (path.contains('/wallet/mutations')) {
      return {
        'success': true,
        'data': [
          {
            'id': 1,
            'type': 'credit',
            'amount_cents': 50000000,
            'amount_display': 'Rp 500.000,00',
            'description': 'Top Up Saldo via BCA VA',
            'reference': 'TOPUP-20261109-01',
            'balance_after_cents': 50000000,
            'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
          },
          {
            'id': 2,
            'type': 'debit',
            'amount_cents': 1085000,
            'amount_display': 'Rp 10.850,00',
            'description': 'Pembelian Telkomsel 10.000',
            'reference': 'TRX-20261109-99',
            'balance_after_cents': 48915000,
            'created_at': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
          },
        ]
      };
    }

    if (path.contains('/wallet')) {
      return {
        'success': true,
        'data': {
          'balance_cents': 25000000,
          'balance_display': 'Rp 250.000,00',
          'currency': 'IDR',
        }
      };
    }

    if (path.contains('/products')) {
      return {
        'success': true,
        'data': [
          {
            'id': 101,
            'sku_code': 'DANA20',
            'name': 'DANA Rp 20.000',
            'category': 'emoney',
            'brand': 'DANA',
            'sell_price_cents': 2000000,
            'sell_price_display': 'Rp 20.000',
            'admin_fee': 1000,
            'admin_fee_display': 'Rp 1.000',
            'is_active': true,
          },
          {
            'id': 102,
            'sku_code': 'DANA50',
            'name': 'DANA Rp 50.000',
            'category': 'emoney',
            'brand': 'DANA',
            'sell_price_cents': 5000000,
            'sell_price_display': 'Rp 50.000',
            'admin_fee': 1000,
            'admin_fee_display': 'Rp 1.000',
            'is_active': true,
          },
          {
            'id': 103,
            'sku_code': 'DANA100',
            'name': 'DANA Rp 100.000',
            'category': 'emoney',
            'brand': 'DANA',
            'sell_price_cents': 10000000,
            'sell_price_display': 'Rp 100.000',
            'admin_fee': 1000,
            'admin_fee_display': 'Rp 1.000',
            'is_active': true,
          },
        ]
      };
    }

    return null;
  }
}

