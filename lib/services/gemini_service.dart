import 'dart:convert';

import 'package:http/http.dart' as http;

// ─── Data ─────────────────────────────────────────────────────────────────────

class FoodScanResult {
  final String name;
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final String servingSize;
  final int healthScore;
  final List<String> ingredients;

  const FoodScanResult({
    required this.name,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.servingSize = '1 serving',
    this.healthScore = 5,
    this.ingredients = const [],
  });
}

class GeminiParseException implements Exception {
  final String message;
  const GeminiParseException(this.message);
  @override
  String toString() => 'GeminiParseException: $message';
}

// ─── Service ──────────────────────────────────────────────────────────────────

class GeminiService {
  static const _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  static const _prompt = '''
You are a nutrition analysis AI. Analyze the food in this image and return ONLY a valid JSON object with these fields:
{
  "name": "food name",
  "calories": <number>,
  "protein_g": <number>,
  "carbs_g": <number>,
  "fat_g": <number>,
  "serving_size": "e.g. 1 cup (240g)",
  "health_score": <1-10 integer>,
  "ingredients": ["ingredient1", "ingredient2"]
}
All numbers should be per serving shown in the image. Return only the JSON with no extra text.
''';

  final String apiKey;

  const GeminiService({required this.apiKey});

  Future<FoodScanResult> analyzeFood(
    String base64Image, {
    String? correctionHint,
  }) async {
    final prompt = correctionHint != null
        ? '$_prompt\nUser correction: $correctionHint. Adjust your analysis accordingly.'
        : _prompt;

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt},
            {
              'inline_data': {'mime_type': 'image/jpeg', 'data': base64Image},
            },
          ],
        },
      ],
      'generationConfig': {'temperature': 0.1, 'maxOutputTokens': 512},
    });

    final response = await http.post(
      Uri.parse('$_baseUrl?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode != 200) {
      throw GeminiParseException(
        'API error ${response.statusCode}: ${response.body}',
      );
    }

    return _parse(response.body);
  }

  FoodScanResult _parse(String responseBody) {
    try {
      final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
      final candidates = decoded['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        throw const GeminiParseException('No candidates in response');
      }
      final text = candidates[0]['content']['parts'][0]['text'] as String;

      // Strip possible markdown code fences
      final cleaned = text
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      final data = jsonDecode(cleaned) as Map<String, dynamic>;

      return FoodScanResult(
        name: data['name'] as String? ?? 'Unknown food',
        calories: _toDouble(data['calories']),
        proteinG: _toDouble(data['protein_g']),
        carbsG: _toDouble(data['carbs_g']),
        fatG: _toDouble(data['fat_g']),
        servingSize: data['serving_size'] as String? ?? '1 serving',
        healthScore: (data['health_score'] as num?)?.toInt().clamp(1, 10) ?? 5,
        ingredients:
            (data['ingredients'] as List?)?.map((e) => e.toString()).toList() ??
            [],
      );
    } catch (e) {
      if (e is GeminiParseException) rethrow;
      throw GeminiParseException('Failed to parse response: $e');
    }
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}
