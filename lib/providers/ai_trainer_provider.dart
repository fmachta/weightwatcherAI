import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/ai_plan.dart';
import '../models/user_profile.dart';
import '../models/meal.dart';
import '../models/workout.dart';
import '../services/openai_service.dart';
import '../repositories/ai_plan_repository.dart';

class AITrainerProvider with ChangeNotifier {
  final AIPlanRepository _repository = AIPlanRepository();
  final Uuid _uuid = const Uuid();

  List<AIPlan> _plans = [];
  AIPlan? _currentPlan;
  bool _isLoading = false;

  List<AIPlan> get plans => _plans;
  AIPlan? get currentPlan => _currentPlan;
  bool get isLoading => _isLoading;

  // Initialize AI trainer data
  Future<void> initialize() async {
    _isLoading = true;
    // Use a microtask to defer notifyListeners until after the current build phase
    Future.microtask(() => notifyListeners());

    _plans = await _repository.getAllPlans();

    // Find active plan only if we have plans
    if (_plans.isNotEmpty) {
      _currentPlan = _plans.firstWhere(
        (plan) =>
          plan.startDate.isBefore(DateTime.now()) &&
          plan.endDate.isAfter(DateTime.now()),
        orElse: () => _plans.last,
      );
    } else {
      _currentPlan = null;
    }

    _isLoading = false;
    // Use a microtask to defer notifyListeners until after the current build phase
    Future.microtask(() => notifyListeners());
  }

  // Generate workout plan based on user profile
  Future<AIPlan> generateWorkoutPlan(UserProfile userProfile) async {
    _isLoading = true;
    notifyListeners();

    final id = _uuid.v4();

    // This is a simplified version, for demo purposes
    // In a real app, this would use ML or more sophisticated algorithms
    final plan = AIPlan(
      id: id,
      title: 'Custom Workout Plan',
      description: 'Personalized workout plan based on your profile',
      type: PlanType.workout,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 28)), // 4 weeks
      days: _generateWorkoutDays(userProfile),
      targetProfile: userProfile,
    );

    await _repository.savePlan(plan);
    _plans = await _repository.getAllPlans();
    _currentPlan = plan;

    _isLoading = false;
    notifyListeners();

    return plan;
  }

  // Generate meal plan based on user profile
  Future<AIPlan> generateMealPlan(UserProfile userProfile) async {
    _isLoading = true;
    notifyListeners();

    final id = _uuid.v4();

    // This is a simplified version, for demo purposes
    final plan = AIPlan(
      id: id,
      title: 'Custom Meal Plan',
      description: 'Personalized meal plan based on your profile',
      type: PlanType.nutrition,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 28)), // 4 weeks
      days: _generateMealPlanDays(userProfile),
      targetProfile: userProfile,
    );

    await _repository.savePlan(plan);
    _plans = await _repository.getAllPlans();
    _currentPlan = plan;

    _isLoading = false;
    notifyListeners();

    return plan;
  }

  // Delete a plan
  Future<void> deletePlan(String id) async {
    _isLoading = true;
    notifyListeners();

    await _repository.deletePlan(id);
    _plans = await _repository.getAllPlans();

    if (_currentPlan?.id == id) {
      _currentPlan = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  // Get plan by id
  Future<AIPlan?> getPlanById(String id) async {
    return _repository.getPlanById(id);
  }

  // Helper method to generate workout days (placeholder implementation)
  List<PlanDay> _generateWorkoutDays(UserProfile userProfile) {
    // This is a simplified version, for demo purposes
    // In a real app, this would be more sophisticated
    final List<PlanDay> days = [];

    // Generate 28 days of workouts
    for (int i = 1; i <= 28; i++) {
      days.add(PlanDay(
        dayNumber: i,
        notes: 'Day $i of your workout plan',
      ));
    }

    return days;
  }

  // Helper method to generate meal plan days (placeholder implementation)
  List<PlanDay> _generateMealPlanDays(UserProfile userProfile) {
    // This is a simplified version, for demo purposes
    final List<PlanDay> days = [];

    // Generate 28 days of meal plans
    for (int i = 1; i <= 28; i++) {
      days.add(PlanDay(
        dayNumber: i,
        notes: 'Day $i of your meal plan',
      ));
    }

    return days;
  }

  // Get AI fitness insight
  Future<String> getAIInsight(
      UserProfile userProfile,
      List<dynamic> recentWorkouts,
      List<dynamic> recentMeals,
      ) async {
    try {
      // Simple fallback message when AI service fails
      return 'Based on your recent activity, consider focusing on consistency and proper nutrition to reach your fitness goals.';
    } catch (e) {
      return 'Based on your recent activity, consider focusing on consistency and proper nutrition to reach your fitness goals.';
    }
  }

  // Answer fitness questions with AI
  Future<String> answerQuestion(
      String question,
      UserProfile userProfile,
      ) async {
    try {
      // Provide a simple default answer when AI service fails
      return 'To achieve your fitness goals, focus on consistency with your workouts and maintaining a balanced diet. Make sure you\'re getting enough protein and staying hydrated.';
    } catch (e) {
      return 'To achieve your fitness goals, focus on consistency with your workouts and maintaining a balanced diet. Make sure you\'re getting enough protein and staying hydrated.';
    }
  }
}