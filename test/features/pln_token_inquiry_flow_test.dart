import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fillbill_mobile/core/config/app_config.dart';
import 'package:fillbill_mobile/core/config/mockup_provider.dart';
import 'package:fillbill_mobile/core/errors/app_exception.dart';
import 'package:fillbill_mobile/core/security/secure_storage_service.dart';
import 'package:fillbill_mobile/features/products/presentation/product_notifier.dart';
import 'package:fillbill_mobile/features/products/presentation/pln_transaction_screen.dart';
import 'package:fillbill_mobile/features/products/data/product_repository.dart';
import 'package:fillbill_mobile/features/products/domain/product_entity.dart';
import 'package:fillbill_mobile/features/products/data/product_remote_data_source.dart';

class MockSuccessProductRepo extends ProductRepository {
  MockSuccessProductRepo() : super(_DummyRemoteSource());

  @override
  Future<List<ProductEntity>> getProducts({String? category, String? provider, String? type}) async {
    return [
      const ProductEntity(
        id: 1,
        skuCode: 'PLN20',
        name: 'PLN Token Rp 20.000',
        description: 'Token 20rb',
        productType: 'prepaid',
        categoryCode: 'token_listrik',
        sellPriceCents: 2050000,
        sellPriceDisplay: 'Rp 20.500',
        provider: 'PLN',
        isActive: true,
      ),
    ];
  }

  @override
  Future<Map<String, dynamic>> inquireProduct({
    required String skuCode,
    required String customerNumber,
  }) async {
    return {
      'id': 777,
      'customer_number': customerNumber,
      'customer_name': 'MAHAYANA GARBILEKA 01',
      'tariff_power': 'R1 / 2200 VA',
      'amount': 2100000,
    };
  }
}

class MockFailingProductRepo extends ProductRepository {
  MockFailingProductRepo() : super(_DummyRemoteSource());

  @override
  Future<List<ProductEntity>> getProducts({String? category, String? provider, String? type}) async {
    return [
      const ProductEntity(
        id: 1,
        skuCode: 'PLN20',
        name: 'PLN Token Rp 20.000',
        description: 'Token 20rb',
        productType: 'prepaid',
        categoryCode: 'token_listrik',
        sellPriceCents: 2050000,
        sellPriceDisplay: 'Rp 20.500',
        provider: 'PLN',
        isActive: true,
      ),
    ];
  }

  @override
  Future<Map<String, dynamic>> inquireProduct({
    required String skuCode,
    required String customerNumber,
  }) async {
    throw AppException(
      message: 'Inquiry PLN gagal [RC: 007]: Gagal - Nomor tidak ditemukan',
      statusCode: 422,
    );
  }
}

class MockNetworkErrorProductRepo extends ProductRepository {
  MockNetworkErrorProductRepo() : super(_DummyRemoteSource());

  @override
  Future<List<ProductEntity>> getProducts({String? category, String? provider, String? type}) async {
    return [
      const ProductEntity(
        id: 1,
        skuCode: 'PLN20',
        name: 'PLN Token Rp 20.000',
        description: 'Token 20rb',
        productType: 'prepaid',
        categoryCode: 'token_listrik',
        sellPriceCents: 2050000,
        sellPriceDisplay: 'Rp 20.500',
        provider: 'PLN',
        isActive: true,
      ),
    ];
  }

  @override
  Future<Map<String, dynamic>> inquireProduct({
    required String skuCode,
    required String customerNumber,
  }) async {
    throw AppException.network();
  }
}

class _DummyRemoteSource implements ProductRemoteDataSource {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DummySecureStorage implements SecureStorageService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<bool?> isMockupEnabled() async => null;
}

class FixedMockupNotifier extends MockupModeNotifier {
  FixedMockupNotifier(bool initial) : super(_DummySecureStorage()) {
    state = initial;
  }
}

