// repositories/ai_plan_repository.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ai_plan.dart';

class AIPlanRepository {
  static const String _plansKey = 'ai_plans';

  // Save a plan
  Future<void> savePlan(AIPlan plan) async {
    final prefs = await SharedPreferences.getInstance();
    final plansJson = prefs.getStringList(_plansKey) ?? [];

    // Check if the plan already exists (update)
    final index = plansJson.indexWhere((json) {
      final existingPlan = AIPlan.fromJson(jsonDecode(json));
      return existingPlan.id == plan.id;
    });

    if (index >= 0) {
      // Update existing plan
      plansJson[index] = jsonEncode(plan.toJson());
    } else {
      // Add new plan
      plansJson.add(jsonEncode(plan.toJson()));
    }

    await prefs.setStringList(_plansKey, plansJson);
  }

  // Get all plans
  Future<List<AIPlan>> getAllPlans() async {
    final prefs = await SharedPreferences.getInstance();
    final plansJson = prefs.getStringList(_plansKey) ?? [];

    return plansJson.map((json) => AIPlan.fromJson(jsonDecode(json))).toList();
  }

  // Get plan by id
  Future<AIPlan?> getPlanById(String id) async {
    final allPlans = await getAllPlans();

    try {
      return allPlans.firstWhere((plan) => plan.id == id);
    } catch (e) {
      return null;
    }
  }

  // Delete a plan
  Future<void> deletePlan(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final plansJson = prefs.getStringList(_plansKey) ?? [];

    final plans =
        plansJson.map((json) => AIPlan.fromJson(jsonDecode(json))).toList();

    // Remove the plan with the given id
    plans.removeWhere((plan) => plan.id == id);

    // Save the updated list
    await prefs.setStringList(
      _plansKey,
      plans.map((plan) => jsonEncode(plan.toJson())).toList(),
    );
  }
}
