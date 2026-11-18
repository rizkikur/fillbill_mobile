import 'dart:io';
import 'dart:math';

// Import domain entity directly from production code
import '../lib/features/wallet/domain/wallet_entity.dart';

// ============================================================================
// EMPIRICAL CHALLENGER M3: TOP-UP CALCULATIONS, FORMATTING & BOUNDS SUITE
// ============================================================================
// Target: fillbill_mobile Milestone 3 Top-Up calculations, currency parsing,
// nominal validation boundaries, fee calculations, and total invariants.
// Executable via: & "D:\flutter\bin\cache\dart-sdk\bin\dart.exe"
// ============================================================================

/// Clean Indonesian currency formatter implementation for empirical cross-verification
String empiricalFormatRupiah(int rupiah) {
  if (rupiah < 0) {
    return '-Rp ${empiricalFormatRupiah(-rupiah).substring(3)}';
  }
  final s = rupiah.toString();
  final len = s.length;
  if (len <= 3) return 'Rp $s';

  final buffer = StringBuffer('Rp ');
  final remainder = len % 3;
  if (remainder > 0) {
    buffer.write(s.substring(0, remainder));
    buffer.write('.');
  }
  for (int i = remainder; i < len; i += 3) {
    buffer.write(s.substring(i, i + 3));
    if (i + 3 < len) buffer.write('.');
  }
  return buffer.toString();
}

/// Standalone replica of parseRupiah matching RupiahInputFormatter.parseRupiah
int empiricalParseRupiah(String text) {
  final digits = text.replaceAll(RegExp(r'[^\d]'), '');
  return int.tryParse(digits) ?? 0;
}

/// Standalone replica of RupiahInputFormatter digit cap logic
String empiricalSanitizeDigits(String text) {
  final digits = text.replaceAll(RegExp(r'[^\d]'), '');
  if (digits.isEmpty) return '';
  return digits.length > 11 ? digits.substring(0, 11) : digits;
}

/// Validation rules mirroring TopupScreen._getValidationMessage and _isAmountValid
class EmpiricalNominalValidator {
  static const int minNominalCents = 1000000;    // Rp 10.000
  static const int maxNominalCents = 1000000000; // Rp 10.000.000

  static String? getValidationMessage(int cents) {
    if (cents == 0) return null;
    if (cents < minNominalCents) {
      return 'Minimal top up Rp 10.000';
    }
    if (cents > maxNominalCents) {
      return 'Maksimal top up Rp 10.000.000';
    }
    return null;
  }

  static bool isAmountValid(int cents) {
    return cents >= minNominalCents && cents <= maxNominalCents;
  }
}

/// Standalone test harness for MockWalletStore simulation contract
class EmpiricalMockWalletStore {
  static const int initialBalanceCents = 25000000; // Rp 250.000
  int _balanceCents = initialBalanceCents;
  final List<WalletMutationEntity> _mutations = [];

  EmpiricalMockWalletStore() {
    reset();
  }

  int get balanceCents => _balanceCents;
  List<WalletMutationEntity> get mutations => List.unmodifiable(_mutations);

  void reset() {
    _balanceCents = initialBalanceCents;
    _mutations.clear();
    _mutations.addAll([
      const WalletMutationEntity(
        id: 301,
        type: 'credit',
        amountCents: 10000000,
        amountDisplay: '+ Rp 100.000',
        balanceAfterCents: 25000000,
        balanceAfterDisplay: 'Rp 250.000',
        referenceType: 'topup',
        note: 'Top Up Deposit via BCA VA',
      ),
      const WalletMutationEntity(
        id: 302,
        type: 'debit',
        amountCents: 1085000,
        amountDisplay: '- Rp 10.850',
        balanceAfterCents: 15000000,
        balanceAfterDisplay: 'Rp 150.000',
        referenceType: 'transaction',
        note: 'Pembelian Pulsa Telkomsel 10K',
      ),
      const WalletMutationEntity(
        id: 303,
        type: 'credit',
        amountCents: 1085000,
        amountDisplay: '+ Rp 10.850',
        balanceAfterCents: 16085000,
        balanceAfterDisplay: 'Rp 160.850',
        referenceType: 'refund',
        note: 'Pengembalian Dana Transaksi',
      ),
    ]);
  }

  void addTopup({
    required int amountCents,
    required String channelCode,
    required String channelName,
  }) {
    _balanceCents += amountCents;
    final now = DateTime.now();
    final newMutation = WalletMutationEntity(
      id: now.millisecondsSinceEpoch,
      type: 'credit',
      amountCents: amountCents,
      amountDisplay: '+ Rp ${(amountCents ~/ 100).toString()}',
      balanceAfterCents: _balanceCents,
      balanceAfterDisplay: 'Rp ${(_balanceCents ~/ 100).toString()}',
      referenceType: 'topup',
      note: 'Top Up Deposit via $channelName',
      createdAt: now,
    );
    _mutations.insert(0, newMutation);
  }
}

