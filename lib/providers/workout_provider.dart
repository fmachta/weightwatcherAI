import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/workout.dart';
import '../models/exercise.dart';
import '../repositories/workout_repository.dart';

class WorkoutProvider with ChangeNotifier {
  final WorkoutRepository _repository = WorkoutRepository();
  final Uuid _uuid = const Uuid();

  List<Exercise> _exercises = [];
  List<Workout> _workouts = [];
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  List<Exercise> get exercises => _exercises;
  List<Workout> get workouts => _workouts;
  DateTime get selectedDate => _selectedDate;
  bool get isLoading => _isLoading;

  // Initialize workout data
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    _exercises = await _repository.getAllExercises();
    await _loadWorkoutsForSelectedDate();

    _isLoading = false;
    notifyListeners();
  }

  // Load workouts for selected date
  Future<void> _loadWorkoutsForSelectedDate() async {
    _workouts = await _repository.getWorkoutsForDate(_selectedDate);
    notifyListeners();
  }

  // Change selected date
  Future<void> changeSelectedDate(DateTime date) async {
    _selectedDate = date;
    await _loadWorkoutsForSelectedDate();
    notifyListeners();
  }

  // Add a workout
  Future<void> addWorkout(
      String name,
      DateTime dateTime,
      Duration duration,
      WorkoutType type,
      List<Exercise> exercises,
      int caloriesBurned,
      {String? notes}) async {
    _isLoading = true;
    notifyListeners();

    final workout = Workout(
      id: _uuid.v4(),
      name: name,
      dateTime: dateTime,
      duration: duration,
      type: type,
      exercises: exercises,
      caloriesBurned: caloriesBurned,
      notes: notes,
    );

    await _repository.saveWorkout(workout);
    await _loadWorkoutsForSelectedDate();

    _isLoading = false;
    notifyListeners();
  }

  // Update a workout
  Future<void> updateWorkout(Workout workout) async {
    _isLoading = true;
    notifyListeners();

    await _repository.saveWorkout(workout);
    await _loadWorkoutsForSelectedDate();

    _isLoading = false;
    notifyListeners();
  }

  // Delete a workout
  Future<void> deleteWorkout(String id) async {
    _isLoading = true;
    notifyListeners();

    await _repository.deleteWorkout(id);
    await _loadWorkoutsForSelectedDate();

    _isLoading = false;
    notifyListeners();
  }

  // Add custom exercise
  Future<void> addCustomExercise(Exercise exercise) async {
    _isLoading = true;
    notifyListeners();

    await _repository.saveCustomExercise(exercise);
    _exercises = await _repository.getAllExercises();

    _isLoading = false;
    notifyListeners();
  }

  // Search exercises
  List<Exercise> searchExercises(String query) {
    if (query.isEmpty) {
      return _exercises;
    }

    return _exercises
        .where((exercise) =>
        exercise.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  // Get workout stats for week
  Future<List<Map<String, dynamic>>> getWeeklyWorkoutStats() async {
    final today = DateTime.now();
    final weekStart = today.subtract(Duration(days: today.weekday - 1));

    List<Map<String, dynamic>> weekData = [];

    for (int i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      final workouts = await _repository.getWorkoutsForDate(date);

      int totalMinutes = 0;
      double totalCaloriesBurned = 0;

      for (final workout in workouts) {
        totalMinutes += workout.duration.inMinutes;
        totalCaloriesBurned += workout.caloriesBurned;
      }

      weekData.add({
        'date': date,
        'day': ['M', 'T', 'W', 'T', 'F', 'S', 'S'][i],
        'minutes': totalMinutes,
        'caloriesBurned': totalCaloriesBurned,
        'workoutCount': workouts.length,
      });
    }

    return weekData;
  }
}
