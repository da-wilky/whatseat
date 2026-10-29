import 'dart:convert';

import 'package:drift/drift.dart';

enum MealType { breakfast, lunch, dinner, snack }

MealType mealTypeForTime(int minutes) {
  final h = minutes ~/ 60;
  if (h >= 5 && h < 10) return MealType.breakfast;
  if (h >= 11 && h < 14) return MealType.lunch;
  if (h >= 17 && h < 21) return MealType.dinner;
  return MealType.snack;
}

class FoodItem {
  const FoodItem({this.quantity, this.unit = '', required this.food});

  final double? quantity;

  /// Stored in singular; pluralised for display.
  final String unit;
  final String food;

  Map<String, dynamic> toJson() => {'quantity': quantity, 'unit': unit, 'food': food};

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    final legacyAmount = json['amount'] as String?;
    if (legacyAmount != null) {
      final match = RegExp(r'^\s*([\d.,]+)?\s*(.*)$').firstMatch(legacyAmount)!;
      return FoodItem(
        quantity: parseQuantity(match[1] ?? ''),
        unit: match[2]!.trim(),
        food: json['food'] as String,
      );
    }
    return FoodItem(
      quantity: (json['quantity'] as num?)?.toDouble(),
      unit: json['unit'] as String? ?? '',
      food: json['food'] as String,
    );
  }
}

double? parseQuantity(String text) => double.tryParse(text.trim().replaceAll(',', '.'));

class FoodItemsConverter extends TypeConverter<List<FoodItem>, String>
    with JsonTypeConverter<List<FoodItem>, String> {
  const FoodItemsConverter();

  @override
  List<FoodItem> fromSql(String fromDb) => [
        for (final e in jsonDecode(fromDb) as List) FoodItem.fromJson(e as Map<String, dynamic>),
      ];

  @override
  String toSql(List<FoodItem> value) => jsonEncode([for (final i in value) i.toJson()]);
}

/// Values are stored as one comma-separated text column so the export matches the paper form.
List<String> splitTags(String value) =>
    value.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

String joinTags(Iterable<String> tags) => tags.join(', ');

String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime parseDayKey(String key) {
  final p = key.split('-').map(int.parse).toList();
  return DateTime(p[0], p[1], p[2]);
}

String formatMinutes(int minutes) =>
    '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';
