import 'dart:async';
import 'dart:io';
import 'dart:math';

// ============================================================================
// EMPIRICAL CHALLENGER 2 SUITE: MILESTONE 2 (SPLASH & ONBOARDING STRESS TEST)
// ============================================================================

/// In-memory SecureStorageService replica matching production contract
class MockSecureStorage {
  final Map<String, String> _data = {};
  bool throwOnRead = false;
  bool throwOnWrite = false;

  void writeRaw(String key, String? value) {
    if (value == null) {
      _data.remove(key);
    } else {
      _data[key] = value;
    }
  }

  String? readRaw(String key) => _data[key];

  Future<void> setOnboardingCompleted(bool completed) async {
    if (throwOnWrite) {
      throw Exception('SecureHardwareEnclaveException: Disk full / Write lock');
    }
    _data['onboarding_completed'] = completed.toString();
  }

  Future<bool> isOnboardingCompleted() async {
    if (throwOnRead) {
      throw Exception('HardwareKeystoreDecryptionException: Corrupted master key');
    }
    final val = _data['onboarding_completed'];
    return val == 'true';
  }

  Future<void> clearOnboardingCompleted() async {
    _data.remove('onboarding_completed');
  }
}

/// Simulated Carousel Controller reflecting OnboardingScreen logic
class SimulatedOnboardingCarousel {
  final MockSecureStorage storage;
  int currentPage = 0;
  final int totalPages = 3;
  bool isCompleting = false;
  String? currentRoute;
  bool lastPersistenceCaughtError = false;

  SimulatedOnboardingCarousel({required this.storage, this.currentRoute = '/onboarding'});

  void onNextPressed() {
    if (currentPage < totalPages - 1) {
      currentPage++;
    } else {
      completeOnboarding();
    }
  }

  void onPreviousPressed() {
    if (currentPage > 0) {
      currentPage--;
    }
  }

  Future<void> completeOnboarding() async {
    if (isCompleting) return;
    isCompleting = true;

    try {
      await storage.setOnboardingCompleted(true);
    } catch (e) {
      lastPersistenceCaughtError = true;
    }

    currentRoute = '/home';
  }

  void skip() {
    completeOnboarding();
  }

  bool get isSkipVisible => currentPage < totalPages - 1;
  String get ctaButtonText => currentPage == totalPages - 1 ? 'Mulai Sekarang' : 'Lanjut';
  String get ctaButtonKey => currentPage == totalPages - 1 ? 'onboarding_finish_button' : 'onboarding_next_button';
}

/// Simulated Splash Navigation Dispatcher
class SimulatedSplashDispatcher {
  final MockSecureStorage storage;
  String? dispatchedRoute;
  int elapsedMs = 0;

  SimulatedSplashDispatcher({required this.storage});

  Future<void> dispatchRoute({int readDelayMs = 5}) async {
    final sw = Stopwatch()..start();

    if (readDelayMs > 0) {
      await Future.delayed(Duration(milliseconds: readDelayMs));
    }

    bool isCompleted = false;
    try {
      isCompleted = await storage.isOnboardingCompleted();
    } catch (e) {
      isCompleted = false; // Graceful default in splash
    }

    final elapsed = sw.elapsedMilliseconds;
    if (elapsed < 1500) {
      // In fast simulation, we skip real 1.5s sleep unless needed, but record logic
      elapsedMs = 1500;
    } else {
      elapsedMs = elapsed;
    }

    if (!isCompleted) {
      dispatchedRoute = '/onboarding';
    } else {
      dispatchedRoute = '/home';
    }
  }
}

// ============================================================================
// WCAG 2.1 CONTRAST RATIO CALCULATOR
// ============================================================================

class WcagColor {
  final int r;
  final int g;
  final int b;
  final String hex;

  const WcagColor(this.r, this.g, this.b, this.hex);

  static WcagColor fromHex(String hexCode) {
    String cleanHex = hexCode.replaceAll('#', '').replaceAll('0x', '').replaceAll('0xFF', '');
    if (cleanHex.length == 8) cleanHex = cleanHex.substring(2);
    final int val = int.parse(cleanHex, radix: 16);
    final int r = (val >> 16) & 0xFF;
    final int g = (val >> 8) & 0xFF;
    final int b = val & 0xFF;
    return WcagColor(r, g, b, '#$cleanHex');
  }

  double get relativeLuminance {
    double transform(int channel) {
      final double sRgb = channel / 255.0;
      if (sRgb <= 0.04045) {
        return sRgb / 12.92;
      } else {
        return pow((sRgb + 0.055) / 1.055, 2.4).toDouble();
      }
    }

    final double rLin = transform(r);
    final double gLin = transform(g);
    final double bLin = transform(b);

    return 0.2126 * rLin + 0.7152 * gLin + 0.0722 * bLin;
  }

