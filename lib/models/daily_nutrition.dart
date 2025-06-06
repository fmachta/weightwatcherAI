import 'meal.dart';

class DailyNutrition {
  final DateTime date;
  final List<Meal>? meals;
  final double calorieGoal;
  final double proteinGoal;
  final double carbsGoal;
  final double fatGoal;

  DailyNutrition({
    required this.date,
    required this.meals,
    required this.calorieGoal,
    required this.proteinGoal,
    required this.carbsGoal,
    required this.fatGoal,
  });

  // Calculate total calories from all meals
  double get totalCalories =>
      meals?.fold<double>(0, (sum, meal) => sum + (meal.totalCalories)) ?? 0;

  // Calculate total protein from all meals
  double get totalProtein =>
      meals?.fold<double>(0, (sum, meal) => sum + (meal.totalProtein)) ?? 0;

  // Calculate total carbs from all meals
  double get totalCarbs =>
      meals?.fold<double>(0, (sum, meal) => sum + (meal.totalCarbs)) ?? 0;

  // Calculate total fat from all meals
  double get totalFat =>
      meals?.fold<double>(0, (sum, meal) => sum + (meal.totalFat)) ?? 0;

  // Calculate remaining nutritional values
  double get remainingCalories => calorieGoal - totalCalories;
  double get remainingProtein => proteinGoal - totalProtein;
  double get remainingCarbs => carbsGoal - totalCarbs;
  double get remainingFat => fatGoal - totalFat;

  // Calculate progress percentages
  double get calorieProgress => totalCalories / calorieGoal;
  double get proteinProgress => totalProtein / proteinGoal;
  double get carbsProgress => totalCarbs / carbsGoal;
  double get fatProgress => totalFat / fatGoal;

  // Convert to and from JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'meals': meals?.map((meal) => meal.toJson()).toList() ?? [],
      'calorieGoal': calorieGoal,
      'proteinGoal': proteinGoal,
      'carbsGoal': carbsGoal,
      'fatGoal': fatGoal,
    };
  }

  factory DailyNutrition.fromJson(Map<String, dynamic> json) {
    return DailyNutrition(
      date: DateTime.parse(json['date']),
      meals: json['meals'] != null
          ? (json['meals'] as List)
          .map((mealJson) => Meal.fromJson(mealJson))
          .toList()
          : [],
      calorieGoal: json['calorieGoal'],
      proteinGoal: json['proteinGoal'],
      carbsGoal: json['carbsGoal'],
      fatGoal: json['fatGoal'],
    );
  }
}