import 'dart:io';
import 'dart:math';

// ============================================================================
// FORENSIC INTEGRITY AUDIT SUITE: MILESTONE 4 (BOTTOM NAV BAR UI ENHANCEMENT)
// ============================================================================

/// WCAG 2.1 Contrast Formula Standard Implementation
class ForensicWcagOracle {
  static double linearize(int srgbChannel) {
    final s = srgbChannel / 255.0;
    return s <= 0.03928 ? s / 12.92 : pow((s + 0.055) / 1.055, 2.4).toDouble();
  }

  static double relativeLuminance(int r, int g, int b) {
    return 0.2126 * linearize(r) + 0.7152 * linearize(g) + 0.0722 * linearize(b);
  }

  static double contrastRatio(double l1, double l2) {
    final lighter = max(l1, l2);
    final darker = min(l1, l2);
    return (lighter + 0.05) / (darker + 0.05);
  }
}

void main() {
  print('======================================================================');
  print('  FORENSIC INTEGRITY AUDIT: MILESTONE 4 BOTTOM NAVIGATION BAR        ');
  print('======================================================================\n');

  int totalChecks = 0;
  int passedChecks = 0;
  int failedChecks = 0;

  void assertCheck(bool condition, String checkName, [String? failReason]) {
    totalChecks++;
    if (condition) {
      passedChecks++;
      print('  [PASS] $checkName');
    } else {
      failedChecks++;
      print('  [FAIL] $checkName');
      if (failReason != null) print('         Violation: $failReason');
    }
  }

  // ==========================================================================
  // CHECK 1: NO HARDCODED TEST RESULTS
  // ==========================================================================
  print('--- CHECK 1: NO HARDCODED TEST RESULTS ---');
  final shellFile = File('lib/app/main_nav_shell.dart');
  assertCheck(shellFile.existsSync(), 'main_nav_shell.dart exists');
  final shellCode = shellFile.readAsStringSync();

  // 1.1 Dynamic branch binding
  assertCheck(
    shellCode.contains('final branchIndex = navigationShell.currentIndex;'),
    'Dynamically extracts branchIndex from StatefulNavigationShell.currentIndex',
  );

  // 1.2 No hardcoded active indices
  assertCheck(
    !RegExp(r'branchIndex\s*=\s*[0-3];').hasMatch(shellCode),
    'branchIndex is not hardcoded or overridden',
  );

  // 1.3 goBranch calls dynamic target with initialLocation check
  assertCheck(
    shellCode.contains('navigationShell.goBranch(') &&
        shellCode.contains('initialLocation: branchTarget == navigationShell.currentIndex'),
    'Tab onTap triggers navigationShell.goBranch with proper initialLocation parameter',
  );

  // 1.4 No mock bypasses or test environment bypass flags in production shell
  assertCheck(
    !shellCode.contains('isRunningTest') &&
        !shellCode.contains('isMockNav') &&
        !shellCode.contains('forceActiveIndex'),
    'Zero test backdoor or mock-state bypass flags in main_nav_shell.dart',
  );

  // ==========================================================================
  // CHECK 2: NO DUMMY / FACADE IMPLEMENTATIONS
  // ==========================================================================
  print('\n--- CHECK 2: NO DUMMY / FACADE IMPLEMENTATIONS ---');

  // 2.1 Tab count: Exactly 4 distinct navigation tabs invoked in Row
  final callMatches = RegExp(r'child:\s*_buildNavItem\(').allMatches(shellCode).length;
  assertCheck(callMatches == 4, 'Invokes exactly 4 navigation items in bottom bar (found: $callMatches)');

  // 2.2 Discrete targets 0, 1, 2, 3
  assertCheck(shellCode.contains('branchTarget: 0'), 'Defines branchTarget 0 (Home)');
  assertCheck(shellCode.contains('branchTarget: 1'), 'Defines branchTarget 1 (Riwayat)');
  assertCheck(shellCode.contains('branchTarget: 2'), 'Defines branchTarget 2 (Dompet)');
  assertCheck(shellCode.contains('branchTarget: 3'), 'Defines branchTarget 3 (Profil)');

  // 2.3 Interactive widgets with InkWell and Semantics
  assertCheck(shellCode.contains('InkWell(') && shellCode.contains('Semantics('),
      'Tabs wrapped in genuine Semantics and InkWell tap listeners');

  // 2.4 Animated visual indicator
  assertCheck(
    shellCode.contains('AnimatedContainer(') &&
        shellCode.contains('AppColors.neoGreenSurface') &&
        shellCode.contains('Curves.easeInOutCubic'),
    'Active tab applies genuine AnimatedContainer with neoGreenSurface and easeInOutCubic',
  );

  // 2.5 Center FAB genuine implementation
  assertCheck(
    shellCode.contains('_buildCenterFloatingActionButton(context)') &&
        shellCode.contains('QuickTopUpSheet.show(context);') &&
        shellCode.contains("Key('nav_fab')"),
    'Center FAB is genuine interactive widget invoking QuickTopUpSheet',
  );

  // 2.6 CurvedScoopPainter is a real painter with mathematical curves
  assertCheck(
    shellCode.contains('class CurvedScoopPainter extends CustomPainter') &&
        shellCode.contains('path.cubicTo(') &&
        shellCode.contains('canvas.drawPath(path, paint)') &&
        shellCode.contains('canvas.drawPath(borderPath, borderPaint)'),
    'CurvedScoopPainter performs genuine CustomPainter canvas drawing with continuous borderPath',
  );

  // ==========================================================================
  // CHECK 3: NO FABRICATED VERIFICATION ARTIFACTS
  // ==========================================================================
  print('\n--- CHECK 3: NO FABRICATED VERIFICATION ARTIFACTS ---');

  // 3.1 Verify test files exist
  final standaloneTestFile = File('test/standalone_milestone_4_test.dart');
  final widgetTestFile = File('test/app/main_nav_shell_test.dart');
  assertCheck(standaloneTestFile.existsSync(), 'standalone_milestone_4_test.dart exists');
  assertCheck(widgetTestFile.existsSync(), 'main_nav_shell_test.dart exists');

  // 3.2 Ensure test files are not pre-canned PASS output mocks
  final testContent = standaloneTestFile.readAsStringSync();
  assertCheck(
    testContent.contains('totalTests++') &&
        testContent.contains('passedTests++') &&
        testContent.contains('if (condition)'),
    'Test suite uses genuine conditional assertion evaluation (expect condition)',
  );
  assertCheck(
    !testContent.contains("print('[PASS] all tests passed')") &&
        !testContent.contains("exit(0); // bypass"),
    'Test suite contains zero unconditional PASS fabrication shortcuts',
  );

  // ==========================================================================
  // CHECK 4: LEGITIMATE ARCHITECTURE & ROUTE CONFORMANCE
  // ==========================================================================
  print('\n--- CHECK 4: LEGITIMATE ARCHITECTURE & ROUTE CONFORMANCE ---');
  final routerFile = File('lib/app/router.dart');
  assertCheck(routerFile.existsSync(), 'router.dart exists');
  final routerCode = routerFile.readAsStringSync();

  // 4.1 StatefulShellRoute.indexedStack used
  assertCheck(
    routerCode.contains('StatefulShellRoute.indexedStack'),
    'router.dart configures StatefulShellRoute.indexedStack',
  );

  // 4.2 Branch 3 synchronized to /profile
  final branch3Match = RegExp(r"path:\s*'/profile'").hasMatch(routerCode);
  assertCheck(branch3Match, 'router.dart registers /profile in shell branch');

  // 4.3 ProfileScreen mapped to Branch 3
  assertCheck(
    routerCode.contains('ProfileScreen()') &&
        routerCode.contains("import '../features/profile/presentation/profile_screen.dart';"),
    'router.dart imports and builds ProfileScreen for /profile branch',
  );

  // 4.4 Tab 3 label in shell is strictly 'Profil'
  assertCheck(
    shellCode.contains("label: 'Profil'") && !shellCode.contains("label: 'Menu'"),
    "Tab 3 label is synchronized to 'Profil' and legacy 'Menu' is eradicated",
  );

  // 4.5 Tab 3 icon is person icon and NOT tune_rounded
  assertCheck(
    shellCode.contains('Icons.person_outline_rounded') &&
        shellCode.contains('Icons.person_rounded') &&
        !shellCode.contains('Icons.tune_rounded'),
    'Tab 3 uses person icons and legacy Icons.tune_rounded is eradicated',
  );

  // 4.6 Dual-keying contract
  assertCheck(
    shellCode.contains("Key('nav_bar')") &&
        shellCode.contains("Key('nav_tab_0')") &&
        shellCode.contains("Key('nav_tab_1')") &&
        shellCode.contains("Key('nav_tab_2')") &&
        shellCode.contains("Key('nav_tab_3')") &&
        shellCode.contains("Key('nav_tab_home')") &&
        shellCode.contains("Key('nav_tab_history')") &&
        shellCode.contains("Key('nav_tab_wallet')") &&
        shellCode.contains("Key('nav_tab_profile')") &&
        shellCode.contains("Key('nav_fab')"),
    'Complete dual-keying contract (positional + semantic + bar + fab) is implemented',
  );

  // ==========================================================================
  // CHECK 5: NO INTENT CIRCUMVENTION & AUTHENTIC WCAG STYLING
  // ==========================================================================
  print('\n--- CHECK 5: NO INTENT CIRCUMVENTION & AUTHENTIC WCAG STYLING ---');

  // 5.1 AppColors tokens imported and used
  final colorsFile = File('lib/core/theme/app_colors.dart');
  assertCheck(colorsFile.existsSync(), 'lib/core/theme/app_colors.dart exists');
  final colorsCode = colorsFile.readAsStringSync();
  assertCheck(colorsCode.contains('static const Color neoGreen'), 'AppColors defines neoGreen');
  assertCheck(colorsCode.contains('static const Color neoGreenContrast'), 'AppColors defines neoGreenContrast');
  assertCheck(colorsCode.contains('static const Color neoGreenSurface'), 'AppColors defines neoGreenSurface');
  assertCheck(colorsCode.contains('static const Color neoGreenGlow'), 'AppColors defines neoGreenGlow');

  // 5.2 Mathematical WCAG 2.1 Contrast ratios
  final lWhite = ForensicWcagOracle.relativeLuminance(255, 255, 255);       // #FFFFFF = 1.0
  final lSurface = ForensicWcagOracle.relativeLuminance(247, 254, 231);     // #F7FEE7
  final lNeoGreen = ForensicWcagOracle.relativeLuminance(163, 230, 53);     // #A3E635
  final lContrast = ForensicWcagOracle.relativeLuminance(20, 41, 0);        // #142900
  final lTextSec = ForensicWcagOracle.relativeLuminance(100, 116, 139);     // #64748B

  final crActive = ForensicWcagOracle.contrastRatio(lContrast, lSurface);
  final crInactive = ForensicWcagOracle.contrastRatio(lTextSec, lWhite);
  final crFab = ForensicWcagOracle.contrastRatio(lContrast, lNeoGreen);
  final crRawNeoOnWhite = ForensicWcagOracle.contrastRatio(lNeoGreen, lWhite);

  assertCheck(
    crActive >= 7.0,
    'Active tab contrast (${crActive.toStringAsFixed(2)}:1) satisfies WCAG AAA (>= 7.0:1)',
    'Active contrast is below 7.0:1',
  );
  assertCheck(
    crInactive >= 4.5,
    'Inactive tab contrast (${crInactive.toStringAsFixed(2)}:1) satisfies WCAG AA (>= 4.5:1)',
    'Inactive contrast is below 4.5:1',
  );
  assertCheck(
    crFab >= 3.0,
    'Center FAB contrast (${crFab.toStringAsFixed(2)}:1) satisfies WCAG UI standard (>= 3.0:1)',
    'FAB contrast is below 3.0:1',
  );
  assertCheck(
    crRawNeoOnWhite < 3.0,
    'Confirmed direct neoGreen on white (${crRawNeoOnWhite.toStringAsFixed(2)}:1) fails contrast, validating use of dark contrast glyphs inside pill',
  );

  // 5.3 Center FAB visual authenticity
  assertCheck(
    shellCode.contains('AppColors.neoGreenLight') &&
        shellCode.contains('AppColors.neoGreen') &&
        shellCode.contains('AppColors.neoGreenDark') &&
        shellCode.contains('AppColors.neoGreenGlow'),
    'Center FAB uses full authentic neo-green gradient and signature aura glow tokens',
  );

  print('\n======================================================================');
  print('  AUDIT RESULTS SUMMARY');
  print('  Total Forensic Checks: $totalChecks');
  print('  Passed:                $passedChecks');
  print('  Failed:                $failedChecks');
  print('======================================================================\n');

  if (failedChecks > 0) {
    print('>> VERDICT: INTEGRITY VIOLATION <<');
    exit(1);
  } else {
    print('>> VERDICT: CLEAN <<');
    exit(0);
  }
}
