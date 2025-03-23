// We'll update the CalorieTrackerScreen and add new screens for meal functionality

// screens/calorie_tracker_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/meal.dart';
import '../models/food_item.dart';
import '../models/daily_nutrition.dart';
import '../providers/nutrition_provider.dart';
import '../providers/user_provider.dart';

class CalorieTrackerScreen extends StatefulWidget {
  const CalorieTrackerScreen({super.key});

  @override
  State<CalorieTrackerScreen> createState() => _CalorieTrackerScreenState();
}

class _CalorieTrackerScreenState extends State<CalorieTrackerScreen> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    // Load data for today
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final nutritionProvider = Provider.of<NutritionProvider>(context, listen: false);
    await nutritionProvider.changeSelectedDate(_selectedDate);

    // Update nutrition goals based on user profile
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.userProfile != null) {
      final profile = userProvider.userProfile!;
      final calorieGoal = profile.calculateDailyCalorieGoal();
      await nutritionProvider.updateDailyNutrition(
        calorieGoal,
        profile.macroDistribution,
      );
    }
  }

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2025),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });

      final nutritionProvider = Provider.of<NutritionProvider>(context, listen: false);
      await nutritionProvider.changeSelectedDate(_selectedDate);

      // Update nutrition goals based on user profile
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.userProfile != null) {
        final profile = userProvider.userProfile!;
        final calorieGoal = profile.calculateDailyCalorieGoal();
        await nutritionProvider.updateDailyNutrition(
          calorieGoal,
          profile.macroDistribution,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<NutritionProvider, UserProvider>(
      builder: (context, nutritionProvider, userProvider, child) {
        final dailyNutrition = nutritionProvider.dailyNutrition;
        final meals = nutritionProvider.meals;
        final isLoading = nutritionProvider.isLoading;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Calorie Tracker',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _selectDate(context),
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(
                            DateFormat('MMMM d, yyyy').format(_selectedDate),
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: _loadData,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Display the calorie progress card
                if (isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (dailyNutrition != null)
                  CalorieProgressCard(dailyNutrition: dailyNutrition)
                else
                  const Center(child: Text("No nutrition data available")),

                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Today\'s Meals',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _navigateToAddMeal(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Meal'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Display the list of meals
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : meals.isEmpty
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.no_food,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No meals added yet',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => _navigateToAddMeal(context),
                          child: const Text('Add Your First Meal'),
                        ),
                      ],
                    ),
                  )
                      : ListView.builder(
                    itemCount: meals.length,
                    itemBuilder: (context, index) {
                      return MealCard(
                        meal: meals[index],
                        onEdit: () => _navigateToEditMeal(context, meals[index]),
                        onDelete: () => _deleteMeal(context, meals[index].id),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateToAddMeal(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddMealScreen(selectedDate: _selectedDate),
      ),
    );
  }

  void _navigateToEditMeal(BuildContext context, Meal meal) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditMealScreen(meal: meal),
      ),
    );
  }

  Future<void> _deleteMeal(BuildContext context, String mealId) async {
    // Show confirmation dialog
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Meal'),
        content: const Text('Are you sure you want to delete this meal?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;

    if (shouldDelete) {
      final nutritionProvider = Provider.of<NutritionProvider>(context, listen: false);
      await nutritionProvider.deleteMeal(mealId);

      // Update daily nutrition after deleting
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.userProfile != null) {
        final profile = userProvider.userProfile!;
        final calorieGoal = profile.calculateDailyCalorieGoal();
        await nutritionProvider.updateDailyNutrition(
          calorieGoal,
          profile.macroDistribution,
        );
      }
    }
  }
}

class CalorieProgressCard extends StatelessWidget {
  final DailyNutrition dailyNutrition;

