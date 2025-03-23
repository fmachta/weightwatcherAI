// models/user_profile.dart

class UserProfile {
  final String name;
  final String email;
  final double currentWeight;
  final double targetWeight;
  final double height;
  final int age;
  final String gender;
  final double bodyFat;
  final double muscleMass;
  final ActivityLevel activityLevel;
  final FitnessGoal fitnessGoal;
  final Map<String, double>? macroDistribution;

  UserProfile({
    required this.name,
    required this.email,
    required this.currentWeight,
    required this.targetWeight,
    required this.height,
    required this.age,
    required this.gender,
    required this.bodyFat,
    required this.muscleMass,
    required this.activityLevel,
    required this.fitnessGoal,
    this.macroDistribution,
  });

  // Calculate BMI (Body Mass Index)
  double get bmi => currentWeight / ((height / 100) * (height / 100));

  // Calculate BMR (Basal Metabolic Rate) using the Mifflin-St Jeor Equation
  double get bmr {
    if (gender.toLowerCase() == 'male') {
      return (10 * currentWeight) + (6.25 * height) - (5 * age) + 5;
    } else {
      return (10 * currentWeight) + (6.25 * height) - (5 * age) - 161;
    }
  }

  // Calculate TDEE (Total Daily Energy Expenditure)
  double get tdee => bmr * activityLevel.multiplier;

  // Calculate daily calorie goal based on fitness goal
  double calculateDailyCalorieGoal() {
    switch (fitnessGoal) {
      case FitnessGoal.weightLoss:
        return tdee * 0.8; // 20% deficit
      case FitnessGoal.maintenance:
        return tdee;
      case FitnessGoal.muscleGain:
        return tdee * 1.1; // 10% surplus
    }
  }

  // Get default macro distribution (protein, carbs, fat) percentages
  Map<String, double> get defaultMacroDistribution {
    switch (fitnessGoal) {
      case FitnessGoal.weightLoss:
        return {'protein': 0.4, 'carbs': 0.3, 'fat': 0.3};
      case FitnessGoal.maintenance:
        return {'protein': 0.3, 'carbs': 0.4, 'fat': 0.3};
      case FitnessGoal.muscleGain:
        return {'protein': 0.3, 'carbs': 0.5, 'fat': 0.2};
    }
  }

  // Convert to and from JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'currentWeight': currentWeight,
      'targetWeight': targetWeight,
      'height': height,
      'age': age,
      'gender': gender,
      'bodyFat': bodyFat,
      'muscleMass': muscleMass,
      'activityLevel': activityLevel.toString(),
      'fitnessGoal': fitnessGoal.toString(),
      'macroDistribution': macroDistribution ?? defaultMacroDistribution,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'],
      email: json['email'],
      currentWeight: json['currentWeight'].toDouble(),
      targetWeight: json['targetWeight'].toDouble(),
      height: json['height'].toDouble(),
      age: json['age'],
      gender: json['gender'],
      bodyFat: json['bodyFat'].toDouble(),
      muscleMass: json['muscleMass'].toDouble(),
      activityLevel: ActivityLevel.values.firstWhere(
            (e) => e.toString() == json['activityLevel'],
        orElse: () => ActivityLevel.moderatelyActive,
      ),
      fitnessGoal: FitnessGoal.values.firstWhere(
            (e) => e.toString() == json['fitnessGoal'],
        orElse: () => FitnessGoal.maintenance,
      ),
      macroDistribution: (json['macroDistribution'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value.toDouble()),
      ),
    );
  }
}

// Activity levels
enum ActivityLevel {
  sedentary,
  lightlyActive,
  moderatelyActive,
  veryActive,
  extraActive
}

// Activity level multipliers for TDEE calculation
extension ActivityLevelExtension on ActivityLevel {
  double get multiplier {
    switch (this) {
      case ActivityLevel.sedentary:
        return 1.2;
      case ActivityLevel.lightlyActive:
        return 1.375;
      case ActivityLevel.moderatelyActive:
        return 1.55;
      case ActivityLevel.veryActive:
        return 1.725;
      case ActivityLevel.extraActive:
        return 1.9;
    }
  }
}

// Fitness goals
enum FitnessGoal {
  weightLoss,
  maintenance,
  muscleGain
}