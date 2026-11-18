import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Foundation imports
import 'package:fillbill_mobile/core/theme/app_colors.dart';
import 'package:fillbill_mobile/core/constants/storage_keys.dart';
import 'package:fillbill_mobile/core/security/secure_storage_service.dart';
import 'package:fillbill_mobile/core/config/app_config.dart';

// Wallet & Product imports
import 'package:fillbill_mobile/features/wallet/data/mock_wallet_store.dart';
import 'package:fillbill_mobile/features/wallet/data/wallet_repository.dart';
import 'package:fillbill_mobile/features/wallet/data/wallet_remote_data_source.dart';
import 'package:fillbill_mobile/features/wallet/domain/wallet_entity.dart';
import 'package:fillbill_mobile/features/products/data/product_repository.dart';
import 'package:fillbill_mobile/features/products/data/product_remote_data_source.dart';
import 'package:fillbill_mobile/features/products/domain/product_entity.dart';
import 'package:fillbill_mobile/core/network/api_response.dart';

// ============================================================================
// TEST HARNESS: HERMETIC IN-MEMORY FAKES (Zero External Mock Library Dependencies)
// ============================================================================

class FakeFlutterSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> _store = {};

  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      _store.remove(key);
    } else {
      _store[key] = value;
    }
  }

  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _store[key];
  }

  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _store.remove(key);
  }

  Future<void> deleteAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _store.clear();
  }
}

class FakeProductRemoteDataSource extends Fake implements ProductRemoteDataSource {
  final bool shouldThrow;

  FakeProductRemoteDataSource({this.shouldThrow = true});

  @override
  Future<ApiResponse<HomeDashboardData>> getHomeDashboard() async {
    if (shouldThrow) {
      throw Exception('Remote network failure (triggering mockup fallback)');
    }
    return const ApiResponse<HomeDashboardData>(
      success: true,
      data: HomeDashboardData(
        balanceCents: 99900000,
        balanceDisplay: 'Rp 999.000,00',
        categories: [],
        recentTransactions: [],
      ),
    );
  }
}

class FakeWalletRemoteDataSource extends Fake implements WalletRemoteDataSource {
  final bool shouldThrow;

  FakeWalletRemoteDataSource({this.shouldThrow = true});

  @override
  Future<ApiResponse<List<WalletMutationEntity>>> getMutations({String? type, int page = 1}) async {
    if (shouldThrow) {
      throw Exception('Remote network failure (triggering mockup fallback)');
    }
    return const ApiResponse<List<WalletMutationEntity>>(
      success: true,
      data: [],
    );
  }

  @override
  Future<ApiResponse<TopupResultEntity>> requestTopup({
    required int amountCents,
    String method = 'payment_gateway',
    String paymentGateway = 'midtrans',
    required String idempotencyKey,
  }) async {
    if (shouldThrow) {
      throw Exception('Remote network failure (triggering mockup fallback)');
    }
    return ApiResponse<TopupResultEntity>(
      success: true,
      data: TopupResultEntity(
        id: 1,
        amountCents: amountCents,
        amountDisplay: 'Rp ${amountCents ~/ 100}',
        method: method,
        paymentGateway: paymentGateway,
        paymentUrl: 'https://real.api.payment.url',
        status: 'pending',
      ),
    );
  }
}

// ============================================================================
// MAIN TEST SUITE: 5 TEST GROUPS
// ============================================================================

