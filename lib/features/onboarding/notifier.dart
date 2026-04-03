import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class OnboardingState {
  /// 'lose' | 'maintain' | 'gain'
  final String goal;

  /// 'male' | 'female' | 'other'
  final String gender;

  /// ISO date string 'YYYY-MM-DD'
  final String birthday;

  final double currentWeightKg;
  final double heightCm;
  final double targetWeightKg;

  /// 'sedentary' | 'lightly_active' | 'active' | 'very_active'
  final String activityLevel;

  /// e.g. {'vegetarian', 'keto'}
  final Set<String> dietaryPreferences;

  // Editable plan targets (set after TDEE is calculated on plan screen)
  final int dailyCalories;
  final int dailyProteinG;
  final int dailyCarbsG;
  final int dailyFatG;

  const OnboardingState({
    this.goal = 'lose',
    this.gender = 'male',
    this.birthday = '1995-01-01',
    this.currentWeightKg = 70.0,
    this.heightCm = 170.0,
    this.targetWeightKg = 65.0,
    this.activityLevel = 'lightly_active',
    this.dietaryPreferences = const {},
    this.dailyCalories = 0,
    this.dailyProteinG = 0,
    this.dailyCarbsG = 0,
    this.dailyFatG = 0,
  });

  OnboardingState copyWith({
    String? goal,
    String? gender,
    String? birthday,
    double? currentWeightKg,
    double? heightCm,
    double? targetWeightKg,
    String? activityLevel,
    Set<String>? dietaryPreferences,
    int? dailyCalories,
    int? dailyProteinG,
    int? dailyCarbsG,
    int? dailyFatG,
  }) =>
      OnboardingState(
        goal: goal ?? this.goal,
        gender: gender ?? this.gender,
        birthday: birthday ?? this.birthday,
        currentWeightKg: currentWeightKg ?? this.currentWeightKg,
        heightCm: heightCm ?? this.heightCm,
        targetWeightKg: targetWeightKg ?? this.targetWeightKg,
        activityLevel: activityLevel ?? this.activityLevel,
        dietaryPreferences: dietaryPreferences ?? this.dietaryPreferences,
        dailyCalories: dailyCalories ?? this.dailyCalories,
        dailyProteinG: dailyProteinG ?? this.dailyProteinG,
        dailyCarbsG: dailyCarbsG ?? this.dailyCarbsG,
        dailyFatG: dailyFatG ?? this.dailyFatG,
      );
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class OnboardingNotifier extends Notifier<OnboardingState> {
  @override
  OnboardingState build() => const OnboardingState();

  void setGoal(String v) => state = state.copyWith(goal: v);
  void setGender(String v) => state = state.copyWith(gender: v);
  void setBirthday(String v) => state = state.copyWith(birthday: v);
  void setCurrentWeight(double v) =>
      state = state.copyWith(currentWeightKg: v);
  void setHeight(double v) => state = state.copyWith(heightCm: v);
  void setTargetWeight(double v) =>
      state = state.copyWith(targetWeightKg: v);
  void setActivityLevel(String v) =>
      state = state.copyWith(activityLevel: v);
  void toggleDiet(String pref) {
    final prefs = Set<String>.from(state.dietaryPreferences);
    if (prefs.contains(pref)) {
      prefs.remove(pref);
    } else {
      prefs.add(pref);
    }
    state = state.copyWith(dietaryPreferences: prefs);
  }

  void setPlanTargets({
    required int calories,
    required int proteinG,
    required int carbsG,
    required int fatG,
  }) =>
      state = state.copyWith(
        dailyCalories: calories,
        dailyProteinG: proteinG,
        dailyCarbsG: carbsG,
        dailyFatG: fatG,
      );
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final onboardingProvider =
    NotifierProvider<OnboardingNotifier, OnboardingState>(
  OnboardingNotifier.new,
);
