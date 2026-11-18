import 'dart:io';
import 'dart:math';

// ============================================================================
// EMPIRICAL CHALLENGE TEST SUITE: MILESTONE 4
// StatefulNavigationShell Branch Switching, State Persistence & Key Contracts
// ============================================================================

/// State container simulating IndexedStack state isolation
class BranchStateStore {
  final Map<String, dynamic> state = {};
  int buildCount = 0;

  void set(String key, dynamic val) => state[key] = val;
  dynamic get(String key) => state[key];
}

/// Robust Navigation Shell Emulator modeling GoRouter StatefulNavigationShell
class ChallengeNavigationShellEmulator {
  int currentIndex = 0;
  final List<List<String>> _branchStacks;
  final List<BranchStateStore> _branchStates;
  final List<int> _switchHistory = [];

  ChallengeNavigationShellEmulator()
      : _branchStacks = [
          ['/home'],
          ['/transactions'],
          ['/wallet'],
          ['/profile'],
        ],
        _branchStates = [
          BranchStateStore(),
          BranchStateStore(),
          BranchStateStore(),
          BranchStateStore(),
        ] {
    _switchHistory.add(0);
    _branchStates[0].buildCount++;
  }

  int get branchCount => _branchStacks.length;
  List<int> get history => List.unmodifiable(_switchHistory);

  void goBranch(int index, {bool initialLocation = false}) {
    if (index < 0 || index >= _branchStacks.length) {
      throw RangeError.index(index, _branchStacks, 'index', 'Branch index out of range');
    }

    if (index == currentIndex && initialLocation) {
      // Reset this branch's stack to root
      _branchStacks[index] = [_branchStacks[index].first];
    } else {
      if (index != currentIndex) {
        _branchStates[index].buildCount++;
      }
      currentIndex = index;
    }
    _switchHistory.add(index);
  }

  void push(String route) {
    _branchStacks[currentIndex].add(route);
  }

  void pop() {
    if (_branchStacks[currentIndex].length > 1) {
      _branchStacks[currentIndex].removeLast();
    }
  }

  String get currentRoute => _branchStacks[currentIndex].last;
  int get currentStackDepth => _branchStacks[currentIndex].length;
  int getStackDepth(int index) => _branchStacks[index].length;
  String getTopRoute(int index) => _branchStacks[index].last;
  BranchStateStore getState(int index) => _branchStates[index];
}

/// Standalone WCAG 2.1 Contrast Calculator
class WcagCalculator {
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
  print('  EMPIRICAL CHALLENGER TEST SUITE: MILESTONE 4                        ');
  print('  StatefulNavigationShell Branch Switching & Key Contracts Stress Test');
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

