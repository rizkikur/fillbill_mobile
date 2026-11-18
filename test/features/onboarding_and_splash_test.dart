import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

// Core & App
import 'package:fillbill_mobile/core/config/app_config.dart';
import 'package:fillbill_mobile/core/config/brand_config.dart';
import 'package:fillbill_mobile/core/constants/storage_keys.dart';
import 'package:fillbill_mobile/core/security/secure_storage_service.dart';
import 'package:fillbill_mobile/core/widgets/brand_logo_widget.dart';
import 'package:fillbill_mobile/app/router.dart';

// Features
import 'package:fillbill_mobile/features/auth/presentation/auth_notifier.dart';
import 'package:fillbill_mobile/features/splash/presentation/splash_screen.dart';
import 'package:fillbill_mobile/features/onboarding/presentation/onboarding_screen.dart';
import 'package:fillbill_mobile/features/wallet/presentation/topup_screen.dart';

// ============================================================================
// HERMETIC TEST HARNESS: IN-MEMORY STORAGE FAKE (Zero Mock Library Overhead)
// ============================================================================

class FakeFlutterSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> _store = {};

  FakeFlutterSecureStorage([Map<String, String>? initialData]) {
    if (initialData != null) {
      _store.addAll(initialData);
    }
  }

  @override
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

  @override
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

  @override
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

  @override
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

// ============================================================================
// HELPER BUILDERS FOR WIDGET AND ROUTER TESTING
// ============================================================================

Widget createTestApp({
  required Widget child,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      home: child,
    ),
  );
}

GoRouter createTestRouter({
  required String initialLocation,
  required FakeFlutterSecureStorage fakeStorage,
  void Function(String route)? onRouteReached,
}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) {
          onRouteReached?.call('/splash');
          return const SplashScreen();
        },
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) {
          onRouteReached?.call('/onboarding');
          return OnboardingScreen(
            storageService: SecureStorageService(fakeStorage),
          );
        },
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) {
          onRouteReached?.call('/home');
          return const Scaffold(
            key: Key('home_screen_mock'),
            body: Center(child: Text('Home Screen Destination')),
          );
        },
      ),
      GoRoute(
        path: '/topup',
        builder: (context, state) {
          onRouteReached?.call('/topup');
          return const TopupScreen();
        },
      ),
    ],
  );
}

Widget createRouterTestApp({
  required GoRouter router,
  required FakeFlutterSecureStorage fakeStorage,
}) {
  return ProviderScope(
    overrides: [
      secureStorageProvider.overrideWithValue(SecureStorageService(fakeStorage)),
    ],
    child: MaterialApp.router(
      routerConfig: router,
    ),
  );
}

