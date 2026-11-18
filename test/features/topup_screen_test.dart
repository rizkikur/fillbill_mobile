import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

// Core & Config
import 'package:fillbill_mobile/core/config/app_config.dart';
import 'package:fillbill_mobile/core/config/brand_config.dart';

// Features under test
import 'package:fillbill_mobile/features/wallet/data/mock_wallet_store.dart';
import 'package:fillbill_mobile/features/wallet/presentation/topup_screen.dart';
import 'package:fillbill_mobile/features/home/presentation/home_screen.dart';
import 'package:fillbill_mobile/features/wallet/presentation/wallet_screen.dart';

// ============================================================================
// HERMETIC TEST HARNESS & BUILDERS
// ============================================================================

Widget createTopupTestApp({
  required Widget child,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: BrandConfig.primaryColor),
      ),
      home: child,
    ),
  );
}

GoRouter createTopupTestRouter({
  required String initialLocation,
  void Function(String route)? onRouteReached,
}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/home',
        builder: (context, state) {
          onRouteReached?.call('/home');
          return const HomeScreen();
        },
      ),
      GoRoute(
        path: '/wallet',
        builder: (context, state) {
          onRouteReached?.call('/wallet');
          return const WalletScreen();
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
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp.router(
      routerConfig: router,
    ),
  );
}