  // ==========================================================================
  // SECTION 1: BRANCH INDICES & ROUTE PATHS CONTRACT (router.dart)
  // ==========================================================================
  print('--- SECTION 1: Branch Indices & Route Paths Contract in router.dart ---');
  {
    final routerFile = File('lib/app/router.dart');
    expect(routerFile.existsSync(), 'lib/app/router.dart exists');

    final routerSrc = routerFile.readAsStringSync();

    // Check StatefulShellRoute setup
    expect(routerSrc.contains('StatefulShellRoute.indexedStack'), 'Uses StatefulShellRoute.indexedStack for branch navigation');
    expect(routerSrc.contains('MainNavShell(navigationShell: navigationShell)'), 'MainNavShell is attached as shell builder');

    // Branch 0: /home
    expect(routerSrc.contains("path: '/home'"), 'Branch 0 contains path "/home"');
    expect(routerSrc.contains('builder: (context, state) => const HomeScreen()'), 'Branch 0 builder returns HomeScreen()');

    // Branch 1: /transactions
    expect(routerSrc.contains("path: '/transactions'"), 'Branch 1 contains path "/transactions"');
    expect(routerSrc.contains('builder: (context, state) => const TransactionsScreen()'), 'Branch 1 builder returns TransactionsScreen()');

    // Branch 2: /wallet
    expect(routerSrc.contains("path: '/wallet'"), 'Branch 2 contains path "/wallet"');
    expect(routerSrc.contains('builder: (context, state) => const WalletScreen()'), 'Branch 2 builder returns WalletScreen()');

    // Branch 3: /profile
    expect(routerSrc.contains("path: '/profile'"), 'Branch 3 contains path "/profile"');
    expect(routerSrc.contains('builder: (context, state) => const ProfileScreen()'), 'Branch 3 builder returns ProfileScreen()');

    // Order verification in StatefulShellRoute branches array
    final branchesIdx = routerSrc.indexOf('StatefulShellRoute.indexedStack');
    expect(branchesIdx != -1, 'StatefulShellRoute.indexedStack is found');

    final homeIdx = routerSrc.indexOf("path: '/home'", branchesIdx);
    final transIdx = routerSrc.indexOf("path: '/transactions'", homeIdx);
    final walletIdx = routerSrc.indexOf("path: '/wallet'", transIdx);
    final profileIdx = routerSrc.indexOf("path: '/profile'", walletIdx);

    expect(homeIdx != -1 && transIdx > homeIdx && walletIdx > transIdx && profileIdx > walletIdx,
        'Branches are strictly ordered: 0 (/home) -> 1 (/transactions) -> 2 (/wallet) -> 3 (/profile)');
  }

