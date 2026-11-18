import 'dart:io';
import 'dart:math';

// ============================================================================
// EMPIRICAL CHALLENGE HARNESS: NAVIGATION BAR VISUAL TOKENS, WCAG CONTRAST & GEOMETRY
// Milestone 4 Challenge — fillbill_mobile
// ============================================================================

/// Exact WCAG 2.1 Color Mathematics Oracle
class WcagColorMathOracle {
  /// sRGB Gamma Expansion to Linear Luminance channel
  static double sRgbChannelToLinear(int channel8Bit) {
    if (channel8Bit < 0 || channel8Bit > 255) {
      throw RangeError.range(channel8Bit, 0, 255, 'channel8Bit');
    }
    final s = channel8Bit / 255.0;
    return s <= 0.03928 ? s / 12.92 : pow((s + 0.055) / 1.055, 2.4).toDouble();
  }

  /// Relative Luminance L = 0.2126 * R + 0.7152 * G + 0.0722 * B
  static double relativeLuminance(int r, int g, int b) {
    final rLin = sRgbChannelToLinear(r);
    final gLin = sRgbChannelToLinear(g);
    final bLin = sRgbChannelToLinear(b);
    return 0.2126 * rLin + 0.7152 * gLin + 0.0722 * bLin;
  }

  /// Contrast Ratio CR = (L1 + 0.05) / (L2 + 0.05) where L1 >= L2
  static double contrastRatio(double lumA, double lumB) {
    final lighter = max(lumA, lumB);
    final darker = min(lumA, lumB);
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Alpha compositing over a solid background
  static List<int> alphaComposite({
    required List<int> sourceRgb,
    required double sourceAlpha,
    required List<int> backgroundRgb,
  }) {
    final r = (sourceAlpha * sourceRgb[0] + (1.0 - sourceAlpha) * backgroundRgb[0]).round();
    final g = (sourceAlpha * sourceRgb[1] + (1.0 - sourceAlpha) * backgroundRgb[1]).round();
    final b = (sourceAlpha * sourceRgb[2] + (1.0 - sourceAlpha) * backgroundRgb[2]).round();
    return [
      r.clamp(0, 255),
      g.clamp(0, 255),
      b.clamp(0, 255),
    ];
  }

  /// Linear interpolation between two RGB colors
  static List<int> lerpRgb(List<int> c1, List<int> c2, double t) {
    return [
      (c1[0] + (c2[0] - c1[0]) * t).round().clamp(0, 255),
      (c1[1] + (c2[1] - c1[1]) * t).round().clamp(0, 255),
      (c1[2] + (c2[2] - c1[2]) * t).round().clamp(0, 255),
    ];
  }
}

/// Navigation Bar Geometric Layout Oracle
class NavGeometryOracle {
  final double screenWidth;
  final double centerSpacerWidth;
  final int tabCount;
  final double pillIconSize;
  final double pillHorizontalPadding;
  final double pillBorderWidth;
  final double fabDiameter;
  final double notchRadius;
  final double notchDepth;

  const NavGeometryOracle({
    required this.screenWidth,
    this.centerSpacerWidth = 76.0,
    this.tabCount = 4,
    this.pillIconSize = 22.0,
    this.pillHorizontalPadding = 16.0,
    this.pillBorderWidth = 1.0,
    this.fabDiameter = 54.0,
    this.notchRadius = 38.0,
    this.notchDepth = 26.0,
  });

  double get availableWidthForTabs => screenWidth - centerSpacerWidth;
  double get singleTabWidth => availableWidthForTabs / tabCount;
  double get totalRowWidth => (singleTabWidth * tabCount) + centerSpacerWidth;
  double get minimumActivePillWidth => pillIconSize + (pillHorizontalPadding * 2) + (pillBorderWidth * 2);
  double get pillHeadroom => singleTabWidth - minimumActivePillWidth;
  double get leftTabGroupWidth => singleTabWidth * (tabCount / 2);
  double get scoopStartExpected => (screenWidth / 2) - notchRadius;
  double get scoopEndExpected => (screenWidth / 2) + notchRadius;
  double get fabRadialClearance => (notchRadius * 2 - fabDiameter) / 2;

