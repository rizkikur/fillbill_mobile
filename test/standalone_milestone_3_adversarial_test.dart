import 'dart:io';

// ============================================================================
// ADVERSARIAL STRESS TEST & ATTACK SURFACE VERIFICATION: MILESTONE 3
// Reviewer M3 (Instance 2) Independent Verification
// ============================================================================

class StandaloneRupiahFormatter {
  static String format(int rupiah) {
    final s = rupiah.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(s[i]);
    }
    return 'Rp ${buffer.toString()}';
  }

  static int parseRupiah(String text) {
    final digits = text.replaceAll(RegExp(r'[^\d]'), '');
    return int.tryParse(digits) ?? 0;
  }

  static String simulateFormatEditUpdate(String input) {
    if (input.isEmpty) return '';
    final digits = input.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return '';
    final safeDigits = digits.length > 11 ? digits.substring(0, 11) : digits;
    final int value = int.tryParse(safeDigits) ?? 0;
    return format(value);
  }
}

class StandaloneChannelFee {
  final String feeType;
  final int feeCents;

  const StandaloneChannelFee({required this.feeType, required this.feeCents});

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

void main() {
  print('======================================================================');
  print('  ADVERSARIAL STRESS TEST SUITE: MILESTONE 3 (REVIEWER INSTANCE 2)    ');
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
  // ATTACK SURFACE 1: Extreme Inputs & Truncation in Formatter
  // --------------------------------------------------------------------------
  print('--- Attack Surface 1: Extreme Input Fuzzing & Formatter ---');
  {
    // Leading zeros
    expect(StandaloneRupiahFormatter.simulateFormatEditUpdate('0000') == 'Rp 0',
        'Input "0000" safely formats to "Rp 0"');
    expect(StandaloneRupiahFormatter.simulateFormatEditUpdate('00050000') == 'Rp 50.000',
        'Input "00050000" safely normalizes leading zeros to "Rp 50.000"');

    // Negative numbers
    expect(StandaloneRupiahFormatter.simulateFormatEditUpdate('-50000') == 'Rp 50.000',
        'Negative sign is stripped: "-50000" becomes "Rp 50.000"');

    // Emoji, symbols, spaces, zero-width characters
    expect(StandaloneRupiahFormatter.simulateFormatEditUpdate('🎉 Rp 100.000 🚀') == 'Rp 100.000',
        'Emojis and decorative strings stripped cleanly to "Rp 100.000"');
    expect(StandaloneRupiahFormatter.simulateFormatEditUpdate('\u200B\u200D\uFEFF') == '',
        'Zero-width unicode spaces cleanly evaluate to empty');

    // 11-digit cap overflow stress test
    final extremeDigits = '9' * 40; // 40 digits
    final formattedExtreme = StandaloneRupiahFormatter.simulateFormatEditUpdate(extremeDigits);
    expect(formattedExtreme == 'Rp 99.999.999.999',
        '40 digits capped strictly at 11 digits (Rp 99.999.999.999)');

    // Javascript safe integer compatibility (Dart on Web)
    final elevenDigitsInt = int.parse('9' * 11);
    final centsValue = elevenDigitsInt * 100; // 14 digits
    const maxJsSafeInt = 9007199254740991; // 2^53 - 1
    expect(centsValue < maxJsSafeInt,
        'Max 11 digits * 100 ($centsValue) strictly < JS Number.MAX_SAFE_INTEGER ($maxJsSafeInt)');
  }

  // --------------------------------------------------------------------------
  // ATTACK SURFACE 2: Fee Rounding & Off-by-One Under Extreme Nominals
  // --------------------------------------------------------------------------
  print('\n--- Attack Surface 2: Percentage Fee Rounding & Invariants ---');
  {
    const qris = StandaloneChannelFee(feeType: 'percentage', feeCents: 0);

    // Exact min bound: Rp 10.000 (1,000,000 cents)
    expect(qris.calculateFeeCents(1000000) == 7000,
        'QRIS fee for Rp 10.000 is exactly 7,000 cents (Rp 70)');
    expect(qris.calculateTotalCents(1000000) == 1007000,
        'QRIS total for Rp 10.000 is 1,007,000 cents (Rp 10.070)');

    // Rounding fractional cent test: nominal Rp 10.001 (1,000,100 cents)
    // 1,000,100 * 0.007 = 7000.7 -> round to 7001 cents
    expect(qris.calculateFeeCents(1000100) == 7001,
        'QRIS fee for odd nominal rounds 7000.7 to 7001 cents');

    // Exact max bound: Rp 10.000.000 (1,000,000,000 cents)
    expect(qris.calculateFeeCents(1000000000) == 7000000,
        'QRIS fee for Rp 10.000.000 is 7,000,000 cents (Rp 70.000)');
    expect(qris.calculateTotalCents(1000000000) == 1007000000,
        'QRIS total for Rp 10.000.000 is 1,007,000,000 cents (Rp 10.070.000)');

    // Free channel: Manual BCA
    const manual = StandaloneChannelFee(feeType: 'flat', feeCents: 0);
    expect(manual.calculateFeeCents(1000000) == 0, 'Manual fee is 0');
    expect(manual.calculateTotalCents(1000000) == 1000000, 'Manual total equals nominal');
  }

  // --------------------------------------------------------------------------
  // ATTACK SURFACE 3: WCAG Color Contrast Mathematics
  // --------------------------------------------------------------------------
  print('\n--- Attack Surface 3: WCAG AAA Color Contrast Math ---');
  {
    double calculateLuminance(int r, int g, int b) {
      double transform(int c) {
        final s = c / 255.0;
        return s <= 0.03928 ? s / 12.92 : ((s + 0.055) / 1.055) * ((s + 0.055) / 1.055);
      }
      return 0.2126 * transform(r) + 0.7152 * transform(g) + 0.0722 * transform(b);
    }

    double contrastRatio(double l1, double l2) {
      final lighter = l1 > l2 ? l1 : l2;
      final darker = l1 > l2 ? l2 : l1;
      return (lighter + 0.05) / (darker + 0.05);
    }

    // NeoGreenSurface (#F7FEE7) and NeoGreenContrast (#142900)
    final lSurface = calculateLuminance(0xF7, 0xFE, 0xE7);
    final lContrast = calculateLuminance(0x14, 0x29, 0x00);
    final ratioSelectedChip = contrastRatio(lSurface, lContrast);
    print('  [INFO] Selected chip contrast ratio: ${ratioSelectedChip.toStringAsFixed(2)}:1');
    expect(ratioSelectedChip >= 7.0,
        'Selected chip text on background satisfies WCAG AAA (>= 7.0:1)');

    // PrimaryNavy (#0A2540) and White (#FFFFFF)
    final lNavy = calculateLuminance(0x0A, 0x25, 0x40);
    final lWhite = calculateLuminance(0xFF, 0xFF, 0xFF);
    final ratioCta = contrastRatio(lWhite, lNavy);
    print('  [INFO] Primary CTA button contrast ratio: ${ratioCta.toStringAsFixed(2)}:1');
    expect(ratioCta >= 7.0,
        'Primary CTA button text on background satisfies WCAG AAA (>= 7.0:1)');
  }

  // --------------------------------------------------------------------------
  // SUMMARY
  // --------------------------------------------------------------------------
  print('\n======================================================================');
  print('  ADVERSARIAL STRESS TEST SUMMARY');
  print('  Total Assertions: $totalTests');
  print('  Passed:           $passedTests');
  print('  Failed:           $failedTests');
  print('======================================================================');

  if (failedTests == 0) {
    print('\n>> ADVERSARIAL VERDICT: 0 VULNERABILITIES DETECTED <<\n');
  } else {
    print('\n>> ADVERSARIAL VERDICT: FAILURES DETECTED <<\n');
    exitCode = 1;
  }
}