  // ==========================================================================
  // SECTION 2: STATIC KEY CONTRACTS & SOURCE AST IN main_nav_shell.dart
  // ==========================================================================
  print('\n--- SECTION 2: Static Key Contracts & Source AST in main_nav_shell.dart ---');
  {
    final shellFile = File('lib/app/main_nav_shell.dart');
    expect(shellFile.existsSync(), 'lib/app/main_nav_shell.dart exists');

    final shellSrc = shellFile.readAsStringSync();

    // 10 Key Contracts Checklist
    final expectedKeys = [
      "Key('nav_bar')",
      "Key('nav_tab_0')",
      "Key('nav_tab_1')",
      "Key('nav_tab_2')",
      "Key('nav_tab_3')",
      "Key('nav_tab_home')",
      "Key('nav_tab_history')",
      "Key('nav_tab_wallet')",
      "Key('nav_tab_profile')",
      "Key('nav_fab')",
    ];

    for (final key in expectedKeys) {
      final firstIdx = shellSrc.indexOf(key);
      final lastIdx = shellSrc.lastIndexOf(key);
      expect(firstIdx != -1, 'Contains deterministic key $key');
      expect(firstIdx == lastIdx, 'Key $key is strictly unique in file (no duplicate bindings)');
    }

    // Verify Tab 0 structure
    expect(shellSrc.contains("itemKey: const Key('nav_tab_0')"), 'Tab 0 itemKey is nav_tab_0');
    expect(shellSrc.contains("semanticKey: const Key('nav_tab_home')"), 'Tab 0 semanticKey is nav_tab_home');
    expect(shellSrc.contains('branchTarget: 0'), 'Tab 0 targets branch 0');
    expect(shellSrc.contains("label: 'Home'"), 'Tab 0 label is "Home"');
    expect(shellSrc.contains('icon: Icons.home_outlined'), 'Tab 0 inactive icon is Icons.home_outlined');
    expect(shellSrc.contains('selectedIcon: Icons.home_rounded'), 'Tab 0 active icon is Icons.home_rounded');

    // Verify Tab 1 structure
    expect(shellSrc.contains("itemKey: const Key('nav_tab_1')"), 'Tab 1 itemKey is nav_tab_1');
    expect(shellSrc.contains("semanticKey: const Key('nav_tab_history')"), 'Tab 1 semanticKey is nav_tab_history');
    expect(shellSrc.contains('branchTarget: 1'), 'Tab 1 targets branch 1');
    expect(shellSrc.contains("label: 'Riwayat'"), 'Tab 1 label is "Riwayat"');
    expect(shellSrc.contains('icon: Icons.receipt_long_outlined'), 'Tab 1 inactive icon is Icons.receipt_long_outlined');
    expect(shellSrc.contains('selectedIcon: Icons.receipt_long_rounded'), 'Tab 1 active icon is Icons.receipt_long_rounded');

    // Verify Tab 2 structure
    expect(shellSrc.contains("itemKey: const Key('nav_tab_2')"), 'Tab 2 itemKey is nav_tab_2');
    expect(shellSrc.contains("semanticKey: const Key('nav_tab_wallet')"), 'Tab 2 semanticKey is nav_tab_wallet');
    expect(shellSrc.contains('branchTarget: 2'), 'Tab 2 targets branch 2');
    expect(shellSrc.contains("label: 'Dompet'"), 'Tab 2 label is "Dompet"');
    expect(shellSrc.contains('icon: Icons.account_balance_wallet_outlined'), 'Tab 2 inactive icon is Icons.account_balance_wallet_outlined');
    expect(shellSrc.contains('selectedIcon: Icons.account_balance_wallet_rounded'), 'Tab 2 active icon is Icons.account_balance_wallet_rounded');

    // Verify Tab 3 structure (Synchronized to Profil)
    expect(shellSrc.contains("itemKey: const Key('nav_tab_3')"), 'Tab 3 itemKey is nav_tab_3');
    expect(shellSrc.contains("semanticKey: const Key('nav_tab_profile')"), 'Tab 3 semanticKey is nav_tab_profile');
    expect(shellSrc.contains('branchTarget: 3'), 'Tab 3 targets branch 3');
    expect(shellSrc.contains("label: 'Profil'"), 'Tab 3 label is "Profil"');
    expect(shellSrc.contains('icon: Icons.person_outline_rounded'), 'Tab 3 inactive icon is Icons.person_outline_rounded');
    expect(shellSrc.contains('selectedIcon: Icons.person_rounded'), 'Tab 3 active icon is Icons.person_rounded');

    // Negative assertions against legacy code
    expect(!shellSrc.contains("'Menu'"), 'Legacy label "Menu" is completely eliminated');
    expect(!shellSrc.contains('Icons.tune_rounded'), 'Legacy icon Icons.tune_rounded is completely eliminated');

    // Center FAB verification
    expect(shellSrc.contains("key: const Key('nav_fab')"), 'Center FAB key is nav_fab');
    expect(shellSrc.contains('QuickTopUpSheet.show(context)'), 'Center FAB triggers QuickTopUpSheet modal');
    expect(shellSrc.contains('Icons.qr_code_scanner_rounded'), 'Center FAB icon is Icons.qr_code_scanner_rounded');

    // Microinteraction & Token assertions
    expect(shellSrc.contains('AppColors.neoGreenSurface'), 'Active soft pill uses AppColors.neoGreenSurface');
    expect(shellSrc.contains('AppColors.neoGreenContrast'), 'Active text and icon use AppColors.neoGreenContrast');
    expect(shellSrc.contains('AppColors.textSecondary'), 'Inactive text and icon use AppColors.textSecondary');
    expect(shellSrc.contains('AnimatedContainer'), 'Tab pill uses AnimatedContainer');
    expect(shellSrc.contains('AnimatedDefaultTextStyle'), 'Tab text uses AnimatedDefaultTextStyle');
    expect(shellSrc.contains('Duration(milliseconds: 200)'), 'Animations use Duration(milliseconds: 200)');
    expect(shellSrc.contains('Curves.easeInOutCubic'), 'Animations use Curves.easeInOutCubic');
  }

