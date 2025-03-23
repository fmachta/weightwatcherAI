// models/workout.dart
import 'exercise.dart';

class Workout {
  final String id;
  final String name;
  final DateTime dateTime;
  final Duration duration;
  final WorkoutType type;
  final List<Exercise> exercises;
  final int caloriesBurned;
  final String? notes;

  Workout({
    required this.id,
    required this.name,
    required this.dateTime,
    required this.duration,
    required this.type,
    required this.exercises,
    required this.caloriesBurned,
    this.notes,
  });

  // Convert to and from JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dateTime': dateTime.toIso8601String(),
      'duration': duration.inMinutes,
      'type': type.toString(),
      'exercises': exercises.map((exercise) => exercise.toJson()).toList(),
      'caloriesBurned': caloriesBurned,
      'notes': notes,
    };
  }

  factory Workout.fromJson(Map<String, dynamic> json) {
    return Workout(
      id: json['id'],
      name: json['name'],
      dateTime: DateTime.parse(json['dateTime']),
      duration: Duration(minutes: json['duration']),
      type: WorkoutType.values.firstWhere(
            (e) => e.toString() == json['type'],
        orElse: () => WorkoutType.other,
      ),
      exercises: (json['exercises'] as List)
          .map((exerciseJson) => Exercise.fromJson(exerciseJson))
          .toList(),
      caloriesBurned: json['caloriesBurned'],
      notes: json['notes'],
    );
  }
}

// Workout types
enum WorkoutType {
  strength,
  cardio,
  hiit,
  flexibility,
  other
}