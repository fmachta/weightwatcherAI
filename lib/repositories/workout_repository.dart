// repositories/workout_repository.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workout.dart';
import '../models/exercise.dart';

class WorkoutRepository {
  static const String _workoutsKey = 'workouts';
  static const String _exerciseLibraryKey = 'exercise_library';

  // Save a workout
  Future<void> saveWorkout(Workout workout) async {
    final prefs = await SharedPreferences.getInstance();
    final workoutsJson = prefs.getStringList(_workoutsKey) ?? [];

    // Check if the workout already exists (update)
    final index = workoutsJson.indexWhere((json) {
      final existingWorkout = Workout.fromJson(jsonDecode(json));
      return existingWorkout.id == workout.id;
    });

    if (index >= 0) {
      // Update existing workout
      workoutsJson[index] = jsonEncode(workout.toJson());
    } else {
      // Add new workout
      workoutsJson.add(jsonEncode(workout.toJson()));
    }

    await prefs.setStringList(_workoutsKey, workoutsJson);
  }

  // Get all workouts
  Future<List<Workout>> getAllWorkouts() async {
    final prefs = await SharedPreferences.getInstance();
    final workoutsJson = prefs.getStringList(_workoutsKey) ?? [];

    return workoutsJson
        .map((json) => Workout.fromJson(jsonDecode(json)))
        .toList();
  }

  // Get workouts for a specific date
  Future<List<Workout>> getWorkoutsForDate(DateTime date) async {
    final allWorkouts = await getAllWorkouts();

    return allWorkouts.where((workout) {
      return workout.dateTime.year == date.year &&
          workout.dateTime.month == date.month &&
          workout.dateTime.day == date.day;
    }).toList();
  }

  // Delete a workout
  Future<void> deleteWorkout(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final workoutsJson = prefs.getStringList(_workoutsKey) ?? [];

    final workouts = workoutsJson
        .map((json) => Workout.fromJson(jsonDecode(json)))
        .toList();

    // Remove the workout with the given id
    workouts.removeWhere((workout) => workout.id == id);

    // Save the updated list
    await prefs.setStringList(
      _workoutsKey,
      workouts.map((workout) => jsonEncode(workout.toJson())).toList(),
    );
  }

  // Get predefined exercise library
  List<Exercise> _getPredefinedExercises() {
    return [
      Exercise(
        id: 'push_up',
        name: 'Push-up',
        description: 'A classic bodyweight exercise that targets the chest, shoulders, and triceps.',
        targetMuscleGroup: 'Chest',
        caloriesBurnedPerMinute: 7,
      ),
      Exercise(
        id: 'squat',
        name: 'Squat',
        description: 'A compound exercise that targets the quadriceps, hamstrings, and glutes.',
        targetMuscleGroup: 'Legs',
        caloriesBurnedPerMinute: 8,
      ),
      Exercise(
        id: 'plank',
        name: 'Plank',
        description: 'An isometric core exercise that strengthens the abdominals and lower back.',
        targetMuscleGroup: 'Core',
        caloriesBurnedPerMinute: 5,
      ),
      Exercise(
        id: 'pull_up',
        name: 'Pull-up',
        description: 'A bodyweight exercise that targets the back, biceps, and forearms.',
        targetMuscleGroup: 'Back',
        caloriesBurnedPerMinute: 10,
      ),
      Exercise(
        id: 'lunges',
        name: 'Lunges',
        description: 'A unilateral exercise that targets the quadriceps, hamstrings, and glutes.',
        targetMuscleGroup: 'Legs',
        caloriesBurnedPerMinute: 6,
      ),
      Exercise(
        id: 'bench_press',
        name: 'Bench Press',
        description: 'A compound exercise that targets the chest, shoulders, and triceps.',
        targetMuscleGroup: 'Chest',
        caloriesBurnedPerMinute: 8,
      ),
      Exercise(
        id: 'deadlift',
        name: 'Deadlift',
        description: 'A compound exercise that targets the hamstrings, glutes, and lower back.',
        targetMuscleGroup: 'Back',
        caloriesBurnedPerMinute: 9,
      ),
      Exercise(
        id: 'shoulder_press',
        name: 'Shoulder Press',
        description: 'A compound exercise that targets the shoulders and triceps.',
        targetMuscleGroup: 'Shoulders',
        caloriesBurnedPerMinute: 7,
      ),
      Exercise(
        id: 'bicep_curl',
        name: 'Bicep Curl',
        description: 'An isolation exercise that targets the biceps.',
        targetMuscleGroup: 'Arms',
        caloriesBurnedPerMinute: 5,
      ),
      Exercise(
        id: 'tricep_extension',
        name: 'Tricep Extension',
        description: 'An isolation exercise that targets the triceps.',
        targetMuscleGroup: 'Arms',
        caloriesBurnedPerMinute: 5,
      ),
    ];
  }

  // Save a custom exercise
  Future<void> saveCustomExercise(Exercise exercise) async {
    final prefs = await SharedPreferences.getInstance();
    final customExercisesJson = prefs.getStringList(_exerciseLibraryKey) ?? [];

    // Check if the exercise already exists (update)
    final index = customExercisesJson.indexWhere((json) {
      final existingExercise = Exercise.fromJson(jsonDecode(json));
      return existingExercise.id == exercise.id;
    });

    if (index >= 0) {
      // Update existing exercise
      customExercisesJson[index] = jsonEncode(exercise.toJson());
    } else {
      // Add new exercise
      customExercisesJson.add(jsonEncode(exercise.toJson()));
    }

    await prefs.setStringList(_exerciseLibraryKey, customExercisesJson);
  }

  // Get all exercises (predefined + custom)
  Future<List<Exercise>> getAllExercises() async {
    final predefinedExercises = _getPredefinedExercises();
    final customExercises = await getCustomExercises();

    return [...predefinedExercises, ...customExercises];
  }

  // Get custom exercises
  Future<List<Exercise>> getCustomExercises() async {
    final prefs = await SharedPreferences.getInstance();
    final customExercisesJson = prefs.getStringList(_exerciseLibraryKey) ?? [];

    return customExercisesJson
        .map((json) => Exercise.fromJson(jsonDecode(json)))
        .toList();
  }

  // Delete a custom exercise
  Future<void> deleteCustomExercise(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final customExercisesJson = prefs.getStringList(_exerciseLibraryKey) ?? [];

    final customExercises = customExercisesJson
        .map((json) => Exercise.fromJson(jsonDecode(json)))
        .toList();

    // Remove the exercise with the given id
    customExercises.removeWhere((exercise) => exercise.id == id);

    // Save the updated list
    await prefs.setStringList(
      _exerciseLibraryKey,
      customExercises.map((exercise) => jsonEncode(exercise.toJson())).toList(),
    );
  }
}