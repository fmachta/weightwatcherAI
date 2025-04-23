import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle; // For loading assets
import 'package:shared_preferences/shared_preferences.dart';
import '../models/food_item.dart';

class FoodRepository {
  static const String _customFoodItemsKey = 'custom_food_items';

  List<FoodItem>? _foundationFoods; // Cache for loaded foundation foods
  bool _isLoadingFoundation = false; // Flag to prevent concurrent loading

  // Save a custom food item
  Future<void> saveCustomFoodItem(FoodItem foodItem) async {
    final prefs = await SharedPreferences.getInstance();
    final customFoodItemsJson = prefs.getStringList(_customFoodItemsKey) ?? [];

    // Add new food item to the list
    customFoodItemsJson.add(jsonEncode(foodItem.toJson()));

    await prefs.setStringList(_customFoodItemsKey, customFoodItemsJson);
  }

  // Get all food items (foundation + custom)
  Future<List<FoodItem>> getAllFoodItems() async {
    // Ensure foundation foods are loaded
    await _ensureFoundationFoodsLoaded();

    final customFoodItems = await getCustomFoodItems();
    // Combine foundation (or empty list if loading failed) and custom items
    return [...(_foundationFoods ?? []), ...customFoodItems];
  }

  // Get custom food items
  Future<List<FoodItem>> getCustomFoodItems() async {
    final prefs = await SharedPreferences.getInstance();
    final customFoodItemsJson = prefs.getStringList(_customFoodItemsKey) ?? [];

    return customFoodItemsJson
        .map((json) {
          try {
            // Added try-catch for robustness
            return FoodItem.fromJson(jsonDecode(json));
          } catch (e) {
            print("Error decoding custom food item from JSON: $json Error: $e");
            return null; // Return null for invalid items
          }
        })
        .whereType<FoodItem>() // Filter out nulls
        .toList();
  }

  // --- Foundation Foods Loading ---

