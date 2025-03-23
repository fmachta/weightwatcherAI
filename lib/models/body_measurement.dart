// models/body_measurement.dart
class BodyMeasurement {
  final DateTime date;
  final double weight;
  final double? bodyFat;
  final double? muscleMass;
  final Map<String, double>? circumferences;

  BodyMeasurement({
    required this.date,
    required this.weight,
    this.bodyFat,
    this.muscleMass,
    this.circumferences,
  });

  // Convert to and from JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'weight': weight,
      'bodyFat': bodyFat,
      'muscleMass': muscleMass,
      'circumferences': circumferences,
    };
  }

  factory BodyMeasurement.fromJson(Map<String, dynamic> json) {
    return BodyMeasurement(
      date: DateTime.parse(json['date']),
      weight: json['weight'].toDouble(),
      bodyFat: json['bodyFat']?.toDouble(),
      muscleMass: json['muscleMass']?.toDouble(),
      circumferences: json['circumferences'] != null
          ? (json['circumferences'] as Map<String, dynamic>).map(
            (key, value) => MapEntry(key, value.toDouble()),
      )
          : null,
    );
  }
}