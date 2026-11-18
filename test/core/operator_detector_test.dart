import 'package:flutter_test/flutter_test.dart';
import 'package:fillbill_mobile/core/utils/operator_detector.dart';

void main() {
  group('OperatorDetector Test Suite', () {
    test('Detect Telkomsel prefixes', () {
      expect(OperatorDetector.detect('08123456789').type, CellularOperatorType.telkomsel);
      expect(OperatorDetector.detect('08219876543').type, CellularOperatorType.telkomsel);
      expect(OperatorDetector.detect('+6285211112222').type, CellularOperatorType.telkomsel);
      expect(OperatorDetector.detect('62811000000').type, CellularOperatorType.telkomsel);
    });

    test('Detect Indosat Ooredoo prefixes', () {
      expect(OperatorDetector.detect('08151234567').type, CellularOperatorType.indosat);
      expect(OperatorDetector.detect('08571234567').type, CellularOperatorType.indosat);
      expect(OperatorDetector.detect('08561234567').type, CellularOperatorType.indosat);
    });

    test('Detect XL Axiata prefixes', () {
      expect(OperatorDetector.detect('08171234567').type, CellularOperatorType.xl);
      expect(OperatorDetector.detect('08781234567').type, CellularOperatorType.xl);
      expect(OperatorDetector.detect('08191234567').type, CellularOperatorType.xl);
    });

    test('Detect Axis prefixes', () {
      expect(OperatorDetector.detect('08381234567').type, CellularOperatorType.axis);
      expect(OperatorDetector.detect('08311234567').type, CellularOperatorType.axis);
    });

    test('Detect Tri (3) prefixes', () {
      expect(OperatorDetector.detect('08961234567').type, CellularOperatorType.tri);
      expect(OperatorDetector.detect('08951234567').type, CellularOperatorType.tri);
    });

    test('Detect Smartfren prefixes', () {
      expect(OperatorDetector.detect('08811234567').type, CellularOperatorType.smartfren);
      expect(OperatorDetector.detect('08881234567').type, CellularOperatorType.smartfren);
    });

    test('Unknown or short prefix returns unknown', () {
      expect(OperatorDetector.detect('08').type, CellularOperatorType.unknown);
      expect(OperatorDetector.detect('123456').type, CellularOperatorType.unknown);
      expect(OperatorDetector.detect('').type, CellularOperatorType.unknown);
    });

    test('getInfo returns matching brand name and color', () {
      final info = OperatorDetector.getInfo(CellularOperatorType.telkomsel);
      expect(info.name, 'Telkomsel');
      expect(info.code, 'telkomsel');
    });
  });
}
