import 'package:flutter_test/flutter_test.dart';
import 'package:fillbill_mobile/features/auth/domain/user_entity.dart';

void main() {
  group('UserEntity Serialization', () {
    test('parses json correctly with nested tier map', () {
      final json = {
        'id': 12,
        'name': 'Budi Santoso',
        'phone': '+6281234567890',
        'email': 'budi@example.com',
        'role': 'user',
        'tier': {'name': 'end_user', 'label': 'End User'},
        'is_verified': true,
        'created_at': '2026-10-20T14:00:00Z',
      };

      final user = UserEntity.fromJson(json);

      expect(user.id, equals(12));
      expect(user.name, equals('Budi Santoso'));
      expect(user.phone, equals('+6281234567890'));
      expect(user.tier, equals('end_user'));
      expect(user.isVerified, isTrue);
    });

    test('parses json with string tier fallback', () {
      final json = {
        'id': 15,
        'name': 'Agus Reseller',
        'phone': '+6281234567899',
        'role': 'user',
        'tier': 'reseller',
        'is_verified': true,
      };

      final user = UserEntity.fromJson(json);

      expect(user.id, equals(15));
      expect(user.tier, equals('reseller'));
      expect(user.email, isNull);
    });
  });

  group('AuthTokenResult Serialization', () {
    test('parses token and user correctly', () {
      final json = {
        'token': '1|sanctum_token_abc',
        'token_type': 'Bearer',
        'user': {
          'id': 12,
          'name': 'Budi Santoso',
          'phone': '+6281234567890',
          'role': 'user',
          'tier': 'end_user',
          'is_verified': true,
        },
      };

      final result = AuthTokenResult.fromJson(json);

      expect(result.token, equals('1|sanctum_token_abc'));
      expect(result.tokenType, equals('Bearer'));
      expect(result.user.name, equals('Budi Santoso'));
    });
  });
}

