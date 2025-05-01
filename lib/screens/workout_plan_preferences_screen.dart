import 'package:flutter/material.dart';
import '../models/user_profile.dart';

class WorkoutPlanPreferencesScreen extends StatefulWidget {
  final UserProfile userProfile;
  final Function(Map<String, dynamic>) onComplete;

  const WorkoutPlanPreferencesScreen({
    super.key,
    required this.userProfile,
    required this.onComplete,
  });

  @override
  State<WorkoutPlanPreferencesScreen> createState() => _WorkoutPlanPreferencesScreenState();
}

class _WorkoutPlanPreferencesScreenState extends State<WorkoutPlanPreferencesScreen> {
  // Default preferences
  final Map<String, dynamic> _preferences = {
    'primaryGoal': null,
    'fitnessLevel': 'Intermediate',
    'daysPerWeek': 4,
    'workoutDuration': 45,
    'exerciseTypes': <String>[],
    'equipment': <String>[],
    'specificFocus': '',
    'otherPreferences': '',
  };
  
  // Options for selections
  final List<String> _fitnessLevels = ['Beginner', 'Intermediate', 'Advanced'];
  final List<String> _exerciseTypes = [
    'Strength Training', 
    'Cardio', 
    'HIIT', 
    'Calisthenics', 
    'Functional Training',
    'Yoga/Flexibility'
  ];
  final List<String> _equipmentOptions = [
    'None/Bodyweight Only',
    'Dumbbells', 
    'Barbell/Rack', 
    'Resistance Bands', 
    'Kettlebells',
    'Pull-up Bar',
    'Cardio Machine', 
    'Full Gym Access'
  ];
  final List<String> _bodyFocusOptions = [
    'Upper Body',
    'Lower Body',
    'Core/Abs',
    'Back',
    'Arms',
    'Chest',
    'Shoulders',
    'Legs',
    'Glutes',
    'Full Body'
  ];

