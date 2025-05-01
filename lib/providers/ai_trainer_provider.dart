import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/ai_plan.dart';
import '../models/user_profile.dart';
import '../models/meal.dart';
import '../models/workout.dart';
import '../services/gemini_service.dart';
import '../repositories/ai_plan_repository.dart';

class AITrainerProvider with ChangeNotifier {
  final AIPlanRepository _repository = AIPlanRepository();
  final Uuid _uuid = const Uuid();
  final GeminiService _aiService = GeminiService();

  String? _aiInsight;
  String? get aiInsight => _aiInsight;

  List<AIPlan> _plans = [];
  AIPlan? _currentPlan;
  bool _isLoading = false;

  List<AIPlan> get plans => _plans;
  AIPlan? get currentPlan => _currentPlan;
  bool get isLoading => _isLoading;

  Future<void> initialize() async {
    _isLoading = true;
    Future.microtask(() => notifyListeners());

    _plans = await _repository.getAllPlans();

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
    Future.microtask(() => notifyListeners());
  }

  // Get random suggested questions (forwards to GeminiService)
  List<String> getRandomSuggestedQuestions({int count = 3}) {
    return _aiService.getRandomSuggestedQuestions(count: count);
  }
  
  // Get personalized questions based on user profile (forwards to GeminiService)
  List<String> getSuggestedQuestionsForUser(UserProfile userProfile, {int count = 3}) {
    return _aiService.getSuggestedQuestionsForUser(userProfile, count: count);
  }

  Future<void> fetchAIInsight(UserProfile user, List recentWorkouts, List recentMeals) async {
    _aiInsight = await _aiService.getAIInsight(user, recentWorkouts, recentMeals);
    notifyListeners();
  }

  Future<AIPlan> generateWorkoutPlan(UserProfile userProfile, [Map<String, dynamic>? preferenceData]) async {
    _isLoading = true;
    notifyListeners();

    final id = _uuid.v4();

    final plan = await _aiService.generateWorkoutPlan(userProfile, preferenceData);

    /*final plan = AIPlan(
      id: id,
      title: 'Custom Workout Plan',
      description: 'Personalized workout plan based on your profile',
      type: PlanType.workout,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 28)),
      days: _generateWorkoutDays(userProfile),
      targetProfile: userProfile,
    );*/

    await _repository.savePlan(plan);
    _plans = await _repository.getAllPlans();
    _currentPlan = plan;

    _isLoading = false;
    notifyListeners();

    return plan;
  }

  Future<AIPlan> generateMealPlan(UserProfile userProfile, [Map<String, dynamic>? preferenceData]) async {
    _isLoading = true;
    notifyListeners();

    final id = _uuid.v4();

    final plan = await _aiService.generateMealPlan(userProfile, preferenceData);

    /*final plan = AIPlan(
      id: id,
      title: 'Custom Meal Plan',
      description: 'Personalized meal plan based on your profile',
      type: PlanType.nutrition,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 28)),
      days: _generateMealPlanDays(userProfile),
      targetProfile: userProfile,
    );*/

    await _repository.savePlan(plan);
    _plans = await _repository.getAllPlans();
    _currentPlan = plan;

    _isLoading = false;
    notifyListeners();

    return plan;
  }

  Future<String> getAIInsight(
      UserProfile userProfile,
      List<dynamic> recentWorkouts,
      List<dynamic> recentMeals,
      ) async {
    return await _aiService.getAIInsight(userProfile, recentWorkouts, recentMeals);
  }

  Future<String> answerQuestion(
      String question,
      UserProfile userProfile,
      ) async {
    return await _aiService.answerQuestion(question, userProfile);
  }

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

  Future<AIPlan?> getPlanById(String id) async {
    return _repository.getPlanById(id);
  }

  List<PlanDay> _generateWorkoutDays(UserProfile userProfile) {
    final List<PlanDay> days = [];
    for (int i = 1; i <= 28; i++) {
      days.add(PlanDay(
        dayNumber: i,
        notes: 'Day $i of your workout plan',
      ));
    }
    return days;
  }

  List<PlanDay> _generateMealPlanDays(UserProfile userProfile) {
    final List<PlanDay> days = [];
    for (int i = 1; i <= 28; i++) {
      days.add(PlanDay(
        dayNumber: i,
        notes: 'Day $i of your meal plan',
      ));
    }
    return days;
  }
}