void main() {
  setUpAll(() {
    AppConfig.initialize(AppConfig.dev());
  });

  // --------------------------------------------------------------------------
  // GROUP 1: AppColors Neo-Green Design System Tokens
  // --------------------------------------------------------------------------
  group('1. AppColors Neo-Green Design Tokens', () {
    test('Token color values and alpha transparency match exact specification', () {
      expect(AppColors.neoGreen, equals(const Color(0xFFA3E635)));
      expect(AppColors.neoGreenDark, equals(const Color(0xFF65A30D)));
      expect(AppColors.neoGreenLight, equals(const Color(0xFFBEF264)));
      expect(AppColors.neoGreenGlow, equals(const Color(0x66A3E635)));
      expect(AppColors.neoGreenSurface, equals(const Color(0xFFF7FEE7)));
      expect(AppColors.neoGreenContrast, equals(const Color(0xFF142900)));

      // Opacity checks
      expect((AppColors.neoGreen.a * 255).round(), equals(0xFF));
      expect((AppColors.neoGreenDark.a * 255).round(), equals(0xFF));
      expect((AppColors.neoGreenLight.a * 255).round(), equals(0xFF));
      expect((AppColors.neoGreenGlow.a * 255).round(), equals(0x66)); // 40% glow halo
      expect((AppColors.neoGreenSurface.a * 255).round(), equals(0xFF));
      expect((AppColors.neoGreenContrast.a * 255).round(), equals(0xFF));
    });

    test('Luminance hierarchy follows strict perceptual order', () {
      final surfaceLum = AppColors.neoGreenSurface.computeLuminance();
      final lightLum = AppColors.neoGreenLight.computeLuminance();
      final baseLum = AppColors.neoGreen.computeLuminance();
      final darkLum = AppColors.neoGreenDark.computeLuminance();
      final contrastLum = AppColors.neoGreenContrast.computeLuminance();

      expect(surfaceLum, greaterThan(lightLum), reason: 'Surface must be the brightest background');
      expect(lightLum, greaterThan(baseLum), reason: 'Light tint must be brighter than base');
      expect(baseLum, greaterThan(darkLum), reason: 'Base must be brighter than dark shade');
      expect(darkLum, greaterThan(contrastLum), reason: 'Dark shade must be brighter than high-contrast foreground');
    });

    test('WCAG contrast ratio between neoGreen and neoGreenContrast meets AAA standard', () {
      final l1 = AppColors.neoGreen.computeLuminance();
      final l2 = AppColors.neoGreenContrast.computeLuminance();
      final contrastRatio = (l1 + 0.05) / (l2 + 0.05);

      // Must exceed 7:1 for WCAG AAA compliance on text and iconography
      expect(contrastRatio, greaterThanOrEqualTo(7.0),
          reason: 'NeoGreenContrast on NeoGreen must meet WCAG AAA contrast standard (>= 7:1)');

      // Verify that white on neoGreen fails accessibility, demonstrating why neoGreenContrast is mandatory
      final whiteLum = Colors.white.computeLuminance();
      final whiteContrastRatio = (whiteLum + 0.05) / (l1 + 0.05);
      expect(whiteContrastRatio, lessThan(3.0),
          reason: 'White text on NeoGreen fails minimum WCAG AA, requiring neoGreenContrast');
    });
  });

  // --------------------------------------------------------------------------
  // GROUP 2: StorageKeys Constants
  // --------------------------------------------------------------------------
  group('2. StorageKeys Onboarding Key', () {
    test('StorageKeys.onboardingCompleted has correct snake_case string value', () {
      expect(StorageKeys.onboardingCompleted, equals('onboarding_completed'));
    });

    test('StorageKeys entries are unique without collision', () {
      final allKeys = [
        StorageKeys.authToken,
        StorageKeys.userData,
        StorageKeys.biometricEnabled,
        StorageKeys.encryptedPin,
        StorageKeys.fcmToken,
        StorageKeys.mockupEnabled,
        StorageKeys.onboardingCompleted,
      ];

      expect(allKeys.toSet().length, equals(allKeys.length),
          reason: 'All storage keys must be distinct to avoid data overwriting');
    });
  });

  // --------------------------------------------------------------------------
  // GROUP 3: SecureStorageService Onboarding Persistence
  // --------------------------------------------------------------------------
  group('3. SecureStorageService Onboarding Methods', () {
    late FakeFlutterSecureStorage fakeStorage;
    late SecureStorageService storageService;

    setUp(() {
      fakeStorage = FakeFlutterSecureStorage();
      storageService = SecureStorageService(fakeStorage);
    });

    test('isOnboardingCompleted returns false by default for new installs', () async {
      final completed = await storageService.isOnboardingCompleted();
      expect(completed, isFalse);
    });

    test('setOnboardingCompleted(true) persists true state', () async {
      await storageService.setOnboardingCompleted(true);
      final completed = await storageService.isOnboardingCompleted();
      expect(completed, isTrue);

      final raw = await fakeStorage.read(key: StorageKeys.onboardingCompleted);
      expect(raw, equals('true'));
    });

    test('setOnboardingCompleted(false) persists false state', () async {
      await storageService.setOnboardingCompleted(true);
      expect(await storageService.isOnboardingCompleted(), isTrue);

      await storageService.setOnboardingCompleted(false);
      expect(await storageService.isOnboardingCompleted(), isFalse);

      final raw = await fakeStorage.read(key: StorageKeys.onboardingCompleted);
      expect(raw, equals('false'));
    });

    test('clearOnboardingCompleted removes key and resets status to false', () async {
      await storageService.setOnboardingCompleted(true);
      expect(await storageService.isOnboardingCompleted(), isTrue);

      await storageService.clearOnboardingCompleted();
      expect(await storageService.isOnboardingCompleted(), isFalse);

      final raw = await fakeStorage.read(key: StorageKeys.onboardingCompleted);
      expect(raw, isNull);
    });

    test('clearAll wipes onboarding state along with all credentials', () async {
      await storageService.setOnboardingCompleted(true);
      await storageService.saveAuthToken('dummy_token_123');

      await storageService.clearAll();

      expect(await storageService.isOnboardingCompleted(), isFalse);
      expect(await storageService.getAuthToken(), isNull);
    });

    test('isOnboardingCompleted safely handles unexpected or corrupted raw values', () async {
      await fakeStorage.write(key: StorageKeys.onboardingCompleted, value: '1');
      expect(await storageService.isOnboardingCompleted(), isFalse);

      await fakeStorage.write(key: StorageKeys.onboardingCompleted, value: 'TRUE');
      expect(await storageService.isOnboardingCompleted(), isFalse);

      await fakeStorage.write(key: StorageKeys.onboardingCompleted, value: '');
      expect(await storageService.isOnboardingCompleted(), isFalse);
    });
  });

  // --------------------------------------------------------------------------
  // GROUP 4: MockWalletStore Stateful Singleton Operations
  // --------------------------------------------------------------------------
  group('4. MockWalletStore Stateful Singleton', () {
    late MockWalletStore store;

    setUp(() {
      store = MockWalletStore.instance;
      store.reset();
    });

    test('Singleton returns identical instance reference', () {
      expect(identical(MockWalletStore.instance, MockWalletStore.instance), isTrue);
    });

    test('Initial state reflects Rp 250.000 (25,000,000 cents) and 3 baseline mutations', () {
      expect(store.balanceCents, equals(25000000));
      expect(store.balanceDisplay, equals('Rp 250.000,00'));
      expect(store.mutations.length, equals(3));

      expect(store.mutations[0].id, equals(301));
      expect(store.mutations[0].type, equals('credit'));
      expect(store.mutations[1].id, equals(302));
      expect(store.mutations[1].type, equals('debit'));
      expect(store.mutations[2].id, equals(303));
      expect(store.mutations[2].type, equals('credit'));
    });

    test('Mutations getter exposes an unmodifiable list', () {
      expect(
        () => store.mutations.add(
          const WalletMutationEntity(
            id: 999,
            type: 'credit',
            amountCents: 1000,
            amountDisplay: 'Rp 10,00',
            balanceAfterCents: 25001000,
            balanceAfterDisplay: 'Rp 250.010,00',
            referenceType: 'test',
          ),
        ),
        throwsUnsupportedError,
      );
    });

    test('addTopup increments balance and prepends a new mutation record', () {
      store.addTopup(
        amountCents: 5000000, // Rp 50.000,00
        channelCode: 'bca_va',
        channelName: 'BCA Virtual Account',
      );

      expect(store.balanceCents, equals(30000000));
      expect(store.balanceDisplay, equals('Rp 300.000,00'));
      expect(store.mutations.length, equals(4));

      final newest = store.mutations.first;
      expect(newest.type, equals('credit'));
      expect(newest.amountCents, equals(5000000));
      expect(newest.amountDisplay, equals('Rp 50.000,00'));
      expect(newest.balanceAfterCents, equals(30000000));
      expect(newest.balanceAfterDisplay, equals('Rp 300.000,00'));
      expect(newest.referenceType, equals('topup'));
      expect(newest.note, contains('BCA Virtual Account'));
      expect(newest.createdAt, isNotNull);
    });

    test('Multiple sequential top-ups accumulate balance correctly', () {
      store.addTopup(
        amountCents: 5000000,
        channelCode: 'bca_va',
        channelName: 'BCA Virtual Account',
      );
      store.addTopup(
        amountCents: 10000000,
        channelCode: 'qris',
        channelName: 'QRIS',
      );

      expect(store.balanceCents, equals(40000000));
      expect(store.balanceDisplay, equals('Rp 400.000,00'));
      expect(store.mutations.length, equals(5));
      expect(store.mutations[0].amountCents, equals(10000000));
      expect(store.mutations[0].balanceAfterCents, equals(40000000));
      expect(store.mutations[1].amountCents, equals(5000000));
      expect(store.mutations[1].balanceAfterCents, equals(30000000));
    });

    test('reset restores initial balance and default 3 mutations', () {
      store.addTopup(
        amountCents: 20000000,
        channelCode: 'bri_va',
        channelName: 'BRI Virtual Account',
      );
      expect(store.balanceCents, equals(45000000));
      expect(store.mutations.length, equals(4));

      store.reset();

      expect(store.balanceCents, equals(25000000));
      expect(store.balanceDisplay, equals('Rp 250.000,00'));
      expect(store.mutations.length, equals(3));
    });

    test('formatCurrency static helper formats rupiah properly', () {
      expect(MockWalletStore.formatCurrency(0), equals('Rp 0,00'));
      expect(MockWalletStore.formatCurrency(100000), equals('Rp 1.000,00'));
      expect(MockWalletStore.formatCurrency(5000000), equals('Rp 50.000,00'));
      expect(MockWalletStore.formatCurrency(25000000), equals('Rp 250.000,00'));
    });
  });

  // --------------------------------------------------------------------------
  // GROUP 5: Repository Integration with MockWalletStore
  // --------------------------------------------------------------------------
  group('5. Repository Bindings with MockWalletStore', () {
    late ProductRepository productRepo;
    late WalletRepository walletRepo;

    setUp(() {
      AppConfig.setMockupEnabled(true);
      MockWalletStore.instance.reset();

      productRepo = ProductRepository(FakeProductRemoteDataSource(shouldThrow: true));
      walletRepo = WalletRepository(FakeWalletRemoteDataSource(shouldThrow: true));
    });

    tearDown(() {
      AppConfig.setMockupEnabled(false);
      MockWalletStore.instance.reset();
    });

    test('ProductRepository.getHomeDashboard reads live balance from MockWalletStore in mockup mode', () async {
      final initialDashboard = await productRepo.getHomeDashboard();
      expect(initialDashboard.balanceCents, equals(MockWalletStore.instance.balanceCents));
      expect(initialDashboard.balanceDisplay, equals(MockWalletStore.instance.balanceDisplay));

      // Simulate a topup
      MockWalletStore.instance.addTopup(
        amountCents: 15000000,
        channelCode: 'mandiri_va',
        channelName: 'Mandiri Virtual Account',
      );

      final updatedDashboard = await productRepo.getHomeDashboard();
      expect(updatedDashboard.balanceCents, equals(40000000));
      expect(updatedDashboard.balanceDisplay, equals('Rp 400.000,00'));
    });

    test('WalletRepository.getMutations delegates to MockWalletStore with type filtering', () async {
      final allMutations = await walletRepo.getMutations();
      expect(allMutations.length, equals(3));

      final creditMutations = await walletRepo.getMutations(type: 'credit');
      expect(creditMutations.every((m) => m.type.toLowerCase() == 'credit'), isTrue);
      expect(creditMutations.length, equals(2)); // ID 301 and 303

      final debitMutations = await walletRepo.getMutations(type: 'debit');
      expect(debitMutations.every((m) => m.type.toLowerCase() == 'debit'), isTrue);
      expect(debitMutations.length, equals(1)); // ID 302
    });

    test('WalletRepository.requestTopup triggers MockWalletStore.addTopup in mockup mode', () async {
      expect(MockWalletStore.instance.balanceCents, equals(25000000));

      final result = await walletRepo.requestTopup(
        amountCents: 5000000,
        channelCode: 'bca_va',
        channelName: 'BCA Virtual Account',
      );

      expect(result.amountCents, equals(5000000));
      expect(result.status, equals('pending'));
      expect(result.paymentUrl, contains('SNAP-MOCK-DEMO'));

      // Verify that MockWalletStore received the topup mutation
      expect(MockWalletStore.instance.balanceCents, equals(30000000));
      expect(MockWalletStore.instance.mutations.length, equals(4));
      expect(MockWalletStore.instance.mutations.first.note, contains('BCA Virtual Account'));

      // Verify subsequent HomeDashboard call reflects the new balance
      final dashboard = await productRepo.getHomeDashboard();
      expect(dashboard.balanceCents, equals(30000000));
    });

    test('Production isolation: does not read MockWalletStore when mockup mode is disabled', () async {
      AppConfig.setMockupEnabled(false);

      final prodDashboard = await productRepo.getHomeDashboard();
      expect(prodDashboard.balanceCents, equals(0),
          reason: 'Production fallback must yield 0, not mock balance');
    });
  });
}
