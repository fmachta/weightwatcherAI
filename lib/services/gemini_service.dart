// services/gemini_service.dart
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/user_profile.dart';
import '../models/workout.dart';
import '../models/exercise.dart';
import '../models/meal.dart';
import '../models/food_item.dart';
import '../models/ai_plan.dart';
import 'package:uuid/uuid.dart';
import 'dart:math';

class GeminiService {
  // Gemini specific variables
  late final String? _geminiApiKey;
  late final String _geminiModelName;
  late final GenerativeModel _model;
  late final GenerationConfig _defaultConfig;

  final Uuid _uuid = const Uuid();

  // List of suggested fitness questions to randomly rotate
  final List<String> _suggestedQuestions = [
    "How can I improve my bench press?",
    "What's the best way to lose belly fat?",
    "How often should I do cardio?",
    "What should I eat before a workout?",
    "How can I build bigger arms?",
    "What's better for weight loss: cardio or weights?",
    "How much protein should I eat per day?",
    "How do I fix my squat form?",
    "What's a good workout routine for beginners?",
    "How can I improve my running endurance?",
    "What exercises are best for a strong core?",
    "How do I break through a weight loss plateau?",
    "What should I eat after a workout?",
    "How many rest days should I take per week?",
    "What's the best way to stretch before working out?",
    "How can I build muscle as a vegetarian?",
    "What's a good substitute for a pull-up if I can't do one?",
    "How long should my workout sessions be?",
    "What's the best way to track fitness progress?",
    "How can I increase my flexibility?",
  ];