// ============================================================================
// MAIN TEST SUITE: 8 MANDATORY TEST CASES + ROUTER REGISTRY CONTRACT
// ============================================================================

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
    AppConfig.initialize(AppConfig.dev());
  });

  group('Milestone 2: Splash Screen Widget & Flow Tests', () {
    late FakeFlutterSecureStorage fakeStorage;

    setUp(() {
      fakeStorage = FakeFlutterSecureStorage();
    });

    // ------------------------------------------------------------------------
    // TEST CASE 1: Splash Screen Visuals Rendering
    // ------------------------------------------------------------------------
    testWidgets('1. Splash Screen renders brand logo, title, and progress indicator',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          overrides: [
            secureStorageProvider.overrideWithValue(SecureStorageService(fakeStorage)),
          ],
          child: const SplashScreen(),
        ),
      );

      // Verify immediate appearance of core elements
      expect(find.byType(BrandLogoWidget), findsOneWidget);
      expect(find.text(BrandConfig.appName), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byKey(const Key('splash_logo_scale')), findsOneWidget);
      expect(find.byKey(const Key('splash_logo_fade')), findsOneWidget);

      // Progress animation frames smoothly
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(BrandLogoWidget), findsOneWidget);

      // Advance through delay timer
      await tester.pump(const Duration(milliseconds: 1600));
    });

    // ------------------------------------------------------------------------
    // TEST CASE 2: Splash Routes to /onboarding for First-Time Users
    // ------------------------------------------------------------------------
    testWidgets('2. Splash Screen routes to /onboarding when isOnboardingCompleted() == false',
        (WidgetTester tester) async {
      // Storage starts empty (default false)
      final testRouter = createTestRouter(
        initialLocation: '/splash',
        fakeStorage: fakeStorage,
      );

      await tester.pumpWidget(
        createRouterTestApp(
          router: testRouter,
          fakeStorage: fakeStorage,
        ),
      );

      // Initially at splash
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.byType(OnboardingScreen), findsNothing);

      // Advance timer past 1.5 seconds
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pumpAndSettle();

      // Confirms navigation to Onboarding
      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.text('Transaksi PPOB Instan & Super Cepat'), findsOneWidget);
      expect(find.byType(SplashScreen), findsNothing);
    });

    // ------------------------------------------------------------------------
    // TEST CASE 3: Splash Routes to /home for Returning Users
    // ------------------------------------------------------------------------
    testWidgets('3. Splash Screen routes to /home when isOnboardingCompleted() == true',
        (WidgetTester tester) async {
      // Pre-seed storage with completed onboarding
      await fakeStorage.write(key: StorageKeys.onboardingCompleted, value: 'true');

      final testRouter = createTestRouter(
        initialLocation: '/splash',
        fakeStorage: fakeStorage,
      );

      await tester.pumpWidget(
        createRouterTestApp(
          router: testRouter,
          fakeStorage: fakeStorage,
        ),
      );

      // Initially at splash
      expect(find.byType(SplashScreen), findsOneWidget);

      // Advance timer past 1.5 seconds
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pumpAndSettle();

      // Confirms bypass of onboarding and arrival at /home
      expect(find.byKey(const Key('home_screen_mock')), findsOneWidget);
      expect(find.text('Home Screen Destination'), findsOneWidget);
      expect(find.byType(OnboardingScreen), findsNothing);
    });
  });

  group('Milestone 2: Onboarding Screen Widget & Interaction Tests', () {
    late FakeFlutterSecureStorage fakeStorage;

    setUp(() {
      fakeStorage = FakeFlutterSecureStorage();
    });

    // ------------------------------------------------------------------------
    // TEST CASE 4: Onboarding Screen Renders 3 Slides and Badges
    // ------------------------------------------------------------------------
    testWidgets('4. Onboarding Screen renders 3 slides with titles, descriptions, and vector badges',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: OnboardingScreen(
            storageService: SecureStorageService(fakeStorage),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Slide 0: Fast PPOB & Bills
      expect(find.text('Transaksi PPOB Instan & Super Cepat'), findsOneWidget);
      expect(find.text('Pulsa & Data'), findsOneWidget);
      expect(find.text('Token PLN 24/7'), findsOneWidget);
      expect(find.text('PDAM & BPJS'), findsOneWidget);
      expect(find.byKey(const Key('onboarding_skip_button')), findsOneWidget);
      expect(find.byKey(const Key('onboarding_next_button')), findsOneWidget);

      // Advance to Slide 1 via swipe
      await tester.drag(find.byType(PageView), const Offset(-450, 0));
      await tester.pumpAndSettle();

      // Slide 1: Digital Wallet
      expect(find.text('Dompet Digital Finansial Terpercaya'), findsOneWidget);
      expect(find.text('QRIS & VA Instan'), findsOneWidget);
      expect(find.text('Biometrik & PIN'), findsOneWidget);
      expect(find.text('Enkripsi AES'), findsOneWidget);

      // Advance to Slide 2 via swipe
      await tester.drag(find.byType(PageView), const Offset(-450, 0));
      await tester.pumpAndSettle();

      // Slide 2: Transparent Pricing & Receipts
      expect(find.text('Harga Grosir & Riwayat Transparan'), findsOneWidget);
      expect(find.text('Margin Maksimal'), findsOneWidget);
      expect(find.text('Cetak Struk & PDF'), findsOneWidget);
      expect(find.text('Mutasi Rinci'), findsOneWidget);
      expect(find.byKey(const Key('onboarding_finish_button')), findsOneWidget);
    });

    // ------------------------------------------------------------------------
    // TEST CASE 5: Next Button Advances Slides & Updates Dot Indicator
    // ------------------------------------------------------------------------
    testWidgets('5. Onboarding Screen swipe / next button advances page and updates dot indicator',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: OnboardingScreen(
            storageService: SecureStorageService(fakeStorage),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Start on Slide 0
      expect(find.text('Transaksi PPOB Instan & Super Cepat'), findsOneWidget);
      expect(find.text('Lanjut'), findsOneWidget);

      // Tap Next -> Advances to Slide 1
      await tester.tap(find.byKey(const Key('onboarding_next_button')));
      await tester.pumpAndSettle();
      expect(find.text('Dompet Digital Finansial Terpercaya'), findsOneWidget);

      // Tap Next -> Advances to Slide 2
      await tester.tap(find.byKey(const Key('onboarding_next_button')));
      await tester.pumpAndSettle();
      expect(find.text('Harga Grosir & Riwayat Transparan'), findsOneWidget);

      // Dynamic action button transforms to "Mulai Sekarang"
      expect(find.byKey(const Key('onboarding_finish_button')), findsOneWidget);
      expect(find.text('Mulai Sekarang'), findsOneWidget);
    });

    // ------------------------------------------------------------------------
    // TEST CASE 6: Skip Action Persists Completion and Navigates to /home
    // ------------------------------------------------------------------------
    testWidgets('6. Tapping "Lewati" (Skip) writes onboardingCompleted = true and navigates to /home',
        (WidgetTester tester) async {
      final testRouter = createTestRouter(
        initialLocation: '/onboarding',
        fakeStorage: fakeStorage,
      );

      await tester.pumpWidget(
        createRouterTestApp(
          router: testRouter,
          fakeStorage: fakeStorage,
        ),
      );
      await tester.pumpAndSettle();

      // Storage initially false
      expect(await fakeStorage.read(key: StorageKeys.onboardingCompleted), isNull);

      // Tap "Lewati"
      await tester.tap(find.byKey(const Key('onboarding_skip_button')));
      await tester.pumpAndSettle();

      // Storage persisted
      expect(await fakeStorage.read(key: StorageKeys.onboardingCompleted), equals('true'));

      // Destination reached
      expect(find.byKey(const Key('home_screen_mock')), findsOneWidget);
      expect(find.byType(OnboardingScreen), findsNothing);
    });

    // ------------------------------------------------------------------------
    // TEST CASE 7: Finish Action on Last Slide Persists and Navigates to /home
    // ------------------------------------------------------------------------
    testWidgets('7. Tapping "Mulai Sekarang" on last slide writes onboardingCompleted = true and navigates to /home',
        (WidgetTester tester) async {
      final testRouter = createTestRouter(
        initialLocation: '/onboarding',
        fakeStorage: fakeStorage,
      );

      await tester.pumpWidget(
        createRouterTestApp(
          router: testRouter,
          fakeStorage: fakeStorage,
        ),
      );
      await tester.pumpAndSettle();

      // Advance to last slide (2 steps)
      await tester.tap(find.byKey(const Key('onboarding_next_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('onboarding_next_button')));
      await tester.pumpAndSettle();

      expect(find.text('Mulai Sekarang'), findsOneWidget);

      // Tap "Mulai Sekarang"
      await tester.tap(find.byKey(const Key('onboarding_finish_button')));
      await tester.pumpAndSettle();

      // Storage persisted
      expect(await fakeStorage.read(key: StorageKeys.onboardingCompleted), equals('true'));

      // Destination reached
      expect(find.byKey(const Key('home_screen_mock')), findsOneWidget);
      expect(find.byType(OnboardingScreen), findsNothing);
    });

    // ------------------------------------------------------------------------
    // TEST CASE 8: Multi-Launch Persistence & Bypass Lifecycle Test
    // ------------------------------------------------------------------------
    testWidgets('8. In-memory Fake storage verifies state persistence and bypass on second launch',
        (WidgetTester tester) async {
      // Shared persistent fake storage across launches
      final sharedStorage = FakeFlutterSecureStorage();

      // --- LAUNCH 1 (First-Time User Experience) ---
      final launch1Router = createTestRouter(
        initialLocation: '/splash',
        fakeStorage: sharedStorage,
      );

      await tester.pumpWidget(
        createRouterTestApp(
          router: launch1Router,
          fakeStorage: sharedStorage,
        ),
      );

      // Splash delays and moves to Onboarding
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pumpAndSettle();
      expect(find.byType(OnboardingScreen), findsOneWidget);

      // User skips onboarding
      await tester.tap(find.byKey(const Key('onboarding_skip_button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('home_screen_mock')), findsOneWidget);

      // Assert persisted state
      final storageService = SecureStorageService(sharedStorage);
      expect(await storageService.isOnboardingCompleted(), isTrue);

      // --- LAUNCH 2 (Returning User Experience) ---
      final launch2Router = createTestRouter(
        initialLocation: '/splash',
        fakeStorage: sharedStorage,
      );

      await tester.pumpWidget(
        createRouterTestApp(
          router: launch2Router,
          fakeStorage: sharedStorage,
        ),
      );

      // Splash delays and moves DIRECTLY to /home, completely bypassing onboarding
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('home_screen_mock')), findsOneWidget);
      expect(find.byType(OnboardingScreen), findsNothing);
    });
  });

  group('Milestone 2: Production appRouter Route Registry Verification', () {
    test('appRouter has initialLocation configured to /splash', () {
      expect(appRouter.routeInformationProvider.value.uri.path, equals('/splash'));
    });

    test('appRouter registers all mandatory Milestone 2 & Topup routes', () {
      final routes = appRouter.configuration.routes;
      final registeredPaths = <String>[];

      for (final route in routes) {
        if (route is GoRoute) {
          registeredPaths.add(route.path);
        } else if (route is StatefulShellRoute) {
          for (final branch in route.branches) {
            for (final subRoute in branch.routes) {
              if (subRoute is GoRoute) {
                registeredPaths.add(subRoute.path);
              }
            }
          }
        }
      }

      // Assert presence of new routes
      expect(registeredPaths, contains('/splash'));
      expect(registeredPaths, contains('/'));
      expect(registeredPaths, contains('/onboarding'));
      expect(registeredPaths, contains('/topup'));
      expect(registeredPaths, contains('/home'));
    });
  });
}
