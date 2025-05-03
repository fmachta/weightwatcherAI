import 'meal.dart';
import 'workout.dart';
import 'user_profile.dart';

class AIPlan {
  final String id;
  final String title;
  final String description;
  final PlanType type;
  final DateTime startDate;
  final DateTime endDate;
  final List<PlanDay> days;
  final UserProfile targetProfile;

  AIPlan({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.days,
    required this.targetProfile,
  });

  // Calculate duration in weeks
  int get durationInWeeks => endDate.difference(startDate).inDays ~/ 7;

  // Convert to and from JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.toString(),
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'days': days.map((day) => day.toJson()).toList(),
      'targetProfile': targetProfile.toJson(),
    };
  }

  factory AIPlan.fromJson(Map<String, dynamic> json) {
    return AIPlan(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      type: PlanType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => PlanType.other,
      ),
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      days: (json['days'] as List)
          .map((dayJson) => PlanDay.fromJson(dayJson))
          .toList(),
      targetProfile: UserProfile.fromJson(json['targetProfile']),
    );
  }
}

// Plan types
enum PlanType { workout, nutrition, combined, other }

class PlanDay {
  final int dayNumber;
  final String notes;
  final String summary;
  final List<Meal>? meals;
  final Workout? workout;

  PlanDay({
    required this.dayNumber,
    required this.notes,
    this.summary = '',
    this.meals,
    this.workout,
  });

  Map<String, dynamic> toJson() {
    return {
      'dayNumber': dayNumber,
      'notes': notes,
      'summary': summary,
      'meals': meals?.map((meal) => meal.toJson()).toList(),
      'workout': workout?.toJson(),
    };
  }

  factory PlanDay.fromJson(Map<String, dynamic> json) {
    return PlanDay(
      dayNumber: json['dayNumber'],
      notes: json['notes'] ?? '',
      summary: json['summary'] ?? '',
      meals: json['meals'] != null
          ? (json['meals'] as List)
              .map((mealJson) => Meal.fromJson(mealJson))
              .toList()
          : null,
      workout:
          json['workout'] != null ? Workout.fromJson(json['workout']) : null,
    );
  }
}
