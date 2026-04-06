// Unit conversion utilities.
//
// Internal storage is always metric (kg, cm, ml).
// These helpers are used for display only.

// ─── Weight ───────────────────────────────────────────────────────────────────

double kgToLbs(double kg) => kg * 2.20462;
double lbsToKg(double lbs) => lbs / 2.20462;

// ─── Height ───────────────────────────────────────────────────────────────────

/// Returns a (feet, inches) record from centimetres.
(int feet, int inches) cmToFtIn(double cm) {
  final totalInches = cm / 2.54;
  final feet = (totalInches / 12).floor();
  final inches = (totalInches % 12).round();
  return (feet, inches);
}

double ftInToCm(int feet, int inches) => feet * 30.48 + inches * 2.54;

// ─── Volume ───────────────────────────────────────────────────────────────────

double mlToOz(double ml) => ml * 0.033814;
double ozToMl(double oz) => oz / 0.033814;

// ─── Date helpers ─────────────────────────────────────────────────────────────

/// Formats a [DateTime] as a 'YYYY-MM-DD' string for DB storage and lookups.
String dateString(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

// ─── Display helpers ──────────────────────────────────────────────────────────

/// Formats a weight value for display given the current unit preference.
String formatWeight(double kg, String unit) {
  if (unit == 'lbs') {
    return '${kgToLbs(kg).toStringAsFixed(1)} lbs';
  }
  return '${kg.toStringAsFixed(1)} kg';
}

/// Formats a height value for display given the current unit preference.
String formatHeight(double cm, String unit) {
  if (unit == 'lbs') {
    final (ft, inches) = cmToFtIn(cm);
    return "$ft' $inches\"";
  }
  return '${cm.toStringAsFixed(0)} cm';
}

// ─── Servings display ─────────────────────────────────────────────────────────

/// Formats a servings value: shows integer form when whole, decimal otherwise.
String fmtServings(double v) =>
    v == v.truncateToDouble() ? '${v.toInt()}' : '$v';
