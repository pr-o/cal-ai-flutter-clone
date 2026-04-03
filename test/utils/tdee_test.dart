import 'package:flutter_test/flutter_test.dart';
import 'package:cal_ai_flutter_clone/utils/tdee.dart';

void main() {
  group('calculateTdee', () {
    test('male, active, maintain — reasonable calorie range', () {
      final result = calculateTdee(TdeeInput(
        currentWeightKg: 80,
        heightCm: 175,
        birthday: '1994-01-01',
        gender: 'male',
        activityLevel: 'active',
        goal: 'maintain',
      ));
      // BMR ≈ 1749, × 1.55 ≈ 2710
      expect(result.calories, inInclusiveRange(2500, 2900));
      expect(result.proteinG, greaterThan(0));
      expect(result.carbsG, greaterThan(0));
      expect(result.fatG, greaterThan(0));
    });

    test('female, active, lose — calories reduced by 500', () {
      final maintain = calculateTdee(TdeeInput(
        currentWeightKg: 70,
        heightCm: 168,
        birthday: '1990-06-15',
        gender: 'female',
        activityLevel: 'active',
        goal: 'maintain',
      ));
      final lose = calculateTdee(TdeeInput(
        currentWeightKg: 70,
        heightCm: 168,
        birthday: '1990-06-15',
        gender: 'female',
        activityLevel: 'active',
        goal: 'lose',
      ));
      expect(maintain.calories - lose.calories, 500);
    });

    test('gain goal adds 300 calories vs maintain', () {
      final maintain = calculateTdee(TdeeInput(
        currentWeightKg: 70,
        heightCm: 178,
        birthday: '1995-03-20',
        gender: 'male',
        activityLevel: 'lightly_active',
        goal: 'maintain',
      ));
      final gain = calculateTdee(TdeeInput(
        currentWeightKg: 70,
        heightCm: 178,
        birthday: '1995-03-20',
        gender: 'male',
        activityLevel: 'lightly_active',
        goal: 'gain',
      ));
      expect(gain.calories - maintain.calories, 300);
    });

    test('macro calories sum to approximately total calories', () {
      final result = calculateTdee(TdeeInput(
        currentWeightKg: 75,
        heightCm: 170,
        birthday: '1992-09-10',
        gender: 'other',
        activityLevel: 'active',
        goal: 'maintain',
      ));
      final macroCalories =
          result.proteinG * 4 + result.carbsG * 4 + result.fatG * 9;
      // Allow ±5% rounding tolerance
      expect(macroCalories, closeTo(result.calories, result.calories * 0.05));
    });

    test('calories are clamped to minimum 1200', () {
      final result = calculateTdee(TdeeInput(
        currentWeightKg: 40,
        heightCm: 140,
        birthday: '2000-01-01',
        gender: 'female',
        activityLevel: 'sedentary',
        goal: 'lose',
      ));
      expect(result.calories, greaterThanOrEqualTo(1200));
    });
  });
}