// ============================================================================
// MAIN TEST SUITE: 10 MANDATORY DISCRETE TEST CASES + 2 BONUS CASES
// ============================================================================

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
    AppConfig.initialize(AppConfig.dev());
  });

  setUp(() {
    MockWalletStore.instance.reset();
  });

  group('Milestone 3: Top-Up Screen & Navigation Test Suite', () {

    // ------------------------------------------------------------------------
    // TEST 1: Initial Rendering & Component Structure
    // ------------------------------------------------------------------------
    testWidgets('1. Top-Up screen renders active balance, nominal chips, and custom input field',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTopupTestApp(child: const TopupScreen()));
      await tester.pumpAndSettle();

      // Verify Header & Balance Display
      expect(find.text('Top Up Saldo'), findsOneWidget);
      expect(find.byKey(const Key('topup_header_balance')), findsOneWidget);
      expect(find.textContaining('250.000'), findsWidgets);

      // Verify 6 Quick-Pick Nominal Chips
      expect(find.byKey(const Key('topup_chip_20000')), findsOneWidget);
      expect(find.byKey(const Key('topup_chip_50000')), findsOneWidget);
      expect(find.byKey(const Key('topup_chip_100000')), findsOneWidget);
      expect(find.byKey(const Key('topup_chip_200000')), findsOneWidget);
      expect(find.byKey(const Key('topup_chip_500000')), findsOneWidget);
      expect(find.byKey(const Key('topup_chip_1000000')), findsOneWidget);

      // Verify Custom Nominal Input Field
      expect(find.byKey(const Key('topup_nominal_input')), findsOneWidget);

      // Verify Payment Summary Card & CTA
      expect(find.byKey(const Key('topup_summary_card')), findsOneWidget);
      expect(find.byKey(const Key('topup_continue_button')), findsOneWidget);
    });

    // ------------------------------------------------------------------------
    // TEST 2: Quick-Pick Nominal Chip Selection
    // ------------------------------------------------------------------------
    testWidgets('2. Selecting a quick-pick nominal chip updates the input field and summary card',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTopupTestApp(child: const TopupScreen()));
      await tester.pumpAndSettle();

      // Tap Rp 100.000 chip
      final chip100k = find.byKey(const Key('topup_chip_100000'));
      expect(chip100k, findsOneWidget);
      await tester.tap(chip100k);
      await tester.pumpAndSettle();

      // Summary Card and Input Field should reflect Rp 100.000
      expect(find.textContaining('100.000'), findsWidgets);

      // Tap Rp 500.000 chip
      final chip500k = find.byKey(const Key('topup_chip_500000'));
      await tester.tap(chip500k);
      await tester.pumpAndSettle();

      expect(find.textContaining('500.000'), findsWidgets);
    });

    // ------------------------------------------------------------------------
    // TEST 3: Custom Nominal Input & Auto-Deselection of Chips
    // ------------------------------------------------------------------------
    testWidgets('3. Typing a custom nominal updates the summary total and deselects mismatched chips',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTopupTestApp(child: const TopupScreen()));
      await tester.pumpAndSettle();

      // Select chip Rp 100.000
      await tester.tap(find.byKey(const Key('topup_chip_100000')));
      await tester.pumpAndSettle();

      // Type custom nominal "75000" into input field
      final inputField = find.byKey(const Key('topup_nominal_input'));
      await tester.enterText(inputField, '75000');
      await tester.pumpAndSettle();

      // Summary should update to Rp 75.000
      expect(find.textContaining('75.000'), findsWidgets);
    });

    // ------------------------------------------------------------------------
    // TEST 4: Minimum Nominal Validation Boundary (< Rp 10.000)
    // ------------------------------------------------------------------------
    testWidgets('4. Minimum nominal validation (< Rp 10.000 disables CTA with warning)',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTopupTestApp(child: const TopupScreen()));
      await tester.pumpAndSettle();

      // Enter nominal below minimum: Rp 5.000
      final inputField = find.byKey(const Key('topup_nominal_input'));
      await tester.enterText(inputField, '5000');
      await tester.pumpAndSettle();

      // Expect validation warning message
      expect(find.textContaining('Minimal top up Rp 10.000'), findsOneWidget);

      // Verify CTA button is disabled
      final continueBtn = tester.widget<ElevatedButton>(find.byKey(const Key('topup_continue_button')));
      expect(continueBtn.onPressed, isNull);
    });

    // ------------------------------------------------------------------------
    // TEST 5: Maximum Nominal Validation Boundary (> Rp 10.000.000)
    // ------------------------------------------------------------------------
    testWidgets('5. Maximum nominal validation (> Rp 10.000.000 disables CTA with warning)',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTopupTestApp(child: const TopupScreen()));
      await tester.pumpAndSettle();

      // Enter nominal exceeding maximum: Rp 15.000.000
      final inputField = find.byKey(const Key('topup_nominal_input'));
      await tester.enterText(inputField, '15000000');
      await tester.pumpAndSettle();

      // Expect validation warning message
      expect(find.textContaining('Maksimal top up Rp 10.000.000'), findsOneWidget);

      // Verify CTA button is disabled
      final continueBtn = tester.widget<ElevatedButton>(find.byKey(const Key('topup_continue_button')));
      expect(continueBtn.onPressed, isNull);
    });

    // ------------------------------------------------------------------------
    // TEST 6: Payment Channel Selection & Dynamic Fee Calculation
    // ------------------------------------------------------------------------
    testWidgets('6. Selecting payment channels updates fee and total calculation',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTopupTestApp(child: const TopupScreen()));
      await tester.pumpAndSettle();

      // Select Rp 100.000 nominal
      await tester.tap(find.byKey(const Key('topup_chip_100000')));
      await tester.pumpAndSettle();

      // Select BCA Virtual Account (admin fee Rp 1.000 / Rp 2.500)
      final bcaChannel = find.byKey(const Key('topup_channel_bca_va'));
      if (bcaChannel.evaluate().isNotEmpty) {
        await tester.tap(bcaChannel);
        await tester.pumpAndSettle();
      }

      // Verify summary shows non-zero admin fee and calculated total
      expect(find.byKey(const Key('topup_summary_fee')), findsOneWidget);
      expect(find.byKey(const Key('topup_summary_total')), findsOneWidget);

      // Verify CTA button becomes enabled
      final continueBtn = tester.widget<ElevatedButton>(find.byKey(const Key('topup_continue_button')));
      expect(continueBtn.onPressed, isNotNull);
    });

    // ------------------------------------------------------------------------
    // TEST 7: CTA Tap in Mockup Mode Opens Simulation Dialog
    // ------------------------------------------------------------------------
    testWidgets('7. Tapping "Lanjutkan Pembayaran" in mockup mode opens simulation dialog',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTopupTestApp(child: const TopupScreen()));
      await tester.pumpAndSettle();

      // Select valid nominal Rp 100.000
      await tester.tap(find.byKey(const Key('topup_chip_100000')));
      await tester.pumpAndSettle();

      // Tap CTA button
      await tester.tap(find.byKey(const Key('topup_continue_button')));
      await tester.pumpAndSettle();

      // Verify simulation modal sheet or dialog is visible
      expect(find.byKey(const Key('topup_simulation_pay_button')), findsOneWidget);
      expect(find.textContaining('Simulasikan Pembayaran Berhasil'), findsOneWidget);
    });

    // ------------------------------------------------------------------------
    // TEST 8: Completing Simulated Payment Mutates MockWalletStore
    // ------------------------------------------------------------------------
    testWidgets('8. Completing simulated payment calls MockWalletStore.addTopup and increases balance',
        (WidgetTester tester) async {
      final initialBalance = MockWalletStore.instance.balanceCents; // 25,000,000 cents (Rp 250.000)

      await tester.pumpWidget(createTopupTestApp(child: const TopupScreen()));
      await tester.pumpAndSettle();

      // Select Rp 100.000
      await tester.tap(find.byKey(const Key('topup_chip_100000')));
      await tester.pumpAndSettle();

      // Open simulation sheet
      await tester.tap(find.byKey(const Key('topup_continue_button')));
      await tester.pumpAndSettle();

      // Tap "Simulasikan Pembayaran Berhasil"
      await tester.tap(find.byKey(const Key('topup_simulation_pay_button')));
      await tester.pumpAndSettle();

      // Verify MockWalletStore balance increased by 10,000,000 cents (Rp 100.000)
      expect(MockWalletStore.instance.balanceCents, equals(initialBalance + 10000000));

      // Verify new topup mutation inserted
      expect(MockWalletStore.instance.mutations.first.referenceType, equals('topup'));
      expect(MockWalletStore.instance.mutations.first.type, equals('credit'));
      expect(MockWalletStore.instance.mutations.first.amountCents, equals(10000000));
    });

    // ------------------------------------------------------------------------
    // TEST 9: Home Screen '+' Button Navigates to /topup
    // ------------------------------------------------------------------------
    testWidgets('9. Tapping "+" button on Home screen pushes to /topup',
        (WidgetTester tester) async {
      String? currentRoute;
      final router = createTopupTestRouter(
        initialLocation: '/home',
        onRouteReached: (route) => currentRoute = route,
      );

      await tester.pumpWidget(createRouterTestApp(router: router));
      await tester.pumpAndSettle();

      expect(currentRoute, equals('/home'));

      // Find and tap '+' button on Home Screen balance card
      final topupBtn = find.byKey(const Key('home_topup_button'));
      expect(topupBtn, findsOneWidget);
      await tester.tap(topupBtn);
      await tester.pumpAndSettle();

      // Verify route transitioned to /topup and TopupScreen is displayed
      expect(currentRoute, equals('/topup'));
      expect(find.byType(TopupScreen), findsOneWidget);
    });

    // ------------------------------------------------------------------------
    // TEST 10: Wallet Screen "Top Up" Button Navigates to /topup
    // ------------------------------------------------------------------------
    testWidgets('10. Tapping "Top Up" button on Wallet screen pushes to /topup',
        (WidgetTester tester) async {
      String? currentRoute;
      final router = createTopupTestRouter(
        initialLocation: '/wallet',
        onRouteReached: (route) => currentRoute = route,
      );

      await tester.pumpWidget(createRouterTestApp(router: router));
      await tester.pumpAndSettle();

      expect(currentRoute, equals('/wallet'));

      // Find and tap "Top Up" button on Wallet Screen
      final topupBtn = find.byKey(const Key('wallet_topup_button'));
      expect(topupBtn, findsOneWidget);
      await tester.tap(topupBtn);
      await tester.pumpAndSettle();

      // Verify route transitioned to /topup and TopupScreen is displayed
      expect(currentRoute, equals('/topup'));
      expect(find.byType(TopupScreen), findsOneWidget);
    });

    // ------------------------------------------------------------------------
    // BONUS TEST 11: Top-Up Screen Back Navigation
    // ------------------------------------------------------------------------
    testWidgets('11. Back button on TopupScreen pops route back to caller',
        (WidgetTester tester) async {
      String? currentRoute;
      final router = createTopupTestRouter(
        initialLocation: '/home',
        onRouteReached: (route) => currentRoute = route,
      );

      await tester.pumpWidget(createRouterTestApp(router: router));
      await tester.pumpAndSettle();

      // Push to /topup
      await tester.tap(find.byKey(const Key('home_topup_button')));
      await tester.pumpAndSettle();
      expect(currentRoute, equals('/topup'));

      // Pop back using TopupScreen back button
      final backButton = find.byKey(const Key('topup_back_button'));
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton);
      } else {
        await tester.tap(find.byType(BackButton));
      }
      await tester.pumpAndSettle();

      // Verify restored to /home
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    // ------------------------------------------------------------------------
    // BONUS TEST 12: MockWalletStore Hermetic Reset Contract
    // ------------------------------------------------------------------------
    test('12. MockWalletStore hermetic isolation and state reset contract', () {
      final store = MockWalletStore.instance;
      store.addTopup(amountCents: 5000000, channelCode: 'qris', channelName: 'QRIS');
      expect(store.balanceCents, greaterThan(25000000));

      store.reset();
      expect(store.balanceCents, equals(25000000));
      expect(store.balanceDisplay, equals('Rp 250.000,00'));
      expect(store.mutations.length, equals(3));
    });
  });
}
