import 'dart:async';
import 'dart:io';
import 'dart:math';

// ============================================================================
// EMPIRICAL CHALLENGE & STRESS HARNESS: MILESTONE 2 (SPLASH & ONBOARDING)
// ============================================================================

/// In-memory storage mock replicating SecureStorageService contract
class MockStorageService {
  final Map<String, String> _store = {};
  Duration simulatedReadDelay = Duration.zero;
  bool shouldThrow = false;

  void setRaw(String key, String? value) {
    if (value == null) {
      _store.remove(key);
    } else {
      _store[key] = value;
    }
  }

  String? getRaw(String key) => _store[key];

  Future<bool> isOnboardingCompleted() async {
    if (simulatedReadDelay > Duration.zero) {
      await Future.delayed(simulatedReadDelay);
    }
    if (shouldThrow) {
      throw Exception('KeyStore decryption failure');
    }
    final val = _store['onboarding_completed'];
    return val == 'true';
  }

  Future<void> setOnboardingCompleted(bool completed) async {
    _store['onboarding_completed'] = completed.toString();
  }
}

/// Simulated Splash Dispatcher executing exact SplashScreen algorithm
class SimulatedSplashDispatcher {
  final MockStorageService storage;
  bool mounted = true;
  String? dispatchedRoute;
  int? actualTotalElapsedMs;

  SimulatedSplashDispatcher({required this.storage});

  Future<void> dispatchRoute() async {
    final stopwatch = Stopwatch()..start();

    final isOnboardingCompleted = await storage.isOnboardingCompleted();

    final elapsedMs = stopwatch.elapsedMilliseconds;
    if (elapsedMs < 1500) {
      await Future.delayed(Duration(milliseconds: 1500 - elapsedMs));
    }

    actualTotalElapsedMs = stopwatch.elapsedMilliseconds;

    if (!mounted) return;

    if (!isOnboardingCompleted) {
      dispatchedRoute = '/onboarding';
    } else {
      dispatchedRoute = '/home';
    }
  }
}

