import 'package:flutter_test/flutter_test.dart';
import 'package:cal_ai_flutter_clone/utils/units.dart';

void main() {
  group('weight conversions', () {
    test('kgToLbs', () {
      expect(kgToLbs(1), closeTo(2.20462, 0.0001));
      expect(kgToLbs(80), closeTo(176.37, 0.01));
    });

    test('lbsToKg', () {
      expect(lbsToKg(2.20462), closeTo(1.0, 0.0001));
      expect(lbsToKg(176.37), closeTo(80.0, 0.01));
    });

    test('kg → lbs → kg round-trip', () {
      expect(lbsToKg(kgToLbs(70)), closeTo(70.0, 0.0001));
    });
  });

  group('height conversions', () {
    test('cmToFtIn — 180 cm = 5ft 11in', () {
      final (ft, inches) = cmToFtIn(180);
      expect(ft, 5);
      expect(inches, 11);
    });

    test('cmToFtIn — 152.4 cm = 5ft 0in', () {
      final (ft, inches) = cmToFtIn(152.4);
      expect(ft, 5);
      expect(inches, 0);
    });

    test('ftInToCm — 6ft 0in = 182.88 cm', () {
      expect(ftInToCm(6, 0), closeTo(182.88, 0.01));
    });

    test('cm → ftIn → cm round-trip', () {
      final (ft, inches) = cmToFtIn(175);
      expect(ftInToCm(ft, inches), closeTo(175, 2.0));
    });
  });

  group('volume conversions', () {
    test('mlToOz', () {
      expect(mlToOz(1000), closeTo(33.814, 0.01));
    });

    test('ozToMl', () {
      expect(ozToMl(33.814), closeTo(1000.0, 0.1));
    });

    test('ml → oz → ml round-trip', () {
      expect(ozToMl(mlToOz(500)), closeTo(500.0, 0.01));
    });
  });

  group('display helpers', () {
    test('formatWeight kg', () {
      expect(formatWeight(70.5, 'kg'), '70.5 kg');
    });

    test('formatWeight lbs', () {
      expect(formatWeight(70.0, 'lbs'), contains('lbs'));
    });

    test('formatHeight cm', () {
      expect(formatHeight(175, 'kg'), '175 cm');
    });

    test('formatHeight imperial', () {
      expect(formatHeight(180, 'lbs'), contains("'"));
    });
  });
}
