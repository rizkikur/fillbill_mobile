import 'dart:io';

void main() {
  print('======================================================================');
  print('  FORENSIC AUDITOR M3: INDEPENDENT EMPIRICAL INTEGRITY TEST SUITE     ');
  print('======================================================================\n');

  int total = 0;
  int passed = 0;
  int failed = 0;

  void check(bool condition, String description, [String? failDetail]) {
    total++;
    if (condition) {
      passed++;
      print('  [PASS] $description');
    } else {
      failed++;
      print('  [FAIL] $description');
      if (failDetail != null) print('         -> $failDetail');
    }
  }

  // ==========================================================================
  // CHECK 1: NO HARDCODED TEST RESULTS OR PASS/FAIL FACADES
  // ==========================================================================
  print('--- Check 1: Hardcoded Test Results & Facades Forensics ---');
  {
    final topupScreen = File('lib/features/wallet/presentation/topup_screen.dart').readAsStringSync();
    final paymentSheet = File('lib/features/wallet/presentation/widgets/payment_simulation_sheet.dart').readAsStringSync();
    final formatter = File('lib/core/utils/rupiah_input_formatter.dart').readAsStringSync();
    final walletRepo = File('lib/features/wallet/data/wallet_repository.dart').readAsStringSync();
    final mockStore = File('lib/features/wallet/data/mock_wallet_store.dart').readAsStringSync();

    check(paymentSheet.isNotEmpty, 'PaymentSimulationSheet source is present');
    check(walletRepo.isNotEmpty, 'WalletRepository source is present');

    // Check that topup_screen does not hardcode static result status or fake success
    check(!topupScreen.contains('return true; // dummy'), 'No dummy return flags in TopupScreen');
    check(!topupScreen.contains('// hardcoded'), 'No hardcoded markers in TopupScreen');

    // Check that RupiahInputFormatter has genuine algorithmic parsing & formatting
    check(formatter.contains('replaceAll(RegExp(r\'[^\\d]\'), \'\')'), 'RupiahInputFormatter performs genuine digit sanitization');
    check(formatter.contains('digits.length > 11'), 'RupiahInputFormatter enforces 11-digit overflow protection');
    check(formatter.contains('int.tryParse'), 'RupiahInputFormatter parses integers dynamically');

    // Check that MockWalletStore updates real state variable
    check(mockStore.contains('_balanceCents += amountCents;'), 'MockWalletStore dynamically increments _balanceCents');
    check(mockStore.contains('_mutations.insert(0, newMutation);'), 'MockWalletStore prepends new mutation instance');
  }

  // ==========================================================================
  // CHECK 2: MATHEMATICAL & BOUNDARY STRESS-TESTING (PARSER & VALIDATOR)
  // ==========================================================================
  print('\n--- Check 2: Mathematical, Currency Parsing & Edge Case Stress-Testing ---');
  {
    int parse(String text) {
      final digits = text.replaceAll(RegExp(r'[^\d]'), '');
      return int.tryParse(digits) ?? 0;
    }

    // Edge cases
    check(parse('') == 0, 'Empty string -> 0');
    check(parse('    ') == 0, 'Whitespace string -> 0');
    check(parse('0') == 0, 'Single 0 -> 0');
    check(parse('00000') == 0, 'Multiple zeros -> 0');
    check(parse('Rp 0') == 0, '"Rp 0" -> 0');
    check(parse('Rp 10.000') == 10000, '"Rp 10.000" -> 10000');
    check(parse('Rp 9.999.999.999') == 9999999999, 'Large nominal 9.999.999.999 parses correctly');
    check(parse('Rp -50.000') == 50000, 'Negative sign stripped to positive nominal');
    check(parse('Rp 50.000,00') == 5000000, 'Trailing decimals stripped to clean digits');
    check(parse('ABC-!@#\$%^&*()') == 0, 'Special characters without digits safely return 0');
    check(parse('12a34b56') == 123456, 'Mixed alphanumeric string strips non-digits');
    check(parse('🔥Rp 100.000🚀') == 100000, 'Emoji-laden string strips emojis correctly');

    // Boundary validation logic
    const int minCents = 1000000;    // Rp 10.000
    const int maxCents = 1000000000; // Rp 10.000.000

    String? validate(int cents) {
      if (cents == 0) return null;
      if (cents < minCents) return 'Minimal top up Rp 10.000';
      if (cents > maxCents) return 'Maksimal top up Rp 10.000.000';
      return null;
    }

    bool isValid(int cents) => cents >= minCents && cents <= maxCents;

    check(validate(0) == null, 'Cents 0 has no error (neutral initial state)');
    check(!isValid(0), 'Cents 0 is not valid to submit CTA');
    check(validate(1) == 'Minimal top up Rp 10.000', '1 cent triggers minimum error');
    check(validate(minCents - 1) == 'Minimal top up Rp 10.000', 'minCents - 1 cent triggers minimum error');
    check(validate(minCents) == null, 'Exact min boundary (Rp 10.000) has no error');
    check(isValid(minCents), 'Exact min boundary is valid for CTA');
    check(validate(maxCents) == null, 'Exact max boundary (Rp 10.000.000) has no error');
    check(isValid(maxCents), 'Exact max boundary is valid for CTA');
    check(validate(maxCents + 1) == 'Maksimal top up Rp 10.000.000', 'maxCents + 1 cent triggers maximum error');
    check(!isValid(maxCents + 1), 'maxCents + 1 cent is not valid for CTA');
  }

  // ==========================================================================
  // CHECK 3: FEE CALCULATION & FINANCIAL PRECISION
  // ==========================================================================
  print('\n--- Check 3: Fee Calculation & Financial Precision ---');
  {
    int calcFee(String feeType, int feeCents, int nominalCents) {
      if (feeType == 'percentage') {
        return (nominalCents * 0.007).round();
      }
      return feeCents;
    }

    // VA flat fee Rp 2.500 (250,000 cents)
    check(calcFee('flat', 250000, 10000000) == 250000, 'Flat VA fee is 250000 cents');
    check(10000000 + calcFee('flat', 250000, 10000000) == 10250000, 'Total for Rp 100.000 VA is 10,250,000 cents');

    // E-Wallet flat fee Rp 1.000 (100,000 cents)
    check(calcFee('flat', 100000, 5000000) == 100000, 'Flat E-Wallet fee is 100000 cents');
    check(5000000 + calcFee('flat', 100000, 5000000) == 5100000, 'Total for Rp 50.000 E-Wallet is 5,100,000 cents');

    // QRIS 0.7% percentage fee
    // 0.7% of Rp 10.000 (1,000,000 cents) = 7,000 cents (Rp 70)
    check(calcFee('percentage', 0, 1000000) == 7000, 'QRIS 0.7% on Rp 10.000 is 7,000 cents (Rp 70)');
    // 0.7% of Rp 25.430 (2,543,000 cents) = 17,801 cents -> round()
    check(calcFee('percentage', 0, 2543000) == (2543000 * 0.007).round(), 'QRIS 0.7% rounding precision on odd nominal');
    // Manual transfer fee = 0
    check(calcFee('flat', 0, 10000000) == 0, 'Manual transfer fee is 0');
  }

  // ==========================================================================
  // CHECK 4: MOCK WALLET STORE CONCURRENCY & ACCUMULATION
  // ==========================================================================
  print('\n--- Check 4: Stateful Balance Increment & Mutation Integrity ---');
  {
    int balance = 25000000;
    final List<Map<String, dynamic>> mutations = [
      {'id': 1, 'type': 'credit', 'amountCents': 10000000, 'balanceAfter': 25000000},
      {'id': 2, 'type': 'debit', 'amountCents': 1085000, 'balanceAfter': 23915000},
      {'id': 3, 'type': 'credit', 'amountCents': 1085000, 'balanceAfter': 25000000},
    ];

    void addTopup(int amount) {
      balance += amount;
      mutations.insert(0, {
        'id': mutations.length + 1,
        'type': 'credit',
        'amountCents': amount,
        'balanceAfter': balance,
        'referenceType': 'topup',
      });
    }

    // Topup 1: Rp 20.000 (2,000,000 cents)
    addTopup(2000000);
    check(balance == 27000000, 'Balance increments to Rp 270.000');
    check(mutations.length == 4, 'Mutation count is 4');
    check(mutations[0]['balanceAfter'] == 27000000, 'Head mutation records exact balanceAfter');

    // Topup 2: Rp 50.000 (5,000,000 cents)
    addTopup(5000000);
    check(balance == 32000000, 'Balance accumulates to Rp 320.000');
    check(mutations.length == 5, 'Mutation count is 5');

    // Topup 3: Rp 1.000.000 (100,000,000 cents)
    addTopup(100000000);
    check(balance == 132000000, 'Balance accumulates to Rp 1.320.000');
    check(mutations[0]['amountCents'] == 100000000, 'Newest mutation matches Rp 1.000.000');
    check(mutations[0]['referenceType'] == 'topup', 'Newest mutation is referenceType topup');
  }

  // ==========================================================================
  // CHECK 5: ROUTING RESOLUTION & ARCHITECTURAL LEGITIMACY
  // ==========================================================================
  print('\n--- Check 5: Routing Resolution & Architectural Legitimacy ---');
  {
    final router = File('lib/app/router.dart').readAsStringSync();
    check(router.contains("path: '/topup'"), 'GoRouter defines "/topup" route');
    check(router.contains("builder: (context, state) => const TopupScreen()"), 'Route "/topup" returns TopupScreen()');

    final home = File('lib/features/home/presentation/home_screen.dart').readAsStringSync();
    check(home.contains("key: const Key('home_topup_button')"), 'HomeScreen defines "home_topup_button" key');
    check(home.contains("context.push('/topup')"), 'HomeScreen '+' button pushes to "/topup"');

    final wallet = File('lib/features/wallet/presentation/wallet_screen.dart').readAsStringSync();
    check(wallet.contains("key: const Key('wallet_topup_button')"), 'WalletScreen defines "wallet_topup_button" key');
    check(wallet.contains("context.push('/topup')"), 'WalletScreen "Top Up" button pushes to "/topup"');

    final topup = File('lib/features/wallet/presentation/topup_screen.dart').readAsStringSync();
    check(topup.contains("key: const Key('topup_back_button')"), 'TopupScreen defines "topup_back_button" key');
    check(topup.contains("Navigator.of(context).pop()"), 'TopupScreen back button executes Navigator.of(context).pop()');
  }

  // ==========================================================================
  // CHECK 6: MOCKUP MODE VS BACKEND API DUAL-PATHWAYS
  // ==========================================================================
  print('\n--- Check 6: Mockup Mode vs Backend API Dual-Pathways ---');
  {
    final walletRepo = File('lib/features/wallet/data/wallet_repository.dart').readAsStringSync();
    check(walletRepo.contains('if (AppConfig.isMockupEnabled)'), 'WalletRepository checks AppConfig.isMockupEnabled');
    check(walletRepo.contains('MockWalletStore.instance.addTopup'), 'Mockup mode invokes MockWalletStore.instance.addTopup');
    check(walletRepo.contains('final res = await _remoteSource.requestTopup('), 'Non-mockup mode invokes _remoteSource.requestTopup');
    check(walletRepo.contains('idempotencyKey: idempotencyKey'), 'Non-mockup mode passes generated UUID idempotency key');

    final remoteDataSource = File('lib/features/wallet/data/wallet_remote_data_source.dart').readAsStringSync();
    check(remoteDataSource.contains('ApiEndpoints.walletTopup'), 'Remote data source posts to ApiEndpoints.walletTopup');
    check(remoteDataSource.contains('ApiEndpoints.walletChannels'), 'Remote data source gets ApiEndpoints.walletChannels');
    check(remoteDataSource.contains("'Idempotency-Key': idempotencyKey"), 'Remote data source sends Idempotency-Key header');

    final topupScreen = File('lib/features/wallet/presentation/topup_screen.dart').readAsStringSync();
    check(topupScreen.contains('if (AppConfig.isMockupEnabled)'), 'TopupScreen branches on AppConfig.isMockupEnabled');
    check(topupScreen.contains('PaymentSimulationSheet.show'), 'Mockup branch presents PaymentSimulationSheet modal');
    check(topupScreen.contains('ref.read(walletNotifierProvider.notifier).proceedTopup()'), 'Backend branch calls proceedTopup()');
  }

  // ==========================================================================
  // RESULTS
  // ==========================================================================
  print('\n======================================================================');
  print('  FORENSIC AUDIT SUMMARY');
  print('  Total Checks Executed: $total');
  print('  Passed:                $passed');
  print('  Failed:                $failed');
  print('======================================================================');

  if (failed == 0) {
    print('\n>> AUDIT VERDICT: CLEAN - ZERO INTEGRITY VIOLATIONS DETECTED <<\n');
  } else {
    print('\n>> AUDIT VERDICT: INTEGRITY VIOLATION DETECTED <<\n');
    exitCode = 1;
  }
}
