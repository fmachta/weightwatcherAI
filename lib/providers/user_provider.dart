import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import '../models/body_measurement.dart';
import '../repositories/user_repository.dart';

class UserProvider with ChangeNotifier {
  final UserRepository _repository = UserRepository();

  UserProfile? _userProfile;
  List<BodyMeasurement> _bodyMeasurements = [];
  bool _isLoading = false;

  UserProfile? get userProfile => _userProfile;
  set userProfile(UserProfile? value) { // Setter
    _userProfile = value;
    notifyListeners(); // Important: Notify listeners of the change
  }
  List<BodyMeasurement> get bodyMeasurements => _bodyMeasurements;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _userProfile != null; // Getter to check login status

  // Clear user data for guest sessions or logout
  void clearUserProfile() {
    _userProfile = null;
    _bodyMeasurements = [];
    notifyListeners(); // Notify listeners about the cleared state
  }

  // Initialize user data
  Future<void> initialize() async {
    _isLoading = true;
    // Use a microtask to defer notifyListeners until after the current build phase
    Future.microtask(() => notifyListeners());

    _userProfile = await _repository.getUserProfile();
    _bodyMeasurements = await _repository.getBodyMeasurements();

    _isLoading = false;
    // Use a microtask to defer notifyListeners until after the current build phase
    Future.microtask(() => notifyListeners());
  }

  // Save user profile
  Future<void> saveUserProfile(UserProfile userProfile) async {
    _isLoading = true;
    notifyListeners();

    await _repository.saveUserProfile(userProfile);
    _userProfile = userProfile;

    _isLoading = false;
    notifyListeners();
  }

  // Save body measurement
  Future<void> saveBodyMeasurement(BodyMeasurement measurement) async {
    _isLoading = true;
    notifyListeners();

    await _repository.saveBodyMeasurement(measurement);
    _bodyMeasurements = await _repository.getBodyMeasurements();

    _isLoading = false;
    notifyListeners();
  }

  // Delete body measurement
  Future<void> deleteBodyMeasurement(DateTime date) async {
    _isLoading = true;
    notifyListeners();

    await _repository.deleteBodyMeasurement(date);
    _bodyMeasurements = await _repository.getBodyMeasurements();

    _isLoading = false;
    notifyListeners();
  }

  // Get weight trend data for charting
  List<Map<String, dynamic>> getWeightTrendData() {
    final sortedMeasurements = List<BodyMeasurement>.from(_bodyMeasurements);
    sortedMeasurements.sort((a, b) => a.date.compareTo(b.date));

    return sortedMeasurements.map((measurement) {
      return {
        'date': measurement.date,
        'weight': measurement.weight,
      };
    }).toList();
  }

  // Get muscle mass trend data for charting
  List<Map<String, dynamic>> getMuscleMassTrendData() {
    final sortedMeasurements = List<BodyMeasurement>.from(_bodyMeasurements)
        .where((m) => m.muscleMass != null)
        .toList();

    sortedMeasurements.sort((a, b) => a.date.compareTo(b.date));

    return sortedMeasurements.map((measurement) {
      return {
        'date': measurement.date,
        'muscleMass': measurement.muscleMass,
      };
    }).toList();
  }

  // Get body fat trend data for charting
  List<Map<String, dynamic>> getBodyFatTrendData() {
    final sortedMeasurements = List<BodyMeasurement>.from(_bodyMeasurements)
        .where((m) => m.bodyFat != null)
        .toList();

    sortedMeasurements.sort((a, b) => a.date.compareTo(b.date));

    return sortedMeasurements.map((measurement) {
      return {
        'date': measurement.date,
        'bodyFat': measurement.bodyFat,
      };
    }).toList();
  }
}
