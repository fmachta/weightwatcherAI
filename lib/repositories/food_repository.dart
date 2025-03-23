import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/food_item.dart';

class FoodRepository {
  static const String _foodItemsKey = 'food_items';
  static const String _customFoodItemsKey = 'custom_food_items';

  // Load predefined food items
  List<FoodItem> _getPredefinedFoodItems() {
    return [
      FoodItem(
        id: 'apple',
        name: 'Apple',
        calories: 52,
        protein: 0.3,
        carbs: 14,
        fat: 0.2,
        description: 'A medium-sized apple',
      ),
      FoodItem(
        id: 'banana',
        name: 'Banana',
        calories: 96,
        protein: 1.2,
        carbs: 23,
        fat: 0.2,
        description: 'A medium-sized banana',
      ),
      FoodItem(
        id: 'chicken_breast',
        name: 'Chicken Breast',
        calories: 165,
        protein: 31,
        carbs: 0,
        fat: 3.6,
        description: '100g of boneless, skinless chicken breast',
      ),
      FoodItem(
        id: 'oatmeal',
        name: 'Oatmeal',
        calories: 68,
        protein: 2.5,
        carbs: 12,
        fat: 1.4,
        description: '100g of cooked oatmeal',
      ),
      FoodItem(
        id: 'salmon',
        name: 'Salmon',
        calories: 206,
        protein: 22,
        carbs: 0,
        fat: 13,
        description: '100g of cooked salmon',
      ),
      FoodItem(
        id: 'broccoli',
        name: 'Broccoli',
        calories: 55,
        protein: 3.7,
        carbs: 11.2,
        fat: 0.6,
        description: '100g of cooked broccoli',
      ),
      FoodItem(
        id: 'brown_rice',
        name: 'Brown Rice',
        calories: 112,
        protein: 2.6,
        carbs: 23.5,
        fat: 0.9,
        description: '100g of cooked brown rice',
      ),
      FoodItem(
        id: 'eggs',
        name: 'Eggs',
        calories: 155,
        protein: 12.6,
        carbs: 0.6,
        fat: 11.5,
        description: '100g of whole eggs (about 2 large eggs)',
      ),
      FoodItem(
        id: 'greek_yogurt',
        name: 'Greek Yogurt',
        calories: 59,
        protein: 10,
        carbs: 3.6,
        fat: 0.4,
        description: '100g of non-fat Greek yogurt',
      ),
      FoodItem(
        id: 'almonds',
        name: 'Almonds',
        calories: 579,
        protein: 21.2,
        carbs: 21.7,
        fat: 49.9,
        description: '100g of almonds',
      ),
    ];
  }

  // Save a custom food item
  Future<void> saveCustomFoodItem(FoodItem foodItem) async {
    final prefs = await SharedPreferences.getInstance();
    final customFoodItemsJson = prefs.getStringList(_customFoodItemsKey) ?? [];

    // Add new food item to the list
    customFoodItemsJson.add(jsonEncode(foodItem.toJson()));

    await prefs.setStringList(_customFoodItemsKey, customFoodItemsJson);
  }

  // Get all food items (predefined + custom)
  Future<List<FoodItem>> getAllFoodItems() async {
    final predefinedFoodItems = _getPredefinedFoodItems();
    final customFoodItems = await getCustomFoodItems();

    return [...predefinedFoodItems, ...customFoodItems];
  }

  // Get custom food items
  Future<List<FoodItem>> getCustomFoodItems() async {
    final prefs = await SharedPreferences.getInstance();
    final customFoodItemsJson = prefs.getStringList(_customFoodItemsKey) ?? [];

    return customFoodItemsJson
        .map((json) => FoodItem.fromJson(jsonDecode(json)))
        .toList();
  }

  // Find food item by name (for search)
  Future<List<FoodItem>> findFoodItemsByName(String query) async {
    final allFoodItems = await getAllFoodItems();

    if (query.isEmpty) {
      return allFoodItems;
    }

    return allFoodItems
        .where((foodItem) =>
        foodItem.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  // Delete a custom food item
  Future<void> deleteCustomFoodItem(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final customFoodItemsJson = prefs.getStringList(_customFoodItemsKey) ?? [];

    final customFoodItems = customFoodItemsJson
        .map((json) => FoodItem.fromJson(jsonDecode(json)))
        .toList();

    // Remove the food item with the given id
    customFoodItems.removeWhere((item) => item.id == id);

    // Save the updated list
    await prefs.setStringList(
      _customFoodItemsKey,
      customFoodItems.map((item) => jsonEncode(item.toJson())).toList(),
    );
  }
}