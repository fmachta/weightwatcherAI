// repositories/meal_repository.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/meal.dart';
import '../models/daily_nutrition.dart';

class MealRepository {
  static const String _mealsKey = 'meals';

  // Save a meal
  Future<void> saveMeal(Meal meal) async {
    final prefs = await SharedPreferences.getInstance();
    final mealsJson = prefs.getStringList(_mealsKey) ?? [];

    // Check if the meal already exists (update)
    final index = mealsJson.indexWhere((json) {
      final existingMeal = Meal.fromJson(jsonDecode(json));
      return existingMeal.id == meal.id;
    });

    if (index >= 0) {
      // Update existing meal
      mealsJson[index] = jsonEncode(meal.toJson());
    } else {
      // Add new meal
      mealsJson.add(jsonEncode(meal.toJson()));
    }

    await prefs.setStringList(_mealsKey, mealsJson);
  }

  // Get all meals
  Future<List<Meal>> getAllMeals() async {
    final prefs = await SharedPreferences.getInstance();
    final mealsJson = prefs.getStringList(_mealsKey) ?? [];

    return mealsJson
        .map((json) => Meal.fromJson(jsonDecode(json)))
        .toList();
  }

  // Get meals for a specific date
  Future<List<Meal>> getMealsForDate(DateTime date) async {
    final allMeals = await getAllMeals();

    return allMeals.where((meal) {
      return meal.dateTime.year == date.year &&
          meal.dateTime.month == date.month &&
          meal.dateTime.day == date.day;
    }).toList();
  }

  // Get daily nutrition for a specific date
  Future<DailyNutrition> getDailyNutrition(
      DateTime date, double calorieGoal, Map<String, double> macroDistribution) async {
    final meals = await getMealsForDate(date);

    final proteinGoal = calorieGoal * macroDistribution['protein']! / 4; // 4 calories per gram
    final carbsGoal = calorieGoal * macroDistribution['carbs']! / 4; // 4 calories per gram
    final fatGoal = calorieGoal * macroDistribution['fat']! / 9; // 9 calories per gram

    return DailyNutrition(
      date: date,
      meals: meals,
      calorieGoal: calorieGoal,
      proteinGoal: proteinGoal,
      carbsGoal: carbsGoal,
      fatGoal: fatGoal,
    );
  }

  // Delete a meal
  Future<void> deleteMeal(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final mealsJson = prefs.getStringList(_mealsKey) ?? [];

    final meals = mealsJson
        .map((json) => Meal.fromJson(jsonDecode(json)))
        .toList();

    // Remove the meal with the given id
    meals.removeWhere((meal) => meal.id == id);

    // Save the updated list
    await prefs.setStringList(
      _mealsKey,
      meals.map((meal) => jsonEncode(meal.toJson())).toList(),
    );
  }
}
