import 'dart:convert';

import 'package:http/http.dart' as http;

// ─── Data ─────────────────────────────────────────────────────────────────────

class FoodSearchResult {
  final int fdcId;
  final String name;
  final String brandOwner;
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final String servingSize;

  const FoodSearchResult({
    required this.fdcId,
    required this.name,
    this.brandOwner = '',
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.servingSize = '100g',
  });
}

// ─── Service ──────────────────────────────────────────────────────────────────

class UsdaService {
  static const _base = 'https://api.nal.usda.gov/fdc/v1';

  final String apiKey;
  const UsdaService({required this.apiKey});

  Future<List<FoodSearchResult>> searchFoods(String query,
      {int pageSize = 25}) async {
    final uri = Uri.parse('$_base/foods/search').replace(queryParameters: {
      'query': query,
      'api_key': apiKey,
      'pageSize': '$pageSize',
      'dataType': 'Branded,Survey (FNDDS),SR Legacy',
    });

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('USDA API error ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final foods = body['foods'] as List? ?? [];

    return foods
        .map((f) => _parse(f as Map<String, dynamic>))
        .whereType<FoodSearchResult>()
        .toList();
  }

  FoodSearchResult? _parse(Map<String, dynamic> f) {
    try {
      final nutrients = (f['foodNutrients'] as List? ?? [])
          .cast<Map<String, dynamic>>();

      double nutrientValue(String name) {
        final match = nutrients.firstWhere(
          (n) =>
              (n['nutrientName'] as String? ?? '')
                  .toLowerCase()
                  .contains(name.toLowerCase()),
          orElse: () => {},
        );
        return (match['value'] as num?)?.toDouble() ?? 0.0;
      }

      // Prefer Energy (kcal); fall back to "energy" match
      double calories = 0;
      for (final n in nutrients) {
        final name = (n['nutrientName'] as String? ?? '').toLowerCase();
        final unit = (n['unitName'] as String? ?? '').toLowerCase();
        if (name.contains('energy') && unit == 'kcal') {
          calories = (n['value'] as num?)?.toDouble() ?? 0;
          break;
        }
      }

      final servingSize = f['servingSize'] != null
          ? '${f['servingSize']}${f['servingSizeUnit'] ?? 'g'}'
          : '100g';

      return FoodSearchResult(
        fdcId: f['fdcId'] as int,
        name: f['description'] as String? ?? 'Unknown',
        brandOwner: f['brandOwner'] as String? ?? '',
        calories: calories,
        proteinG: nutrientValue('protein'),
        carbsG: nutrientValue('carbohydrate'),
        fatG: nutrientValue('total lipid'),
        servingSize: servingSize,
      );
    } catch (_) {
      return null;
    }
  }
}
