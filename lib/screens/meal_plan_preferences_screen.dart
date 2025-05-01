import 'package:flutter/material.dart';
import '../models/user_profile.dart';

class MealPlanPreferencesScreen extends StatefulWidget {
  final UserProfile userProfile;
  final Function(Map<String, dynamic>) onComplete;

  const MealPlanPreferencesScreen({
    super.key,
    required this.userProfile,
    required this.onComplete,
  });

  @override
  State<MealPlanPreferencesScreen> createState() => _MealPlanPreferencesScreenState();
}

class _MealPlanPreferencesScreenState extends State<MealPlanPreferencesScreen> {
  // Default preferences
  final Map<String, dynamic> _preferences = {
    'dietaryRestrictions': <String>[],
    'mealsPerDay': 3,
    'includeSnacks': true,
    'calorieAdjustment': 0, // -500 to +500 relative to calculated
    'preferredCuisines': <String>[],
    'foodAllergies': '',
    'dislikedFoods': '',
    'otherPreferences': '',
  };
  
  // Options for selections
  final List<String> _dietaryRestrictions = [
    'Vegetarian', 
    'Vegan', 
    'Pescatarian', 
    'Gluten-Free', 
    'Lactose-Free',
    'Keto',
    'Paleo',
    'Low-Carb',
    'Low-Fat',
    'Mediterranean',
  ];
  
  final List<String> _cuisineOptions = [
    'American',
    'Italian',
    'Mexican',
    'Asian',
    'Mediterranean',
    'Indian',
    'Greek',
    'Middle Eastern',
    'Thai',
    'Japanese',
  ];

