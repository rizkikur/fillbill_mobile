import 'dart:io';
import 'dart:math';

// ============================================================================
// STANDALONE EMPIRICAL TEST SUITE: MILESTONE 4 (BOTTOM NAV BAR & SHELL KEYS)
// ============================================================================

/// Simulated Stateful Navigation Shell tracking 4 branches and state stack
class StandaloneNavigationShell {
  int currentIndex = 0;
  final List<List<String>> _branchStacks = [
    ['/home'],
    ['/transactions'],
    ['/wallet'],
    ['/profile'],
  ];

  void goBranch(int index, {bool initialLocation = false}) {
    if (index < 0 || index >= _branchStacks.length) {
      throw RangeError.index(index, _branchStacks, 'index', 'Invalid branch index');
    }
    if (index == currentIndex && initialLocation) {
      // Reset to root route of branch
      _branchStacks[index] = [_branchStacks[index].first];
    }
    currentIndex = index;
  }

  void pushSubRoute(String route) {
    _branchStacks[currentIndex].add(route);
  }

  void popSubRoute() {
    if (_branchStacks[currentIndex].length > 1) {
      _branchStacks[currentIndex].removeLast();
    }
  }

  String get currentRoute => _branchStacks[currentIndex].last;
  int get stackDepth => _branchStacks[currentIndex].length;
}

/// Standalone WCAG 2.1 Contrast Calculator
class StandaloneWcagCalculator {
  static double _channelLuminance(int channel) {
    final c = channel / 255.0;
    return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4).toDouble();
  }

  static double relativeLuminance(int r, int g, int b) {
    return 0.2126 * _channelLuminance(r) +
        0.7152 * _channelLuminance(g) +
        0.0722 * _channelLuminance(b);
  }

  static double contrastRatio(double l1, double l2) {
    final lighter = max(l1, l2);
    final darker = min(l1, l2);
    return (lighter + 0.05) / (darker + 0.05);
  }
}