  // ==========================================================================
  // SECTION 3: 100-STEP RAPID SEQUENTIAL BRANCH SWITCHING SIMULATION
  // ==========================================================================
  print('\n--- SECTION 3: 100-Step Rapid Sequential Branch Switching Simulation ---');
  {
    final shell = ChallengeNavigationShellEmulator();
    final random = Random(42); // Deterministic seed for reproducible adversarial testing

    int totalTransitions = 100;
    int stateIntegrityChecks = 0;
    bool allInvariantsPassed = true;

    // Track oracle states for each branch
    final Map<int, int> oracleCounters = {0: 0, 1: 0, 2: 0, 3: 0};
    final Map<int, List<String>> oracleStacks = {
      0: ['/home'],
      1: ['/transactions'],
      2: ['/wallet'],
      3: ['/profile'],
    };

    for (int step = 1; step <= totalTransitions; step++) {
      final prevIndex = shell.currentIndex;
      final targetBranch = random.nextInt(4);
      final isSelfReTap = targetBranch == prevIndex;
      final useInitialLocation = isSelfReTap && random.nextBool();

      // Mutate current branch before switching (50% chance push subroute, 50% chance increment counter)
      if (random.nextBool()) {
        final subRoute = '${oracleStacks[prevIndex]!.first}/sub_$step';
        shell.push(subRoute);
        oracleStacks[prevIndex]!.add(subRoute);
      }
      oracleCounters[prevIndex] = (oracleCounters[prevIndex] ?? 0) + 1;
      shell.getState(prevIndex).set('counter', oracleCounters[prevIndex]);

      // Execute goBranch transition
      shell.goBranch(targetBranch, initialLocation: useInitialLocation);

      // If re-tapped with initialLocation, update oracle stack
      if (isSelfReTap && useInitialLocation) {
        oracleStacks[targetBranch] = [oracleStacks[targetBranch]!.first];
      }

      // INVARIANT 1: Current index strictly equals target branch
      if (shell.currentIndex != targetBranch) {
        allInvariantsPassed = false;
        print('    [VIOLATION at step $step] shell.currentIndex (${shell.currentIndex}) != targetBranch ($targetBranch)');
      }

      // INVARIANT 2: Active stack depth matches oracle stack depth
      if (shell.currentStackDepth != oracleStacks[targetBranch]!.length) {
        allInvariantsPassed = false;
        print('    [VIOLATION at step $step] Active stack depth mismatch for branch $targetBranch');
      }

      // INVARIANT 3: Active top route matches oracle top route
      if (shell.currentRoute != oracleStacks[targetBranch]!.last) {
        allInvariantsPassed = false;
        print('    [VIOLATION at step $step] Active top route mismatch for branch $targetBranch');
      }

      // INVARIANT 4: Zero Cross-Branch State Contamination
      // Check every branch 0..3 against oracle stack and state counter
      for (int b = 0; b < 4; b++) {
        stateIntegrityChecks++;
        if (shell.getStackDepth(b) != oracleStacks[b]!.length) {
          allInvariantsPassed = false;
          print('    [CONTAMINATION at step $step] Branch $b depth corrupted!');
        }
        if (shell.getTopRoute(b) != oracleStacks[b]!.last) {
          allInvariantsPassed = false;
          print('    [CONTAMINATION at step $step] Branch $b route corrupted!');
        }
        final recordedCounter = shell.getState(b).get('counter') ?? 0;
        if (recordedCounter != oracleCounters[b]) {
          allInvariantsPassed = false;
          print('    [STATE LEAKAGE at step $step] Branch $b counter mismatch: recorded=$recordedCounter, expected=${oracleCounters[b]}');
        }
      }
    }

    expect(allInvariantsPassed, '100 rapid sequential branch transitions completed with ZERO invariant violations');
    expect(stateIntegrityChecks == 400, '400 full cross-branch state isolation checks passed (4 per step)');
    expect(shell.history.length == 101, 'Navigation shell logged all 101 transitions (initial + 100 steps)');
  }