  final TextEditingController _foodAllergiesController = TextEditingController();
  final TextEditingController _dislikedFoodsController = TextEditingController();
  final TextEditingController _otherPreferencesController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    // Initialize text controllers
    _foodAllergiesController.text = _preferences['foodAllergies'];
    _dislikedFoodsController.text = _preferences['dislikedFoods'];
    _otherPreferencesController.text = _preferences['otherPreferences'];
  }
  
  @override
  void dispose() {
    _foodAllergiesController.dispose();
    _dislikedFoodsController.dispose();
    _otherPreferencesController.dispose();
    super.dispose();
  }

  void _updateDietaryRestriction(String restriction, bool selected) {
    setState(() {
      if (selected) {
        if (!(_preferences['dietaryRestrictions'] as List<String>).contains(restriction)) {
          (_preferences['dietaryRestrictions'] as List<String>).add(restriction);
        }
      } else {
        (_preferences['dietaryRestrictions'] as List<String>).remove(restriction);
      }
    });
  }

  void _updateCuisineSelection(String cuisine, bool selected) {
    setState(() {
      if (selected) {
        if (!(_preferences['preferredCuisines'] as List<String>).contains(cuisine)) {
          (_preferences['preferredCuisines'] as List<String>).add(cuisine);
        }
      } else {
        (_preferences['preferredCuisines'] as List<String>).remove(cuisine);
      }
    });
  }

  void _generatePlan() {
    // Update any final values from controllers
    _preferences['foodAllergies'] = _foodAllergiesController.text;
    _preferences['dislikedFoods'] = _dislikedFoodsController.text;
    _preferences['otherPreferences'] = _otherPreferencesController.text;
    
    // Call the onComplete callback with collected preferences without closing the dialog
    // This passes control back to AITrainerScreen which will handle loading and navigation
    widget.onComplete(_preferences);
    
    // Do not navigate back here - the AITrainerScreen will handle this after plan generation
    // Navigator.of(context).pop() is removed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customize Your Meal Plan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tell us about your dietary preferences',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This helps us create a meal plan that fits your lifestyle',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            
            // Dietary Restrictions Section
            _buildSectionTitle('Do you have any dietary restrictions?'),
            const SizedBox(height: 8),
            _buildDietaryRestrictionSelector(),
            const SizedBox(height: 16),

            // Meals Per Day Section
            _buildSectionTitle('How many meals do you prefer per day?'),
            const SizedBox(height: 8),
            _buildMealsPerDaySelector(),
            const SizedBox(height: 16),

            // Include Snacks Section
            _buildSectionTitle('Do you want to include snacks?'),
            const SizedBox(height: 8),
            _buildSnacksSelector(),
            const SizedBox(height: 16),

            // Calorie Adjustment Section
            _buildSectionTitle('Adjust your daily calorie target'),
            const SizedBox(height: 8),
            Text(
              'Default is based on your profile. Adjust if you want more or fewer calories.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            _buildCalorieAdjustmentSelector(),
            const SizedBox(height: 16),

            // Preferred Cuisines Section
            _buildSectionTitle('What cuisines do you prefer?'),
            const SizedBox(height: 8),
            _buildCuisineSelector(),
            const SizedBox(height: 16),

            // Food Allergies Section
            _buildSectionTitle('Any food allergies?'),
            const SizedBox(height: 8),
            _buildFoodAllergiesField(),
            const SizedBox(height: 16),

            // Disliked Foods Section
            _buildSectionTitle('Any foods you dislike?'),
            const SizedBox(height: 8),
            _buildDislikedFoodsField(),
            const SizedBox(height: 16),

            // Other Preferences Section
            _buildSectionTitle('Any other dietary preferences?'),
            const SizedBox(height: 8),
            _buildOtherPreferencesField(),
            const SizedBox(height: 24),

            // Generate Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _generatePlan,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Generate My Meal Plan'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildDietaryRestrictionSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _dietaryRestrictions.map((restriction) => FilterChip(
        label: Text(restriction),
        selected: (_preferences['dietaryRestrictions'] as List<String>).contains(restriction),
        onSelected: (selected) => _updateDietaryRestriction(restriction, selected),
      )).toList(),
    );
  }

  Widget _buildMealsPerDaySelector() {
    return Slider(
      value: _preferences['mealsPerDay'].toDouble(),
      min: 2,
      max: 6,
      divisions: 4,
      label: '${_preferences['mealsPerDay']} meals',
      onChanged: (double value) {
        setState(() {
          _preferences['mealsPerDay'] = value.round();
        });
      },
    );
  }

  Widget _buildSnacksSelector() {
    return SwitchListTile(
      title: const Text('Include snacks between meals'),
      value: _preferences['includeSnacks'],
      onChanged: (value) {
        setState(() {
          _preferences['includeSnacks'] = value;
        });
      },
    );
  }

  Widget _buildCalorieAdjustmentSelector() {
    return Column(
      children: [
        Slider(
          value: _preferences['calorieAdjustment'].toDouble(),
          min: -500,
          max: 500,
          divisions: 20,
          label: _formatCalorieAdjustment(_preferences['calorieAdjustment']),
          onChanged: (double value) {
            setState(() {
              _preferences['calorieAdjustment'] = value.round();
            });
          },
        ),
        Text(
          _formatCalorieAdjustment(_preferences['calorieAdjustment']),
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _formatCalorieAdjustment(int adjustment) {
    if (adjustment == 0) return 'Default calories';
    if (adjustment > 0) return '+$adjustment calories';
    return '$adjustment calories';
  }

  Widget _buildCuisineSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _cuisineOptions.map((cuisine) => FilterChip(
        label: Text(cuisine),
        selected: (_preferences['preferredCuisines'] as List<String>).contains(cuisine),
        onSelected: (selected) => _updateCuisineSelection(cuisine, selected),
      )).toList(),
    );
  }

  Widget _buildFoodAllergiesField() {
    return TextField(
      controller: _foodAllergiesController,
      decoration: InputDecoration(
        hintText: 'e.g., peanuts, shellfish, etc. (optional)',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      maxLines: 2,
    );
  }

  Widget _buildDislikedFoodsField() {
    return TextField(
      controller: _dislikedFoodsController,
      decoration: InputDecoration(
        hintText: 'e.g., broccoli, olives, etc. (optional)',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      maxLines: 2,
    );
  }

  Widget _buildOtherPreferencesField() {
    return TextField(
      controller: _otherPreferencesController,
      decoration: InputDecoration(
        hintText: 'Any other notes about your meal preferences (optional)',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      maxLines: 3,
    );
  }
} 