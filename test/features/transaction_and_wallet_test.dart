import 'package:flutter_test/flutter_test.dart';
import 'package:fillbill_mobile/features/transactions/domain/transaction_entity.dart';
import 'package:fillbill_mobile/features/wallet/domain/wallet_entity.dart';

void main() {
  group('Transaction & Wallet Entities Test Suite', () {
    test('TransactionEntity serialization and field mapping', () {
      final json = {
        'id': 101,
        'user_id': 1,
        'product': {
          'name': 'Telkomsel Data 10GB',
          'sku_code': 'TD10GB',
        },
        'customer_number': '081234567890',
        'sell_price': 52000,
        'sell_price_display': 'Rp 52.000',
        'status': 'success',
        'provider_ref': 'SN1234567890',
        'created_at': '2026-11-09T11:30:00Z',
      };

      final tx = TransactionEntity.fromJson(json);
      expect(tx.id, 101);
      expect(tx.status, 'success');
      expect(tx.sellPriceDisplay, 'Rp 52.000');
      expect(tx.providerRef, 'SN1234567890');
      expect(tx.productName, 'Telkomsel Data 10GB');
      expect(tx.customerNumber, '081234567890');
    });

    test('InquiryEntity serialization', () {
      final json = {
        'id': 99,
        'product': {
          'name': 'PLN Prepaid 50k',
          'sku_code': 'PLNPRE50',
        },
        'customer_number': '14234567890',
        'amount': 50000,
        'amount_display': 'Rp 50.000',
        'admin_fee': 1500,
        'admin_fee_display': 'Rp 1.500',
        'status': 'success',
        'expires_at': '2026-11-09T12:00:00Z',
      };

      final inq = InquiryEntity.fromJson(json);
      expect(inq.id, 99);
      expect(inq.productName, 'PLN Prepaid 50k');
      expect(inq.skuCode, 'PLNPRE50');
      expect(inq.amountDisplay, 'Rp 50.000');
      expect(inq.adminFeeDisplay, 'Rp 1.500');
    });

    test('WalletMutationEntity serialization', () {
      final json = {
        'id': 201,
        'type': 'credit',
        'amount': 100000,
        'amount_display': '+Rp 100.000',
        'balance_after': 150000,
        'balance_after_display': 'Rp 150.000',
        'reference_type': 'topup',
        'note': 'Top Up Saldo via BCA VA',
        'created_at': '2026-11-09T10:00:00Z',
      };

      final mutation = WalletMutationEntity.fromJson(json);
      expect(mutation.id, 201);
      expect(mutation.type, 'credit');
      expect(mutation.amountDisplay, '+Rp 100.000');
      expect(mutation.referenceType, 'topup');
      expect(mutation.note, 'Top Up Saldo via BCA VA');
    });
  });
}