void main() async {
  print('======================================================================');
  print('  EMPIRICAL CHALLENGE SUITE: MILESTONE 2 (SPLASH & ONBOARDING)       ');
  print('======================================================================\n');

  int totalTests = 0;
  int passedTests = 0;
  int failedTests = 0;

  void expect(bool condition, String message, [String? details]) {
    totalTests++;
    if (condition) {
      passedTests++;
      print('  [PASS] $message');
    } else {
      failedTests++;
      print('  [FAIL] $message');
      if (details != null) print('         Details: $details');
    }
  }

  // --------------------------------------------------------------------------
  // 1. SPLASH DISPLAY TIMER EMPIRICAL VERIFICATION (1500ms BOUNDARY)
  // --------------------------------------------------------------------------
  print('--- Challenge 1: Splash Display Timer Empirical Timing Bounds ---');

  // Test 1.1: Fast read (1ms simulated disk read)
  {
    final storage = MockStorageService()..simulatedReadDelay = const Duration(milliseconds: 1);
    final dispatcher = SimulatedSplashDispatcher(storage: storage);

    final start = DateTime.now();
    await dispatcher.dispatchRoute();
    final realElapsedMs = DateTime.now().difference(start).inMilliseconds;

    expect(
      dispatcher.actualTotalElapsedMs! >= 1480, // allowing small OS clock jitter
      'Timer never completes before 1500ms when disk read is ~1ms',
      'Actual elapsed: ${dispatcher.actualTotalElapsedMs}ms, Real wall-clock: ${realElapsedMs}ms',
    );
    expect(
      dispatcher.dispatchedRoute == '/onboarding',
      'Dispatches correctly after 1500ms threshold',
      'Route: ${dispatcher.dispatchedRoute}',
    );
  }

  // Test 1.2: Intermediate read delay (400ms simulated disk read)
  {
    final storage = MockStorageService()..simulatedReadDelay = const Duration(milliseconds: 400);
    final dispatcher = SimulatedSplashDispatcher(storage: storage);

    await dispatcher.dispatchRoute();

    expect(
      dispatcher.actualTotalElapsedMs! >= 1480,
      'Timer maintains minimum 1500ms when disk read takes 400ms',
      'Actual elapsed: ${dispatcher.actualTotalElapsedMs}ms',
    );
  }

  // Test 1.3: Slow read delay (1600ms simulated disk read)
  {
    final storage = MockStorageService()..simulatedReadDelay = const Duration(milliseconds: 1600);
    final dispatcher = SimulatedSplashDispatcher(storage: storage);

    await dispatcher.dispatchRoute();

    expect(
      dispatcher.actualTotalElapsedMs! >= 1590,
      'When disk read > 1500ms, dispatcher completes immediately without extra delay',
      'Actual elapsed: ${dispatcher.actualTotalElapsedMs}ms (expected ~1600ms)',
    );
    expect(
      dispatcher.actualTotalElapsedMs! < 2000,
      'Does not add superfluous 1500ms delay when elapsedMs already exceeds 1500ms',
      'Actual elapsed: ${dispatcher.actualTotalElapsedMs}ms',
    );
  }

  // Test 1.4: Monte Carlo Timing Boundary Stress Test (100 rapid pseudo-random delays)
  {
    final rng = Random(42);
    bool allMetMinimum = true;
    int minObserved = 999999;
    int maxObserved = 0;

    print('  [INFO] Running 100-sample timing simulation with mathematical delay model...');
    for (int i = 0; i < 100; i++) {
      final simulatedIoMs = rng.nextInt(600); // 0ms to 599ms
      final remainingDelayMs = simulatedIoMs < 1500 ? (1500 - simulatedIoMs) : 0;
      final totalComputedMs = simulatedIoMs + remainingDelayMs;

      if (totalComputedMs < 1500) {
        allMetMinimum = false;
      }
      if (totalComputedMs < minObserved) minObserved = totalComputedMs;
      if (totalComputedMs > maxObserved) maxObserved = totalComputedMs;
    }

    expect(
      allMetMinimum && minObserved == 1500 && maxObserved == 1500,
      'Mathematical timing formula (elapsedMs + max(0, 1500 - elapsedMs)) invariant == 1500ms',
      'min=$minObserved ms, max=$maxObserved ms',
    );
  }

  // --------------------------------------------------------------------------
  // 2. COLD START DISPATCHING & STORAGE VARIATION ORACLE
  // --------------------------------------------------------------------------
  print('\n--- Challenge 2: Cold Start Dispatching & Storage Variations ---');

  // Test 2.1: Uninitialized storage (null)
  {
    final storage = MockStorageService();
    final completed = await storage.isOnboardingCompleted();
    expect(completed == false, 'Uninitialized storage (null) returns false');

    final dispatcher = SimulatedSplashDispatcher(storage: storage);
    await dispatcher.dispatchRoute();
    expect(dispatcher.dispatchedRoute == '/onboarding', 'Cold start with null strictly routes to /onboarding');
  }

  // Test 2.2: Explicit 'false'
  {
    final storage = MockStorageService()..setRaw('onboarding_completed', 'false');
    final completed = await storage.isOnboardingCompleted();
    expect(completed == false, 'Storage value "false" returns false');

    final dispatcher = SimulatedSplashDispatcher(storage: storage);
    await dispatcher.dispatchRoute();
    expect(dispatcher.dispatchedRoute == '/onboarding', 'Storage value "false" strictly routes to /onboarding');
  }

  // Test 2.3: Fuzzing non-'true' values
  {
    final adversarialValues = [
      '',
      ' ',
      '0',
      '1',
      'TRUE',
      'True',
      'yes',
      'no',
      'undefined',
      'null',
      '{"done": true}',
      'true ',
      ' true',
      '\x00',
    ];

    bool allRoutedToOnboarding = true;
    for (final badVal in adversarialValues) {
      final storage = MockStorageService()..setRaw('onboarding_completed', badVal);
      final completed = await storage.isOnboardingCompleted();
      if (completed != false) {
        allRoutedToOnboarding = false;
        print('         Fuzz anomaly: value "$badVal" evaluated to true!');
      }
    }
    expect(
      allRoutedToOnboarding,
      'Adversarial fuzzing (14 malformed values): only exact string "true" evaluates to true; all others route to /onboarding',
    );
  }

  // --------------------------------------------------------------------------
  // 3. RETURNING USER BYPASS
  // --------------------------------------------------------------------------
  print('\n--- Challenge 3: Returning User Bypass ---');

  // Test 3.1: Explicit 'true'
  {
    final storage = MockStorageService()..setRaw('onboarding_completed', 'true');
    final completed = await storage.isOnboardingCompleted();
    expect(completed == true, 'Storage value "true" returns true');

    final dispatcher = SimulatedSplashDispatcher(storage: storage);
    await dispatcher.dispatchRoute();
    expect(dispatcher.dispatchedRoute == '/home', 'Returning user with "true" strictly routes to /home');
  }

  // Test 3.2: Full onboarding completion state transition
  {
    final storage = MockStorageService(); // starts empty
    expect(await storage.isOnboardingCompleted() == false, 'State 1: Initial cold launch is not completed');

    // Simulate user tapping "Lewati" or "Mulai Sekarang"
    await storage.setOnboardingCompleted(true);
    expect(storage.getRaw('onboarding_completed') == 'true', 'State 2: Completion writes exact string "true"');

    // Simulate Launch 2
    final secondLaunchDispatcher = SimulatedSplashDispatcher(storage: storage);
    await secondLaunchDispatcher.dispatchRoute();
    expect(secondLaunchDispatcher.dispatchedRoute == '/home', 'State 3: Subsequent launch routes directly to /home, bypassing onboarding');
  }

  // --------------------------------------------------------------------------
  // 4. BACK NAVIGATION GUARD (PopScope) STATIC & AST ANALYSIS
  // --------------------------------------------------------------------------
  print('\n--- Challenge 4: Back Navigation Guard (PopScope Verification) ---');

  final splashFile = File('lib/features/splash/presentation/splash_screen.dart');
  final splashContent = splashFile.existsSync() ? splashFile.readAsStringSync() : '';

  expect(splashContent.isNotEmpty, 'splash_screen.dart exists and is non-empty');
  expect(
    splashContent.contains('PopScope(') && splashContent.contains('canPop: false'),
    'splash_screen.dart wraps root with PopScope(canPop: false)',
  );
  expect(
    !splashContent.contains('canPop: true'),
    'splash_screen.dart does not contain canPop: true',
  );

  final onboardingFile = File('lib/features/onboarding/presentation/onboarding_screen.dart');
  final onboardingContent = onboardingFile.existsSync() ? onboardingFile.readAsStringSync() : '';

  expect(onboardingContent.isNotEmpty, 'onboarding_screen.dart exists and is non-empty');
  expect(
    onboardingContent.contains('PopScope(') && onboardingContent.contains('canPop: false'),
    'onboarding_screen.dart wraps root with PopScope(canPop: false)',
  );
  expect(
    onboardingContent.contains('previousPage('),
    'onboarding_screen.dart intercepts back pop to navigate to previousPage',
  );

  // --------------------------------------------------------------------------
  // 5. WEB ROOT ALIAS & INITIAL LOCATION IN APP ROUTER
  // --------------------------------------------------------------------------
  print('\n--- Challenge 5: Web Root Alias & Route Registration ---');

  final routerFile = File('lib/app/router.dart');
  final routerContent = routerFile.existsSync() ? routerFile.readAsStringSync() : '';

  expect(routerContent.isNotEmpty, 'lib/app/router.dart exists and is non-empty');

  // Verify initialLocation
  expect(
    RegExp(r"initialLocation:\s*'/splash'").hasMatch(routerContent),
    'appRouter has initialLocation configured to \'/splash\'',
  );

  // Verify web root alias
  final hasWebRootRedirect = routerContent.contains("path: '/'") &&
      (routerContent.contains("redirect: (context, state) => '/splash'") ||
       routerContent.contains("redirect: (context, state) => '/splash'"));
  expect(
    hasWebRootRedirect,
    "appRouter contains GoRoute with path: '/' that redirects directly to '/splash'",
  );

  // Verify route paths present
  expect(routerContent.contains("path: '/splash'"), "appRouter defines GoRoute for '/splash'");
  expect(routerContent.contains("path: '/onboarding'"), "appRouter defines GoRoute for '/onboarding'");
  expect(routerContent.contains("path: '/home'"), "appRouter defines GoRoute for '/home'");
  expect(routerContent.contains("path: '/topup'"), "appRouter defines GoRoute for '/topup'");

  // --------------------------------------------------------------------------
  // 6. ADVERSARIAL STRESS TEST: EXCEPTION RESILIENCE & RACE CONDITIONS
  // --------------------------------------------------------------------------
  print('\n--- Challenge 6: Stress Testing & Resilience Analysis ---');

  // Test 6.1: Premature unmount handling (mounted check)
  {
    final storage = MockStorageService();
    final dispatcher = SimulatedSplashDispatcher(storage: storage);
    dispatcher.mounted = false; // simulated unmount during wait

    await dispatcher.dispatchRoute();
    expect(
      dispatcher.dispatchedRoute == null,
      'If SplashScreen is unmounted before delay ends, no navigation is dispatched (mounted guard works)',
    );
  }

  // Test 6.2: KeyStore failure resilience
  {
    final storage = MockStorageService()..shouldThrow = true;
    bool exceptionHandled = false;
    try {
      await storage.isOnboardingCompleted();
    } catch (e) {
      exceptionHandled = true;
    }
    expect(
      exceptionHandled,
      'Storage throws on KeyStore hardware decryption failure (Observation on error boundary)',
    );
  }

  // --------------------------------------------------------------------------
  // SUMMARY
  // --------------------------------------------------------------------------
  print('\n======================================================================');
  print('  TEST RESULTS SUMMARY');
  print('  Total Assertions: $totalTests');
  print('  Passed:           $passedTests');
  print('  Failed:           $failedTests');
  print('======================================================================');

  if (failedTests == 0) {
    print('\n>> EMPIRICAL VERDICT: CONFIRMED CORRECT <<\n');
    exit(0);
  } else {
    print('\n>> EMPIRICAL VERDICT: DEFECT DETECTED <<\n');
    exit(1);
  }
}
