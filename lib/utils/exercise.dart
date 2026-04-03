/// MET (Metabolic Equivalent of Task) values for common exercises.
/// Calories burned = MET × weight_kg × duration_hours
const _metValues = {
  'Running': 9.8,
  'Walking': 3.5,
  'Cycling': 7.5,
  'Strength Training': 5.0,
  'HIIT': 10.0,
  'Swimming': 8.0,
  'Yoga': 2.5,
  'Pilates': 3.0,
  'Jump Rope': 11.0,
  'Rowing': 7.0,
  'Elliptical': 5.0,
  'Stair Climbing': 8.0,
  'Dancing': 5.5,
  'Hiking': 6.0,
  'Basketball': 8.0,
};

const List<String> kExerciseSuggestions = [
  'Running',
  'Walking',
  'Cycling',
  'Strength Training',
  'HIIT',
  'Swimming',
  'Yoga',
  'Pilates',
  'Jump Rope',
  'Rowing',
  'Elliptical',
  'Stair Climbing',
  'Dancing',
  'Hiking',
  'Basketball',
];

/// Estimate calories burned using MET formula.
/// [weightKg] defaults to 70 kg if profile not available.
double estimateCaloriesBurned({
  required String exerciseName,
  required int durationMinutes,
  double weightKg = 70.0,
}) {
  final met = _metValues[exerciseName] ?? 5.0;
  return met * weightKg * (durationMinutes / 60.0);
}
