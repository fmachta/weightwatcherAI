// services/openai_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/user_profile.dart';
import '../models/workout.dart';
import '../models/exercise.dart';
import '../models/meal.dart';
import '../models/food_item.dart';
import '../models/ai_plan.dart';
import 'package:uuid/uuid.dart';

class OpenAIService {
  final String _baseUrl = 'https://api.openai.com/v1/chat/completions';
  late final String _apiKey;
  final Uuid _uuid = const Uuid();

  OpenAIService() {
    // Load API key from .env file or use a placeholder for development
    _apiKey = dotenv.env['OPENAI_API_KEY'] ?? 'your-api-key-here';
  }

  // Generate a workout plan based on user profile
  Future<AIPlan> generateWorkoutPlan(UserProfile userProfile) async {
    // Create a prompt that describes the user and their fitness goals
    final prompt = _createWorkoutPlanPrompt(userProfile);

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4-turbo', // Use the most appropriate model
          'messages': [
            {
              'role': 'system',
              'content': 'You are a professional fitness trainer with expertise in creating personalized workout plans. Provide detailed, actionable workouts tailored to the user\'s goals and fitness level. Format your response as JSON.'
            },
            {
              'role': 'user',
              'content': prompt
            }
          ],
          'temperature': 0.7,
          'max_tokens': 2500,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];