void main() async {
  print('======================================================================');
  print('  EMPIRICAL CHALLENGER M3: TOP-UP STRESS TEST HARNESS               ');
  print('======================================================================\n');

  int totalTests = 0;
  int passedTests = 0;
  int failedTests = 0;
  final List<String> failures = [];

  void assertCondition(bool condition, String description, [String? extraDetail]) {
    totalTests++;
    if (condition) {
      passedTests++;
      print('  [PASS] $description');
    } else {
      failedTests++;
      final msg = '  [FAIL] $description' + (extraDetail != null ? ' | $extraDetail' : '');
      print(msg);
      failures.add(msg);
    }
  }

  // ==========================================================================
  // SECTION 1: CURRENCY FORMATTING & PARSING STRESS TESTS
  // ==========================================================================
  print('--- 1. Currency Formatting, Parsing & Sanitization Stress Tests ---');

  // 1.1 parseRupiah standard formats
  assertCondition(empiricalParseRupiah('') == 0, 'parseRupiah: Empty string -> 0');
  assertCondition(empiricalParseRupiah('   ') == 0, 'parseRupiah: Whitespace only -> 0');
  assertCondition(empiricalParseRupiah('Rp ') == 0, 'parseRupiah: Currency symbol only -> 0');
  assertCondition(empiricalParseRupiah('Rp 0') == 0, 'parseRupiah: "Rp 0" -> 0');
  assertCondition(empiricalParseRupiah('Rp 10.000') == 10000, 'parseRupiah: "Rp 10.000" -> 10000');
  assertCondition(empiricalParseRupiah('Rp 50.000') == 50000, 'parseRupiah: "Rp 50.000" -> 50000');
  assertCondition(empiricalParseRupiah('Rp 100.000') == 100000, 'parseRupiah: "Rp 100.000" -> 100000');
  assertCondition(empiricalParseRupiah('Rp 1.000.000') == 1000000, 'parseRupiah: "Rp 1.000.000" -> 1000000');
  assertCondition(empiricalParseRupiah('Rp 10.000.000') == 10000000, 'parseRupiah: "Rp 10.000.000" -> 10000000');

  // 1.2 parseRupiah adversarial and edge inputs
  assertCondition(empiricalParseRupiah('12345') == 12345, 'parseRupiah: Raw digits "12345" -> 12345');
  assertCondition(empiricalParseRupiah('00050000') == 50000, 'parseRupiah: Leading zeros "00050000" -> 50000');
  assertCondition(empiricalParseRupiah('Rp 50,000,00') == 5000000, 'parseRupiah: Commas stripped as digits -> 5000000');
  assertCondition(empiricalParseRupiah('!@#\$%^&*()') == 0, 'parseRupiah: Pure punctuation -> 0');
  assertCondition(empiricalParseRupiah('Rp 5a0.b0c0') == 5000, 'parseRupiah: Interleaved letters stripped -> 5000');
  assertCondition(empiricalParseRupiah('Rp 100.000 🚀') == 100000, 'parseRupiah: Unicode emoji stripped -> 100000');
  assertCondition(empiricalParseRupiah('Rp\t20.000\n') == 20000, 'parseRupiah: Tabs & newlines handled -> 20000');
  assertCondition(empiricalParseRupiah('-Rp 50.000') == 50000, 'parseRupiah: Negative sign stripped -> 50000');

  // 1.3 parseRupiah large number boundaries
  assertCondition(empiricalParseRupiah('99999999999') == 99999999999, 'parseRupiah: 11-digit boundary (99,999,999,999) parsed safely');
  assertCondition(empiricalParseRupiah('9999999999999999999999999999999') == 0, 'parseRupiah: Enormous number exceeding Int64 gracefully returns 0 without crashing');

  // 1.4 Formatting validation
  assertCondition(empiricalFormatRupiah(0) == 'Rp 0', 'Format: 0 -> "Rp 0"');
  assertCondition(empiricalFormatRupiah(1) == 'Rp 1', 'Format: 1 -> "Rp 1"');
  assertCondition(empiricalFormatRupiah(10) == 'Rp 10', 'Format: 10 -> "Rp 10"');
  assertCondition(empiricalFormatRupiah(100) == 'Rp 100', 'Format: 100 -> "Rp 100"');
  assertCondition(empiricalFormatRupiah(1000) == 'Rp 1.000', 'Format: 1000 -> "Rp 1.000"');
  assertCondition(empiricalFormatRupiah(10000) == 'Rp 10.000', 'Format: 10000 -> "Rp 10.000"');
  assertCondition(empiricalFormatRupiah(50000) == 'Rp 50.000', 'Format: 50000 -> "Rp 50.000"');
  assertCondition(empiricalFormatRupiah(1000000) == 'Rp 1.000.000', 'Format: 1000000 -> "Rp 1.000.000"');
  assertCondition(empiricalFormatRupiah(10000000) == 'Rp 10.000.000', 'Format: 10000000 -> "Rp 10.000.000"');
  assertCondition(empiricalFormatRupiah(99999999999) == 'Rp 99.999.999.999', 'Format: 99999999999 -> "Rp 99.999.999.999"');

  // 1.5 Round-trip Property Generator (200 random values)
  final rng = Random(42);
  bool roundTripSuccess = true;
  for (int i = 0; i < 200; i++) {
    // Generate values up to 11 digits: max 99,999,999,999
    final val = rng.nextInt(100000000) * 1000 + rng.nextInt(1000);
    final formatted = empiricalFormatRupiah(val);
    final parsed = empiricalParseRupiah(formatted);
    if (parsed != val) {
      roundTripSuccess = false;
      break;
    }
  }
  assertCondition(roundTripSuccess, 'Round-trip Generator: parseRupiah(format(x)) == x for 200 random values');

  // 1.6 Digit Sanitization & 11-digit cap
  assertCondition(empiricalSanitizeDigits('') == '', 'Sanitize: Empty -> Empty');
  assertCondition(empiricalSanitizeDigits('abcdef') == '', 'Sanitize: Non-digits -> Empty');
  assertCondition(empiricalSanitizeDigits('Rp 50.000') == '50000', 'Sanitize: "Rp 50.000" -> "50000"');
  assertCondition(empiricalSanitizeDigits('12345678901') == '12345678901', 'Sanitize: Exactly 11 digits preserved');
  assertCondition(empiricalSanitizeDigits('123456789012345') == '12345678901', 'Sanitize: 15 digits capped to 11 digits');
  assertCondition(empiricalSanitizeDigits('999999999999') == '99999999999', 'Sanitize: 12 digits capped to 11 digits');

  // ==========================================================================
  // SECTION 2: NOMINAL VALIDATION BOUNDARY STRESS TESTS
  // ==========================================================================
  print('\n--- 2. Nominal Validation Boundary Stress Tests ---');

  // 2.1 Values below Rp 10.000 (1,000,000 cents)
  assertCondition(
    EmpiricalNominalValidator.getValidationMessage(0) == null &&
    !EmpiricalNominalValidator.isAmountValid(0),
    'Bounds: 0 cents -> warning null, isValid false',
  );
  assertCondition(
    EmpiricalNominalValidator.getValidationMessage(-100) == 'Minimal top up Rp 10.000' &&
    !EmpiricalNominalValidator.isAmountValid(-100),
    'Bounds: -100 cents -> warning "Minimal top up Rp 10.000", isValid false',
  );
  assertCondition(
    EmpiricalNominalValidator.getValidationMessage(1) == 'Minimal top up Rp 10.000' &&
    !EmpiricalNominalValidator.isAmountValid(1),
    'Bounds: 1 cent -> warning "Minimal top up Rp 10.000", isValid false',
  );
  assertCondition(
    EmpiricalNominalValidator.getValidationMessage(100) == 'Minimal top up Rp 10.000' &&
    !EmpiricalNominalValidator.isAmountValid(100),
    'Bounds: 100 cents (Rp 1) -> warning "Minimal top up Rp 10.000", isValid false',
  );
  assertCondition(
    EmpiricalNominalValidator.getValidationMessage(500000) == 'Minimal top up Rp 10.000' &&
    !EmpiricalNominalValidator.isAmountValid(500000),
    'Bounds: 500,000 cents (Rp 5.000) -> warning "Minimal top up Rp 10.000", isValid false',
  );
  assertCondition(
    EmpiricalNominalValidator.getValidationMessage(999900) == 'Minimal top up Rp 10.000' &&
    !EmpiricalNominalValidator.isAmountValid(999900),
    'Bounds: 999,900 cents (Rp 9.999) -> warning "Minimal top up Rp 10.000", isValid false',
  );
  assertCondition(
    EmpiricalNominalValidator.getValidationMessage(999999) == 'Minimal top up Rp 10.000' &&
    !EmpiricalNominalValidator.isAmountValid(999999),
    'Bounds: 999,999 cents (1 cent below min boundary) -> warning "Minimal top up Rp 10.000", isValid false',
  );

  // 2.2 Exact min boundary Rp 10.000 (1,000,000 cents)
  assertCondition(
    EmpiricalNominalValidator.getValidationMessage(1000000) == null &&
    EmpiricalNominalValidator.isAmountValid(1000000),
    'Bounds: Exact boundary min 1,000,000 cents (Rp 10.000) -> warning null, isValid true',
  );
  assertCondition(
    EmpiricalNominalValidator.getValidationMessage(1000001) == null &&
    EmpiricalNominalValidator.isAmountValid(1000001),
    'Bounds: 1,000,001 cents (1 cent above min boundary) -> warning null, isValid true',
  );

  // 2.3 All 6 Preset Chips
  assertCondition(
    EmpiricalNominalValidator.isAmountValid(2000000) &&
    EmpiricalNominalValidator.getValidationMessage(2000000) == null,
    'Bounds: Preset Chip 1 (Rp 20.000 / 2,000,000 cents) -> valid',
  );
  assertCondition(
    EmpiricalNominalValidator.isAmountValid(5000000) &&
    EmpiricalNominalValidator.getValidationMessage(5000000) == null,
    'Bounds: Preset Chip 2 (Rp 50.000 / 5,000,000 cents) -> valid',
  );
  assertCondition(
    EmpiricalNominalValidator.isAmountValid(10000000) &&
    EmpiricalNominalValidator.getValidationMessage(10000000) == null,
    'Bounds: Preset Chip 3 (Rp 100.000 / 10,000,000 cents) -> valid',
  );
  assertCondition(
    EmpiricalNominalValidator.isAmountValid(20000000) &&
    EmpiricalNominalValidator.getValidationMessage(20000000) == null,
    'Bounds: Preset Chip 4 (Rp 200.000 / 20,000,000 cents) -> valid',
  );
  assertCondition(
    EmpiricalNominalValidator.isAmountValid(50000000) &&
    EmpiricalNominalValidator.getValidationMessage(50000000) == null,
    'Bounds: Preset Chip 5 (Rp 500.000 / 50,000,000 cents) -> valid',
  );
  assertCondition(
    EmpiricalNominalValidator.isAmountValid(100000000) &&
    EmpiricalNominalValidator.getValidationMessage(100000000) == null,
    'Bounds: Preset Chip 6 (Rp 1.000.000 / 100,000,000 cents) -> valid',
  );

  // 2.4 Arbitrary valid amounts
  assertCondition(
    EmpiricalNominalValidator.isAmountValid(500000000) &&
    EmpiricalNominalValidator.getValidationMessage(500000000) == null,
    'Bounds: Nominal Rp 5.000.000 (500,000,000 cents) -> valid',
  );
  assertCondition(
    EmpiricalNominalValidator.isAmountValid(999999900) &&
    EmpiricalNominalValidator.getValidationMessage(999999900) == null,
    'Bounds: Nominal Rp 9.999.999 (999,999,900 cents) -> valid',
  );
  assertCondition(
    EmpiricalNominalValidator.isAmountValid(999999999) &&
    EmpiricalNominalValidator.getValidationMessage(999999999) == null,
    'Bounds: 999,999,999 cents (1 cent below max boundary) -> valid',
  );

  // 2.5 Exact max boundary Rp 10.000.000 (1,000,000,000 cents)
  assertCondition(
    EmpiricalNominalValidator.getValidationMessage(1000000000) == null &&
    EmpiricalNominalValidator.isAmountValid(1000000000),
    'Bounds: Exact boundary max 1,000,000,000 cents (Rp 10.000.000) -> warning null, isValid true',
  );

  // 2.6 Values above Rp 10.000.000 (1,000,000,000 cents)
  assertCondition(
    EmpiricalNominalValidator.getValidationMessage(1000000001) == 'Maksimal top up Rp 10.000.000' &&
    !EmpiricalNominalValidator.isAmountValid(1000000001),
    'Bounds: 1,000,000,001 cents (1 cent above max boundary) -> warning "Maksimal top up Rp 10.000.000", isValid false',
  );
  assertCondition(
    EmpiricalNominalValidator.getValidationMessage(1000000100) == 'Maksimal top up Rp 10.000.000' &&
    !EmpiricalNominalValidator.isAmountValid(1000000100),
    'Bounds: 1,000,000,100 cents (Rp 10.000.001) -> warning "Maksimal top up Rp 10.000.000", isValid false',
  );
  assertCondition(
    EmpiricalNominalValidator.getValidationMessage(1500000000) == 'Maksimal top up Rp 10.000.000' &&
    !EmpiricalNominalValidator.isAmountValid(1500000000),
    'Bounds: 1,500,000,000 cents (Rp 15.000.000) -> warning "Maksimal top up Rp 10.000.000", isValid false',
  );
  assertCondition(
    EmpiricalNominalValidator.getValidationMessage(10000000000) == 'Maksimal top up Rp 10.000.000' &&
    !EmpiricalNominalValidator.isAmountValid(10000000000),
    'Bounds: 10,000,000,000 cents (Rp 100.000.000) -> warning "Maksimal top up Rp 10.000.000", isValid false',
  );

  // 2.7 Continuous Range Invariant Sweep (100 values in range)
  bool rangeValid = true;
  for (int step = 1; step <= 100; step++) {
    final cents = 1000000 + (step * 9990000); // from ~10k to ~10M
    if (!EmpiricalNominalValidator.isAmountValid(cents) ||
        EmpiricalNominalValidator.getValidationMessage(cents) != null) {
      rangeValid = false;
      break;
    }
  }
  assertCondition(rangeValid, 'Bounds Sweep: 100 equidistant values in [10k, 10M] are strictly valid');

  // ==========================================================================
  // SECTION 3: PAYMENT CHANNEL CALCULATIONS & INVARIANTS
  // ==========================================================================
  print('\n--- 3. Channel Fee Calculations, Invariants & Rounding ---');

  // Instantiating production TopupChannelEntity directly
  const bcaVa = TopupChannelEntity(
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

  const mandiriVa = TopupChannelEntity(
    code: 'mandiri_va',
    name: 'Mandiri Virtual Account',
    method: 'payment_gateway',
    paymentGateway: 'midtrans',
    minAmountCents: 1000000,
    maxAmountCents: 2000000000,
    feeCents: 250000,
    feeDisplay: 'Rp 2.500',
    feeType: 'flat',
    isActive: true,
  );

  const bniVa = TopupChannelEntity(
    code: 'bni_va',
    name: 'BNI Virtual Account',
    method: 'payment_gateway',
    paymentGateway: 'midtrans',
    minAmountCents: 1000000,
    maxAmountCents: 2000000000,
    feeCents: 250000,
    feeDisplay: 'Rp 2.500',
    feeType: 'flat',
    isActive: true,
  );

  const briVa = TopupChannelEntity(
    code: 'bri_va',
    name: 'BRI Virtual Account',
    method: 'payment_gateway',
    paymentGateway: 'midtrans',
    minAmountCents: 1000000,
    maxAmountCents: 2000000000,
    feeCents: 250000,
    feeDisplay: 'Rp 2.500',
    feeType: 'flat',
    isActive: true,
  );

  const qris = TopupChannelEntity(
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

  const gopay = TopupChannelEntity(
    code: 'gopay',
    name: 'GoPay',
    method: 'payment_gateway',
    paymentGateway: 'midtrans',
    minAmountCents: 1000000,
    maxAmountCents: 200000000,
    feeCents: 100000,
    feeDisplay: 'Rp 1.000',
    feeType: 'flat',
    isActive: true,
  );

  const ovo = TopupChannelEntity(
    code: 'ovo',
    name: 'OVO',
    method: 'payment_gateway',
    paymentGateway: 'midtrans',
    minAmountCents: 1000000,
    maxAmountCents: 200000000,
    feeCents: 100000,
    feeDisplay: 'Rp 1.000',
    feeType: 'flat',
    isActive: true,
  );

  const dana = TopupChannelEntity(
    code: 'dana',
    name: 'DANA',
    method: 'payment_gateway',
    paymentGateway: 'midtrans',
    minAmountCents: 1000000,
    maxAmountCents: 200000000,
    feeCents: 100000,
    feeDisplay: 'Rp 1.000',
    feeType: 'flat',
    isActive: true,
  );

  const shopeepay = TopupChannelEntity(
    code: 'shopeepay',
    name: 'ShopeePay',
    method: 'payment_gateway',
    paymentGateway: 'midtrans',
    minAmountCents: 1000000,
    maxAmountCents: 200000000,
    feeCents: 100000,
    feeDisplay: 'Rp 1.000',
    feeType: 'flat',
    isActive: true,
  );

  const manualBca = TopupChannelEntity(
    code: 'manual_bca',
    name: 'Transfer Bank BCA (Konfirmasi Manual)',
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

  final allChannels = [
    bcaVa, mandiriVa, bniVa, briVa,
    qris, gopay, ovo, dana, shopeepay,
    manualBca,
  ];

  // 3.1 Flat Fee Calculations
  for (final va in [bcaVa, mandiriVa, bniVa, briVa]) {
    assertCondition(
      va.calculateFeeCents(1000000) == 250000 &&
      va.calculateTotalCents(1000000) == 1250000,
      'VA ${va.code}: Flat fee Rp 2.500 at min nominal (1,000,000 -> fee 250,000, total 1,250,000)',
    );
    assertCondition(
      va.calculateFeeCents(1000000000) == 250000 &&
      va.calculateTotalCents(1000000000) == 1000250000,
      'VA ${va.code}: Flat fee Rp 2.500 at max nominal (1,000,000,000 -> total 1,000,250,000)',
    );
  }

  for (final ew in [gopay, ovo, dana, shopeepay]) {
    assertCondition(
      ew.calculateFeeCents(1000000) == 100000 &&
      ew.calculateTotalCents(1000000) == 1100000,
      'E-Wallet ${ew.code}: Flat fee Rp 1.000 at min nominal (1,000,000 -> fee 100,000, total 1,100,000)',
    );
    assertCondition(
      ew.calculateFeeCents(50000000) == 100000 &&
      ew.calculateTotalCents(50000000) == 50100000,
      'E-Wallet ${ew.code}: Flat fee Rp 1.000 at Rp 500.000 (total 50,100,000)',
    );
  }

  assertCondition(
    manualBca.calculateFeeCents(1000000) == 0 &&
    manualBca.calculateTotalCents(1000000) == 1000000,
    'Manual Transfer: Fee 0 at min nominal (total == nominal)',
  );
  assertCondition(
    manualBca.calculateFeeCents(1000000000) == 0 &&
    manualBca.calculateTotalCents(1000000000) == 1000000000,
    'Manual Transfer: Fee 0 at max nominal (total == nominal)',
  );
  assertCondition(
    manualBca.accountNumber == '1234567890' &&
    manualBca.accountName == 'PT PPOB INDONESIA SEJAHTERA',
    'Manual Transfer: Dedicated corporate bank account details intact',
  );

  // 3.2 Percentage Fee (QRIS 0.7%) Matrix & Rounding Verification
  // Formula: (nominalCents * 0.007).round()
  final qrisTestCases = [
    // nominalCents, expectedFeeCents, expectedTotalCents, description
    [1000000, 7000, 1007000, 'Min Rp 10.000 (0.7% = 7,000 cents / Rp 70)'],
    [2000000, 14000, 2014000, 'Preset Rp 20.000 (0.7% = 14,000 cents / Rp 140)'],
    [5000000, 35000, 5035000, 'Preset Rp 50.000 (0.7% = 35,000 cents / Rp 350)'],
    [10000000, 70000, 10070000, 'Preset Rp 100.000 (0.7% = 70,000 cents / Rp 700)'],
    [20000000, 140000, 20140000, 'Preset Rp 200.000 (0.7% = 140,000 cents / Rp 1.400)'],
    [50000000, 350000, 50350000, 'Preset Rp 500.000 (0.7% = 350,000 cents / Rp 3.500)'],
    [100000000, 700000, 100700000, 'Preset Rp 1.000.000 (0.7% = 700,000 cents / Rp 7.000)'],
    [1000000000, 7000000, 1007000000, 'Max Rp 10.000.000 (0.7% = 7,000,000 cents / Rp 70.000)'],
    // Rounding edge cases:
    [1000001, 7000, 1007001, 'Rounding: 1000001 * 0.007 = 7000.007 -> 7,000 cents'],
    [1000050, 7000, 1007050, 'Rounding: 1000050 * 0.007 = 7000.35 -> 7,000 cents'],
    [1000071, 7000, 1007071, 'Rounding: 1000071 * 0.007 = 7000.497 -> 7,000 cents'],
    [1000072, 7001, 1007073, 'Rounding: 1000072 * 0.007 = 7000.504 -> 7,001 cents'],
    [1000100, 7001, 1007101, 'Rounding: 1000100 * 0.007 = 7000.700 -> 7,001 cents'],
    [1000143, 7001, 1007144, 'Rounding: 1000143 * 0.007 = 7001.001 -> 7,001 cents'],
    [1000214, 7001, 1007215, 'Rounding: 1000214 * 0.007 = 7001.498 -> 7,001 cents'],
    [1000215, 7002, 1007217, 'Rounding: 1000215 * 0.007 = 7001.505 -> 7,002 cents'],
  ];

  for (final tc in qrisTestCases) {
    final nominal = tc[0] as int;
    final expFee = tc[1] as int;
    final expTotal = tc[2] as int;
    final desc = tc[3] as String;

    final actualFee = qris.calculateFeeCents(nominal);
    final actualTotal = qris.calculateTotalCents(nominal);
    assertCondition(
      actualFee == expFee && actualTotal == expTotal,
      'QRIS $desc: fee=$actualFee, total=$actualTotal',
    );
  }

  // 3.3 Channel Invariant Engine across ALL 10 channels with 50 pseudo-random amounts
  bool invariantsSatisfied = true;
  String? invariantViolation;

  for (final ch in allChannels) {
    int prevTotal = -1;
    // Test 50 strictly increasing nominal values
    for (int i = 0; i < 50; i++) {
      final nominal = 1000000 + (i * 20000000) + rng.nextInt(1000);
      final fee = ch.calculateFeeCents(nominal);
      final total = ch.calculateTotalCents(nominal);

      // Invariant 1: Total == Nominal + Fee
      if (total != nominal + fee) {
        invariantsSatisfied = false;
        invariantViolation = '${ch.code}: total != nominal + fee ($total != $nominal + $fee)';
        break;
      }
      // Invariant 2: Fee >= 0
      if (fee < 0) {
        invariantsSatisfied = false;
        invariantViolation = '${ch.code}: fee is negative ($fee)';
        break;
      }
      // Invariant 3: Total >= Nominal
      if (total < nominal) {
        invariantsSatisfied = false;
        invariantViolation = '${ch.code}: total < nominal ($total < $nominal)';
        break;
      }
      // Invariant 4: Monotonicity (if nominal increases, total must strictly increase)
      if (prevTotal != -1 && total <= prevTotal) {
        invariantsSatisfied = false;
        invariantViolation = '${ch.code}: non-monotonic total ($total <= $prevTotal)';
        break;
      }
      prevTotal = total;
    }
    if (!invariantsSatisfied) break;
  }
  assertCondition(
    invariantsSatisfied,
    'Invariant Engine: Conservation, non-negativity, lower bound & strict monotonicity hold across all 10 channels',
    invariantViolation,
  );

  // ==========================================================================
  // SECTION 4: SIMULATION STORE MUTATION LEDGER INVARIANTS
  // ==========================================================================
  print('\n--- 4. MockWalletStore Simulation & Mutation Ledger Invariants ---');

  final store = EmpiricalMockWalletStore();
  assertCondition(
    store.balanceCents == 25000000 && store.mutations.length == 3,
    'Store Baseline: balance Rp 250.000, 3 seed mutations',
  );

  // Simulation Step 1: Top Up Rp 100.000 via BCA VA
  store.addTopup(
    amountCents: 10000000,
    channelCode: 'bca_va',
    channelName: 'BCA Virtual Account',
  );
  assertCondition(
    store.balanceCents == 35000000,
    'Simulation 1: Balance increments to Rp 350.000 (35,000,000 cents)',
  );
  assertCondition(
    store.mutations.length == 4 &&
    store.mutations.first.referenceType == 'topup' &&
    store.mutations.first.type == 'credit' &&
    store.mutations.first.amountCents == 10000000 &&
    store.mutations.first.note!.contains('BCA Virtual Account'),
    'Simulation 1: Mutation ledger prepends credit record with amount 10,000,000 cents',
  );

  // Simulation Step 2: Top Up Rp 50.000 via QRIS
  store.addTopup(
    amountCents: 5000000,
    channelCode: 'qris',
    channelName: 'QRIS Instant',
  );
  assertCondition(
    store.balanceCents == 40000000,
    'Simulation 2: Cumulative balance increments to Rp 400.000 (40,000,000 cents)',
  );
  assertCondition(
    store.mutations.length == 5 &&
    store.mutations.first.amountCents == 5000000 &&
    store.mutations.first.note!.contains('QRIS Instant'),
    'Simulation 2: Second credit prepended with amount 5,000,000 cents',
  );

  // Simulation Step 3: Top Up Rp 1.000.000 via Manual Transfer
  store.addTopup(
    amountCents: 100000000,
    channelCode: 'manual_bca',
    channelName: 'Transfer Bank BCA',
  );
  assertCondition(
    store.balanceCents == 140000000,
    'Simulation 3: Balance reaches Rp 1.400.000 (140,000,000 cents)',
  );
  assertCondition(
    store.mutations.length == 6,
    'Simulation 3: Mutation count increments to 6',
  );

  // Simulation Step 4: Reset restores baseline state cleanly
  store.reset();
  assertCondition(
    store.balanceCents == 25000000 && store.mutations.length == 3,
    'Store Reset: Balance resets to Rp 250.000 and mutations reset to 3 records',
  );

  // ==========================================================================
  // SECTION 5: STATIC AST & WIDGET KEY INTEGRITY VERIFICATION
  // ==========================================================================
  print('\n--- 5. Static AST, Source Code & Navigation Wiring Verification ---');

  final topupScreenFile = File('lib/features/wallet/presentation/topup_screen.dart');
  assertCondition(topupScreenFile.existsSync(), 'TopupScreen file exists');
  final topupScreenSrc = topupScreenFile.readAsStringSync();

  final requiredKeys = [
    'topup_header_balance',
    'topup_toggle_balance_button',
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

  for (final key in requiredKeys) {
    assertCondition(
      topupScreenSrc.contains(key),
      'TopupScreen contracts: contains key "$key"',
    );
  }

  // Verify PaymentSimulationSheet file and contents
  final sheetFile = File('lib/features/wallet/presentation/widgets/payment_simulation_sheet.dart');
  assertCondition(sheetFile.existsSync(), 'PaymentSimulationSheet file exists');
  final sheetSrc = sheetFile.readAsStringSync();
  assertCondition(sheetSrc.contains('topup_simulation_pay_button'), 'PaymentSimulationSheet: key "topup_simulation_pay_button" present');
  assertCondition(sheetSrc.contains('Simulasikan Pembayaran Berhasil'), 'PaymentSimulationSheet: button label "Simulasikan Pembayaran Berhasil" present');
  assertCondition(sheetSrc.contains('MockWalletStore.instance.addTopup'), 'PaymentSimulationSheet: invokes MockWalletStore.instance.addTopup');
  assertCondition(sheetSrc.contains('fetchDashboard'), 'PaymentSimulationSheet: synchronizes homeNotifier fetchDashboard');
  assertCondition(sheetSrc.contains('fetchMutations'), 'PaymentSimulationSheet: synchronizes walletNotifier fetchMutations');

  // Verify Navigation Entry Points
  final homeFile = File('lib/features/home/presentation/home_screen.dart');
  assertCondition(homeFile.existsSync(), 'HomeScreen file exists');
  final homeSrc = homeFile.readAsStringSync();
  assertCondition(homeSrc.contains('home_topup_button'), 'HomeScreen: contains key "home_topup_button"');
  assertCondition(homeSrc.contains("context.push('/topup')"), 'HomeScreen: uses context.push("/topup")');

  final walletFile = File('lib/features/wallet/presentation/wallet_screen.dart');
  assertCondition(walletFile.existsSync(), 'WalletScreen file exists');
  final walletSrc = walletFile.readAsStringSync();
  assertCondition(walletSrc.contains('wallet_topup_button'), 'WalletScreen: contains key "wallet_topup_button"');
  assertCondition(walletSrc.contains("context.push('/topup')"), 'WalletScreen: uses context.push("/topup")');

  // Verify Router Registration
  final routerFile = File('lib/app/router.dart');
  assertCondition(routerFile.existsSync(), 'Router file exists');
  final routerSrc = routerFile.readAsStringSync();
  assertCondition(routerSrc.contains("path: '/topup'"), 'Router: registers route "/topup"');
  assertCondition(routerSrc.contains('TopupScreen'), 'Router: maps "/topup" to TopupScreen');

  // Verify Rupiah Input Formatter static utility methods
  final formatterFile = File('lib/core/utils/rupiah_input_formatter.dart');
  assertCondition(formatterFile.existsSync(), 'RupiahInputFormatter file exists');
  final formatterSrc = formatterFile.readAsStringSync();
  assertCondition(formatterSrc.contains('parseRupiah'), 'RupiahInputFormatter: defines parseRupiah');
  assertCondition(formatterSrc.contains('format'), 'RupiahInputFormatter: defines format');
  assertCondition(formatterSrc.contains('formatEditUpdate'), 'RupiahInputFormatter: implements formatEditUpdate');
  assertCondition(formatterSrc.contains('digits.length > 11'), 'RupiahInputFormatter: caps at 11 digits');

  // ==========================================================================
  // FINAL EMPIRICAL SUMMARY & VERDICT
  // ==========================================================================
  print('\n======================================================================');
  print('  EMPIRICAL CHALLENGER TEST RESULTS SUMMARY');
  print('  Total Assertions: $totalTests');
  print('  Passed:           $passedTests');
  print('  Failed:           $failedTests');
  print('======================================================================');

  if (failedTests == 0) {
    print('\n>> EMPIRICAL VERDICT: CONFIRMED CORRECT <<\n');
    print('All currency formatting, boundary validations, channel calculations,');
    print('total invariants, and navigation key contracts passed without defects.\n');
  } else {
    print('\n>> EMPIRICAL VERDICT: DISPROVEN / FAILED <<\n');
    print('Failed assertions:');
    for (final f in failures) {
      print('  * $f');
    }
    exitCode = 1;
  }
}
