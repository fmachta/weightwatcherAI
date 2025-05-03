// models/exercise.dart
class Exercise {
  final String id;
  final String name;
  final String targetMuscleGroup;
  final List<ExerciseSet>? sets;
  final Duration? duration;
  final String? description;
  final double? caloriesBurnedPerMinute;

  Exercise({
    required this.id,
    required this.name,
    required this.targetMuscleGroup,
    this.sets,
    this.duration,
    this.description,
    this.caloriesBurnedPerMinute,
  });

  // Convert to and from JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'targetMuscleGroup': targetMuscleGroup,
      'sets': sets?.map((set) => set.toJson()).toList(),
      'duration': duration?.inSeconds,
      'description': description,
      'caloriesBurnedPerMinute': caloriesBurnedPerMinute,
    };
  }

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'],
      name: json['name'],
      targetMuscleGroup: json['targetMuscleGroup'],
      sets: json['sets'] != null
          ? (json['sets'] as List)
              .map((setJson) => ExerciseSet.fromJson(setJson))
              .toList()
          : null,
      duration:
          json['duration'] != null ? Duration(seconds: json['duration']) : null,
      description: json['description'],
      caloriesBurnedPerMinute: json['caloriesBurnedPerMinute']?.toDouble(),
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
    final rawDuration = json['duration'];
    final durationSeconds = rawDuration is int
        ? rawDuration
        : rawDuration is String
            ? int.tryParse(rawDuration)
            : rawDuration is double
                ? rawDuration.toInt()
                : null;

    return ExerciseSet(
      reps: json['reps'],
      weight:
          json['weight'] != null ? (json['weight'] as num).toDouble() : null,
      duration:
          durationSeconds != null ? Duration(seconds: durationSeconds) : null,
    );
  }
}
