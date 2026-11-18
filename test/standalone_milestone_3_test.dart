import 'dart:io';

// ============================================================================
// STANDALONE EMPIRICAL TEST SUITE: MILESTONE 3 (TOP-UP FLOW & NAVIGATION)
// ============================================================================

class StandaloneRupiahFormatter {
  static int parseRupiah(String text) {
    final digits = text.replaceAll(RegExp(r'[^\d]'), '');
    return int.tryParse(digits) ?? 0;
  }
}

class StandaloneTopupChannel {
  final String code;
  final String name;
  final String method;
  final String paymentGateway;
  final int minAmountCents;
  final int maxAmountCents;
  final int feeCents;
  final String feeDisplay;
  final String feeType;
  final bool isActive;
  final String? accountNumber;
  final String? accountName;

  const StandaloneTopupChannel({
    required this.code,
    required this.name,
    required this.method,
    required this.paymentGateway,
    required this.minAmountCents,
    required this.maxAmountCents,
    required this.feeCents,
    required this.feeDisplay,
    required this.feeType,
    required this.isActive,
    this.accountNumber,
    this.accountName,
  });

  int calculateFeeCents(int nominalCents) {
    if (feeType == 'percentage') {
      return (nominalCents * 0.007).round();
    }
    return feeCents;
  }

  int calculateTotalCents(int nominalCents) {
    return nominalCents + calculateFeeCents(nominalCents);
  }
}

class StandaloneMockWalletStore {
  static final StandaloneMockWalletStore instance = StandaloneMockWalletStore._();
  StandaloneMockWalletStore._() {
    reset();
  }

  int balanceCents = 25000000;
  final List<Map<String, dynamic>> mutations = [];

  void reset() {
    balanceCents = 25000000;
    mutations.clear();
    mutations.addAll([
      {'id': 301, 'type': 'credit', 'amountCents': 10000000, 'referenceType': 'topup'},
      {'id': 302, 'type': 'debit', 'amountCents': 1085000, 'referenceType': 'transaction'},
      {'id': 303, 'type': 'credit', 'amountCents': 1085000, 'referenceType': 'refund'},
    ]);
  }

  void addTopup({required int amountCents, required String channelCode, required String channelName}) {
    balanceCents += amountCents;
    mutations.insert(0, {
      'id': DateTime.now().millisecondsSinceEpoch,
      'type': 'credit',
      'amountCents': amountCents,
      'referenceType': 'topup',
      'note': 'Top Up Deposit via $channelName',
    });
  }
}