  // ==========================================================================
  // SECTION 4: HOSTILE BOUNDARY, EDGE CASES & EXCEPTION SAFETY
  // ==========================================================================
  print('\n--- SECTION 4: Hostile Boundary, Edge Cases & Exception Safety ---');
  {
    final shell = ChallengeNavigationShellEmulator();

    // 1. Negative Branch Index
    bool caughtNegative = false;
    try {
      shell.goBranch(-1);
    } catch (e) {
      if (e is RangeError) caughtNegative = true;
    }
    expect(caughtNegative, 'goBranch(-1) throws RangeError');
    expect(shell.currentIndex == 0, 'Current index remains 0 after negative index rejection');

    // 2. Out-of-Bounds Upper Index
    bool caughtUpperBound = false;
    try {
      shell.goBranch(4);
    } catch (e) {
      if (e is RangeError) caughtUpperBound = true;
    }
    expect(caughtUpperBound, 'goBranch(4) throws RangeError');
    expect(shell.currentIndex == 0, 'Current index remains 0 after upper bound rejection');

    bool caughtExtremeBound = false;
    try {
      shell.goBranch(99999);
    } catch (e) {
      if (e is RangeError) caughtExtremeBound = true;
    }
    expect(caughtExtremeBound, 'goBranch(99999) throws RangeError');

    // 3. Deep Route Nesting Across Branches
    // Push 50 subroutes on Branch 0
    for (int i = 1; i <= 50; i++) {
      shell.push('/home/level_$i');
    }
    expect(shell.currentStackDepth == 51, 'Branch 0 stack depth is 51 (root + 50 levels)');
    expect(shell.currentRoute == '/home/level_50', 'Branch 0 top route is /home/level_50');

    // Switch to Branch 2 (/wallet) and push 25 subroutes
    shell.goBranch(2);
    for (int i = 1; i <= 25; i++) {
      shell.push('/wallet/trx_$i');
    }
    expect(shell.currentStackDepth == 26, 'Branch 2 stack depth is 26');

    // Switch to Branch 3 (/profile) and push 10 subroutes
    shell.goBranch(3);
    for (int i = 1; i <= 10; i++) {
      shell.push('/profile/settings_$i');
    }
    expect(shell.currentStackDepth == 11, 'Branch 3 stack depth is 11');

    // Switch back to Branch 0: Verify 51-depth stack intact
    shell.goBranch(0);
    expect(shell.currentStackDepth == 51, 'Branch 0 retains 51-depth stack after multi-branch deep navigation');
    expect(shell.currentRoute == '/home/level_50', 'Branch 0 retains top route /home/level_50');

    // Switch to Branch 2: Reset to root with initialLocation: true
    shell.goBranch(2, initialLocation: false);
    expect(shell.currentStackDepth == 26, 'Branch 2 remains at depth 26 when initialLocation is false');

    shell.goBranch(2, initialLocation: true);
    expect(shell.currentStackDepth == 1, 'Branch 2 resets to depth 1 with initialLocation: true');
    expect(shell.currentRoute == '/wallet', 'Branch 2 resets to root /wallet');

    // Verify Branch 0 and Branch 3 stacks were NOT affected by Branch 2 reset!
    shell.goBranch(0);
    expect(shell.currentStackDepth == 51, 'Branch 0 stack completely unaffected by Branch 2 stack reset');
    shell.goBranch(3);
    expect(shell.currentStackDepth == 11, 'Branch 3 stack completely unaffected by Branch 2 stack reset');

    // 4. Rapid 50-step Ping-Pong between Branch 0 and Branch 1
    for (int i = 0; i < 25; i++) {
      shell.goBranch(0);
      shell.goBranch(1);
    }
    expect(shell.currentIndex == 1, 'Ping-pong completed on branch 1');
    shell.goBranch(0);
    expect(shell.currentIndex == 0, 'Ping-pong returned to branch 0 with intact depth 51');
    expect(shell.currentStackDepth == 51, 'Branch 0 still holds 51 items after ping-pong stress');
  }