  final TextEditingController _otherPreferencesController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    // Initialize preferences based on user profile
    _preferences['primaryGoal'] = widget.userProfile.fitnessGoal.name;
    _otherPreferencesController.text = _preferences['otherPreferences'];
  }
  
  @override
  void dispose() {
    _otherPreferencesController.dispose();
    super.dispose();
  }

  void _updateExerciseTypeSelection(String type, bool selected) {
    setState(() {
      if (selected) {
        if (!(_preferences['exerciseTypes'] as List<String>).contains(type)) {
          (_preferences['exerciseTypes'] as List<String>).add(type);
        }
      } else {
        (_preferences['exerciseTypes'] as List<String>).remove(type);
      }
    });
  }

  void _updateEquipmentSelection(String equipment, bool selected) {
    setState(() {
      if (selected) {
        if (!(_preferences['equipment'] as List<String>).contains(equipment)) {
          (_preferences['equipment'] as List<String>).add(equipment);
        }
      } else {
        (_preferences['equipment'] as List<String>).remove(equipment);
      }
    });
  }

  void _generatePlan() {
    // Update any final values from controllers
    _preferences['otherPreferences'] = _otherPreferencesController.text;
    
    // Make sure specificFocus has a value (even if empty)
    _preferences['specificFocus'] ??= '';
    
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
        title: const Text('Customize Your Workout Plan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tell us more about your workout preferences',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This helps us create a more personalized plan that fits your needs',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            
            // Fitness Goal Section
            _buildSectionTitle('What is your primary fitness goal?'),
            const SizedBox(height: 8),
            _buildGoalSelection(),
            const SizedBox(height: 16),

            // Fitness Level Section
            _buildSectionTitle('Your fitness level'),
            const SizedBox(height: 8),
            _buildFitnessLevelSelector(),
            const SizedBox(height: 16),

            // Days Per Week Section
            _buildSectionTitle('How many days can you workout each week?'),
            const SizedBox(height: 8),
            _buildDaysPerWeekSelector(),
            const SizedBox(height: 16),

            // Workout Duration Section
            _buildSectionTitle('Preferred workout duration (minutes)'),
            const SizedBox(height: 8),
            _buildWorkoutDurationSelector(),
            const SizedBox(height: 16),

            // Exercise Types Section
            _buildSectionTitle('What types of exercises do you prefer?'),
            const SizedBox(height: 8),
            _buildExerciseTypeSelector(),
            const SizedBox(height: 16),

            // Equipment Section
            _buildSectionTitle('What equipment do you have access to?'),
            const SizedBox(height: 8),
            _buildEquipmentSelector(),
            const SizedBox(height: 16),

            // Specific Focus Section
            _buildSectionTitle('Any specific body parts you want to focus on?'),
            const SizedBox(height: 8),
            _buildSpecificFocusField(),
            const SizedBox(height: 16),

            // Other Preferences Section
            _buildSectionTitle('Any other preferences or limitations?'),
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
                child: const Text('Generate My Workout Plan'),
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

  Widget _buildGoalSelection() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surfaceContainerLow,
      ),
      child: Column(
        children: [
          RadioListTile<String>(
            title: const Text('Weight Loss'),
            value: 'Weight Loss',
            groupValue: _preferences['primaryGoal'],
            onChanged: (value) {
              setState(() {
                _preferences['primaryGoal'] = value;
              });
            },
          ),
          RadioListTile<String>(
            title: const Text('Muscle Gain'),
            value: 'Muscle Gain',
            groupValue: _preferences['primaryGoal'],
            onChanged: (value) {
              setState(() {
                _preferences['primaryGoal'] = value;
              });
            },
          ),
          RadioListTile<String>(
            title: const Text('Improve Fitness/Endurance'),
            value: 'Fitness',
            groupValue: _preferences['primaryGoal'],
            onChanged: (value) {
              setState(() {
                _preferences['primaryGoal'] = value;
              });
            },
          ),
          RadioListTile<String>(
            title: const Text('Maintain Current Fitness'),
            value: 'Maintenance',
            groupValue: _preferences['primaryGoal'],
            onChanged: (value) {
              setState(() {
                _preferences['primaryGoal'] = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFitnessLevelSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surfaceContainerLow,
      ),
      child: Column(
        children: _fitnessLevels.map((level) => RadioListTile<String>(
          title: Text(level),
          value: level,
          groupValue: _preferences['fitnessLevel'],
          onChanged: (value) {
            setState(() {
              _preferences['fitnessLevel'] = value;
            });
          },
        )).toList(),
      ),
    );
  }

  Widget _buildDaysPerWeekSelector() {
    return Slider(
      value: _preferences['daysPerWeek'].toDouble(),
      min: 1,
      max: 7,
      divisions: 6,
      label: '${_preferences['daysPerWeek']} days',
      onChanged: (double value) {
        setState(() {
          _preferences['daysPerWeek'] = value.round();
        });
      },
    );
  }

  Widget _buildWorkoutDurationSelector() {
    return Slider(
      value: _preferences['workoutDuration'].toDouble(),
      min: 15,
      max: 90,
      divisions: 15,
      label: '${_preferences['workoutDuration']} mins',
      onChanged: (double value) {
        setState(() {
          _preferences['workoutDuration'] = value.round();
        });
      },
    );
  }

  Widget _buildExerciseTypeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _exerciseTypes.map((type) => FilterChip(
        label: Text(type),
        selected: (_preferences['exerciseTypes'] as List<String>).contains(type),
        onSelected: (selected) => _updateExerciseTypeSelection(type, selected),
      )).toList(),
    );
  }

  Widget _buildEquipmentSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _equipmentOptions.map((equipment) => FilterChip(
        label: Text(equipment),
        selected: (_preferences['equipment'] as List<String>).contains(equipment),
        onSelected: (selected) => _updateEquipmentSelection(equipment, selected),
      )).toList(),
    );
  }

  Widget _buildSpecificFocusField() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      hint: const Text('Select focus area (optional)'),
      value: _preferences['specificFocus'].isEmpty ? null : _preferences['specificFocus'],
      items: _bodyFocusOptions.map((focus) => DropdownMenuItem(
        value: focus,
        child: Text(focus),
      )).toList(),
      onChanged: (value) {
        setState(() {
          _preferences['specificFocus'] = value ?? '';
        });
      },
      validator: (_) => null,
      autovalidateMode: AutovalidateMode.disabled,
    );
  }

  Widget _buildOtherPreferencesField() {
    return TextField(
      controller: _otherPreferencesController,
      decoration: InputDecoration(
        hintText: 'Injuries, time constraints, or other notes (optional)',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      maxLines: 3,
    );
  }
} 