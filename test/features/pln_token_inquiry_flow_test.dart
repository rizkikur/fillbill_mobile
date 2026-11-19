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

  group('PLN Token Flow (Validasi Input -> Tampil Produk -> Inq -> Popup Konfirmasi)', () {
    testWidgets('1. Sebelum nomor 11-12 digit diinput, produk belum muncul', (tester) async {
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

      // Placeholder instruksi harus muncul
      expect(find.text('Masukkan Nomor Meter / IDPEL'), findsOneWidget);
      // Grid produk TIDAK boleh muncul
      expect(find.text('PLN Token Rp 20.000'), findsNothing);
      expect(find.text('Pilih Nominal Token'), findsNothing);
    });

    testWidgets('2. Setelah nomor 11 digit valid diinput, produk muncul', (tester) async {
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

      // Input nomor meter 11 digit valid
      final textFieldFinder = find.byType(TextField);
      await tester.enterText(textFieldFinder, '12000000001');
      await tester.pumpAndSettle();

      // Sekarang pilihan produk harus muncul
      expect(find.text('Pilih Nominal Token'), findsOneWidget);
      expect(find.text('PLN Token Rp 20.000'), findsOneWidget);
    });

    testWidgets('3. Klik nominal -> Inq Sukses -> Tampil POPUP (Bottom Sheet) Data Pelanggan & Bayar', (tester) async {
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

      // Input 11 digit valid
      final textFieldFinder = find.byType(TextField);
      await tester.enterText(textFieldFinder, '12000000001');
      await tester.pumpAndSettle();

      // Klik token nominal
      final tokenChipFinder = find.text('PLN Token Rp 20.000');
      expect(tokenChipFinder, findsOneWidget);
      await tester.tap(tokenChipFinder);
      await tester.pumpAndSettle();

      // POPUP Modal Bottom Sheet harus muncul dengan data pelanggan & rincian pembayaran
      expect(find.text('Konfirmasi Pembelian Token'), findsOneWidget);
      expect(find.text('DATA PELANGGAN PLN'), findsOneWidget);
      expect(find.text('MAHAYANA GARBILEKA 01'), findsOneWidget);
      expect(find.text('R1 / 2200 VA'), findsOneWidget);
      expect(find.text('RINCIAN PEMBAYARAN'), findsOneWidget);
      expect(find.text('Bayar Sekarang'), findsOneWidget);
    });

    testWidgets('4. Nomor tidak terdaftar (RC 007) -> Tampil Error Alert dan TIDAK muncul popup bayar', (tester) async {
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

      // Input 11 digit
      final textFieldFinder = find.byType(TextField);
      await tester.enterText(textFieldFinder, '12000000000');
      await tester.pumpAndSettle();

      // Klik token nominal
      final tokenChipFinder = find.text('PLN Token Rp 20.000');
      await tester.tap(tokenChipFinder);
      await tester.pumpAndSettle();

      // Error Alert Dialog harus muncul
      expect(find.text('Inquiry Gagal'), findsOneWidget);
      expect(find.textContaining('Nomor tidak ditemukan'), findsWidgets);

      // Popup konfirmasi bayar TIDAK boleh ada
      expect(find.text('Konfirmasi Pembelian Token'), findsNothing);
    });
  });
}
