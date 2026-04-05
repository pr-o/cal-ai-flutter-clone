// TDEE calculation using the Mifflin-St Jeor formula.
//
// All inputs are in metric (kg, cm). The [goal] field adjusts the final
// calorie target: 'lose' subtracts 500 kcal, 'gain' adds 300 kcal.

class TdeeInput {
  final double currentWeightKg;
  final double heightCm;

  /// ISO date string (YYYY-MM-DD) — used to derive age.
  final String birthday;

  /// 'male' | 'female' | 'other'
  final String gender;

  /// 'sedentary' | 'lightly_active' | 'active' | 'very_active'
  final String activityLevel;

  /// 'lose' | 'maintain' | 'gain'
  final String goal;

  const TdeeInput({
    required this.currentWeightKg,
    required this.heightCm,
    required this.birthday,
    required this.gender,
    required this.activityLevel,
    required this.goal,
  });
}

class TdeeResult {
  final int calories;
  final int proteinG;
  final int carbsG;
  final int fatG;

  const TdeeResult({
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });
}

TdeeResult calculateTdee(TdeeInput input) {
  final age = _ageFromBirthday(input.birthday);

  // Mifflin-St Jeor BMR
  final double bmrMale =
      10 * input.currentWeightKg + 6.25 * input.heightCm - 5 * age + 5;
  final double bmrFemale =
      10 * input.currentWeightKg + 6.25 * input.heightCm - 5 * age - 161;

  final double bmr = switch (input.gender) {
    'male' => bmrMale,
    'female' => bmrFemale,
    _ => (bmrMale + bmrFemale) / 2, // 'other'
  };

  // Activity multiplier
  final double multiplier = switch (input.activityLevel) {
    'sedentary' => 1.2,
    'lightly_active' => 1.375,
    'active' => 1.55,
    'very_active' => 1.725,
    _ => 1.2,
  };

  double tdee = bmr * multiplier;

  // Goal adjustment
  tdee += switch (input.goal) {
    'lose' => -500,
    'gain' => 300,
    _ => 0,
  };

  final int calories = tdee.round().clamp(1200, 4000);

  // Macro split: 30% protein, 40% carbs, 30% fat
  final int proteinG = (calories * 0.30 / 4).round();
  final int carbsG = (calories * 0.40 / 4).round();
  final int fatG = (calories * 0.30 / 9).round();

  return TdeeResult(
    calories: calories,
    proteinG: proteinG,
    carbsG: carbsG,
    fatG: fatG,
  );
}

int _ageFromBirthday(String birthday) {
  final parts = birthday.split('-');
  if (parts.length != 3) return 25;
  final dob = DateTime(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
  final now = DateTime.now();
  int age = now.year - dob.year;
  if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
    age--;
  }
  return age.clamp(1, 120);
}
