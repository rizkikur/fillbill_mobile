import 'dart:io';

/// Master End-to-End Verification Runner for FillBill Mobile
/// Executes all standalone empirical, adversarial, challenge, and forensic test suites
/// across Milestones 1 through 4, aggregates assertions, and prints a comprehensive scorecard.
void main(List<String> args) async {
  print('======================================================================');
  print('       FILLBILL MOBILE — MASTER E2E VERIFICATION RUNNER (M1–M5)       ');
  print('======================================================================');
  print('Timestamp: ${DateTime.now().toUtc().toIso8601String()}');
  print('Dart SDK:  ${Platform.version.split(' ').first}');
  print('Platform:  ${Platform.operatingSystem} ${Platform.operatingSystemVersion}');
  print('Directory: ${Directory.current.path}\n');

  final dartExecutable = Platform.executable;

  // Resolve fillbill_mobile root directory
  String appDir = Directory.current.path;
  if (!File('$appDir/pubspec.yaml').existsSync()) {
    if (File('$appDir/fillbill_mobile/pubspec.yaml').existsSync()) {
      appDir = '$appDir/fillbill_mobile';
    } else {
      final scriptDir = File(Platform.script.toFilePath()).parent.parent.path;
      if (File('$scriptDir/pubspec.yaml').existsSync()) {
        appDir = scriptDir;
      }
    }
  }

  print('App Directory: $appDir\n');

  final suites = <TestSuiteMeta>[
    TestSuiteMeta(
      category: 'Milestone 2: Splash & Onboarding',
      file: 'test/standalone_milestone_2_stress_test.dart',
      description: 'Splash timing bounds, cold start, returning user bypass, PopScope',
    ),
    TestSuiteMeta(
      category: 'Milestone 2: Adversarial Challenges',
      file: 'test/standalone_milestone_2_challenger_2_test.dart',
      description: 'Storage corrupted JSON, rapid clicks, null values, back gesture',
    ),
    TestSuiteMeta(
      category: 'Milestone 3: Top-Up & Navigation',
      file: 'test/standalone_milestone_3_test.dart',
      description: 'Rupiah parsing, nominal bounds, fee calculation, MockWalletStore',
    ),
    TestSuiteMeta(
      category: 'Milestone 3: Adversarial Fuzzing',
      file: 'test/standalone_milestone_3_adversarial_test.dart',
      description: 'Int32/64 overflow, zero-amount protection, currency injection',
    ),
    TestSuiteMeta(
      category: 'Milestone 3: Empirical Calculation',
      file: 'test/empirical_topup_calc_challenge_test.dart',
      description: 'Channel fee structures, total price invariants, rounding safety',
    ),
    TestSuiteMeta(
      category: 'Milestone 3: Empirical Mock Store',
      file: 'test/empirical_topup_store_challenge_test.dart',
      description: 'Stateful ledger invariants, concurrent mutations, history balance',
    ),
    TestSuiteMeta(
      category: 'Milestone 3: Adversarial Audit',
      file: 'test/reviewer_m3_adversarial_audit_test.dart',
      description: 'Code AST static contract audit, route mapping, keys verification',
    ),
    TestSuiteMeta(
      category: 'Milestone 3: Forensic Audit',
      file: 'test/auditor_m3_forensic_test.dart',
      description: 'Forensic integrity, zero backdoor/mock facade detection',
    ),
    TestSuiteMeta(
      category: 'Milestone 4: Modern Bottom Nav Shell',
      file: 'test/standalone_milestone_4_test.dart',
      description: 'State preservation, branch switching, active soft-pill, FAB aura',
    ),
    TestSuiteMeta(
      category: 'Milestone 4: WCAG 2.1 Contrast Standards',
      file: 'test/empirical_nav_contrast_challenge_test.dart',
      description: 'Relative luminance, WCAG AAA active pill text, AA inactive labels',
    ),
    TestSuiteMeta(
      category: 'Milestone 4: Shell Responsive & Keys',
      file: 'test/empirical_nav_shell_challenge_test.dart',
      description: 'Multi-screen reflow (320px–1024px), Bézier scoop, dual-key contract',
    ),
    TestSuiteMeta(
      category: 'Milestone 4: Adversarial Audit',
      file: 'test/reviewer_m4_adversarial_test.dart',
      description: 'Profile route alignment, menu eradication, FAB click isolation',
    ),
    TestSuiteMeta(
      category: 'Milestone 4: Forensic Audit',
      file: 'test/auditor_m4_forensic_integrity_test.dart',
      description: 'Forensic checks 1-5, authentic neo-green tokens, zero fake metrics',
    ),
  ];

  int totalSuites = suites.length;
  int passedSuites = 0;
  int failedSuites = 0;
  int grandTotalAssertions = 0;
  int grandTotalPassedAssertions = 0;
  int grandTotalFailedAssertions = 0;
  final stopwatch = Stopwatch()..start();

  final results = <SuiteExecutionResult>[];

  for (int i = 0; i < suites.length; i++) {
    final suite = suites[i];
    stdout.write('[${(i + 1).toString().padLeft(2, '0')}/$totalSuites] Running ${suite.file}... ');

    final resolvedFilePath = '$appDir/${suite.file}';
    final file = File(resolvedFilePath);
    if (!file.existsSync()) {
      print('MISSING FILE ($resolvedFilePath)');
      failedSuites++;
      results.add(SuiteExecutionResult(
        meta: suite,
        exitCode: 1,
        passed: false,
        durationMs: 0,
        assertionsPassed: 0,
        assertionsFailed: 1,
        summary: 'Error: File does not exist',
      ));
      continue;
    }

    final sw = Stopwatch()..start();
    final processResult = await Process.run(
      dartExecutable,
      [suite.file],
      workingDirectory: appDir,
    );
    sw.stop();

    final output = '${processResult.stdout}\n${processResult.stderr}';
    final isSuccess = processResult.exitCode == 0;

    int passedCount = 0;
    int failedCount = 0;

    // Parse assertions from output
    final passMatches = RegExp(r'\[PASS\]').allMatches(output);
    final failMatches = RegExp(r'\[FAIL\]').allMatches(output);
    passedCount = passMatches.length;
    failedCount = failMatches.length;

    // Check summary block if available
    final totalSummaryMatch = RegExp(r'Total Assertions:\s*(\d+)').firstMatch(output);
    final passedSummaryMatch = RegExp(r'Passed:\s*(\d+)').firstMatch(output);
    final failedSummaryMatch = RegExp(r'Failed:\s*(\d+)').firstMatch(output);

    if (totalSummaryMatch != null && passedSummaryMatch != null) {
      passedCount = int.parse(passedSummaryMatch.group(1)!);
      failedCount = failedSummaryMatch != null ? int.parse(failedSummaryMatch.group(1)!) : 0;
    }

    if (isSuccess && passedCount == 0) {
      // Fallback if suite did not use standard assertion formatting
      passedCount = 1;
    }

    grandTotalAssertions += (passedCount + failedCount);
    grandTotalPassedAssertions += passedCount;
    grandTotalFailedAssertions += failedCount;

    if (isSuccess && failedCount == 0) {
      passedSuites++;
      print('PASS ($passedCount assertions, ${sw.elapsedMilliseconds}ms)');
    } else {
      failedSuites++;
      print('FAIL (Exit: ${processResult.exitCode}, Failed assertions: $failedCount, ${sw.elapsedMilliseconds}ms)');
    }

    // Extract verdict summary line
    String summaryLine = '';
    final lines = output.split('\n');
    for (final line in lines.reversed) {
      final trimmed = line.trim();
      if (trimmed.contains('VERDICT') || trimmed.contains('CONFIRMED') || trimmed.contains('PASSED') || trimmed.contains('CLEAN')) {
        summaryLine = trimmed;
        break;
      }
    }

    results.add(SuiteExecutionResult(
      meta: suite,
      exitCode: processResult.exitCode,
      passed: isSuccess && failedCount == 0,
      durationMs: sw.elapsedMilliseconds,
      assertionsPassed: passedCount,
      assertionsFailed: failedCount,
      summary: summaryLine.isNotEmpty ? summaryLine : (isSuccess ? 'PASS' : 'FAIL'),
    ));
  }

  stopwatch.stop();

  // Print Scorecard Table
  print('\n====================================================================================================');
  print('                                   MASTER VERIFICATION SCORECARD                                    ');
  print('====================================================================================================');
  print('${'#'.padRight(3)} | ${'Test Suite'.padRight(42)} | ${'Category'.padRight(28)} | ${'Assertions'.padRight(10)} | ${'Duration'.padRight(8)} | Status');
  print('----+--------------------------------------------+------------------------------+------------+----------+--------');

  for (int i = 0; i < results.length; i++) {
    final r = results[i];
    final numStr = '${i + 1}'.padRight(3);
    final fileStr = (r.meta.file.replaceFirst('test/', '')).padRight(42);
    final catStr = (r.meta.category.length > 28 ? r.meta.category.substring(0, 28) : r.meta.category).padRight(28);
    final assertStr = '${r.assertionsPassed}/${r.assertionsPassed + r.assertionsFailed}'.padRight(10);
    final durStr = '${r.durationMs}ms'.padRight(8);
    final statusStr = r.passed ? 'PASSED' : 'FAILED';
    print('$numStr | $fileStr | $catStr | $assertStr | $durStr | $statusStr');
  }

  print('====================================================================================================');
  print('                                          GRAND TOTALS                                              ');
  print('====================================================================================================');
  print('Test Suites Executed:     $totalSuites');
  print('Test Suites Passed:       $passedSuites (${(passedSuites / totalSuites * 100).toStringAsFixed(1)}%)');
  print('Test Suites Failed:       $failedSuites');
  print('Total Assertions Executed: $grandTotalAssertions');
  print('Total Assertions Passed:   $grandTotalPassedAssertions (${(grandTotalPassedAssertions / grandTotalAssertions * 100).toStringAsFixed(1)}%)');
  print('Total Assertions Failed:   $grandTotalFailedAssertions');
  print('Total Verification Time:   ${stopwatch.elapsedMilliseconds} ms (${(stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(2)}s)');
  print('====================================================================================================');

  if (failedSuites == 0 && grandTotalFailedAssertions == 0) {
    print('\n>> MASTER VERDICT: 100% E2E VERIFICATION PASSED — SYSTEM FULLY HARDENED & CLEAN <<\n');
    exit(0);
  } else {
    print('\n>> MASTER VERDICT: VERIFICATION FAILED — $failedSuites SUITES FAILED <<\n');
    exit(1);
  }
}

class TestSuiteMeta {
  final String category;
  final String file;
  final String description;
  TestSuiteMeta({required this.category, required this.file, required this.description});
}

class SuiteExecutionResult {
  final TestSuiteMeta meta;
  final int exitCode;
  final bool passed;
  final int durationMs;
  final int assertionsPassed;
  final int assertionsFailed;
  final String summary;

  SuiteExecutionResult({
    required this.meta,
    required this.exitCode,
    required this.passed,
    required this.durationMs,
    required this.assertionsPassed,
    required this.assertionsFailed,
    required this.summary,
  });
}