  const CalorieProgressCard({
    super.key,
    required this.dailyNutrition,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daily Goal',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      dailyNutrition.totalCalories.toInt().toString(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      ' / ${dailyNutrition.calorieGoal.toInt()} kcal',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: dailyNutrition.calorieProgress > 1 ? 1 : dailyNutrition.calorieProgress,
                backgroundColor: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NutrientProgress(
                  title: 'Protein',
                  current: dailyNutrition.totalProtein,
                  goal: dailyNutrition.proteinGoal,
                  color: Colors.red.shade400,
                ),
                _NutrientProgress(
                  title: 'Carbs',
                  current: dailyNutrition.totalCarbs,
                  goal: dailyNutrition.carbsGoal,
                  color: Colors.green.shade400,
                ),
                _NutrientProgress(
                  title: 'Fat',
                  current: dailyNutrition.totalFat,
                  goal: dailyNutrition.fatGoal,
                  color: Colors.blue.shade400,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NutrientProgress extends StatelessWidget {
  final String title;
  final double current;
  final double goal;
  final Color color;

  const _NutrientProgress({
    required this.title,
    required this.current,
    required this.goal,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (current / goal).clamp(0.0, 1.0);

    return Column(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 60,
          width: 60,
          child: Stack(
            children: [
              CircularProgressIndicator(
                value: progress,
                backgroundColor: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                strokeWidth: 8,
              ),
              Center(
                child: Text(
                  '${(progress * 100).toInt()}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${current.toInt()}/${goal.toInt()}g',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      ],
    );
  }
}

class MealCard extends StatelessWidget {
  final Meal meal;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MealCard({
    super.key,
    required this.meal,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      meal.type == MealType.breakfast
                          ? Icons.wb_sunny
                          : meal.type == MealType.lunch
                          ? Icons.wb_twilight
                          : meal.type == MealType.dinner
                          ? Icons.nights_stay
                          : Icons.fastfood,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      meal.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      DateFormat('h:mm a').format(meal.dateTime),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${meal.totalCalories.toInt()} kcal',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...meal.items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.circle,
                        size: 8,
                      ),
                      const SizedBox(width: 8),
                      Text(item.foodItem.name),
                    ],
                  ),
                  Text(
                    '${(item.foodItem.calories * item.quantity).toInt()} kcal',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      '${meal.totalProtein.toInt()}g',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Protein',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      '${meal.totalCarbs.toInt()}g',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Carbs',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      '${meal.totalFat.toInt()}g',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Fat',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit meal',
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete),
                  tooltip: 'Delete meal',
                  color: Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Add Meal Screen
class AddMealScreen extends StatefulWidget {
  final DateTime selectedDate;

  const AddMealScreen({
    super.key,
    required this.selectedDate,
  });

  @override
  State<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  MealType _selectedMealType = MealType.breakfast;
  final List<MealItem> _selectedItems = [];
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Meal'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Meal name field
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Meal Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a meal name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Meal type dropdown
            DropdownButtonFormField<MealType>(
              value: _selectedMealType,
              decoration: const InputDecoration(
                labelText: 'Meal Type',
                border: OutlineInputBorder(),
              ),
              items: MealType.values.map((type) {
                return DropdownMenuItem<MealType>(
                  value: type,
                  child: Text(type.toString().split('.').last.capitalize()),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedMealType = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Time picker
            ListTile(
              title: const Text('Time'),
              subtitle: Text(_selectedTime.format(context)),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final TimeOfDay? picked = await showTimePicker(
                  context: context,
                  initialTime: _selectedTime,
                );
                if (picked != null && picked != _selectedTime) {
                  setState(() {
                    _selectedTime = picked;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Food items section
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Food Items',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // List of selected food items
                    if (_selectedItems.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Text('No food items added yet'),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _selectedItems.length,
                        itemBuilder: (context, index) {
                          final item = _selectedItems[index];
                          return ListTile(
                            title: Text(item.foodItem.name),
                            subtitle: Text(
                              'Quantity: ${item.quantity.toStringAsFixed(1)} - '
                                  '${(item.foodItem.calories * item.quantity).toInt()} kcal',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              color: Colors.red,
                              onPressed: () {
                                setState(() {
                                  _selectedItems.removeAt(index);
                                });
                              },
                            ),
                          );
                        },
                      ),

                    // Add food item button
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () => _navigateToAddFoodItem(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Food Item'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Notes field
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Save button
            ElevatedButton(
              onPressed: _saveMeal,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Save Meal'),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToAddFoodItem(BuildContext context) async {
    final result = await Navigator.of(context).push<MealItem>(
      MaterialPageRoute(
        builder: (_) => const AddFoodItemScreen(),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedItems.add(result);
      });
    }
  }

  void _saveMeal() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please add at least one food item'),
          ),
        );
        return;
      }

      // Create DateTime with selected date and time
      final dateTime = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      // Save meal
      final nutritionProvider = Provider.of<NutritionProvider>(context, listen: false);
      await nutritionProvider.addMeal(
        _nameController.text,
        _selectedMealType,
        dateTime,
        _selectedItems,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      // Update daily nutrition after adding meal
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.userProfile != null) {
        final profile = userProvider.userProfile!;
        final calorieGoal = profile.calculateDailyCalorieGoal();
        await nutritionProvider.updateDailyNutrition(
          calorieGoal,
          profile.macroDistribution,
        );
      }

      Navigator.of(context).pop();
    }
  }
}

// Edit Meal Screen
class EditMealScreen extends StatefulWidget {
  final Meal meal;

  const EditMealScreen({
    super.key,
    required this.meal,
  });

  @override
  State<EditMealScreen> createState() => _EditMealScreenState();
}

class _EditMealScreenState extends State<EditMealScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _notesController;

  late MealType _selectedMealType;
  late List<MealItem> _selectedItems;
  late TimeOfDay _selectedTime;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.meal.name);
    _notesController = TextEditingController(text: widget.meal.notes);
    _selectedMealType = widget.meal.type;
    _selectedItems = List.from(widget.meal.items);
    _selectedTime = TimeOfDay(
      hour: widget.meal.dateTime.hour,
      minute: widget.meal.dateTime.minute,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Meal'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Meal name field
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Meal Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a meal name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Meal type dropdown
            DropdownButtonFormField<MealType>(
              value: _selectedMealType,
              decoration: const InputDecoration(
                labelText: 'Meal Type',
                border: OutlineInputBorder(),
              ),
              items: MealType.values.map((type) {
                return DropdownMenuItem<MealType>(
                  value: type,
                  child: Text(type.toString().split('.').last.capitalize()),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedMealType = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Time picker
            ListTile(
              title: const Text('Time'),
              subtitle: Text(_selectedTime.format(context)),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final TimeOfDay? picked = await showTimePicker(
                  context: context,
                  initialTime: _selectedTime,
                );
                if (picked != null && picked != _selectedTime) {
                  setState(() {
                    _selectedTime = picked;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Food items section
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Food Items',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // List of selected food items
                    if (_selectedItems.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Text('No food items added yet'),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _selectedItems.length,
                        itemBuilder: (context, index) {
                          final item = _selectedItems[index];
                          return ListTile(
                            title: Text(item.foodItem.name),
                            subtitle: Text(
                              'Quantity: ${item.quantity.toStringAsFixed(1)} - '
                                  '${(item.foodItem.calories * item.quantity).toInt()} kcal',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              color: Colors.red,
                              onPressed: () {
                                setState(() {
                                  _selectedItems.removeAt(index);
                                });
                              },
                            ),
                          );
                        },
                      ),

                    // Add food item button
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () => _navigateToAddFoodItem(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Food Item'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Notes field
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Update button
            ElevatedButton(
              onPressed: _updateMeal,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Update Meal'),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToAddFoodItem(BuildContext context) async {
    final result = await Navigator.of(context).push<MealItem>(
      MaterialPageRoute(
        builder: (_) => const AddFoodItemScreen(),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedItems.add(result);
      });
    }
  }

  void _updateMeal() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please add at least one food item'),
          ),
        );
        return;
      }

      // Create DateTime with original date and selected time
      final originalDate = widget.meal.dateTime;
      final dateTime = DateTime(
        originalDate.year,
        originalDate.month,
        originalDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      // Update meal
      final updatedMeal = Meal(
        id: widget.meal.id,
        name: _nameController.text,
        type: _selectedMealType,
        dateTime: dateTime,
        items: _selectedItems,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      final nutritionProvider = Provider.of<NutritionProvider>(context, listen: false);
      await nutritionProvider.updateMeal(updatedMeal);

      // Update daily nutrition after updating meal
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.userProfile != null) {
        final profile = userProvider.userProfile!;
        final calorieGoal = profile.calculateDailyCalorieGoal();
        await nutritionProvider.updateDailyNutrition(
          calorieGoal,
          profile.macroDistribution,
        );
      }

      Navigator.of(context).pop();
    }
  }
}

// Add Food Item Screen
class AddFoodItemScreen extends StatefulWidget {
  const AddFoodItemScreen({super.key});

  @override
  State<AddFoodItemScreen> createState() => _AddFoodItemScreenState();
}

class _AddFoodItemScreenState extends State<AddFoodItemScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(text: '1.0');

  FoodItem? _selectedFoodItem;
  List<FoodItem> _searchResults = [];
  bool _isLoading = false;
  bool _isCustomFood = false;

  // Controllers for custom food
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _proteinController = TextEditingController();
  final TextEditingController _carbsController = TextEditingController();
  final TextEditingController _fatController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitialFoodItems();
  }

  Future<void> _loadInitialFoodItems() async {
    setState(() {
      _isLoading = true;
    });

    final nutritionProvider = Provider.of<NutritionProvider>(context, listen: false);
    _searchResults = await nutritionProvider.searchFoodItems('');

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _quantityController.dispose();
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Food Item'),
        actions: [
          IconButton(
            icon: Icon(_isCustomFood ? Icons.list : Icons.add),
            onPressed: () {
              setState(() {
                _isCustomFood = !_isCustomFood;
              });
            },
            tooltip: _isCustomFood ? 'Search Food' : 'Add Custom Food',
          ),
        ],
      ),
      body: _isCustomFood
          ? _buildCustomFoodForm()
          : _buildSearchFoodForm(),
    );
  }

  Widget _buildSearchFoodForm() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search Food',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: _searchFood,
              ),
            ),
            onSubmitted: (_) => _searchFood(),
          ),
        ),

        // Results or loading indicator
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _searchResults.isEmpty
              ? const Center(child: Text('No food items found'))
              : ListView.builder(
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final foodItem = _searchResults[index];
              return ListTile(
                title: Text(foodItem.name),
                subtitle: Text(
                  '${foodItem.calories.toInt()} kcal | '
                      'P: ${foodItem.protein.toInt()}g | '
                      'C: ${foodItem.carbs.toInt()}g | '
                      'F: ${foodItem.fat.toInt()}g',
                ),
                onTap: () {
                  setState(() {
                    _selectedFoodItem = foodItem;
                  });
                  _showQuantityDialog(context);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCustomFoodForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add Custom Food',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Name field
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Food Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // Calories field
          TextFormField(
            controller: _caloriesController,
            decoration: const InputDecoration(
              labelText: 'Calories (per 100g)',
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),

          // Protein field
          TextFormField(
            controller: _proteinController,
            decoration: const InputDecoration(
              labelText: 'Protein (g per 100g)',
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),

          // Carbs field
          TextFormField(
            controller: _carbsController,
            decoration: const InputDecoration(
              labelText: 'Carbs (g per 100g)',
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),

          // Fat field
          TextFormField(
            controller: _fatController,
            decoration: const InputDecoration(
              labelText: 'Fat (g per 100g)',
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 24),

          // Add button
          ElevatedButton(
            onPressed: _addCustomFood,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text('Add Custom Food'),
          ),
        ],
      ),
    );
  }

  void _searchFood() async {
    setState(() {
      _isLoading = true;
    });

    final nutritionProvider = Provider.of<NutritionProvider>(context, listen: false);
    _searchResults = await nutritionProvider.searchFoodItems(_searchController.text);

    setState(() {
      _isLoading = false;
    });
  }

  void _showQuantityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Quantity for ${_selectedFoodItem!.name}'),
        content: TextField(
          controller: _quantityController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Quantity (servings)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final quantity = double.tryParse(_quantityController.text) ?? 1.0;

              final mealItem = MealItem(
                foodItem: _selectedFoodItem!,
                quantity: quantity,
              );

              Navigator.of(context).pop();
              Navigator.of(context).pop(mealItem);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _addCustomFood() async {
    // Validate inputs
    if (_nameController.text.isEmpty ||
        _caloriesController.text.isEmpty ||
        _proteinController.text.isEmpty ||
        _carbsController.text.isEmpty ||
        _fatController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields'),
        ),
      );
      return;
    }

    // Parse inputs
    final name = _nameController.text;
    final calories = double.tryParse(_caloriesController.text) ?? 0;
    final protein = double.tryParse(_proteinController.text) ?? 0;
    final carbs = double.tryParse(_carbsController.text) ?? 0;
    final fat = double.tryParse(_fatController.text) ?? 0;

    // Create custom food item
    final uuid = const Uuid();
    final customFoodItem = FoodItem(
      id: 'custom_${uuid.v4()}',
      name: name,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      description: 'Custom food item',
    );

    // Save custom food item
    final nutritionProvider = Provider.of<NutritionProvider>(context, listen: false);
    await nutritionProvider.addFoodItem(customFoodItem);

    // Return meal item with custom food
    final mealItem = MealItem(
      foodItem: customFoodItem,
      quantity: 1.0,
    );

    // Navigate back with the new meal item
    if (mounted) {
      Navigator.of(context).pop(mealItem);
    }
  }
}

// Extension to capitalize the first letter of a string
extension StringExtension on String {
  String capitalize() {
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}