  GeminiService() {
    _geminiApiKey = dotenv.env['GEMINI_API_KEY'];
    _geminiModelName = dotenv.env['GEMINI_MODEL_NAME'] ?? 'gemini-1.5-flash';

    _defaultConfig = GenerationConfig(
      temperature: 0.8,
      topP: 1.0,
      topK: 40,
      maxOutputTokens: 8192,
    );

    if (_geminiApiKey == null ||
        _geminiApiKey!.isEmpty ||
        _geminiApiKey == 'google-api-key-here') {
      print(
          "Error: GEMINI_API_KEY not found or is placeholder in .env file. Gemini features will not work.");
      _model =
          GenerativeModel(model: _geminiModelName, apiKey: 'DUMMY_API_KEY');
    } else {
      _model = GenerativeModel(
        model: _geminiModelName,
        apiKey: _geminiApiKey!,
        generationConfig: _defaultConfig, // use shared config here
      );
    }
  }

// Generate a workout plan based on user profile
  Future<AIPlan> generateWorkoutPlan(UserProfile userProfile,
      [Map<String, dynamic>? preferenceData]) async {
    if (_geminiApiKey == null ||
        _geminiApiKey!.isEmpty ||
        _geminiApiKey == 'google-api-key-here') {
      print(
          "Error: Cannot generate workout plan. GEMINI_API_KEY is missing or invalid.");
      return _createDefaultWorkoutPlan(userProfile);
    }

    final primaryGoal =
        preferenceData?['primaryGoal'] ?? userProfile.fitnessGoal.name;
    final fitnessLevel =
        preferenceData?['fitnessLevel'] ?? _determineFitnessLevel(userProfile);
    final workoutDaysPerWeek = preferenceData?['daysPerWeek'] ?? 4;
    final workoutDuration = preferenceData?['workoutDuration'] ?? 45;
    final preferredExerciseTypes = preferenceData?['exerciseTypes'] ?? [];
    final equipmentAvailable = preferenceData?['equipment'] ?? [];
    final specificFocus =
        _sanitizeUserInput(preferenceData?['specificFocus'] ?? '');
    final otherPreferences =
        _sanitizeUserInput(preferenceData?['otherPreferences'] ?? '');

    final prompt = """
You are a fitness coach AI that generates structured, safe workout plans.

Create a detailed 4-week workout plan (28 days) for the following user:

Age: ${userProfile.age}
Gender: ${userProfile.gender}
Current weight: ${userProfile.currentWeight} kg
Goal weight: ${userProfile.targetWeight} kg
Height: ${userProfile.height} cm
Body Fat: ${userProfile.bodyFat}%
Fitness Goal: $primaryGoal
Fitness Level: $fitnessLevel
Workout days per week: $workoutDaysPerWeek
Workout duration per day: $workoutDuration minutes
${preferredExerciseTypes.isNotEmpty ? 'Preferred exercise types: ${preferredExerciseTypes.join(', ')}' : ''}
${equipmentAvailable.isNotEmpty ? 'Available equipment: ${equipmentAvailable.join(', ')}' : ''}
${specificFocus.isNotEmpty ? 'Specific focus: $specificFocus' : ''}
${otherPreferences.isNotEmpty ? 'Other preferences: $otherPreferences' : ''}

IMPORTANT STRICT RULES:
- ❗ Return a single valid JSON object with a "days" array of 28 entries (4 full weeks). Each week must include both workout and rest/recovery days. Distribute workoutDaysPerWeek accordingly.
- ❗ If workoutDaysPerWeek < 7, assign the remaining days as rest or active recovery.
- ❗ DO NOT use any ranges like 8-12. Only provide exact numbers like 10.
- ❗ DO NOT use vague values like "as many as possible", "TBD", "choose a weight", or "adjust as needed". Always use a numeric value.
- ❗ Every exercise MUST include a numeric top-level "duration" field in seconds. This represents the **total time spent on the exercise**, not per rep or set. Do NOT omit it.
- ❗ DO NOT return null, 0, empty, or missing durations — use realistic values (e.g., 120 for 2 minutes, 600 for 10 minutes).
- ❗ For bodyweight, yoga, or cardio-style exercises, OMIT the "weight" field entirely. Do not include weight: 0.
- ❗ Only include "weight" if it is actually used (e.g., barbell, dumbbell, machine).
- ❗ Return only a valid single JSON object. No markdown, no explanations, no comments.
- ❗ All numbers (sets, reps, weight, duration) must be raw numbers (not strings).

Output Format:
{
  "title": "Custom Workout Plan",
  "description": "Generated plan",
  "days": [
    {
      "day": 1,
      "notes": "Upper Body Strength",
      "summary": "Chest, shoulders, triceps",
      "workout": {
        "name": "Upper Body Push",
        "type": "strength",
        "duration": 2700,
        "notes": "Controlled reps",
        "exercises": [
          {
            "name": "Bench Press",
            "muscleGroup": "Chest",
            "sets": 4,
            "reps": 10,
            "weight": 50,
            "duration": 60
          },
          {
            "name": "Push-ups",
            "muscleGroup": "Chest",
            "sets": 3,
            "reps": 15,
            "duration": 45
          }
        ]
      }
    }
  ]
}
""";

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(
        content,
        generationConfig: GenerationConfig(
          temperature: 0.6,
          maxOutputTokens: 8192,
        ),
      );

      print("Raw Gemini workout response: \${response.text}");
      if (response.text == null || response.text!.trim().isEmpty) {
        print("Error: Gemini response was null or blocked.");
        return _createDefaultWorkoutPlan(userProfile);
      }

      return _parseWorkoutPlanResponse(response.text!, userProfile);
    } catch (e) {
      print("Error generating workout plan with Gemini: \$e");
      return _createDefaultWorkoutPlan(userProfile);
    }
  }

  AIPlan _parseWorkoutPlanResponse(
      String jsonResponse, UserProfile userProfile) {
    try {
      // Step 1: Remove markdown wrappers
      final raw = jsonResponse.replaceAll(RegExp(r'```json|```'), '').trim();

      final sanitized = _sanitizeGeminiWorkoutResponse(raw);
      print("Sanitized Gemini workout response:\n$sanitized");

      final decoded = jsonDecode(sanitized) as Map<String, dynamic>;
      final data = decoded['days'] as List<dynamic>;

      final List<PlanDay> planDays = [];

      for (final dayEntry in data) {
        if (dayEntry is! Map) continue;

        final int dayNumber = (dayEntry['day'] as num?)?.toInt() ?? 0;
        final String notes = dayEntry['notes']?.toString() ?? '';
        final String summary = dayEntry['summary']?.toString() ?? '';

        final workoutData = dayEntry['workout'];
        final isRestDay = workoutData == null ||
            (workoutData['type']?.toString().toLowerCase() == 'rest');

        final exercises = <Exercise>[];

        if (!isRestDay && workoutData['exercises'] is List) {
          for (var ex in workoutData['exercises']) {
            if (ex is! Map) continue;

            final reps = _safeParseInt(ex['reps']);
            final sets = _safeParseInt(ex['sets']);
            final weight = _safeParseDouble(ex['weight']);

            // Handle duration safely (in seconds)
            final durationRaw = ex['duration'];
            final durationSeconds = _safeParseInt(durationRaw) ??
                _safeParseDouble(durationRaw)?.toInt();
            final exDuration = durationSeconds != null
                ? Duration(seconds: durationSeconds)
                : null;

            // Use fallback if reps/sets missing
            final validSets = sets ?? 1;
            final validReps = reps ?? 0;

            // Generate sets anyway so duration displays
            final exSets = List.generate(
              validSets,
              (_) => ExerciseSet(
                reps: validReps,
                weight: (weight != null && weight > 0) ? weight : null,
                duration: exDuration,
              ),
            );

            exercises.add(Exercise(
              id: _uuid.v4(),
              name: ex['name']?.toString() ?? 'Unnamed',
              targetMuscleGroup: ex['muscleGroup']?.toString() ?? 'Unknown',
              sets: exSets,
              duration: exDuration,
              description: ex['notes']?.toString(),
            ));

            print(
                'Parsed exercise: ${ex['name']} → duration: ${exDuration?.inSeconds ?? 'null'} sec'); //debug log
          }
        }

        final duration = isRestDay
            ? Duration.zero
            : Duration(minutes: _safeParseInt(workoutData['duration']) ?? 45);

        final workout = Workout(
          id: _uuid.v4(),
          name: isRestDay
              ? 'Rest Day'
              : (workoutData['name']?.toString() ?? 'Workout Day $dayNumber'),
          dateTime: DateTime.now().add(Duration(days: dayNumber - 1)),
          duration: duration,
          type: isRestDay
              ? WorkoutType.rest
              : _parseWorkoutType(workoutData['type']?.toString()),
          exercises: exercises,
          caloriesBurned: isRestDay
              ? 0
              : _estimateCaloriesBurned(
                      exercises, duration.inMinutes, userProfile)
                  .toInt(),
          notes: workoutData['notes']?.toString() ?? notes,
        );

        planDays.add(PlanDay(
          dayNumber: dayNumber,
          notes: notes,
          summary: summary,
          workout: workout,
        ));
      }
      print('Returning parsed AIPlan with ${planDays.length} days'); //debug log

      return AIPlan(
        id: _uuid.v4(),
        title: 'Custom Workout Plan',
        description: 'AI-generated workout plan based on your profile.',
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

  String _sanitizeGeminiWorkoutResponse(String raw) {
    return raw
        .replaceAllMapped(RegExp(r'(\d+)\s*[-–]\s*(\d+)'), (match) {
          final start = int.parse(match.group(1)!);
          final end = int.parse(match.group(2)!);
          return ((start + end) / 2).round().toString();
        })
        .replaceAll(
            RegExp(
                r'(?<!\")\b(AsManyAsPossible|ChooseModerateWeight|ChooseHeavyWeight|TBD|Any)\b(?!\")',
                caseSensitive: false),
            '10')
        .replaceAll(
            RegExp(r'"[^"]*(as many as possible|choose a weight|tbd|any)[^"]*"',
                caseSensitive: false),
            '10')
        .replaceAll(RegExp(r'```json|```'), '')
        .replaceAllMapped(RegExp(r'"(\d+(\.\d+)?)"'),
            (m) => m.group(1)!) // ← converts "60" to 60
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAllMapped(RegExp(r'"(\d+(\.\d+)?)(\s*(reps|seconds|min|kg))?"'),
            (m) => m.group(1)!)
        .trim();
  }

  String _sanitizeUserInput(String input) {
    return input
        .replaceAll(RegExp(r'[^ -~]'), '')
        .replaceAll(RegExp(r'["\\]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  int? _safeParseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String && RegExp(r'^\d+$').hasMatch(value.trim())) {
      return int.tryParse(value);
    }
    return null;
  }

  double? _safeParseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final cleaned = value.replaceAll(RegExp(r'[^\d.]'), '');
      return double.tryParse(cleaned);
    }
    return null;
  }

  // Generate a meal plan based on user profile
  Future<AIPlan> generateMealPlan(UserProfile userProfile,
      [Map<String, dynamic>? preferenceData]) async {
    // Check if API key is valid
    if (_geminiApiKey == null ||
        _geminiApiKey!.isEmpty ||
        _geminiApiKey == 'google-api-key-here') {
      print(
          "Error: Cannot generate meal plan. GEMINI_API_KEY is missing or invalid.");
      return _createDefaultMealPlan(userProfile);
    }

    // Parse the user's specific preferences
    final dietaryRestrictions = preferenceData?['dietaryRestrictions'] ?? [];
    final mealsPerDay = preferenceData?['mealsPerDay'] ?? 3;
    final includeSnacks = preferenceData?['includeSnacks'] ?? true;
    final calorieAdjustment = preferenceData?['calorieAdjustment'] ?? 0;
    final preferredCuisines = preferenceData?['preferredCuisines'] ?? [];
    final foodAllergies = preferenceData?['foodAllergies'] ?? '';
    final dislikedFoods = preferenceData?['dislikedFoods'] ?? '';
    final otherPreferences = preferenceData?['otherPreferences'] ?? '';

    // Calculate calorie targets based on user profile and adjustments
    final dailyCalories =
        userProfile.calculateDailyCalorieGoal() + calorieAdjustment;
    final macrosDistribution =
        userProfile.macroDistribution ?? userProfile.defaultMacroDistribution;
    final proteinGoal = dailyCalories *
        macrosDistribution['protein']! /
        4; // 4 calories per gram of protein
    final carbsGoal = dailyCalories *
        macrosDistribution['carbs']! /
        4; // 4 calories per gram of carbs
    final fatGoal = dailyCalories *
        macrosDistribution['fat']! /
        9; // 9 calories per gram of fat

    try {
      // Create the basic meal plan structure
      final id = _uuid.v4();
      const title = "Custom Meal Plan";
      const description =
          "AI-generated meal plan based on your profile and preferences";
      final planDays = <PlanDay>[];

      // Generate each day sequentially
      for (int dayNumber = 1; dayNumber <= 7; dayNumber++) {
        print("Generating meal plan for Day $dayNumber...");

        // Create a prompt specific to this day
        final singleDayPrompt = """
You are a professional nutritionist creating a personalized meal plan. Format your response as JSON.

Create a detailed meal plan for DAY $dayNumber of a 7-day plan for a user with the following profile:

Age: ${userProfile.age}
Gender: ${userProfile.gender}
Weight: ${userProfile.currentWeight}kg
Height: ${userProfile.height}cm
Body Fat: ${userProfile.bodyFat}%
Fitness Goal: ${userProfile.fitnessGoal.name}
Activity Level: ${userProfile.activityLevel.toString().split('.').last}

Dietary Requirements:
- Daily Calorie Target: ${dailyCalories.toInt()} calories
- Protein: ${(macrosDistribution['protein']! * 100).toInt()}% (${proteinGoal.toInt()}g)
- Carbs: ${(macrosDistribution['carbs']! * 100).toInt()}% (${carbsGoal.toInt()}g)
- Fat: ${(macrosDistribution['fat']! * 100).toInt()}% (${fatGoal.toInt()}g)
${dietaryRestrictions.isNotEmpty ? '- Dietary Restrictions: ${dietaryRestrictions.join(', ')}' : ''}
${foodAllergies.isNotEmpty ? '- Food Allergies: $foodAllergies' : ''}
${dislikedFoods.isNotEmpty ? '- Disliked Foods: $dislikedFoods' : ''}
- Meals per day: $mealsPerDay
- Include Snacks: ${includeSnacks ? 'Yes' : 'No'}
${preferredCuisines.isNotEmpty ? '- Preferred Cuisines: ${preferredCuisines.join(', ')}' : ''}
${otherPreferences.isNotEmpty ? '- Other Notes: $otherPreferences' : ''}

The plan should:
1. Include $mealsPerDay main meals${includeSnacks ? ' and 1-2 snacks' : ''}
2. Focus on whole, nutritious foods
3. Be practical and reasonably easy to prepare
4. Include approximate calories and macronutrients for each meal
5. Provide a COMPLETE and DETAILED list of ingredients for each meal with specific quantities
6. Include DETAILED step-by-step cooking instructions for each meal that are easy to follow

For the ingredients and cooking instructions:
- List ALL ingredients needed for each recipe, including spices and oils
- Specify exact quantities (e.g., "1 cup", "2 tablespoons", "150g")
- Include specific cooking times and temperatures where applicable
- Break down cooking instructions into clear, numbered steps
- Include preparation instructions (washing, chopping, etc.)
- Mention cooking methods (bake, sauté, steam, etc.)

Format the response as a JSON object with the following structure:
{
  "day": $dayNumber,
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
      "totalCalories": TOTAL_MEAL_CALORIES,
      "ingredients": ["1 cup rolled oats", "1 tbsp honey", "1/2 cup almond milk", ...],
      "cookingInstructions": "1. Combine oats and milk in a pot.\\n2. Bring to a simmer over medium heat and cook for 5 minutes, stirring occasionally.\\n3. Remove from heat and let stand for 2 minutes.\\n4. Stir in honey and serve with your favorite toppings."
    },
    ...
  ]
}
""";

        // Prepare the content for Gemini
        final content = [
          Content.text(singleDayPrompt),
        ];

        // Call Gemini API for this day
        final response = await _model.generateContent(
          content,
          generationConfig: GenerationConfig(
            temperature: 0.7,
            maxOutputTokens: 8192,
          ),
        );

        print("Raw Gemini response for Day $dayNumber:\n${response.text}");

        if (response.text == null || response.text!.trim().isEmpty) {
          print(
              "Error: Gemini response was null or blocked for Day $dayNumber.");
          // Add default day
          planDays.add(_createDefaultMealPlanDay(userProfile, dayNumber));
          continue;
        }

        // Parse the meal plan day from the response
        try {
          final dayPlan =
              await _parseMealPlanDay(response.text!, userProfile, dayNumber);
          planDays.add(dayPlan);
          print("Successfully generated meal plan for Day $dayNumber.");
        } catch (e) {
          print("Error parsing meal plan for Day $dayNumber: $e");
          // Add default day on error
          planDays.add(_createDefaultMealPlanDay(userProfile, dayNumber));
        }

        // Optional: add a small delay between API calls to avoid rate limits
        await Future.delayed(const Duration(milliseconds: 500));
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
      print('Error generating meal plan with Gemini: $e');
      // If there's an error, return a default plan
      return _createDefaultMealPlan(userProfile);
    }
  }

  Future<PlanDay> _parseMealPlanDay(
      String jsonResponse, UserProfile userProfile, int dayNumber) async {
    try {
      // Strip code fences
      String cleaned =
          jsonResponse.replaceAll(RegExp(r'```(json)?|```'), '').trim();

      // Find the first opening brace
      final jsonStart = cleaned.indexOf('{');
      if (jsonStart == -1) {
        throw const FormatException("No '{' found in Gemini response.");
      }

      // Count braces to find the last matching closing brace
      int braceCount = 0;
      int jsonEnd = -1;
      for (int i = jsonStart; i < cleaned.length; i++) {
        if (cleaned[i] == '{') braceCount++;
        if (cleaned[i] == '}') braceCount--;
        if (braceCount == 0) {
          jsonEnd = i;
          break;
        }
      }

      if (jsonEnd == -1) {
        throw const FormatException("No matching closing '}' found in JSON.");
      }

      final safeEnd =
          jsonEnd + 1 <= cleaned.length ? jsonEnd + 1 : cleaned.length;
      final jsonString = cleaned.substring(jsonStart, safeEnd);

      print(
          "Parsed JSON string (truncated): ${jsonString.substring(0, jsonString.length > 300 ? 300 : jsonString.length)}");

      final data = jsonDecode(jsonString);
      final meals = <Meal>[];

      if (data['meals'] is! List) {
        throw const FormatException(
            "Expected 'meals' to be a list in the JSON.");
      }

      for (var mealData in data['meals']) {
        if (mealData is! Map) continue;

        final mealName = mealData['name']?.toString() ?? 'Unnamed Meal';
        final mealType = _getMealTypeFromName(mealName);
        final mealItems = <MealItem>[];
        final mealNotes = mealData['notes']?.toString();

        // Ingredients
        List<String>? ingredients;
        if (mealData['ingredients'] is List) {
          ingredients = List<String>.from(mealData['ingredients']);
        }

        final cookingInstructions = mealData['cookingInstructions']?.toString();

        // Foods
        if (mealData['foods'] is List) {
          for (var foodData in mealData['foods']) {
            if (foodData is! Map) continue;

            double? safeParseDouble(dynamic value) {
              if (value is num) return value.toDouble();
              if (value is String) return double.tryParse(value);
              return null;
            }

            final foodItem = FoodItem(
              id: _uuid.v4(),
              name: foodData['name']?.toString() ?? 'Unnamed Food',
              calories: safeParseDouble(foodData['calories']) ?? 0,
              protein: safeParseDouble(foodData['protein']) ?? 0,
              carbs: safeParseDouble(foodData['carbs']) ?? 0,
              fat: safeParseDouble(foodData['fat']) ?? 0,
              description: foodData['quantity']?.toString(),
            );

            mealItems.add(MealItem(
              foodItem: foodItem,
              quantity: 1.0,
              servingSize: foodData['quantity']?.toString() ?? '1 serving',
            ));
          }
        }

        meals.add(Meal(
          id: _uuid.v4(),
          name: mealName,
          type: mealType,
          dateTime: DateTime.now().add(Duration(days: dayNumber - 1)),
          items: mealItems,
          notes: mealNotes,
          ingredients: ingredients,
          cookingInstructions: cookingInstructions,
        ));
      }

      return PlanDay(
        dayNumber: dayNumber,
        notes: 'Day $dayNumber meal plan',
        meals: meals,
      );
    } catch (e) {
      print('Error parsing meal plan day: $e');
      rethrow;
    }
  }

  // Create a default meal plan day (for fallback)
  PlanDay _createDefaultMealPlanDay(UserProfile userProfile, int dayNumber) {
    final dayDate = DateTime.now().add(Duration(days: dayNumber - 1));
    final meals = <Meal>[];

    // Base calorie estimate if AI fails - could use userProfile.calculateDailyCalorieGoal()
    // For simplicity, using fixed examples here. Actual implementation should be more dynamic.
    final targetCalories = userProfile.fitnessGoal == FitnessGoal.weightLoss
        ? 1800
        : userProfile.fitnessGoal == FitnessGoal.muscleGain
            ? 2500
            : 2200;

    // Add meals with sample data
    meals.add(_createSampleMeal(
        MealType.breakfast, dayDate, targetCalories * 0.25)); // 25% calories
    meals.add(_createSampleMeal(
        MealType.snack, dayDate, targetCalories * 0.10)); // 10% calories
    meals.add(_createSampleMeal(
        MealType.lunch, dayDate, targetCalories * 0.30)); // 30% calories
    meals.add(_createSampleMeal(
        MealType.snack, dayDate, targetCalories * 0.10)); // 10% calories
    meals.add(_createSampleMeal(
        MealType.dinner, dayDate, targetCalories * 0.25)); // 25% calories

    return PlanDay(
      dayNumber: dayNumber,
      meals: meals,
      notes:
          'Sample meal plan for Day $dayNumber aiming for approx ${targetCalories}kcal.',
    );
  }

  Future<String> getAIInsight(UserProfile userProfile,
      List<dynamic> recentWorkouts, List<dynamic> recentMeals) async {
    if (_geminiApiKey == null || _geminiApiKey!.isEmpty) {
      print("Error: GEMINI_API_KEY is missing.");
      return 'Stay consistent with your fitness routine and ensure you\'re getting enough hydration throughout the day.';
    }

    final prompt =
        _createInsightPrompt(userProfile, recentWorkouts, recentMeals);

    final List<String> styleVariants = [
      "Give a fresh, motivating tip:",
      "Offer a brief and inspiring fitness insight:",
      "Share a quick and energetic reminder to help the user stay on track:"
    ];
    final stylePrompt =
        styleVariants[_uuid.v4().hashCode % styleVariants.length];

    final content = [
      Content.text(
          "You are a highly motivating and practical AI fitness coach."),
      Content.text("$stylePrompt\n\n$prompt")
    ];

    try {
      final response = await _model.generateContent(
        content,
        generationConfig: GenerationConfig(
          temperature: 0.9, // Higher variety
          maxOutputTokens: 250,
          topP: 1.0,
          topK: 40,
        ),
      );

      if (response.text != null && response.text!.isNotEmpty) {
        return response.text!;
      } else {
        print(
            'Error: Gemini returned no text. Reason: ${response.promptFeedback?.blockReason?.name}');
        return 'Keep up the effort and remember — every step forward counts!';
      }
    } catch (e) {
      print('Gemini Insight Error: $e');
      return 'Stay consistent with your workouts and mindful of your nutrition.';
    }
  }

  Future<String> answerQuestion(
      String question, UserProfile userProfile) async {
    // Check API key
    if (_geminiApiKey == null ||
        _geminiApiKey!.isEmpty ||
        _geminiApiKey == 'google-api-key-here') {
      print(
          "Error: Cannot answer question. GEMINI_API_KEY is missing or invalid.");
      return "I'm sorry, but my AI capabilities are not configured correctly. Please check the API key setup.";
    }

    // System prompt defines the AI's behavior
    const systemPrompt = """
         You are 'Weight Watcher AI Trainer', an expert fitness coach and nutritionist AI.
         Your job is to motivate and guide users to achieve their health goals with high-impact, concise advice.
         Each response must be extremely concise — no more than 2–3 sentences.
         Use simple, encouraging language. Vary your tone slightly to keep responses fresh. You may include motivational phrases (e.g., "Keep pushing!" or "You're doing great!") occasionally.
         Be direct and practical — offer actionable tips or quick insights that change each time.
         It is okay to provide healthy advice on fat loss, weight management, and body composition when asked — focus on fitness, nutrition, and positive lifestyle changes.
         Do NOT provide any medical advice or diagnose conditions. If a question relates to medical concerns, direct the user to a healthcare provider.
         Avoid introductions or repeating the user's question.
         Do NOT use markdown formatting or asterisks.
          """;

    // User profile context
    final profileContext = '''
      Age: ${userProfile.age}
      Gender: ${userProfile.gender}
      Current Weight: ${userProfile.currentWeight} kg
      Goal Weight: ${userProfile.targetWeight} kg
      Height: ${userProfile.height} cm
      Body Fat: ${userProfile.bodyFat}%
      Fitness Goal: ${userProfile.fitnessGoal.name}
      Activity Level: ${userProfile.activityLevel.toString().split('.').last}
      ''';

    final content = [
      Content.text(systemPrompt), // System prompt
      Content.text(
          'Here is my profile:\n$profileContext\n\nMy question is: $question'),
    ];

    try {
      final response = await _model.generateContent(content);

      /*final response = await _model.generateContent(
        content,
        generationConfig:
            _defaultConfig, // reuse the one defined in constructor
      );*/

      if (response.text != null && response.text!.isNotEmpty) {
        return response.text!;
      } else {
        print(
            'Error: Gemini response was null or blocked. Reason: ${response.promptFeedback?.blockReason?.name}');
        return "I couldn't generate a response. This might be due to safety settings or a technical issue. Try rephrasing your question.";
      }
    } catch (e) {
      print('Error answering question with Gemini: $e');
      if (e is GenerativeAIException) {
        return "I encountered an issue communicating with the AI service (${e.message}). Please try again later.";
      }
      return 'I\'m experiencing technical difficulties processing your request. Please check your connection and try again later.';
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
    // Calculate calorie targets based on user profile
    final dailyCalories = userProfile.calculateDailyCalorieGoal();
    final macrosDistribution =
        userProfile.macroDistribution ?? userProfile.defaultMacroDistribution;
    final proteinGoal = dailyCalories *
        macrosDistribution['protein']! /
        4; // 4 calories per gram of protein
    final carbsGoal = dailyCalories *
        macrosDistribution['carbs']! /
        4; // 4 calories per gram of carbs
    final fatGoal = dailyCalories *
        macrosDistribution['fat']! /
        9; // 9 calories per gram of fat

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
    - Protein: ${(macrosDistribution['protein']! * 100).toInt()}% (${(dailyCalories * macrosDistribution['protein']! / 4).toInt()}g)
    - Carbs: ${(macrosDistribution['carbs']! * 100).toInt()}% (${(dailyCalories * macrosDistribution['carbs']! / 4).toInt()}g)
    - Fat: ${(macrosDistribution['fat']! * 100).toInt()}% (${(dailyCalories * macrosDistribution['fat']! / 9).toInt()}g)
    
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
  String _createInsightPrompt(UserProfile userProfile,
      List<dynamic> recentWorkouts, List<dynamic> recentMeals) {
    String formattedWorkouts;
    if (recentWorkouts.isEmpty) {
      formattedWorkouts = "The user has not logged any workouts this week.";
    } else {
      num totalMinutes = 0;
      for (var workout in recentWorkouts) {
        if (workout.duration != null) {
          totalMinutes += workout.duration.inMinutes;
        }
      }
      formattedWorkouts =
          "${recentWorkouts.length} workouts logged this week, totaling about $totalMinutes minutes.";
    }

    String mealSummary = recentMeals.isEmpty
        ? "No recent meals logged."
        : "Recent meals average ${(recentMeals.fold(0.0, (sum, meal) => sum + (meal.totalCalories ?? 0.0)) / (recentMeals.length)).round()} calories per meal.";

    final fitnessLevel = _determineFitnessLevel(userProfile);

    return '''
You are a fitness and nutrition AI providing personalized, positive insights.

User Profile:
- Age: ${userProfile.age}
- Weight: ${userProfile.currentWeight}kg (Goal: ${userProfile.targetWeight}kg)
- Body Fat: ${userProfile.bodyFat.toStringAsFixed(1)}%
- Muscle Mass: ${userProfile.muscleMass.toStringAsFixed(1)}%
- Height: ${userProfile.height} cm
- Fitness Goal: ${userProfile.fitnessGoal.name}
- Activity Level: ${userProfile.activityLevel.toString().split('.').last}
- Estimated Fitness Level: $fitnessLevel

Activity Summary:
- $formattedWorkouts
- $mealSummary

When writing the insight:
- Use 1–2 clear sentences
- Use a varied tone: friendly, calm, confident, motivating
- Start with a greeting **only 30–50% of the time**
  - Examples: "Hey champ", "You've got this", "Quick reminder", "Heads up", or no greeting at all
- End with a **unique motivational nudge**
  - Examples: "Small wins lead to big changes.", "You're stronger than you think.", "Keep showing up.", "Fuel your progress.", "Consistency creates confidence."
- Tailor the advice to the user's stats and habits
- Do not repeat greetings, tips, or advice often
- Do not include any medical disclaimers
- Do not use formatting, asterisks, or bullet points

Respond with the insight **text only**.
''';
  }

// Determine fitness level based on profile and activity
  String _determineFitnessLevel(UserProfile userProfile) {
    if (userProfile.activityLevel == ActivityLevel.sedentary ||
        userProfile.activityLevel == ActivityLevel.lightlyActive) {
      return 'Beginner';
    } else if (userProfile.activityLevel == ActivityLevel.moderatelyActive) {
      return 'Intermediate';
    } else {
      return 'Advanced';
    }
  }

  AIPlan _parseMealPlanResponse(String jsonResponse, UserProfile userProfile) {
    try {
      // Extract JSON from the response (in case there's markdown or other text)
      final jsonStart = jsonResponse.indexOf('{');
      final jsonEnd = jsonResponse.lastIndexOf('}') + 1;
      if (jsonStart == -1 || jsonEnd == 0) {
        throw const FormatException(
            "Could not find JSON object in the response.");
      }
      final cleaned =
          jsonResponse.replaceAll(RegExp(r'```json|```'), '').trim();
      final jsonString = cleaned.substring(jsonStart, jsonEnd);

      final data = jsonDecode(jsonString);

      final id = _uuid.v4();
      final title = data['title']?.toString() ?? 'Custom Meal Plan';
      final description = data['description']?.toString() ??
          'AI-generated meal plan based on your profile.';

      // Create plan days
      final List<PlanDay> planDays = [];
      if (data['days'] is! List) {
        throw const FormatException(
            "Expected 'days' to be a list in the JSON response.");
      }

      for (var dayData in data['days']) {
        if (dayData is! Map) continue; // Skip invalid day entries

        final dayNumberDynamic = dayData['day'];
        if (dayNumberDynamic is! num) continue; // Skip invalid day number

        final int dayNumber = (dayNumberDynamic).toInt();
        final notes = dayData['notes']?.toString() ?? 'Nutrition-focused day';
        final meals = <Meal>[];

        if (dayData['meals'] is List) {
          for (var mealData in dayData['meals']) {
            if (mealData is! Map) continue; // Skip invalid meal entries

            final mealName = mealData['name']?.toString() ?? 'Unnamed Meal';
            final mealType = _getMealTypeFromName(mealName);
            final mealItems = <MealItem>[];
            final mealNotes = mealData['notes']?.toString(); // Allow null notes

            // Parse ingredients (new)
            List<String>? ingredients;
            if (mealData['ingredients'] is List) {
              ingredients = List<String>.from(mealData['ingredients']);
            }

            // Parse cooking instructions (new)
            final cookingInstructions =
                mealData['cookingInstructions']?.toString();

            if (mealData['foods'] is List) {
              for (var foodData in mealData['foods']) {
                if (foodData is! Map) continue; // Skip invalid food entries

                // Helper function to safely parse numbers
                double? safeParseDouble(dynamic value) {
                  if (value is num) return value.toDouble();
                  if (value is String) return double.tryParse(value);
                  return null;
                }

                final foodItem = FoodItem(
                  id: _uuid.v4(),
                  name: foodData['name']?.toString() ?? 'Unnamed Food',
                  calories: safeParseDouble(foodData['calories']) ?? 0,
                  protein: safeParseDouble(foodData['protein']) ?? 0,
                  carbs: safeParseDouble(foodData['carbs']) ?? 0,
                  fat: safeParseDouble(foodData['fat']) ?? 0,
                  description: foodData['quantity']
                      ?.toString(), // Use quantity as description
                );

                mealItems.add(MealItem(
                  foodItem: foodItem,
                  quantity: 1.0, // Assume quantity 1 unless specified otherwise
                  servingSize: foodData['quantity']?.toString() ??
                      '1 serving', // Use quantity as serving size
                ));
              }
            }

            meals.add(Meal(
              id: _uuid.v4(),
              name: mealName,
              type: mealType,
              dateTime: DateTime.now()
                  .add(Duration(days: dayNumber - 1)), // Approximate time
              items: mealItems,
              notes: mealNotes,
              ingredients: ingredients,
              cookingInstructions: cookingInstructions,
            ));
          }
        }

        planDays.add(PlanDay(
          dayNumber: dayNumber,
          notes: notes,
          meals: meals,
        ));
      }

      return AIPlan(
        id: id,
        title: title,
        description: description,
        type: PlanType.nutrition,
        startDate: DateTime.now(),
        endDate: DateTime.now()
            .add(const Duration(days: 7)), // Assuming 7-day plan default
        days: planDays,
        targetProfile: userProfile,
      );
    } catch (e) {
      print('Error parsing meal plan: $e');
      // Consider logging the jsonResponse
      return _createDefaultMealPlan(userProfile); // Fallback
    }
  }

  // Get meal type from name
  MealType _getMealTypeFromName(String name) {
    final lowerCaseName = name.toLowerCase();
    if (lowerCaseName.contains('breakfast')) {
      return MealType.breakfast;
    } else if (lowerCaseName.contains('lunch')) {
      return MealType.lunch;
    } else if (lowerCaseName.contains('dinner')) {
      return MealType.dinner;
    } else if (lowerCaseName.contains('snack')) {
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
      case 'rest':
        return WorkoutType.rest;
      case 'hiit': // Added HIIT
        return WorkoutType.hiit;
      default:
        return WorkoutType.other;
    }
  }

  // Estimate calories burned for a workout
  double _estimateCaloriesBurned(
      List<Exercise> exercises, int durationMinutes, UserProfile userProfile) {
    // Ensure duration is positive
    if (durationMinutes <= 0) return 0;

    // MET values approximation per workout type
    // Source: Compendium of Physical Activities (Ainsworth et al.) - simplified
    double metValue;
    switch (exercises.isEmpty
        ? WorkoutType.other
        : _determineWorkoutType(exercises)) {
      case WorkoutType.strength:
        metValue = 3.5; // General strength training
        break;
      case WorkoutType.cardio:
        metValue = 7.0; // Moderate cardio (like jogging)
        break;
      case WorkoutType.hiit:
        metValue = 8.0; // High-intensity interval training
        break;
      case WorkoutType.flexibility:
        metValue = 2.5; // Stretching, Yoga
        break;
      case WorkoutType.balance:
        metValue = 2.5;
        break;
      case WorkoutType.sports:
        metValue = 6.0; // Generic sports estimate
        break;
      case WorkoutType.rest:
        metValue = 1.0; // Resting MET
        break;
      case WorkoutType.other:
        metValue = 3.0; // Light activity
        break;
    }

    // Formula: Calories Burned = MET * Body Weight (kg) * Duration (hours) * (3.5 / 200) -> simplified to MET * weight * duration_hr
    // More standard formula: MET * 3.5 * bodyWeightKg / 200 * durationMinutes
    final caloriesPerMinute = metValue * 3.5 * userProfile.currentWeight / 200;
    return caloriesPerMinute * durationMinutes;
  }

  // Determine workout type based on exercises
  WorkoutType _determineWorkoutType(List<Exercise> exercises) {
    if (exercises.isEmpty) return WorkoutType.other;

    // Count exercise types based on keywords
    int strengthCount = 0;
    int cardioCount = 0;
    int flexibilityCount = 0;
    int hiitCount = 0; // Added HIIT counter

    for (var exercise in exercises) {
      final name = exercise.name.toLowerCase();
      // Prioritize HIIT if keywords match
      if (name.contains('burpee') ||
          name.contains('interval') ||
          name.contains('tabata') ||
          name.contains('hiit')) {
        hiitCount++;
      } else if (name.contains('push') ||
          name.contains('pull') ||
          name.contains('press') ||
          name.contains('curl') ||
          name.contains('squat') ||
          name.contains('deadlift') ||
          name.contains('row') ||
          name.contains('raise') ||
          name.contains('extension')) {
        strengthCount++;
      } else if (name.contains('run') ||
          name.contains('jog') ||
          name.contains('sprint') ||
          name.contains('cycle') ||
          name.contains('elliptical') ||
          name.contains('swim') ||
          name.contains('jump') ||
          name.contains('cardio')) {
        cardioCount++;
      } else if (name.contains('stretch') ||
          name.contains('yoga') ||
          name.contains('flex') ||
          name.contains('mobility') ||
          name.contains('foam roll')) {
        flexibilityCount++;
      }
    }

    // Determine primary type based on counts (prioritize HIIT)
    if (hiitCount > 0 &&
        hiitCount >= strengthCount &&
        hiitCount >= cardioCount &&
        hiitCount >= flexibilityCount) {
      return WorkoutType.hiit;
    } else if (strengthCount >= cardioCount &&
        strengthCount >= flexibilityCount) {
      return WorkoutType.strength;
    } else if (cardioCount >= strengthCount &&
        cardioCount >= flexibilityCount) {
      return WorkoutType.cardio;
    } else if (flexibilityCount > 0) {
      // Flexibility only if explicitly present
      return WorkoutType.flexibility;
    } else {
      return WorkoutType.other; // Default if no clear type
    }
  }

  // Create a default workout plan if API generation fails
  AIPlan _createDefaultWorkoutPlan(UserProfile userProfile) {
    final id = _uuid.v4();
    final List<PlanDay> planDays = [];
    final now = DateTime.now();

    // Create a simple 4-week plan based on user's goal
    for (int day = 1; day <= 28; day++) {
      final dayOfWeek = day % 7; // 1 = Monday, ..., 0 = Sunday
      final workoutDate = now.add(Duration(days: day - 1));
      Workout? workout; // Nullable workout
      String notes = '';

      // Rest days on Sundays (dayOfWeek == 0)
      if (dayOfWeek == 0) {
        notes =
            'Rest day - focus on recovery and active rest like light walking or stretching.';
        workout = Workout(
          id: _uuid.v4(),
          name: 'Rest Day',
          dateTime: workoutDate,
          duration: Duration.zero,
          type: WorkoutType.rest,
          exercises: [],
          caloriesBurned: 0,
          notes: notes,
        );
      } else {
        // Assign workouts based on goal and day
        if (userProfile.fitnessGoal == FitnessGoal.weightLoss) {
          workout = _createDefaultWeightLossWorkout(dayOfWeek, workoutDate);
          notes = workout.notes ?? 'Weight Loss Focus Workout';
        } else if (userProfile.fitnessGoal == FitnessGoal.muscleGain) {
          workout = _createDefaultMuscleGainWorkout(dayOfWeek, workoutDate);
          notes = workout.notes ?? 'Muscle Gain Focus Workout';
        } else {
          // Maintenance
          workout = _createDefaultMaintenanceWorkout(dayOfWeek, workoutDate);
          notes = workout.notes ?? 'Balanced Fitness Workout';
        }

        // Estimate calories for non-rest days if workout exists
        workout = Workout(
          id: workout.id,
          name: workout.name,
          dateTime: workout.dateTime,
          duration: workout.duration,
          type: workout.type,
          exercises: workout.exercises,
          caloriesBurned: _estimateCaloriesBurned(
                  workout.exercises, workout.duration.inMinutes, userProfile)
              .toInt(),
          notes: workout.notes,
        );
        notes = workout.notes ?? ''; // Update notes from workout if available
      }

      planDays.add(PlanDay(
        dayNumber: day,
        workout:
            workout, // Can be null if no specific workout assigned (though unlikely with current logic)
        notes: notes,
        summary: workout.name ?? 'Rest or Light Activity', // Provide a summary
      ));
    }

    String planTitle;
    String planDescription;

    switch (userProfile.fitnessGoal) {
      case FitnessGoal.weightLoss:
        planTitle = 'Default Fat Loss Workout Plan';
        planDescription =
            'A basic 4-week plan combining cardio and strength to support weight loss when AI generation fails.';
        break;
      case FitnessGoal.muscleGain:
        planTitle = 'Default Muscle Building Program';
        planDescription =
            'A basic 4-week strength-focused plan for muscle gain when AI generation fails.';
        break;
      case FitnessGoal.maintenance:
      default:
        planTitle = 'Default Balanced Fitness Plan';
        planDescription =
            'A basic 4-week plan with mixed activities for general fitness when AI generation fails.';
        break;
    }

    return AIPlan(
      id: id,
      title: planTitle,
      description: planDescription,
      type: PlanType.workout,
      startDate: now,
      endDate: now.add(const Duration(days: 28)),
      days: planDays,
      targetProfile: userProfile,
    );
  }

  // Helper to create weight loss workout for a specific day
  Workout _createDefaultWeightLossWorkout(int dayOfWeek, DateTime date) {
    List<Exercise> exercises = [];
    String name = '';
    WorkoutType type = WorkoutType.other;

    switch (dayOfWeek) {
      case 1: // Mon: Full Body Strength
      case 4: // Thu: Full Body Strength
        name = 'Full Body Strength';
        type = WorkoutType.strength;
        exercises = [
          Exercise(
              id: _uuid.v4(),
              name: 'Goblet Squats',
              sets: [
                ExerciseSet(reps: 12),
                ExerciseSet(reps: 12),
                ExerciseSet(reps: 12)
              ],
              targetMuscleGroup: 'Legs'),
          Exercise(
              id: _uuid.v4(),
              name: 'Push-ups (on knees if needed)',
              sets: [
                ExerciseSet(reps: 10),
                ExerciseSet(reps: 10),
                ExerciseSet(reps: 10)
              ],
              targetMuscleGroup: 'Chest/Triceps'),
          Exercise(
              id: _uuid.v4(),
              name: 'Dumbbell Rows',
              sets: [
                ExerciseSet(reps: 12),
                ExerciseSet(reps: 12),
                ExerciseSet(reps: 12)
              ],
              targetMuscleGroup: 'Back/Biceps'),
          Exercise(
              id: _uuid.v4(),
              name: 'Plank',
              duration: const Duration(seconds: 30),
              sets: [
                ExerciseSet(reps: 1),
                ExerciseSet(reps: 1),
                ExerciseSet(reps: 1)
              ],
              targetMuscleGroup: 'Core'),
        ];
        break;
      case 2: // Tue: Cardio HIIT
      case 5: // Fri: Cardio HIIT
        name = 'Cardio HIIT';
        type = WorkoutType.hiit;
        exercises = [
          Exercise(
              id: _uuid.v4(),
              name: 'Jumping Jacks (Warm-up)',
              duration: const Duration(minutes: 2),
              targetMuscleGroup: 'Full Body'),
          Exercise(
              id: _uuid.v4(),
              name: 'High Knees (30s work, 30s rest)',
              sets: [
                ExerciseSet(reps: 1),
                ExerciseSet(reps: 1),
                ExerciseSet(reps: 1),
                ExerciseSet(reps: 1)
              ],
              targetMuscleGroup: 'Full Body'),
          Exercise(
              id: _uuid.v4(),
              name: 'Burpees (30s work, 30s rest)',
              sets: [
                ExerciseSet(reps: 1),
                ExerciseSet(reps: 1),
                ExerciseSet(reps: 1),
                ExerciseSet(reps: 1)
              ],
              targetMuscleGroup: 'Full Body'),
          Exercise(
              id: _uuid.v4(),
              name: 'Mountain Climbers (30s work, 30s rest)',
              sets: [
                ExerciseSet(reps: 1),
                ExerciseSet(reps: 1),
                ExerciseSet(reps: 1),
                ExerciseSet(reps: 1)
              ],
              targetMuscleGroup: 'Core/Full Body'),
          Exercise(
              id: _uuid.v4(),
              name: 'Cool-down walk',
              duration: const Duration(minutes: 5),
              targetMuscleGroup: 'Full Body'),
        ];
        break;
      case 3: // Wed: Active Recovery / Light Cardio
      case 6: // Sat: Active Recovery / Light Cardio
        name = 'Active Recovery / Light Cardio';
        type = WorkoutType.cardio; // Or flexibility
        exercises = [
          Exercise(
              id: _uuid.v4(),
              name: 'Brisk Walking or Light Jogging',
              duration: const Duration(minutes: 30),
              targetMuscleGroup: 'Cardiovascular'),
          Exercise(
              id: _uuid.v4(),
              name: 'Light Stretching',
              duration: const Duration(minutes: 10),
              targetMuscleGroup: 'Full Body'),
        ];
        break;
    }

    return Workout(
      id: _uuid.v4(),
      name: name,
      dateTime: date,
      duration: const Duration(minutes: 45), // Default duration
      type: type,
      exercises: exercises,
      caloriesBurned: 200, // Default calories burned value
      notes:
          '$name focusing on calorie expenditure and improving cardiovascular health.',
    );
  }

  // Helper to create muscle gain workout for a specific day
  Workout _createDefaultMuscleGainWorkout(int dayOfWeek, DateTime date) {
    List<Exercise> exercises = [];
    String name = '';
    WorkoutType type = WorkoutType.strength;

    switch (dayOfWeek) {
      case 1: // Mon: Upper Body Push (Chest, Shoulders, Triceps)
        name = 'Upper Body Push';
        exercises = [
          Exercise(
              id: _uuid.v4(),
              name: 'Bench Press (or Dumbbell Press)',
              sets: [
                ExerciseSet(reps: 8),
                ExerciseSet(reps: 8),
                ExerciseSet(reps: 8)
              ],
              targetMuscleGroup: 'Chest'),
          Exercise(
              id: _uuid.v4(),
              name: 'Overhead Press',
              sets: [
                ExerciseSet(reps: 10),
                ExerciseSet(reps: 10),
                ExerciseSet(reps: 10)
              ],
              targetMuscleGroup: 'Shoulders'),
          Exercise(
              id: _uuid.v4(),
              name: 'Tricep Dips (or Extensions)',
              sets: [
                ExerciseSet(reps: 12),
                ExerciseSet(reps: 12),
                ExerciseSet(reps: 12)
              ],
              targetMuscleGroup: 'Triceps'),
          Exercise(
              id: _uuid.v4(),
              name: 'Lateral Raises',
              sets: [
                ExerciseSet(reps: 15),
                ExerciseSet(reps: 15),
                ExerciseSet(reps: 15)
              ],
              targetMuscleGroup: 'Shoulders'),
        ];
        break;
      case 2: // Tue: Lower Body (Quads, Hamstrings, Glutes, Calves)
        name = 'Lower Body';
        exercises = [
          Exercise(
              id: _uuid.v4(),
              name: 'Barbell Squats',
              sets: [
                ExerciseSet(reps: 8),
                ExerciseSet(reps: 8),
                ExerciseSet(reps: 8)
              ],
              targetMuscleGroup: 'Legs/Glutes'),
          Exercise(
              id: _uuid.v4(),
              name: 'Romanian Deadlifts',
              sets: [
                ExerciseSet(reps: 10),
                ExerciseSet(reps: 10),
                ExerciseSet(reps: 10)
              ],
              targetMuscleGroup: 'Hamstrings/Glutes'),
          Exercise(
              id: _uuid.v4(),
              name: 'Leg Press',
              sets: [
                ExerciseSet(reps: 12),
                ExerciseSet(reps: 12),
                ExerciseSet(reps: 12)
              ],
              targetMuscleGroup: 'Legs'),
          Exercise(
              id: _uuid.v4(),
              name: 'Calf Raises',
              sets: [
                ExerciseSet(reps: 15),
                ExerciseSet(reps: 15),
                ExerciseSet(reps: 15)
              ],
              targetMuscleGroup: 'Calves'),
        ];
        break;
      case 3: // Wed: Rest or Active Recovery
        name = 'Active Recovery / Light Activity';
        type = WorkoutType.other; // Or flexibility
        exercises = [
          Exercise(
              id: _uuid.v4(),
              name: 'Light walk or stretching',
              duration: const Duration(minutes: 30),
              targetMuscleGroup: 'Full Body')
        ];
        break;
      case 4: // Thu: Upper Body Pull (Back, Biceps)
        name = 'Upper Body Pull';
        exercises = [
          Exercise(
              id: _uuid.v4(),
              name: 'Pull-ups (or Lat Pulldowns)',
              sets: [
                ExerciseSet(reps: 8),
                ExerciseSet(reps: 8),
                ExerciseSet(reps: 8)
              ],
              targetMuscleGroup: 'Back/Biceps'),
          Exercise(
              id: _uuid.v4(),
              name: 'Barbell Rows',
              sets: [
                ExerciseSet(reps: 10),
                ExerciseSet(reps: 10),
                ExerciseSet(reps: 10)
              ],
              targetMuscleGroup: 'Back'),
          Exercise(
              id: _uuid.v4(),
              name: 'Face Pulls',
              sets: [
                ExerciseSet(reps: 15),
                ExerciseSet(reps: 15),
                ExerciseSet(reps: 15)
              ],
              targetMuscleGroup: 'Shoulders/Back'),
          Exercise(
              id: _uuid.v4(),
              name: 'Bicep Curls',
              sets: [
                ExerciseSet(reps: 12),
                ExerciseSet(reps: 12),
                ExerciseSet(reps: 12)
              ],
              targetMuscleGroup: 'Biceps'),
        ];
        break;
      case 5: // Fri: Lower Body / Core
        name = 'Lower Body & Core';
        exercises = [
          Exercise(
              id: _uuid.v4(),
              name: 'Front Squats',
              sets: [
                ExerciseSet(reps: 10),
                ExerciseSet(reps: 10),
                ExerciseSet(reps: 10)
              ],
              targetMuscleGroup: 'Quads/Glutes'),
          Exercise(
              id: _uuid.v4(),
              name: 'Hamstring Curls',
              sets: [
                ExerciseSet(reps: 12),
                ExerciseSet(reps: 12),
                ExerciseSet(reps: 12)
              ],
              targetMuscleGroup: 'Hamstrings'),
          Exercise(
              id: _uuid.v4(),
              name: 'Leg Extensions',
              sets: [
                ExerciseSet(reps: 15),
                ExerciseSet(reps: 15),
                ExerciseSet(reps: 15)
              ],
              targetMuscleGroup: 'Quads'),
          Exercise(
              id: _uuid.v4(),
              name: 'Hanging Leg Raises',
              sets: [
                ExerciseSet(reps: 15),
                ExerciseSet(reps: 15),
                ExerciseSet(reps: 15)
              ],
              targetMuscleGroup: 'Core'),
        ];
        break;
      case 6: // Sat: Rest or Optional Light Cardio/Mobility
        name = 'Optional Light Activity';
        type = WorkoutType.other;
        exercises = [
          Exercise(
              id: _uuid.v4(),
              name: 'Optional light cardio or mobility work',
              duration: const Duration(minutes: 30),
              targetMuscleGroup: 'Full Body')
        ];
        break;
    }

    return Workout(
      id: _uuid.v4(),
      name: name,
      dateTime: date,
      duration: const Duration(minutes: 60), // Longer default for strength
      type: type,
      exercises: exercises,
      caloriesBurned: 250, // Default calories burned for strength training
      notes: '$name focusing on progressive overload for muscle hypertrophy.',
    );
  }

  // Helper to create maintenance workout for a specific day
  Workout _createDefaultMaintenanceWorkout(int dayOfWeek, DateTime date) {
    List<Exercise> exercises = [];
    String name = '';
    WorkoutType type = WorkoutType.other;

    switch (dayOfWeek) {
      case 1: // Mon: Full Body Strength A
        name = 'Full Body Strength A';
        type = WorkoutType.strength;
        exercises = [
          Exercise(
              id: _uuid.v4(),
              name: 'Squats',
              sets: [
                ExerciseSet(reps: 10),
                ExerciseSet(reps: 10),
                ExerciseSet(reps: 10)
              ],
              targetMuscleGroup: 'Legs/Glutes'),
          Exercise(
              id: _uuid.v4(),
              name: 'Bench Press',
              sets: [
                ExerciseSet(reps: 10),
                ExerciseSet(reps: 10),
                ExerciseSet(reps: 10)
              ],
              targetMuscleGroup: 'Chest'),
          Exercise(
              id: _uuid.v4(),
              name: 'Barbell Rows',
              sets: [
                ExerciseSet(reps: 10),
                ExerciseSet(reps: 10),
                ExerciseSet(reps: 10)
              ],
              targetMuscleGroup: 'Back'),
        ];
        break;
      case 2: // Tue: Light Cardio / Active Recovery
        name = 'Light Cardio / Active Recovery';
        type = WorkoutType.cardio;
        exercises = [
          Exercise(
              id: _uuid.v4(),
              name: 'Brisk walking or cycling',
              duration: const Duration(minutes: 30),
              targetMuscleGroup: 'Cardiovascular')
        ];
        break;
      case 3: // Wed: Full Body Strength B
        name = 'Full Body Strength B';
        type = WorkoutType.strength;
        exercises = [
          Exercise(
              id: _uuid.v4(),
              name: 'Deadlifts (conventional or Romanian)',
              sets: [ExerciseSet(reps: 8), ExerciseSet(reps: 8)],
              targetMuscleGroup: 'Back/Legs/Glutes'),
          Exercise(
              id: _uuid.v4(),
              name: 'Overhead Press',
              sets: [
                ExerciseSet(reps: 10),
                ExerciseSet(reps: 10),
                ExerciseSet(reps: 10)
              ],
              targetMuscleGroup: 'Shoulders'),
          Exercise(
              id: _uuid.v4(),
              name: 'Pull-ups (or Lat Pulldowns)',
              sets: [
                ExerciseSet(reps: 10),
                ExerciseSet(reps: 10),
                ExerciseSet(reps: 10)
              ],
              targetMuscleGroup: 'Back/Biceps'),
        ];
        break;
      case 4: // Thu: Rest or Mobility/Flexibility
        name = 'Mobility & Flexibility';
        type = WorkoutType.flexibility;
        exercises = [
          Exercise(
              id: _uuid.v4(),
              name: 'Yoga or Dynamic Stretching',
              duration: const Duration(minutes: 30),
              targetMuscleGroup: 'Full Body')
        ];
        break;
      case 5: // Fri: Full Body Strength A (Repeat) or Optional activity
        name = 'Full Body Strength A (Repeat)';
        type = WorkoutType.strength;
        exercises = [
          // Same as Monday
          Exercise(
              id: _uuid.v4(),
              name: 'Squats',
              sets: [
                ExerciseSet(reps: 10),
                ExerciseSet(reps: 10),
                ExerciseSet(reps: 10)
              ],
              targetMuscleGroup: 'Legs/Glutes'),
          Exercise(
              id: _uuid.v4(),
              name: 'Bench Press',
              sets: [
                ExerciseSet(reps: 10),
                ExerciseSet(reps: 10),
                ExerciseSet(reps: 10)
              ],
              targetMuscleGroup: 'Chest'),
          Exercise(
              id: _uuid.v4(),
              name: 'Barbell Rows',
              sets: [
                ExerciseSet(reps: 10),
                ExerciseSet(reps: 10),
                ExerciseSet(reps: 10)
              ],
              targetMuscleGroup: 'Back'),
        ];
        break;
      case 6: // Sat: Longer Cardio or Recreational Activity
        name = 'Longer Cardio / Activity';
        type = WorkoutType.cardio; // Or Sports
        exercises = [
          Exercise(
              id: _uuid.v4(),
              name: 'Jogging, Hiking, Cycling, or Sport',
              duration: const Duration(minutes: 45),
              targetMuscleGroup: 'Cardiovascular'),
        ];
        break;
    }

    return Workout(
      id: _uuid.v4(),
      name: name,
      dateTime: date,
      duration: const Duration(minutes: 50), // Average duration
      type: type,
      exercises: exercises,
      caloriesBurned: 225, // Default calories burned for maintenance
      notes: '$name for maintaining overall fitness and health.',
    );
  }

  // Create a default meal plan if API generation fails
  AIPlan _createDefaultMealPlan(UserProfile userProfile) {
    final id = _uuid.v4();
    final List<PlanDay> planDays = [];
    final now = DateTime.now();

    // Base calorie estimate if AI fails - could use userProfile.calculateDailyCalorieGoal()
    // For simplicity, using fixed examples here. Actual implementation should be more dynamic.
    final targetCalories = userProfile.fitnessGoal == FitnessGoal.weightLoss
        ? 1800
        : userProfile.fitnessGoal == FitnessGoal.muscleGain
            ? 2500
            : 2200;

    // Create a simple 7-day meal plan structure
    for (int day = 1; day <= 7; day++) {
      final dayDate = now.add(Duration(days: day - 1));
      final meals = <Meal>[];

      // Add meals with sample data (adjust based on targetCalories if desired)
      meals.add(_createSampleMeal(
          MealType.breakfast, dayDate, targetCalories * 0.25)); // 25% calories
      meals.add(_createSampleMeal(
          MealType.snack, dayDate, targetCalories * 0.10)); // 10% calories
      meals.add(_createSampleMeal(
          MealType.lunch, dayDate, targetCalories * 0.30)); // 30% calories
      meals.add(_createSampleMeal(
          MealType.snack, dayDate, targetCalories * 0.10)); // 10% calories
      meals.add(_createSampleMeal(
          MealType.dinner, dayDate, targetCalories * 0.25)); // 25% calories

      planDays.add(PlanDay(
        dayNumber: day,
        meals: meals,
        notes:
            'Sample meal plan for Day $day aiming for approx ${targetCalories}kcal.',
        summary: 'Breakfast, Lunch, Dinner, 2 Snacks (~$targetCalories kcal)',
      ));
    }

    String planTitle;
    String planDescription;

    switch (userProfile.fitnessGoal) {
      case FitnessGoal.weightLoss:
        planTitle = 'Default Weight Loss Meal Plan';
        planDescription =
            'A basic 7-day sample meal plan (~$targetCalories kcal/day) when AI generation fails.';
        break;
      case FitnessGoal.muscleGain:
        planTitle = 'Default Muscle Building Meal Plan';
        planDescription =
            'A basic 7-day sample meal plan (~$targetCalories kcal/day) when AI generation fails.';
        break;
      case FitnessGoal.maintenance:
      default:
        planTitle = 'Default Balanced Nutrition Plan';
        planDescription =
            'A basic 7-day sample meal plan (~$targetCalories kcal/day) when AI generation fails.';
        break;
    }

    return AIPlan(
      id: id,
      title: planTitle,
      description: planDescription,
      type: PlanType.nutrition,
      startDate: now,
      endDate: now.add(const Duration(days: 7)),
      days: planDays,
      targetProfile: userProfile,
    );
  }

  // Helper to create a sample meal with approximate nutritional info
  Meal _createSampleMeal(MealType type, DateTime date, double targetCalories) {
    String name = '';
    List<MealItem> items = [];
    DateTime mealTime;
    List<String> ingredients = [];
    String cookingInstructions = '';

    // Simplified macro split: 40% Carbs, 30% Protein, 30% Fat
    final proteinGrams = (targetCalories * 0.30) / 4;
    final carbsGrams = (targetCalories * 0.40) / 4;
    final fatGrams = (targetCalories * 0.30) / 9;

    switch (type) {
      case MealType.breakfast:
        name = 'Breakfast';
        mealTime = DateTime(date.year, date.month, date.day, 8); // 8 AM

        ingredients = [
          "2/3 cup rolled oats",
          "1 cup unsweetened almond milk",
          "1 tablespoon honey or maple syrup",
          "1/2 teaspoon cinnamon",
          "1 medium banana, sliced",
          "1 tablespoon chia seeds",
          "2 tablespoons chopped walnuts",
          "1/4 cup fresh berries (blueberries, strawberries, etc.)"
        ];

        cookingInstructions =
            "1. Combine oats and almond milk in a small pot.\n"
            "2. Bring to a simmer over medium heat and cook for 5-7 minutes, stirring occasionally, until oats are soft and creamy.\n"
            "3. Remove from heat and stir in honey and cinnamon.\n"
            "4. Transfer to a bowl and top with sliced banana, chia seeds, walnuts, and berries.\n"
            "5. Allow to cool slightly before serving.";

        items = [
          MealItem(
            foodItem: FoodItem(
                id: _uuid.v4(),
                name: 'Oatmeal with Fruit and Nuts',
                calories: targetCalories,
                protein: proteinGrams,
                carbs: carbsGrams,
                fat: fatGrams,
                description: '~${targetCalories.toInt()} kcal'),
            quantity: 1.0,
            servingSize: '1 bowl',
          ),
        ];
        break;

      case MealType.lunch:
        name = 'Lunch';
        mealTime = DateTime(date.year, date.month, date.day, 13); // 1 PM

        ingredients = [
          "4 oz (120g) boneless, skinless chicken breast",
          "1/2 cup cooked brown rice",
          "1 tablespoon olive oil",
          "1 clove garlic, minced",
          "1/2 teaspoon dried oregano",
          "1/4 teaspoon salt",
          "1/4 teaspoon black pepper",
          "1 cup mixed vegetables (broccoli, bell peppers, carrots)",
          "2 tablespoons low-sodium soy sauce",
          "1 teaspoon honey",
          "1/2 tablespoon sesame seeds"
        ];

        cookingInstructions =
            "1. Cook brown rice according to package instructions and set aside.\n"
            "2. Cut chicken into 1-inch cubes and season with salt, pepper, and oregano.\n"
            "3. Heat olive oil in a non-stick pan over medium-high heat.\n"
            "4. Add minced garlic and sauté for 30 seconds until fragrant.\n"
            "5. Add chicken pieces and cook for 5-6 minutes until golden brown and cooked through.\n"
            "6. Add mixed vegetables and stir-fry for 3-4 minutes until crisp-tender.\n"
            "7. In a small bowl, mix soy sauce and honey, then pour over the chicken and vegetables.\n"
            "8. Cook for another minute, stirring to coat everything in the sauce.\n"
            "9. Serve over brown rice and sprinkle with sesame seeds.";

        items = [
          MealItem(
            foodItem: FoodItem(
                id: _uuid.v4(),
                name: 'Chicken Stir-Fry with Brown Rice',
                calories: targetCalories,
                protein: proteinGrams,
                carbs: carbsGrams,
                fat: fatGrams,
                description: '~${targetCalories.toInt()} kcal'),
            quantity: 1.0,
            servingSize: '1 plate',
          ),
        ];
        break;

      case MealType.dinner:
        name = 'Dinner';
        mealTime = DateTime(date.year, date.month, date.day, 19); // 7 PM

        ingredients = [
          "4 oz (120g) salmon fillet",
          "1 tablespoon olive oil",
          "1 clove garlic, minced",
          "1 teaspoon lemon zest",
          "1 tablespoon fresh lemon juice",
          "1/2 teaspoon dried dill or 1 teaspoon fresh dill, chopped",
          "1/4 teaspoon salt",
          "1/4 teaspoon black pepper",
          "1 cup broccoli florets",
          "1 cup cauliflower florets",
          "1 medium carrot, sliced",
          "1/2 tablespoon olive oil for roasting vegetables",
          "1 small sweet potato, cubed (about 3/4 cup)"
        ];

        cookingInstructions = "1. Preheat oven to 400°F (200°C).\n"
            "2. Toss broccoli, cauliflower, carrots, and sweet potato with 1/2 tablespoon olive oil, salt, and pepper. Spread on a baking sheet.\n"
            "3. Roast vegetables for 20-25 minutes, tossing halfway through, until tender and caramelized.\n"
            "4. While vegetables are roasting, prepare the salmon: mix 1 tablespoon olive oil, garlic, lemon zest, lemon juice, dill, salt, and pepper in a small bowl.\n"
            "5. Place salmon on a parchment-lined baking sheet and brush with the marinade.\n"
            "6. During the last 12-15 minutes of vegetable roasting time, add the salmon to the oven.\n"
            "7. Cook until salmon is opaque and flakes easily with a fork.\n"
            "8. Serve salmon with roasted vegetables.";

        items = [
          MealItem(
            foodItem: FoodItem(
                id: _uuid.v4(),
                name: 'Baked Salmon with Roasted Vegetables',
                calories: targetCalories,
                protein: proteinGrams,
                carbs: carbsGrams,
                fat: fatGrams,
                description: '~${targetCalories.toInt()} kcal'),
            quantity: 1.0,
            servingSize: '1 portion',
          ),
        ];
        break;

      case MealType.snack:
        name = 'Snack';
        mealTime = date.hour < 12
            ? DateTime(date.year, date.month, date.day, 11) // 11 AM
            : DateTime(date.year, date.month, date.day, 16); // 4 PM

        ingredients = [
          "1/2 cup plain Greek yogurt",
          "1 tablespoon honey or maple syrup",
          "1/4 teaspoon vanilla extract",
          "2 tablespoons mixed nuts (almonds, walnuts, pecans)",
          "1 tablespoon pumpkin seeds",
          "1/4 cup fresh berries",
          "1 teaspoon chia seeds"
        ];

        cookingInstructions =
            "1. In a small bowl, mix Greek yogurt with honey and vanilla extract.\n"
            "2. Top with mixed nuts, pumpkin seeds, berries, and chia seeds.\n"
            "3. Enjoy immediately or refrigerate for up to 24 hours (add nuts just before eating to maintain crunch).";

        items = [
          MealItem(
            foodItem: FoodItem(
                id: _uuid.v4(),
                name: 'Greek Yogurt Parfait with Nuts and Berries',
                calories: targetCalories,
                protein: proteinGrams,
                carbs: carbsGrams,
                fat: fatGrams,
                description: '~${targetCalories.toInt()} kcal'),
            quantity: 1.0,
            servingSize: '1 serving',
          ),
        ];
        break;

      case MealType.other:
      default:
        name = 'Other Meal';
        mealTime =
            DateTime(date.year, date.month, date.day, 12); // Default noon

        ingredients = [
          "1 whole grain wrap",
          "3 oz (90g) lean turkey breast, sliced",
          "1/4 avocado, sliced",
          "1/2 cup mixed greens",
          "2 slices tomato",
          "1 tablespoon hummus",
          "1 teaspoon Dijon mustard",
          "1 small apple"
        ];

        cookingInstructions =
            "1. Spread hummus evenly over the whole grain wrap.\n"
            "2. Layer turkey slices, avocado, mixed greens, and tomato on top.\n"
            "3. Drizzle with Dijon mustard.\n"
            "4. Roll up tightly, tucking in the sides as you go.\n"
            "5. Cut in half diagonally and serve with apple on the side.";

        items = [
          MealItem(
            foodItem: FoodItem(
                id: _uuid.v4(),
                name: 'Turkey Avocado Wrap with Apple',
                calories: targetCalories,
                protein: proteinGrams,
                carbs: carbsGrams,
                fat: fatGrams,
                description: '~${targetCalories.toInt()} kcal'),
            quantity: 1.0,
            servingSize: '1 serving',
          ),
        ];
        break;
    }

    return Meal(
      id: _uuid.v4(),
      name: name,
      type: type,
      dateTime: mealTime,
      items: items,
      notes: 'Sample meal (~${targetCalories.toInt()} kcal)',
      ingredients: ingredients,
      cookingInstructions: cookingInstructions,
    );
  }

  // Get random suggested questions
  List<String> getRandomSuggestedQuestions({int count = 3}) {
    // Create a copy of the list to avoid modifying the original
    final questions = List<String>.from(_suggestedQuestions);

    // Shuffle the questions
    questions.shuffle();

    // Return the specified number of questions (or all if less available)
    return questions.take(count).toList();
  }

  // Generate question suggestions based on user profile
  List<String> getSuggestedQuestionsForUser(UserProfile userProfile,
      {int count = 3}) {
    // Create lists of targeted questions based on fitness goals
    final List<String> weightLossQuestions = [
      "How can I burn more calories during my workouts?",
      "What's the best cardio for weight loss?",
      "How do I create a calorie deficit?",
      "How often should I weigh myself?",
      "What foods should I avoid to lose weight?",
    ];

    final List<String> muscleGainQuestions = [
      "How much protein should I eat to build muscle?",
      "What's the best split for muscle growth?",
      "How heavy should I lift to gain muscle?",
      "How do I know if I'm making muscle gains?",
      "Should I take creatine for muscle building?",
    ];

    final List<String> maintenanceQuestions = [
      "How do I maintain my current fitness level?",
      "What's a good balanced workout routine?",
      "How do I know if my nutrition is balanced?",
      "What's the best way to stay motivated?",
      "How often should I change my workout routine?",
    ];

    // Combine general questions with goal-specific questions
    List<String> combinedQuestions = List<String>.from(_suggestedQuestions);

    // Add goal-specific questions based on user profile
    if (userProfile.fitnessGoal == FitnessGoal.weightLoss) {
      combinedQuestions.addAll(weightLossQuestions);
    } else if (userProfile.fitnessGoal == FitnessGoal.muscleGain) {
      combinedQuestions.addAll(muscleGainQuestions);
    } else if (userProfile.fitnessGoal == FitnessGoal.maintenance) {
      combinedQuestions.addAll(maintenanceQuestions);
    }

    // Shuffle the combined list
    combinedQuestions.shuffle();

    // Return the specified number of questions
    return combinedQuestions.take(count).toList();
  }
}