  // Helper to ensure foundation foods are loaded before use
  Future<void> _ensureFoundationFoodsLoaded() async {
     if (_foundationFoods == null && !_isLoadingFoundation) {
      await _loadFoundationFoods();
    }
    // Wait if loading is in progress (basic handling)
    while (_isLoadingFoundation) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  // Load and parse foundation foods from local JSON asset
  Future<void> _loadFoundationFoods() async {
    // Prevent multiple loads and return if already loaded
    if (_isLoadingFoundation || _foundationFoods != null) return;
    _isLoadingFoundation = true;

    print("Loading foundation foods from asset..."); // Log start

    try {
      final String jsonString = await rootBundle.loadString('assets/data/foundation_foods.json');
      final Map<String, dynamic> jsonData = jsonDecode(jsonString);
      final List<dynamic> foundationFoodsList = jsonData['FoundationFoods'] ?? [];

      final List<FoodItem> loadedItems = [];
      int skippedCount = 0; // Count skipped items

      for (var foodData in foundationFoodsList) {
        if (foodData is Map<String, dynamic>) {
          final String? name = foodData['description'];
          // Explicitly check if fdcId is an int
          final dynamic fdcIdRaw = foodData['fdcId'];
          final int? fdcId = (fdcIdRaw is int) ? fdcIdRaw : null;

          final List<dynamic> nutrients = foodData['foodNutrients'] ?? [];

          if (name != null && fdcId != null) { // Check if fdcId is a valid integer
            double calories = 0;
            double protein = 0;
            double carbs = 0;
            double fat = 0;

            for (var nutrientData in nutrients) {
              if (nutrientData is Map<String, dynamic>) {
                final Map<String, dynamic>? nutrientInfo = nutrientData['nutrient'];
                final num? amount = nutrientData['amount']; // Use num? for flexibility

                if (nutrientInfo != null && amount != null) {
                  final String? nutrientName = nutrientInfo['name'];
                  final String? unitName = nutrientInfo['unitName'];

                  // Using lowercase contains for names, exact match for units
                  final lowerNutrientName = nutrientName?.toLowerCase() ?? '';

                  if (lowerNutrientName.contains('energy') && unitName == 'kcal') {
                    calories = amount.toDouble();
                  } else if (lowerNutrientName.contains('protein') && unitName == 'g') {
                    protein = amount.toDouble();
                  } else if (lowerNutrientName.contains('carbohydrate') && unitName == 'g') { // More robust carb match
                    carbs = amount.toDouble();
                  } else if (lowerNutrientName.contains('fat') && unitName == 'g') { // More robust fat match (e.g., 'total lipid (fat)')
                    fat = amount.toDouble();
                  }
                }
              }
            } // End nutrient loop

            // Only add if we have a name and valid ID
            loadedItems.add(FoodItem(
              id: 'foundation_$fdcId', // Prefix ID
              name: name,
              calories: calories,
              protein: protein,
              carbs: carbs,
              fat: fat,
              description: name, // Use name as description for now
            ));
          } else if (name != null && fdcId == null) {
             // Log if an item has a name but invalid/missing fdcId
             print("Skipping item '$name' due to missing or invalid fdcId: $fdcIdRaw");
             skippedCount++;
          }
        } // End if foodData is Map
      } // End foodData loop

      _foundationFoods = loadedItems;
      print("Successfully loaded ${_foundationFoods?.length ?? 0} foundation foods.");
      if (skippedCount > 0) {
        print("Skipped $skippedCount items due to missing/invalid fdcId.");
      }
    } catch (e, stacktrace) { // Catch stacktrace too
      print('Error loading foundation foods: $e'); // Log error
      print('Stacktrace: $stacktrace');
      _foundationFoods = []; // Set to empty list on error to prevent repeated load attempts
    } finally {
      _isLoadingFoundation = false; // Release lock
    }
  }


  // Find food item by name (local foundation + custom)
  Future<List<FoodItem>> findFoodItemsByName(String query) async {
    // 1. Ensure foundation foods are loaded
    await _ensureFoundationFoodsLoaded();

    final lowerCaseQuery = query.toLowerCase();

    // 2. Get custom items
    final customFoodItems = await getCustomFoodItems();

    // 3. Combine foundation and custom items
    // Use ?? [] to handle potential loading errors where _foundationFoods might still be null
    final allLocalItems = [...(_foundationFoods ?? []), ...customFoodItems];

    // 4. Filter combined list
    final Set<String> foundIds = {}; // Avoid duplicates if custom matches foundation
    final List<FoodItem> filteredResults = [];

    if (query.isEmpty) {
      // Return all local items without duplicates if query is empty
      for (var item in allLocalItems) {
        if (foundIds.add(item.id)) {
          filteredResults.add(item);
        }
      }
    } else {
      // Filter by name if query is not empty
      for (var item in allLocalItems) {
        if (item.name.toLowerCase().contains(lowerCaseQuery)) {
           if (foundIds.add(item.id)) {
             filteredResults.add(item);
           }
        }
      }
    }

    // Optional: Sort results
    filteredResults.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return filteredResults;
  }

  // Delete a custom food item
  Future<void> deleteCustomFoodItem(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final customFoodItemsJson = prefs.getStringList(_customFoodItemsKey) ?? [];

    final customFoodItems = customFoodItemsJson
        .map((json) {
          try {
            // Added try-catch for robustness
            return FoodItem.fromJson(jsonDecode(json));
          } catch (e) {
            print("Error decoding custom food item from JSON: $json Error: $e");
            return null; // Return null for invalid items
          }
        })
        .whereType<FoodItem>() // Filter out nulls
        .toList();


    // Remove the food item with the given id
    // Ensure we only try to remove custom items (IDs starting with 'custom_')
    customFoodItems.removeWhere((item) => item.id == id && item.id.startsWith('custom_'));

    // Save the updated list
    await prefs.setStringList(
      _customFoodItemsKey,
      customFoodItems.map((item) => jsonEncode(item.toJson())).toList(),
    );
  }
}
