import 'food_item.dart';

class Meal {
  final String id;
  final String name;
  final MealType type;
  final DateTime dateTime;
  final List<MealItem> items;
  final String? notes;
  final List<String>? ingredients;
  final String? cookingInstructions;

  Meal({
    required this.id,
    required this.name,
    required this.type,
    required this.dateTime,
    required this.items,
    this.notes,
    this.ingredients,
    this.cookingInstructions,
  });

  // Calculate total nutritional values
  double get totalCalories =>
      items.fold(0, (sum, item) => sum + (item.foodItem.calories * item.quantity));

  double get totalProtein =>
      items.fold(0, (sum, item) => sum + (item.foodItem.protein * item.quantity));

  double get totalCarbs =>
      items.fold(0, (sum, item) => sum + (item.foodItem.carbs * item.quantity));

  double get totalFat =>
      items.fold(0, (sum, item) => sum + (item.foodItem.fat * item.quantity));

  // Convert to and from JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.toString(),
      'dateTime': dateTime.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      'notes': notes,
      'ingredients': ingredients,
      'cookingInstructions': cookingInstructions,
    };
  }

  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      id: json['id'],
      name: json['name'],
      type: MealType.values.firstWhere(
            (e) => e.toString() == json['type'],
        orElse: () => MealType.other,
      ),
      dateTime: DateTime.parse(json['dateTime']),
      items: (json['items'] as List)
          .map((itemJson) => MealItem.fromJson(itemJson))
          .toList(),
      notes: json['notes'],
      ingredients: json['ingredients'] != null 
          ? List<String>.from(json['ingredients']) 
          : null,
      cookingInstructions: json['cookingInstructions'],
    );
  }
}

// Meal item represents a food item with a specific quantity
class MealItem {
  final FoodItem foodItem;
  final double quantity;
  final String? servingSize;

  MealItem({
    required this.foodItem,
    required this.quantity,
    this.servingSize,
  });

  // Convert to and from JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'foodItem': foodItem.toJson(),
      'quantity': quantity,
      'servingSize': servingSize,
    };
  }

  factory MealItem.fromJson(Map<String, dynamic> json) {
    return MealItem(
      foodItem: FoodItem.fromJson(json['foodItem']),
      quantity: json['quantity'],
      servingSize: json['servingSize'],
    );
  }
}

// Meal types
enum MealType {
  breakfast,
  lunch,
  dinner,
  snack,
  other
}