void main() {
  setUp(() {
    AppConfig.initialize(AppConfig.dev());
    AppConfig.setMockupEnabled(false);
  });

  group('PLN Token Inquiry Flow Verification', () {
    testWidgets('Live mode: failed inquiry shows prominent error card and prevents payment', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mockupModeProvider.overrideWith((ref) => FixedMockupNotifier(false)),
            productRepositoryProvider.overrideWithValue(MockFailingProductRepo()),
          ],
          child: const MaterialApp(
            home: PlnTransactionScreen(initialType: 'token'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Input 11 digit meter number
      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);
      await tester.enterText(textFieldFinder, '12000000000');
      await tester.pumpAndSettle();

      // Tap 'Cek ID Pelanggan'
      final checkBtn = find.text('Cek ID Pelanggan');
      expect(checkBtn, findsOneWidget);
      await tester.tap(checkBtn);
      await tester.pumpAndSettle();

      // Must show error card
      expect(find.textContaining('Nomor tidak ditemukan'), findsOneWidget);
      expect(find.text('Inquiry Pelanggan Gagal'), findsOneWidget);

      // Must NOT show verified card or Bayar button
      expect(find.text('Data Pelanggan PLN'), findsNothing);
      expect(find.text('Bayar Sekarang'), findsNothing);
    });

    testWidgets('Live mode: successful inquiry retrieves real subscriber name and unlocks nominal tokens', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mockupModeProvider.overrideWith((ref) => FixedMockupNotifier(false)),
            productRepositoryProvider.overrideWithValue(MockSuccessProductRepo()),
          ],
          child: const MaterialApp(
            home: PlnTransactionScreen(initialType: 'token'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Input 11 digit valid meter number
      final textFieldFinder = find.byType(TextField);
      await tester.enterText(textFieldFinder, '12000000001');
      await tester.pumpAndSettle();

      // Tap 'Cek ID Pelanggan'
      final checkBtn = find.text('Cek ID Pelanggan');
      await tester.tap(checkBtn);
      await tester.pumpAndSettle();

      // Verified customer card should be visible with real subscriber name & tariff
      expect(find.text('Data Pelanggan PLN'), findsOneWidget);
      expect(find.text('MAHAYANA GARBILEKA 01'), findsOneWidget);
      expect(find.text('R1 / 2200 VA'), findsOneWidget);

      // Nominal tokens are unlocked
      final tokenChipFinder = find.text('PLN Token Rp 20.000');
      expect(tokenChipFinder, findsOneWidget);
      await tester.tap(tokenChipFinder);
      await tester.pumpAndSettle();

      // Checkout bar appears with 'Bayar Sekarang'
      expect(find.text('Bayar Sekarang'), findsOneWidget);
    });

    testWidgets('Mockup mode ON: offline network error triggers fallback subscriber card for valid meter', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      AppConfig.setMockupEnabled(true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mockupModeProvider.overrideWith((ref) => FixedMockupNotifier(true)),
            productRepositoryProvider.overrideWithValue(MockNetworkErrorProductRepo()),
          ],
          child: const MaterialApp(
            home: PlnTransactionScreen(initialType: 'token'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // In mockup mode, meter controller is prefilled with 12000000001 and pre-inquired
      expect(find.text('Data Pelanggan PLN'), findsOneWidget);
      expect(find.text('MAHAYANA GARBILEKA 01'), findsOneWidget);

      // Tap nominal
      final tokenChipFinder = find.text('PLN Token Rp 20.000');
      expect(tokenChipFinder, findsOneWidget);
      await tester.tap(tokenChipFinder);
      await tester.pumpAndSettle();

      expect(find.text('Bayar Sekarang'), findsOneWidget);
    });

    testWidgets('Mockup mode ON: invalid meter 12000000000 is rejected even when offline', (tester) async {
      AppConfig.setMockupEnabled(true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mockupModeProvider.overrideWith((ref) => FixedMockupNotifier(true)),
            productRepositoryProvider.overrideWithValue(MockNetworkErrorProductRepo()),
          ],
          child: const MaterialApp(
            home: PlnTransactionScreen(initialType: 'token'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter failing meter number
      final textFieldFinder = find.byType(TextField);
      await tester.enterText(textFieldFinder, '12000000000');
      await tester.pumpAndSettle();

      // Tap 'Cek ID Pelanggan'
      final checkBtn = find.text('Cek ID Pelanggan');
      await tester.tap(checkBtn);
      await tester.pumpAndSettle();

      // Must show error card and NOT allow payment
      expect(find.textContaining('Nomor tidak ditemukan'), findsOneWidget);
      expect(find.text('Inquiry Pelanggan Gagal'), findsOneWidget);
      expect(find.text('Bayar Sekarang'), findsNothing);
    });
  });
}