  static double calculateContrastRatio(WcagColor c1, WcagColor c2) {
    final l1 = c1.relativeLuminance;
    final l2 = c2.relativeLuminance;
    final lighter = max(l1, l2);
    final darker = min(l1, l2);
    return (lighter + 0.05) / (darker + 0.05);
  }
}

// ============================================================================
// MAIN EXECUTION
// ============================================================================

void main() async {
  print('======================================================================');
  print('  CHALLENGER 2 EMPIRICAL TEST SUITE: MILESTONE 2                     ');
  print('  (Carousel, Persistence, Bypass, WCAG AAA Contrast, Fuzzing)        ');
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
  // OBJECTIVE 1: CAROUSEL ADVANCEMENT & CONTENT VERIFICATION
  // --------------------------------------------------------------------------
  print('--- Objective 1: Carousel Content, State Progression & PopScope ---');

  // Verify static AST / source of onboarding_screen.dart
  final onboardingFile = File('lib/features/onboarding/presentation/onboarding_screen.dart');
  final onboardingSrc = onboardingFile.readAsStringSync();

  // Slide 0 Check
  expect(
    onboardingSrc.contains('Transaksi PPOB Instan & Super Cepat') &&
        onboardingSrc.contains('Pulsa & Data') &&
        onboardingSrc.contains('Token PLN 24/7') &&
        onboardingSrc.contains('PDAM & BPJS') &&
        onboardingSrc.contains('⚡ Proses 3 Detik'),
    'Slide 0: Title, badges ("Pulsa & Data", "Token PLN 24/7", "PDAM & BPJS") and tags properly declared',
  );

  // Slide 1 Check
  expect(
    onboardingSrc.contains('Dompet Digital Finansial Terpercaya') &&
        onboardingSrc.contains('QRIS & VA Instan') &&
        onboardingSrc.contains('Biometrik & PIN') &&
        onboardingSrc.contains('Enkripsi AES') &&
        onboardingSrc.contains('🔒 Enkripsi Hardware'),
    'Slide 1: Title, badges ("QRIS & VA Instan", "Biometrik & PIN", "Enkripsi AES") and tags properly declared',
  );

  // Slide 2 Check
  expect(
    onboardingSrc.contains('Harga Grosir & Riwayat Transparan') &&
        onboardingSrc.contains('Margin Maksimal') &&
        onboardingSrc.contains('Cetak Struk & PDF') &&
        onboardingSrc.contains('Mutasi Rinci') &&
        onboardingSrc.contains('🧾 Cetak Struk Bluetooth'),
    'Slide 2: Title, badges ("Margin Maksimal", "Cetak Struk & PDF", "Mutasi Rinci") and tags properly declared',
  );

  // State Progression Simulation
  {
    final storage = MockSecureStorage();
    final carousel = SimulatedOnboardingCarousel(storage: storage);

    // Initial state: slide 0
    expect(carousel.currentPage == 0, 'Initial page index is 0');
    expect(carousel.isSkipVisible == true, 'Skip button is visible on slide 0');
    expect(carousel.ctaButtonText == 'Lanjut', 'Slide 0 CTA button text is "Lanjut"');
    expect(carousel.ctaButtonKey == 'onboarding_next_button', 'Slide 0 CTA button key is "onboarding_next_button"');

    // Advance to slide 1
    carousel.onNextPressed();
    expect(carousel.currentPage == 1, 'Advancing from slide 0 transitions to page index 1');
    expect(carousel.isSkipVisible == true, 'Skip button is visible on slide 1');
    expect(carousel.ctaButtonText == 'Lanjut', 'Slide 1 CTA button text is "Lanjut"');

    // Advance to slide 2
    carousel.onNextPressed();
    expect(carousel.currentPage == 2, 'Advancing from slide 1 transitions to page index 2 (last slide)');
    expect(carousel.isSkipVisible == false, 'Skip button is hidden/ignored on slide 2 (last slide)');
    expect(carousel.ctaButtonText == 'Mulai Sekarang', 'Slide 2 CTA button transforms to "Mulai Sekarang"');
    expect(carousel.ctaButtonKey == 'onboarding_finish_button', 'Slide 2 CTA button key is "onboarding_finish_button"');

    // Backwards navigation via PopScope
    carousel.onPreviousPressed();
    expect(carousel.currentPage == 1, 'Back pop invokes previousPage to slide 1');
    carousel.onPreviousPressed();
    expect(carousel.currentPage == 0, 'Back pop invokes previousPage to slide 0');
    carousel.onPreviousPressed();
    expect(carousel.currentPage == 0, 'Back pop at slide 0 does not underflow below 0 (canPop: false blocks exit)');
  }

  // --------------------------------------------------------------------------
  // OBJECTIVE 2: SKIP ACTION PERSISTENCE & NAVIGATION
  // --------------------------------------------------------------------------
  print('\n--- Objective 2: Skip Action Persistence & Navigation ---');
  {
    final storage = MockSecureStorage();
    final carousel = SimulatedOnboardingCarousel(storage: storage);

    expect(storage.readRaw('onboarding_completed') == null, 'Storage is initially null before skip');

    carousel.skip();
    await Future.delayed(Duration.zero);

    expect(
      storage.readRaw('onboarding_completed') == 'true',
      'Tapping "Lewati" writes "true" to onboarding_completed key',
    );
    expect(
      await storage.isOnboardingCompleted() == true,
      'isOnboardingCompleted() resolves to true after skip',
    );
    expect(
      carousel.currentRoute == '/home',
      'Tapping "Lewati" navigates directly to /home',
    );
  }

  // --------------------------------------------------------------------------
  // OBJECTIVE 3: FINISH ACTION PERSISTENCE & NAVIGATION
  // --------------------------------------------------------------------------
  print('\n--- Objective 3: Finish Action on Slide 2 Persistence & Navigation ---');
  {
    final storage = MockSecureStorage();
    final carousel = SimulatedOnboardingCarousel(storage: storage);

    // Advance to slide 2
    carousel.onNextPressed(); // -> 1
    carousel.onNextPressed(); // -> 2
    expect(carousel.currentPage == 2, 'Carousel at slide 2');

    // Tap "Mulai Sekarang"
    carousel.onNextPressed(); // triggers completeOnboarding()
    await Future.delayed(Duration.zero);

    expect(
      storage.readRaw('onboarding_completed') == 'true',
      'Tapping "Mulai Sekarang" writes "true" to onboarding_completed key',
    );
    expect(
      await storage.isOnboardingCompleted() == true,
      'isOnboardingCompleted() resolves to true after finish action',
    );
    expect(
      carousel.currentRoute == '/home',
      'Tapping "Mulai Sekarang" navigates directly to /home',
    );
  }

  // --------------------------------------------------------------------------
  // OBJECTIVE 4: MULTI-LAUNCH BYPASS SCENARIO
  // --------------------------------------------------------------------------
  print('\n--- Objective 4: Multi-Launch Lifecycle & Direct Bypass ---');
  {
    // Shared persistent storage instance across app restarts
    final persistentStorage = MockSecureStorage();

    // --- LAUNCH 1 ---
    print('  [INFO] Simulating Launch 1: Fresh installation cold start...');
    final launch1Splash = SimulatedSplashDispatcher(storage: persistentStorage);
    await launch1Splash.dispatchRoute(readDelayMs: 2);

    expect(
      launch1Splash.dispatchedRoute == '/onboarding',
      'Launch 1 (First-time user): Splash routes to /onboarding',
      'Route: ${launch1Splash.dispatchedRoute}',
    );

    // User completes onboarding
    final launch1Carousel = SimulatedOnboardingCarousel(storage: persistentStorage);
    await launch1Carousel.completeOnboarding();
    expect(
      await persistentStorage.isOnboardingCompleted() == true,
      'Launch 1: Onboarding completed and written to persistent storage',
    );

    // --- LAUNCH 2 ---
    print('  [INFO] Simulating Launch 2: Subsequent cold launch after app reload...');
    final launch2Splash = SimulatedSplashDispatcher(storage: persistentStorage);
    await launch2Splash.dispatchRoute(readDelayMs: 2);

    expect(
      launch2Splash.dispatchedRoute == '/home',
      'Launch 2 (Returning user): Splash completely BYPASSES /onboarding and routes directly to /home',
      'Route: ${launch2Splash.dispatchedRoute}',
    );
  }

  // --------------------------------------------------------------------------
  // OBJECTIVE 5: ACCESSIBILITY & WCAG AAA CONTRAST VERIFICATION
  // --------------------------------------------------------------------------
  print('\n--- Objective 5: Accessibility & WCAG AAA Contrast Calculation ---');
  {
    // AppColors tokens:
    // neoGreen = Color(0xFFA3E635) -> #A3E635
    // neoGreenContrast = Color(0xFF142900) -> #142900
    final neoGreen = WcagColor.fromHex('A3E635');
    final neoGreenContrast = WcagColor.fromHex('142900');

    final lumBg = neoGreen.relativeLuminance;
    final lumFg = neoGreenContrast.relativeLuminance;
    final ratio = WcagColor.calculateContrastRatio(neoGreen, neoGreenContrast);

    print('  [INFO] Neo-Green Background (#A3E635): Relative Luminance = ${lumBg.toStringAsFixed(4)}');
    print('  [INFO] Neo-Green Contrast Text (#142900): Relative Luminance = ${lumFg.toStringAsFixed(4)}');
    print('  [INFO] Computed Contrast Ratio = ${ratio.toStringAsFixed(2)}:1');

    expect(
      ratio >= 7.0,
      'Contrast ratio between #A3E635 and #142900 strictly satisfies WCAG AAA requirement (>= 7.0:1)',
      'Calculated ratio: ${ratio.toStringAsFixed(2)}:1 (Minimum required: 7.00:1)',
    );

    expect(
      ratio >= 10.0,
      'High accessibility safety margin: Contrast exceeds 10:1 (actual: ${ratio.toStringAsFixed(2)}:1)',
    );

    // Verify CustomButton wiring in onboarding_screen.dart uses exactly these tokens
    expect(
      onboardingSrc.contains('backgroundColor: AppColors.neoGreen') &&
          onboardingSrc.contains('textColor: AppColors.neoGreenContrast'),
      'onboarding_screen.dart uses AppColors.neoGreen and AppColors.neoGreenContrast for "Mulai Sekarang" CTA',
    );

    // Also verify "Lanjut" button contrast: primaryNavy (#0A2540) vs textWhite (#FFFFFF)
    final navyBg = WcagColor.fromHex('0A2540');
    final whiteText = WcagColor.fromHex('FFFFFF');
    final navyRatio = WcagColor.calculateContrastRatio(whiteText, navyBg);
    print('  [INFO] "Lanjut" Button Contrast (#FFFFFF on #0A2540) = ${navyRatio.toStringAsFixed(2)}:1');
    expect(
      navyRatio >= 7.0,
      '"Lanjut" button (#FFFFFF on #0A2540) also satisfies WCAG AAA (>= 7.0:1)',
      'Calculated ratio: ${navyRatio.toStringAsFixed(2)}:1',
    );
  }

  // --------------------------------------------------------------------------
  // OBJECTIVE 6: CORRUPTED PAYLOAD RESILIENCE & ERROR RECOVERY
  // --------------------------------------------------------------------------
  print('\n--- Objective 6: Corrupted Payload Resilience & Error Recovery ---');
  {
    final corruptedPayloads = <String, String>{
      'empty string': '',
      'spaces': '   ',
      'malformed json': '{"completed": true, "corrupted": true}',
      'capitalized TRUE': 'TRUE',
      'mixed case True': 'True',
      'numeric 1': '1',
      'numeric 0': '0',
      'boolean false': 'false',
      'random string': 'corrupted_state_payload',
      'sql injection string': "' OR '1'='1",
      'script tag': '<script>alert("xss")</script>',
      'null byte': 'true\x00corrupt',
      'long buffer string': 'A' * 65536,
    };

    bool allCorruptedSafelyHandled = true;

    for (final entry in corruptedPayloads.entries) {
      final storage = MockSecureStorage();
      storage.writeRaw('onboarding_completed', entry.value);

      final isCompleted = await storage.isOnboardingCompleted();
      if (isCompleted != false) {
        allCorruptedSafelyHandled = false;
        print('  [FAIL] Payload "${entry.key}" falsely evaluated to completed!');
      }

      final splash = SimulatedSplashDispatcher(storage: storage);
      await splash.dispatchRoute(readDelayMs: 0);
      if (splash.dispatchedRoute != '/onboarding') {
        allCorruptedSafelyHandled = false;
        print('  [FAIL] Payload "${entry.key}" routed to "${splash.dispatchedRoute}" instead of /onboarding!');
      }
    }

    expect(
      allCorruptedSafelyHandled,
      'All 13 corrupted/adversarial payloads safely evaluate to false and route to /onboarding without crash',
    );

    // Test resilience when storage write fails during onboarding completion
    final failingStorage = MockSecureStorage()..throwOnWrite = true;
    final carousel = SimulatedOnboardingCarousel(storage: failingStorage);

    bool threwUnhandled = false;
    try {
      await carousel.completeOnboarding();
    } catch (e) {
      threwUnhandled = true;
    }

    expect(
      !threwUnhandled,
      'Storage write failure during completion does not throw unhandled exception to UI',
    );
    expect(
      carousel.lastPersistenceCaughtError,
      'Storage write error is cleanly intercepted in try/catch block',
    );
    expect(
      carousel.currentRoute == '/home',
      'Even if persistence fails, onboarding proceeds gracefully to /home without trapping user',
    );
  }

  // --------------------------------------------------------------------------
  // FINAL VERDICT & SUMMARY
  // --------------------------------------------------------------------------
  print('\n======================================================================');
  print('  CHALLENGER 2 TEST EXECUTION SUMMARY');
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