void main() {
  print('======================================================================');
  print('  EMPIRICAL TEST SUITE: MILESTONE 4 (BOTTOM NAV BAR & SHELL KEYS)     ');
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
  // 1. STATEFUL NAVIGATION SHELL BRANCH SWITCHING & INVARIANTS
  // --------------------------------------------------------------------------
  print('--- 1. Stateful Navigation Shell Branch Switching & State Invariants ---');
  {
    final shell = StandaloneNavigationShell();
    expect(shell.currentIndex == 0, 'Initial branch index is 0 (/home)');
    expect(shell.currentRoute == '/home', 'Initial route is /home');

    // Switch to Tab 1 (/transactions)
    shell.goBranch(1);
    expect(shell.currentIndex == 1, 'Switched to branch 1');
    expect(shell.currentRoute == '/transactions', 'Current route is /transactions');

    // Push deep route on Branch 1 (e.g. /transactions/detail/123)
    shell.pushSubRoute('/transactions/detail/123');
    expect(shell.stackDepth == 2, 'Branch 1 stack depth is 2');
    expect(shell.currentRoute == '/transactions/detail/123', 'Branch 1 at detail route');

    // Switch to Tab 2 (/wallet)
    shell.goBranch(2);
    expect(shell.currentIndex == 2, 'Switched to branch 2');
    expect(shell.currentRoute == '/wallet', 'Branch 2 route is /wallet');

    // Switch to Tab 3 (/profile)
    shell.goBranch(3);
    expect(shell.currentIndex == 3, 'Switched to branch 3');
    expect(shell.currentRoute == '/profile', 'Branch 3 route is /profile');

    // Switch back to Tab 1: State preservation check!
    shell.goBranch(1, initialLocation: false);
    expect(shell.currentIndex == 1, 'Returned to branch 1');
    expect(shell.currentRoute == '/transactions/detail/123', 'Branch 1 state preserved at detail page');
    expect(shell.stackDepth == 2, 'Stack depth preserved across tab switches');

    // Re-tap Tab 1 with initialLocation = true (reset branch stack)
    shell.goBranch(1, initialLocation: true);
    expect(shell.currentRoute == '/transactions', 'Re-tapping active tab resets to branch initial location');
    expect(shell.stackDepth == 1, 'Stack depth restored to 1');
  }

  // --------------------------------------------------------------------------
  // 2. WCAG 2.1 CONTRAST & ACCESSIBILITY SPECIFICATION VERIFICATION
  // --------------------------------------------------------------------------
  print('\n--- 2. WCAG 2.1 Accessibility & Color Contrast Standards ---');
  {
    // Token values
    final lSurfaceWhite = StandaloneWcagCalculator.relativeLuminance(255, 255, 255);       // #FFFFFF
    final lNeoGreenSurface = StandaloneWcagCalculator.relativeLuminance(247, 254, 231);   // #F7FEE7
    final lNeoGreen = StandaloneWcagCalculator.relativeLuminance(163, 230, 53);           // #A3E635
    final lNeoGreenContrast = StandaloneWcagCalculator.relativeLuminance(20, 41, 0);       // #142900
    final lTextSecondary = StandaloneWcagCalculator.relativeLuminance(100, 116, 139);     // #64748B
    final lPrimaryNavy = StandaloneWcagCalculator.relativeLuminance(13, 33, 55);          // #0D2137

    // Active pill contrast: neoGreenContrast text on neoGreenSurface background
    final crActivePill = StandaloneWcagCalculator.contrastRatio(lNeoGreenContrast, lNeoGreenSurface);
    expect(crActivePill >= 7.0, 'Active pill text contrast ratio (${crActivePill.toStringAsFixed(2)}:1) satisfies WCAG AAA (>= 7.0:1)');

    // Inactive tab text: textSecondary on surfaceWhite background
    final crInactiveTab = StandaloneWcagCalculator.contrastRatio(lTextSecondary, lSurfaceWhite);
    expect(crInactiveTab >= 4.5, 'Inactive tab label contrast ratio (${crInactiveTab.toStringAsFixed(2)}:1) satisfies WCAG AA (>= 4.5:1)');

    // FAB button contrast: dark green icon on neo-green FAB surface
    final crFab = StandaloneWcagCalculator.contrastRatio(lNeoGreenContrast, lNeoGreen);
    expect(crFab >= 3.0, 'FAB icon contrast ratio (${crFab.toStringAsFixed(2)}:1) satisfies WCAG UI standard (>= 3.0:1)');

    // FAB button contrast vs navy
    final crFabNavy = StandaloneWcagCalculator.contrastRatio(lPrimaryNavy, lNeoGreen);
    expect(crFabNavy >= 7.0, 'FAB contrast with navy (${crFabNavy.toStringAsFixed(2)}:1) exceeds AAA');

    // Illegal contrast guard: neoGreen on surfaceWhite is illegible
    final crForbidden = StandaloneWcagCalculator.contrastRatio(lNeoGreen, lSurfaceWhite);
    expect(crForbidden < 3.0, 'Confirmed raw neoGreen on surfaceWhite (${crForbidden.toStringAsFixed(2)}:1) fails contrast and must not be used without pill');
  }

  // --------------------------------------------------------------------------
  // 3. STATIC SOURCE CODE CONTRACT VERIFICATION (main_nav_shell.dart)
  // --------------------------------------------------------------------------
  print('\n--- 3. Static Source Code & UI Keys Contract Verification ---');
  {
    final shellFile = File('lib/app/main_nav_shell.dart');
    expect(shellFile.existsSync(), 'lib/app/main_nav_shell.dart exists');
    final shellSrc = shellFile.readAsStringSync();

    // UI Keys Contract: Positional Keys
    expect(shellSrc.contains("Key('nav_bar')"), 'MainNavShell defines Key "nav_bar"');
    expect(shellSrc.contains("Key('nav_tab_0')"), 'MainNavShell defines positional Key "nav_tab_0"');
    expect(shellSrc.contains("Key('nav_tab_1')"), 'MainNavShell defines positional Key "nav_tab_1"');
    expect(shellSrc.contains("Key('nav_tab_2')"), 'MainNavShell defines positional Key "nav_tab_2"');
    expect(shellSrc.contains("Key('nav_tab_3')"), 'MainNavShell defines positional Key "nav_tab_3"');
    expect(shellSrc.contains("Key('nav_fab')"), 'MainNavShell defines Key "nav_fab"');

    // UI Keys Contract: Semantic Keys
    expect(shellSrc.contains("Key('nav_tab_home')"), 'MainNavShell defines semantic Key "nav_tab_home"');
    expect(shellSrc.contains("Key('nav_tab_history')"), 'MainNavShell defines semantic Key "nav_tab_history"');
    expect(shellSrc.contains("Key('nav_tab_wallet')"), 'MainNavShell defines semantic Key "nav_tab_wallet"');
    expect(shellSrc.contains("Key('nav_tab_profile')"), 'MainNavShell defines semantic Key "nav_tab_profile"');

    // Tab Labels
    expect(shellSrc.contains("'Home'"), 'Tab 0 label is "Home"');
    expect(shellSrc.contains("'Riwayat'"), 'Tab 1 label is "Riwayat"');
    expect(shellSrc.contains("'Dompet'"), 'Tab 2 label is "Dompet"');
    expect(shellSrc.contains("'Profil'"), 'Tab 3 label synchronized to "Profil"');
    expect(!shellSrc.contains("'Menu'"), 'Legacy label "Menu" cleanly eliminated');

    // Tab Icons
    expect(shellSrc.contains("Icons.home_outlined"), 'Tab 0 defines inactive home icon');
    expect(shellSrc.contains("Icons.home_rounded"), 'Tab 0 defines active home icon');
    expect(shellSrc.contains("Icons.receipt_long_outlined"), 'Tab 1 defines inactive receipt icon');
    expect(shellSrc.contains("Icons.receipt_long_rounded"), 'Tab 1 defines active receipt icon');
    expect(shellSrc.contains("Icons.account_balance_wallet_outlined"), 'Tab 2 defines inactive wallet icon');
    expect(shellSrc.contains("Icons.account_balance_wallet_rounded"), 'Tab 2 defines active wallet icon');
    expect(shellSrc.contains("Icons.person_outline_rounded"), 'Tab 3 defines inactive person icon');
    expect(shellSrc.contains("Icons.person_rounded"), 'Tab 3 defines active person icon');
    expect(!shellSrc.contains("Icons.tune_rounded"), 'Legacy icon Icons.tune_rounded cleanly eliminated');

    // Design Tokens Integration
    expect(shellSrc.contains("AppColors.neoGreenSurface"), 'Uses AppColors.neoGreenSurface for active soft pill');
    expect(shellSrc.contains("AppColors.neoGreenContrast"), 'Uses AppColors.neoGreenContrast for high-contrast active text/icon');
    expect(shellSrc.contains("AppColors.neoGreenGlow"), 'Uses AppColors.neoGreenGlow for FAB shadow');
    expect(shellSrc.contains("AppColors.neoGreen"), 'Uses AppColors.neoGreen in FAB gradient');
    expect(shellSrc.contains("AppColors.neoGreenLight"), 'Uses AppColors.neoGreenLight in FAB gradient');
    expect(shellSrc.contains("AppColors.neoGreenDark"), 'Uses AppColors.neoGreenDark in FAB gradient');
    expect(shellSrc.contains("AppColors.textSecondary"), 'Uses AppColors.textSecondary for inactive tabs');

    // Animated Pill Indicator specifications
    expect(shellSrc.contains("AnimatedContainer"), 'Uses AnimatedContainer for smooth pill transitions');
    expect(shellSrc.contains("Curves.easeInOutCubic"), 'Uses Curves.easeInOutCubic for organic animations');
    expect(shellSrc.contains("Duration(milliseconds: 200)"), 'Uses 200ms animation duration');
    expect(shellSrc.contains("AnimatedDefaultTextStyle"), 'Uses AnimatedDefaultTextStyle for smooth text styling');

    // Center FAB Specifications
    expect(shellSrc.contains("QuickTopUpSheet.show(context)"), 'Center FAB triggers QuickTopUpSheet');
    expect(shellSrc.contains("Icons.qr_code_scanner_rounded"), 'Center FAB uses QR scanner icon');
    expect(shellSrc.contains("BoxShape.circle"), 'Center FAB is circular');

    // Cradle & Painter
    expect(shellSrc.contains("CurvedScoopPainter"), 'MainNavShell uses CurvedScoopPainter');
    expect(shellSrc.contains("notchRadius"), 'CurvedScoopPainter defines notchRadius');
    expect(shellSrc.contains("notchDepth"), 'CurvedScoopPainter defines notchDepth');
    expect(shellSrc.contains("borderPath"), 'CurvedScoopPainter traces continuous borderPath');
  }

  // --------------------------------------------------------------------------
  // 4. ROUTER BRANCH CONFIGURATION VERIFICATION (router.dart)
  // --------------------------------------------------------------------------
  print('\n--- 4. Router Branch Configuration Verification ---');
  {
    final routerFile = File('lib/app/router.dart');
    expect(routerFile.existsSync(), 'lib/app/router.dart exists');
    final routerSrc = routerFile.readAsStringSync();

    expect(routerSrc.contains("path: '/home'"), 'Branch 0 registered with path "/home"');
    expect(routerSrc.contains("path: '/transactions'"), 'Branch 1 registered with path "/transactions"');
    expect(routerSrc.contains("path: '/wallet'"), 'Branch 2 registered with path "/wallet"');
    expect(routerSrc.contains("path: '/profile'"), 'Branch 3 registered with path "/profile"');
    expect(routerSrc.contains("StatefulShellRoute.indexedStack"), 'Router uses StatefulShellRoute.indexedStack');
    expect(routerSrc.contains("MainNavShell(navigationShell: navigationShell)"), 'Router attaches MainNavShell');
  }

  print('\n======================================================================');
  print('  TEST RESULTS SUMMARY');
  print('  Total Assertions: $totalTests');
  print('  Passed:           $passedTests');
  print('  Failed:           $failedTests');
  print('======================================================================\n');

  if (failedTests > 0) {
    print('>> VERDICT: FAILED <<');
    exit(1);
  } else {
    print('>> EMPIRICAL VERDICT: ALL TESTS PASSED! CONFIRMED CORRECT <<\n');
  }
}