        // Parse the workout plan from the response
        return _parseWorkoutPlanResponse(content, userProfile);
      } else {
        // If API call fails, fall back to a default plan
        return _createDefaultWorkoutPlan(userProfile);
      }
    } catch (e) {
      print('Error generating workout plan: $e');
      // If there's an error, return a default plan
      return _createDefaultWorkoutPlan(userProfile);
    }
  }

  // Generate a meal plan based on user profile
  Future<AIPlan> generateMealPlan(UserProfile userProfile) async {
    // Create a prompt that describes the user and their nutrition needs
    final prompt = _createMealPlanPrompt(userProfile);

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4-turbo', // Use the most appropriate model
          'messages': [
            {
              'role': 'system',
              'content': 'You are a professional nutritionist with expertise in creating personalized meal plans. Provide detailed, nutritious meal suggestions tailored to the user\'s goals and preferences. Format your response as JSON.'
            },
            {
              'role': 'user',
              'content': prompt
            }
          ],
          'temperature': 0.7,
          'max_tokens': 2500,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];

        // Parse the meal plan from the response
        return _parseMealPlanResponse(content, userProfile);
      } else {
        // If API call fails, fall back to a default plan
        return _createDefaultMealPlan(userProfile);
      }
    } catch (e) {
      print('Error generating meal plan: $e');
      // If there's an error, return a default plan
      return _createDefaultMealPlan(userProfile);
    }
  }

  // Get an AI insight for dashboard based on user data
  Future<String> getAIInsight(UserProfile userProfile, List<dynamic> recentWorkouts, List<dynamic> recentMeals) async {
    // Create a prompt based on user's recent activities
    final prompt = _createInsightPrompt(userProfile, recentWorkouts, recentMeals);

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4-turbo',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a fitness and nutrition expert. Provide a short, personalized insight based on the user\'s recent activity and goals.'
            },
            {
              'role': 'user',
              'content': prompt
            }
          ],
          'temperature': 0.7,
          'max_tokens': 250,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        return 'Based on your recent activity, consider focusing on maintaining consistency in your workouts and ensuring adequate protein intake for muscle recovery.';
      }
    } catch (e) {
      print('Error generating AI insight: $e');
      return 'Stay consistent with your fitness routine and ensure you\'re getting enough hydration throughout the day.';
    }
  }

  // Answer a fitness question using AI
  Future<String> answerQuestion(String question, UserProfile userProfile) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4-turbo',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a fitness and nutrition expert. Provide helpful, evidence-based advice tailored to the user\'s profile. Keep answers concise and actionable.'
            },
            {
              'role': 'user',
              'content': 'User Profile: Age: ${userProfile.age}, Weight: ${userProfile.currentWeight}kg, Height: ${userProfile.height}cm, Body Fat: ${userProfile.bodyFat}%, Goal: ${userProfile.fitnessGoal.name}\n\nQuestion: $question'
            }
          ],
          'temperature': 0.7,
          'max_tokens': 400,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        return 'I\'m sorry, I couldn\'t process your question right now. Please try again later.';
      }
    } catch (e) {
      print('Error answering question: $e');
      return 'I\'m experiencing technical difficulties. Please try asking again later.';
    }
  }

  // Create a prompt for workout plan generation
  String _createWorkoutPlanPrompt(UserProfile userProfile) {
    final fitnessLevel = _determineFitnessLevel(userProfile);

    return '''
    Create a detailed 4-week workout plan for a user with the following profile:
    
    Age: ${userProfile.age}
    Gender: ${userProfile.gender}
    Weight: ${userProfile.currentWeight}kg
    Height: ${userProfile.height}cm
    Body Fat: ${userProfile.bodyFat}%
    Fitness Goal: ${userProfile.fitnessGoal.name}
    Activity Level: ${userProfile.activityLevel.toString().split('.').last}
    Fitness Level: $fitnessLevel
    
    The plan should:
    1. Span 28 days (4 weeks)
    2. Include appropriate rest days
    3. Focus on ${userProfile.fitnessGoal.name == 'Muscle Gain' ? 'progressive overload and hypertrophy' : userProfile.fitnessGoal.name == 'Weight Loss' ? 'fat burning and calorie expenditure' : 'balanced fitness and maintenance'}
    4. Include specific exercises with sets, reps, and suggested weights (relative to fitness level)
    5. Have a mix of different workout types appropriate for the user's goals
    
    Format the response as a JSON object with the following structure:
    {
      "title": "PLAN_TITLE",
      "description": "PLAN_DESCRIPTION",
      "days": [
        {
          "day": 1,
          "workout": {
            "name": "WORKOUT_NAME",
            "type": "strength/cardio/flexibility/rest",
            "exercises": [
              {
                "name": "EXERCISE_NAME",
                "sets": NUMBER_OF_SETS,
                "reps": NUMBER_OF_REPS,
                "notes": "OPTIONAL_NOTES"
              },
              ...
            ],
            "duration": ESTIMATED_MINUTES,
            "notes": "WORKOUT_NOTES"
          }
        },
        ...
      ]
    }
    ''';
  }

  // Create a prompt for meal plan generation
  String _createMealPlanPrompt(UserProfile userProfile) {
    // Calculate daily calorie goal
    final dailyCalories = userProfile.calculateDailyCalorieGoal();
    final macros = userProfile.macroDistribution;

    return '''
    Create a detailed 1-week meal plan for a user with the following profile:
    
    Age: ${userProfile.age}
    Gender: ${userProfile.gender}
    Weight: ${userProfile.currentWeight}kg
    Height: ${userProfile.height}cm
    Body Fat: ${userProfile.bodyFat}%
    Fitness Goal: ${userProfile.fitnessGoal.name}
    Activity Level: ${userProfile.activityLevel.toString().split('.').last}
    
    Dietary Requirements:
    - Daily Calorie Target: ${dailyCalories.toInt()} calories
    - Protein: ${(macros['protein']! * 100).toInt()}% (${(dailyCalories * macros['protein']! / 4).toInt()}g)
    - Carbs: ${(macros['carbs']! * 100).toInt()}% (${(dailyCalories * macros['carbs']! / 4).toInt()}g)
    - Fat: ${(macros['fat']! * 100).toInt()}% (${(dailyCalories * macros['fat']! / 9).toInt()}g)
    
    The plan should:
    1. Cover 7 days
    2. Include 3 main meals (breakfast, lunch, dinner) and 2 snacks per day
    3. Focus on whole, nutritious foods
    4. Be practical and reasonably easy to prepare
    5. Include approximate calories and macronutrients for each meal
    
    Format the response as a JSON object with the following structure:
    {
      "title": "PLAN_TITLE",
      "description": "PLAN_DESCRIPTION",
      "days": [
        {
          "day": 1,
          "meals": [
            {
              "name": "Breakfast",
              "foods": [
                {
                  "name": "FOOD_NAME",
                  "quantity": "QUANTITY",
                  "calories": CALORIES,
                  "protein": PROTEIN_GRAMS,
                  "carbs": CARBS_GRAMS,
                  "fat": FAT_GRAMS
                },
                ...
              ],
              "totalCalories": TOTAL_MEAL_CALORIES
            },
            ...
          ]
        },
        ...
      ]
    }
    ''';
  }

  // Create a prompt for insight generation
  String _createInsightPrompt(UserProfile userProfile, List<dynamic> recentWorkouts, List<dynamic> recentMeals) {
    // Create simple summaries of recent activity
    String workoutSummary = recentWorkouts.isEmpty
        ? "No recent workouts"
        : "${recentWorkouts.length} workouts in the past week, totaling approximately ${recentWorkouts.fold(0, (sum, workout) => sum + workout.duration.inMinutes).toInt()} minutes";

    String mealSummary = recentMeals.isEmpty
        ? "No meal tracking data available"
        : "Recent meals show an average of ${recentMeals.fold(0.0, (sum, meal) => sum + meal.totalCalories) / (recentMeals.isEmpty ? 1 : recentMeals.length)} calories per meal";

    return '''
    Generate a short, personalized fitness insight for a user with the following profile and recent activity:
    
    Profile:
    - Age: ${userProfile.age}
    - Current Weight: ${userProfile.currentWeight}kg
    - Goal Weight: ${userProfile.targetWeight}kg
    - Fitness Goal: ${userProfile.fitnessGoal.name}
    
    Recent Activity:
    - $workoutSummary
    - $mealSummary
    
    Provide a specific, actionable insight (1-2 sentences) based on their profile and activity that can help them make progress toward their fitness goal.
    ''';
  }

  // Determine fitness level based on profile and activity
  String _determineFitnessLevel(UserProfile userProfile) {
    // This is a simple approximation - a real app would use more data points
    if (userProfile.activityLevel == ActivityLevel.sedentary ||
        userProfile.activityLevel == ActivityLevel.lightlyActive) {
      return 'Beginner';
    } else if (userProfile.activityLevel == ActivityLevel.moderatelyActive) {
      return 'Intermediate';
    } else {
      return 'Advanced';
    }
  }

  // Parse the OpenAI response for workout plan
  AIPlan _parseWorkoutPlanResponse(String jsonResponse, UserProfile userProfile) {
    try {
      // Extract JSON from the response (in case there's markdown or other text)
      final jsonStart = jsonResponse.indexOf('{');
      final jsonEnd = jsonResponse.lastIndexOf('}') + 1;
      final jsonString = jsonResponse.substring(jsonStart, jsonEnd);

      final data = jsonDecode(jsonString);

      final id = _uuid.v4();
      final title = data['title'] ?? 'Custom Workout Plan';
      final description = data['description'] ?? 'AI-generated workout plan based on your profile.';

      // Create plan days
      final List<PlanDay> planDays = [];
      for (var dayData in data['days']) {
        final dayNumber = dayData['day'];

        // If it's a rest day
        if (dayData['workout'] == null || dayData['workout']['type'] == 'rest') {
          planDays.add(PlanDay(
            dayNumber: dayNumber,
            notes: 'Rest day - focus on recovery and mobility.',
          ));
          continue;
        }

        // Create workout
        final workoutData = dayData['workout'];
        final exercises = <Exercise>[];

        for (var exerciseData in workoutData['exercises'] ?? []) {
          final exerciseSets = <ExerciseSet>[];

          // Create sets if available
          if (exerciseData['sets'] != null && exerciseData['reps'] != null) {
            for (int i = 0; i < exerciseData['sets']; i++) {
              exerciseSets.add(ExerciseSet(
                reps: exerciseData['reps'],
                weight: exerciseData['weight'],
              ));
            }
          }

          exercises.add(Exercise(
            id: _uuid.v4(),
            name: exerciseData['name'],
            description: exerciseData['notes'],
            sets: exerciseSets.isEmpty ? null : exerciseSets,
            targetMuscleGroup: exerciseData['muscleGroup'],
          ));
        }

        final workout = Workout(
          id: _uuid.v4(),
          name: workoutData['name'] ?? 'Day $dayNumber Workout',
          dateTime: DateTime.now().add(Duration(days: dayNumber - 1)),
          duration: Duration(minutes: workoutData['duration'] ?? 45),
          type: _parseWorkoutType(workoutData['type']),
          exercises: exercises,
          caloriesBurned: _estimateCaloriesBurned(exercises, workoutData['duration'] ?? 45, userProfile),
          notes: workoutData['notes'],
        );

        planDays.add(PlanDay(
          dayNumber: dayNumber,
          workout: workout,
        ));
      }

      return AIPlan(
        id: id,
        title: title,
        description: description,
        type: PlanType.workout,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 28)),
        days: planDays,
        targetProfile: userProfile,
      );
    } catch (e) {
      print('Error parsing workout plan: $e');
      return _createDefaultWorkoutPlan(userProfile);
    }
  }

  // Parse the OpenAI response for meal plan
  AIPlan _parseMealPlanResponse(String jsonResponse, UserProfile userProfile) {
    try {
      // Extract JSON from the response (in case there's markdown or other text)
      final jsonStart = jsonResponse.indexOf('{');
      final jsonEnd = jsonResponse.lastIndexOf('}') + 1;
      final jsonString = jsonResponse.substring(jsonStart, jsonEnd);

      final data = jsonDecode(jsonString);

      final id = _uuid.v4();
      final title = data['title'] ?? 'Custom Meal Plan';
      final description = data['description'] ?? 'AI-generated meal plan based on your profile.';

      // Create plan days
      final List<PlanDay> planDays = [];
      for (var dayData in data['days']) {
        final dayNumber = dayData['day'];

        // Create meals for the day
        final meals = <Meal>[];

        for (var mealData in dayData['meals'] ?? []) {
          final mealType = _getMealTypeFromName(mealData['name']);
          final mealItems = <MealItem>[];

          for (var foodData in mealData['foods'] ?? []) {
            final foodItem = FoodItem(
              id: _uuid.v4(),
              name: foodData['name'],
              calories: foodData['calories']?.toDouble() ?? 0,
              protein: foodData['protein']?.toDouble() ?? 0,
              carbs: foodData['carbs']?.toDouble() ?? 0,
              fat: foodData['fat']?.toDouble() ?? 0,
              description: foodData['quantity'],
            );

            mealItems.add(MealItem(
              foodItem: foodItem,
              quantity: 1.0, // Default to 1 serving
              servingSize: foodData['quantity'],
            ));
          }

          meals.add(Meal(
            id: _uuid.v4(),
            name: mealData['name'] ?? 'Meal',
            type: mealType,
            dateTime: DateTime.now().add(Duration(days: dayNumber - 1)),
            items: mealItems,
            notes: mealData['notes'],
          ));
        }

        planDays.add(PlanDay(
          dayNumber: dayNumber,
          meals: meals,
        ));
      }

      return AIPlan(
        id: id,
        title: title,
        description: description,
        type: PlanType.nutrition,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 7)),
        days: planDays,
        targetProfile: userProfile,
      );
    } catch (e) {
      print('Error parsing meal plan: $e');
      return _createDefaultMealPlan(userProfile);
    }
  }

  // Get meal type from name
  MealType _getMealTypeFromName(String name) {
    if (name.toLowerCase().contains('breakfast')) {
      return MealType.breakfast;
    } else if (name.toLowerCase().contains('lunch')) {
      return MealType.lunch;
    } else if (name.toLowerCase().contains('dinner')) {
      return MealType.dinner;
    } else if (name.toLowerCase().contains('snack')) {
      return MealType.snack;
    } else {
      return MealType.other;
    }
  }

  // Parse workout type from string
  WorkoutType _parseWorkoutType(String? type) {
    if (type == null) return WorkoutType.other;

    switch (type.toLowerCase()) {
      case 'cardio':
        return WorkoutType.cardio;
      case 'strength':
        return WorkoutType.strength;
      case 'flexibility':
        return WorkoutType.flexibility;
      case 'balance':
        return WorkoutType.balance;
      case 'sports':
        return WorkoutType.sports;
      default:
        return WorkoutType.other;
    }
  }

  // Estimate calories burned for a workout
  double _estimateCaloriesBurned(List<Exercise> exercises, int durationMinutes, UserProfile userProfile) {
    // A simple estimation algorithm
    final workoutIntensity = exercises.length > 5 ? 1.2 : 1.0;
    final weightFactor = userProfile.currentWeight / 70.0; // Adjust for body weight

    switch (exercises.isEmpty ? WorkoutType.other : _determineWorkoutType(exercises)) {
      case WorkoutType.cardio:
        return 10.0 * durationMinutes * workoutIntensity * weightFactor;
      case WorkoutType.strength:
        return 8.0 * durationMinutes * workoutIntensity * weightFactor;
      case WorkoutType.flexibility:
        return 3.0 * durationMinutes * workoutIntensity * weightFactor;
      case WorkoutType.balance:
        return 4.0 * durationMinutes * workoutIntensity * weightFactor;
      case WorkoutType.sports:
        return 9.0 * durationMinutes * workoutIntensity * weightFactor;
      case WorkoutType.other:
        return 6.0 * durationMinutes * workoutIntensity * weightFactor;
    }
  }

  // Determine workout type based on exercises
  WorkoutType _determineWorkoutType(List<Exercise> exercises) {
    // Count exercise types
    int strengthCount = 0;
    int cardioCount = 0;
    int flexibilityCount = 0;

    for (var exercise in exercises) {
      final name = exercise.name.toLowerCase();
      if (name.contains('push') || name.contains('pull') || name.contains('press') ||
          name.contains('curl') || name.contains('squat') || name.contains('deadlift')) {
        strengthCount++;
      } else if (name.contains('run') || name.contains('jog') || name.contains('sprint') ||
          name.contains('cycle') || name.contains('row') || name.contains('swim')) {
        cardioCount++;
      } else if (name.contains('stretch') || name.contains('yoga') || name.contains('flex')) {
        flexibilityCount++;
      }
    }

    if (strengthCount >= cardioCount && strengthCount >= flexibilityCount) {
      return WorkoutType.strength;
    } else if (cardioCount >= strengthCount && cardioCount >= flexibilityCount) {
      return WorkoutType.cardio;
    } else if (flexibilityCount >= strengthCount && flexibilityCount >= cardioCount) {
      return WorkoutType.flexibility;
    } else {
      return WorkoutType.other;
    }
  }

  // Create a default workout plan if OpenAI generation fails
  AIPlan _createDefaultWorkoutPlan(UserProfile userProfile) {
    final id = _uuid.v4();
    final List<PlanDay> planDays = [];

    // Create a simple 4-week plan based on user's goal
    for (int day = 1; day <= 28; day++) {
      // Rest days on Sundays
      if (day % 7 == 0) {
        planDays.add(PlanDay(
          dayNumber: day,
          notes: 'Rest day - focus on recovery and mobility.',
        ));
        continue;
      }

      // Different workout types based on days of the week
      final dayOfWeek = day % 7;
      late WorkoutType workoutType;
      late String workoutName;
      late List<Exercise> exercises;

      if (userProfile.fitnessGoal == FitnessGoal.weightLoss) {
        // Weight loss plan focuses on cardio and full-body workouts
        switch (dayOfWeek) {
          case 1: // Monday
            workoutType = WorkoutType.cardio;
            workoutName = 'Cardio Session';
            exercises = [
              Exercise(
                id: _uuid.v4(),
                name: 'Running',
                duration: const Duration(minutes: 30),
                targetMuscleGroup: 'Cardiovascular',
              ),
              Exercise(
                id: _uuid.v4(),
                name: 'Jumping Jacks',
                sets: [ExerciseSet(reps: 25), ExerciseSet(reps: 25), ExerciseSet(reps: 25)],
                targetMuscleGroup: 'Full body',
              ),
            ];
            break;
          case 2: // Tuesday
            workoutType = WorkoutType.strength;
            workoutName = 'Upper Body Circuit';
            exercises = [
              Exercise(
                id: _uuid.v4(),
                name: 'Push-ups',
                sets: [ExerciseSet(reps: 10), ExerciseSet(reps: 10), ExerciseSet(reps: 10)],
                targetMuscleGroup: 'Chest',
              ),
              Exercise(
                id: _uuid.v4(),
                name: 'Dumbbell Rows',
                sets: [ExerciseSet(reps: 12), ExerciseSet(reps: 12), ExerciseSet(reps: 12)],
                targetMuscleGroup: 'Back',
              ),
            ];
            break;
          default:
            workoutType = WorkoutType.cardio;
            workoutName = 'Fat Burning Workout';
            exercises = [
              Exercise(
                id: _uuid.v4(),
                name: 'Burpees',
                sets: [ExerciseSet(reps: 10), ExerciseSet(reps: 10), ExerciseSet(reps: 10)],
                targetMuscleGroup: 'Full body',
              ),
            ];
        }
      } else if (userProfile.fitnessGoal == FitnessGoal.muscleGain) {
        // Muscle gain plan focuses on strength training with different muscle groups
        switch (dayOfWeek) {
          case 1: // Monday
            workoutType = WorkoutType.strength;
            workoutName = 'Chest & Triceps';
            exercises = [
              Exercise(
                id: _uuid.v4(),
                name: 'Bench Press',
                sets: [ExerciseSet(reps: 8), ExerciseSet(reps: 8), ExerciseSet(reps: 8)],
                targetMuscleGroup: 'Chest',
              ),
              Exercise(
                id: _uuid.v4(),
                name: 'Tricep Extensions',
                sets: [ExerciseSet(reps: 12), ExerciseSet(reps: 12), ExerciseSet(reps: 12)],
                targetMuscleGroup: 'Triceps',
              ),
            ];
            break;
          case 2: // Tuesday
            workoutType = WorkoutType.strength;
            workoutName = 'Back & Biceps';
            exercises = [
              Exercise(
                id: _uuid.v4(),
                name: 'Deadlift',
                sets: [ExerciseSet(reps: 6), ExerciseSet(reps: 6), ExerciseSet(reps: 6)],
                targetMuscleGroup: 'Back',
              ),
              Exercise(
                id: _uuid.v4(),
                name: 'Bicep Curls',
                sets: [ExerciseSet(reps: 12), ExerciseSet(reps: 12), ExerciseSet(reps: 12)],
                targetMuscleGroup: 'Biceps',
              ),
            ];
            break;
          default:
            workoutType = WorkoutType.strength;
            workoutName = 'Leg Day';
            exercises = [
              Exercise(
                id: _uuid.v4(),
                name: 'Squats',
                sets: [ExerciseSet(reps: 10), ExerciseSet(reps: 10), ExerciseSet(reps: 10)],
                targetMuscleGroup: 'Legs',
              ),
            ];
        }
      } else {
        // Maintenance plan has a mix of cardio and strength
        switch (dayOfWeek) {
          case 1: // Monday
            workoutType = WorkoutType.strength;
            workoutName = 'Full Body Strength';
            exercises = [
              Exercise(
                id: _uuid.v4(),
                name: 'Push-ups',
                sets: [ExerciseSet(reps: 10), ExerciseSet(reps: 10), ExerciseSet(reps: 10)],
                targetMuscleGroup: 'Chest',
              ),
              Exercise(
                id: _uuid.v4(),
                name: 'Squats',
                sets: [ExerciseSet(reps: 12), ExerciseSet(reps: 12), ExerciseSet(reps: 12)],
                targetMuscleGroup: 'Legs',
              ),
            ];
            break;
          case 3: // Wednesday
            workoutType = WorkoutType.cardio;
            workoutName = 'Cardio & Core';
            exercises = [
              Exercise(
                id: _uuid.v4(),
                name: 'Running',
                duration: const Duration(minutes: 20),
                targetMuscleGroup: 'Cardiovascular',
              ),
              Exercise(
                id: _uuid.v4(),
                name: 'Plank',
                duration: const Duration(minutes: 5),
                targetMuscleGroup: 'Core',
              ),
            ];
            break;
          default:
            workoutType = WorkoutType.flexibility;
            workoutName = 'Mobility & Flexibility';
            exercises = [
              Exercise(
                id: _uuid.v4(),
                name: 'Yoga Flow',
                duration: const Duration(minutes: 30),
                targetMuscleGroup: 'Full body',
              ),
            ];
        }
      }

      // Create the workout
      final workout = Workout(
        id: _uuid.v4(),
        name: workoutName,
        dateTime: DateTime.now().add(Duration(days: day - 1)),
        duration: const Duration(minutes: 45),
        type: workoutType,
        exercises: exercises,
        caloriesBurned: _estimateCaloriesBurned(exercises, 45, userProfile),
        notes: 'Default workout for ${userProfile.fitnessGoal.name}',
      );

      planDays.add(PlanDay(
        dayNumber: day,
        workout: workout,
      ));
    }

    String planTitle;
    String planDescription;

    if (userProfile.fitnessGoal == FitnessGoal.weightLoss) {
      planTitle = 'Fat Loss Workout Plan';
      planDescription = 'A 28-day plan designed to maximize calorie burn and support weight loss. Combines cardio and strength training to boost metabolism.';
    } else if (userProfile.fitnessGoal == FitnessGoal.muscleGain) {
      planTitle = 'Muscle Building Program';
      planDescription = 'A 28-day hypertrophy-focused plan to build muscle mass. Targets different muscle groups with progressive overload.';
    } else {
      planTitle = 'Balanced Fitness Plan';
      planDescription = 'A 28-day balanced plan to maintain overall fitness. Includes a mix of strength, cardio, and flexibility training.';
    }

    return AIPlan(
      id: id,
      title: planTitle,
      description: planDescription,
      type: PlanType.workout,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 28)),
      days: planDays,
      targetProfile: userProfile,
    );
  }

  // Create a default meal plan if OpenAI generation fails
  AIPlan _createDefaultMealPlan(UserProfile userProfile) {
    final id = _uuid.v4();
    final List<PlanDay> planDays = [];

    // Calculate calorie targets based on user profile
    final dailyCalories = userProfile.calculateDailyCalorieGoal();
    final proteinGoal = dailyCalories * userProfile.macroDistribution['protein']! / 4; // 4 calories per gram of protein
    final carbsGoal = dailyCalories * userProfile.macroDistribution['carbs']! / 4; // 4 calories per gram of carbs
    final fatGoal = dailyCalories * userProfile.macroDistribution['fat']! / 9; // 9 calories per gram of fat

    // Create a simple 7-day meal plan
    for (int day = 1; day <= 7; day++) {
      final meals = <Meal>[];

      // Breakfast
      meals.add(Meal(
        id: _uuid.v4(),
        name: 'Breakfast',
        type: MealType.breakfast,
        dateTime: DateTime.now().add(Duration(days: day - 1, hours: 8)),
        items: [
          MealItem(
            foodItem: FoodItem(
              id: 'oatmeal',
              name: 'Oatmeal with Berries and Nuts',
              calories: 350,
              protein: 12,
              carbs: 45,
              fat: 15,
              description: 'Bowl of oatmeal with mixed berries and almonds',
            ),
            quantity: 1.0,
          ),
        ],
      ));

      // Lunch
      meals.add(Meal(
        id: _uuid.v4(),
        name: 'Lunch',
        type: MealType.lunch,
        dateTime: DateTime.now().add(Duration(days: day - 1, hours: 13)),
        items: [
          MealItem(
            foodItem: FoodItem(
              id: 'chicken_salad',
              name: 'Chicken Salad with Quinoa',
              calories: 450,
              protein: 35,
              carbs: 40,
              fat: 15,
              description: 'Grilled chicken with mixed greens and quinoa',
            ),
            quantity: 1.0,
          ),
        ],
      ));

      // Dinner
      meals.add(Meal(
        id: _uuid.v4(),
        name: 'Dinner',
        type: MealType.dinner,
        dateTime: DateTime.now().add(Duration(days: day - 1, hours: 19)),
        items: [
          MealItem(
            foodItem: FoodItem(
              id: 'salmon',
              name: 'Baked Salmon with Vegetables',
              calories: 450,
              protein: 30,
              carbs: 25,
              fat: 25,
              description: 'Baked salmon fillet with roasted vegetables',
            ),
            quantity: 1.0,
          ),
        ],
      ));

      // Snacks
      meals.add(Meal(
        id: _uuid.v4(),
        name: 'Snack 1',
        type: MealType.snack,
        dateTime: DateTime.now().add(Duration(days: day - 1, hours: 11)),
        items: [
          MealItem(
            foodItem: FoodItem(
              id: 'greek_yogurt',
              name: 'Greek Yogurt with Honey',
              calories: 150,
              protein: 15,
              carbs: 12,
              fat: 3,
              description: 'Greek yogurt with a drizzle of honey',
            ),
            quantity: 1.0,
          ),
        ],
      ));

      meals.add(Meal(
        id: _uuid.v4(),
        name: 'Snack 2',
        type: MealType.snack,
        dateTime: DateTime.now().add(Duration(days: day - 1, hours: 16)),
        items: [
          MealItem(
            foodItem: FoodItem(
              id: 'protein_shake',
              name: 'Protein Shake',
              calories: 200,
              protein: 25,
              carbs: 15,
              fat: 3,
              description: 'Whey protein shake with water',
            ),
            quantity: 1.0,
          ),
        ],
      ));

      planDays.add(PlanDay(
        dayNumber: day,
        meals: meals,
        notes: 'Day $day of your meal plan',
      ));
    }

    String planTitle;
    String planDescription;

    if (userProfile.fitnessGoal == FitnessGoal.weightLoss) {
      planTitle = 'Weight Loss Meal Plan';
      planDescription = 'A 7-day calorie-controlled meal plan designed to support fat loss while preserving muscle mass. Focuses on high-protein, nutrient-dense foods.';
    } else if (userProfile.fitnessGoal == FitnessGoal.muscleGain) {
      planTitle = 'Muscle Building Meal Plan';
      planDescription = 'A 7-day high-protein meal plan to support muscle growth and recovery. Provides adequate calories and nutrients for optimal gains.';
    } else {
      planTitle = 'Balanced Nutrition Plan';
      planDescription = 'A 7-day well-rounded meal plan to maintain health and energy levels. Includes a balanced mix of macronutrients from whole food sources.';
    }

    return AIPlan(
      id: id,
      title: planTitle,
      description: planDescription,
      type: PlanType.nutrition,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 7)),
      days: planDays,
      targetProfile: userProfile,
    );
  }
}