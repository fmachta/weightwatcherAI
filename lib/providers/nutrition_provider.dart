import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/food_item.dart';
import '../models/meal.dart';
import '../models/daily_nutrition.dart';
import '../repositories/food_repository.dart';
import '../repositories/meal_repository.dart';

class NutritionProvider with ChangeNotifier {
  final FoodRepository _foodRepository = FoodRepository();
  final MealRepository _mealRepository = MealRepository();
  final Uuid _uuid = const Uuid();

  List<FoodItem> _foodItems = [];
  List<Meal> _meals = [];
  DailyNutrition? _dailyNutrition;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  List<FoodItem> get foodItems => _foodItems;
  List<Meal> get meals => _meals;
  DailyNutrition? get dailyNutrition => _dailyNutrition;
  DateTime get selectedDate => _selectedDate;
  bool get isLoading => _isLoading;

  // Initialize nutrition data
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    _foodItems = await _foodRepository.getAllFoodItems();
    await _loadMealsForSelectedDate();

    _isLoading = false;
    notifyListeners();
  }

  // Load meals for selected date
  Future<void> _loadMealsForSelectedDate() async {
    _meals = await _mealRepository.getMealsForDate(_selectedDate);
    notifyListeners();
  }

  // Change selected date
  Future<void> changeSelectedDate(DateTime date) async {
    _selectedDate = date;
    await _loadMealsForSelectedDate();
    notifyListeners();
  }

  // Update daily nutrition (called when user profile changes)
  Future<void> updateDailyNutrition(
      double calorieGoal, Map<String, double> macroDistribution) async {
    _dailyNutrition = await _mealRepository.getDailyNutrition(
        _selectedDate, calorieGoal, macroDistribution);
    notifyListeners();
  }

  // Add a meal
  Future<void> addMeal(
      String name, MealType type, DateTime dateTime, List<MealItem> items, {String? notes}) async {
    _isLoading = true;
    notifyListeners();

    final meal = Meal(
      id: _uuid.v4(),
      name: name,
      type: type,
      dateTime: dateTime,
      items: items,
      notes: notes,
    );

    await _mealRepository.saveMeal(meal);
    await _loadMealsForSelectedDate();

    _isLoading = false;
    notifyListeners();
  }

  // Update a meal
  Future<void> updateMeal(Meal meal) async {
    _isLoading = true;
    notifyListeners();

    await _mealRepository.saveMeal(meal);
    await _loadMealsForSelectedDate();

    _isLoading = false;
    notifyListeners();
  }

  // Delete a meal
  Future<void> deleteMeal(String id) async {
    _isLoading = true;
    notifyListeners();

    await _mealRepository.deleteMeal(id);
    await _loadMealsForSelectedDate();

    _isLoading = false;
    notifyListeners();
  }

  // Add food item
  Future<void> addFoodItem(FoodItem foodItem) async {
    _isLoading = true;
    notifyListeners();

    await _foodRepository.saveCustomFoodItem(foodItem);
    _foodItems = await _foodRepository.getAllFoodItems();

    _isLoading = false;
    notifyListeners();
  }

  // Search food items
  Future<List<FoodItem>> searchFoodItems(String query) async {
    return _foodRepository.findFoodItemsByName(query);
  }

  // Get calorie and nutrition data for week
  Future<List<Map<String, dynamic>>> getWeeklyNutritionData() async {
    final today = DateTime.now();
    final weekStart = today.subtract(Duration(days: today.weekday - 1));

    List<Map<String, dynamic>> weekData = [];

    for (int i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      final meals = await _mealRepository.getMealsForDate(date);

      double totalCalories = 0;
      double totalProtein = 0;
      double totalCarbs = 0;
      double totalFat = 0;

      for (final meal in meals) {
        totalCalories += meal.totalCalories;
        totalProtein += meal.totalProtein;
        totalCarbs += meal.totalCarbs;
        totalFat += meal.totalFat;
      }

      weekData.add({
        'date': date,
        'day': ['M', 'T', 'W', 'T', 'F', 'S', 'S'][i],
        'calories': totalCalories,
        'protein': totalProtein,
        'carbs': totalCarbs,
        'fat': totalFat,
      });
    }

    return weekData;
  }
}