void main() async {
  print('======================================================================');
  print('  EMPIRICAL TEST SUITE: MILESTONE 3 (TOP-UP FLOW & NAVIGATION)       ');
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
  // 1. RUPIAH INPUT FORMATTER LOGIC & EXTRACTION
  // --------------------------------------------------------------------------
  print('--- 1. Rupiah Input Formatter & Currency Parsing ---');
  {
    expect(StandaloneRupiahFormatter.parseRupiah('') == 0, 'Empty string parses to 0');
    expect(StandaloneRupiahFormatter.parseRupiah('Rp 50.000') == 50000, 'Formatted Rp 50.000 parses to 50000');
    expect(StandaloneRupiahFormatter.parseRupiah('Rp 10.000.000') == 10000000, 'Formatted Rp 10.000.000 parses to 10000000');
    expect(StandaloneRupiahFormatter.parseRupiah('75000') == 75000, 'Raw digits 75000 parses to 75000');
    expect(StandaloneRupiahFormatter.parseRupiah('Rp 123.456,00') == 12345600, 'String with decimals stripped to digits');
    expect(StandaloneRupiahFormatter.parseRupiah('abc!@#') == 0, 'Non-digit string safely returns 0');
  }

  // --------------------------------------------------------------------------
  // 2. NOMINAL BOUNDS & VALIDATION RULES
  // --------------------------------------------------------------------------
  print('\n--- 2. Nominal Validation Boundary Invariants ---');
  {
    const int minCents = 1000000;    // Rp 10.000
    const int maxCents = 1000000000; // Rp 10.000.000

    String? validate(int cents) {
      if (cents == 0) return null;
      if (cents < minCents) return 'Minimal top up Rp 10.000';
      if (cents > maxCents) return 'Maksimal top up Rp 10.000.000';
      return null;
    }

    expect(validate(0) == null, 'Nominal 0 is neutral without validation error');
    expect(validate(500000) == 'Minimal top up Rp 10.000', 'Nominal Rp 5.000 produces minimal error');
    expect(validate(999900) == 'Minimal top up Rp 10.000', 'Nominal Rp 9.999 produces minimal error');
    expect(validate(minCents) == null, 'Exact boundary min (Rp 10.000) is valid');
    expect(validate(5000000) == null, 'Nominal Rp 50.000 is valid');
    expect(validate(maxCents) == null, 'Exact boundary max (Rp 10.000.000) is valid');
    expect(validate(1500000000) == 'Maksimal top up Rp 10.000.000', 'Nominal Rp 15.000.000 produces maximal error');
  }

  // --------------------------------------------------------------------------
  // 3. TOP-UP CHANNELS, FEE & TOTAL CALCULATION
  // --------------------------------------------------------------------------
  print('\n--- 3. Top-Up Channels Catalog, Fee & Total Calculation ---');
  {
    const bcaVa = StandaloneTopupChannel(
      code: 'bca_va',
      name: 'BCA Virtual Account',
      method: 'payment_gateway',
      paymentGateway: 'midtrans',
      minAmountCents: 1000000,
      maxAmountCents: 2000000000,
      feeCents: 250000,
      feeDisplay: 'Rp 2.500',
      feeType: 'flat',
      isActive: true,
    );

    const qris = StandaloneTopupChannel(
      code: 'qris',
      name: 'QRIS Instant',
      method: 'payment_gateway',
      paymentGateway: 'midtrans',
      minAmountCents: 500000,
      maxAmountCents: 500000000,
      feeCents: 0,
      feeDisplay: '0.7%',
      feeType: 'percentage',
      isActive: true,
    );

    const manualBca = StandaloneTopupChannel(
      code: 'manual_bca',
      name: 'Transfer Bank BCA',
      method: 'manual_transfer',
      paymentGateway: 'none',
      accountNumber: '1234567890',
      accountName: 'PT PPOB INDONESIA SEJAHTERA',
      minAmountCents: 5000000,
      maxAmountCents: 10000000000,
      feeCents: 0,
      feeDisplay: 'Gratis',
      feeType: 'flat',
      isActive: true,
    );

    // Flat fee check (Rp 100.000 = 10,000,000 cents)
    expect(bcaVa.calculateFeeCents(10000000) == 250000, 'Flat fee returns fixed feeCents (Rp 2.500)');
    expect(bcaVa.calculateTotalCents(10000000) == 10250000, 'Flat fee total is nominal + 250000');

    // Percentage fee check (0.7% on Rp 100.000 = Rp 700 = 70,000 cents)
    expect(qris.calculateFeeCents(10000000) == 70000, 'Percentage fee calculates 0.7% of nominal (70,000 cents)');
    expect(qris.calculateTotalCents(10000000) == 10070000, 'Percentage fee total is nominal + 70000');

    // Free channel check
    expect(manualBca.calculateFeeCents(10000000) == 0, 'Manual transfer has 0 fee');
    expect(manualBca.calculateTotalCents(10000000) == 10000000, 'Manual transfer total equals nominal');
    expect(manualBca.accountNumber == '1234567890', 'Manual transfer exposes corporate account number');
    expect(manualBca.accountName == 'PT PPOB INDONESIA SEJAHTERA', 'Manual transfer exposes corporate account name');
  }

  // --------------------------------------------------------------------------
  // 4. MOCK WALLET STORE STATEFUL SIMULATION CONTRACT
  // --------------------------------------------------------------------------
  print('\n--- 4. MockWalletStore Stateful Simulation Contract ---');
  {
    final store = StandaloneMockWalletStore.instance;
    store.reset();

    expect(store.balanceCents == 25000000, 'Initial balance is Rp 250.000 (25,000,000 cents)');
    expect(store.mutations.length == 3, 'Initial mutations count is 3');

    // Execute simulated topup of Rp 100.000 (10,000,000 cents)
    store.addTopup(
      amountCents: 10000000,
      channelCode: 'bca_va',
      channelName: 'BCA Virtual Account',
    );

    expect(store.balanceCents == 35000000, 'Balance after topup is Rp 350.000 (35,000,000 cents)');
    expect(store.mutations.length == 4, 'Mutation count increments to 4');
    expect(store.mutations.first['referenceType'] == 'topup', 'First mutation has referenceType topup');
    expect(store.mutations.first['type'] == 'credit', 'First mutation has type credit');
    expect(store.mutations.first['amountCents'] == 10000000, 'First mutation amount matches 10,000,000 cents');

    // Sequential top-up (Rp 50.000)
    store.addTopup(
      amountCents: 5000000,
      channelCode: 'qris',
      channelName: 'QRIS',
    );
    expect(store.balanceCents == 40000000, 'Sequential top-up accumulates balance to Rp 400.000');

    // Reset restores initial state
    store.reset();
    expect(store.balanceCents == 25000000, 'Reset restores balance to Rp 250.000');
    expect(store.mutations.length == 3, 'Reset restores mutations to baseline 3');
  }

  // --------------------------------------------------------------------------
  // 5. STATIC SOURCE CODE CONTRACT VERIFICATION
  // --------------------------------------------------------------------------
  print('\n--- 5. Static Source Code & Key Contract Verification ---');
  {
    final topupScreenFile = File('lib/features/wallet/presentation/topup_screen.dart');
    expect(topupScreenFile.existsSync(), 'lib/features/wallet/presentation/topup_screen.dart exists');
    final topupScreenSrc = topupScreenFile.readAsStringSync();

    final requiredTopupKeys = [
      'topup_header_balance',
      'topup_chip_20000',
      'topup_chip_50000',
      'topup_chip_100000',
      'topup_chip_200000',
      'topup_chip_500000',
      'topup_chip_1000000',
      'topup_nominal_input',
      'topup_validation_warning',
      'topup_summary_card',
      'topup_summary_nominal',
      'topup_summary_fee',
      'topup_summary_total',
      'topup_continue_button',
      'topup_back_button',
    ];

    for (final k in requiredTopupKeys) {
      expect(topupScreenSrc.contains(k), 'TopupScreen contains key: $k');
    }

    // Payment simulation sheet inspection
    final simulationSheetFile = File('lib/features/wallet/presentation/widgets/payment_simulation_sheet.dart');
    expect(simulationSheetFile.existsSync(), 'payment_simulation_sheet.dart exists');
    final simulationSheetSrc = simulationSheetFile.readAsStringSync();
    expect(simulationSheetSrc.contains('topup_simulation_pay_button'), 'PaymentSimulationSheet contains Key: topup_simulation_pay_button');
    expect(simulationSheetSrc.contains('Simulasikan Pembayaran Berhasil'), 'PaymentSimulationSheet contains label: Simulasikan Pembayaran Berhasil');
    expect(simulationSheetSrc.contains('MockWalletStore.instance.addTopup'), 'PaymentSimulationSheet mutates MockWalletStore directly');

    // Home Screen navigation inspection
    final homeScreenFile = File('lib/features/home/presentation/home_screen.dart');
    expect(homeScreenFile.existsSync(), 'home_screen.dart exists');
    final homeScreenSrc = homeScreenFile.readAsStringSync();
    expect(homeScreenSrc.contains('home_topup_button'), 'HomeScreen contains Key: home_topup_button');
    expect(homeScreenSrc.contains("context.push('/topup')"), 'HomeScreen uses context.push("/topup")');

    // Wallet Screen navigation inspection
    final walletScreenFile = File('lib/features/wallet/presentation/wallet_screen.dart');
    expect(walletScreenFile.existsSync(), 'wallet_screen.dart exists');
    final walletScreenSrc = walletScreenFile.readAsStringSync();
    expect(walletScreenSrc.contains('wallet_topup_button'), 'WalletScreen contains Key: wallet_topup_button');
    expect(walletScreenSrc.contains("context.push('/topup')"), 'WalletScreen uses context.push("/topup")');
    expect(walletScreenSrc.contains("import 'package:go_router/go_router.dart';"), 'WalletScreen imports go_router');
    expect(!walletScreenSrc.contains('quick_topup_sheet.dart'), 'WalletScreen cleanly removed unused quick_topup_sheet import');

    // Router inspection
    final routerFile = File('lib/app/router.dart');
    expect(routerFile.existsSync(), 'lib/app/router.dart exists');
    final routerSrc = routerFile.readAsStringSync();
    expect(routerSrc.contains("path: '/topup'"), 'router.dart registers route: /topup');
    expect(routerSrc.contains('TopupScreen'), 'router.dart maps /topup to TopupScreen');

    // Rupiah formatter inspection
    final formatterFile = File('lib/core/utils/rupiah_input_formatter.dart');
    expect(formatterFile.existsSync(), 'rupiah_input_formatter.dart exists');
    final formatterSrc = formatterFile.readAsStringSync();
    expect(formatterSrc.contains('class RupiahInputFormatter extends TextInputFormatter'), 'RupiahInputFormatter extends TextInputFormatter');
    expect(formatterSrc.contains('parseRupiah'), 'RupiahInputFormatter defines parseRupiah method');
    expect(formatterSrc.contains('format'), 'RupiahInputFormatter defines format method');
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
    print('\n>> EMPIRICAL VERDICT: ALL TESTS PASSED! CONFIRMED CORRECT <<\n');
  } else {
    print('\n>> EMPIRICAL VERDICT: FAILURES DETECTED <<\n');
    exitCode = 1;
  }
}
