// models/exercise.dart
class Exercise {
  final String id;
  final String name;
  final String targetMuscleGroup;
  final List<ExerciseSet>? sets;
  final Duration? duration;

  Exercise({
    required this.id,
    required this.name,
    required this.targetMuscleGroup,
    this.sets,
    this.duration,
  });

  // Convert to and from JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'targetMuscleGroup': targetMuscleGroup,
      'sets': sets?.map((set) => set.toJson()).toList(),
      'duration': duration?.inSeconds,
    };
  }

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'],
      name: json['name'],
      targetMuscleGroup: json['targetMuscleGroup'],
      sets: json['sets'] != null
          ? (json['sets'] as List).map((setJson) => ExerciseSet.fromJson(setJson)).toList()
          : null,
      duration: json['duration'] != null
          ? Duration(seconds: json['duration'])
          : null,
    );
  }
}

class ExerciseSet {
  final int? reps;
  final double? weight;
  final Duration? duration;

  ExerciseSet({
    this.reps,
    this.weight,
    this.duration,
  });

  // Convert to and from JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'reps': reps,
      'weight': weight,
      'duration': duration?.inSeconds,
    };
  }

  factory ExerciseSet.fromJson(Map<String, dynamic> json) {
    return ExerciseSet(
      reps: json['reps'],
      weight: json['weight']?.toDouble(),
      duration: json['duration'] != null
          ? Duration(seconds: json['duration'])
          : null,
    );
  }
}