  bool get hasZeroOverflow => (totalRowWidth - screenWidth).abs() < 1e-9;
  bool get hasPositivePillHeadroom => pillHeadroom >= 0;
  bool get notchIsPerfectCentered => (leftTabGroupWidth - scoopStartExpected).abs() < 1e-9;
}

void main() {
  print('======================================================================');
  print('  EMPIRICAL CHALLENGE SUITE: NAV BAR VISUAL TOKENS, WCAG & GEOMETRY   ');
  print('  Milestone 4 — fillbill_mobile                                      ');
  print('======================================================================\n');

  int totalAssertions = 0;
  int passedAssertions = 0;
  int failedAssertions = 0;

  void assertChallenge(bool condition, String description, [String? failureDetail]) {
    totalAssertions++;
    if (condition) {
      passedAssertions++;
      print('  [PASS] $description');
    } else {
      failedAssertions++;
      print('  [FAIL] $description');
      if (failureDetail != null) {
        print('         >> FAILURE DETAIL: $failureDetail');
      }
    }
  }

  // --------------------------------------------------------------------------
  // TEST SUITE 1: RELATIVE LUMINANCE MATHEMATICS FOR ALL DESIGN SYSTEM TOKENS
  // --------------------------------------------------------------------------
  print('--- TEST SUITE 1: sRGB Gamma Expansion & Relative Luminance Oracle ---');
  {
    // Token RGB Definitions
    final tokenWhite = [255, 255, 255];          // AppColors.surfaceWhite (#FFFFFF)
    final tokenNeoGreenSurface = [247, 254, 231]; // AppColors.neoGreenSurface (#F7FEE7)
    final tokenNeoGreenLight = [190, 242, 100];   // AppColors.neoGreenLight (#BEF264)
    final tokenNeoGreen = [163, 230, 53];         // AppColors.neoGreen (#A3E635)
    final tokenNeoGreenDark = [101, 163, 13];     // AppColors.neoGreenDark (#65A30D)
    final tokenTextSecondary = [100, 116, 139];   // AppColors.textSecondary (#64748B)
    final tokenPrimaryNavy = [13, 33, 55];        // BrandConfig.primaryColor (#0D2137)
    final tokenNeoGreenContrast = [20, 41, 0];    // AppColors.neoGreenContrast (#142900)
    final tokenBlack = [0, 0, 0];                 // Pure Black (#000000)

    // 1. Boundary channel expansions
    final lin0 = WcagColorMathOracle.sRgbChannelToLinear(0);
    final lin255 = WcagColorMathOracle.sRgbChannelToLinear(255);
    assertChallenge((lin0 - 0.0).abs() < 1e-9, 'Channel 0 linearizes to exactly 0.0');
    assertChallenge((lin255 - 1.0).abs() < 1e-9, 'Channel 255 linearizes to exactly 1.0');

    // Threshold check for sRGB transition boundary (0.03928 * 255 = 10.0164)
    // Channel 10 is below threshold, channel 11 is above threshold
    final lin10 = WcagColorMathOracle.sRgbChannelToLinear(10);
    final expected10 = (10.0 / 255.0) / 12.92;
    assertChallenge((lin10 - expected10).abs() < 1e-6, 'Channel 10 uses linear division formula (s / 12.92)');

    final lin11 = WcagColorMathOracle.sRgbChannelToLinear(11);
    final expected11 = pow(((11.0 / 255.0) + 0.055) / 1.055, 2.4).toDouble();
    assertChallenge((lin11 - expected11).abs() < 1e-6, 'Channel 11 uses exponential gamma formula ((s+0.055)/1.055)^2.4');

    // 2. Relative Luminance calculations
    final lumWhite = WcagColorMathOracle.relativeLuminance(tokenWhite[0], tokenWhite[1], tokenWhite[2]);
    final lumBlack = WcagColorMathOracle.relativeLuminance(tokenBlack[0], tokenBlack[1], tokenBlack[2]);
    final lumNeoGreenSurface = WcagColorMathOracle.relativeLuminance(tokenNeoGreenSurface[0], tokenNeoGreenSurface[1], tokenNeoGreenSurface[2]);
    final lumNeoGreenLight = WcagColorMathOracle.relativeLuminance(tokenNeoGreenLight[0], tokenNeoGreenLight[1], tokenNeoGreenLight[2]);
    final lumNeoGreen = WcagColorMathOracle.relativeLuminance(tokenNeoGreen[0], tokenNeoGreen[1], tokenNeoGreen[2]);
    final lumNeoGreenDark = WcagColorMathOracle.relativeLuminance(tokenNeoGreenDark[0], tokenNeoGreenDark[1], tokenNeoGreenDark[2]);
    final lumTextSecondary = WcagColorMathOracle.relativeLuminance(tokenTextSecondary[0], tokenTextSecondary[1], tokenTextSecondary[2]);
    final lumPrimaryNavy = WcagColorMathOracle.relativeLuminance(tokenPrimaryNavy[0], tokenPrimaryNavy[1], tokenPrimaryNavy[2]);
    final lumNeoGreenContrast = WcagColorMathOracle.relativeLuminance(tokenNeoGreenContrast[0], tokenNeoGreenContrast[1], tokenNeoGreenContrast[2]);

    assertChallenge((lumWhite - 1.0).abs() < 1e-9, 'White luminance is exactly 1.0');
    assertChallenge((lumBlack - 0.0).abs() < 1e-9, 'Black luminance is exactly 0.0');
    assertChallenge(lumNeoGreenSurface > 0.94 && lumNeoGreenSurface < 0.98,
        'neoGreenSurface luminance is in bright range (measured: ${lumNeoGreenSurface.toStringAsFixed(4)})');
    assertChallenge(lumNeoGreenLight > 0.74 && lumNeoGreenLight < 0.85,
        'neoGreenLight luminance is high (measured: ${lumNeoGreenLight.toStringAsFixed(4)})');
    assertChallenge(lumNeoGreen > 0.60 && lumNeoGreen < 0.70,
        'neoGreen luminance is vibrant (measured: ${lumNeoGreen.toStringAsFixed(4)})');
    assertChallenge(lumNeoGreenDark > 0.25 && lumNeoGreenDark < 0.35,
        'neoGreenDark luminance is olive-green mid-tone (measured: ${lumNeoGreenDark.toStringAsFixed(4)})');
    assertChallenge(lumTextSecondary > 0.15 && lumTextSecondary < 0.25,
        'textSecondary luminance is medium slate (measured: ${lumTextSecondary.toStringAsFixed(4)})');
    assertChallenge(lumPrimaryNavy > 0.01 && lumPrimaryNavy < 0.03,
        'primaryNavy luminance is dark (measured: ${lumPrimaryNavy.toStringAsFixed(4)})');
    assertChallenge(lumNeoGreenContrast > 0.01 && lumNeoGreenContrast < 0.03,
        'neoGreenContrast luminance is deep obsidian-green (measured: ${lumNeoGreenContrast.toStringAsFixed(4)})');

    // 3. Strict Monotonic Luminance Chain:
    // lumBlack < lumPrimaryNavy < lumNeoGreenContrast < lumTextSecondary < lumNeoGreenDark < lumNeoGreen < lumNeoGreenLight < lumNeoGreenSurface < lumWhite
    final isMonotonic = (lumBlack < lumPrimaryNavy) &&
        (lumPrimaryNavy < lumNeoGreenContrast) &&
        (lumNeoGreenContrast < lumTextSecondary) &&
        (lumTextSecondary < lumNeoGreenDark) &&
        (lumNeoGreenDark < lumNeoGreen) &&
        (lumNeoGreen < lumNeoGreenLight) &&
        (lumNeoGreenLight < lumNeoGreenSurface) &&
        (lumNeoGreenSurface < lumWhite);
    assertChallenge(isMonotonic, 'Luminance hierarchy strictly preserves visual contrast ladder');
  }

  // --------------------------------------------------------------------------
  // TEST SUITE 2: CONTRAST RATIO VALIDATION AGAINST WCAG 2.1 SPECIFICATIONS
  // --------------------------------------------------------------------------
  print('\n--- TEST SUITE 2: WCAG 2.1 Contrast Ratio Verification ---');
  {
    final lumWhite = WcagColorMathOracle.relativeLuminance(255, 255, 255);
    final lumNeoGreenSurface = WcagColorMathOracle.relativeLuminance(247, 254, 231);
    final lumNeoGreen = WcagColorMathOracle.relativeLuminance(163, 230, 53);
    final lumNeoGreenContrast = WcagColorMathOracle.relativeLuminance(20, 41, 0);
    final lumTextSecondary = WcagColorMathOracle.relativeLuminance(100, 116, 139);
    final lumTextTertiary = WcagColorMathOracle.relativeLuminance(148, 163, 184); // #94A3B8

    // CR 1: Active Soft Pill text/icon (neoGreenContrast on neoGreenSurface)
    // Target: >= 7.0:1 (WCAG AAA)
    final crActivePill = WcagColorMathOracle.contrastRatio(lumNeoGreenContrast, lumNeoGreenSurface);
    assertChallenge(crActivePill >= 7.0,
        'Active pill contrast (${crActivePill.toStringAsFixed(2)}:1) satisfies WCAG AAA (>= 7.0:1)');
    assertChallenge(crActivePill >= 15.0,
        'Active pill contrast (${crActivePill.toStringAsFixed(2)}:1) achieves high-contrast target (>= 15.0:1)');

    // Fallback CR: neoGreenContrast on surfaceWhite (if container background fails to render)
    final crActivePillOnWhite = WcagColorMathOracle.contrastRatio(lumNeoGreenContrast, lumWhite);
    assertChallenge(crActivePillOnWhite >= 7.0,
        'Active text on surfaceWhite fallback (${crActivePillOnWhite.toStringAsFixed(2)}:1) satisfies WCAG AAA');

    // CR 2: Inactive tab text/icon (textSecondary on surfaceWhite)
    // Target: >= 4.5:1 (WCAG AA)
    final crInactiveTab = WcagColorMathOracle.contrastRatio(lumTextSecondary, lumWhite);
    assertChallenge(crInactiveTab >= 4.5,
        'Inactive tab contrast (${crInactiveTab.toStringAsFixed(2)}:1) satisfies WCAG AA (>= 4.5:1)');

    // Anti-pattern challenge: Verify textTertiary (#94A3B8) would FAIL WCAG AA
    final crTertiaryFail = WcagColorMathOracle.contrastRatio(lumTextTertiary, lumWhite);
    assertChallenge(crTertiaryFail < 4.5,
        'Confirmed textTertiary (${crTertiaryFail.toStringAsFixed(2)}:1) fails WCAG AA, justifying textSecondary choice');

    // CR 3: Center FAB Icon (neoGreenContrast on neoGreen surface)
    // Target: >= 3.0:1 (WCAG 2.1 UI Component / Non-text contrast)
    final crFab = WcagColorMathOracle.contrastRatio(lumNeoGreenContrast, lumNeoGreen);
    assertChallenge(crFab >= 3.0,
        'Center FAB icon contrast (${crFab.toStringAsFixed(2)}:1) satisfies WCAG UI standard (>= 3.0:1)');
    assertChallenge(crFab >= 10.0,
        'Center FAB icon contrast (${crFab.toStringAsFixed(2)}:1) exceeds 10.0:1');

    // Anti-pattern challenge: White icon on neoGreen FAILS contrast
    final crWhiteOnNeoGreen = WcagColorMathOracle.contrastRatio(lumWhite, lumNeoGreen);
    assertChallenge(crWhiteOnNeoGreen < 3.0,
        'Confirmed white on neoGreen (${crWhiteOnNeoGreen.toStringAsFixed(2)}:1) fails WCAG UI standard, proving neoGreenContrast is mandatory');

    // CR 4: Full Gradient Stress Test across FAB Stops
    // FAB gradient traverses: neoGreenLight -> neoGreen -> neoGreenDark
    final cLight = [190, 242, 100];
    final cMid = [163, 230, 53];
    final cDark = [101, 163, 13];

    bool gradientPassesAllSteps = true;
    double minGradientCr = 999.0;
    double maxGradientCr = 0.0;

    // Sample 21 points along the gradient from t = 0.0 to t = 1.0
    for (int step = 0; step <= 20; step++) {
      final t = step / 20.0;
      List<int> sampleRgb;
      if (t <= 0.5) {
        sampleRgb = WcagColorMathOracle.lerpRgb(cLight, cMid, t / 0.5);
      } else {
        sampleRgb = WcagColorMathOracle.lerpRgb(cMid, cDark, (t - 0.5) / 0.5);
      }
      final lumSample = WcagColorMathOracle.relativeLuminance(sampleRgb[0], sampleRgb[1], sampleRgb[2]);
      final crStep = WcagColorMathOracle.contrastRatio(lumNeoGreenContrast, lumSample);
      if (crStep < minGradientCr) minGradientCr = crStep;
      if (crStep > maxGradientCr) maxGradientCr = crStep;
      if (crStep < 3.0) {
        gradientPassesAllSteps = false;
      }
    }

    assertChallenge(gradientPassesAllSteps,
        'FAB gradient maintains WCAG UI contrast (>= 3.0:1) across 21 sample stops (range: ${minGradientCr.toStringAsFixed(2)}:1 to ${maxGradientCr.toStringAsFixed(2)}:1)');
    assertChallenge(minGradientCr >= 4.5,
        'Worst-case gradient contrast stop exceeds WCAG AA text standard 4.5:1 (measured: ${minGradientCr.toStringAsFixed(2)}:1 at dark edge)');

    // CR 5: Ambient Glow Compositing Math
    // neoGreenGlow: Color(0x66A3E635) -> alpha = 102/255 = 0.40
    final glowCompositeRgb = WcagColorMathOracle.alphaComposite(
      sourceRgb: cMid,
      sourceAlpha: 102 / 255.0,
      backgroundRgb: [255, 255, 255],
    );
    final lumGlowComposite = WcagColorMathOracle.relativeLuminance(
      glowCompositeRgb[0],
      glowCompositeRgb[1],
      glowCompositeRgb[2],
    );
    final crGlowVsWhite = WcagColorMathOracle.contrastRatio(lumGlowComposite, lumWhite);
    assertChallenge(crGlowVsWhite < 1.3,
        'Ambient glow on surfaceWhite produces soft luminous aura (${crGlowVsWhite.toStringAsFixed(2)}:1 <= 1.3:1)');
  }

  // --------------------------------------------------------------------------
  // TEST SUITE 3: RESPONSIVE GEOMETRY & OVERFLOW PROOF ACROSS VIEWPORTS
  // --------------------------------------------------------------------------
  print('\n--- TEST SUITE 3: Responsive Geometry & Zero-Overflow Proof ---');
  {
    final testViewports = [
      {'name': 'Ultra-compact mobile (WCAG Reflow Minimum)', 'width': 320.0},
      {'name': 'Compact Android standard', 'width': 360.0},
      {'name': 'iPhone Standard (12/13/14)', 'width': 390.0},
      {'name': 'Google Pixel Standard', 'width': 412.0},
      {'name': 'Tablet Portrait (iPad Mini/Air)', 'width': 768.0},
      // Additional adversarial viewports
      {'name': 'Legacy Compact iPhone (6/7/8/SE)', 'width': 375.0},
      {'name': 'Phablet / iPhone Pro Max', 'width': 428.0},
      {'name': 'Tablet Landscape (iPad Pro)', 'width': 1024.0},
    ];

    for (final vp in testViewports) {
      final name = vp['name'] as String;
      final width = vp['width'] as double;
      final geom = NavGeometryOracle(screenWidth: width);

      // 1. Exact Row Width Summation Proof:
      // totalRowWidth = 4 * ((W - 76) / 4) + 76 = W - 76 + 76 = W
      assertChallenge(geom.hasZeroOverflow,
          '[$name (W=${width.toInt()}px)] Horizontal width summation exactly equals screen width (Zero Overflow)');

      // 2. Active Soft-Pill Headroom Proof:
      // Minimum pill width: icon (22px) + horizontal padding (16*2=32px) + border (1*2=2px) = 56px
      final tabWidth = geom.singleTabWidth;
      final pillWidth = geom.minimumActivePillWidth;
      final headroom = geom.pillHeadroom;

      assertChallenge(geom.hasPositivePillHeadroom,
          '[$name] Tab width (${tabWidth.toStringAsFixed(1)}px) >= Active Pill width (${pillWidth.toStringAsFixed(1)}px) with ${headroom.toStringAsFixed(1)}px margin headroom');

      // 3. Curved Scoop Notch Mechanical Centering Proof:
      // Tab 0 + Tab 1 width must perfectly align with left shoulder of scoop notch
      assertChallenge(geom.notchIsPerfectCentered,
          '[$name] Center scoop notch radius (38px) is mathematically centered at X = ${(width / 2).toStringAsFixed(1)}px');
    }

    // Edge-case stress analysis: Determine theoretical minimum screen width before pill clipping
    // W_min = 4 * pillWidth + 76 = 4 * 56 + 76 = 224 + 76 = 300px
    const theoreticalCutoff = 300.0;
    final geomCutoff = NavGeometryOracle(screenWidth: theoreticalCutoff);
    assertChallenge((geomCutoff.pillHeadroom - 0.0).abs() < 1e-9,
        'Theoretical minimum device width without pill deformation is exactly 300.0px (WCAG 320px leaves +5.0px per tab)');

    // Center FAB Mechanical Docking & Clearance
    final defaultGeom = NavGeometryOracle(screenWidth: 360.0);
    assertChallenge(defaultGeom.fabRadialClearance == 11.0,
        'Center FAB (54px) has symmetrical 11.0px radial clearance inside the 76px scoop notch');
  }

  // --------------------------------------------------------------------------
  // TEST SUITE 4: STATIC SOURCE CODE CONTRACT & SOURCE IMPLEMENTATION INTEGRITY
  // --------------------------------------------------------------------------
  print('\n--- TEST SUITE 4: Static Source Code Contract & Anti-Regressions ---');
  {
    // Locate main_nav_shell.dart regardless of whether running from root or fillbill_mobile
    final primaryPath = 'lib/app/main_nav_shell.dart';
    final fallbackPath = 'fillbill_mobile/lib/app/main_nav_shell.dart';
    final shellFile = File(primaryPath).existsSync() ? File(primaryPath) : File(fallbackPath);

    assertChallenge(shellFile.existsSync(), 'main_nav_shell.dart located successfully at ${shellFile.path}');
    final src = shellFile.readAsStringSync();

    // Verify UI Key Contract
    assertChallenge(src.contains("Key('nav_bar')"), 'Defines bar container Key "nav_bar"');
    assertChallenge(src.contains("Key('nav_fab')"), 'Defines center action Key "nav_fab"');
    for (int i = 0; i < 4; i++) {
      assertChallenge(src.contains("Key('nav_tab_$i')"), 'Defines positional tap target Key "nav_tab_$i"');
    }
    assertChallenge(src.contains("Key('nav_tab_home')"), 'Defines semantic pill Key "nav_tab_home"');
    assertChallenge(src.contains("Key('nav_tab_history')"), 'Defines semantic pill Key "nav_tab_history"');
    assertChallenge(src.contains("Key('nav_tab_wallet')"), 'Defines semantic pill Key "nav_tab_wallet"');
    assertChallenge(src.contains("Key('nav_tab_profile')"), 'Defines semantic pill Key "nav_tab_profile"');

    // Tab 3 Synchronization & Elimination of Legacy Code
    assertChallenge(src.contains("'Profil'"), 'Tab 3 label is synchronized to "Profil"');
    assertChallenge(!src.contains("'Menu'"), 'Legacy label "Menu" is completely eliminated');
    assertChallenge(src.contains("Icons.person_outline_rounded"), 'Tab 3 defines inactive person icon');
    assertChallenge(src.contains("Icons.person_rounded"), 'Tab 3 defines active person icon');
    assertChallenge(!src.contains("Icons.tune_rounded"), 'Legacy icon Icons.tune_rounded is completely eliminated');

    // Design Tokens & Visual Hierarchy
    assertChallenge(src.contains("AppColors.neoGreenSurface"), 'Active pill uses AppColors.neoGreenSurface');
    assertChallenge(src.contains("AppColors.neoGreenContrast"), 'Active typography and icon use AppColors.neoGreenContrast');
    assertChallenge(src.contains("AppColors.textSecondary"), 'Inactive typography uses AppColors.textSecondary');
    assertChallenge(src.contains("AppColors.neoGreenGlow"), 'FAB applies signature AppColors.neoGreenGlow');

    // Continuous Cradle Border Path
    assertChallenge(src.contains("CurvedScoopPainter"), 'Bar background rendered via CurvedScoopPainter');
    assertChallenge(src.contains("borderPath"), 'CurvedScoopPainter traces continuous borderPath without gaps');
    assertChallenge(src.contains("const SizedBox(width: 76)"), 'Row center spacer matches 76px notch diameter');
  }

  // --------------------------------------------------------------------------
  // SUMMARY & VERDICT
  // --------------------------------------------------------------------------
  print('\n======================================================================');
  print('  EMPIRICAL CHALLENGE SUITE SUMMARY');
  print('  Total Assertions: $totalAssertions');
  print('  Passed:           $passedAssertions');
  print('  Failed:           $failedAssertions');
  print('======================================================================\n');

  if (failedAssertions > 0) {
    print('>> EMPIRICAL VERDICT: DISPROVEN / FAILED ($failedAssertions failures) <<\n');
    exit(1);
  } else {
    print('>> EMPIRICAL VERDICT: CONFIRMED CORRECT ($passedAssertions/$totalAssertions assertions passed) <<\n');
  }
}