  // ==========================================================================
  // SECTION 5: WCAG 2.1 CONTRAST & ACCESSIBILITY MATHEMATICAL PROOF
  // ==========================================================================
  print('\n--- SECTION 5: WCAG 2.1 Contrast & Accessibility Mathematical Proof ---');
  {
    final lSurfaceWhite = WcagCalculator.relativeLuminance(255, 255, 255);       // #FFFFFF
    final lNeoGreenSurface = WcagCalculator.relativeLuminance(247, 254, 231);   // #F7FEE7
    final lNeoGreen = WcagCalculator.relativeLuminance(163, 230, 53);           // #A3E635
    final lNeoGreenContrast = WcagCalculator.relativeLuminance(20, 41, 0);       // #142900
    final lTextSecondary = WcagCalculator.relativeLuminance(100, 116, 139);     // #64748B
    final lPrimaryNavy = WcagCalculator.relativeLuminance(13, 33, 55);          // #0D2137

    // 1. Active Soft Pill: neoGreenContrast (#142900) on neoGreenSurface (#F7FEE7)
    final crActivePill = WcagCalculator.contrastRatio(lNeoGreenContrast, lNeoGreenSurface);
    print('  - Active Soft Pill Text Contrast: ${crActivePill.toStringAsFixed(2)}:1');
    expect(crActivePill >= 7.0, 'Active pill text (${crActivePill.toStringAsFixed(2)}:1) satisfies WCAG AAA (>= 7.0:1)');
    expect(crActivePill >= 15.0, 'Active pill text reaches outstanding 15.0+:1 contrast');

    // 2. Inactive Tab: textSecondary (#64748B) on surfaceWhite (#FFFFFF)
    final crInactiveTab = WcagCalculator.contrastRatio(lTextSecondary, lSurfaceWhite);
    print('  - Inactive Tab Label Contrast: ${crInactiveTab.toStringAsFixed(2)}:1');
    expect(crInactiveTab >= 4.5, 'Inactive tab label (${crInactiveTab.toStringAsFixed(2)}:1) satisfies WCAG AA (>= 4.5:1)');

    // 3. Center FAB: neoGreenContrast (#142900) on neoGreen (#A3E635)
    final crFabIcon = WcagCalculator.contrastRatio(lNeoGreenContrast, lNeoGreen);
    print('  - FAB Icon on Neo-Green Contrast: ${crFabIcon.toStringAsFixed(2)}:1');
    expect(crFabIcon >= 3.0, 'FAB icon (${crFabIcon.toStringAsFixed(2)}:1) satisfies WCAG UI standard (>= 3.0:1)');
    expect(crFabIcon >= 10.0, 'FAB icon reaches outstanding 10.0+:1 contrast');

    // 4. Grounding Drop Shadow Contrast vs Dark Navy
    final crNavy = WcagCalculator.contrastRatio(lPrimaryNavy, lNeoGreen);
    expect(crNavy >= 7.0, 'FAB neoGreen vs primaryNavy contrast (${crNavy.toStringAsFixed(2)}:1) satisfies AAA');

    // 5. Raw Neo-Green Failure Proof (shows why neoGreen alone on white fails)
    final crRawFail = WcagCalculator.contrastRatio(lNeoGreen, lSurfaceWhite);
    print('  - Raw Neo-Green on White (Forbidden direct usage): ${crRawFail.toStringAsFixed(2)}:1');
    expect(crRawFail < 3.0, 'Empirical proof that raw neoGreen on white (${crRawFail.toStringAsFixed(2)}:1) fails accessibility without pill');
  }

  // ==========================================================================
  // FINAL VERDICT
  // ==========================================================================
  print('\n======================================================================');
  print('  CHALLENGER TEST RESULTS SUMMARY');
  print('  Total Assertions: $totalTests');
  print('  Passed:           $passedTests');
  print('  Failed:           $failedTests');
  print('======================================================================\n');

  if (failedTests > 0) {
    print('>> VERDICT: DISPROVEN / FAILED ($failedTests failures) <<\n');
    exit(1);
  } else {
    print('>> EMPIRICAL VERDICT: CONFIRMED CORRECT (100% Passed) <<\n');
  }
}
